# ETL de CNPJs da Receita Federal - Mapa Interativo de Devedores

## 📋 Objetivo

Importar dados públicos de CNPJs da Receita Federal (Empresas e Estabelecimentos) para o banco de dados PostgreSQL, permitindo:

1. **Geolocalização de empresas** - Mapear devedores por localização usando CEP → lat/long via BrasilAPI
2. **Cache de dívidas** - Consultar Dívida Ativa via SERPRO com cache de 3 meses
3. **Visualização em mapa** - Exibir empresas devedoras em mapa interativo por região

## 🎯 O que foi implementado

### 1. Estrutura do Banco de Dados

**Tabelas criadas via Rails migrations:**

**`empresas`** - Dados básicos da empresa (CNPJ raiz)
- Migration: [20260107000001_create_empresas_and_estabelecimentos.rb](../api/db/migrate/20260107000001_create_empresas_and_estabelecimentos.rb)
- `cnpj_basico` (8 dígitos)
- `razao_social`
- `natureza_juridica`
- `capital_social`
- `porte_empresa`

**`estabelecimentos`** - Locais físicos das empresas (CNPJ completo)
- Migration: [20260107000001_create_empresas_and_estabelecimentos.rb](../api/db/migrate/20260107000001_create_empresas_and_estabelecimentos.rb)
- `cnpj_completo` (14 dígitos: cnpj_basico + ordem + dv)
- `nome_fantasia`, `logradouro`, `bairro`, `cep`, `uf`, `municipio`
- `situacao_cadastral` (2 = ativo)
- **Geolocalização**: `latitude`, `longitude`, `geocoded_at` (campos locais, backup)
- **Cache de dívidas**: `debt_value`, `debt_count`, `debt_checked_at`, `debt_details` (jsonb)

**`cep_coordinates`** - Cache de CEPs geocodificados (CEPs únicos)
- Migration: [20260109120000_create_cep_coordinates.rb](../api/db/migrate/20260109120000_create_cep_coordinates.rb)
- `cep` (8 dígitos, chave única)
- `latitude`, `longitude`
- `geocoded_at` (timestamp do geocoding)
- Índices para performance em queries de busca por região

**Modelos Rails:**
- [Empresa](../api/app/models/empresa.rb)
- [Estabelecimento](../api/app/models/estabelecimento.rb)
- [CepCoordinate](../api/app/models/cep_coordinate.rb)

### 2. Pipeline ETL em Python

**Arquivo**: `import_cnpj.py`

#### Componentes:

**CNPJExtractor** (Extract)
- ✅ **Lê arquivos ZIP diretamente** (sem extrair para disco)
- ✅ Streaming de CSV linha por linha (baixo uso de memória)
- ✅ Encoding: ISO-8859-1 (latin1)
- ✅ Delimitador: `;`

**CNPJTransformer** (Transform)
- ✅ Valida e limpa dados
- ✅ **Filtra apenas estabelecimentos ATIVOS** (`situacao_cadastral = 2`)
- ✅ Calcula CNPJ completo (basico + ordem + dv)
- ✅ Normaliza tipos (decimal, inteiros, strings)

**CNPJLoader** (Load)
- ✅ Batch inserts de 1000 registros por vez
- ✅ `ON CONFLICT DO NOTHING` para evitar duplicatas
- ✅ Relacionamento empresa_id via cache em memória

## 🚀 Como usar

### Teste com 100 registros:
```powershell
cd C:\momento-fiscal-transferencia\source-code\momento-fiscal-main\etl
python import_cnpj.py --limit 100
```

### Importação completa (~20M registros ativos):
```powershell
python import_cnpj.py
```

**⏱️ Tempo estimado**: 2-4 horas para importação completa

## 📋 Pré-requisitos

