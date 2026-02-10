# Script para geocodificar todos os CEPs do banco em lotes
# Uso: powershell.exe -ExecutionPolicy Bypass -File .\geocode_all.ps1 -BatchSize 10000

param(
    [int]$BatchSize = 10000,
    [int]$MaxIterations = 0
)

$iteration = 0

Write-Host ""
Write-Host "🌍 Iniciando geocodificação massiva" -ForegroundColor Green
Write-Host "📦 Tamanho do lote: $BatchSize CEPs" -ForegroundColor Cyan
Write-Host ""

# Loop de processamento
while ($true) {
    $iteration++
    
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "🔄 Iteração $iteration" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Geocodifica lote
    python geocode_google.py --batch $BatchSize
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host ""
        Write-Host "❌ Erro ao geocodificar. Aguardando 5 segundos..." -ForegroundColor Red
        Start-Sleep -Seconds 5
        continue
    }
    
    # Verifica se ainda há CEPs pendentes
    Write-Host ""
    Write-Host "📊 Verificando CEPs restantes..." -ForegroundColor Yellow
    
    $checkScript = @"
import psycopg
try:
    conn = psycopg.connect(host='localhost', port='5434', dbname='momento_fiscal_api_production', user='postgres', password='TECHbyops30!')
    cur = conn.cursor()
    cur.execute('''
        SELECT COUNT(DISTINCT e.cep)
        FROM estabelecimentos e
        LEFT JOIN cep_coordinates c ON e.cep = c.cep
        WHERE e.situacao_cadastral = '2'
          AND e.cep IS NOT NULL
          AND LENGTH(e.cep) = 8
          AND (c.cep IS NULL OR c.latitude IS NULL)
    ''')
    pending = cur.fetchone()[0]
    print(f'CEPs restantes: {pending:,}')
    conn.close()
    exit(0 if pending > 0 else 1)
except Exception as e:
    print(f'Erro: {e}')
    exit(2)
"@
    
    $checkScript | python
    $hasMore = $LASTEXITCODE
    
    if ($hasMore -eq 1) {
        Write-Host ""
        Write-Host "✅ Todos os CEPs foram geocodificados!" -ForegroundColor Green
        break
    }
    
    if ($hasMore -eq 2) {
        Write-Host ""
        Write-Host "❌ Erro ao verificar CEPs restantes" -ForegroundColor Red
        break
    }
    
    # Verifica limite de iterações
    if ($MaxIterations -gt 0 -and $iteration -ge $MaxIterations) {
        Write-Host ""
        Write-Host "⏸️  Limite de iterações atingido ($MaxIterations)" -ForegroundColor Yellow
        break
    }
    
    # Pequena pausa entre lotes
    Write-Host ""
    Write-Host "⏳ Aguardando 2 segundos..." -ForegroundColor Gray
    Start-Sleep -Seconds 2
    Write-Host ""
}

# Propaga coordenadas
Write-Host ""
Write-Host "🔄 Propagando coordenadas para estabelecimentos..." -ForegroundColor Green
python geocode_google.py --propagate

Write-Host ""
Write-Host "✅ Processo concluído!" -ForegroundColor Green
