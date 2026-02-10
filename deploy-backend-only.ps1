# Deploy Backend - Momento Fiscal
# Faz rebuild e deploy do backend Rails na VM

param(
    [string]$VMHost = "165.22.136.67",
    [string]$VMUser = "root"
)

$ErrorActionPreference = "Stop"
function Write-Success { Write-Host $args -ForegroundColor Green }
function Write-Info { Write-Host $args -ForegroundColor Cyan }
function Write-Error { Write-Host $args -ForegroundColor Red }

$SOURCE_PATH = "c:\momento-fiscal-transferencia\source-code\momento-fiscal-main\api"
$REMOTE_PATH = "/root/momento-fiscal-main/api"

Write-Info "`n========== DEPLOY BACKEND RAILS =========="

# =============================================================================
# 1. SINCRONIZAR CÓDIGO
# =============================================================================
Write-Info "`n[1/4] Sincronizando código do backend..."

Write-Info "Copiando arquivos..."
ssh "${VMUser}@${VMHost}" "mkdir -p $REMOTE_PATH"

# Sincronizar todo o código da API via rsync (mais eficiente)
# Exclui pastas desnecessárias
$rsyncCmd = "rsync -avz --delete --exclude='log/' --exclude='tmp/' --exclude='storage/' --exclude='.git/' `"$SOURCE_PATH/`" `"${VMUser}@${VMHost}:${REMOTE_PATH}/`""

Write-Info "Executando rsync..."
Invoke-Expression $rsyncCmd

Write-Success "Código sincronizado"

# =============================================================================
# 2. REBUILD DA IMAGEM DOCKER
# =============================================================================
Write-Info "`n[2/4] Fazendo rebuild da imagem Docker..."

ssh "${VMUser}@${VMHost}" @"
cd $REMOTE_PATH

echo '>>> Verificando Dockerfile...'
ls -la Dockerfile

echo '>>> Fazendo rebuild da imagem...'
docker build -t momento-fiscal-api:latest .

echo '>>> Verificando imagem criada:'
docker images momento-fiscal-api:latest
"@

Write-Success "Imagem Docker criada"

# =============================================================================
# 3. ATUALIZAR SERVIÇO
# =============================================================================
Write-Info "`n[3/4] Atualizando serviço no Docker Swarm..."

ssh "${VMUser}@${VMHost}" @"
echo '>>> Atualizando service...'
docker service update --force --image momento-fiscal-api:latest momento_fiscal_backend

echo '>>> Aguardando deploy...'
sleep 10

echo '>>> Status do service:'
docker service ps momento_fiscal_backend --no-trunc | head -5
"@

Write-Success "Serviço atualizado"

# =============================================================================
# 4. VALIDAÇÃO
# =============================================================================
Write-Info "`n[4/4] Validando backend..."

Write-Info "Testando health check..."
$healthStatus = ssh "${VMUser}@${VMHost}" "curl -s -o /dev/null -w '%{http_code}' http://localhost:3000/health"
if ($healthStatus -eq "200") {
    Write-Success "Health check OK (200)"
} else {
    Write-Error "Health check falhou: $healthStatus"
}

Write-Info "Testando API debtors..."
$apiStatus = ssh "${VMUser}@${VMHost}" "curl -s -o /dev/null -w '%{http_code}' 'http://localhost:3000/api/v1/debtors/nearby?lat=-23.627&lng=-46.57&radius_km=10'"
if ($apiStatus -eq "200") {
    Write-Success "API debtors OK (200)"
} else {
    Write-Error "API debtors retornou: $apiStatus"
}

# =============================================================================
# LOGS
# =============================================================================
Write-Info "`nÚltimas linhas do log:"
ssh "${VMUser}@${VMHost}" "docker service logs momento_fiscal_backend --tail 20"

# =============================================================================
# FINALIZADO
# =============================================================================
Write-Success "`n========== DEPLOY BACKEND CONCLUÍDO =========="
Write-Info "API: http://$VMHost:3000"
Write-Info "Backend via HTTPS: https://momentofiscal.com.br/api/v1/"
Write-Info "`nVerificar logs completos:"
Write-Info "  ssh $VMUser@$VMHost 'docker service logs -f momento_fiscal_backend'"
