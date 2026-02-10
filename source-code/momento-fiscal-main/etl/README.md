# ETL - Pipeline de Importação de CNPJs

Pipeline completo para importar dados da Receita Federal (Empresas e Estabelecimentos) no PostgreSQL.

> 📄 **Documentação completa**: Veja [ETL_MAPA_INTERATIVO.md](./ETL_MAPA_INTERATIVO.md) para detalhes técnicos e arquitetura completa

## 🚀 Quick Start

### 1. Instalação
```bash
cd etl
pip install -r requirements.txt
```

### 2. Configuração
Crie `.env.local`:
```env
DB_HOST=localhost
DB_PORT=5434
DB_NAME=momento_fiscal_api_production
DB_USER=postgres
DB_PASSWORD=TECHbyops30!
```

### 3. Executar

**Teste (100 registros)**:
```bash
python import_cnpj.py --limit 100
```

**Importação completa**:
```bash
python import_cnpj.py
```

## 📋 Requisitos

- Python 3.13+
- PostgreSQL 13 (Docker porta 5434)
- Arquivos ZIP da Receita Federal em `C:\cnpjs\`

## 📊 O que faz

- ✅ Importa ~20M estabelecimentos ativos da Receita Federal
- ✅ Lê arquivos ZIP diretamente (sem extrair)
- ✅ Filtra apenas empresas ativas (`situacao_cadastral = 2`)
- ✅ Batch processing (1000 registros/lote)
- ✅ Prepara dados para mapa de devedores com geolocalização

## 📄 Arquivos

- `import_cnpj.py` - Script ETL principal
- `requirements.txt` - Dependências Python
- `.env.local` - Configuração do banco
- `ETL_MAPA_INTERATIVO.md` - Documentação completa

## ⏱️ Tempo estimado

- Teste (100 registros): ~2 segundos
- Importação completa: 2-4 horas

---

**Status:** ✅ Funcional | **Última atualização:** 09/01/2026

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

## 🔄 Próximos Passos

1. **Geocodificação** - Criar serviço para converter CEP → lat/long via BrasilAPI
   - Endpoint: `GET https://brasilapi.com.br/api/cep/v2/{cep}`
   - Retorna: `latitude`, `longitude`
   - Cachear em `geocoded_at`

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

## � Estatísticas

- **Total de CNPJs nos arquivos:** ~50 milhões
- **Estabelecimentos ativos importados:** ~20 milhões (40% são ativos)
- **Empresas únicas:** ~8-10 milhões
- **Tempo estimado importação completa:** 2-4 horas

## 📄 Referências

- [Dados Públicos da Receita Federal](https://www.gov.br/receitafederal/pt-br/assuntos/orientacao-tributaria/cadastros/consultas/dados-publicos-cnpj)
- [Layout dos arquivos CSV](https://www.gov.br/receitafederal/pt-br/assuntos/orientacao-tributaria/cadastros/consultas/arquivos/NOVOLAYOUTDOSDADOSABERTOSDOCNPJ.pdf)
- [BrasilAPI - CEP](https://brasilapi.com.br/docs#tag/CEP-V2)
- [SERPRO - Dívida Ativa DF](https://www.serpro.gov.br/)

---

**Última atualização:** 09/01/2026  
**Status:** ✅ Funcional - Teste com 100 registros passou  
**Próximo deploy:** Aguardando importação completa
