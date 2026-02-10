#!/bin/bash
# Script para instalar certificado SSL válido com Let's Encrypt

# Instalar Certbot
sudo apt-get update
sudo apt-get install -y certbot python3-certbot-nginx

# Parar nginx temporariamente
sudo systemctl stop nginx

# Obter certificado SSL (modo standalone)
sudo certbot certonly --standalone \
  -d momentofiscal.com.br \
  -d www.momentofiscal.com.br \
  --email seu-email@exemplo.com \
  --agree-tos \
  --no-eff-email

# Iniciar nginx novamente
sudo systemctl start nginx

# Configurar renovação automática
sudo systemctl enable certbot.timer
sudo systemctl start certbot.timer

echo "Certificado SSL instalado com sucesso!"
echo "Os certificados estão em: /etc/letsencrypt/live/momentofiscal.com.br/"