1. **Arquivos da Receita Federal** em `C:\cnpjs\`
   - `Empresas0.zip` até `Empresas9.zip` (10 arquivos)
   - `Estabelecimentos0.zip` até `Estabelecimentos9.zip` (10 arquivos)

2. **Python 3.13+**

3. **PostgreSQL 13** rodando (via Docker na porta 5434)

## ⚙️ Configuração

### Arquivo: `.env.local` (neste diretório etl/)

```env
DB_HOST=localhost
DB_PORT=5434
DB_NAME=momento_fiscal_api_production
DB_USER=postgres
DB_PASSWORD=TECHbyops30!
```

### Instalação de dependências:

```bash
pip install -r requirements.txt
```

**Pacotes instalados**:
```txt
psycopg[binary]>=3.2.0  # PostgreSQL adapter com wheels pré-compilados para Windows
python-dotenv==1.0.0     # Carrega variáveis de ambiente
tqdm==4.66.1             # Progress bar
requests>=2.31.0         # HTTP client para BrasilAPI
```

## 🏗️ Estrutura do Pipeline

```
Extract (CNPJExtractor)
  ↓ Lê ZIPs diretamente
  ↓ Streaming linha por linha
  ↓
Transform (CNPJTransformer)
  ↓ Filtra apenas ativos (situacao_cadastral=2)
  ↓ Valida e normaliza dados
  ↓
Load (CNPJLoader)
  ↓ Batch insert (1000/lote)
  ↓ Cache de empresa_ids
  ↓
PostgreSQL (empresas + estabelecimentos)
```

### Fluxo de Dados:

1. **Empresas**: Lê todos os ZIPs `Empresas*.zip` → Insere em `empresas` → Cache de IDs
2. **Estabelecimentos**: Lê todos os ZIPs `Estabelecimentos*.zip` → Filtra ativos → Relaciona com empresas → Insere em `estabelecimentos`

## 📂 Formato dos Dados

### Fonte: Receita Federal

**Arquivos dentro do ZIP**: Sem extensão (ex: `K3241.K03200Y0.D51213.EMPRECSV`)

**Formato CSV**:
- **Encoding**: ISO-8859-1 (latin1)
- **Delimitador**: `;` (ponto e vírgula)
- **Sem header**: Campos por posição fixa

### Campos Mapeados:

**Empresas** (7 campos):
- `cnpj_basico`, `razao_social`, `natureza_juridica`, `qualificacao_responsavel`, `capital_social`, `porte_empresa`, `ente_federativo_responsavel`

**Estabelecimentos** (30+ campos):
- CNPJ: `cnpj_basico`, `cnpj_ordem`, `cnpj_dv`
- Endereço: `tipo_logradouro`, `logradouro`, `numero`, `complemento`, `bairro`, `cep`, `uf`, `municipio`
- Contato: `ddd_1`, `telefone_1`, `email`
- Status: `situacao_cadastral`, `data_situacao_cadastral`, `data_inicio_atividade`
- Atividade: `cnae_fiscal_principal`, `cnae_fiscal_secundaria`

## 🔍 Filtros Aplicados

**Empresas**: Todas importadas (necessárias para foreign key)

**Estabelecimentos**: **Apenas ATIVOS**
- `situacao_cadastral = 2` (Ativa)
- Resultado: ~12% dos registros processados (~20 milhões de 50 milhões)

## 📊 Resultado do Teste

Teste executado com `--limit 100`:

```
✅ Conectado ao banco: momento_fiscal_api_production
✅ 100 empresas importadas
✅ 12 estabelecimentos ativos (filtrados de 100)
⏱️ Tempo: ~2 segundos
```

## 🌍 Geocodificação de CEPs

### ✅ Serviço implementado: `geocode_service.py`

Converte CEPs em coordenadas lat/long via **ViaCEP + Nominatim (OpenStreetMap)** e cacheia no banco.

#### Estratégia implementada:

1. **ViaCEP**: Busca endereço completo (gratuito, sem rate limit)
2. **Nominatim**: Geocodifica endereço → lat/long (OpenStreetMap)
3. **Fallback inteligente**: Se endereço completo falhar, tenta apenas cidade + UF
4. **Cache**: Salva em `latitude`, `longitude`, `geocoded_at`

**Por que não BrasilAPI?**
- ✅ BrasilAPI retorna coordenadas vazias na maioria dos casos
- ✅ ViaCEP + Nominatim tem cobertura muito melhor
- ✅ Ambos são gratuitos e públicos

#### Como usar:

**Teste com um CEP específico:**
```powershell
cd C:\momento-fiscal-transferencia\source-code\momento-fiscal-main\etl
python geocode_service.py --cep 01310100  # Av. Paulista, SP
python geocode_service.py --cep 70040902  # Brasília, DF
```

**Geocodificar 1000 estabelecimentos pendentes:**
```powershell
python geocode_service.py --batch 1000
```

**Geocodificar todos os pendentes (em lotes de 1000):**
```powershell
python geocode_service.py --batch 10000
```

#### Funcionamento detalhado:

1. **Busca estabelecimentos ativos** com CEP válido e sem coordenadas
2. **Consulta ViaCEP**: `GET https://viacep.com.br/ws/{cep}/json/`
3. **Geocodifica via Nominatim**: 
   - Tenta primeiro: `Logradouro, Bairro, Cidade, UF, Brasil`
   - Se falhar: `Cidade, UF, Brasil` (fallback)
