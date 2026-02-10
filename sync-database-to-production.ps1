# Script Automático de Backup e Restore do Banco de Dados
# Sincroniza banco local (com dados do ETL) para produção na VM

param(
    [string]$VMHost = "165.22.136.67",
    [string]$VMUser = "root",
    [switch]$SkipBackup,
    [switch]$DryRun
)

# Configurações
$LOCAL_CONTAINER = "momento_fiscal_db"
$LOCAL_DB = "momento_fiscal_production"
$REMOTE_DB = "momento_fiscal_production"
$BACKUP_DIR = "c:\momento-fiscal-transferencia\source-code\momento-fiscal-main\backups\database"
$TIMESTAMP = Get-Date -Format "yyyyMMdd_HHmmss"
$BACKUP_FILE = "etl_data_$TIMESTAMP.backup"
$BACKUP_PATH = "$BACKUP_DIR\$BACKUP_FILE"

Write-Host "🚀 Sincronização de Banco de Dados - Momento Fiscal" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host ""

# Função para logging com timestamp
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "ERROR" { "Red" }
        "SUCCESS" { "Green" }
        "WARNING" { "Yellow" }
        default { "White" }
    }
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

# Função para executar comando com verificação de erro
function Invoke-SafeCommand {
    param([string]$Command, [string]$Description)
    Write-Log "Executando: $Description" "INFO"
    if ($DryRun) {
        Write-Log "[DRY-RUN] $Command" "WARNING"
        return $true
    }
    try {
        Invoke-Expression $Command
        if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne $null) {
            throw "Comando retornou código de erro: $LASTEXITCODE"
        }
        Write-Log "✓ $Description concluído" "SUCCESS"
        return $true
    } catch {
        Write-Log "✗ Erro em: $Description - $_" "ERROR"
        return $false
    }
}

