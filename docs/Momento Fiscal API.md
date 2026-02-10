Momento Fiscal API (v0.1.4)
Download OpenAPI specification:
Download
Momento Fiscal Team: contato@momentofiscal.com.br
URL: https://momentofiscal.com.br
License: Proprietary
Terms of Service
API completa do sistema Momento Fiscal - plataforma para análise fiscal e consultorias.
Esta API fornece endpoints para:
Autenticação e gerenciamento de usuários
Gestão de instituições
Consultorias e propostas
Notificações
Análise de licitações
Integração com Stripe para pagamentos
Consultas ao SERPRO
Autenticação
A API utiliza JWT (JSON Web Tokens) para autenticação. Após o login, inclua o token no header:
Authorization: Bearer <seu_token>
Paginação
Endpoints que retornam listas suportam paginação via parâmetros:
page : número da página (padrão: 1)
per_page : itens por página (padrão: 10)
Health
|
|
10/10/25, 4:46 PM
Momento Fiscal API
ﬁle:///home/ximenes/dev/momento-ﬁscal/redoc-static.html#tag/Authentication/paths/~1api~1v1~1authentication~1users~1sign_in/post
1/45


Verificação de saúde do sistema
Verificação de saúde do sistema
Endpoint para verificar se a API está funcionando corretamente
AUTHORIZATIONS:
bearerAuth
Responses
200 Sistema funcionando normalmente
— 500 Erro interno do servidor
Response samples
200
GET
/api/health/up
application/json
Expand all
Collapse all
Copy
{
"name": "momento_fiscal",
"hostname": "servidor-001",
"pid": 12345,
"parent_id": 1,
"platform": 
-
{
"name": "rails",
"version": "7.1.0"
}
}
Content type
10/10/25, 4:46 PM
Momento Fiscal API
ﬁle:///home/ximenes/dev/momento-ﬁscal/redoc-static.html#tag/Authentication/paths/~1api~1v1~1authentication~1users~1sign_in/post
2/45


Authentication
Autenticação e gerenciamento de sessões
Login de usuário
Autentica um usuário e retorna um token JWT
AUTHORIZATIONS:
bearerAuth
REQUEST BODY SCHEMA: 
application/json
required
object
Responses
200 Login realizado com sucesso
— 401 Credenciais inválidas
— 404 Usuário não encontrado
Request samples
Payload
user
required
POST
/api/v1/authentication/users/sign_in
application/json
Expand all
Collapse all
Copy
Content type
10/10/25, 4:46 PM
Momento Fiscal API
ﬁle:///home/ximenes/dev/momento-ﬁscal/redoc-static.html#tag/Authentication/paths/~1api~1v1~1authentication~1users~1sign_in/post
3/45


