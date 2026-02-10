# 🧪 Guia de Teste Local

Este guia explica como testar a aplicação localmente antes do deploy em produção.

---

## 📋 PRÉ-REQUISITOS

- Docker Desktop instalado e rodando
- Porta 3000 disponível (ou altere no docker-compose)
- Porta 5434 disponível para PostgreSQL
- ~4GB RAM disponível

---

## 🚀 QUICK START

### 1. Preparar ambiente

```powershell
cd C:\momento-fiscal-transferencia\source-code\momento-fiscal-main

# Copiar arquivo de variáveis
Copy-Item .env.local.example .env.local
```

### 2. (Opcional) Editar .env.local

Se quiser testar com APIs reais, edite o arquivo `.env.local`:

```powershell
notepad .env.local
```

### 3. Iniciar aplicação

```powershell
docker-compose -f docker-compose.local.yml up -d
```

Isso irá:
- ✅ Baixar imagens (primeira vez)
- ✅ Fazer build da API
- ✅ Criar banco de dados
- ✅ Executar migrations
- ✅ Iniciar todos os serviços

**Tempo estimado (primeira vez):** 5-10 minutos

### 4. Acompanhar logs

```powershell
# Ver todos os logs
docker-compose -f docker-compose.local.yml logs -f

# Ver apenas logs do backend
docker-compose -f docker-compose.local.yml logs -f backend

# Ver apenas logs do Sidekiq
docker-compose -f docker-compose.local.yml logs -f sidekiq
```

### 5. Testar a API

Aguarde o backend iniciar e teste:

```powershell
# Health check
curl http://localhost:3000/api/health/up

# Deve retornar: {"status":"ok"}
```

---

## 🗄️ RESTAURAR BACKUP (Opcional)

Se quiser testar com dados reais do backup:

```powershell
# 1. Aguardar backend estar pronto
Start-Sleep -Seconds 30

# 2. Pegar ID do container do PostgreSQL
$DB_CONTAINER = docker ps -q -f name=momento-fiscal-main-db-1

# 3. Restaurar backup
docker exec -i $DB_CONTAINER pg_restore `
  -U postgres `
  -d momento_fiscal_api_production `
  -c `
  /backups/momento_fiscal_production.backup
```

---

## 🧪 TESTES

### Testar Autenticação

```powershell
# Criar usuário de teste (via console Rails)
$BACKEND = docker ps -q -f name=momento-fiscal-main-backend-1
docker exec -it $BACKEND rails console

# No console Rails:
# User.create!(
#   email: 'teste@exemplo.com',
#   password: 'senha123',
#   name: 'Usuario Teste',
#   cpf: '12345678901',
#   phone: '(11) 99999-9999',
#   birth_date: 20.years.ago,
#   sex: 'male',
#   role: 'client'
# )
# exit
```

### Testar Login

```powershell
curl -X POST http://localhost:3000/api/v1/authentication/users/sign_in `
  -H "Content-Type: application/json" `
  -d '{\"user\":{\"email\":\"teste@exemplo.com\",\"password\":\"senha123\"}}'
```

### Testar com Postman

Importe a collection OpenAPI:
- URL: `http://localhost:3000`
- Arquivo: `docs/spec/openapi/openapi.yml`

---

## 📊 SERVIÇOS DISPONÍVEIS

| Serviço | URL/Porta | Descrição |
|---------|-----------|-----------|
| **API Backend** | http://localhost:3000 | Rails API |
| **PostgreSQL** | localhost:5434 | Banco de dados |
| **Redis** | localhost:6379 | Cache e jobs |
| **Sidekiq** | - | Background jobs |

### Conectar no PostgreSQL

Use pgAdmin 4 ou qualquer cliente:

```
Host: localhost
Port: 5434
Database: momento_fiscal_api_production
Username: postgres
Password: TECHbyops30!
```

---

## 🔧 COMANDOS ÚTEIS