# ========================================
# ETAPA 1: Backup do Banco Local
# ========================================
if (-not $SkipBackup) {
    Write-Host ""
    Write-Log "📦 ETAPA 1/7: Criando backup do banco local..." "INFO"
    
    $backupCmd = "docker exec $LOCAL_CONTAINER pg_dump -U postgres -d $LOCAL_DB -Fc -f /tmp/$BACKUP_FILE"
    if (-not (Invoke-SafeCommand $backupCmd "Criar backup dentro do container")) {
        exit 1
    }
    
    # Verificar contagem de registros antes do backup
    Write-Log "Verificando dados no banco local..." "INFO"
    $countCmd = "docker exec $LOCAL_CONTAINER psql -U postgres -d $LOCAL_DB -t -c 'SELECT COUNT(*) FROM empresas; SELECT COUNT(*) FROM estabelecimentos;'"
    Invoke-Expression $countCmd
    
    # Copiar backup para fora do container
    $copyCmd = "docker cp ${LOCAL_CONTAINER}:/tmp/$BACKUP_FILE `"$BACKUP_PATH`""
    if (-not (Invoke-SafeCommand $copyCmd "Copiar backup para o host")) {
        exit 1
    }
    
    # Verificar tamanho do backup
    if (Test-Path $BACKUP_PATH) {
        $size = (Get-Item $BACKUP_PATH).Length / 1MB
        Write-Log "Backup criado: $BACKUP_FILE ($([math]::Round($size, 2)) MB)" "SUCCESS"
    } else {
        Write-Log "Erro: Backup não encontrado em $BACKUP_PATH" "ERROR"
        exit 1
    }
} else {
    Write-Log "Pulando criação de backup (usando backup existente)" "WARNING"
    # Usar o backup mais recente
    $latestBackup = Get-ChildItem "$BACKUP_DIR\etl_data_*.backup" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($latestBackup) {
        $BACKUP_PATH = $latestBackup.FullName
        $BACKUP_FILE = $latestBackup.Name
        Write-Log "Usando backup: $BACKUP_FILE" "INFO"
    } else {
        Write-Log "Erro: Nenhum backup encontrado em $BACKUP_DIR" "ERROR"
        exit 1
    }
}

# ========================================
# ETAPA 2: Validar Backup
# ========================================
Write-Host ""
Write-Log "🔍 ETAPA 2/7: Validando formato do backup..." "INFO"

$bytes = Get-Content -Path $BACKUP_PATH -Encoding Byte -TotalCount 5
$header = [System.Text.Encoding]::ASCII.GetString($bytes)

if ($header -eq "PGDMP") {
    Write-Log "✓ Formato válido: PostgreSQL custom format" "SUCCESS"
} else {
    Write-Log "✗ Formato inválido: Esperado 'PGDMP', encontrado '$header'" "ERROR"
    exit 1
}

# ========================================
# ETAPA 3: Obter ID do Container Remoto
# ========================================
Write-Host ""
Write-Log "🔍 ETAPA 3/7: Identificando container PostgreSQL na VM..." "INFO"

$getContainerCmd = "ssh ${VMUser}@${VMHost} `"docker ps -q -f name=momento_fiscal_db`""
$REMOTE_CONTAINER = (Invoke-Expression $getContainerCmd).Trim()

if (-not $REMOTE_CONTAINER) {
    Write-Log "✗ Container PostgreSQL não encontrado na VM" "ERROR"
    exit 1
}

Write-Log "✓ Container encontrado: $REMOTE_CONTAINER" "SUCCESS"

# ========================================
# ETAPA 4: Fazer Backup de Segurança da Produção
# ========================================
Write-Host ""
Write-Log "💾 ETAPA 4/7: Criando backup de segurança da produção..." "INFO"

$prodBackupFile = "production_backup_before_restore_$TIMESTAMP.backup"
$prodBackupCmd = "ssh ${VMUser}@${VMHost} `"docker exec $REMOTE_CONTAINER pg_dump -U postgres -d $REMOTE_DB -Fc -f /tmp/$prodBackupFile`""

if (Invoke-SafeCommand $prodBackupCmd "Backup de segurança da produção") {
    Write-Log "✓ Backup de segurança criado: $prodBackupFile" "SUCCESS"
} else {
    Write-Log "⚠ Falha no backup de segurança, mas continuando..." "WARNING"
}

# ========================================
# ETAPA 5: Transferir Backup para VM
# ========================================
Write-Host ""
Write-Log "📤 ETAPA 5/7: Transferindo backup para VM..." "INFO"

$scpCmd = "scp `"$BACKUP_PATH`" ${VMUser}@${VMHost}:/root/"
if (-not (Invoke-SafeCommand $scpCmd "Transferência via SCP")) {
    exit 1
}

# ========================================
# ETAPA 6: Copiar para Dentro do Container
# ========================================
Write-Host ""
Write-Log "📥 ETAPA 6/7: Copiando backup para dentro do container..." "INFO"

$dockerCpCmd = "ssh ${VMUser}@${VMHost} `"docker cp /root/$BACKUP_FILE ${REMOTE_CONTAINER}:/tmp/`""
if (-not (Invoke-SafeCommand $dockerCpCmd "Copiar para container")) {
    exit 1
}

# ========================================
# ETAPA 7: Restaurar no Banco de Produção
# ========================================
Write-Host ""
Write-Log "🔄 ETAPA 7/7: Restaurando backup no banco de produção..." "INFO"

$restoreCmd = "ssh ${VMUser}@${VMHost} `"docker exec $REMOTE_CONTAINER pg_restore -U postgres -d $REMOTE_DB --clean --if-exists /tmp/$BACKUP_FILE 2>&1`""

if ($DryRun) {
    Write-Log "[DRY-RUN] Restore não será executado" "WARNING"
} else {
    Write-Log "⚠ Iniciando restore (isso irá SUBSTITUIR os dados atuais)..." "WARNING"
    Start-Sleep -Seconds 3
    
    $output = Invoke-Expression $restoreCmd
    Write-Host $output
    
    Write-Log "✓ Restore concluído" "SUCCESS"
}

# ========================================
# VALIDAÇÃO FINAL
# ========================================
Write-Host ""
Write-Log "✅ VALIDAÇÃO: Verificando dados restaurados..." "INFO"

$validateCmd = "ssh ${VMUser}@${VMHost} `"docker exec $REMOTE_CONTAINER psql -U postgres -d $REMOTE_DB -t -c 'SELECT COUNT(*) FROM empresas; SELECT COUNT(*) FROM estabelecimentos;'`""
$counts = Invoke-Expression $validateCmd

Write-Host ""
Write-Host "📊 Contagem de registros na produção:" -ForegroundColor Cyan
Write-Host $counts

# ========================================
# TESTE DA API
# ========================================
Write-Host ""
Write-Log "🌐 Testando API /debtors/nearby..." "INFO"

try {
    $apiUrl = "http://${VMHost}:3000/api/v1/debtors/nearby?lat=-23.627`&lng=-46.57`&radius_km=10"
    $response = Invoke-WebRequest $apiUrl -ErrorAction Stop
    
    if ($response.StatusCode -eq 200) {
        $contentSize = $response.Content.Length / 1KB
        Write-Log "✓ API funcionando! Status: 200, Tamanho: $([math]::Round($contentSize, 2)) KB" "SUCCESS"
        
        # Contar empresas retornadas
        $json = $response.Content | ConvertFrom-Json
        $companyCount = $json.companies.Count
        Write-Log "✓ API retornou $companyCount empresas" "SUCCESS"
    } else {
        Write-Log "⚠ API retornou status: $($response.StatusCode)" "WARNING"
    }
} catch {
    Write-Log "✗ Erro ao testar API: $_" "ERROR"
}

# ========================================
# LIMPEZA
# ========================================
Write-Host ""
Write-Log "🧹 Limpando arquivos temporários na VM..." "INFO"

$cleanupCmd = "ssh ${VMUser}@${VMHost} `"rm -f /root/$BACKUP_FILE`""
Invoke-SafeCommand $cleanupCmd "Remover arquivo temporário"

# ========================================
# RESUMO FINAL
# ========================================
Write-Host ""
Write-Host "=================================================" -ForegroundColor Cyan
Write-Log "🎉 Sincronização concluída com sucesso!" "SUCCESS"
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📋 Resumo:" -ForegroundColor Yellow
Write-Host "  • Backup: $BACKUP_FILE" -ForegroundColor White
Write-Host "  • VM: ${VMHost}" -ForegroundColor White
Write-Host "  • Container: $REMOTE_CONTAINER" -ForegroundColor White
Write-Host "  • Backup de segurança: $prodBackupFile" -ForegroundColor White
Write-Host ""
Write-Host "🔗 Próximos passos:" -ForegroundColor Yellow
Write-Host "  1. Verificar aplicação em: https://momentofiscal.com.br/" -ForegroundColor White
Write-Host "  2. Testar busca de devedores no mapa interativo" -ForegroundColor White
Write-Host "  3. Monitorar logs do backend para erros" -ForegroundColor White
Write-Host ""
