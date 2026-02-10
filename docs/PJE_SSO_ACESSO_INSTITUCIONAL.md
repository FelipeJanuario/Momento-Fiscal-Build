# Acesso ao SSO PJe - Realidade Institucional

## Por que não conseguimos acessar o SSO PJe

O **SSO PJe (Keycloak)** não é uma API pública. O acesso é **institucional** e depende de **convênio formal** com o CNJ ou Tribunais.

## Requisitos para obter acesso

1. **Pessoa jurídica constituída** com finalidade institucional (não comercial direta)
2. **Vínculo com órgão público**:
   - Tribunal parceiro
   - Universidade pública
   - Contratação via licitação/convênio
3. **Projeto aprovado** com finalidade clara (apoio ao Judiciário, interoperabilidade, pesquisa)

## Caminhos possíveis

### Via Tribunal (mais comum)
- Tribunal demonstra interesse no sistema
- Tribunal solicita acesso ao CNJ em nome da empresa
- Ambiente: homologação → produção
- **Prazo realista**: meses

### Via Convênio CNJ (projetos nacionais)
- Sistema atende múltiplos tribunais
- Proposta técnica + análise jurídica + acordo formal
- **Prazo realista**: meses

### Pedido direto (empresa privada)
- ❌ **Negado** - SSO não é API pública

## O que o SSO entrega vs. não entrega

**Entrega**:
- ✅ Autenticação de usuários do Judiciário
- ✅ Tokens OAuth2/OpenID Connect
- ✅ Identificação de perfil (magistrado, servidor)

**NÃO entrega**:
- ❌ Dados processuais
- ❌ Conteúdo dos autos
- ❌ Movimentações processuais

**Ou seja**: SSO ≠ Dados processuais

## Decisão técnica atual: SERPRO + Datajud

### Por que essa escolha está correta agora:

| Critério | SERPRO + Datajud | PJe SSO |
|----------|------------------|---------|
| Acesso | ✅ Oficial e imediato | ❌ Bloqueio institucional |
| Dados | ✅ Processos + Dívidas | ❌ Só autenticação |
| Cobertura | ✅ 91 tribunais | ⚠️ Depende do convênio |
| Jurídico | ✅ Seguro | ⚠️ Requer acordo formal |
| Timeline | ✅ Funciona agora | ❌ Meses de negociação |

## Quando retomar o PJe SSO

Só faz sentido retomar quando houver:

1. **Tribunal parceiro** interessado no sistema
2. **Convênio formal** assinado
3. **Demanda institucional** clara que exija:
   - Login único de magistrados/servidores
   - Integração profunda com fluxo interno do Tribunal

## Roadmap técnico

### Fase Atual ✅
- SERPRO: Consulta dívidas ativas por CPF
- Datajud: Consulta processos em 91 tribunais

### Fase Futura (se houver convênio)
- PJe SSO: Autenticação institucional
- PJe API: Consulta processos por CPF (via tribunal específico)

## Conclusão

**A integração técnica com PJe SSO está pronta e documentada.**

**O bloqueio não é técnico, é institucional.**

Aguardar parceria com Tribunal ou convênio CNJ antes de retomar.

---

**Data**: 07/01/2026  
**Status**: SERPRO + Datajud operacionais | PJe SSO aguarda convênio institucional
