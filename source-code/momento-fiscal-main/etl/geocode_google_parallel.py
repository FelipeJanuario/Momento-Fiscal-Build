#!/usr/bin/env python3
"""
Geocodificação PARALELA via Google Geocoding API
Otimizado para alta performance com múltiplas threads e batch inserts

Performance esperada: 30-50 CEPs/segundo (vs 2.6 anterior)
"""

import os
import sys
import time
import argparse
from decimal import Decimal
from datetime import datetime, timedelta
from concurrent.futures import ThreadPoolExecutor, as_completed
from queue import Queue
from threading import Lock
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

# Configurações de performance
MAX_WORKERS = 20  # Threads simultâneas (ajustar conforme API limit)
BATCH_INSERT_SIZE = 5000  # Acumula 5k resultados antes de inserir
GEOCODE_CACHE_MONTHS = 6
BRASIL_LAT_RANGE = (-33.75, 5.27)
BRASIL_LNG_RANGE = (-73.99, -28.84)


class ParallelGeocoder:
    """Geocodificador paralelo com batch inserts"""
    
    def __init__(self, api_key: str, max_workers: int = MAX_WORKERS):
        if not api_key:
            raise ValueError("GOOGLE_GEOCODING_API_KEY não configurada")
        
        self.gmaps = googlemaps.Client(key=api_key)
        self.max_workers = max_workers
        self.buffer = []
        self.buffer_lock = Lock()
        
        self.stats = {
            'sucesso': 0,
            'nao_encontrado': 0,
            'erro': 0
        }
        self.stats_lock = Lock()
    
    def geocode_cep(self, cep: str) -> dict:
        """
        Geocodifica um CEP e retorna dict para batch insert
        
        Returns:
            {'cep': str, 'lat': Decimal, 'lng': Decimal, 'success': bool}
        """
        try:
            cep_formatted = f"{cep[:5]}-{cep[5:]}"
            query = f"{cep_formatted}, Brasil"
            
            result = self.gmaps.geocode(query, region='br')
            
            if not result:
                with self.stats_lock:
                    self.stats['nao_encontrado'] += 1
                return {'cep': cep, 'lat': None, 'lng': None, 'success': False}
            
            location = result[0]['geometry']['location']
            lat = Decimal(str(location['lat']))
            lng = Decimal(str(location['lng']))
            
            # Valida se está no Brasil
            if not self._is_in_brazil(lat, lng):
                with self.stats_lock:
                    self.stats['nao_encontrado'] += 1
                return {'cep': cep, 'lat': None, 'lng': None, 'success': False}
            
            with self.stats_lock:
                self.stats['sucesso'] += 1
            
            return {'cep': cep, 'lat': lat, 'lng': lng, 'success': True}
            
        except Exception as e:
            with self.stats_lock:
                self.stats['erro'] += 1
            return {'cep': cep, 'lat': None, 'lng': None, 'success': False}
    
    def _is_in_brazil(self, lat: Decimal, lng: Decimal) -> bool:
        """Valida se coordenadas estão no Brasil"""
        return (BRASIL_LAT_RANGE[0] <= lat <= BRASIL_LAT_RANGE[1] and
                BRASIL_LNG_RANGE[0] <= lng <= BRASIL_LNG_RANGE[1])
    
    def add_to_buffer(self, result: dict):
        """Adiciona resultado ao buffer (thread-safe)"""
        with self.buffer_lock:
            self.buffer.append(result)
    
    def get_buffer(self) -> list:
        """Retorna e limpa buffer (thread-safe)"""
        with self.buffer_lock:
            results = self.buffer.copy()
            self.buffer.clear()
            return results
    
    def print_stats(self):
        """Exibe estatísticas"""
        total = sum(self.stats.values())
        if total == 0:
            return
        
        print(f"\n📊 Estatísticas finais:")
        print(f"   ✅ Sucesso:        {self.stats['sucesso']:8,d}")
        print(f"   ❓ Não encontrado: {self.stats['nao_encontrado']:8,d}")
        print(f"   ❌ Erros:          {self.stats['erro']:8,d}")
        print(f"   📦 Total:          {total:8,d}")


