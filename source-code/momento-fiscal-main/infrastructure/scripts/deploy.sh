#!/bin/bash
# =============================================================================
# Script de Deploy do Momento Fiscal
# =============================================================================
# Execute este script sempre que quiser fazer deploy de uma nova versão
# Uso: bash deploy.sh
# =============================================================================

set -e

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo "🚀 Iniciando deploy do Momento Fiscal..."

# Verificar se .env existe
if [ ! -f ".env" ]; then
    echo -e "${RED}❌ Arquivo .env não encontrado!${NC}"
    echo "Copie .env.production.example para .env e configure:"
    echo "   cp .env.production.example .env"
    exit 1
fi

# Carregar variáveis de ambiente
set -a
source .env
set +a

# Verificar variáveis obrigatórias
REQUIRED_VARS=(
    "APP_BACK_IMAGE"
    "APP_DOMAIN"
    "OTEL_EXPORTER_OTLP_ENDPOINT"
    "MAIL_SMTP_PORT"
    "MAIL_SMTP_LOGIN"
    "MAIL_SMTP_DOMAIN"
)

echo "🔍 Verificando variáveis de ambiente obrigatórias..."
for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var}" ]; then
        echo -e "${RED}❌ Variável $var não está definida no .env${NC}"
        exit 1
    fi
done
echo -e "${GREEN}✅ Todas as variáveis obrigatórias estão definidas${NC}"

# Verificar se está no diretório correto
if [ ! -f "infrastructure/swarm_services/docker-compose.yml" ]; then
    echo -e "${RED}❌ Execute este script da raiz do projeto!${NC}"
    exit 1
fi

# Build da imagem
echo ""
echo "🔨 Fazendo build da imagem Docker..."
cd api
docker build -t ${APP_BACK_IMAGE} -f Dockerfile .
echo -e "${GREEN}✅ Build concluído!${NC}"
cd ..

# Fazer deploy do stack
echo ""
echo "🚢 Fazendo deploy do stack Docker Swarm..."
docker stack deploy \
    -c infrastructure/swarm_services/docker-compose.yml \
    momento-fiscal

echo ""
echo "⏳ Aguardando serviços iniciarem..."
sleep 5

# Verificar status dos serviços
echo ""
echo "📊 Status dos serviços:"
docker service ls | grep momento-fiscal

# Verificar se backend está rodando
echo ""
echo "🔍 Verificando réplicas do backend..."
docker service ps momento-fiscal_backend --filter "desired-state=running"

# Executar migrations (se necessário)
echo ""
echo -e "${YELLOW}⚠️  Deseja executar as migrations do banco de dados? (s/n)${NC}"
read -r run_migrations

if [ "$run_migrations" = "s" ] || [ "$run_migrations" = "S" ]; then
    echo "🗄️  Executando migrations..."
    
    # Aguardar backend estar pronto
    sleep 10
    
    # Pegar ID de um container do backend
    BACKEND_CONTAINER=$(docker ps -q -f name=momento-fiscal_backend | head -n 1)
    
    if [ -n "$BACKEND_CONTAINER" ]; then
        docker exec $BACKEND_CONTAINER rails db:migrate
        echo -e "${GREEN}✅ Migrations executadas!${NC}"
    else
        echo -e "${RED}❌ Nenhum container do backend encontrado${NC}"
    fi
fi

# Mostrar logs
echo ""
echo "📋 Últimos logs do backend:"
docker service logs momento-fiscal_backend --tail 20

echo ""
echo "================================================================"
echo "✅ Deploy concluído com sucesso!"
echo "================================================================"
echo ""
echo "🌐 Aplicação disponível em: https://${APP_DOMAIN}"
echo ""
echo "📊 Comandos úteis:"
echo "   Ver serviços:        docker service ls"
echo "   Ver logs:            docker service logs momento-fiscal_backend -f"
echo "   Ver logs Sidekiq:    docker service logs momento-fiscal_sidekiq -f"
echo "   Escalar backend:     docker service scale momento-fiscal_backend=3"
echo "   Remover stack:       docker stack rm momento-fiscal"
echo ""
echo "🔍 Health check:"
echo "   curl https://${APP_DOMAIN}/api/health/up"
echo ""
