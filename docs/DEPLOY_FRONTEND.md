# Deploy Frontend Flutter Web

**Última atualização:** 07/01/2026

## Visão Geral

O frontend é um app Flutter compilado para Web, servido via Nginx dentro de um container Docker. O deploy é feito através de uma imagem Docker exportada e carregada no servidor.

---

## Processo de Deploy Completo

### 1. Build do Flutter Web

```powershell
cd "c:\momento-fiscal-transferencia\source-code\momento-fiscal-main\mobile"

# Build para produção na raiz
flutter build web --release --base-href "/"
```

**Resultado:** Gera pasta `build/web` com todos os assets compilados.

### 2. Build da Imagem Docker

```powershell
# Cria imagem Docker com Nginx servindo o build
docker build -t momento-fiscal-frontend:latest .

# Exporta imagem para arquivo .tar
docker save momento-fiscal-frontend:latest -o frontend.image.tar
```

**Resultado:** Arquivo `frontend.image.tar` (~34MB) pronto para transferência.

### 3. Enviar para Servidor

```powershell
# Transfere imagem para /tmp do servidor
scp "c:\momento-fiscal-transferencia\source-code\momento-fiscal-main\mobile\frontend.image.tar" root@165.22.136.67:/tmp/
```

### 4. Carregar e Atualizar Serviço

```powershell
# Conecta ao servidor e executa:
# 1. Carrega a imagem no Docker local
# 2. Força atualização do serviço Docker Swarm
# 3. Remove arquivo temporário
ssh root@165.22.136.67 "docker load -i /tmp/frontend.image.tar && docker service update --force --image momento-fiscal-frontend:latest momento_fiscal_frontend && rm /tmp/frontend.image.tar"
```

**Resultado:** Serviço `momento_fiscal_frontend` atualizado com zero downtime.

---

## Estrutura do Frontend

### Arquivos Essenciais

```
mobile/
├── build/web/              # Build compilado (gerado)
├── lib/                    # Código-fonte Dart/Flutter
│   ├── core/
│   │   ├── models/         # Modelos de dados
│   │   └── services/       # Serviços (API calls)
│   └── pages/              # Telas da aplicação
├── Dockerfile              # Config para servir com Nginx
├── nginx.conf              # Configuração customizada Nginx
└── pubspec.yaml            # Dependências Flutter
```

### Dockerfile

```dockerfile
FROM nginx:alpine

COPY build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

### Nginx Config

O `nginx.conf` configura:
- Roteamento SPA (todas rotas → `index.html`)
- Compressão gzip
- Cache de assets estáticos
- Headers de segurança

---

## Scripts de Deploy Disponíveis

### 1. `deploy-frontend-simple.ps1` (Método Antigo)

Envia apenas o build + configs, faz build Docker no servidor.

```powershell
.\deploy-frontend-simple.ps1
```

**Quando usar:** Se não tem Docker local ou quer buildar no servidor.

### 2. Método Atual (Imagem Docker Pronta)

Build local + exportar imagem + carregar no servidor.

```powershell
# Script completo em uma linha
cd "c:\momento-fiscal-transferencia\source-code\momento-fiscal-main\mobile"; `
flutter build web --release --base-href "/"; `
docker build -t momento-fiscal-frontend:latest .; `
docker save momento-fiscal-frontend:latest -o frontend.image.tar; `
scp frontend.image.tar root@165.22.136.67:/tmp/; `
ssh root@165.22.136.67 "docker load -i /tmp/frontend.image.tar && docker service update --force --image momento-fiscal-frontend:latest momento_fiscal_frontend && rm /tmp/frontend.image.tar"
```

**Quando usar:** Deploy rápido e confiável (recomendado).

### 3. `enviar-prod.ps1` (Deploy Completo)

Envia todo o projeto (API + Frontend + Infra) compactado.

```powershell
.\enviar-prod.ps1
```

**Quando usar:** Deploy inicial ou atualização completa da aplicação.

---

## Alterações Recentes (07/01/2026)

### Problema: Resposta Datajud incompatível

**Sintoma:** Backend retornava processos, mas frontend mostrava "Processo não encontrado".

**Causa:** Backend retorna formato Datajud (campo `processos`), mas frontend esperava formato Jusbrasil (campo `content`).

**Solução:**

1. **ProcessNumberService** ([process_number_service.dart](../source-code/momento-fiscal-main/mobile/lib/core/services/processDataCrawlers/process_number_service.dart))
   - Detecta resposta Datajud (`processos` presente)
   - Converte para formato esperado usando `Jusbrasil.fromDatajud()`

