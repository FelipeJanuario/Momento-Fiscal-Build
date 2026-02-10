# 🌐 Configuração de CORS - Momento Fiscal

## 📋 Visão Geral

O projeto usa a gem `rack-cors` com controle por variável de ambiente `DEV_MODE` para gerenciar políticas de CORS entre desenvolvimento e produção.

---

## ⚙️ Configuração

### Arquivos Modificados

1. **`api/Gemfile`** - Gem rack-cors habilitada
2. **`api/config/initializers/cors.rb`** - Lógica condicional de CORS
3. **`.env.local.example`** - Variável DEV_MODE para desenvolvimento
4. **`.env.production.example`** - Variável DEV_MODE para produção
5. **`docker-compose.local.yml`** - Variável DEV_MODE nos containers

---

## 🔧 Como Funciona

### Lógica do CORS (config/initializers/cors.rb)

```ruby
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # Em modo DEV (DEV_MODE=true), permite qualquer origem
    # Em produção (DEV_MODE=false), restringe para domínios específicos
    if ENV['DEV_MODE'] == 'true'
      origins '*'
    else
      # Configure aqui os domínios permitidos em produção
      origins [
        'https://momentofiscal.com.br',
        'https://www.momentofiscal.com.br',
        'https://app.momentofiscal.com.br'
      ]
    end

    resource "*",
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: true
  end
end
```

---

## 💻 Desenvolvimento Local

### Configuração (.env.local)

```bash
# Modo Desenvolvimento - CORS liberado para qualquer origem
DEV_MODE=true
```

### Comportamento

- ✅ Permite requisições de **qualquer origem** (`*`)
- ✅ Flutter Web local (`http://localhost`) funciona
- ✅ Testes com Postman/Insomnia funcionam
- ✅ Frontend rodando em qualquer porta/domínio funciona

### Como usar

```powershell
# 1. Criar arquivo .env.local a partir do exemplo
cd source-code\momento-fiscal-main
Copy-Item .env.local.example .env.local

# 2. Subir containers (DEV_MODE=true já está no docker-compose.local.yml)
docker-compose -f docker-compose.local.yml up -d

# 3. Verificar logs
docker-compose -f docker-compose.local.yml logs -f backend
```

---

## 🚀 Produção (Digital Ocean VM)

### Configuração (.env na VM)

```bash
# Modo Produção - CORS restrito
DEV_MODE=false

# Domínios permitidos (edite conforme necessário)
ALLOWED_ORIGINS=https://momentofiscal.spezi.com.br,https://app.momentofiscal.com.br
```

### Comportamento

- ✅ Permite requisições **apenas** dos domínios configurados
- ❌ Bloqueia qualquer outro domínio
- 🔒 Segurança mantida
- 🛡️ Proteção contra ataques CSRF/XSS de origens não autorizadas

### Deploy em Produção

```bash
# 1. Conectar na VM
ssh root@167.172.209.132

# 2. Navegar para o projeto
cd /opt/momento-fiscal

# 3. Criar/editar arquivo .env
nano .env

# Adicionar:
DEV_MODE=false
RAILS_ENV=production
SECRET_KEY_BASE=<sua-chave-secreta-aqui>
DATABASE_URL=postgresql://user:pass@db:5432/momento_fiscal_api_production

# 4. Build e deploy
bash infrastructure/scripts/deploy.sh

# 5. Verificar se CORS está funcionando
docker-compose logs backend | grep -i cors
```

---

## 🎯 Comparação: DEV vs PROD

| Aspecto | Desenvolvimento (`DEV_MODE=true`) | Produção (`DEV_MODE=false`) |
|---------|-----------------------------------|------------------------------|
| **Origins permitidas** | `*` (todas) | Apenas domínios específicos |
| **Segurança** | Baixa (para facilitar testes) | Alta (protegido) |
| **Onde usar** | `localhost`, Docker local | VM Digital Ocean |
| **Flutter Web local** | ✅ Funciona sem configuração | ❌ Bloqueado (não está na lista) |
| **Postman/Insomnia** | ✅ Funciona | ❌ Bloqueado (não é navegador) |
| **App Mobile nativo** | ✅ Funciona | ✅ Funciona (sem CORS) |
| **Mudança de config** | Restart container | Restart container |

---

## 🔄 Adicionando Novos Domínios em Produção

### Cenário: Adicionar novo domínio ao CORS

