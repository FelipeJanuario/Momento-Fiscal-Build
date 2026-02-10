#!/bin/bash
# Comandos para executar na VM 165.22.136.67
# Copie e cole no terminal SSH

# 1. Instalar Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# 2. Iniciar Docker
systemctl start docker
systemctl enable docker

# 3. Verificar instalação
docker --version

# 4. Ir para o diretório do projeto
cd /opt/momento-fiscal

# 5. Dar permissão de execução aos scripts
chmod +x deploy-simple.sh
chmod +x infrastructure/scripts/*.sh

# 6. Rodar o deploy
bash deploy-simple.sh
