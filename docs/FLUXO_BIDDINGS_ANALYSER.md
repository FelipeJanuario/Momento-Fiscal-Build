# Fluxo Biddings Analyser API

## 🎯 Visão Geral

O **Biddings Analyser** é um serviço externo desenvolvido pela Spezi que fornece dados sobre empresas devedoras, débitos e licitações. A integração é feita através de uma API REST com autenticação via Bearer Token.

---

## 🔧 Configuração

### Variáveis de Ambiente

```bash
BIDDINGS_ANALYSER_URL="https://ba.dtr40.com.br"
BIDDINGS_ANALYSER_API_KEY="[API_KEY]"
```

### Autenticação

```ruby
Authorization: Bearer [BIDDINGS_ANALYSER_API_KEY]
Content-Type: application/json
```

---

## 📊 Fluxo de Integração

```
┌─────────────────┐
│  Mobile/Web App │
└────────┬────────┘
         │
         │ 1. Requisição do usuário
         │    (CPF/CNPJ, localização, etc)
         ↓
┌─────────────────────────────────────────┐
│   Rails API - Momento Fiscal            │
│   (BiddingsAnalyserController)          │
│                                         │
│   • Recebe parâmetros                  │
│   • Valida autenticação do usuário     │
│   • Prepara requisição                 │
└────────┬────────────────────────────────┘
         │
         │ 2. Proxy da requisição
         │    Headers: Authorization Bearer
         │    Method: GET
         ↓
┌─────────────────────────────────────────┐
│   Biddings Analyser API                 │
│   https://ba.dtr40.com.br               │
│                                         │
│   • Processa consulta                  │
│   • Busca dados no banco               │
│   • Retorna JSON                       │
└────────┬────────────────────────────────┘
         │
         │ 3. Resposta da API
         │    Status: 200/404/401/500
         │    Body: JSON
         ↓
┌─────────────────────────────────────────┐
│   Rails API - Momento Fiscal            │
│                                         │
│   • Recebe resposta                    │
│   • Repassa para o cliente             │
│   • (sem processamento adicional)      │
└────────┬────────────────────────────────┘
         │
         │ 4. Resposta final
         ↓
┌─────────────────┐
│  Mobile/Web App │
│                 │
│  • Exibe dados │
│  • Renderiza   │
│    mapa        │
└─────────────────┘
```

---

## 🔌 Endpoints Disponíveis

### 1. **Consulta de Empresas**
```
GET /api/v1/biddings_analyser/companies
```

**Função:** Lista empresas cadastradas no sistema

**Fluxo:**
```
Cliente → Momento Fiscal → ba.dtr40.com.br/api/v1/companies
                          ← JSON com lista de empresas
```

**Parâmetros esperados:**
- `q` - Query de busca
- `page` - Número da página
- `page_size` - Tamanho da página

---

### 2. **Consulta de Débitos**
```
GET /api/v1/biddings_analyser/debts
```

**Função:** Lista débitos registrados

**Fluxo:**
```
Cliente → Momento Fiscal → ba.dtr40.com.br/api/v1/debts
                          ← JSON com lista de débitos
```

**Parâmetros esperados:**
- `cpf_cnpj` - CPF ou CNPJ do devedor
- `page` - Número da página
- `page_size` - Tamanho da página

---

### 3. **Débitos por Nome do Devedor**
```
GET /api/v1/biddings_analyser/debts/:cpf_cnpj/debts_per_debted_name
```

**Função:** Agrupa débitos pelo nome do devedor

**Fluxo:**
```
Cliente → Momento Fiscal → ba.dtr40.com.br/api/v1/debts/{cpf_cnpj}/debts_per_debted_name
                          ← JSON com débitos agrupados
```

**Parâmetros:**
- `:cpf_cnpj` - CPF ou CNPJ (na URL)

---

### 4. **Contagem de Empresas por Localização**
```
GET /api/v1/biddings_analyser/companies/count_in_location
```

**Função:** Retorna quantidade de empresas dentro de uma área retangular (bounding box)

**Fluxo:**
```
Cliente → Momento Fiscal → ba.dtr40.com.br/api/v1/companies/count_in_location
                          ← JSON: { "count": 123 }
```