def batch_insert_coordinates(conn, results: list):
    """
    Insere ou atualiza múltiplos CEPs de uma vez (bulk operation)
    
    Args:
        conn: Conexão psycopg
        results: Lista de dicts {'cep': str, 'lat': Decimal, 'lng': Decimal}
    """
    if not results:
        return
    
    with conn.cursor() as cur:
        # Prepara valores para bulk insert
        values = []
        for r in results:
            if r['lat'] is not None:
                values.append((r['cep'], r['lat'], r['lng']))
            else:
                # Marca como tentado (sem coordenadas)
                values.append((r['cep'], None, None))
        
        # Bulk insert com ON CONFLICT
        cur.executemany("""
            INSERT INTO cep_coordinates (cep, latitude, longitude, geocoded_at, updated_at)
            VALUES (%s, %s, %s, NOW(), NOW())
            ON CONFLICT (cep) 
            DO UPDATE SET 
                latitude = EXCLUDED.latitude,
                longitude = EXCLUDED.longitude,
                geocoded_at = NOW(),
                updated_at = NOW()
        """, values)
    
    conn.commit()


def ensure_cep_coordinates_table(conn):
    """Garante que a tabela existe"""
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
    """Busca CEPs únicos para geocodificar"""
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


def geocode_parallel(batch_size: int = 20000, max_workers: int = MAX_WORKERS):
    """
    Geocodifica CEPs em paralelo com batch inserts
    
    Args:
        batch_size: Quantidade de CEPs a processar
        max_workers: Número de threads simultâneas
    """
    
    print(f"\n🚀 Geocodificação PARALELA via Google Maps API")
    print(f"📦 Lote: {batch_size:,} CEPs únicos")
    print(f"🔀 Threads: {max_workers}")
    print(f"💾 Batch insert: a cada {BATCH_INSERT_SIZE:,} resultados\n")
    
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
    
    print(f"📍 {len(ceps):,} CEPs únicos para geocodificar\n")
    
    # Inicializa geocoder
    geocoder = ParallelGeocoder(GOOGLE_API_KEY, max_workers)
    
    # Processa CEPs em paralelo
    start_time = time.time()
    processed = 0
    
    with ThreadPoolExecutor(max_workers=max_workers) as executor:
        # Submete todas as tarefas
        futures = {executor.submit(geocoder.geocode_cep, cep): cep for cep in ceps}
        
        # Progress bar
        with tqdm(total=len(ceps), desc="Geocodificando CEPs") as pbar:
            for future in as_completed(futures):
                result = future.result()
                geocoder.add_to_buffer(result)
                processed += 1
                pbar.update(1)
                
                # Batch insert quando buffer atingir o limite
                if len(geocoder.buffer) >= BATCH_INSERT_SIZE:
                    batch_results = geocoder.get_buffer()
                    batch_insert_coordinates(conn, batch_results)
    
    # Insere resultados restantes no buffer
    remaining = geocoder.get_buffer()
    if remaining:
        batch_insert_coordinates(conn, remaining)
    
    elapsed = time.time() - start_time
    
    # Exibe estatísticas
    geocoder.print_stats()
    print(f"\n⏱️  Tempo total: {elapsed:.1f}s ({elapsed/60:.1f} min)")
    print(f"⚡ Taxa: {len(ceps)/elapsed:.1f} CEPs/segundo")
    print(f"🚀 Speedup: {(len(ceps)/elapsed) / 2.6:.1f}x mais rápido que versão anterior")
    
    conn.close()


def propagate_coordinates():
    """Propaga coordenadas para estabelecimentos"""
    
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
        description='Geocodifica CEPs via Google Maps API (VERSÃO PARALELA)'
    )
    parser.add_argument(
        '--batch',
        type=int,
        help='Quantidade de CEPs únicos para geocodificar (padrão: 20000)'
    )
    parser.add_argument(
        '--workers',
        type=int,
        default=MAX_WORKERS,
        help=f'Número de threads paralelas (padrão: {MAX_WORKERS})'
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
        geocode_parallel(args.batch, args.workers)
    else:
        # Padrão: geocodifica 20k CEPs
        geocode_parallel(20000, args.workers)


if __name__ == '__main__':
    main()
