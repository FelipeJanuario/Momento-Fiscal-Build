# Backup e Restore de Banco de Dados PostgreSQL

## 📚 Lições Aprendidas

### 1. **Formato do Backup PostgreSQL**
- O `pg_dump` com opção `-Fc` (formato custom) cria arquivos binários começando com `PGDMP`
- Este formato é compacto e permite restore seletivo
- Pode verificar o formato com: `Get-Content -Encoding Byte -TotalCount 5`

### 2. **Diferença entre Banco Local e Produção**
- **Banco Local** (porta 5434): Usado para desenvolvimento e ETL
- **Banco Produção** (porta 5432 na VM): Usado pela aplicação em produção
- Backups antigos podem **NÃO** conter dados de migrations recentes!

### 3. **Estrutura de Containers Docker**
- Container do PostgreSQL não tem acesso direto ao filesystem do host
- É necessário copiar arquivos para dentro do container antes do restore
- Comando: `docker cp arquivo container:/tmp/`

### 4. **Usuários do PostgreSQL**
- Backup pode conter referências a usuários específicos (`momento_fiscal`)
- Se o usuário não existir na produção, usar `postgres` (superuser)
- Verificar usuários disponíveis: `\du`

## 🔄 Processo Completo

### Passo 1: Criar Backup do Banco Local
```powershell
# O banco local se chama: momento_fiscal_api_production
docker exec momento-fiscal-main-db-1 pg_dump -U postgres -d momento_fiscal_api_production -Fc -v -f /tmp/etl_backup.backup
```

### Passo 2: Copiar Backup para Fora do Container
```powershell
docker cp momento-fiscal-main-db-1:/tmp/etl_backup.backup "c:\momento-fiscal-transferencia\backups\database\etl_backup.backup"

# Verificar tamanho
Get-Item "c:\momento-fiscal-transferencia\backups\database\etl_backup.backup" | Select-Object Name, @{N='Size_MB';E={[math]::Round($_.Length/1MB,2)}}
```

### Passo 3: Transferir para VM via SCP (pode demorar - arquivo é ~1.7GB)
```powershell
scp "c:\momento-fiscal-transferencia\backups\database\etl_backup.backup" root@165.22.136.67:/root/
```

### Passo 4: Identificar Container e Copiar
```powershell
# Identificar container PostgreSQL
$container = ssh root@165.22.136.67 "docker ps -q -f name=momento_fiscal_db"
Write-Host "Container: $container"

# Copiar para dentro do container
ssh root@165.22.136.67 "docker cp /root/etl_backup.backup ${container}:/tmp/etl_backup.backup"
```

### Passo 5: Restaurar no Banco de Produção
```powershell
# O banco de produção se chama: momento_fiscal_production
ssh root@165.22.136.67 "docker exec ${container} pg_restore -U postgres -d momento_fiscal_production --clean --if-exists -v /tmp/etl_backup.backup"
```

### Passo 6: Verificar Dados
```powershell
ssh root@165.22.136.67 "docker exec ${container} psql -U postgres -d momento_fiscal_production -c 'SELECT (SELECT COUNT(*) FROM empresas) as empresas, (SELECT COUNT(*) FROM estabelecimentos) as estabelecimentos, (SELECT COUNT(*) FROM dividas) as dividas'"

# Resultado esperado (Jan/2026):
# empresas: 65.696.874
# estabelecimentos: 3.655.445
# dividas: variável
```

### Passo 7: Limpar Arquivos Temporários
```powershell
ssh root@165.22.136.67 "rm -f /root/etl_backup.backup; docker exec ${container} rm -f /tmp/etl_backup.backup"
```

## ⚠️ Cuidados Importantes

1. **--clean --if-exists**: Remove dados existentes antes de restaurar
2. **Verificar espaço em disco**: Backups podem ser grandes (37+ MB)
3. **Testar em staging**: Sempre teste antes de produção
4. **Backup de segurança**: Faça backup da produção antes de sobrescrever
5. **Validar API**: Teste endpoints após restore

## 🎯 Checklist de Validação

- [ ] Backup criado com sucesso (verificar tamanho do arquivo)
- [ ] Formato do backup válido (PGDMP nos primeiros 5 bytes)
- [ ] Transferência SCP concluída sem erros
- [ ] Arquivo copiado para dentro do container
- [ ] Restore executado sem erros
- [ ] Contagem de registros confere
- [ ] API retorna dados corretamente
- [ ] Sem erros 500 nos logs do backend

## 📊 Dados Esperados (após ETL completo - Jan/2026)

- **Empresas**: ~65.696.874 registros
- **Estabelecimentos**: ~3.655.445 registros
- **Estabelecimentos geocodificados**: ~40.337 registros
- **Tamanho do backup**: ~1.7 GB (formato custom compactado)

## 🔍 Troubleshooting

### Erro: "input file does not appear to be a valid archive"
- Verificar os primeiros bytes do arquivo
- Pode ser um backup em formato SQL text (não custom)

### Erro: "role does not exist"
- Usar usuário `postgres` em vez do usuário específico
- Ou criar o usuário antes: `CREATE ROLE momento_fiscal LOGIN;`

### Erro: "could not open input file"
- Arquivo não está dentro do container
- Executar `docker cp` antes do `pg_restore`

### API retorna 200 mas sem dados
- Verificar se tabelas foram criadas: `\dt`
- Verificar se há registros: `SELECT COUNT(*) FROM estabelecimentos;`
- Conferir se migration rodou corretamente
