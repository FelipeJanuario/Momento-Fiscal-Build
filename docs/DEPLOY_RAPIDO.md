# Deploy Rápido - Backend API

**Última atualização:** 16/01/2026

## Processo de Deploy (5 passos)

### 1. Comprimir código completo da API

```powershell
cd "c:\momento-fiscal-transferencia\source-code\momento-fiscal-main"
Compress-Archive -Path "api\*" -DestinationPath "api.zip" -Force
```

### 2. Enviar para servidor

```powershell
scp "c:\momento-fiscal-transferencia\source-code\momento-fiscal-main\api.zip" root@165.22.136.67:/tmp/api.zip
```

### 3. Extrair no servidor

```bash
ssh root@165.22.136.67 "rm -rf /root/momento-fiscal-main/api && mkdir -p /root/momento-fiscal-main/api && cd /root/momento-fiscal-main/api && unzip -o /tmp/api.zip && rm /tmp/api.zip"
```

### 4. Rebuild da imagem e update do service

```bash
ssh root@165.22.136.67 "cd /root/momento-fiscal-main/api && docker build -t momento-fiscal-api:latest . && docker service update --force --image momento-fiscal-api:latest momento_fiscal_backend"
```

### 5. Verificar deploy

```bash
# Aguardar convergência (até "Service converged")
# Health check é automático via HEALTHCHECK no Dockerfile
```

---

## Estrutura no Servidor

| Local | Descrição |
|-------|-----------|
| `/root/momento-fiscal-main/` | Raiz do projeto |
| `/root/momento-fiscal-main/api/` | Código da API Rails |
| `/root/momento-fiscal-main/api/config/routes.rb` | Rotas |
| `/root/momento-fiscal-main/api/app/` | Controllers, Services, Models |

---

## Comandos Úteis

```bash
# Ver logs do backend
ssh root@165.22.136.67 "docker service logs momento_fiscal_backend --tail 50"

# Ver container rodando
ssh root@165.22.136.67 "docker ps --filter name=momento_fiscal_backend"

# Reiniciar service sem rebuild
ssh root@165.22.136.67 "docker service update --force momento_fiscal_backend"

# Ver status dos services
ssh root@165.22.136.67 "docker service ls"
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
