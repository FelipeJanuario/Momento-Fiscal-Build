#!/bin/bash
# =============================================================================
# Script para criar todos os Docker Secrets necessários
# =============================================================================
# Execute este script ANTES do primeiro deploy
# Uso: bash create-secrets.sh
# =============================================================================

set -e

echo "🔐 Criando Docker Secrets para Momento Fiscal..."
echo ""

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Função para criar secret
create_secret() {
    local secret_name=$1
    local secret_prompt=$2
    local secret_file=$3
    
    # Verificar se secret já existe
    if docker secret ls | grep -q "$secret_name"; then
        echo -e "${YELLOW}⚠️  Secret '$secret_name' já existe. Pulando...${NC}"
        return
    fi
    
    if [ -n "$secret_file" ]; then
        # Secret de arquivo
        if [ -f "$secret_file" ]; then
            cat "$secret_file" | docker secret create "$secret_name" -
            echo -e "${GREEN}✅ Secret '$secret_name' criado do arquivo${NC}"
        else
            echo -e "${RED}❌ Arquivo '$secret_file' não encontrado${NC}"
        fi
    else
        # Secret de texto
        echo -n "$secret_prompt"
        read -s secret_value
        echo ""
        echo "$secret_value" | docker secret create "$secret_name" -
        echo -e "${GREEN}✅ Secret '$secret_name' criado${NC}"
    fi
}

# Gerar secrets automaticamente se não fornecidos
generate_secret_key() {
    openssl rand -hex 64
}

echo "================================================================"
echo "SECRETS OBRIGATÓRIOS"
echo "================================================================"
echo ""

# 1. PostgreSQL Password
echo "📦 1/13 - PostgreSQL Password"
create_secret "momento_fiscal_postgres_password" "Digite a senha do PostgreSQL: "

# 2. Rails Secret Key Base
echo ""
echo "📦 2/13 - Rails Secret Key Base"
echo "Gerando automaticamente..."
SECRET_KEY=$(generate_secret_key)
echo "$SECRET_KEY" | docker secret create momento_fiscal_secret_key_base -
echo -e "${GREEN}✅ Secret 'momento_fiscal_secret_key_base' criado${NC}"

# 3. SMTP Password
echo ""
echo "📦 3/13 - SMTP Password (para envio de emails)"
create_secret "momento_fiscal_smtp_password" "Digite a senha do SMTP: "

# 4. Lockbox Master Key
echo ""
echo "📦 4/13 - Lockbox Master Key"
echo "Gerando automaticamente..."
LOCKBOX_KEY=$(openssl rand -hex 32)
echo "$LOCKBOX_KEY" | docker secret create momento_fiscal_lockbox_master_key -
echo -e "${GREEN}✅ Secret 'momento_fiscal_lockbox_master_key' criado${NC}"

# 5. Active Record Encryption - Primary Key
echo ""
echo "📦 5/13 - Active Record Encryption Primary Key"
echo "Gerando automaticamente..."
ENCRYPTION_PRIMARY=$(openssl rand -hex 32)
echo "$ENCRYPTION_PRIMARY" | docker secret create momento_fiscal_active_record_encryption_primary_key -
echo -e "${GREEN}✅ Secret 'momento_fiscal_active_record_encryption_primary_key' criado${NC}"

# 6. Active Record Encryption - Deterministic Key
echo ""
echo "📦 6/13 - Active Record Encryption Deterministic Key"
echo "Gerando automaticamente..."
ENCRYPTION_DETERMINISTIC=$(openssl rand -hex 32)
echo "$ENCRYPTION_DETERMINISTIC" | docker secret create momento_fiscal_active_record_encryption_deterministic_key -
echo -e "${GREEN}✅ Secret 'momento_fiscal_active_record_encryption_deterministic_key' criado${NC}"

# 7. Active Record Encryption - Key Derivation Salt
echo ""
echo "📦 7/13 - Active Record Encryption Key Derivation Salt"
echo "Gerando automaticamente..."
ENCRYPTION_SALT=$(openssl rand -hex 32)
echo "$ENCRYPTION_SALT" | docker secret create momento_fiscal_active_record_encryption_key_derivation_salt -
echo -e "${GREEN}✅ Secret 'momento_fiscal_active_record_encryption_key_derivation_salt' criado${NC}"

# 8. Biddings Analyser API Key
echo ""
echo "📦 8/13 - Biddings Analyser API Key"
create_secret "momento_fiscal_biddings_analyser_api_key" "Digite a API Key do Biddings Analyser: "

# 9. Stripe Secret Key
echo ""
echo "📦 9/13 - Stripe Secret Key (produção)"
create_secret "momento_fiscal_stripe_secret_key" "Digite a Stripe Secret Key (sk_live_...): "

# 10. PJE Auth PFX
echo ""
echo "📦 10/13 - Certificado PJE PFX (arquivo)"
echo "Informe o caminho do arquivo .pfx: "
read pfx_file
if [ -f "$pfx_file" ]; then
    cat "$pfx_file" | base64 -w 0 | docker secret create momento_fiscal_pje_auth_pfx -
    echo -e "${GREEN}✅ Secret 'momento_fiscal_pje_auth_pfx' criado${NC}"
else
    echo -e "${YELLOW}⚠️  Arquivo não encontrado. Pulando... (configure depois)${NC}"
fi

# 11. PJE Auth PFX Password
echo ""
echo "📦 11/13 - Senha do certificado PJE PFX"
create_secret "momento_fiscal_pje_auth_pfx_password" "Digite a senha do certificado PFX: "

# 12. PJE Auth Certchain
echo ""
echo "📦 12/13 - Certificate Chain PJE (arquivo .pem)"
echo "Informe o caminho do arquivo certchain.pem: "
read certchain_file
if [ -f "$certchain_file" ]; then
    cat "$certchain_file" | docker secret create momento_fiscal_pje_auth_certchain -
    echo -e "${GREEN}✅ Secret 'momento_fiscal_pje_auth_certchain' criado${NC}"
else
    echo -e "${YELLOW}⚠️  Arquivo não encontrado. Pulando... (configure depois)${NC}"
fi

# 13. Google API PFX Base64
echo ""
echo "📦 13/13 - Google API PFX Base64"
echo "Informe o caminho do arquivo Google API .pfx: "
read google_pfx_file
if [ -f "$google_pfx_file" ]; then
    cat "$google_pfx_file" | base64 -w 0 | docker secret create momento_fiscal_google_api_pfx_base64 -
    echo -e "${GREEN}✅ Secret 'momento_fiscal_google_api_pfx_base64' criado${NC}"
else
    echo -e "${YELLOW}⚠️  Arquivo não encontrado. Pulando... (configure depois)${NC}"
fi

echo ""
echo "================================================================"
echo "✅ Secrets criados com sucesso!"
echo "================================================================"
echo ""
echo "📋 Lista de secrets criados:"
docker secret ls | grep momento_fiscal
echo ""
echo "🔍 Para inspecionar um secret (não mostra o valor):"
echo "   docker secret inspect momento_fiscal_postgres_password"
echo ""
echo "🎯 Próximo passo:"
echo "   Configure o arquivo .env e execute: bash deploy.sh"
echo ""