2. **Modelo Jusbrasil** ([jusbrasil.dart](../source-code/momento-fiscal-main/mobile/lib/core/models/jusbrasil.dart))
   - Adicionado factory `Jusbrasil.fromDatajud()`
   - Adicionado factory `Content.fromDatajud()`
   - Adicionado factory `Tramitacao.fromDatajud()`
   - Conversão de campos: `tribunal`, `grau`, `classe`, `assuntos`, etc.

3. **Campos mapeados:**
   ```dart
   Backend (Datajud)         →  Frontend (Jusbrasil)
   ─────────────────────────────────────────────────
   processos[]               →  content[]
   numero_processo           →  numeroProcesso
   tribunal                  →  siglaTribunal
   classe                    →  classe[].descricao
   grau                      →  grau.sigla
   assuntos[]                →  assunto[].descricao
   orgao_julgador            →  orgaoJulgador.nome
   data_ajuizamento          →  dataHoraUltimaDistribuicao
   ```

---

## Verificação Pós-Deploy

### 1. Verificar serviço ativo

```bash
ssh root@165.22.136.67 "docker service ps momento_fiscal_frontend"
```

### 2. Verificar logs

```bash
ssh root@165.22.136.67 "docker service logs momento_fiscal_frontend --tail 50"
```

### 3. Testar aplicação

Acesse: https://momentofiscal.com.br/

Teste busca de processo: `0001136-33.2022.8.26.0011`

**Resultado esperado:**
- Backend busca em 91 tribunais (~10s)
- Encontra processo no TJSP
- Frontend exibe card com dados do processo

---

## Estrutura no Servidor

| Local | Descrição |
|-------|-----------|
| Docker Swarm Service | `momento_fiscal_frontend` |
| Porta interna | 80 (Nginx) |
| Porta pública | Via proxy reverso (nginx-proxy) |
| URL pública | https://momentofiscal.com.br/ |
| Imagem | `momento-fiscal-frontend:latest` |

---

## Troubleshooting

### Build Flutter falha

```powershell
# Limpar cache Flutter
flutter clean
flutter pub get
flutter build web --release --base-href "/"
```

### Imagem Docker muito grande

```powershell
# Ver tamanho da imagem
docker images momento-fiscal-frontend

# Limpar imagens antigas
docker image prune -a
```

### Serviço não atualiza

```bash
# Forçar recreação do container
ssh root@165.22.136.67 "docker service update --force momento_fiscal_frontend"

# Verificar réplicas
ssh root@165.22.136.67 "docker service ls | grep frontend"
```

### Frontend mostra tela branca

1. Verificar `base-href` no build: `/`
2. Verificar nginx.conf aponta para `/usr/share/nginx/html`
3. Verificar logs do Nginx:
   ```bash
   ssh root@165.22.136.67 "docker service logs momento_fiscal_frontend --tail 100"
   ```

### Processo não encontrado

1. Verificar backend está respondendo:
   ```bash
   ssh root@165.22.136.67 "curl -s 'http://localhost:3000/api/v1/processes/00011363320228260011' | head -c 500"
   ```

2. Verificar CORS habilitado no backend ([CORS_CONFIG.md](CORS_CONFIG.md))

3. Verificar console do navegador (F12) para erros JavaScript

---

## Boas Práticas

1. **Sempre teste localmente antes do deploy:**
   ```powershell
   cd mobile
   flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000
   ```

2. **Versione as imagens Docker:**
   ```powershell
   docker build -t momento-fiscal-frontend:v1.2.3 .
   docker tag momento-fiscal-frontend:v1.2.3 momento-fiscal-frontend:latest
   ```

3. **Mantenha backup da imagem anterior:**
   ```bash
   ssh root@165.22.136.67 "docker tag momento-fiscal-frontend:latest momento-fiscal-frontend:backup-$(date +%Y%m%d)"
   ```

4. **Monitore logs após deploy:**
   ```bash
   ssh root@165.22.136.67 "docker service logs -f momento_fiscal_frontend"
   ```

---

## Links Relacionados

- [DEPLOY_RAPIDO.md](DEPLOY_RAPIDO.md) - Deploy do backend
- [CORS_CONFIG.md](CORS_CONFIG.md) - Configuração de CORS
- [TESTE_LOCAL.md](TESTE_LOCAL.md) - Testes em ambiente local
- [PROBLEMA_ROTAS_2026-01-07.md](../PROBLEMA_ROTAS_2026-01-07.md) - Histórico de correções