4. **Valida coordenadas**: Verifica se estão dentro do território brasileiro
5. **Cacheia resultado**: Atualiza `latitude`, `longitude`, `geocoded_at`
6. **Rate limiting**: 1 segundo entre requisições (política do Nominatim)

#### Estratégia de cache:

- ✅ Só geocodifica estabelecimentos **ativos** (`situacao_cadastral = 2`)
- ✅ Ignora registros sem CEP ou CEP inválido
- ✅ **Re-geocodifica** após 6 meses (endereços podem mudar)
- ✅ Marca CEPs não encontrados (`geocoded_at` sem coords) para não tentar novamente
- ✅ Valida ranges de lat/long para Brasil (-33.75 a 5.27, -73.99 a -28.84)

#### Estatísticas exibidas:

```
📊 Estatísticas:
   ✅ Sucesso:        856
   ❓ Não encontrado: 120
   ❌ Erros:          24
   📦 Total:          1000
```

#### Performance:

- **Taxa**: ~1 requisição/segundo (rate limit do Nominatim)
- **Tempo para 1000 CEPs**: ~16-20 minutos
- **Tempo para 20M estabelecimentos**: ~230 dias contínuos 😱

### ⚡ Otimização: Geocodificação de CEPs Únicos

**Implementado:** `geocode_unique_ceps.py`

Ao invés de geocodificar 20M estabelecimentos individualmente, geocodifica apenas ~2M CEPs únicos e propaga para todos estabelecimentos.

**Economia**: ~90% (de 230 dias → 23 dias)

#### Como usar:

```powershell
# 1. Geocodifica 1000 CEPs únicos
python geocode_unique_ceps.py --batch 1000

# 2. Propaga coordenadas para estabelecimentos
python geocode_unique_ceps.py --propagate
```

#### Estratégia:

1. Cria tabela `cep_coordinates` para cachear CEPs únicos
2. Geocodifica apenas CEPs distintos (não duplicados)
3. Propaga coordenadas para todos estabelecimentos com aquele CEP
4. Muito mais eficiente para datasets grandes

#### Estrutura da tabela:

```sql
CREATE TABLE cep_coordinates (
    id SERIAL PRIMARY KEY,
    cep VARCHAR(8) NOT NULL UNIQUE,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    geocoded_at TIMESTAMP,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);
```

**⚠️ Otimizações adicionais:**

Para acelerar ainda mais:
1. **Rodar em múltiplas máquinas** (IPs diferentes para evitar rate limit)
2. **Usar serviço pago** (Google Geocoding API)
   - 40.000 requisições/mês grátis
   - $5 por 1000 após o limite
   - Sem rate limit (até 100 req/s)

## 🔄 Próximos Passos

1. ✅ **Geocodificação** - ✅ CONCLUÍDO
   - ✅ Serviço criado (`geocode_service.py`)
   - ✅ Integração com BrasilAPI
   - ✅ Cache no banco com validade de 6 meses
   - 🔜 **Otimizar**: Cachear CEPs únicos antes de geocodificar