```bash
# 1. Conectar na VM
ssh root@167.172.209.132

# 2. Editar config/initializers/cors.rb
cd /opt/momento-fiscal
nano api/config/initializers/cors.rb

# 3. Adicionar novo domínio na lista:
origins [
  'https://momentofiscal.com.br',
  'https://www.momentofiscal.com.br',
  'https://app.momentofiscal.com.br',
  'https://novo-dominio.com'  # <- NOVO
]

# 4. Rebuild e restart
docker-compose build backend
docker-compose restart backend

# 5. Verificar
curl -H "Origin: https://novo-dominio.com" \
     -H "Access-Control-Request-Method: POST" \
     -X OPTIONS \
     --verbose \
     https://api.momentofiscal.com.br/api/health/up
```

---

## 🧪 Testando CORS

### Teste Local (DEV_MODE=true)

```powershell
# Deve funcionar de qualquer origem
curl -H "Origin: http://localhost:3000" `
     -H "Access-Control-Request-Method: POST" `
     -X OPTIONS `
     --verbose `
     http://localhost:3000/api/health/up
```

**Resposta esperada:**
```
< HTTP/1.1 204 No Content
< Access-Control-Allow-Origin: http://localhost:3000
< Access-Control-Allow-Methods: GET, POST, PUT, PATCH, DELETE, OPTIONS, HEAD
```

### Teste Produção (DEV_MODE=false)

```bash
# Origem permitida - deve funcionar
curl -H "Origin: https://momentofiscal.spezi.com.br" \
     -H "Access-Control-Request-Method: POST" \
     -X OPTIONS \
     --verbose \
     https://api.momentofiscal.com.br/api/health/up
# ✅ Retorna: Access-Control-Allow-Origin: https://momentofiscal.spezi.com.br

# Origem não permitida - deve bloquear
curl -H "Origin: https://site-malicioso.com" \
     -H "Access-Control-Request-Method: POST" \
     -X OPTIONS \
     --verbose \
     https://api.momentofiscal.com.br/api/health/up
# ❌ NÃO retorna header Access-Control-Allow-Origin
```

---

## 🐛 Troubleshooting

### Problema: CORS não está funcionando em produção

**Verificações:**

```bash
# 1. Confirmar que DEV_MODE está setado
ssh root@167.172.209.132
cd /opt/momento-fiscal
cat .env | grep DEV_MODE
# Deve mostrar: DEV_MODE=false

# 2. Verificar se rack-cors está carregado
docker-compose exec backend rails runner \
  "puts Rails.application.config.middleware"
# Deve incluir: use Rack::Cors

# 3. Ver logs
docker-compose logs backend | grep -i cors

# 4. Testar manualmente
docker-compose exec backend rails runner \
  "puts ENV['DEV_MODE']"
# Deve mostrar: false
```

### Problema: CORS bloqueando requisições legítimas

**Solução: Adicionar domínio à lista**

Edite `api/config/initializers/cors.rb` e adicione o domínio:

```ruby
origins [
  'https://momentofiscal.com.br',
  'https://seu-novo-dominio.com'  # Adicione aqui
]
```

Depois:
```bash
docker-compose build backend
docker-compose restart backend
```

### Problema: CORS funciona local mas não em produção

**Causa comum:** `DEV_MODE` não está definido no `.env` da VM

**Solução:**
```bash
echo "DEV_MODE=false" >> /opt/momento-fiscal/.env
docker-compose restart backend
```

---

## 📝 Checklist de Deploy

Antes de fazer deploy em produção, confirme:

- [ ] `DEV_MODE=false` no arquivo `.env` da VM
- [ ] `RAILS_ENV=production` configurado
- [ ] Domínios corretos em `config/initializers/cors.rb`
- [ ] DNS apontando para o IP da VM
- [ ] SSL/TLS configurado (Traefik)
- [ ] Teste de CORS executado com sucesso
- [ ] Logs do backend verificados (sem erros de CORS)

---

## 🔐 Segurança

### ⚠️ NUNCA faça isso em produção:

```ruby
# ❌ INSEGURO - Permite qualquer origem
origins '*'

# ❌ INSEGURO - Wildcard em subdomínio
origins 'https://*.example.com'
```

### ✅ Sempre faça isso em produção:

```ruby
# ✅ SEGURO - Lista explícita de domínios
origins [
  'https://dominio1.com',
  'https://dominio2.com'
]

# ✅ SEGURO - Validação por variável de ambiente
origins ENV.fetch('ALLOWED_ORIGINS', '').split(',')
```

---

## 📚 Referências

- [rack-cors gem](https://github.com/cyu/rack-cors)
- [MDN - CORS](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS)
- [Rails Security Guide](https://guides.rubyonrails.org/security.html)

---

## 📞 Suporte

Se encontrar problemas com CORS:

1. Verifique os logs: `docker-compose logs backend`
2. Confirme a variável `DEV_MODE`
3. Teste com `curl` como mostrado acima
4. Verifique se o domínio está na lista de origins permitidas

---

**Última atualização:** 19/12/2025  
**Versão:** 1.0