**Parâmetros (Bounding Box):**
- `starting_point[]` - Primeiro canto do retângulo `[longitude, latitude]`
  - Exemplo: `starting_point[]=-46.7&starting_point[]=-23.6`
- `ending_point[]` - Canto oposto do retângulo `[longitude, latitude]`
  - Exemplo: `ending_point[]=-46.3&ending_point[]=-23.3`

**⚠️ IMPORTANTE:** Usa **retângulo** (bounding box), não círculo/raio!

**Formato das coordenadas:** `[longitude, latitude]` (ordem inversa do padrão `lat,lng`)

**Exemplo de requisição:**
```
GET /api/v1/biddings_analyser/companies/count_in_location
  ?starting_point[]=-46.7
  &starting_point[]=-23.6
  &ending_point[]=-46.3
  &ending_point[]=-23.3
```

**Resposta:**
```json
{
  "count": 47
}
```

**Uso típico:** Exibir no mapa quantas empresas devedoras existem em uma área visível

---

### 5. **Empresas por Localização**
```
GET /api/v1/biddings_analyser/companies/in_location
```

**Função:** Lista empresas dentro de uma área retangular (bounding box) com paginação

**Fluxo:**
```
Cliente → Momento Fiscal → ba.dtr40.com.br/api/v1/companies/in_location
                          ← JSON com array de empresas
```

**Parâmetros:**
- `starting_point[]` - Primeiro canto do retângulo `[longitude, latitude]`
- `ending_point[]` - Canto oposto do retângulo `[longitude, latitude]`
- `page` - Número da página (padrão: 1)
- `page_size` - Tamanho da página (padrão: 10)
- `min_debts_value` - Valor mínimo de débitos (filtro opcional)
- `_id` - Filtro por ID MongoDB (opcional)
- `cnpj` - Filtro por CNPJ (apenas números, 14 dígitos)
- `debts_value[gte]` - Filtro de débitos maior ou igual (opcional)

**Ordenação:** Por `debts_value` descendente (empresas com mais débitos primeiro)

**Exemplo de requisição:**
```
GET /api/v1/biddings_analyser/companies/in_location
  ?starting_point[]=-46.7
  &starting_point[]=-23.6
  &ending_point[]=-46.3
  &ending_point[]=-23.3
  &page=1
  &page_size=50
  &min_debts_value=10000
```E VIEWPORT DO MAPA                 │
│    - GPS / Geolocation API                                   │
│    - Centro: Lat -15.7801, Lng -47.9292 (Brasília)         │
│    - Calcula bounding box da área visível                   │
│    - SW: [-47.95, -15.80], NE: [-47.90, -15.76]           │
└──────────────────────────────────────────────────────────────┘
                           │
                           ↓
┌──────────────────────────────────────────────────────────────┐
│ 3. CONSULTA CONTAGEM DE EMPRESAS NA REGIÃO VISÍVEL          │
│    GET /biddings_analyser/companies/count_in_location        │
│    Params:                                                   │
│      starting_point[]=[-47.95, -15.80]  (SW corner)        │
│      ending_point[]=[-47.90, -15.76]    (NE corner)      
GET /api/v1/biddings_analyser/download?file_id={file_id}
```

**Função:** Redireciona para download de arquivo (relatórios, PDFs, etc)

**Fluxo:**
```
Cliente → Momento Fiscal → REDIRECT →
                   }                                          │
└──────────────────────────────────────────────────────────────┘
                           │
                           ↓
┌──────────────────────────────────────────────────────────────┐
│ 6. APP RENDERIZA MAPA COM CONTAGEM                          │
│    "47 empresas devedoras nesta região"                     │
└──────────────────────────────────────────────────────────────┘
                           │
                           ↓
┌──────────────────────────────────────────────────────────────┐
│ 7. USUÁRIO AMPLIA ZOOM / MOVE O MAPA                        │
│    Novo bounding box calculado automaticamente              │
│    Novo SW: [-47.92, -15.78], NE: [-47.91, -15.77]        │
└──────────────────────────────────────────────────────────────┘
                           │
                           ↓
