# ETL para CNPJs - Via Docker

## Rodar com Docker (recomendado no Windows)

### 1. Build da imagem:
```bash
docker build -t cnpj-etl etl/
```

### 2. Testar com 100 registros:
```bash
docker run --rm \
  --network momento-fiscal-main_default \
  -v C:/cnpjs:/cnpjs \
  -e DB_HOST=db \
  -e DB_PORT=5432 \
  -e DB_NAME=momento_fiscal_api_production \
  -e DB_USER=postgres \
  -e DB_PASSWORD=postgres \
  cnpj-etl python import_cnpj.py --limit 100
```

### 3. Importar tudo:
```bash
docker run --rm \
  --network momento-fiscal-main_default \
  -v C:/cnpjs:/cnpjs \
  -e DB_HOST=db \
  -e DB_PORT=5432 \
  -e DB_NAME=momento_fiscal_api_production \
  -e DB_USER=postgres \
  -e DB_PASSWORD=postgres \
  cnpj-etl python import_cnpj.py
```

## Atalho PowerShell

```powershell
# Teste
docker run --rm --network momento-fiscal-main_default -v C:/cnpjs:/cnpjs -e DB_HOST=db -e DB_PORT=5432 -e DB_NAME=momento_fiscal_api_production -e DB_USER=postgres -e DB_PASSWORD=postgres cnpj-etl python import_cnpj.py --limit 100

# Full
docker run --rm --network momento-fiscal-main_default -v C:/cnpjs:/cnpjs -e DB_HOST=db -e DB_PORT=5432 -e DB_NAME=momento_fiscal_api_production -e DB_USER=postgres -e DB_PASSWORD=postgres cnpj-etl python import_cnpj.py
```
