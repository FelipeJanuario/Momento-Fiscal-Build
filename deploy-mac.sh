#!/bin/bash
# =============================================================================
# Deploy - Momento Fiscal (macOS)
# Espelho dos scripts deploy-backend-only.ps1 e deploy-frontend-only.ps1
# =============================================================================
# Uso:
#   bash deploy-mac.sh            → backend + frontend
#   bash deploy-mac.sh backend    → só backend
#   bash deploy-mac.sh frontend   → só frontend
# =============================================================================

set -e

VM_HOST="165.22.136.67"
VM_USER="root"

# Caminhos no Mac (equivalente a c:\momento-fiscal-transferencia\... no PS1)
PROJECT_PATH="/Users/luizfelipe/Documents/VS Code/Momento Fiscal/momento-fiscal/source-code/momento-fiscal-main"
SOURCE_PATH="$PROJECT_PATH/api"
MOBILE_PATH="$PROJECT_PATH/mobile"

# Caminho remoto na VM (igual ao PS1)
REMOTE_PATH="/root/momento-fiscal-main/api"

GREEN='\033[0;32m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

info()    { echo -e "${CYAN}$*${NC}"; }
success() { echo -e "${GREEN}✅ $*${NC}"; }
error()   { echo -e "${RED}❌ $*${NC}"; exit 1; }

# =============================================================================
# BACKEND (equivalente a deploy-backend-only.ps1)
# =============================================================================
deploy_backend() {
  info "\n========== DEPLOY BACKEND RAILS =========="

  # ── [1/4] Sincronizar código ─────────────────────────────────────────────
  info "\n[1/4] Sincronizando código do backend..."
  ssh "${VM_USER}@${VM_HOST}" "mkdir -p $REMOTE_PATH"
  rsync -avz --delete \
    --exclude='log/' \
    --exclude='tmp/' \
    --exclude='storage/' \
    --exclude='.git/' \
    "$SOURCE_PATH/" \
    "${VM_USER}@${VM_HOST}:${REMOTE_PATH}/"
  success "Código sincronizado"

  # ── [2/4] Rebuild da imagem Docker ──────────────────────────────────────
  info "\n[2/4] Fazendo rebuild da imagem Docker..."
  ssh "${VM_USER}@${VM_HOST}" "
    cd ${REMOTE_PATH}
    echo '>>> Verificando Dockerfile...'
    ls -la Dockerfile
    echo '>>> Fazendo rebuild da imagem...'
    docker build -t momento-fiscal-api:latest .
    echo '>>> Verificando imagem criada:'
    docker images momento-fiscal-api:latest
  "
  success "Imagem Docker criada"

  # ── [3/4] Atualizar serviço ──────────────────────────────────────────────
  info "\n[3/4] Atualizando serviço no Docker Swarm..."
  ssh "${VM_USER}@${VM_HOST}" "
    echo '>>> Atualizando service...'
    docker service update --force --image momento-fiscal-api:latest momento_fiscal_backend
    echo '>>> Aguardando deploy...'
    sleep 10
    echo '>>> Status do service:'
    docker service ps momento_fiscal_backend --no-trunc | head -5
  "
  success "Serviço atualizado"

  # ── [4/4] Validação ──────────────────────────────────────────────────────
  info "\n[4/4] Validando backend..."
  HEALTH=$(ssh "${VM_USER}@${VM_HOST}" "curl -s -o /dev/null -w '%{http_code}' http://localhost:3000/health")
  if [ "$HEALTH" = "200" ]; then
    success "Health check OK (200)"
  else
    echo "Health check retornou: $HEALTH"
  fi

  API_STATUS=$(ssh "${VM_USER}@${VM_HOST}" "curl -s -o /dev/null -w '%{http_code}' 'http://localhost:3000/api/v1/debtors/nearby?lat=-23.627&lng=-46.57&radius_km=10'")
  if [ "$API_STATUS" = "200" ]; then
    success "API debtors OK (200)"
  else
    echo "API debtors retornou: $API_STATUS"
  fi

  info "\nÚltimas linhas do log:"
  ssh "${VM_USER}@${VM_HOST}" "docker service logs momento_fiscal_backend --tail 20"

  success "\n========== DEPLOY BACKEND CONCLUÍDO =========="
  info "API: http://$VM_HOST:3000"
  info "Backend via HTTPS: https://momentofiscal.com.br/api/v1/"
  info "\nVerificar logs completos:"
  info "  ssh $VM_USER@$VM_HOST 'docker service logs -f momento_fiscal_backend'"
}

# =============================================================================
# FRONTEND (equivalente a deploy-frontend-only.ps1)
# =============================================================================
deploy_frontend() {
  info "\n========== BUILD DO FRONTEND =========="

  # ── [1/4] Build Flutter Web ──────────────────────────────────────────────
  cd "$MOBILE_PATH"
  info "Compilando Flutter Web..."
  flutter build web --release --base-href "/"
  [ -f "build/web/index.html" ] || error "Build do Flutter falhou!"
  success "Flutter compilado"

  # ── [2/4] Criar imagem Docker ────────────────────────────────────────────
  info "\n========== CRIANDO IMAGEM DOCKER =========="
  docker build -t momento-fiscal-frontend:latest .
  success "Imagem Docker criada"

  info "Exportando para .tar..."
  docker save momento-fiscal-frontend:latest -o frontend.image.tar
  [ -f "frontend.image.tar" ] || error "Falha ao exportar imagem!"
  TAR_SIZE=$(du -sh frontend.image.tar | cut -f1)
  success "Imagem exportada: $TAR_SIZE"

  # ── [3/4] Enviar para servidor ───────────────────────────────────────────
  info "\n========== ENVIANDO PARA SERVIDOR =========="
  info "Enviando imagem do frontend..."
  scp frontend.image.tar "${VM_USER}@${VM_HOST}:/tmp/"
  success "Frontend enviado"

  # ── [4/4] Carregar e atualizar no servidor ───────────────────────────────
  info "\n========== ATUALIZANDO SERVIDOR =========="
  info "Carregando imagem do frontend..."
  ssh "${VM_USER}@${VM_HOST}" "docker load -i /tmp/frontend.image.tar"
  success "Imagem carregada"

  info "Atualizando serviço frontend..."
  ssh "${VM_USER}@${VM_HOST}" "docker service update --force --image momento-fiscal-frontend:latest momento_fiscal_frontend"
  success "Frontend atualizado"

  info "\nLimpando arquivos temporários..."
  ssh "${VM_USER}@${VM_HOST}" "rm /tmp/frontend.image.tar"
  rm -f frontend.image.tar

  success "\n========== DEPLOY CONCLUÍDO =========="
  info "Frontend: https://momentofiscal.com.br/"
  info "\nVerificar logs:"
  info "  ssh $VM_USER@$VM_HOST 'docker service logs -f momento_fiscal_frontend'"
}

# =============================================================================
# EXECUÇÃO
# =============================================================================
MODE="${1:-all}"

case "$MODE" in
  backend)  deploy_backend ;;
  frontend) deploy_frontend ;;
  all)
    deploy_backend
    deploy_frontend
    ;;
  *)
    error "Modo inválido: '$MODE'. Use: all | backend | frontend"
    ;;
esac
