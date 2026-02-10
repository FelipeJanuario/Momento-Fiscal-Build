# Resumo das APIs - Momento Fiscal

## 1️⃣ SERPRO - Dívida Ativa DF

### O que é
API oficial da **Receita do Distrito Federal** para consulta de dívidas ativas.

### O que entrega
- **Inscrições em dívida ativa** vinculadas a um CPF/CNPJ
- Dados: número da inscrição, situação, valor, origem
- Cobertura: **somente Distrito Federal**

### Autenticação
- **OAuth2 Client Credentials**
- Consumer Key + Consumer Secret

### Status da Integração
✅ **FUNCIONANDO**

**Teste realizado**: CPF 11904675859  
**Resultado**: Encontrou dívida real
```
Nome: ROSEMBERG FREIRE GUEDES
Inscrição: 80 6 22 090919-95
Situação: ATIVA EM COBRANCA
```

### Como usar
```ruby
SerproAuthService.new.call
# Retorna token OAuth2

# Consultar dívidas
GET https://gateway.apiserpro.serpro.gov.br/consulta-divida-ativa-df/v1/dividas/{cpf_cnpj}
```

---

## 2️⃣ Datajud (CNJ) - Processos Judiciais

### O que é
API pública do **Conselho Nacional de Justiça** para consulta de processos judiciais em todo o Brasil.

### O que entrega
- **Processos judiciais públicos** de 91 tribunais
- Dados: número do processo, partes, movimentações, tribunal
- Cobertura: **todos os tribunais brasileiros** (TJs, TRFs, TRTs, STF, STJ, TST, etc.)

### Autenticação
- **API Key** (estática)
- Header: `Authorization: ApiKey <base64>`

### Status da Integração
✅ **FUNCIONANDO PERFEITAMENTE**

**Teste realizado**: Consultou 91/91 tribunais em 2.23 segundos

### Limitações importantes
- ⚠️ **Busca apenas por número de processo** (não busca por CPF diretamente)
- ⚠️ Requer conhecer o número do processo previamente
- ✅ Retorna dados públicos (sem dados sensíveis sob segredo)

### Como usar
```ruby
JusbrasilService.new.search_all_tribunals(numero_processo)
# Retorna dados do processo de todos os 91 tribunais
```

**Lista completa de tribunais**:
- 27 Tribunais de Justiça (TJs)
- 5 Tribunais Regionais Federais (TRFs)
- 24 Tribunais Regionais do Trabalho (TRTs)
- Tribunais Superiores (STF, STJ, STM, TST, TSE)
- Tribunais de Justiça Militar (TJMs)

---

## 3️⃣ PJe - Processo Judicial Eletrônico

### O que é
Sistema oficial do **CNJ** para tramitação eletrônica de processos judiciais.

### O que entregaria (se tivéssemos acesso)
- **Busca de processos por CPF/CNPJ** (diferente do Datajud)
- Dados processuais mais detalhados
- Integração com fluxo interno dos tribunais

### Autenticação possível
1. **Certificado Digital** (mTLS) - Testado, certificados de videoconferência não têm permissão
2. **Usuário/Senha** (OAuth2 Password Grant) - Requer credenciais SSO PJe

### Status da Integração
❌ **BLOQUEADO - Acesso Institucional**

**Motivo**: SSO PJe não é API pública
- Requer **convênio formal** com CNJ ou Tribunal
- Empresas privadas não conseguem acesso direto
- Necessário vínculo institucional (tribunal parceiro, licitação, convênio)

**Testes realizados**:
- ❌ Certificado e-CPF (Videoconferência) → Erro 500 (sem permissão)
- ❌ Certificado e-CNPJ (Videoconferência) → Erro 500 (sem permissão)
- ❌ Credenciais portal TJDFT → Erro 401 (não válidas no SSO Cloud)

**Implementação técnica**: ✅ Pronta (PjePasswordAuthService)  
**Acesso institucional**: ❌ Pendente de convênio

### Como funcionaria (quando houver acesso)
```ruby
PjePasswordAuthService.new(username: "...", password: "...").call
# Retorna token OAuth2

# Consultar processos por CPF
service.query_processes("11904675859")
# Retorna processos vinculados ao CPF
```

---

## 📊 Comparativo

| Critério | SERPRO | Datajud | PJe |
|----------|---------|---------|-----|
| **Status** | ✅ Funcionando | ✅ Funcionando | ❌ Sem acesso |
| **Tipo de dado** | Dívidas ativas | Processos judiciais | Processos judiciais |
| **Busca por CPF** | ✅ Sim | ❌ Não (só nº processo) | ✅ Sim (se tiver acesso) |
| **Cobertura** | Só DF | 91 tribunais nacionais | Tribunais com PJe |
| **Acesso** | Oficial/Imediato | Oficial/Imediato | Institucional/Convênio |
| **Autenticação** | OAuth2 (Client) | API Key | OAuth2 (Password) ou Cert |
| **Implementação** | ✅ Completa | ✅ Completa | ✅ Código pronto |

---

## 🎯 Estratégia Atual

### Fase 1 - Operacional Agora ✅
**Usar**: SERPRO + Datajud

**Fluxo recomendado**:
1. Buscar dívidas no SERPRO (por CPF)
2. Usuário informa números de processo
3. Buscar processos no Datajud (por número)

### Fase 2 - Futuro (com convênio)
**Adicionar**: PJe

**Benefício adicional**:
- Busca direta por CPF (sem precisar do número do processo)
- Dados mais detalhados de tribunais específicos

---

## 🔧 Serviços Implementados

### SERPRO
- `SerproAuthService` - OAuth2 authentication
- `SerproConsultaService` - Consulta dívidas

### Datajud
- `JusbrasilService` - Consulta 91 tribunais
- Constantes: `TRIBUNAIS` (todos) e `TRIBUNAIS_PRIORITARIOS` (21 principais)

### PJe (pronto, aguardando acesso)
- `PjePasswordAuthService` - OAuth2 com usuário/senha
- `AuthenticatePjeService` - OAuth2 com certificado
- `PjeProcessosService` - Consulta processos

---

**Última atualização**: 07/01/2026  
**Conclusão**: SERPRO + Datajud entregam funcionalidade completa. PJe é opcional e depende de convênio institucional.
