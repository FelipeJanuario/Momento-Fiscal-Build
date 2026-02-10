# Deploy Frontend - Momento Fiscal
# Faz build do Flutter Web e deploy na VM

param(
    [string]$VMHost = "165.22.136.67",
    [string]$VMUser = "root"
)

$ErrorActionPreference = "Stop"
function Write-Success { Write-Host $args -ForegroundColor Green }
function Write-Info { Write-Host $args -ForegroundColor Cyan }
function Write-Error { Write-Host $args -ForegroundColor Red }

$ProjectPath = "c:\momento-fiscal-transferencia\source-code\momento-fiscal-main"

# =============================================================================
# 1. BUILD DO FRONTEND FLUTTER
# =============================================================================
Write-Info "`n========== BUILD DO FRONTEND =========="
Set-Location "$ProjectPath\mobile"

Write-Info "Compilando Flutter Web..."
flutter build web --release --base-href "/"

if (-not (Test-Path "build\web\index.html")) {
    Write-Error "Build do Flutter falhou!"
    exit 1
}
Write-Success "Flutter compilado"

# =============================================================================
# 2. CRIAR IMAGEM DOCKER
# =============================================================================
Write-Info "`n========== CRIANDO IMAGEM DOCKER =========="
docker build -t momento-fiscal-frontend:latest .
Write-Success "Imagem Docker criada"

Write-Info "Exportando para .tar..."
docker save momento-fiscal-frontend:latest -o frontend.image.tar

if (Test-Path "frontend.image.tar") {
    $size = (Get-Item "frontend.image.tar").Length / 1MB
    Write-Success "Imagem exportada: $([math]::Round($size, 2)) MB"
} else {
    Write-Error "Falha ao exportar imagem!"
    exit 1
}

# =============================================================================
# 3. ENVIAR PARA SERVIDOR
# =============================================================================
Write-Info "`n========== ENVIANDO PARA SERVIDOR =========="

Write-Info "Enviando imagem do frontend..."
scp frontend.image.tar "${VMUser}@${VMHost}:/tmp/"
Write-Success "Frontend enviado"

# =============================================================================
# 4. CARREGAR E ATUALIZAR NO SERVIDOR
# =============================================================================
Write-Info "`n========== ATUALIZANDO SERVIDOR =========="

Write-Info "Carregando imagem do frontend..."
ssh "${VMUser}@${VMHost}" "docker load -i /tmp/frontend.image.tar"
Write-Success "Imagem carregada"

Write-Info "Atualizando serviço frontend..."
ssh "${VMUser}@${VMHost}" "docker service update --force --image momento-fiscal-frontend:latest momento_fiscal_frontend"
Write-Success "Frontend atualizado"

# Limpar arquivos temporários
Write-Info "`nLimpando arquivos temporários..."
ssh "${VMUser}@${VMHost}" "rm /tmp/frontend.image.tar"
Remove-Item "frontend.image.tar" -Force

# =============================================================================
# FINALIZADO
# =============================================================================
Write-Success "`n========== DEPLOY CONCLUÍDO =========="
Write-Info "Frontend: https://momentofiscal.com.br/"
Write-Info "`nVerificar logs:"
Write-Info "  ssh $VMUser@$VMHost 'docker service logs -f momento_fiscal_frontend'"
