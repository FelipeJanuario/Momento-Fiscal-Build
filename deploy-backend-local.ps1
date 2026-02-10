# Deploy Backend Local - Rebuild e Restart
# Atualiza a imagem Docker do backend API e reinicia o container

Write-Host "================================" -ForegroundColor Cyan
Write-Host "DEPLOY BACKEND LOCAL" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

$ErrorActionPreference = "Stop"

# Navega para o diretório do projeto
$projectPath = "c:\momento-fiscal-transferencia\source-code\momento-fiscal-main"
Set-Location $projectPath

Write-Host "📁 Diretório: $projectPath" -ForegroundColor Yellow
Write-Host ""

# 1. Rebuild da imagem Docker (sem cache para garantir código atualizado)
Write-Host "🔨 STEP 1: Rebuild da imagem Docker (--no-cache)..." -ForegroundColor Green
docker-compose -f docker-compose.local.yml --env-file .env.local build --no-cache backend

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Erro ao fazer build da imagem!" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Build concluído com sucesso!" -ForegroundColor Green
Write-Host ""

# 2. Recriar container com a nova imagem (--force-recreate garante que usa a imagem nova)
Write-Host "🔄 STEP 2: Recriando container (--force-recreate)..." -ForegroundColor Green
docker-compose -f docker-compose.local.yml --env-file .env.local up -d --force-recreate backend

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Erro ao recriar container!" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Container recriado com nova imagem!" -ForegroundColor Green
Write-Host ""

# Aguarda o container inicializar
Write-Host "⏳ Aguardando container inicializar (10 segundos)..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# 3. Testes rápidos
Write-Host "🧪 STEP 3: Testando endpoints..." -ForegroundColor Green
Write-Host ""

Write-Host "📡 Teste 1: Health check..." -ForegroundColor Cyan
try {
    $response = Invoke-WebRequest -Uri "http://localhost:3000/health" -TimeoutSec 5 -ErrorAction SilentlyContinue
    if ($response.StatusCode -eq 200) {
        Write-Host "✅ API respondendo!" -ForegroundColor Green
    }
} catch {
    Write-Host "⚠️  API ainda não está respondendo" -ForegroundColor Yellow
}
Write-Host ""

Write-Host "📡 Teste 2: Endpoint de empresas..." -ForegroundColor Cyan
Write-Host "curl http://localhost:3000/api/v1/biddings_analyser/companies?cnpj=60.872.173/0001-21" -ForegroundColor Gray
Write-Host ""

Write-Host "📡 Teste 3: Endpoint Serpro dívidas..." -ForegroundColor Cyan
Write-Host "curl http://localhost:3000/api/v1/serpro/dividas/60872173000121" -ForegroundColor Gray
Write-Host ""

# 4. Mostrar logs
Write-Host "📋 STEP 4: Logs do container (últimas 20 linhas)..." -ForegroundColor Green
Write-Host "================================" -ForegroundColor Gray
docker-compose -f docker-compose.local.yml --env-file .env.local logs --tail=20 backend
Write-Host "================================" -ForegroundColor Gray
Write-Host ""

Write-Host "✅ Deploy local concluído!" -ForegroundColor Green
Write-Host ""
Write-Host "💡 Comandos úteis:" -ForegroundColor Yellow
Write-Host "   Ver logs ao vivo:    docker-compose -f docker-compose.local.yml --env-file .env.local logs -f backend" -ForegroundColor Gray
Write-Host "   Parar containers:    docker-compose -f docker-compose.local.yml --env-file .env.local down" -ForegroundColor Gray
Write-Host "   Ver status:          docker-compose -f docker-compose.local.yml --env-file .env.local ps" -ForegroundColor Gray
Write-Host ""
