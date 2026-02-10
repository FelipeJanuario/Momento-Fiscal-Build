# Script Simples de Sync do Banco de Dados
param(
    [string]$VMHost = "165.22.136.67",
    [string]$VMUser = "root"
)

$ErrorActionPreference = "Stop"

# Configuracoes
$LOCAL_CONTAINER = "momento-fiscal-main-db-1"
$LOCAL_DB = "momento_fiscal_production"
$BACKUP_DIR = "c:\momento-fiscal-transferencia\backups\database"
$TIMESTAMP = Get-Date -Format "yyyyMMdd_HHmmss"
$BACKUP_FILE = "etl_data_$TIMESTAMP.backup"

Write-Host "=== Sincronizacao de Banco de Dados ===" -ForegroundColor Cyan

# Criar diretorio se nao existir
if (-not (Test-Path $BACKUP_DIR)) {
    New-Item -ItemType Directory -Path $BACKUP_DIR -Force | Out-Null
}

# ETAPA 1: Backup do banco local
Write-Host "`n[1/6] Criando backup do banco local..." -ForegroundColor Yellow
docker exec $LOCAL_CONTAINER pg_dump -U postgres -d $LOCAL_DB -Fc -f /tmp/$BACKUP_FILE
if ($LASTEXITCODE -ne 0) { Write-Host "Erro no backup!" -ForegroundColor Red; exit 1 }

Write-Host "[1/6] Copiando backup para host..." -ForegroundColor Yellow
docker cp "${LOCAL_CONTAINER}:/tmp/$BACKUP_FILE" "$BACKUP_DIR\$BACKUP_FILE"
if ($LASTEXITCODE -ne 0) { Write-Host "Erro ao copiar!" -ForegroundColor Red; exit 1 }

$size = [math]::Round((Get-Item "$BACKUP_DIR\$BACKUP_FILE").Length / 1MB, 2)
Write-Host "[1/6] Backup criado: $size MB" -ForegroundColor Green

# ETAPA 2: Obter container remoto
Write-Host "`n[2/6] Identificando container na VM..." -ForegroundColor Yellow
$REMOTE_CONTAINER = (ssh "${VMUser}@${VMHost}" "docker ps -q -f name=momento_fiscal_db").Trim()
if (-not $REMOTE_CONTAINER) {
    Write-Host "Container nao encontrado!" -ForegroundColor Red
    exit 1
}
Write-Host "[2/6] Container: $REMOTE_CONTAINER" -ForegroundColor Green

# ETAPA 3: Backup de seguranca da producao
Write-Host "`n[3/6] Backup de seguranca da producao..." -ForegroundColor Yellow
$prodBackup = "prod_backup_before_$TIMESTAMP.backup"
ssh "${VMUser}@${VMHost}" "docker exec $REMOTE_CONTAINER pg_dump -U postgres -d $LOCAL_DB -Fc -f /tmp/$prodBackup"
Write-Host "[3/6] Backup de seguranca criado" -ForegroundColor Green

# ETAPA 4: Transferir backup
Write-Host "`n[4/6] Transferindo backup para VM (pode demorar)..." -ForegroundColor Yellow
scp "$BACKUP_DIR\$BACKUP_FILE" "${VMUser}@${VMHost}:/root/"
if ($LASTEXITCODE -ne 0) { Write-Host "Erro no SCP!" -ForegroundColor Red; exit 1 }
Write-Host "[4/6] Transferencia concluida" -ForegroundColor Green

# ETAPA 5: Copiar para container e restaurar
Write-Host "`n[5/6] Copiando para container..." -ForegroundColor Yellow
ssh "${VMUser}@${VMHost}" "docker cp /root/$BACKUP_FILE ${REMOTE_CONTAINER}:/tmp/"
Write-Host "[5/6] Arquivo copiado para container" -ForegroundColor Green

Write-Host "`n[6/6] Restaurando banco (pode demorar)..." -ForegroundColor Yellow
ssh "${VMUser}@${VMHost}" "docker exec $REMOTE_CONTAINER pg_restore -U postgres -d $LOCAL_DB --clean --if-exists /tmp/$BACKUP_FILE"
Write-Host "[6/6] Restore concluido!" -ForegroundColor Green

# Validacao
Write-Host "`n=== Validando ===" -ForegroundColor Cyan
ssh "${VMUser}@${VMHost}" "docker exec $REMOTE_CONTAINER psql -U postgres -d $LOCAL_DB -c 'SELECT COUNT(*) as empresas FROM empresas; SELECT COUNT(*) as estabelecimentos FROM estabelecimentos;'"

# Limpeza
Write-Host "`n=== Limpando arquivos temporarios ===" -ForegroundColor Cyan
ssh "${VMUser}@${VMHost}" "rm -f /root/$BACKUP_FILE"

Write-Host "`n=== CONCLUIDO ===" -ForegroundColor Green
Write-Host "Backup: $BACKUP_FILE"
Write-Host "Backup de seguranca: $prodBackup"
Write-Host "Verifique: https://momentofiscal.com.br/"
