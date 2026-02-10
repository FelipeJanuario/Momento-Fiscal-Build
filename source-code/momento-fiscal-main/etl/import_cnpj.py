#!/usr/bin/env python3
"""
Pipeline ETL para importar dados da Receita Federal no PostgreSQL

Uso:
    python import_cnpj.py --limit 100  # Teste com 100 registros
    python import_cnpj.py              # Importa tudo (apenas ativos)
"""

import os
import sys
import csv
import glob
import argparse
import psycopg
import zipfile
import io
from datetime import datetime
from pathlib import Path
from typing import Generator, Dict, Optional
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

CNPJ_PATH = Path("C:/cnpjs")
BATCH_SIZE = 1000

# Mapeamento de campos
EMPRESA_FIELDS = {
    0: 'cnpj_basico',
    1: 'razao_social',
    2: 'natureza_juridica',
    3: 'qualificacao_responsavel',
    4: 'capital_social',
    5: 'porte_empresa',
    6: 'ente_federativo_responsavel'
}

ESTABELECIMENTO_FIELDS = {
    0: 'cnpj_basico',
    1: 'cnpj_ordem',
    2: 'cnpj_dv',
    3: 'identificador_matriz_filial',
    4: 'nome_fantasia',
    5: 'situacao_cadastral',
    6: 'data_situacao_cadastral',
    7: 'motivo_situacao_cadastral',
    10: 'data_inicio_atividade',
    13: 'tipo_logradouro',
    14: 'logradouro',
    15: 'numero',
    16: 'complemento',
    17: 'bairro',
    18: 'cep',
    19: 'uf',
    20: 'municipio',
    21: 'ddd_1',
    22: 'telefone_1',
    23: 'ddd_2',
    24: 'telefone_2',
    25: 'ddd_fax',
    26: 'fax',
    27: 'email',
    11: 'cnae_fiscal_principal',
    12: 'cnae_fiscal_secundaria'
}


class CNPJExtractor:
    """Extract: Lê arquivos CSV da Receita Federal"""

    def __init__(self, base_path: Path):
        self.base_path = base_path

    def find_files(self, pattern: str) -> list:
        """Encontra arquivos por padrão (procura .zip)"""
        # Procura arquivos ZIP que correspondem ao padrão
        zip_pattern = pattern + '.zip'
        files = list(self.base_path.glob(zip_pattern))
        if not files:
            print(f"⚠️  Nenhum arquivo encontrado com padrão: {zip_pattern}")
        return files

    def read_csv(self, filepath: Path, encoding='latin1') -> Generator[list, None, None]:
        """Lê CSV linha por linha (streaming) - suporta .zip"""
        try:
            if filepath.suffix == '.zip':
                # Lê CSV diretamente do ZIP
                with zipfile.ZipFile(filepath, 'r') as zf:
                    # Pega todos os arquivos dentro do ZIP (arquivos da Receita não têm extensão .csv)
                    csv_files = zf.namelist()
                    if not csv_files:
                        print(f"⚠️  Nenhum arquivo encontrado em {filepath.name}")
                        return
                    
                    for csv_name in csv_files:
                        with zf.open(csv_name) as f:
                            # Lê bytes e decodifica para string
                            text_stream = io.TextIOWrapper(f, encoding=encoding, errors='replace')
                            reader = csv.reader(text_stream, delimiter=';')
                            for row in reader:
                                yield row
            else:
                # Lê CSV normal
                with open(filepath, 'r', encoding=encoding, errors='replace') as f:
                    reader = csv.reader(f, delimiter=';')
                    for row in reader:
                        yield row
        except Exception as e:
            print(f"❌ Erro ao ler {filepath.name}: {e}")


