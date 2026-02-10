#!/usr/bin/env python3
"""
Geocodificação otimizada de CEPs únicos

Ao invés de geocodificar 20M estabelecimentos individualmente,
geocodifica apenas ~2M CEPs únicos e depois propaga para todos estabelecimentos.

Uso:
    python geocode_unique_ceps.py --batch 1000
    python geocode_unique_ceps.py --propagate  # Propaga coordenadas para estabelecimentos
"""

import os
import sys
import time
import argparse
import requests
import psycopg
from pathlib import Path
from typing import Optional, Tuple, Dict
from dotenv import load_dotenv
from tqdm import tqdm

# Reutiliza configuração do geocode_service
from geocode_service import (
    DB_CONFIG,
    VIACEP_BASE_URL,
    NOMINATIM_BASE_URL,
    RATE_LIMIT_DELAY,
    REQUEST_TIMEOUT
)

# Configuração
load_dotenv(Path(__file__).parent / '.env.local')


class UniqueGeocodeService:
    """Geocodificação otimizada de CEPs únicos"""

    def __init__(self, db_config: Dict):
        self.db_config = db_config
        self.conn = None
        self.cursor = None
        self.session = requests.Session()
        self.session.headers.update({
            'User-Agent': 'Momento-Fiscal-ETL/1.0 (contato@momentofiscal.df.gov.br)'
        })
        
        self.stats = {
            'success': 0,
            'not_found': 0,
            'errors': 0
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

    def get_unique_ceps(self, limit: int = 1000, state: str = None) -> list:
        """
        Busca CEPs únicos que precisam ser geocodificados
        
        Critérios:
        - CEPs de estabelecimentos ativos
        - Ainda não geocodificados (sem registro em cep_coordinates)
        - Opcional: filtrar por UF específica
        
        Args:
            limit: Quantidade de CEPs a buscar
            state: Sigla do estado (ex: 'SP', 'DF') ou None para todos
            
        Returns:
            Lista de CEPs (strings de 8 dígitos)
        """
        state_filter = "AND e.uf = %s" if state else ""
        params = [limit] if not state else [state, limit]
        
        sql = f"""
            SELECT DISTINCT e.cep
            FROM estabelecimentos e
            LEFT JOIN cep_coordinates cc ON e.cep = cc.cep
            WHERE e.situacao_cadastral = 2
              AND e.cep IS NOT NULL
              AND LENGTH(e.cep) = 8
              AND cc.cep IS NULL
              {state_filter}
            ORDER BY e.cep
            LIMIT %s
        """
        
        try:
            if state:
                self.cursor.execute(sql, (state, limit))
            else:
                self.cursor.execute(sql, (limit,))
            rows = self.cursor.fetchall()
            return [row[0] for row in rows]
        except Exception as e:
            print(f"❌ Erro ao buscar CEPs únicos: {e}")
            return []

    def count_pending_ceps(self, state: str = None) -> int:
        """Conta CEPs únicos pendentes (opcionalmente por UF)"""
        state_filter = "AND e.uf = %s" if state else ""
        
        sql = f"""
            SELECT COUNT(DISTINCT e.cep)
            FROM estabelecimentos e
            LEFT JOIN cep_coordinates cc ON e.cep = cc.cep
            WHERE e.situacao_cadastral = 2
              AND e.cep IS NOT NULL
              AND LENGTH(e.cep) = 8
              AND cc.cep IS NULL
              {state_filter}
        """
        
        try:
            if state:
                self.cursor.execute(sql, (state,))
            else:
                self.cursor.execute(sql)
            return self.cursor.fetchone()[0]
        except Exception as e:
            print(f"❌ Erro ao contar CEPs: {e}")
            return 0

    def geocode_cep(self, cep: str) -> Optional[Tuple[float, float]]:
        """
        Geocodifica um CEP via ViaCEP + Nominatim
        (Reutiliza lógica do geocode_service.py)
        """
        if not cep or len(cep) != 8 or not cep.isdigit():
            return None

        try:
            # Busca endereço no ViaCEP
            cep_formatado = f"{cep[:5]}-{cep[5:]}"
            viacep_url = f"{VIACEP_BASE_URL}{cep_formatado}/json/"
            
            response = self.session.get(viacep_url, timeout=REQUEST_TIMEOUT)
            
            if response.status_code != 200 or response.json().get('erro'):
                return None
            
            data = response.json()
            
            # Monta endereço completo
            endereco_partes = []
            for field in ['logradouro', 'bairro', 'localidade', 'uf']:
                if data.get(field):
                    endereco_partes.append(data[field])
            endereco_partes.append('Brasil')
            endereco_completo = ', '.join(endereco_partes)
            
            # Geocodifica via Nominatim
            time.sleep(RATE_LIMIT_DELAY)
            coords = self._geocode_nominatim(endereco_completo)
            
            # Fallback: tenta apenas cidade + UF
            if not coords and data.get('localidade') and data.get('uf'):
                endereco_simples = f"{data['localidade']}, {data['uf']}, Brasil"
                time.sleep(RATE_LIMIT_DELAY)
                coords = self._geocode_nominatim(endereco_simples)
            
            return coords
                
        except Exception as e:
            print(f"⚠️  CEP {cep}: {e}")
            return None

    def _geocode_nominatim(self, endereco: str) -> Optional[Tuple[float, float]]:
        """Geocodifica via Nominatim"""
        try:
            params = {
                'q': endereco,
                'format': 'json',
                'limit': 1,
                'addressdetails': 1,
                'countrycodes': 'br'
            }
            
            response = self.session.get(
                NOMINATIM_BASE_URL,
                params=params,
                timeout=REQUEST_TIMEOUT
            )
            
            if response.status_code == 200:
                results = response.json()
                if results:
                    result = results[0]
                    lat = float(result.get('lat'))
                    lon = float(result.get('lon'))
                    
                    # Valida território brasileiro
                    if -33.75 <= lat <= 5.27 and -73.99 <= lon <= -28.84:
                        return (lat, lon)
            
            return None
        except Exception:
            return None

    def save_cep_coordinates(self, cep: str, latitude: float, longitude: float):
        """Salva coordenadas de um CEP na tabela cep_coordinates"""
        sql = """
            INSERT INTO cep_coordinates (cep, latitude, longitude, geocoded_at, created_at, updated_at)
            VALUES (%s, %s, %s, NOW(), NOW(), NOW())
            ON CONFLICT (cep) DO UPDATE SET
                latitude = EXCLUDED.latitude,
                longitude = EXCLUDED.longitude,
                geocoded_at = NOW(),
                updated_at = NOW()
        """
        
        try:
            self.cursor.execute(sql, (cep, latitude, longitude))
            self.conn.commit()
            self.stats['success'] += 1
        except Exception as e:
            self.conn.rollback()
            print(f"❌ Erro ao salvar CEP {cep}: {e}")
            self.stats['errors'] += 1

    def mark_cep_not_found(self, cep: str):
        """Marca CEP como não encontrado"""
        sql = """
            INSERT INTO cep_coordinates (cep, geocoded_at, created_at, updated_at)
            VALUES (%s, NOW(), NOW(), NOW())
            ON CONFLICT (cep) DO UPDATE SET
                geocoded_at = NOW(),
                updated_at = NOW()
        """
        
        try:
            self.cursor.execute(sql, (cep,))
            self.conn.commit()
            self.stats['not_found'] += 1
        except Exception as e:
            self.conn.rollback()
            self.stats['errors'] += 1

    def process_unique_ceps(self, batch_size: int = 1000, state: str = None):
        """Geocodifica CEPs únicos (opcionalmente filtrado por UF)"""
        state_label = f" do {state}" if state else ""
        total_pending = self.count_pending_ceps(state)
        print(f"🔍 Total de CEPs únicos pendentes{state_label}: {total_pending:,}\n")
        
        if total_pending == 0:
            print(f"✅ Não há CEPs pendentes{state_label}")
            return

        ceps = self.get_unique_ceps(batch_size, state)
        
        if not ceps:
            print(f"✅ Não há CEPs para processar neste batch{state_label}")
            return

        print(f"📍 Geocodificando {len(ceps)} CEPs únicos{state_label}...\n")
        
        for cep in tqdm(ceps, desc="Progresso"):
            coords = self.geocode_cep(cep)
            
            if coords:
                latitude, longitude = coords
                self.save_cep_coordinates(cep, latitude, longitude)
            else:
                self.mark_cep_not_found(cep)
            
            # Rate limiting
            time.sleep(RATE_LIMIT_DELAY)

        self.print_stats()

    def propagate_to_estabelecimentos(self, state: str = None):
        """Propaga coordenadas dos CEPs para todos estabelecimentos (opcionalmente por UF)"""
        state_label = f" do {state}" if state else ""
        state_filter = "AND e.uf = %s" if state else ""
        
        print(f"🔄 Propagando coordenadas para estabelecimentos{state_label}...\n")
        
        sql = f"""
            UPDATE estabelecimentos e
            SET latitude = cc.latitude,
                longitude = cc.longitude,
                geocoded_at = cc.geocoded_at,
                updated_at = NOW()
            FROM cep_coordinates cc
            WHERE e.cep = cc.cep
              AND cc.latitude IS NOT NULL
              AND cc.longitude IS NOT NULL
              AND (e.latitude IS NULL OR e.geocoded_at < cc.geocoded_at)
              {state_filter}
        """
        
        try:
            if state:
                self.cursor.execute(sql, (state,))
            else:
                self.cursor.execute(sql)
            affected = self.cursor.rowcount
            self.conn.commit()
            print(f"✅ {affected:,} estabelecimentos atualizados com coordenadas")
        except Exception as e:
            self.conn.rollback()
            print(f"❌ Erro ao propagar coordenadas: {e}")

    def print_stats(self):
        """Imprime estatísticas"""
        total = sum(self.stats.values())
        print(f"\n📊 Estatísticas:")
        print(f"   ✅ Sucesso:        {self.stats['success']}")
        print(f"   ❓ Não encontrado: {self.stats['not_found']}")
        print(f"   ❌ Erros:          {self.stats['errors']}")
        print(f"   📦 Total:          {total}")


def create_cep_coordinates_table(service: UniqueGeocodeService):
    """Cria tabela cep_coordinates se não existir"""
    sql = """
        CREATE TABLE IF NOT EXISTS cep_coordinates (
            id SERIAL PRIMARY KEY,
            cep VARCHAR(8) NOT NULL UNIQUE,
            latitude DECIMAL(10, 8),
            longitude DECIMAL(11, 8),
            geocoded_at TIMESTAMP,
            created_at TIMESTAMP NOT NULL,
            updated_at TIMESTAMP NOT NULL
        );
        
        CREATE INDEX IF NOT EXISTS idx_cep_coordinates_cep ON cep_coordinates(cep);
        CREATE INDEX IF NOT EXISTS idx_cep_coordinates_geocoded ON cep_coordinates(geocoded_at) WHERE latitude IS NOT NULL;
    """
    
    try:
        service.cursor.execute(sql)
        service.conn.commit()
        print("✅ Tabela cep_coordinates criada/verificada\n")
    except Exception as e:
        print(f"❌ Erro ao criar tabela: {e}")
        sys.exit(1)


def main():
    parser = argparse.ArgumentParser(
        description='Geocodificação otimizada de CEPs únicos'
    )
    parser.add_argument(
        '--batch',
        type=int,
        default=1000,
        help='Quantidade de CEPs únicos a geocodificar (padrão: 1000)'
    )
    parser.add_argument(
        '--propagate',
        action='store_true',
        help='Propaga coordenadas dos CEPs para estabelecimentos'
    )
    parser.add_argument(
        '--state',
        type=str,
        default=None,
        help='Filtrar por UF específica (ex: SP, DF, RJ)'
    )
    args = parser.parse_args()

    state_label = f" - {args.state}" if args.state else ""
    print(f"🌍 Geocodificação Otimizada - CEPs Únicos{state_label}\n")

    service = UniqueGeocodeService(DB_CONFIG)
    service.connect()

    # Cria tabela se não existir
    create_cep_coordinates_table(service)

    try:
        if args.propagate:
            # Propaga coordenadas para estabelecimentos
            service.propagate_to_estabelecimentos(args.state)
        else:
            # Geocodifica CEPs únicos
            service.process_unique_ceps(args.batch, args.state)

    except KeyboardInterrupt:
        print("\n⚠️  Interrompido pelo usuário")
        service.print_stats()
    finally:
        service.close()


if __name__ == '__main__':
    main()
