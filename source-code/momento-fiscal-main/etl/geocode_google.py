#!/usr/bin/env python3
"""
Geocodificação via Google Geocoding API
Otimizado para CEPs únicos - geocodifica apenas CEPs distintos e propaga para estabelecimentos
"""

import os
import sys
import time
import argparse
from decimal import Decimal
from datetime import datetime, timedelta
from dotenv import load_dotenv
import psycopg
import googlemaps
from tqdm import tqdm

# Carrega variáveis de ambiente
load_dotenv('.env.local')

# Configurações do banco
DB_CONFIG = {
    'host': os.getenv('DB_HOST', 'localhost'),
    'port': os.getenv('DB_PORT', '5434'),
    'dbname': os.getenv('DB_NAME', 'momento_fiscal_api_production'),
    'user': os.getenv('DB_USER', 'postgres'),
    'password': os.getenv('DB_PASSWORD', 'TECHbyops30!')
}

# Google API Key
GOOGLE_API_KEY = os.getenv('GOOGLE_GEOCODING_API_KEY')

# Configurações de geocodificação
GEOCODE_CACHE_MONTHS = 6
BRASIL_LAT_RANGE = (-33.75, 5.27)
BRASIL_LNG_RANGE = (-73.99, -28.84)


class GoogleGeocoder:
    """Serviço de geocodificação via Google Maps API"""
    
    def __init__(self, api_key: str):
        if not api_key:
            raise ValueError("GOOGLE_GEOCODING_API_KEY não configurada no .env.local")
        
        self.gmaps = googlemaps.Client(key=api_key)
        self.stats = {
            'sucesso': 0,
            'nao_encontrado': 0,
            'erro': 0
        }
    
    def geocode_cep(self, cep: str) -> tuple[Decimal, Decimal] | None:
        """
        Geocodifica um CEP brasileiro via Google Geocoding API
        
        Args:
            cep: CEP com 8 dígitos (sem hífen)
        
        Returns:
            (latitude, longitude) ou None se não encontrado
        """
        try:
            # Formata CEP para busca
            cep_formatted = f"{cep[:5]}-{cep[5:]}"
            query = f"{cep_formatted}, Brasil"
            
            # Geocodifica via Google
            result = self.gmaps.geocode(query, region='br')
            
            if not result:
                self.stats['nao_encontrado'] += 1
                return None
            
            # Extrai coordenadas
            location = result[0]['geometry']['location']
            lat = Decimal(str(location['lat']))
            lng = Decimal(str(location['lng']))
            
            # Valida se está no Brasil
            if not self._is_in_brazil(lat, lng):
                self.stats['nao_encontrado'] += 1
                return None
            
            self.stats['sucesso'] += 1
            return (lat, lng)
            
        except googlemaps.exceptions.ApiError as e:
            print(f"\n❌ Erro na API do Google: {e}")
            self.stats['erro'] += 1
            return None
        except Exception as e:
            print(f"\n❌ Erro ao geocodificar CEP {cep}: {e}")
            self.stats['erro'] += 1
            return None
    
    def _is_in_brazil(self, lat: Decimal, lng: Decimal) -> bool:
        """Valida se coordenadas estão dentro do território brasileiro"""
        return (BRASIL_LAT_RANGE[0] <= lat <= BRASIL_LAT_RANGE[1] and
                BRASIL_LNG_RANGE[0] <= lng <= BRASIL_LNG_RANGE[1])
    
    def print_stats(self):
        """Exibe estatísticas de geocodificação"""
        total = sum(self.stats.values())
        if total == 0:
            return
        
        print(f"\n📊 Estatísticas:")
        print(f"   ✅ Sucesso:        {self.stats['sucesso']:6d}")
        print(f"   ❓ Não encontrado: {self.stats['nao_encontrado']:6d}")
        print(f"   ❌ Erros:          {self.stats['erro']:6d}")
        print(f"   📦 Total:          {total:6d}")


