#!/usr/bin/env python3
"""
Serviço de Geocodificação de CEPs usando BrasilAPI

Converte CEPs em coordenadas lat/long para o Mapa Interativo de Devedores
Cacheia resultados no banco para evitar requisições repetidas

Uso:
    python geocode_service.py --batch 1000  # Geocodifica 1000 estabelecimentos pendentes
    python geocode_service.py --cep 70040902  # Testa um CEP específico
"""

import os
import sys
import time
import argparse
import requests
import psycopg
from datetime import datetime
from pathlib import Path
from typing import Optional, Dict, Tuple
from dotenv import load_dotenv
from tqdm import tqdm

# Configuração
load_dotenv(Path(__file__).parent / '.env.local')

DB_CONFIG = {
    'host': os.getenv('DB_HOST', 'localhost'),
    'port': int(os.getenv('DB_PORT', 5434)),
    'database': os.getenv('DB_NAME', 'momento_fiscal_api_production'),
    'user': os.getenv('DB_USER', 'postgres'),
    'password': os.getenv('DB_PASSWORD', 'postgres')
}

# APIs de CEP e Geocoding
VIACEP_BASE_URL = "https://viacep.com.br/ws/"
NOMINATIM_BASE_URL = "https://nominatim.openstreetmap.org/search"
RATE_LIMIT_DELAY = 1.0  # 1 segundo entre requisições (Nominatim requer)
REQUEST_TIMEOUT = 10  # 10 segundos timeout