class CNPJTransformer:
    """Transform: Limpa e valida dados"""

    @staticmethod
    def parse_empresa(row: list) -> Optional[Dict]:
        """Transforma linha de empresa"""
        if len(row) < 7:
            return None

        try:
            data = {}
            for idx, field in EMPRESA_FIELDS.items():
                value = row[idx].strip() if idx < len(row) else ''
                
                if field == 'capital_social':
                    # Remove vírgula e converte para decimal
                    value = value.replace(',', '.') if value else '0'
                    value = float(value)
                elif field in ['natureza_juridica', 'qualificacao_responsavel', 'porte_empresa']:
                    value = int(value) if value and value.isdigit() else None
                
                data[field] = value if value != '' else None

            return data if data.get('cnpj_basico') and data.get('razao_social') else None
        except Exception as e:
            return None

    @staticmethod
    def parse_estabelecimento(row: list) -> Optional[Dict]:
        """Transforma linha de estabelecimento"""
        if len(row) < 28:
            return None

        try:
            data = {}
            for idx, field in ESTABELECIMENTO_FIELDS.items():
                value = row[idx].strip() if idx < len(row) else ''
                
                # Conversões específicas
                if field == 'situacao_cadastral':
                    value = int(value) if value and value.isdigit() else None
                elif field in ['identificador_matriz_filial', 'motivo_situacao_cadastral', 
                               'municipio', 'cnae_fiscal_principal']:
                    value = int(value) if value and value.isdigit() else None
                elif field in ['data_situacao_cadastral', 'data_inicio_atividade']:
                    # Formato: YYYYMMDD
                    if value and len(value) == 8:
                        value = f"{value[0:4]}-{value[4:6]}-{value[6:8]}"
                    else:
                        value = None
                elif field == 'cep':
                    # Remove formatação
                    value = value.replace('-', '').replace('.', '')
                
                data[field] = value if value != '' else None

            # Monta CNPJ completo
            if data.get('cnpj_basico') and data.get('cnpj_ordem') and data.get('cnpj_dv'):
                data['cnpj_completo'] = f"{data['cnpj_basico']}{data['cnpj_ordem']}{data['cnpj_dv']}"
            else:
                return None

            return data
        except Exception as e:
            return None

    @staticmethod
    def is_active(estabelecimento: Dict) -> bool:
        """Verifica se estabelecimento está ativo"""
        return estabelecimento.get('situacao_cadastral') == 2


class CNPJLoader:
    """Load: Insere dados no PostgreSQL"""

    def __init__(self, db_config: Dict):
        self.db_config = db_config
        self.conn = None
        self.cursor = None

    def connect(self):
        """Conecta ao banco"""
        try:
            conn_string = f"host={self.db_config['host']} port={self.db_config['port']} dbname={self.db_config['database']} user={self.db_config['user']} password={self.db_config['password']}"
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

    def insert_empresas_batch(self, empresas: list):
        """Insere empresas em batch"""
        if not empresas:
            return

        sql = """
            INSERT INTO empresas (
                cnpj_basico, razao_social, natureza_juridica, qualificacao_responsavel,
                capital_social, porte_empresa, ente_federativo_responsavel,
                created_at, updated_at
            ) VALUES (
                %(cnpj_basico)s, %(razao_social)s, %(natureza_juridica)s, %(qualificacao_responsavel)s,
                %(capital_social)s, %(porte_empresa)s, %(ente_federativo_responsavel)s,
                NOW(), NOW()
            )
            ON CONFLICT (cnpj_basico) DO UPDATE SET
                razao_social = EXCLUDED.razao_social,
                updated_at = NOW()
            RETURNING id, cnpj_basico
        """
        try:
            # Insere e retorna IDs
            empresa_ids = {}
            for empresa in empresas:
                self.cursor.execute(sql, empresa)
                result = self.cursor.fetchone()
                if result:
                    empresa_ids[result[1]] = result[0]  # cnpj_basico -> id
            
            self.conn.commit()
            return empresa_ids
        except Exception as e:
            self.conn.rollback()
            print(f"❌ Erro ao inserir empresas: {e}")
            return {}

    def insert_estabelecimentos_batch(self, estabelecimentos: list, empresa_ids: Dict):
        """Insere estabelecimentos em batch"""
        if not estabelecimentos:
            return

        sql = """
            INSERT INTO estabelecimentos (
                empresa_id, cnpj_completo, cnpj_basico, cnpj_ordem, cnpj_dv,
                identificador_matriz_filial, nome_fantasia, situacao_cadastral,
                data_situacao_cadastral, motivo_situacao_cadastral, data_inicio_atividade,
                tipo_logradouro, logradouro, numero, complemento, bairro, cep, uf, municipio,
                ddd_1, telefone_1, ddd_2, telefone_2, ddd_fax, fax, email,
                cnae_fiscal_principal, cnae_fiscal_secundaria,
                created_at, updated_at
            ) VALUES (
                %(empresa_id)s, %(cnpj_completo)s, %(cnpj_basico)s, %(cnpj_ordem)s, %(cnpj_dv)s,
                %(identificador_matriz_filial)s, %(nome_fantasia)s, %(situacao_cadastral)s,
                %(data_situacao_cadastral)s, %(motivo_situacao_cadastral)s, %(data_inicio_atividade)s,
                %(tipo_logradouro)s, %(logradouro)s, %(numero)s, %(complemento)s, %(bairro)s,
                %(cep)s, %(uf)s, %(municipio)s,
                %(ddd_1)s, %(telefone_1)s, %(ddd_2)s, %(telefone_2)s, %(ddd_fax)s, %(fax)s, %(email)s,
                %(cnae_fiscal_principal)s, %(cnae_fiscal_secundaria)s,
                NOW(), NOW()
            )
            ON CONFLICT (cnpj_completo) DO UPDATE SET
                situacao_cadastral = EXCLUDED.situacao_cadastral,
                updated_at = NOW()
        """
        
        # Adiciona empresa_id a cada estabelecimento
        for est in estabelecimentos:
            est['empresa_id'] = empresa_ids.get(est['cnpj_basico'])
        
        # Remove estabelecimentos sem empresa_id
        estabelecimentos = [e for e in estabelecimentos if e.get('empresa_id')]

        try:
            # psycopg3 usa executemany ao invés de execute_batch
            for est in estabelecimentos:
                self.cursor.execute(sql, est)
            self.conn.commit()
        except Exception as e:
            self.conn.rollback()
            print(f"❌ Erro ao inserir estabelecimentos: {e}")