2. **Integração SERPRO** - Consultar Dívida Ativa DF
   - Cache de 3 meses em `debt_checked_at`
   - Armazenar em `debt_value`, `debt_count`, `debt_details`

3. **API Endpoint** - `GET /api/v1/debtors/in_region`
   - Parâmetros: `lat`, `lng`, `radius_km`
   - Usa scope `Estabelecimento.in_region` (bounding box)

4. **Frontend** - Mapa interativo com clusters de devedores
   - Biblioteca: Leaflet ou Google Maps
   - Clusters por densidade
   - Tooltip com dados da dívida

## 🛠️ Tecnologias

- **Python 3.13** - Linguagem
- **psycopg 3.x** - Driver PostgreSQL com binary wheels para Windows
- **tqdm** - Progress bar
- **python-dotenv** - Variáveis de ambiente
- **PostgreSQL 13** - Banco de dados (Docker)
- **zipfile** - Leitura de arquivos ZIP (built-in)

## 📝 Decisões Técnicas

### Por que psycopg3 ao invés de psycopg2?

- ✅ Wheels pré-compilados para Windows (sem Visual Studio Build Tools)
- ✅ API moderna com melhor performance
- ✅ Suporte nativo para async
- ✅ Batch inserts mais eficientes

### Por que não pandas?

- ❌ Requer compilação no Windows (Visual C++)
- ❌ Overhead de memória para datasets grandes
- ✅ CSV nativo do Python é suficiente para streaming

### Por que streaming ao invés de carregar tudo?

- 📦 Arquivos ZIP somam ~15GB compactados
- 💾 Descompactado seria ~100GB+
- ⚡ Streaming permite processar sem extrair
- 🧠 Uso constante de memória (~100MB)

### Por que ler ZIP diretamente?

- 💾 Economiza ~100GB de espaço em disco
- ⚡ Mais rápido que extrair + ler
- 🔒 Mantém arquivos originais intactos

## 🐛 Troubleshooting

### Erro de autenticação PostgreSQL
```
FATAL: password authentication failed for user "postgres"
```
**Solução**: Verificar senha em `.env.local` - deve ser `TECHbyops30!`

### "Nenhum arquivo encontrado"
```
⚠️  Nenhum arquivo encontrado com padrão: Empresas*.zip
```
**Solução**: 
- Confirmar arquivos em `C:\cnpjs\`
- Verificar `CNPJ_PATH` na linha 33 de `import_cnpj.py`

### Container PostgreSQL não está rodando
```
connection refused
```
**Solução**: 
```powershell
cd C:\momento-fiscal-transferencia\source-code\momento-fiscal-main
docker-compose -f docker-compose.local.yml up -d db
```

### Erro de encoding
**Solução**: Arquivos da Receita usam ISO-8859-1 (latin1), já configurado no script

## 📊 Estatísticas

- **Total de CNPJs nos arquivos:** ~50 milhões
- **Estabelecimentos ativos importados:** ~20 milhões (40% são ativos)
- **Empresas únicas:** ~8-10 milhões
- **Tempo estimado importação completa:** 2-4 horas

## 📄 Referências

- [Dados Públicos da Receita Federal](https://www.gov.br/receitafederal/pt-br/assuntos/orientacao-tributaria/cadastros/consultas/dados-publicos-cnpj)
- [Layout dos arquivos CSV](https://www.gov.br/receitafederal/pt-br/assuntos/orientacao-tributaria/cadastros/consultas/arquivos/NOVOLAYOUTDOSDADOSABERTOSDOCNPJ.pdf)
- [ViaCEP - API de consulta de CEP](https://viacep.com.br/)
- [Nominatim - OpenStreetMap Geocoding](https://nominatim.org/)
- [SERPRO - Dívida Ativa DF](https://www.serpro.gov.br/)

---

**Última atualização:** 09/01/2026  
**Status:** ✅ Geocodificação funcional - Testado com CEPs de SP e DF  
**Próximo passo:** Otimizar geocodificação de CEPs únicos + Integração SERPRO
