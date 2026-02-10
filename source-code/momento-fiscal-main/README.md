# Momento Fiscal

[![Ruby](https://img.shields.io/badge/Ruby-3.3.6-red.svg)](https://www.ruby-lang.org/)
[![Rails](https://img.shields.io/badge/Rails-7.2.2-red.svg)](https://rubyonrails.org/)
[![Flutter](https://img.shields.io/badge/Flutter-3.4.3-blue.svg)](https://flutter.dev/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15-blue.svg)](https://www.postgresql.org/)

Plataforma completa para gestão e análise fiscal, oferecendo ferramentas para consultoria, análise de licitações, gestão de processos e assinaturas.

## 📋 Índice

- [Sobre o Projeto](#sobre-o-projeto)
- [Arquitetura](#arquitetura)
- [Tecnologias](#tecnologias)
- [Pré-requisitos](#pré-requisitos)
- [Configuração do Ambiente](#configuração-do-ambiente)
- [Estrutura do Projeto](#estrutura-do-projeto)
- [Desenvolvimento](#desenvolvimento)
- [Testes](#testes)
- [Deploy](#deploy)
- [Contribuindo](#contribuindo)
- [Licença](#licença)

## 🎯 Sobre o Projeto

O Momento Fiscal é uma solução completa que combina:

- **Backend API REST** em Ruby on Rails para gerenciamento de dados e lógica de negócio
- **Aplicativo Mobile** em Flutter para iOS e Android
- **Integrações** com Stripe, Google Play, SERPRO, JusBrasil e outros serviços
- **Análise de Licitações** com processamento de dados governamentais
- **Sistema de Assinaturas** com planos freemium e premium
- **Gestão de Documentos** com geração de PDFs e relatórios

## 🏗️ Arquitetura

Este é um monorepo organizado em 4 módulos principais:

```
momento-fiscal/
├── api/              # Backend Rails API
├── mobile/           # Aplicativo Flutter
├── infrastructure/   # Configurações de CI/CD e Docker
└── docs/            # Documentação e especificações
```

### Fluxo de Dados

```
Mobile App (Flutter)
       ↓
   API REST (Rails)
       ↓
   PostgreSQL + Redis
       ↓
   Background Jobs (Sidekiq)
       ↓
   Serviços Externos (Stripe, Google Play, SERPRO)
```

## 🛠️ Tecnologias

### Backend (API)

- **Framework**: Ruby on Rails 7.2.2
- **Linguagem**: Ruby 3.3.6
- **Banco de Dados**: PostgreSQL 15
- **Cache/Jobs**: Redis + Sidekiq
- **Autenticação**: Devise + JWT
- **Pagamentos**: Stripe, Google Play Billing
- **PDF Generation**: PDFKit + wkhtmltopdf
- **Testes**: RSpec, Factory Bot, Shoulda Matchers
- **Qualidade**: RuboCop, Brakeman, SimpleCov
- **Monitoramento**: OpenTelemetry

### Mobile

- **Framework**: Flutter SDK 3.4.3+
- **Linguagem**: Dart
- **Mapas**: Google Maps Flutter
- **Pagamentos**: In-App Purchase, Stripe, RevenueCat
- **Armazenamento**: Flutter Secure Storage, Shared Preferences
- **Editor**: Flutter Quill (editor de texto rico)
- **Geolocalização**: Geolocator

### Infrastructure

- **Containerização**: Docker + Docker Compose
- **Orquestração**: Docker Swarm
- **Proxy Reverso**: Traefik
- **CI/CD**: GitLab CI

## 📦 Pré-requisitos

### Para a API

- Ruby 3.3.6
- PostgreSQL 15+
- Redis 7+
- Bundler 2.5+
- wkhtmltopdf (para geração de PDFs)

### Para o Mobile

- Flutter SDK 3.4.3+
- Dart SDK
- Android Studio / Xcode (para builds nativos)
- CocoaPods (para iOS)

### Ferramentas de Desenvolvimento

- Git
- Docker e Docker Compose (opcional, mas recomendado)
- Editor de código (VS Code recomendado)

## ⚙️ Configuração do Ambiente

### Opção 1: Dev Container (Recomendado) 🚀

A forma mais rápida e consistente de configurar o ambiente de desenvolvimento é usando **Dev Containers**. Todo o ambiente já está pré-configurado!

#### Pré-requisitos

- [Visual Studio Code](https://code.visualstudio.com/)
- [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- [Dev Containers Extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)

#### Passos

1. **Clone o repositório**
   ```bash
   git clone <repository-url>
   cd momento-fiscal
   ```

2. **Abra no VS Code**
   ```bash
   code .
   ```

3. **Inicie o Dev Container**
   - O VS Code detectará o arquivo `.devcontainer/devcontainer.json`
   - Clique em "Reopen in Container" na notificação
   - Ou use `Ctrl+Shift+P` → "Dev Containers: Reopen in Container"

4. **Aguarde a inicialização**
   - O Docker irá construir a imagem e iniciar os serviços
   - PostgreSQL, Redis e outros serviços serão iniciados automaticamente
   - As extensões do VS Code serão instaladas automaticamente

5. **Configure o banco de dados**
   ```bash
   cd api
   rails db:create
   rails db:migrate
   rails db:seed
   ```

6. **Inicie os serviços**
   ```bash
   # Terminal 1: API Rails
   cd api && rails s -b 0.0.0.0 -p 3000
   
   # Terminal 2: Sidekiq (background jobs)
   cd api && bundle exec sidekiq -C config/sidekiq.yml
   ```

#### Portas Disponíveis

- **3000**: API Rails (`http://localhost:3000`)
- **5432**: PostgreSQL
- **8025**: MailHog (inbox de emails de desenvolvimento)

#### Variáveis de Ambiente

As variáveis já estão configuradas no `devcontainer.json` para desenvolvimento:
- Credenciais do banco de dados
- Chaves de API (Stripe, SERPRO, etc.) em modo de teste
- Configurações de Redis e serviços

### Opção 2: Configuração Manual

Se preferir não usar Dev Containers, siga estas etapas:

#### 1. Clone o Repositório

```bash
git clone <repository-url>
cd momento-fiscal
```

#### 2. Configuração da API

```bash
cd api

# Instalar dependências
bundle install

# Configurar variáveis de ambiente
cp .env.example .env
# Edite o arquivo .env com suas credenciais

# Criar e configurar banco de dados
rails db:create
rails db:migrate
rails db:seed

# Iniciar servidor de desenvolvimento
rails server
```

A API estará disponível em `http://localhost:3000`

#### Variáveis de Ambiente Essenciais

```env
DATABASE_HOST=localhost
DATABASE_USER=postgres
DATABASE_PASSWORD=your_password
REDIS_HOST=localhost
REDIS_PORT=6379
SECRET_KEY_BASE=your_secret_key
STRIPE_SECRET_KEY=your_stripe_key
SERPRO_CONSUMER_KEY=your_serpro_key
SERPRO_CONSUMER_SECRET=your_serpro_secret
JUSBRASIL_API_TOKEN=your_jusbrasil_token
BIDDINGS_ANALYSER_API_KEY=your_biddings_api_key
```

#### 3. Configuração do Mobile

```bash
cd mobile

# Instalar dependências
flutter pub get

# Executar o aplicativo
flutter run
```

#### Configuração de API Endpoint

Edite o arquivo de constantes com o endpoint da API:

```dart
// lib/constants.dart
const String API_BASE_URL = 'http://localhost:3000/api/v1';
```

### Opção 3: Docker Compose (Produção Local)

Para simular ambiente de produção localmente:

```bash
# Build e iniciar todos os serviços
docker-compose -f infrastructure/swarm_services/docker-compose.yml up -d

# Executar migrations
docker exec -it <container_id> rails db:migrate

# Ver logs
docker-compose logs -f
```

## 📁 Estrutura do Projeto

### API (Backend)

```
api/
├── app/
│   ├── controllers/     # Controladores REST API
│   ├── models/          # Models ActiveRecord
│   ├── services/        # Lógica de negócio
│   ├── jobs/           # Background jobs (Sidekiq)
│   └── mailers/        # Email templates
├── config/
│   ├── routes.rb       # Definição de rotas
│   └── initializers/   # Configurações iniciais
├── db/
│   └── migrate/        # Migrations do banco
├── spec/               # Testes RSpec
└── Dockerfile          # Container da aplicação
```

### Mobile (Flutter)

```
mobile/
├── lib/
│   ├── components/     # Componentes reutilizáveis
│   ├── core/          # Configurações e utilidades
│   ├── pages/         # Telas do aplicativo
│   ├── constants.dart  # Constantes globais
│   └── main.dart      # Entry point
├── assets/
│   └── images/        # Recursos de imagem
├── android/           # Código nativo Android
└── ios/              # Código nativo iOS
```

### Infrastructure

```
infrastructure/
├── ci_cd/
│   └── gitlab/        # Pipelines GitLab CI
├── dockerfiles/       # Dockerfiles específicos
├── scripts/          # Scripts de automação
└── swarm_services/
    └── docker-compose.yml  # Orquestração de serviços
```

## 💻 Desenvolvimento

### API - Principais Endpoints

```
POST   /api/v1/authentication/users/sign_in      # Login
POST   /api/v1/authentication/users/sign_up      # Registro
GET    /api/v1/users                             # Listar usuários
GET    /api/v1/consultings                       # Consultorias
GET    /api/v1/biddings_analyser/debts          # Análise de dívidas
POST   /api/v1/stripe/create_payment_intent     # Pagamento Stripe
GET    /api/v1/stripe/current_subscription      # Assinatura atual
```

### Rodando Background Jobs

```bash
# Desenvolvimento
bundle exec sidekiq

# Com Docker
docker-compose up sidekiq
```

### Mobile - Estrutura de Navegação

O aplicativo segue uma arquitetura baseada em páginas/telas com:

- Tela de autenticação e onboarding
- Dashboard principal
- Páginas de consultoria e análise
- Gerenciamento de assinaturas
- Configurações e perfil

## 🧪 Testes

### Backend (RSpec)

```bash
# Executar todos os testes
bundle exec rspec

# Executar teste específico
bundle exec rspec spec/models/user_spec.rb

# Cobertura de código
bundle exec rspec --format documentation

# Relatório de cobertura (SimpleCov)
open coverage/index.html
```

## 🚀 Deploy

### Produção com Docker Swarm

```bash
# 1. Build da imagem
docker build -t momento-fiscal-api:latest -f infrastructure/dockerfiles/Dockerfile.api .

# 2. Push para registry
docker push momento-fiscal-api:latest

# 3. Deploy no Swarm
docker stack deploy -c infrastructure/swarm_services/docker-compose.yml momento-fiscal

# 4. Verificar serviços
docker service ls

# 5. Executar migrations
docker exec $(docker ps -q -f name=momento-fiscal_backend) rails db:migrate
```

### Secrets (Docker Swarm)

Todos os secrets necessários devem ser criados antes do deploy. Abaixo está a lista completa:

#### Secrets Obrigatórios

```bash
# 1. Secret Key Base do Rails (gerado com: rails secret)
echo "your_generated_secret_key_base" | docker secret create momento_fiscal_secret_key_base -

# 2. Senha do PostgreSQL
echo "your_secure_postgres_password" | docker secret create momento_fiscal_postgres_password -

# 3. Senha do SMTP para envio de emails
echo "your_smtp_password" | docker secret create momento_fiscal_smtp_password -

# 4. Lockbox Master Key (para criptografia de dados sensíveis)
echo "your_lockbox_master_key" | docker secret create momento_fiscal_lockbox_master_key -

# 5. Active Record Encryption - Primary Key
echo "your_encryption_primary_key" | docker secret create momento_fiscal_active_record_encryption_primary_key -

# 6. Active Record Encryption - Deterministic Key
echo "your_encryption_deterministic_key" | docker secret create momento_fiscal_active_record_encryption_deterministic_key -

# 7. Active Record Encryption - Key Derivation Salt
echo "your_encryption_key_derivation_salt" | docker secret create momento_fiscal_active_record_encryption_key_derivation_salt -

# 8. API Key do Biddings Analyser
echo "your_biddings_analyser_api_key" | docker secret create momento_fiscal_biddings_analyser_api_key -

# 9. Stripe Secret Key (chave secreta de produção)
echo "your_stripe_secret_key" | docker secret create momento_fiscal_stripe_secret_key -

# 10. Certificado PFX para autenticação PJE
cat path/to/pje_auth.pfx | base64 -w 0 | docker secret create momento_fiscal_pje_auth_pfx -

# 11. Senha do certificado PFX do PJE
echo "your_pje_pfx_password" | docker secret create momento_fiscal_pje_auth_pfx_password -

# 12. Certificate Chain do PJE
cat path/to/pje_certchain.pem | docker secret create momento_fiscal_pje_auth_certchain -

# 13. Google API PFX em Base64 (para Google Play Billing)
echo "your_google_api_pfx_base64" | docker secret create momento_fiscal_google_api_pfx_base64 -
```

#### Variáveis de Ambiente Adicionais (não secrets)

Estas devem ser configuradas no arquivo `.env` ou exportadas antes do deploy:

```bash
# OpenTelemetry
export OTEL_SERVICE_NAME="momento-fiscal-api"
export OTEL_EXPORTER_OTLP_ENDPOINT="http://your-otel-collector:4318"

# SMTP Configuration
export MAIL_SMTP_PORT="587"
export MAIL_SMTP_LOGIN="your_smtp_login"
export MAIL_SMTP_DOMAIN="your_domain.com"
export MAIL_SMTP_SSL="true"

# Domain
export APP_DOMAIN="api.momentofiscal.com.br"

# Biddings Analyser
export BIDDINGS_ANALYSER_URL="https://your-biddings-api.com"

# JusBrasil
export JUSBRASIL_API_TOKEN="your_jusbrasil_token"

# SERPRO
export SERPRO_CONSUMER_KEY="your_serpro_key"
export SERPRO_CONSUMER_SECRET="your_serpro_secret"

# Stripe Publishable Key (pode ser pública)
export STRIPE_PUBLISHABLE_KEY="pk_live_xxxxx"
```

#### Script Helper para Criar Todos os Secrets

Crie um arquivo `create-secrets.sh`:

```bash
#!/bin/bash

# Validar se todos os arquivos/valores necessários existem
read -sp "PostgreSQL Password: " POSTGRES_PASSWORD && echo
read -sp "Rails Secret Key Base: " SECRET_KEY_BASE && echo
read -sp "SMTP Password: " SMTP_PASSWORD && echo
# ... continue para outros secrets

# Criar secrets
echo "$POSTGRES_PASSWORD" | docker secret create momento_fiscal_postgres_password -
echo "$SECRET_KEY_BASE" | docker secret create momento_fiscal_secret_key_base -
echo "$SMTP_PASSWORD" | docker secret create momento_fiscal_smtp_password -
# ... continue para outros secrets

echo "✅ Todos os secrets foram criados com sucesso!"
```

#### Listar Secrets Existentes

```bash
# Verificar todos os secrets criados
docker secret ls | grep momento_fiscal

# Inspecionar um secret específico (não mostra o valor)
docker secret inspect momento_fiscal_postgres_password
```

### Mobile - Build para Produção

#### Android

```bash
# Build APK
flutter build apk --release

# Build App Bundle (Google Play)
flutter build appbundle --release
```

#### iOS

```bash
# Build para App Store
flutter build ios --release

# Abrir no Xcode para upload
open ios/Runner.xcworkspace
```

## 📊 Monitoramento

A aplicação utiliza OpenTelemetry para monitoramento e rastreamento:

- Métricas de performance
- Rastreamento distribuído
- Logs estruturados
- Health checks em `/api/health/up`

## 🔐 Segurança

- Autenticação JWT com refresh tokens
- Criptografia de dados sensíveis (Active Record Encryption)
- Secrets management via Docker Secrets
- HTTPS/TLS em produção (via Traefik)
- Validação de entrada e sanitização
- Rate limiting e proteção contra ataques

## 📄 Licença

Este projeto é proprietário e confidencial. Todos os direitos reservados.

---

**Desenvolvido com ❤️ pela equipe Momento Fiscal**