class GeocodeService:
    """Serviço de geocodificação via ViaCEP + Nominatim (OpenStreetMap)"""

    def __init__(self, db_config: Dict):
        self.db_config = db_config
        self.conn = None
        self.cursor = None
        self.session = requests.Session()
        self.session.headers.update({
            'User-Agent': 'Momento-Fiscal-ETL/1.0 (contato@momentofiscal.df.gov.br)'
        })
        
        # Contadores
        self.stats = {
            'success': 0,
            'not_found': 0,
            'errors': 0,
            'skipped': 0
        }

    def connect(self):
        """Conecta ao banco"""
        try:
            conn_string = (
                f"host={self.db_config['host']} "
                f"port={self.db_config['port']} "
                f"dbname={self.db_config['database']} "
                f"user={self.db_config['user']} "
                f"password={self.db_config['password']}"
            )
            self.conn = psycopg.connect(conn_string)
            self.cursor = self.conn.cursor()
            print(f"✅ Conectado ao banco: {self.db_config['database']}")
        except Exception as e:
            print(f"❌ Erro ao conectar: {e}")
            sys.exit(1)

    def close(self):
        """Fecha conexão"""
        if self.cursor:
            self.cursor.close()
        if self.conn:
            self.conn.close()
        if self.session:
            self.session.close()

    def geocode_cep(self, cep: str) -> Optional[Tuple[float, float]]:
        """
        Converte CEP em coordenadas lat/long via ViaCEP + Nominatim
        
        Estratégia:
        1. Busca endereço completo no ViaCEP
        2. Geocodifica endereço via Nominatim (OpenStreetMap)
        
        Args:
            cep: CEP com 8 dígitos (sem formatação)
        
        Returns:
            Tupla (latitude, longitude) ou None se não encontrado
        """
        if not cep or len(cep) != 8 or not cep.isdigit():
            return None

        try:
            # Passo 1: Busca endereço no ViaCEP
            cep_formatado = f"{cep[:5]}-{cep[5:]}"
            viacep_url = f"{VIACEP_BASE_URL}{cep_formatado}/json/"
            
            response = self.session.get(viacep_url, timeout=REQUEST_TIMEOUT)
            
            if response.status_code != 200:
                return None
            
            data = response.json()
            
            # ViaCEP retorna {"erro": true} se não encontrar
            if data.get('erro'):
                return None
            
            # Monta endereço completo para geocoding
            endereco_partes = []
            
            if data.get('logradouro'):
                endereco_partes.append(data['logradouro'])
            
            if data.get('bairro'):
                endereco_partes.append(data['bairro'])
            
            if data.get('localidade'):
                endereco_partes.append(data['localidade'])
            
            if data.get('uf'):
                endereco_partes.append(data['uf'])
            
            endereco_partes.append('Brasil')
            
            endereco_completo = ', '.join(endereco_partes)
            
            # Passo 2: Geocodifica via Nominatim
            time.sleep(RATE_LIMIT_DELAY)  # Rate limiting obrigatório para Nominatim
            
            # Tenta primeiro com endereço completo
            coords = self._geocode_nominatim(endereco_completo)
            
            # Se falhar, tenta apenas com cidade + UF (mais genérico)
            if not coords and data.get('localidade') and data.get('uf'):
                endereco_simples = f"{data['localidade']}, {data['uf']}, Brasil"
                time.sleep(RATE_LIMIT_DELAY)
                coords = self._geocode_nominatim(endereco_simples)
            
            return coords
                
        except requests.exceptions.Timeout:
            print(f"⚠️  CEP {cep}: Timeout")
            return None
        except requests.exceptions.RequestException as e:
            print(f"⚠️  CEP {cep}: Erro de rede - {e}")
            return None
        except KeyboardInterrupt:
            raise
        except Exception as e:
            print(f"❌ CEP {cep}: Erro inesperado - {e}")
            import traceback
            traceback.print_exc()
            return None

    def _geocode_nominatim(self, endereco: str) -> Optional[Tuple[float, float]]:
        """
        Geocodifica um endereço via Nominatim
        
        Args:
            endereco: Endereço completo ou simplificado
            
        Returns:
            Tupla (latitude, longitude) ou None
        """
        try:
            params = {
                'q': endereco,
                'format': 'json',
                'limit': 1,
                'addressdetails': 1,
                'countrycodes': 'br'  # Limita ao Brasil
            }
            
            response = self.session.get(
                NOMINATIM_BASE_URL,
                params=params,
                timeout=REQUEST_TIMEOUT
            )
            
            if response.status_code != 200:
                return None
            
            results = response.json()
            
            if not results or len(results) == 0:
                return None
            
            result = results[0]
            latitude = result.get('lat')
            longitude = result.get('lon')
            
            if latitude and longitude:
                latitude = float(latitude)
                longitude = float(longitude)
                
                # Valida ranges válidos para Brasil
                # Latitude: -33.75 a 5.27
                # Longitude: -73.99 a -28.84
                if -33.75 <= latitude <= 5.27 and -73.99 <= longitude <= -28.84:
                    return (latitude, longitude)
            
            return None
            
        except Exception:
            return None

    def get_pending_estabelecimentos(self, limit: int = 1000) -> list:
        """
        Busca estabelecimentos que precisam ser geocodificados
        
        Critérios:
        - Situação cadastral = 2 (ativa)
        - CEP não nulo
        - latitude/longitude nulos (ainda não geocodificado)
        - OU geocoded_at mais antigo que 6 meses (re-geocodificar)
        
        Args:
            limit: Máximo de registros a retornar
        
        Returns:
            Lista de dicts com id, cnpj_completo e cep
        """
        sql = """
            SELECT id, cnpj_completo, cep
            FROM estabelecimentos
            WHERE situacao_cadastral = 2
              AND cep IS NOT NULL
              AND LENGTH(cep) = 8
              AND (
                  latitude IS NULL 
                  OR longitude IS NULL
                  OR geocoded_at IS NULL
                  OR geocoded_at < NOW() - INTERVAL '6 months'
              )
            ORDER BY id
            LIMIT %s
        """
        
        try:
            self.cursor.execute(sql, (limit,))
            rows = self.cursor.fetchall()
            
            return [
                {'id': row[0], 'cnpj_completo': row[1], 'cep': row[2]}
                for row in rows
            ]
        except Exception as e:
            print(f"❌ Erro ao buscar estabelecimentos: {e}")
            return []

    def update_coordinates(self, estabelecimento_id: int, latitude: float, longitude: float):
        """
        Atualiza coordenadas de um estabelecimento
        
        Args:
            estabelecimento_id: ID do registro
            latitude: Latitude
            longitude: Longitude
        """
        sql = """
            UPDATE estabelecimentos
            SET latitude = %s,
                longitude = %s,
                geocoded_at = NOW(),
                updated_at = NOW()
            WHERE id = %s
        """
        
        try:
            self.cursor.execute(sql, (latitude, longitude, estabelecimento_id))
            self.conn.commit()
            self.stats['success'] += 1
        except Exception as e:
            self.conn.rollback()
            print(f"❌ Erro ao atualizar estabelecimento {estabelecimento_id}: {e}")
            self.stats['errors'] += 1

    def mark_as_not_found(self, estabelecimento_id: int):
        """
        Marca estabelecimento como CEP não encontrado
        (seta geocoded_at sem coordenadas para não tentar novamente)
        """
        sql = """
            UPDATE estabelecimentos
            SET geocoded_at = NOW(),
                updated_at = NOW()
            WHERE id = %s
        """
        
        try:
            self.cursor.execute(sql, (estabelecimento_id,))
            self.conn.commit()
            self.stats['not_found'] += 1
        except Exception as e:
            self.conn.rollback()
            print(f"❌ Erro ao marcar estabelecimento {estabelecimento_id}: {e}")
            self.stats['errors'] += 1

    def process_batch(self, batch_size: int = 1000):
        """
        Processa um batch de estabelecimentos pendentes
        
        Args:
            batch_size: Quantidade máxima de registros a processar
        """
        print(f"🔍 Buscando {batch_size} estabelecimentos pendentes...\n")
        
        estabelecimentos = self.get_pending_estabelecimentos(batch_size)
        
        if not estabelecimentos:
            print("✅ Não há estabelecimentos pendentes de geocodificação")
            return

        print(f"📍 Geocodificando {len(estabelecimentos)} estabelecimentos...\n")
        
        for est in tqdm(estabelecimentos, desc="Progresso"):
            cep = est['cep']
            est_id = est['id']
            
            # Geocodifica
            coords = self.geocode_cep(cep)
            
            if coords:
                latitude, longitude = coords
                self.update_coordinates(est_id, latitude, longitude)
            else:
                # Marca como não encontrado para não tentar novamente
                self.mark_as_not_found(est_id)
            
            # Rate limiting
            time.sleep(RATE_LIMIT_DELAY)

        self.print_stats()

    def test_cep(self, cep: str):
        """Testa geocodificação de um CEP específico"""
        print(f"🧪 Testando geocodificação do CEP: {cep}\n")
        
        coords = self.geocode_cep(cep)
        
        if coords:
            latitude, longitude = coords
            print(f"✅ Sucesso!")
            print(f"   Latitude:  {latitude}")
            print(f"   Longitude: {longitude}")
            print(f"   Google Maps: https://www.google.com/maps?q={latitude},{longitude}")
        else:
            print(f"❌ CEP não encontrado ou inválido")

    def print_stats(self):
        """Imprime estatísticas do processamento"""
        total = sum(self.stats.values())
        print(f"\n📊 Estatísticas:")
        print(f"   ✅ Sucesso:        {self.stats['success']}")
        print(f"   ❓ Não encontrado: {self.stats['not_found']}")
        print(f"   ❌ Erros:          {self.stats['errors']}")
        print(f"   ⏭️  Ignorados:      {self.stats['skipped']}")
        print(f"   📦 Total:          {total}")


def main():
    parser = argparse.ArgumentParser(
        description='Geocodificação de CEPs via BrasilAPI'
    )
    parser.add_argument(
        '--batch',
        type=int,
        default=1000,
        help='Quantidade de estabelecimentos a geocodificar (padrão: 1000)'
    )
    parser.add_argument(
        '--cep',
        type=str,
        help='Testa geocodificação de um CEP específico (8 dígitos)'
    )
    args = parser.parse_args()

    print("🌍 Serviço de Geocodificação - BrasilAPI\n")

    service = GeocodeService(DB_CONFIG)
    service.connect()

    try:
        if args.cep:
            # Modo teste: geocodifica um CEP específico
            service.test_cep(args.cep)
        else:
            # Modo batch: processa estabelecimentos pendentes
            service.process_batch(args.batch)

    except KeyboardInterrupt:
        print("\n⚠️  Interrompido pelo usuário")
        service.print_stats()
    finally:
        service.close()


if __name__ == '__main__':
    main()
