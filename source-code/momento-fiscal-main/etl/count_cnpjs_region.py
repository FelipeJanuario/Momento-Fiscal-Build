#!/usr/bin/env python3
"""
Contador de CNPJs por região (filtro por CEP)

Uso:
    python count_cnpjs_region.py --cep-prefix 095  # São Caetano do Sul
    python count_cnpjs_region.py --cep-prefix 01   # São Paulo capital
"""

import os
import csv
import glob
import argparse
import zipfile
import io
from pathlib import Path
from collections import defaultdict
from tqdm import tqdm

CNPJ_PATH = Path("C:/cnpjs")

# Índice do campo CEP no CSV de Estabelecimentos (posição 18, 0-indexed)
CEP_INDEX = 18
SITUACAO_CADASTRAL_INDEX = 5  # 2 = Ativa


def count_by_cep_prefix(cep_prefix: str, limit: int = None):
    """
    Conta estabelecimentos por prefixo de CEP
    
    Args:
        cep_prefix: Prefixo do CEP (ex: "095" para São Caetano)
        limit: Limitar quantidade de arquivos processados (para teste)
    """
    print(f"🔍 Buscando CNPJs com CEP iniciando em: {cep_prefix}\n")
    
    stats = {
        'total_linhas': 0,
        'ativos_regiao': 0,
        'inativos_regiao': 0,
        'ceps_encontrados': defaultdict(int),  # CEP -> quantidade
        'situacoes': defaultdict(int)  # situacao_cadastral -> quantidade
    }
    
    # Encontra arquivos de Estabelecimentos
    pattern = CNPJ_PATH / "Estabelecimentos*.zip"
    files = sorted(glob.glob(str(pattern)))
    
    if not files:
        print(f"❌ Nenhum arquivo encontrado em: {pattern}")
        return
    
    if limit:
        files = files[:limit]
    
    print(f"📁 Arquivos a processar: {len(files)}\n")
    
    for idx, filepath in enumerate(files, 1):
        filepath = Path(filepath)
        print(f"\n[{idx}/{len(files)}] 📄 Processando: {filepath.name}")
        
        try:
            with zipfile.ZipFile(filepath, 'r') as zf:
                csv_files = zf.namelist()
                print(f"      CSV dentro do ZIP: {csv_files[0] if csv_files else 'nenhum'}")
                
                for csv_name in csv_files:
                    with zf.open(csv_name) as f:
                        text_stream = io.TextIOWrapper(f, encoding='latin1', errors='replace')
                        reader = csv.reader(text_stream, delimiter=';')
                        
                        linhas_arquivo = 0
                        for row in reader:
                            stats['total_linhas'] += 1
                            linhas_arquivo += 1
                            
                            # Print a cada 100k linhas
                            if linhas_arquivo % 100000 == 0:
                                print(f"      ⏳ {linhas_arquivo:,} linhas... (Ativos região: {stats['ativos_regiao']:,})")
                            
                            if len(row) > CEP_INDEX:
                                cep = row[CEP_INDEX].strip()
                                situacao = row[SITUACAO_CADASTRAL_INDEX].strip() if len(row) > SITUACAO_CADASTRAL_INDEX else ''
                                
                                # Verifica se CEP começa com o prefixo
                                if cep.startswith(cep_prefix):
                                    # Remove zeros à esquerda da situação cadastral
                                    situacao_int = situacao.lstrip('0') if situacao else ''
                                    
                                    if situacao_int == '2':  # Ativa
                                        stats['ativos_regiao'] += 1
                                        stats['ceps_encontrados'][cep] += 1
                                    else:
                                        stats['inativos_regiao'] += 1
                                    
                                    stats['situacoes'][situacao] += 1
                        
                        print(f"      ✅ {linhas_arquivo:,} linhas processadas | Ativos na região: {stats['ativos_regiao']:,}")
                                    
        except Exception as e:
            print(f"      ❌ Erro ao processar arquivo: {e}")
    
    # Resultados
    print(f"\n{'='*60}")
    print(f"📊 RESULTADOS - CEPs iniciando com '{cep_prefix}'")
    print(f"{'='*60}")
    print(f"\n📈 Estatísticas gerais:")
    print(f"   Total de linhas processadas: {stats['total_linhas']:,}")
    print(f"   Estabelecimentos ATIVOS na região: {stats['ativos_regiao']:,}")
    print(f"   Estabelecimentos INATIVOS na região: {stats['inativos_regiao']:,}")
    print(f"   Total na região: {stats['ativos_regiao'] + stats['inativos_regiao']:,}")
    
    print(f"\n📍 CEPs únicos encontrados: {len(stats['ceps_encontrados'])}")
    
    # Top 10 CEPs mais frequentes
    if stats['ceps_encontrados']:
        print(f"\n🏆 Top 10 CEPs com mais empresas:")
        sorted_ceps = sorted(stats['ceps_encontrados'].items(), key=lambda x: -x[1])[:10]
        for cep, count in sorted_ceps:
            cep_formatted = f"{cep[:5]}-{cep[5:]}" if len(cep) == 8 else cep
            print(f"   {cep_formatted}: {count:,} estabelecimentos")
    
    print(f"\n📋 Situações cadastrais na região:")
    situacao_nomes = {
        '1': 'Nula',
        '2': 'Ativa',
        '3': 'Suspensa',
        '4': 'Inapta',
        '8': 'Baixada'
    }
    for sit, count in sorted(stats['situacoes'].items()):
        nome = situacao_nomes.get(sit, f'Código {sit}')
        print(f"   {nome}: {count:,}")
    
    # Estimativa de custo SERPRO
    print(f"\n💰 Estimativa para consulta SERPRO:")
    print(f"   CNPJs ativos a consultar: {stats['ativos_regiao']:,}")
    print(f"   (Custo depende do contrato SERPRO)")
    
    return stats


def main():
    parser = argparse.ArgumentParser(description='Contador de CNPJs por região')
    parser.add_argument(
        '--cep-prefix',
        type=str,
        default='095',
        help='Prefixo do CEP para filtrar (padrão: 095 = São Caetano do Sul)'
    )
    parser.add_argument(
        '--limit',
        type=int,
        help='Limitar número de arquivos ZIP a processar (para teste)'
    )
    args = parser.parse_args()
    
    count_by_cep_prefix(args.cep_prefix, args.limit)


if __name__ == '__main__':
    main()
