# Importação Completa de CNPJs da Receita Federal
# Importa TODAS empresas e estabelecimentos ativos do Brasil

param(
    [int]$Limit = 0,  # 0 = sem limite (todos)
    [switch]$TestMode  # Modo teste: apenas 1000 registros
)

$ErrorActionPreference = "Stop"
function Write-Success { Write-Host $args -ForegroundColor Green }
function Write-Info { Write-Host $args -ForegroundColor Cyan }
function Write-Error { Write-Host $args -ForegroundColor Red }

$ETL_PATH = "c:\momento-fiscal-transferencia\source-code\momento-fiscal-main\etl"

Write-Info "============================================"
Write-Info "  IMPORTAÇÃO COMPLETA DE CNPJs - RF      "
Write-Info "============================================"
Write-Host ""

# Ir para diretório do ETL
Set-Location $ETL_PATH

# =============================================================================
# ETAPA 1: Verificar arquivos da Receita Federal
# =============================================================================
Write-Info "[1/4] Verificando arquivos da Receita Federal..."
Write-Host ""

if (-not (Test-Path "C:\cnpjs")) {
    Write-Error "Pasta C:\cnpjs não encontrada!"
    Write-Host "Faça download dos arquivos em: https://dados.gov.br/dados/conjuntos-dados/cadastro-nacional-da-pessoa-juridica---cnpj" -ForegroundColor Yellow
    exit 1
}

$empresasFiles = Get-ChildItem "C:\cnpjs\Empresas*.zip"
$estabelecimentosFiles = Get-ChildItem "C:\cnpjs\Estabelecimentos*.zip"

Write-Success "✓ Empresas: $($empresasFiles.Count) arquivos ZIP"
Write-Success "✓ Estabelecimentos: $($estabelecimentosFiles.Count) arquivos ZIP"

if ($empresasFiles.Count -eq 0 -or $estabelecimentosFiles.Count -eq 0) {
    Write-Error "Arquivos faltando! Certifique-se de ter todos os ZIPs da Receita Federal em C:\cnpjs\"
    exit 1
}

Write-Host ""

# =============================================================================
# ETAPA 2: Verificar estado atual do banco
# =============================================================================
Write-Info "[2/4] Verificando estado atual do banco..."
Write-Host ""

$checkScript = @'
import psycopg
conn = psycopg.connect("host=localhost port=5434 dbname=momento_fiscal_api_production user=postgres password=TECHbyops30!")
cur = conn.cursor()

cur.execute("SELECT COUNT(*) FROM empresas")
empresas = cur.fetchone()[0]

cur.execute("SELECT COUNT(*) FROM estabelecimentos")
estabs = cur.fetchone()[0]

cur.execute("SELECT COUNT(*) FROM estabelecimentos WHERE situacao_cadastral=2")
ativos = cur.fetchone()[0]

print(f"Empresas no banco: {empresas:,}")
print(f"Estabelecimentos no banco: {estabs:,}")
print(f"  └─ Ativos: {ativos:,}")

conn.close()
'@

$tempFile = [System.IO.Path]::GetTempFileName() + ".py"
$checkScript | Out-File -FilePath $tempFile -Encoding UTF8
python $tempFile
Remove-Item $tempFile

Write-Host ""

# =============================================================================
# ETAPA 3: Importar CNPJs
# =============================================================================
Write-Info "[3/4] Iniciando importação..."
Write-Host ""

if ($TestMode) {
    Write-Host "⚠️  MODO TESTE: Importando apenas 1.000 registros" -ForegroundColor Yellow
    $Limit = 1000
}

if ($Limit -gt 0) {
    Write-Host "Limite: $Limit registros" -ForegroundColor Yellow
    Write-Host ""
    python import_cnpj.py --limit $Limit
} else {
    Write-Host "IMPORTAÇÃO COMPLETA - Todos os estabelecimentos ativos (~20M)" -ForegroundColor Yellow
    Write-Host "⏱️  Tempo estimado: 2-4 horas" -ForegroundColor Yellow
    Write-Host ""
    
    # Pergunta confirmação
    $confirm = Read-Host "Deseja continuar? (S/N)"
    if ($confirm -ne 'S' -and $confirm -ne 's') {
        Write-Host "Importação cancelada pelo usuário" -ForegroundColor Yellow
        exit 0
    }
    
    Write-Host ""
    python import_cnpj.py
}

if ($LASTEXITCODE -ne 0) {
    Write-Error "Erro na importação"
    exit 1
}

Write-Host ""

# =============================================================================
# ETAPA 4: Verificar resultado final
# =============================================================================
Write-Info "[4/4] Verificando resultado final..."
Write-Host ""

$tempFile = [System.IO.Path]::GetTempFileName() + ".py"
$checkScript | Out-File -FilePath $tempFile -Encoding UTF8
python $tempFile
Remove-Item $tempFile

Write-Host ""

# Estatísticas por UF
Write-Info "Top 10 UFs com mais estabelecimentos ativos:"
Write-Host ""

$statsScript = @'
import psycopg
conn = psycopg.connect("host=localhost port=5434 dbname=momento_fiscal_api_production user=postgres password=TECHbyops30!")
cur = conn.cursor()

cur.execute("""
    SELECT uf, COUNT(*) as total
    FROM estabelecimentos
    WHERE situacao_cadastral = 2
    GROUP BY uf
    ORDER BY total DESC
    LIMIT 10
""")

for row in cur.fetchall():
    uf, total = row
    print(f"  {uf}: {total:>10,} estabelecimentos")

conn.close()
'@

$tempFile2 = [System.IO.Path]::GetTempFileName() + ".py"
$statsScript | Out-File -FilePath $tempFile2 -Encoding UTF8
python $tempFile2
Remove-Item $tempFile2

Write-Host ""
Write-Success "============================================"
Write-Success "  IMPORTAÇÃO CONCLUÍDA!"
Write-Success "============================================"
Write-Host ""
Write-Info "Próximos passos:"
Write-Host "  1. Geocodificar por UF: .\geocode-df.ps1 -ContinuousMode"
Write-Host "  2. Ou geocodificar tudo: python geocode_unique_ceps.py --batch 1000 --propagate"
Write-Host ""