### Gerenciar containers

```powershell
# Parar todos os serviços
docker-compose -f docker-compose.local.yml stop

# Iniciar novamente
docker-compose -f docker-compose.local.yml start

# Reiniciar um serviço específico
docker-compose -f docker-compose.local.yml restart backend

# Remover tudo (incluindo volumes)
docker-compose -f docker-compose.local.yml down -v
```

### Acessar containers

```powershell
# Rails console
docker-compose -f docker-compose.local.yml exec backend rails console

# Bash no backend
docker-compose -f docker-compose.local.yml exec backend bash

# PostgreSQL shell
docker-compose -f docker-compose.local.yml exec db psql -U postgres -d momento_fiscal_api_production
```

### Executar comandos Rails

```powershell
# Migrations
docker-compose -f docker-compose.local.yml exec backend rails db:migrate

# Rollback
docker-compose -f docker-compose.local.yml exec backend rails db:rollback

# Seed
docker-compose -f docker-compose.local.yml exec backend rails db:seed

# Routes
docker-compose -f docker-compose.local.yml exec backend rails routes
```

### Ver status

```powershell
# Listar containers
docker-compose -f docker-compose.local.yml ps

# Ver recursos
docker stats

# Ver logs de erro
docker-compose -f docker-compose.local.yml logs backend | Select-String -Pattern "ERROR"
```

---

## 🧹 LIMPEZA

### Limpar tudo e recomeçar

```powershell
# Parar e remover containers, networks e volumes
docker-compose -f docker-compose.local.yml down -v

# Limpar imagens não utilizadas
docker system prune -a
```

---

## 🐛 TROUBLESHOOTING

### Backend não inicia

```powershell
# Ver logs detalhados
docker-compose -f docker-compose.local.yml logs backend

# Problemas comuns:
# 1. Porta 3000 em uso → Altere no docker-compose.local.yml
# 2. Migrations falharam → Execute manualmente
# 3. Credenciais incorretas → Verifique .env.local
```

### Erro de conexão com banco

```powershell
# Verificar se PostgreSQL está rodando
docker-compose -f docker-compose.local.yml ps db

# Verificar logs do banco
docker-compose -f docker-compose.local.yml logs db

# Recriar banco
docker-compose -f docker-compose.local.yml down -v
docker-compose -f docker-compose.local.yml up -d
```

### Rebuild da imagem

Se fez alterações no código:

```powershell
# Rebuild e restart
docker-compose -f docker-compose.local.yml up -d --build backend
```

---

## 📱 TESTAR COM MOBILE

Para testar o app mobile contra o backend local:

1. No arquivo `mobile/lib/core/utilities/api_constants.dart`, altere:

```dart
static String url = "http://SEU_IP_LOCAL:3000";
```

2. Se estiver usando emulador Android:
```dart
static String url = "http://10.0.2.2:3000";  // Localhost do emulador
```

3. Se estiver usando device físico:
```dart
static String url = "http://192.168.1.XXX:3000";  // IP da sua máquina
```

---

## ✅ CHECKLIST DE TESTE

Antes de fazer deploy em produção, teste:

- [ ] Health check responde OK
- [ ] Login funciona
- [ ] Criar usuário funciona
- [ ] Consultas funcionam
- [ ] Background jobs rodam (Sidekiq)
- [ ] Logs não mostram erros críticos
- [ ] Banco de dados persiste dados
- [ ] APIs externas respondem (se configuradas)

---

## 🚀 PRÓXIMO PASSO

Se tudo funcionar localmente, siga para o deploy em produção:

```powershell
# Ver guia de deploy
Get-Content DEPLOY_GUIDE.md
```

---

**Boa sorte nos testes!** 🎉



# Teste local (padrão)
python test-all.py

# Teste em produção
python test-all.py --env production --url https://api.momentofiscal.com.br

# Ver opções
python test-all.py --help