def ensure_cep_coordinates_table(conn):
    """Garante que a tabela cep_coordinates existe"""
    with conn.cursor() as cur:
        cur.execute("""
            CREATE TABLE IF NOT EXISTS cep_coordinates (
                id SERIAL PRIMARY KEY,
                cep VARCHAR(8) NOT NULL UNIQUE,
                latitude DECIMAL(10, 8),
                longitude DECIMAL(11, 8),
                geocoded_at TIMESTAMP,
                created_at TIMESTAMP DEFAULT NOW(),
                updated_at TIMESTAMP DEFAULT NOW()
            );
            
            CREATE INDEX IF NOT EXISTS idx_cep_coordinates_cep 
                ON cep_coordinates(cep);
            CREATE INDEX IF NOT EXISTS idx_cep_coordinates_lat_lng 
                ON cep_coordinates(latitude, longitude);
        """)
        conn.commit()


def get_unique_ceps_to_geocode(conn, batch_size: int) -> list[str]:
    """
    Busca CEPs únicos que precisam ser geocodificados
    
    Critérios:
    1. Estabelecimentos ativos (situacao_cadastral = '2')
    2. CEP válido (8 dígitos)
    3. CEP ainda não geocodificado OU geocodificação expirada
    """
    cache_expiry = datetime.now() - timedelta(days=GEOCODE_CACHE_MONTHS * 30)
    
    with conn.cursor() as cur:
        cur.execute("""
            SELECT DISTINCT e.cep
            FROM estabelecimentos e
            LEFT JOIN cep_coordinates c ON e.cep = c.cep
            WHERE e.situacao_cadastral = '2'
              AND e.cep IS NOT NULL
              AND LENGTH(e.cep) = 8
              AND (
                  c.cep IS NULL 
                  OR c.geocoded_at IS NULL
                  OR c.geocoded_at < %s
              )
            ORDER BY e.cep
            LIMIT %s
        """, (cache_expiry, batch_size))
        
        return [row[0] for row in cur.fetchall()]


def geocode_unique_ceps(batch_size: int = 1000):
    """Geocodifica CEPs únicos via Google Geocoding API"""
    
    print(f"\n🌍 Iniciando geocodificação via Google Maps API")
    print(f"📦 Lote: {batch_size:,} CEPs únicos")
    print(f"⚡ Rate limit: 50 req/s (Google API padrão)\n")
    
    # Conecta ao banco
    conn = psycopg.connect(**DB_CONFIG)
    print(f"✅ Conectado ao banco: {DB_CONFIG['dbname']}")
    
    # Garante que a tabela existe
    ensure_cep_coordinates_table(conn)
    
    # Busca CEPs para geocodificar
    ceps = get_unique_ceps_to_geocode(conn, batch_size)
    
    if not ceps:
        print("✅ Todos os CEPs já estão geocodificados!")
        conn.close()
        return
    
    print(f"📍 {len(ceps)} CEPs únicos para geocodificar\n")
    
    # Inicializa geocoder
    geocoder = GoogleGeocoder(GOOGLE_API_KEY)
    
    # Processa CEPs
    start_time = time.time()
    
    with conn.cursor() as cur:
        for i, cep in enumerate(tqdm(ceps, desc="Geocodificando CEPs")):
            coords = geocoder.geocode_cep(cep)
            
            # Rate limiting: 50 req/s (dentro do limite do Google)
            if i < len(ceps) - 1:  # Não espera no último
                time.sleep(0.02)
            
            if coords:
                lat, lng = coords
                # Insere ou atualiza na tabela de cache
                cur.execute("""
                    INSERT INTO cep_coordinates (cep, latitude, longitude, geocoded_at, updated_at)
                    VALUES (%s, %s, %s, NOW(), NOW())
                    ON CONFLICT (cep) 
                    DO UPDATE SET 
                        latitude = EXCLUDED.latitude,
                        longitude = EXCLUDED.longitude,
                        geocoded_at = NOW(),
                        updated_at = NOW()
                """, (cep, lat, lng))
            else:
                # Marca como tentado (sem coordenadas) para não tentar novamente
                cur.execute("""
                    INSERT INTO cep_coordinates (cep, geocoded_at, updated_at)
                    VALUES (%s, NOW(), NOW())
                    ON CONFLICT (cep) 
                    DO UPDATE SET 
                        geocoded_at = NOW(),
                        updated_at = NOW()
                """, (cep,))
            
            # Commit a cada 100 CEPs
            if (geocoder.stats['sucesso'] + geocoder.stats['nao_encontrado'] + geocoder.stats['erro']) % 100 == 0:
                conn.commit()
    
    conn.commit()
    
    elapsed = time.time() - start_time
    
    # Exibe estatísticas
    geocoder.print_stats()
    print(f"\n⏱️  Tempo total: {elapsed:.1f}s")
    print(f"⚡ Taxa: {len(ceps)/elapsed:.1f} CEPs/segundo")
    
    conn.close()


