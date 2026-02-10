# Atualizar Role de Usuário

## Comandos para atualizar role diretamente no PostgreSQL

### 1. Ver nome do container do banco de dados
```bash
docker ps | grep postgres
```

### 2. Atualizar role do usuário (por email)
```bash
docker exec momento_fiscal_db.1.skmyo0p2fyr2ldhg2n08v6ob8 psql -U postgres -d momento_fiscal_production -c "UPDATE users SET role = 2 WHERE email = 'ataideotimiza2@gmail.com';"
```

### 3. Verificar se a atualização funcionou
```bash
docker exec momento_fiscal_db.1.skmyo0p2fyr2ldhg2n08v6ob8 psql -U postgres -d momento_fiscal_production -c "SELECT email, role FROM users WHERE email = 'ataideotimiza2@gmail.com';"
```

### 4. Listar todos os usuários e suas roles
```bash
docker exec momento_fiscal_db.1.skmyo0p2fyr2ldhg2n08v6ob8 psql -U postgres -d momento_fiscal_production -c "SELECT email, role FROM users;"
```

### 5. Ver estrutura da tabela users
```bash
docker exec momento_fiscal_db.1.skmyo0p2fyr2ldhg2n08v6ob8 psql -U postgres -d momento_fiscal_production -c "\d users"
```

## Valores de Role

- **0** = user (usuário comum)
- **1** = consultant (consultor)
- **2** = admin (administrador)

## Notas

- Os CPFs estão criptografados no banco de dados (Lockbox)
- Use o `email` para identificar usuários ao atualizar
- Após atualizar o role, o usuário precisa fazer **logout e login novamente** no app para que a mudança seja carregada
- Container do banco: `momento_fiscal_db.1.skmyo0p2fyr2ldhg2n08v6ob8` (pode mudar se o serviço for recriado)
- Credenciais: 
  - User: `postgres`
  - Database: `momento_fiscal_production`
  - Password: `TECHbyops30!`
