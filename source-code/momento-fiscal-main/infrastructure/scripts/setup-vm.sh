#!/bin/bash
# =============================================================================
# Script de Setup Inicial da VM Digital Ocean
# =============================================================================
# Este script instala e configura tudo necessário para rodar o Momento Fiscal
# Execute como root: bash setup-vm.sh
# =============================================================================

set -e

echo "🚀 Iniciando setup da VM para Momento Fiscal..."

# Atualizar sistema
echo "📦 Atualizando sistema operacional..."
apt-get update
apt-get upgrade -y

# Instalar dependências básicas
echo "📦 Instalando dependências básicas..."
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    git \
    vim \
    htop

# Instalar Docker
echo "🐳 Instalando Docker..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
    
    # Iniciar Docker
    systemctl enable docker
    systemctl start docker
    
    echo "✅ Docker instalado com sucesso!"
else
    echo "✅ Docker já está instalado"
fi

# Verificar versão do Docker
docker --version

# Inicializar Docker Swarm
echo "🐝 Inicializando Docker Swarm..."
if ! docker info | grep -q "Swarm: active"; then
    docker swarm init
    echo "✅ Docker Swarm inicializado!"
else
    echo "✅ Docker Swarm já está ativo"
fi

# Criar rede traefik-public se não existir
echo "🌐 Criando rede traefik-public..."
if ! docker network ls | grep -q "traefik-public"; then
    docker network create --driver=overlay traefik-public
    echo "✅ Rede traefik-public criada!"
else
    echo "✅ Rede traefik-public já existe"
fi

# Criar diretórios necessários
echo "📁 Criando estrutura de diretórios..."
mkdir -p /opt/momento-fiscal
mkdir -p /opt/momento-fiscal/backups
mkdir -p /opt/momento-fiscal/logs
mkdir -p /opt/momento-fiscal/postgres-data
mkdir -p /opt/momento-fiscal/redis-data

# Configurar firewall (UFW)
echo "🔥 Configurando firewall..."
if command -v ufw &> /dev/null; then
    ufw allow 22/tcp      # SSH
    ufw allow 80/tcp      # HTTP
    ufw allow 443/tcp     # HTTPS
    ufw allow 2377/tcp    # Docker Swarm
    ufw allow 7946/tcp    # Docker Swarm
    ufw allow 7946/udp    # Docker Swarm
    ufw allow 4789/udp    # Docker overlay
    echo "y" | ufw enable || true
    echo "✅ Firewall configurado!"
fi

# Otimizações do sistema
echo "⚙️  Aplicando otimizações do sistema..."
cat >> /etc/sysctl.conf <<EOF

# Otimizações para Docker e PostgreSQL
vm.max_map_count=262144
vm.swappiness=10
net.core.somaxconn=1024
net.ipv4.tcp_max_syn_backlog=2048
EOF
sysctl -p

# Configurar swap se necessário
echo "💾 Verificando swap..."
if [ $(free | grep Swap | awk '{print $2}') -eq 0 ]; then
    echo "Criando arquivo de swap de 2GB..."
    fallocate -l 2G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile none swap sw 0 0' >> /etc/fstab
    echo "✅ Swap criado!"
else
    echo "✅ Swap já configurado"
fi

# Configurar timezone
echo "🕐 Configurando timezone para America/Sao_Paulo..."
timedatectl set-timezone America/Sao_Paulo

# Informações finais
echo ""
echo "================================================================"
echo "✅ Setup da VM concluído com sucesso!"
echo "================================================================"
echo ""
echo "📊 Informações do sistema:"
echo "   - Docker: $(docker --version)"
echo "   - Docker Swarm: Ativo"
echo "   - Timezone: $(timedatectl | grep "Time zone")"
echo "   - Memória: $(free -h | grep Mem | awk '{print $2}')"
echo "   - Swap: $(free -h | grep Swap | awk '{print $2}')"
echo ""
echo "📂 Diretórios criados:"
echo "   - /opt/momento-fiscal"
echo "   - /opt/momento-fiscal/backups"
echo "   - /opt/momento-fiscal/logs"
echo ""
echo "🎯 Próximos passos:"
echo "   1. Clone o repositório: cd /opt/momento-fiscal && git clone <repo-url>"
echo "   2. Configure os secrets: bash create-secrets.sh"
echo "   3. Configure as variáveis: cp .env.example .env && vim .env"
echo "   4. Faça o deploy: bash deploy.sh"
echo ""
echo "================================================================"