def propagate_coordinates():
    """
    Propaga coordenadas da tabela cep_coordinates para estabelecimentos
    Atualiza latitude/longitude/geocoded_at de todos estabelecimentos que possuem
    um CEP com coordenadas no cache
    """
    
    print(f"\n🔄 Propagando coordenadas de CEPs para estabelecimentos...")
    
    conn = psycopg.connect(**DB_CONFIG)
    print(f"✅ Conectado ao banco: {DB_CONFIG['dbname']}")
    
    with conn.cursor() as cur:
        # Conta quantos estabelecimentos serão atualizados
        cur.execute("""
            SELECT COUNT(*)
            FROM estabelecimentos e
            INNER JOIN cep_coordinates c ON e.cep = c.cep
            WHERE e.situacao_cadastral = '2'
              AND c.latitude IS NOT NULL
              AND c.longitude IS NOT NULL
              AND (
                  e.latitude IS NULL 
                  OR e.longitude IS NULL
                  OR e.geocoded_at IS NULL
                  OR e.geocoded_at < c.geocoded_at
              )
        """)
        
        count = cur.fetchone()[0]
        
        if count == 0:
            print("✅ Todos os estabelecimentos já possuem coordenadas atualizadas!")
            conn.close()
            return
        
        print(f"📍 Atualizando {count:,} estabelecimentos...\n")
        
        # Propaga coordenadas
        start_time = time.time()
        
        cur.execute("""
            UPDATE estabelecimentos e
            SET 
                latitude = c.latitude,
                longitude = c.longitude,
                geocoded_at = c.geocoded_at,
                updated_at = NOW()
            FROM cep_coordinates c
            WHERE e.cep = c.cep
              AND e.situacao_cadastral = '2'
              AND c.latitude IS NOT NULL
              AND c.longitude IS NOT NULL
              AND (
                  e.latitude IS NULL 
                  OR e.longitude IS NULL
                  OR e.geocoded_at IS NULL
                  OR e.geocoded_at < c.geocoded_at
              )
        """)
        
        conn.commit()
        
        elapsed = time.time() - start_time
        
        print(f"✅ {count:,} estabelecimentos atualizados")
        print(f"⏱️  Tempo: {elapsed:.1f}s")
    
    conn.close()


def main():
    parser = argparse.ArgumentParser(
        description='Geocodifica CEPs via Google Maps API (otimizado para CEPs únicos)'
    )
    parser.add_argument(
        '--batch',
        type=int,
        help='Quantidade de CEPs únicos para geocodificar (padrão: 1000)'
    )
    parser.add_argument(
        '--propagate',
        action='store_true',
        help='Propaga coordenadas de CEPs para estabelecimentos'
    )
    
    args = parser.parse_args()
    
    if args.propagate:
        propagate_coordinates()
    elif args.batch:
        geocode_unique_ceps(args.batch)
    else:
        # Padrão: geocodifica 1000 CEPs
        geocode_unique_ceps(1000)


if __name__ == '__main__':
    main()