┌──────────────────────────────────────────────────────────────┐
│ 8. CONSULTA EMPRESAS NA NOVA REGIÃO (MAIS ZOOM)             │
│    GET /biddings_analyser/companies/in_location              │
│    Params:                                                   │
│      starting_point[]=[-47.92, -15.78]                     │
│      ending_point[]=[-47.91, -15.77]                       │
│      page=1, page_size=50           
┌──────────────────────────────────────────────────────────────┐
│ 2. APP OBTÉM LOCALIZAÇÃO ATUAL DO USUÁRIO                   │
│    - GPS / Geolocation API                                   │
│    - Lat: -15.7801, Lng: -47.9292 (Brasília)               │
└──────────────────────────────────────────────────────────────┘
                           │
                           ↓
┌──────────────────────────────────────────────────────────────┐
│ 3. CONSULTA CONTAGEM DE EMPRESAS NA REGIÃO                  │
│    GET /biddings_analyser/companies/count_in_location        │
│    Params: { lat: -15.7801, lng: -47.9292, radius: 5000 }  │
└──────────────────────────────────────────────────────────────┘
                           │
                           ↓
┌──────────────────────────────────────────────────────────────┐
│ 4. RAILS PROXY PARA BIDDINGS ANALYSER                       │
│    Authorization: Bearer [API_KEY]                           │
│    → ba.dtr40.com.br/api/v1/companies/count_in_location     │
└──────────────────────────────────────────────────────────────┘
                           │
                           ↓
┌──────────────────────────────────────────────────────────────┐
│ 5. RESPOSTA COM CONTAGEM                                     │
│    { "count": 47, "radius": 5000 }                          │
└──────────────────────────────────────────────────────────────┘
                           │
                           ↓
┌──────────────────────────────────────────────────────────────┐
│ 6. APP RENDERIZA MAPA COM CONTAGEM                          │
│    "47 empresas devedoras em um raio de 5km"               │
└──────────────────────────────────────────────────────────────┘
                           │
                           ↓
┌──────────────────────────────────────────────────────────────┐
│ 7. USUÁRIO AMPLIA ZOOM / MOVE O MAPA                        │
│    Novo bbox ou novos parâmetros de localização             │
└──────────────────────────────────────────────────────────────┘
                           │
                           ↓
┌──────────────────────────────────────────────────────────────┐
│ 8. CONSULTA EMPRESAS NA NOVA REGIÃO                         │
│    GET /biddings_analyser/companies/in_location              │
│    Params: { lat: -15.7850, lng: -47.9300, radius: 2000,   │
│              page: 1, page_size: 50 }                        │
└──────────────────────────────────────────────────────────────┘
          corporate_name": "Empresa ABC Ltda",                │
│        "fantasy_name": "ABC",                               │
│        "city_name": "Brasília",                             │
│        "uf": "DF",                                          │
│        "debts_value": 150000.00,                            │
│        "debts_count": 5,                                    │
│        "debts_cache_updated_at": "2026-01-05T10:30:00Z"    │
│      },                                                      │
│      ...                                                     │
│    ]                                                         │
│    Ordenado por debts_value DESCBC Ltda",                  │
│        "latitude": -15.7812,                                │
│        "longitude": -47.9301,                               │
│        "total_debitos": 150000.00,                          │
│        "quantidade_debitos": 5                              │
│      },                                                      │
│      ...                                                     │
│    ]                                                         │
└──────────────────────────────────────────────────────────────┘
                           │
                           ↓
┌──────────────────────────────────────────────────────────────┐
│ 10. APP RENDERIZA PINS NO MAPA                              │
│     • Cada empresa = 1 pin                                   │
│     • Cor do pin baseada em valor do débito                 │
│     • Clustering para muitas empresas próximas              │
└──────────────────────────────────────────────────────────────┘
                           │
                           ↓
┌──────────────────────────────────────────────────────────────┐
│ 11. USUÁRIO CLICA EM UM PIN                                 │
│     Empresa selecionada: CNPJ 12345678000100                │
└──────────────────────────────────────────────────────────────┘
                           │
                           ↓
┌──────────────────────────────────────────────────────────────┐
│ 12. CONSULTA DÉBITOS DA EMPRESA                             │
│     GET /biddings_analyser/debts                             │
│     Params: { cpf_cnpj: "12345678000100" }                  │
└──────────────────────────────────────────────────────────────┘
                           │
                           ↓