Response samples
200
{
"user": 
-
{
"identity": "12345678900",
"password": "minhasenha123"
}
}
application/json
Expand all
Collapse all
Copy
{
"user": 
-
{
"id": "550e8400-e29b-41d4-a716-446655440000",
"name": "João Silva",
"email": "joao.silva@exemplo.com",
"cpf": "12345678901",
"phone": "(11) 99999-9999",
"birth_date": "1990-01-15",
"sex": "male",
"role": "client",
"oab_subscription": "123456",
"oab_state": "SP",
"admin": false,
"ios_plan": false,
"stripe_customer_id": "string",
"created_at": "2024-01-15T10:30:00Z",
"updated_at": "2024-01-15T10:30:00Z"
},
"token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
Logout de usuário
Encerra a sessão do usuário autenticado
AUTHORIZATIONS:
bearerAuth
Content type
10/10/25, 4:46 PM
Momento Fiscal API
ﬁle:///home/ximenes/dev/momento-ﬁscal/redoc-static.html#tag/Authentication/paths/~1api~1v1~1authentication~1users~1sign_in/post
4/45


Responses
200 Logout realizado com sucesso
Response samples
200
DELETE
/api/v1/authentication/users/sign_out
application/json
Copy
{
"message": "Signed out successfully"
}
Registro de usuário
Registra um novo usuário no sistema
AUTHORIZATIONS:
bearerAuth
REQUEST BODY SCHEMA: 
application/json
required
object (UserRegistrationInput)
Responses
201 Usuário criado com sucesso
user
required
Content type
10/10/25, 4:46 PM
Momento Fiscal API
ﬁle:///home/ximenes/dev/momento-ﬁscal/redoc-static.html#tag/Authentication/paths/~1api~1v1~1authentication~1users~1sign_in/post
5/45


422 Dados inválidos
Request samples
Payload
Response samples
201
422
POST
/api/v1/authentication/users
application/json
Expand all
Collapse all
Copy
{
"user": 
-
{
"name": "João Silva",
"email": "joao.silva@exemplo.com",
"cpf": "12345678901",
"phone": "(11) 99999-9999",
"birth_date": "1990-01-15",
"sex": "male",
"oab_subscription": "123456",
"oab_state": "SP",
"ios_plan": false,
"password": "senhasegura123",
"password_confirmation": "senhasegura123"
}
}
application/json
Expand all
Collapse all
Copy
Content type
Content type
10/10/25, 4:46 PM
Momento Fiscal API
ﬁle:///home/ximenes/dev/momento-ﬁscal/redoc-static.html#tag/Authentication/paths/~1api~1v1~1authentication~1users~1sign_in/post
6/45


Users
Operações com usuários
{
"user": 
-
{
"id": "550e8400-e29b-41d4-a716-446655440000",
"name": "João Silva",
"email": "joao.silva@exemplo.com",
"cpf": "12345678901",
"phone": "(11) 99999-9999",
"birth_date": "1990-01-15",
"sex": "male",
"role": "client",
"oab_subscription": "123456",
"oab_state": "SP",
"admin": false,
"ios_plan": false,
"stripe_customer_id": "string",
"created_at": "2024-01-15T10:30:00Z",
"updated_at": "2024-01-15T10:30:00Z"
}
}
Listar usuários
Retorna uma lista paginada de usuários
AUTHORIZATIONS:
bearerAuth
QUERY PARAMETERS
object
Termo de busca para filtrar resultados
integer
>= 1
Default: 1
Número da página para paginação (padrão: 1)
query
page
10/10/25, 4:46 PM
Momento Fiscal API
ﬁle:///home/ximenes/dev/momento-ﬁscal/redoc-static.html#tag/Authentication/paths/~1api~1v1~1authentication~1users~1sign_in/post
7/45


integer
[ 1 .. 100 ]
Default: 25
Número de itens por página (padrão: 25, máximo: 100)
Responses
200 Lista de usuários
Response samples
200
per_page
GET
/api/v1/users
application/json
Expand all
Collapse all
Copy
{
"users": 
-
[
 … 
+ {
}
],
"pagination_params": 
-
{
"page": 1,
"per_page": 10,
"total": 150
}
}
Criar usuário
Cria um novo usuário no sistema
AUTHORIZATIONS:
bearerAuth
REQUEST BODY SCHEMA: 
application/json
Content type
10/10/25, 4:46 PM
Momento Fiscal API
ﬁle:///home/ximenes/dev/momento-ﬁscal/redoc-static.html#tag/Authentication/paths/~1api~1v1~1authentication~1users~1sign_in/post
8/45


required
object (UserUpdateInput)
Responses
201 Usuário criado com sucesso
— 422 Dados inválidos
Request samples
Payload
Response samples
201
user
required
POST
/api/v1/users
application/json
Expand all
Collapse all
Copy
{
"user": 
-
{
"name": "João Silva Santos",
"email": "joao.santos@exemplo.com",
"cpf": "12345678901",
"phone": "(11) 99999-9999",
"birth_date": "1990-01-15",
"sex": "male",
"ios_plan": false,
"role": "consultant"
}
}
application/json
Content type
Content type
10/10/25, 4:46 PM
Momento Fiscal API
ﬁle:///home/ximenes/dev/momento-ﬁscal/redoc-static.html#tag/Authentication/paths/~1api~1v1~1authentication~1users~1sign_in/post
9/45


Expand all
Collapse all
Copy
{
"user": 
-
{
"id": "550e8400-e29b-41d4-a716-446655440000",
"name": "João Silva",
"email": "joao.silva@exemplo.com",
"cpf": "12345678901",
"phone": "(11) 99999-9999",
"birth_date": "1990-01-15",
"sex": "male",
"role": "client",
"oab_subscription": "123456",
"oab_state": "SP",
"admin": false,
"ios_plan": false,
"stripe_customer_id": "string",
"created_at": "2024-01-15T10:30:00Z",
"updated_at": "2024-01-15T10:30:00Z"
}
}
Obter usuário
Retorna os detalhes de um usuário específico
AUTHORIZATIONS:
bearerAuth
PATH PARAMETERS
string <uuid>
ID do usuário
Responses
200 Detalhes do usuário
— 404 Usuário não encontrado
id
required
10/10/25, 4:46 PM
Momento Fiscal API
ﬁle:///home/ximenes/dev/momento-ﬁscal/redoc-static.html#tag/Authentication/paths/~1api~1v1~1authentication~1users~1sign_in/post
10/45


Response samples
200
GET
/api/v1/users/{id}
application/json
Expand all
Collapse all
Copy
{
"user": 
-
{
"id": "550e8400-e29b-41d4-a716-446655440000",
"name": "João Silva",
"email": "joao.silva@exemplo.com",
"cpf": "12345678901",
"phone": "(11) 99999-9999",
"birth_date": "1990-01-15",
"sex": "male",
"role": "client",
"oab_subscription": "123456",
"oab_state": "SP",
"admin": false,
"ios_plan": false,
"stripe_customer_id": "string",
"created_at": "2024-01-15T10:30:00Z",
"updated_at": "2024-01-15T10:30:00Z"
}
}
Atualizar usuário
Atualiza os dados de um usuário
AUTHORIZATIONS:
bearerAuth
PATH PARAMETERS
Content type
10/10/25, 4:46 PM
Momento Fiscal API
ﬁle:///home/ximenes/dev/momento-ﬁscal/redoc-static.html#tag/Authentication/paths/~1api~1v1~1authentication~1users~1sign_in/post
11/45


string <uuid>
ID do usuário
REQUEST BODY SCHEMA: 
application/json
required
object (UserUpdateInput)
Responses
200 Usuário atualizado com sucesso
— 422 Dados inválidos
Request samples
Payload
Response samples
id
required
user
required
PATCH
/api/v1/users/{id}
application/json
Expand all
Collapse all
Copy
{
"user": 
-
{
"name": "João Silva Santos",
"email": "joao.santos@exemplo.com",
"cpf": "12345678901",
"phone": "(11) 99999-9999",
"birth_date": "1990-01-15",
"sex": "male",
"ios_plan": false,
"role": "consultant"
}
}
Content type
10/10/25, 4:46 PM
Momento Fiscal API
ﬁle:///home/ximenes/dev/momento-ﬁscal/redoc-static.html#tag/Authentication/paths/~1api~1v1~1authentication~1users~1sign_in/post
12/45


200
application/json
Expand all
Collapse all
Copy
{
"user": 
-
{
"id": "550e8400-e29b-41d4-a716-446655440000",
"name": "João Silva",
"email": "joao.silva@exemplo.com",
"cpf": "12345678901",
"phone": "(11) 99999-9999",
"birth_date": "1990-01-15",
"sex": "male",
"role": "client",
"oab_subscription": "123456",
"oab_state": "SP",
"admin": false,
"ios_plan": false,
"stripe_customer_id": "string",
"created_at": "2024-01-15T10:30:00Z",
"updated_at": "2024-01-15T10:30:00Z"
}
}
Excluir usuário
Remove um usuário do sistema
AUTHORIZATIONS:
bearerAuth
PATH PARAMETERS
string <uuid>
ID do usuário
Responses
id
required
Content type
10/10/25, 4:46 PM
Momento Fiscal API
ﬁle:///home/ximenes/dev/momento-ﬁscal/redoc-static.html#tag/Authentication/paths/~1api~1v1~1authentication~1users~1sign_in/post
13/45


Institutions
Gestão de instituições
— 204 Usuário excluído com sucesso
— 404 Usuário não encontrado
DELETE
/api/v1/users/{id}
Listar instituições
Retorna uma lista paginada de instituições
AUTHORIZATIONS:
bearerAuth
QUERY PARAMETERS
object
Termo de busca para filtrar resultados
integer
>= 1
Default: 1
Número da página para paginação (padrão: 1)
integer
[ 1 .. 100 ]
Default: 25
Número de itens por página (padrão: 25, máximo: 100)
Responses
query
page
per_page
10/10/25, 4:46 PM
Momento Fiscal API
ﬁle:///home/ximenes/dev/momento-ﬁscal/redoc-static.html#tag/Authentication/paths/~1api~1v1~1authentication~1users~1sign_in/post
14/45


200 Lista de instituições
Response samples
200
GET
/api/v1/institutions
application/json
Expand all
Collapse all
Copy
{
"institutions": 
-
[
 … 
+ {
}
],
"pagination_params": 
-
{
"page": 1,
"per_page": 10,
"total": 150
}
}
Criar instituição
Cria uma nova instituição junto com usuário responsável
AUTHORIZATIONS:
bearerAuth
REQUEST BODY SCHEMA: 
application/json
required
object (InstitutionInput)
object (UserInput)
institution
required
user
required
Content type
10/10/25, 4:46 PM
Momento Fiscal API
ﬁle:///home/ximenes/dev/momento-ﬁscal/redoc-static.html#tag/Authentication/paths/~1api~1v1~1authentication~1users~1sign_in/post
15/45


Responses
201 Instituição criada com sucesso
— 422 Dados inválidos
Request samples
Payload
Response samples
POST
/api/v1/institutions
application/json
Expand all
Collapse all
Copy
{
"institution": 
-
{
"cnpj": "12345678000195",
"responsible_name": "Maria Santos",
"responsible_cpf": "98765432100",
"email": "contato@instituicao.com.br",
"phone": "(11) 3333-4444",
"cell_phone": "(11) 99999-8888",
"limit_debt": 50000
},
"user": 
-
{
"name": "João Silva",
"email": "joao.silva@exemplo.com",
"cpf": "12345678901",
"phone": "(11) 99999-9999",
"birth_date": "1990-01-15",
"sex": "male",
"ios_plan": false,
"password": "senhasegura123",
"password_confirmation": "senhasegura123"
}
}
Content type
10/10/25, 4:46 PM
Momento Fiscal API
ﬁle:///home/ximenes/dev/momento-ﬁscal/redoc-static.html#tag/Authentication/paths/~1api~1v1~1authentication~1users~1sign_in/post
16/45


201
application/json
Expand all
Collapse all
Copy
{
"institution": 
-
{
"id": "550e8400-e29b-41d4-a716-446655440000",
"cnpj": "12345678000195",
"responsible_name": "Maria Santos",
"responsible_cpf": "98765432100",
"email": "contato@instituicao.com.br",
"phone": "(11) 3333-4444",
"cell_phone": "(11) 99999-8888",
"limit_debt": 50000,
"created_at": "2024-01-15T10:30:00Z",
"updated_at": "2024-01-15T10:30:00Z"
}
}
Obter instituição
Retorna os detalhes de uma instituição específica
AUTHORIZATIONS:
bearerAuth
PATH PARAMETERS
string <uuid>
ID da instituição
Responses
200 Detalhes da instituição
— 404 Instituição não encontrada
id
required
Content type
10/10/25, 4:46 PM
Momento Fiscal API
ﬁle:///home/ximenes/dev/momento-ﬁscal/redoc-static.html#tag/Authentication/paths/~1api~1v1~1authentication~1users~1sign_in/post
17/45


Response samples
200
GET
/api/v1/institutions/{id}
application/json
Expand all
Collapse all
Copy
{
"institution": 
-
{
"id": "550e8400-e29b-41d4-a716-446655440000",
"cnpj": "12345678000195",
"responsible_name": "Maria Santos",
"responsible_cpf": "98765432100",
"email": "contato@instituicao.com.br",
"phone": "(11) 3333-4444",
"cell_phone": "(11) 99999-8888",
"limit_debt": 50000,
"created_at": "2024-01-15T10:30:00Z",
"updated_at": "2024-01-15T10:30:00Z"
}
}
Atualizar instituição
Atualiza os dados de uma instituição
AUTHORIZATIONS:
bearerAuth
PATH PARAMETERS
string <uuid>
ID da instituição
REQUEST BODY SCHEMA: 
application/json
required
id
required
Content type
10/10/25, 4:46 PM
Momento Fiscal API
ﬁle:///home/ximenes/dev/momento-ﬁscal/redoc-static.html#tag/Authentication/paths/~1api~1v1~1authentication~1users~1sign_in/post
18/45


object (InstitutionInput)
Responses
200 Instituição atualizada com sucesso
— 422 Dados inválidos
Request samples
Payload
Response samples
200
institution
required
PATCH
/api/v1/institutions/{id}
application/json
Expand all
Collapse all
Copy
{
"institution": 
-
{
"cnpj": "12345678000195",
"responsible_name": "Maria Santos",
"responsible_cpf": "98765432100",
"email": "contato@instituicao.com.br",
"phone": "(11) 3333-4444",
"cell_phone": "(11) 99999-8888",
"limit_debt": 50000
}
}
application/json
Expand all
Collapse all
Copy
Content type
Content type
10/10/25, 4:46 PM
Momento Fiscal API
ﬁle:///home/ximenes/dev/momento-ﬁscal/redoc-static.html#tag/Authentication/paths/~1api~1v1~1authentication~1users~1sign_in/post
19/45


{
"institution": 
-
{
"id": "550e8400-e29b-41d4-a716-446655440000",
"cnpj": "12345678000195",
"responsible_name": "Maria Santos",
"responsible_cpf": "98765432100",
"email": "contato@instituicao.com.br",
"phone": "(11) 3333-4444",
"cell_phone": "(11) 99999-8888",
"limit_debt": 50000,
"created_at": "2024-01-15T10:30:00Z",
"updated_at": "2024-01-15T10:30:00Z"
}
}
Excluir instituição
Remove uma instituição do sistema
AUTHORIZATIONS:
bearerAuth
PATH PARAMETERS
string <uuid>
ID da instituição
Responses
— 204 Instituição excluída com sucesso
— 404 Instituição não encontrada
id
required
DELETE
/api/v1/institutions/{id}
10/10/25, 4:46 PM
Momento Fiscal API
ﬁle:///home/ximenes/dev/momento-ﬁscal/redoc-static.html#tag/Authentication/paths/~1api~1v1~1authentication~1users~1sign_in/post
20/45


User Institutions
Tabela associativa entre usuários e instituições
Consultings
Gerenciamento de consultorias
Listar consultorias
Retorna uma lista paginada de consultorias
AUTHORIZATIONS:
bearerAuth
QUERY PARAMETERS
object
Termo de busca para filtrar resultados
integer
>= 1
Default: 1
Número da página para paginação (padrão: 1)
integer
[ 1 .. 100 ]
Default: 25
Número de itens por página (padrão: 25, máximo: 100)
Responses
200 Lista de consultorias
query
page
per_page
10/10/25, 4:46 PM
Momento Fiscal API
ﬁle:///home/ximenes/dev/momento-ﬁscal/redoc-static.html#tag/Authentication/paths/~1api~1v1~1authentication~1users~1sign_in/post
21/45


Response samples
200
GET
/api/v1/consultings
application/json
Expand all
Collapse all
Copy
{
"consultings": 
-
[
 … 
+ {
}
],
"pagination_params": 
-
{
"page": 1,
"per_page": 10,
"total": 150
}
}
Criar consultoria
Cria uma nova consultoria
AUTHORIZATIONS:
bearerAuth
REQUEST BODY SCHEMA: 
application/json
required
object (ConsultingInput)
Responses
201 Consultoria criada com sucesso
consulting
required
Content type
10/10/25, 4:46 PM
Momento Fiscal API
ﬁle:///home/ximenes/dev/momento-ﬁscal/redoc-static.html#tag/Authentication/paths/~1api~1v1~1authentication~1users~1sign_in/post
22/45


— 422 Dados inválidos
Request samples
Payload
Response samples
201
POST
/api/v1/consultings
application/json
Expand all
Collapse all
Copy
{
"consulting": 
-
{
"status": "not_started",
"value": 1500,
"debts_count": 5,
"sent_at": "14:30:00",
"is_favorite": false,
"client_id": "5b3fa7ba-57d3-4017-a65b-d57dcd2db643",
"consultant_id": "75fce6e3-2a82-48eb-be66-650c78d95935"
}
}
application/json
Expand all
Collapse all
Copy
Content type
Content type
10/10/25, 4:46 PM
Momento Fiscal API
ﬁle:///home/ximenes/dev/momento-ﬁscal/redoc-static.html#tag/Authentication/paths/~1api~1v1~1authentication~1users~1sign_in/post
23/45


{
"consulting": 
-
{
"id": 1,
"status": "not_started",
"value": 1500,
"debts_count": 5,
"sent_at": "14:30:00",
"is_favorite": false,
"import_hash": "ABC123",
"client_id": "5b3fa7ba-57d3-4017-a65b-d57dcd2db643",
"consultant_id": "75fce6e3-2a82-48eb-be66-650c78d95935",
"client":  … 
+
{
},
"consultant":  … 
+
{
},
"created_at": "2024-01-15T10:30:00Z",
"updated_at": "2024-01-15T10:30:00Z"
}
}
Obter consultoria
Retorna os detalhes de uma consultoria específica
AUTHORIZATIONS:
bearerAuth
PATH PARAMETERS
integer
ID da consultoria
Responses
200 Detalhes da consultoria
— 404 Consultoria não encontrada
id
required
GET
/api/v1/consultings/{id}
10/10/25, 4:46 PM
Momento Fiscal API
ﬁle:///home/ximenes/dev/momento-ﬁscal/redoc-static.html#tag/Authentication/paths/~1api~1v1~1authentication~1users~1sign_in/post
24/45


Response samples
200
application/json
Expand all
Collapse all
Copy
{
"consulting": 
-
{
"id": 1,
"status": "not_started",
"value": 1500,
"debts_count": 5,
"sent_at": "14:30:00",
"is_favorite": false,
"import_hash": "ABC123",
"client_id": "5b3fa7ba-57d3-4017-a65b-d57dcd2db643",
"consultant_id": "75fce6e3-2a82-48eb-be66-650c78d95935",
"client":  … 
+
{
},
"consultant":  … 
+
{
},
"created_at": "2024-01-15T10:30:00Z",
"updated_at": "2024-01-15T10:30:00Z"
}
}
Atualizar consultoria
Atualiza os dados de uma consultoria
AUTHORIZATIONS:
bearerAuth
PATH PARAMETERS
integer
ID da consultoria
REQUEST BODY SCHEMA: 
application/json
required
object (ConsultingInput)
id
required
consulting
required
Content type
10/10/25, 4:46 PM
Momento Fiscal API
ﬁle:///home/ximenes/dev/momento-ﬁscal/redoc-static.html#tag/Authentication/paths/~1api~1v1~1authentication~1users~1sign_in/post
25/45


Responses
200 Consultoria atualizada com sucesso
— 422 Dados inválidos
Request samples
Payload
Response samples
200
PATCH
/api/v1/consultings/{id}
application/json
Expand all
Collapse all
Copy
{
"consulting": 
-
{
"status": "not_started",
"value": 1500,
"debts_count": 5,
"sent_at": "14:30:00",
"is_favorite": false,
"client_id": "5b3fa7ba-57d3-4017-a65b-d57dcd2db643",
"consultant_id": "75fce6e3-2a82-48eb-be66-650c78d95935"
}
}
application/json
Expand all
Collapse all
Copy
Content type
Content type
10/10/25, 4:46 PM
Momento Fiscal API
ﬁle:///home/ximenes/dev/momento-ﬁscal/redoc-static.html#tag/Authentication/paths/~1api~1v1~1authentication~1users~1sign_in/post
26/45


{
"consulting": 
-
{
"id": 1,
"status": "not_started",
"value": 1500,
"debts_count": 5,
"sent_at": "14:30:00",
"is_favorite": false,
"import_hash": "ABC123",
"client_id": "5b3fa7ba-57d3-4017-a65b-d57dcd2db643",
"consultant_id": "75fce6e3-2a82-48eb-be66-650c78d95935",
"client":  … 
+
{
},
"consultant":  … 
+
{
},
"created_at": "2024-01-15T10:30:00Z",
"updated_at": "2024-01-15T10:30:00Z"
}
}
Excluir consultoria
Remove uma consultoria do sistema
AUTHORIZATIONS:
bearerAuth
PATH PARAMETERS
integer
ID da consultoria
Responses
— 204 Consultoria excluída com sucesso
— 404 Consultoria não encontrada
id
required
DELETE
/api/v1/consultings/{id}
10/10/25, 4:46 PM
Momento Fiscal API
ﬁle:///home/ximenes/dev/momento-ﬁscal/redoc-static.html#tag/Authentication/paths/~1api~1v1~1authentication~1users~1sign_in/post
27/45


Importar consultoria
Importa uma consultoria usando hash de importação
AUTHORIZATIONS:
bearerAuth
PATH PARAMETERS
string
Hash de importação da consultoria
Responses
200 Consultoria importada com sucesso
— 404 Consultoria não encontrada
Response samples
200
import_hash
required
POST
/api/v1/consultings/{import_hash}/import
application/json
Expand all
Collapse all
Copy
Content type
10/10/25, 4:46 PM
Momento Fiscal API
ﬁle:///home/ximenes/dev/momento-ﬁscal/redoc-static.html#tag/Authentication/paths/~1api~1v1~1authentication~1users~1sign_in/post
28/45


Consulting Proposals
Propostas de consultoria
Notifications
Sistema de notificações
{
"consulting": 
-
{
"id": 1,
"status": "not_started",
"value": 1500,
"debts_count": 5,
"sent_at": "14:30:00",
"is_favorite": false,
"import_hash": "ABC123",
"client_id": "5b3fa7ba-57d3-4017-a65b-d57dcd2db643",
"consultant_id": "75fce6e3-2a82-48eb-be66-650c78d95935",
"client":  … 
+
{
},
"consultant":  … 
+
{
},
"created_at": "2024-01-15T10:30:00Z",
"updated_at": "2024-01-15T10:30:00Z"
}
}
Listar notificações
Retorna uma lista paginada de notificações do usuário atual
AUTHORIZATIONS:
bearerAuth
QUERY PARAMETERS
object
query
10/10/25, 4:46 PM
Momento Fiscal API
ﬁle:///home/ximenes/dev/momento-ﬁscal/redoc-static.html#tag/Authentication/paths/~1api~1v1~1authentication~1users~1sign_in/post
29/45


Termo de busca para filtrar resultados
integer
>= 1
Default: 1
Número da página para paginação (padrão: 1)
integer
[ 1 .. 100 ]
Default: 25
Número de itens por página (padrão: 25, máximo: 100)
Responses
200 Lista de notificações
Response samples
200
page
per_page
GET
/api/v1/notifications
application/json
Expand all
Collapse all
Copy
{
"notifications": 
-
[
 … 
+ {
}
],
"pagination_params": 
-
{
"page": 1,
"per_page": 10,
"total": 150
}
}
Obter notificação
Content type
10/10/25, 4:46 PM
Momento Fiscal API
ﬁle:///home/ximenes/dev/momento-ﬁscal/redoc-static.html#tag/Authentication/paths/~1api~1v1~1authentication~1users~1sign_in/post
30/45


Retorna os detalhes de uma notificação específica
AUTHORIZATIONS:
bearerAuth
PATH PARAMETERS
string <uuid>
ID da notificação
Responses
200 Detalhes da notificação
— 404 Notificação não encontrada
Response samples
200
id
required
GET
/api/v1/notifications/{id}
application/json
Expand all
Collapse all
Copy
{
"notification": 
-
{
"id": "550e8400-e29b-41d4-a716-446655440000",
"user_id": "550e8400-e29b-41d4-a716-446655440000",
"title": "Nova consultoria disponível",
"content": "Uma nova consultoria foi adicionada ao sistema",
"redirect_to": "/consultings/1",
"read_at": "14:15:22Z",
"created_at": "2024-01-15T10:30:00Z",
"updated_at": "2024-01-15T10:30:00Z"
}
}
Content type
10/10/25, 4:46 PM
Momento Fiscal API
ﬁle:///home/ximenes/dev/momento-ﬁscal/redoc-static.html#tag/Authentication/paths/~1api~1v1~1authentication~1users~1sign_in/post
31/45


Invitations
Convites de usuários
Free Plan Usage
Controle de uso do plano gratuito
Excluir notificação
Remove uma notificação do usuário
AUTHORIZATIONS:
bearerAuth
PATH PARAMETERS
string <uuid>
ID da notificação
Responses
— 204 Notificação excluída com sucesso
— 404 Notificação não encontrada
id
required
DELETE
/api/v1/notifications/{id}
10/10/25, 4:46 PM
Momento Fiscal API
ﬁle:///home/ximenes/dev/momento-ﬁscal/redoc-static.html#tag/Authentication/paths/~1api~1v1~1authentication~1users~1sign_in/post
32/45


Biddings Analyser
Análise de licitações e empresas
Download de arquivo
Redireciona para download de arquivo do analisador de licitações
AUTHORIZATIONS:
bearerAuth
QUERY PARAMETERS
string
ID do arquivo para download
Responses
— 302 Redirecionamento para download
— 404 Arquivo não encontrado
file_id
required
GET
/api/v1/biddings_analyser/download
Consultar dívidas
Busca informações sobre dívidas no sistema de análise de licitações
AUTHORIZATIONS:
bearerAuth
QUERY PARAMETERS
10/10/25, 4:46 PM
Momento Fiscal API
ﬁle:///home/ximenes/dev/momento-ﬁscal/redoc-static.html#tag/Authentication/paths/~1api~1v1~1authentication~1users~1sign_in/post
33/45


string
ID da dívida
string
CPF ou CNPJ do devedor
string
Status de registro
string
Tipo de status de registro
string
Nome do devedor
integer
Número da página
integer
Tamanho da página
Responses
200 Lista de dívidas
Response samples
200
_id
cpf_cnpj
registration_status
registration_status_type
debted_name
page
page_size
GET
/api/v1/biddings_analyser/debts
application/json
Expand all
Collapse all
Copy
Content type
10/10/25, 4:46 PM
Momento Fiscal API
ﬁle:///home/ximenes/dev/momento-ﬁscal/redoc-static.html#tag/Authentication/paths/~1api~1v1~1authentication~1users~1sign_in/post
34/45


[
- {
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
"value": 1000.5
}
]
Resumo de dívidas por nome do devedor
Retorna a soma (debts_value) e a contagem (debts_count) de dívidas agrupadas por debted_name
para um CPF/CNPJ informado. Os resultados são ordenados por debted_name.
AUTHORIZATIONS:
bearerAuth
PATH PARAMETERS
string
CPF ou CNPJ do devedor
Responses
200 Lista agregada de dívidas por devedor
cpf_cnpj
required
10/10/25, 4:46 PM
Momento Fiscal API
ﬁle:///home/ximenes/dev/momento-ﬁscal/redoc-static.html#tag/Authentication/paths/~1api~1v1~1authentication~1users~1sign_in/post
35/45


Response samples
200
GET
/api/v1/biddings_analyser/debts/{cpf_cnpj}/debts_per_debted_name
application/json
Expand all
Collapse all
Copy
[
- {
"debted_name": "ACME LTDA",
"debts_value": 12345.67,
"debts_count": 3
}
]
Listar empresas
Busca informações sobre empresas no sistema de análise
AUTHORIZATIONS:
bearerAuth
QUERY PARAMETERS
string
Termo de busca
integer
Número da página
integer
Tamanho da página
Responses
200 Lista de empresas
q
page
page_size
Content type
10/10/25, 4:46 PM
Momento Fiscal API
ﬁle:///home/ximenes/dev/momento-ﬁscal/redoc-static.html#tag/Authentication/paths/~1api~1v1~1authentication~1users~1sign_in/post
36/45


Response samples
200
GET
/api/v1/biddings_analyser/companies
application/json
Expand all
Collapse all
Copy
Content type
10/10/25, 4:46 PM
Momento Fiscal API
ﬁle:///home/ximenes/dev/momento-ﬁscal/redoc-static.html#tag/Authentication/paths/~1api~1v1~1authentication~1users~1sign_in/post
37/45


[
- {
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
"foreign_city_name": "string",
"activity_start_date": "2020-01-01",
"main_cnae": "6201-5/01",
"secondary_cnae": "6202-3/00, 6311-9/00",
"email": "contato@empresa.com.br",
"special_status": "string",
"special_status_date": "2019-08-24",
"uf": "SP",
"municipality_code": "3550308",
"special_situation": "string",
"special_situation_date": "2019-08-24",
"simple": true,
"simple_date": "2019-08-24",
"simple_exclusion_date": "2019-08-24",
"mei": true,
"mei_date": "2019-08-24",
"mei_exclusion_date": "2019-08-24",
"debts_count": 0,
"debts_value": 0,
"debts_cache_updated_at": "2019-08-24T14:15:22Z"
}
]
10/10/25, 4:46 PM
Momento Fiscal API
ﬁle:///home/ximenes/dev/momento-ﬁscal/redoc-static.html#tag/Authentication/paths/~1api~1v1~1authentication~1users~1sign_in/post
38/45


Contar empresas por localização
Retorna a contagem de empresas dentro de uma área retangular (bounding box). Informe os dois
pontos (cantos opostos) usando coordenadas [longitude, latitude].
AUTHORIZATIONS:
bearerAuth
QUERY PARAMETERS
Array of numbers <double>
= 2 items
[ items <double > ]
Examples:
starting_point=-46.7&starting_point=-23.6  -
Primeiro ponto (canto) do retângulo de consulta no formato [longitude,
latitude]
Array of numbers <double>
= 2 items
[ items <double > ]
Examples:
ending_point=-46.3&ending_point=-23.3  -
Segundo ponto (canto oposto) do retângulo de consulta no formato
[longitude, latitude]
Responses
200 Contagem de empresas
Response samples
200
starting_point
required
ending_point
required
GET
/api/v1/biddings_analyser/companies/count_in_location
application/json
Copy
Content type
10/10/25, 4:46 PM
Momento Fiscal API
ﬁle:///home/ximenes/dev/momento-ﬁscal/redoc-static.html#tag/Authentication/paths/~1api~1v1~1authentication~1users~1sign_in/post
39/45


{
"count": 0
}
Empresas por localização
Lista empresas localizadas dentro de uma área retangular (bounding box), com ordenação por
debts_value  desc e suporte a filtros e paginação.
AUTHORIZATIONS:
bearerAuth
QUERY PARAMETERS
Array of numbers <double>
= 2 items
[ items <double > ]
Examples:
starting_point=-46.7&starting_point=-23.6  -
Primeiro ponto (canto) do retângulo de consulta no formato [longitude,
latitude]
Array of numbers <double>
= 2 items
[ items <double > ]
Examples:
ending_point=-46.3&ending_point=-23.3  -
Segundo ponto (canto oposto) do retângulo de consulta no formato
[longitude, latitude]
integer
>= 1
Default: 1
Número da página
integer
>= 1
Default: 10
Tamanho da página
number <float>
Valor mínimo de debts_value  (filtro gte)
string
Filtro por ID interno (Mongo _id )
string ^\d{14}$
Filtro por CNPJ (somente números)
starting_point
required
ending_point
required
page
page_size
min_debts_value
_id
cnpj
10/10/25, 4:46 PM
Momento Fiscal API
ﬁle:///home/ximenes/dev/momento-ﬁscal/redoc-static.html#tag/Authentication/paths/~1api~1v1~1authentication~1users~1sign_in/post
40/45


object
Filtros por campo debts_value  usando notação de objeto (exemplo:
debts_value[gte]=1000)
Responses
200 Lista de empresas na localização
Response samples
200
debts_value
GET
/api/v1/biddings_analyser/companies/in_location
application/json
Expand all
Collapse all
Copy
Content type
10/10/25, 4:46 PM
Momento Fiscal API
ﬁle:///home/ximenes/dev/momento-ﬁscal/redoc-static.html#tag/Authentication/paths/~1api~1v1~1authentication~1users~1sign_in/post
41/45


[
- {
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
"foreign_city_name": "string",
"activity_start_date": "2020-01-01",
"main_cnae": "6201-5/01",
"secondary_cnae": "6202-3/00, 6311-9/00",
"email": "contato@empresa.com.br",
"special_status": "string",
"special_status_date": "2019-08-24",
"uf": "SP",
"municipality_code": "3550308",
"special_situation": "string",
"special_situation_date": "2019-08-24",
"simple": true,
"simple_date": "2019-08-24",
"simple_exclusion_date": "2019-08-24",
"mei": true,
"mei_date": "2019-08-24",
"mei_exclusion_date": "2019-08-24",
"debts_count": 0,
"debts_value": 0,
"debts_cache_updated_at": "2019-08-24T14:15:22Z"
}
]
10/10/25, 4:46 PM
Momento Fiscal API
ﬁle:///home/ximenes/dev/momento-ﬁscal/redoc-static.html#tag/Authentication/paths/~1api~1v1~1authentication~1users~1sign_in/post
42/45


SERPRO
Consultas ao SERPRO
Consultar CPF
Realiza consulta de CPF no SERPRO
AUTHORIZATIONS:
bearerAuth
PATH PARAMETERS
string ^\d{11}$
CPF para consulta (apenas números)
Responses
200 Dados do CPF consultado
— 404 CPF não encontrado
Response samples
200
cpf
required
GET
/api/v1/consulta_cpf/{cpf}
application/json
Copy
Content type
10/10/25, 4:46 PM
Momento Fiscal API
ﬁle:///home/ximenes/dev/momento-ﬁscal/redoc-static.html#tag/Authentication/paths/~1api~1v1~1authentication~1users~1sign_in/post
43/45


Processes
Processos judiciais
{
"numeroInscricao": "string"
}
Consultar processos
Consulta processos judiciais
AUTHORIZATIONS:
bearerAuth
Responses
200 Lista de processos
Response samples
200
GET
/api/v1/processes
application/json
Expand all
Collapse all
Copy
{
"total": 2,
"numberOfElements": 20,
"maxElementsSize": 100,
Content type
10/10/25, 4:46 PM
Momento Fiscal API
ﬁle:///home/ximenes/dev/momento-ﬁscal/redoc-static.html#tag/Authentication/paths/~1api~1v1~1authentication~1users~1sign_in/post
44/45


"searchAfter": 
-
[
"1585827783000",
"01348152520198060001"
],
"content": 
-
[
 … 
+ {
}
]
}
10/10/25, 4:46 PM
Momento Fiscal API
ﬁle:///home/ximenes/dev/momento-ﬁscal/redoc-static.html#tag/Authentication/paths/~1api~1v1~1authentication~1users~1sign_in/post
45/45