def main():
    parser = argparse.ArgumentParser(description='ETL para importar CNPJs da Receita Federal')
    parser.add_argument('--limit', type=int, help='Limitar número de registros (para teste)')
    parser.add_argument('--cep-prefix', type=str, help='Filtrar apenas CEPs iniciando com este prefixo (ex: 095 para São Caetano)')
    parser.add_argument('--skip-empresas', action='store_true', help='Pular importação de empresas (usar se já estão no banco)')
    parser.add_argument('--start-from', type=int, help='Começar do arquivo N (ex: 7 para Empresas7.zip)', default=0)
    args = parser.parse_args()

    if args.cep_prefix:
        print(f"🚀 Iniciando ETL de CNPJs - REGIÃO CEP {args.cep_prefix}*****\n")
    else:
        print("🚀 Iniciando ETL de CNPJs da Receita Federal\n")

    # Inicializa componentes
    extractor = CNPJExtractor(CNPJ_PATH)
    transformer = CNPJTransformer()
    loader = CNPJLoader(DB_CONFIG)
    loader.connect()

    # Buffers
    empresas_buffer = []
    estabelecimentos_buffer = []
    empresa_ids_cache = {}
    
    total_processados = 0
    total_ativos = 0

    try:
        # Estratégia: Se tem filtro de CEP, processa estabelecimentos primeiro
        # para importar apenas as empresas necessárias
        
        if args.cep_prefix:
            print(f"🎯 Modo FILTRADO: Processando apenas CEPs {args.cep_prefix}*\n")
            
            estabelecimento_files = extractor.find_files("Estabelecimentos*")
            
            if not args.skip_empresas:
                # 1. Primeiro passa: coleta cnpj_basico dos estabelecimentos filtrados
                print("📥 PASSO 1: Identificando empresas da região...")
                empresas_necessarias = set()
                
                for file in estabelecimento_files:
                    print(f"   Escaneando: {file.name}")
                    for row in extractor.read_csv(file):
                        estabelecimento = transformer.parse_estabelecimento(row)
                        if estabelecimento and transformer.is_active(estabelecimento):
                            cep = estabelecimento.get('cep', '')
                            if cep and cep.startswith(args.cep_prefix):
                                empresas_necessarias.add(estabelecimento['cnpj_basico'])
                
                print(f"   ✅ Encontradas {len(empresas_necessarias)} empresas únicas na região\n")
                
                # 2. Importa apenas as empresas necessárias
                print("📥 PASSO 2: Importando empresas da região...")
                empresa_files = extractor.find_files("Empresas*")
                
                for file in empresa_files:
                    print(f"   Processando: {file.name}")
                    for row in extractor.read_csv(file):
                        empresa = transformer.parse_empresa(row)
                        if empresa and empresa['cnpj_basico'] in empresas_necessarias:
                            empresas_buffer.append(empresa)
                            
                            if len(empresas_buffer) >= BATCH_SIZE:
                                ids = loader.insert_empresas_batch(empresas_buffer)
                                empresa_ids_cache.update(ids)
                                empresas_buffer = []
                
                if empresas_buffer:
                    ids = loader.insert_empresas_batch(empresas_buffer)
                    empresa_ids_cache.update(ids)
                
                print(f"✅ {len(empresa_ids_cache)} empresas importadas\n")
            else:
                print("⏭️  Pulando importação de empresas (já existem no banco)\n")
                # Carrega empresa_ids do banco
                loader.cursor.execute("SELECT id, cnpj_basico FROM empresas")
                for row in loader.cursor.fetchall():
                    empresa_ids_cache[row[1]] = row[0]
                print(f"✅ {len(empresa_ids_cache)} empresas carregadas do banco\n")
            
            # 3. Importa estabelecimentos filtrados
            print("📥 PASSO 3: Importando estabelecimentos da região...")
            for file in estabelecimento_files:
                print(f"   Processando: {file.name}")
                for row in tqdm(extractor.read_csv(file), desc="Estabelecimentos"):
                    estabelecimento = transformer.parse_estabelecimento(row)
                    
                    if estabelecimento and transformer.is_active(estabelecimento):
                        cep = estabelecimento.get('cep', '')
                        if cep and cep.startswith(args.cep_prefix):
                            estabelecimentos_buffer.append(estabelecimento)
                            total_ativos += 1
                            
                            if len(estabelecimentos_buffer) >= BATCH_SIZE:
                                loader.insert_estabelecimentos_batch(estabelecimentos_buffer, empresa_ids_cache)
                                estabelecimentos_buffer = []
                    
                    total_processados += 1
                    if args.limit and total_processados >= args.limit:
                        break
                
                if args.limit and total_processados >= args.limit:
                    break
            
            if estabelecimentos_buffer:
                loader.insert_estabelecimentos_batch(estabelecimentos_buffer, empresa_ids_cache)
        
        else:
            # Modo normal: importa tudo
            # 1. Processar Empresas
            print("📥 EXTRACT: Lendo arquivos de Empresas...")
            empresa_files = sorted(extractor.find_files("Empresas*"))
            
            # Filtrar arquivos baseado em --start-from
            if args.start_from > 0:
                empresa_files = [f for f in empresa_files if any(f.stem.endswith(str(i)) for i in range(args.start_from, 100))]
                print(f"   ⏭️  Pulando arquivos 0-{args.start_from-1}, iniciando do arquivo {args.start_from}\n")
            
            for file in empresa_files:
                print(f"   Processando: {file.name}")
                for row in tqdm(extractor.read_csv(file), desc="Empresas"):
                    empresa = transformer.parse_empresa(row)
                    if empresa:
                        empresas_buffer.append(empresa)
                        
                        # Insert em batch
                        if len(empresas_buffer) >= BATCH_SIZE:
                            ids = loader.insert_empresas_batch(empresas_buffer)
                            empresa_ids_cache.update(ids)
                            empresas_buffer = []
                    
                    total_processados += 1
                    if args.limit and total_processados >= args.limit:
                        break
                
                if args.limit and total_processados >= args.limit:
                    break
            
            # Flush empresas restantes
            if empresas_buffer:
                ids = loader.insert_empresas_batch(empresas_buffer)
                empresa_ids_cache.update(ids)

            print(f"✅ {len(empresa_ids_cache)} empresas importadas\n")

            # 2. Processar Estabelecimentos (apenas ATIVOS)
            print("📥 EXTRACT: Lendo arquivos de Estabelecimentos...")
            estabelecimento_files = extractor.find_files("Estabelecimentos*")
            
            total_processados = 0
            
            for file in estabelecimento_files:
                print(f"   Processando: {file.name}")
                for row in tqdm(extractor.read_csv(file), desc="Estabelecimentos"):
                    estabelecimento = transformer.parse_estabelecimento(row)
                    
                    if estabelecimento and transformer.is_active(estabelecimento):
                        estabelecimentos_buffer.append(estabelecimento)
                        total_ativos += 1
                        
                        # Insert em batch
                        if len(estabelecimentos_buffer) >= BATCH_SIZE:
                            loader.insert_estabelecimentos_batch(estabelecimentos_buffer, empresa_ids_cache)
                            estabelecimentos_buffer = []
                    
                    total_processados += 1
                    if args.limit and total_processados >= args.limit:
                        break
                
                if args.limit and total_processados >= args.limit:
                    break
        
        # Flush estabelecimentos restantes
        if estabelecimentos_buffer:
            loader.insert_estabelecimentos_batch(estabelecimentos_buffer, empresa_ids_cache)

        print(f"\n✅ ETL Concluído!")
        print(f"   Total processados: {total_processados}")
        print(f"   Estabelecimentos ativos importados: {total_ativos}")

    except KeyboardInterrupt:
        print("\n⚠️  Interrompido pelo usuário")
    finally:
        loader.close()


if __name__ == '__main__':
    main()
