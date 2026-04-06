# Deploy Rápido - Backend API

**Última atualização:** 28/03/2026

## ⚠️ Regras de Ouro (NUNCA fazer)

- **NUNCA** executar `docker stack rm` como parte do deploy — destrói os volumes `postgres` e `redis`
- **NUNCA** executar `docker-compose down -v` — a flag `-v` apaga volumes
- **NUNCA** re-executar `create-secrets.sh` em produção — regenera `SECRET_KEY_BASE` e invalida todas as sessões/tokens, e pode corromper dados criptografados
- **NUNCA** executar `docker volume prune` ou `docker volume rm postgres` na VM de produção

---

## Deploy Completo (Backend + Frontend)

### Opção A — Script automatizado (recomendado)

```powershell
# No PowerShell local, a partir da pasta momento-fiscal/
.\deploy-backend-only.ps1
.\deploy-frontend-only.ps1
```

O script `deploy-backend-only.ps1` executa automaticamente:
1. Backup `pg_dump` pré-deploy em `/root/backups/pre_deploy_YYYYMMDD_HHMMSS.backup`
2. Rsync do código para a VM
3. `docker build` da nova imagem
4. `docker service update` do backend **e** do sidekiq
5. Pergunta se deve rodar `rails db:migrate`
6. Health check de validação

---

### Opção B — Comandos manuais passo a passo

#### 0. Backup pré-deploy (obrigatório)

```bash
ssh root@165.22.136.67 '
  DB_CONTAINER=$(docker ps -q -f name=momento_fiscal_db | head -1)
  mkdir -p /root/backups
  docker exec $DB_CONTAINER pg_dump -U postgres -d momento_fiscal_production -Fc -f /tmp/pre_deploy.backup
  docker cp $DB_CONTAINER:/tmp/pre_deploy.backup /root/backups/pre_deploy_$(date +%Y%m%d_%H%M%S).backup
  docker exec $DB_CONTAINER rm /tmp/pre_deploy.backup
  echo "Backup OK:"
  ls -lh /root/backups/ | tail -3
'
```

#### 1. Sincronizar código via rsync

```powershell
# No PowerShell local
rsync -avz --delete --exclude='log/' --exclude='tmp/' --exclude='storage/' --exclude='.git/' `
  "c:\momento-fiscal-transferencia\source-code\momento-fiscal-main\api/" `
  "root@165.22.136.67:/root/momento-fiscal-main/api/"
```

#### 2. Build da nova imagem na VM

```bash
ssh root@165.22.136.67 "cd /root/momento-fiscal-main/api && docker build -t momento-fiscal-api:latest ."
```

#### 3. Atualizar serviços (sem derrubar o banco)

```bash
# Atualizar backend
ssh root@165.22.136.67 "docker service update --force --image momento-fiscal-api:latest momento_fiscal_backend"

# Atualizar sidekiq (mesma imagem do backend)
ssh root@165.22.136.67 "docker service update --force --image momento-fiscal-api:latest momento_fiscal_sidekiq"
```

#### 4. Rodar migrations (somente se houver migrações novas)

```bash
ssh root@165.22.136.67 '
  sleep 5
  BACKEND=$(docker ps -q -f name=momento_fiscal_backend | head -1)
  docker exec $BACKEND rails db:migrate
'
```

#### 5. Verificar deploy

```bash
# Status dos serviços
ssh root@165.22.136.67 "docker service ls"

# Health check
ssh root@165.22.136.67 "curl -s -o /dev/null -w '%{http_code}' http://localhost:3000/api/health/up"

# Logs do backend
ssh root@165.22.136.67 "docker service logs momento_fiscal_backend --tail 30"
```

---

## Estrutura no Servidor

| Local | Descrição |
|-------|-----------|
| `/root/momento-fiscal-main/` | Raiz do projeto |
| `/root/momento-fiscal-main/api/` | Código da API Rails |
| `/root/backups/` | Backups automáticos pré-deploy |

---

## Comandos Úteis

```bash
# Ver logs do backend
ssh root@165.22.136.67 "docker service logs momento_fiscal_backend --tail 50"

# Ver logs do sidekiq
ssh root@165.22.136.67 "docker service logs momento_fiscal_sidekiq --tail 30"

# Ver container rodando
ssh root@165.22.136.67 "docker ps --filter name=momento_fiscal"

# Reiniciar service sem rebuild
ssh root@165.22.136.67 "docker service update --force momento_fiscal_backend"

# Ver status dos services
ssh root@165.22.136.67 "docker service ls"

# Verificar volumes (banco de dados)
ssh root@165.22.136.67 "docker volume ls | grep momento"

# Listar backups disponíveis
ssh root@165.22.136.67 "ls -lh /root/backups/"
```

---

## Problema Resolvido em 07/01/2026

**Erro:** `NameError (uninitialized constant JusbrasilService::TRIBUNAIS)`

**Causa:** Arquivo `jusbrasil_service.rb` desatualizado no servidor

**Solução:** Copiar os 3 arquivos + rebuild da imagem Docker

**Arquivos atualizados:**
1. `routes.rb` - Nova rota `/processes/:numero_processo`
2. `processes_controller.rb` - Método `show_by_number`
3. `jusbrasil_service.rb` - Constante `TRIBUNAIS` com lista de tribunais