┌──────────────────────────────────────────────────────────────┐
│ 13. RESPOSTA COM DÉBITOS DETALHADOS                         │
│     [                                                        │
│       {                                                      │
│         "numero_inscricao": "12345.67/2023",                │
│         "valor": 50000.00,                                  │
│         "origem": "PGFN",                                   │
│         "situacao": "Ativa",                                │
│         "data_inscricao": "2023-05-15"                      │
│       },                                                     │
│       ...                                                    │
│     ]                                                        │
└──────────────────────────────────────────────────────────────┘
                           │
                           ↓
┌──────────────────────────────────────────────────────────────┐
│ 14. APP EXIBE MODAL/BOTTOMSHEET COM DETALHES                │
│     • Razão Social                                           │
│     • CNPJ                                                   │
│     • Total de débitos: R$ 150.000,00                       │
│     • Lista de débitos individuais                          │
│     • Botão: "Ver relatório completo"                       │
└──────────────────────────────────────────────────────────────┘
                           │
                           ↓
┌──────────────────────────────────────────────────────────────┐
│ 15. USUÁRIO SOLICITA RELATÓRIO                              │
│     Download de PDF com análise completa                     │
└──────────────────────────────────────────────────────────────┘
                           │
                           ↓
┌──────────────────────────────────────────────────────────────┐
│ 16. REQUISIÇÃO DE DOWNLOAD                                   │
│     GET /biddings_analyser/download?file_id=ABC123          │
│     → REDIRECT para ba.dtr40.com.br/api/v1/download/ABC123 │
└──────────────────────────────────────────────────────────────┘
```

---

## 📚 Documentação Existente

### ✅ **API Momento Fiscal Tem Documentação**

A documentação em `docs/Momento Fiscal API.md` mostra todos os endpoints `/api/v1/biddings_analyser/*`, mas **documenta apenas a camada de proxy Rails**, não a API Biddings Analyser original da Spezi.

**O que está documentado:**
- ✅ Todos os 6 endpoints do Rails
- ✅ Estrutura completa dos JSONs de resposta
- ✅ Parâmetros aceitos e tipos
- ✅ Códigos de status HTTP
- ✅ Exemplos de request/response

**O que NÃO está documentado:**
- ❌ API interna `ba.dtr40.com.br` (Spezi)
- ❌ Rate limits do serviço Biddings Analyser
- ❌ SLA e disponibilidade
- ❌ Plano de continuidade se Spezi descontinuar

---

## ⚠️ Problemas Identificados

### 1. **Dependência Total da Spezi**

```
┌──────────────────────────────────────────┐
│ Momento Fiscal Rails                     │
│ (momentofiscal.com.br)                   │
│                                          │
│ ✅ Documentado                           │
│ ✅ Código fonte disponível               │
│ ❌ Apenas PROXY transparente             │
└──────────────┬───────────────────────────┘
               │
               │ Dependência 100%
               ↓
┌──────────────────────────────────────────┐
│ Biddings Analyser - Spezi                │
│ (ba.dtr40.com.br)                        │
│                                          │
│ ❌ URL interna da Spezi                  │
│ ❌ Sem documentação da API real          │
│ ❌ Sem acesso ao código fonte            │
│ ❌ Sem SLA ou garantias                  │
└──────────────────────────────────────────┘
```

**Problema:** A URL `https://ba.dtr40.com.br` aponta para o domínio interno da Spezi (dtr40). O Rails apenas repassa requisições sem processamento.

**Impacto:** 
- ⚠️ Se `ba.dtr40.com.br` ficar indisponível, todo o módulo "Mapa de Devedores" para
- ⚠️ Sem código fonte, não há como replicar a funcionalidade
- ⚠️ Sem SLA, não há garantias de disponibilidade
- ⚠️ Mudanças na API da Spezi podem quebrar o sistema sem aviso

**Ação necessária:** ✉️ **Contatar Spezi urgentemente para:**
1. Confirmar se `ba.dtr40.com.br` continuará disponível
2. Obter documentação técnica da API real
3. Estabelecer SLA e suporte
4. Plano de continuidade ou migração

---

### 3. **Implementação como Proxy Simples**

```ruby
def companies
  response = biddings_analyser_connection.get("/api/v1/companies", params)
  render json: response.body, status: response.status
end
```

**Característica:** 
- ✅ Simples e direto
- ✅ Baixa latência
- ❌ Sem cache
- ❌ Sem tratamento de erros
- ❌ Sem logging detalhado
- ❌ Sem fallback

**Possível melhoria:** Adicionar cache, retry logic, error handling

---

## 🔐 Segurança

### Isolamento de API Key

```
┌─────────────┐
│   Cliente   │  ← NÃO tem acesso à API Key
└──────┬──────┘
       │
       │ Requisição sem API Key
       ↓
┌─────────────────────┐
│   Rails Backend     │  ← Adiciona API Key
│   (Proxy Seguro)    │
└──────┬──────────────┘
       │
       │ Authorization: Bearer [KEY]
       ↓
┌─────────────────────┐
│  Biddings Analyser  │
└─────────────────────┘
```

**Vantagem:** O cliente nunca vê a API Key, mantendo-a segura no backend.

---

## 📝 Modelo de Dados (Documentado)

### Empresa (Company)
```json
{
  "name": "Momento Fiscal LTDA",
  "corporate_name": "Momento Fiscal Tecnologia LTDA",
  "cnpj": "12345678000195",
  "base_cnpj": "12345678",
  "order_cnpj": "0001",
  "dv_cnpj": "95",
  "fantasy_name": "Momento Fiscal",
  "juridical_nature": "206-2 - Sociedade Empresária Limitada",
  "qualification": "Administrador",
  "social_capital": "50000.00",
  "responsible_federal_entity": "Receita Federal",
  "matrix": false,
  "branch": false,
  "cadastral_status_date": "2023-05-10",
  "cadastral_status_reason": "Ativa",
  "city_name": "São Paulo",
  "foreign_city_name": null,
  "activity_start_date": "2020-01-01",
  "main_cnae": "6201-5/01",
  "secondary_cnae": "6202-3/00, 6311-9/00",
  "email": "contato@empresa.com.br",
  "special_status": null,
  "special_status_date": null,
  "uf": "SP",
  "municipality_code": "3550308",
  "special_situation": null,
  "special_situation_date": null,
  "simple": true,
  "simple_date": "2019-08-24",
  "simple_exclusion_date": null,
  "mei": true,
  "mei_date": "2019-08-24",
  "mei_exclusion_date": null,
  "debts_count": 5,
  "debts_value": 150000.00,
  "debts_cache_updated_at": "2026-01-05T10:30:00Z"
}
```

**Campos importantes:**
- `debts_count` - Quantidade de débitos
- `debts_value` - Valor total dos débitos
- `debts_cache_updated_at` - Última atualização do cache de débitos
- Empresa tem localização implícita via `city_name` + `uf` + `municipality_code`

### Débito (Debt)
```json
{
  "_id": "507f1f77bcf86cd799439011",
  "cpf_cnpj": "12345678901",
  "debted_person_type": "PF",
  "debted_type": "principal",
  "debted_name": "Empresa XYZ LTDA",
  "debt_state": "SP",
  "responsible_unit": "SRF-SP",
  "registration_number": "1234567890",
  "registration_status_type": "ativo",
  "registration_status": "regular",
  "main_revenue": "Imposto de Renda",
  "registration_date": "2024-01-15",
  "judicial_indicator": "N",
  "credit_type": "tributário",
  "fgts_responsible_entity": "CEF",
  "fgts_unit_subscription": "SP-001",
  "value": 1000.50
}
```

**Campos importantes:**
- `_id` - ID MongoDB
- `cpf_cnpj` - CPF ou CNPJ do devedor
- `debted_name` - Nome do devedor (pode variar para mesma empresa)
- `value` - Valor do débito
- `registration_status_type` - Status da inscrição

### Débitos Agregados por Nome
```json
{
  "debted_name": "ACME LTDA",
  "debts_value": 12345.67,
  "debts_count": 3
}
```

**Uso:** Agrupa débitos por nome do devedor para identificar variações de nome da mesma empresa.

---

## 🧪 Testes Necessários

### 1. Validarcontagem por localização (Bounding Box)
```bash
# Brasília e arredores
curl -H "Authorization: Bearer [API_KEY]" \
     "https://ba.dtr40.com.br/api/v1/companies/count_in_location?starting_point[]=-47.95&starting_point[]=-15.80&ending_point[]=-47.90&ending_point[]=-15.76"
```

### 3. Testar lista de empresas por localização
```bash
curl -H "Authorization: Bearer [API_KEY]" \
     "https://ba.dtr40.com.br/api/v1/companies/in_location?starting_point[]=-47.95&starting_point[]=-15.80&ending_point[]=-47.90&ending_point[]=-15.76&page=1&page_size=10"
```

### 4. Validar débitos
```bash
curl -H "Authorization: Bearer [API_KEY]" \
     "https://ba.dtr40.com.br/api/v1/debts?cpf_cnpj=12345678000100"
```

### 5. Testar agregação de dSuporte e Esclarecimentos - API Biddings Analyser (ba.dtr40.com.br)

---

Prezada equipe Spezi,

Assumi recentemente o projeto **Momento Fiscal**, desenvolvido inicialmente por vocês, e estou finalizando o mapeamento técnico do sistema.

Identifiquei que a aplicação possui **dependência total** da API Biddings Analyser hospedada em `https://ba.dtr40.com.br`. A camada Rails do Momento Fiscal funciona apenas como proxy transparente, repassando todas as requisições para esse serviço.

Embora tenhamos documentação dos endpoints na API Rails (ver arquivo `docs/Momento Fiscal API.md`), ela documenta apenas a camada de proxy, não a API real da Spezi.

**Situação Atual:**
- ✅ Documentação dos endpoints Rails: **disponível**
- ✅ Estrutura dos JSONs de resposta: **documentada**
- ❌ Acesso à documentação da API `ba.dtr40.com.br`: **não disponível**
- ❌ Código fonte do Biddings Analyser: **não disponível**
- ❌ SLA ou garantias de disponibilidade: **não definido**

**Solicitações Urgentes:**

### 1. **Continuidade do Serviço**
- A URL `https://ba.dtr40.com.br` continuará disponível?
- Qual o prazo de continuidade garantido?
- Existe um plano de descontinuação ou migração?
- Como seremos notificados sobre mudanças?

### 2. **Suporte Técnico**
- Existe SLA para disponibilidade da API?
- Qual o canal de suporte em caso de problemas?
- Existe monitoramento de status/uptime?
- Como reportar bugs ou problemas?

### 3. **Documentação Técnica da API Real**
- Rate limits e throttling
- Mensagens de erro detalhadas
- Formato do `file_id` para endpoint de download
- Sistema de coordenadas (confirmação de WGS84)
- Estrutura do banco de dados (MongoDB?)
- Frequência de atualização dos dados de débitos

### 4. **Plano de Contingência**
Se por algum motivo o serviço precisar ser descontinuado:
- Existe possibilidade de transferência do código fonte?
- Seria possível exportar a base de dados?
- Existe alternativa ou serviço substituto?
- Qual seria o prazo de migração?

**Contexto Técnico:**

Os seguintes endpoints são críticos para o funcionamento do sistema:
- `/api/v1/companies/in_location` - Mapa de devedores (funcionalidade principal)
- `/api/v1/companies/count_in_location` - Contador do mapa
- `/api/v1/debts` - Consulta de débitos
- `/api/v1/debts/{cpf_cnpj}/debts_per_debted_name` - Agregação de débitos

**Urgência:** Esta é uma questão crítica para a continuidade do projeto, pois o módulo "Mapa de Devedores" representa uma funcionalidade principal do sistema.

Agradeço pela atenção e fico no aguardo de retorno.

Atenciosamente,  
[Seu Nome]  
[Seu Cargo]  
Momento Fiscal  
[Seu Email]  
[Seu Telefone]o `file_id` para downloads
   - Como funciona a paginação?
   - Existe cache na API?
   - Existe webhook para atualizações?

4. **Infraestrutura:**
   - A URL `ba.dtr40.com.br` é pública ou interna?
   - Existe SLA garantido?
   - Plano de backup/contingência em caso de indisponibilidade?

Qualquer material técnico será de grande ajuda para garantir a continuidade do projeto.

Agradeço pela atenção!

Atenciosamente,  
[Seu Nome]  
Momento Fiscal
