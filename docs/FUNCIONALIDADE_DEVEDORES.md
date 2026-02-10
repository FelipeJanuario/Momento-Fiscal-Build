# 🗺️ Funcionalidade: Localização de Devedores

## 📋 Resumo da Funcionalidade

O app possui um **sistema completo de localização de empresas devedoras** usando geolocalização e Google Maps.

---

## 🎯 Como Funciona

### 1. **Busca por Localização no Mapa** (Principal)

**Arquivo**: `pages/location/search_by_location_page.dart`

**Funcionalidades**:
- ✅ Exibe mapa do Google Maps
- ✅ Mostra localização atual do usuário (botão GPS)
- ✅ Desenha círculo de 1km ao redor da câmera
- ✅ Busca empresas devedoras na área visível automaticamente
- ✅ Exibe marcadores customizados com:
  - 📊 Quantidade de empresas
  - 💰 Valor total das dívidas
  - 📍 Agrupamento por geohash

**Fluxo**:
```
Usuário move o mapa
  ↓
_onCameraIdle() detecta parada
  ↓
getCountInLocation() busca dados da API
  ↓
Cria marcadores customizados
  ↓
Usuário clica no marcador
  ↓
Navega para IndebtedCompaniesPage
```

**API Chamada**:
```
GET /api/v1/biddings_analyser/companies/count_in_location
Params:
  - starting_point: [lat, long]
  - ending_point: [lat, long]
  - rows: 15
  - columns: 5
  - debt_nature: (opcional)
```

---

### 2. **Devedores Próximos** (Botão Rápido)

**Arquivo**: `pages/search/debtors_nearby.dart`

**Funcionalidades**:
- ✅ Obtém localização atual automaticamente
- ✅ Cria área de busca de 0.1° (~11km) ao redor
- ✅ Redireciona para lista de empresas

**Fluxo**:
```
Usuário clica "Devedores Próximos"
  ↓
Solicita permissão de localização
  ↓
Obtém GPS atual
  ↓
Calcula bounds (±0.1°)
  ↓
Navega para IndebtedCompaniesPage
```

---

### 3. **Lista de Empresas Endividadas**

**Arquivo**: `pages/location/indebted_companies_page.dart`

**Funcionalidades**:
- ✅ Lista empresas na área selecionada
- ✅ Paginação automática (scroll infinito)
- ✅ Exibe cards com dados da empresa
- ✅ Botão "voltar ao topo"
- ✅ Loading ao carregar mais

**API Chamada**:
```
GET /api/v1/biddings_analyser/companies/in_location
Params:
  - starting_point: [lat, long]
  - ending_point: [lat, long]
  - page: número da página
  - page_size: 10
  - min_debts_value: 100
```

---

## 🏗️ Arquitetura

### Serviços

**`LocationCompaniesRails`** (`core/services/biddingAnalyser/location/location_compaines_rails.dart`)

Métodos:
1. **`getCountInLocation()`** - Conta empresas em região
   - Retorna lista de `Location` com contagem agrupada
   - Usa geohash para agrupamento
   
2. **`getInLocation()`** - Lista empresas em região
   - Retorna lista de `Company` com detalhes completos
   - Suporta paginação

### Modelos

**`Location`** (`core/models/location.dart`)
```dart
- count: int              // Quantidade de empresas
- debtValue: String       // Valor total das dívidas
- geohash: String         // Hash de agrupamento
- center: [lat, long]     // Centro do cluster
- box: [[lat1, long1], [lat2, long2]]  // Bounds da região
```

**`Company`** (`core/models/company.dart`)
```dart
- id, cnpj, corporateName, fantasyName
- debtsValue: double      // Valor das dívidas
- debtsCount: int         // Quantidade de dívidas
- address: Address        // Endereço completo
- cadastralStatus, juridicalNature
- phones, email
- e mais ~40 campos
```

---

## 🎨 UI/UX

### Marcadores Customizados

**Função**: `createCustomMarkerIcon()`

Cria marcadores personalizados com:
- 🎨 Fundo colorido arredondado
- 💰 Ícone de dinheiro
- 📊 Texto com quantidade de empresas
- 💵 Valor total das dívidas

### Círculo de Busca

- Raio: 1000m (1km)
- Cor: Azul semi-transparente
- Centralizado na câmera do mapa
- Atualiza ao mover o mapa

### Interações

1. **Arraste o mapa** → Busca automática ao parar
2. **Clique no marcador** → Vai para lista de empresas
3. **Botão GPS** → Centraliza na localização atual
4. **Botão Info** → Mostra ajuda (método `_showInfoDialog`)

---

## 📊 Dados Retornados pelo Backend

### Contagem em Localização

```json
[
  {
    "count": 15,
    "debt_value": "R$ 1.500.000,00",
    "geohash": "6gkzmg",
    "center": [-23.5505, -46.6333],
    "box": [
      [-23.5600, -46.6400],
      [-23.5400, -46.6200]
    ]
  }
]
```

### Empresas na Localização

```json
{
  "companies": [
    {
      "id": "123",
      "cnpj": "12.345.678/0001-90",
      "corporate_name": "Empresa XYZ Ltda",
      "fantasy_name": "XYZ",
      "debts_value": 50000.00,
      "debts_count": 3,
      "address": {
        "street": "Rua ABC",
        "number": "123",
        "neighborhood": "Centro",
        "city": "São Paulo",
        "state": "SP",
        "zip_code": "01234-567"
      },
      // ... mais campos
    }
  ],
  "total_count": 150,
  "current_page": 1,
  "total_pages": 15
}
```

---

## 🔧 Configurações Técnicas

### Geohash

- Sistema de agrupamento geográfico
- Precisão variável (mais zoom = geohash mais longo)
- Otimiza consultas ao backend

### Grid de Busca

```dart
rows: 15      // Divisões verticais
columns: 5    // Divisões horizontais
```

Divide a tela em 75 células (15×5) para agrupamento eficiente.

### Paginação

```dart
page_size: 10           // 10 empresas por página
min_debts_value: 100    // Mínimo R$ 100 em dívidas
```

### Área de Busca (Devedores Próximos)

```dart
raio = 0.1° // Aproximadamente 11km
latStarting = currentLat - 0.1
latEnding = currentLat + 0.1
longStarting = currentLong - 0.1
longEnding = currentLong + 0.1
```

---

## 🚀 Fluxo Completo de Uso

### Cenário 1: Busca Manual no Mapa

```
1. Usuário abre "Busca por Localização"
2. Mapa carrega com localização atual
3. Círculo azul aparece (raio 1km)
4. Marcadores aparecem automaticamente
5. Usuário move/zoom no mapa
6. Ao parar, novos marcadores carregam
7. Clica em marcador → Lista de empresas
8. Scroll na lista → Carrega mais empresas
```

### Cenário 2: Busca Rápida Próxima

```
1. Usuário clica "Devedores Próximos"
2. App pede permissão de localização
3. Obtém GPS atual
4. Calcula área de ~11km ao redor
5. Abre lista diretamente
6. Mostra empresas na área
```

---

## 📱 Componentes Visuais

### Tela: Busca por Localização

```
[AppBar: "Busca por Localização" | Info]
┌─────────────────────────────────────┐
│         Google Maps                 │
│                                     │
│  [Marcadores com valores]          │
│  [Círculo azul 1km]                │
│  [Marcador verde: você está aqui]  │
│                                     │
│                      [Botão GPS ⊙] │
└─────────────────────────────────────┘
```

### Tela: Lista de Empresas

```
[AppBar: "Empresas Endividadas"]
┌─────────────────────────────────────┐
│ [CompanyCard]                       │
│  Nome Fantasia                      │
│  CNPJ: XX.XXX.XXX/XXXX-XX          │
│  Dívidas: R$ XXX.XXX,XX (X itens)  │
│  Endereço: Rua..., Nº, Bairro      │
├─────────────────────────────────────┤
│ [CompanyCard]                       │
│  ...                                │
├─────────────────────────────────────┤
│ [Loading mais empresas...]          │
│                                     │
│                    [↑ Topo]         │
└─────────────────────────────────────┘
```

---

## 🔍 Filtros e Recursos Adicionais

### Recursos Comentados (Disponíveis para Ativar)

**Busca por Natureza da Dívida**:
```dart
// Código comentado nas linhas ~325-400 de search_by_location_page.dart
// _showAutocompleteDialog() - Dialog para filtrar por tipo de dívida
```

Para ativar:
1. Descomentar método `_showAutocompleteDialog()`
2. Descomentar botão FloatingActionButton no build
3. Implementar lista `_kOptions` com tipos de dívida

---

## 🎯 Casos de Uso

### 1. Escritório de Advocacia
Buscar empresas devedoras em região específica para oferecer serviços de cobrança.

### 2. Contador/Consultor
Identificar potenciais clientes com problemas fiscais.

### 3. Análise de Mercado
Mapear áreas com maior concentração de empresas endividadas.

### 4. Investigação
Localizar empresas específicas e suas dívidas.

---

## ⚙️ Variáveis de Estado

```dart
// search_by_location_page.dart
_markers: Set<Marker>           // Marcador do usuário
_locationMarkers: Set<Marker>   // Marcadores de empresas
circles: Set<Circle>            // Círculo de busca
companies: List<Company>        // Empresas encontradas
currentPage: int                // Paginação
isLoading: bool                 // Loading geral
_currentCameraCenter: LatLng    // Centro da câmera
_previousGeohash: String        // Último geohash (otimização)
_selectedDebtNature: String     // Filtro de tipo de dívida
```

---

## 🔒 Permissões Necessárias

### Android (`android/app/src/main/AndroidManifest.xml`)
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
```

### iOS (`ios/Runner/Info.plist`)
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Precisamos da sua localização para encontrar empresas próximas</string>
```

---

## 📈 Otimizações Implementadas

1. **Geohash** - Agrupa empresas próximas
2. **Debounce** - Evita múltiplas requisições ao mover o mapa
3. **Lazy Loading** - Carrega empresas sob demanda
4. **Cache de Marcadores** - Não recria marcadores existentes
5. **Clear seletivo** - Limpa marcadores apenas ao mudar precisão (geohash length)

---

## 🐛 Observações e TODOs

### Código Comentado

Há código comentado para:
- Busca por tipo de dívida
- Dialog de autocomplete
- Lista de opções de filtro

### Melhorias Possíveis

1. ✨ Ativar filtro por natureza da dívida
2. ✨ Adicionar filtro por valor mínimo
3. ✨ Salvar localizações favoritas
4. ✨ Exportar lista de empresas
5. ✨ Modo offline com cache
6. ✨ Compartilhar localização de empresa

---

## 📊 Métricas de Performance

### Quantidade de Dados

- **Por requisição**: ~15-75 localizações (depende do zoom)
- **Por página**: 10 empresas
- **Valor mínimo**: R$ 100 em dívidas

### Latência Esperada

- Busca de contagem: ~500-1000ms
- Busca de empresas: ~300-800ms (depende da quantidade)
- Carregamento de marcadores: ~100-300ms (render)

---

## 🎓 Tecnologias Utilizadas

- **google_maps_flutter**: Mapa interativo
- **geolocator**: GPS e permissões
- **geohash**: Agrupamento geográfico (backend)
- **http**: Requisições à API
- **flutter_svg**: Ícones customizados (se usado)

---

## ✅ Status Atual

| Funcionalidade | Status | Observação |
|---------------|--------|------------|
| Mapa Google Maps | ✅ Funcionando | API key configurada |
| Localização GPS | ✅ Funcionando | Necessita permissão |
| Busca automática | ✅ Funcionando | onCameraIdle |
| Marcadores customizados | ✅ Funcionando | Com valores |
| Lista de empresas | ✅ Funcionando | Paginação ok |
| Scroll infinito | ✅ Funcionando | Debounce ok |
| Filtro por dívida | ⚠️ Comentado | Código disponível |
| Platform Web | ✅ Funcionando | Correções aplicadas |

---

## 🔗 Arquivos Relacionados

### Páginas
- `pages/location/search_by_location_page.dart` - Mapa principal
- `pages/location/indebted_companies_page.dart` - Lista empresas
- `pages/search/debtors_nearby.dart` - Busca rápida

### Serviços
- `core/services/biddingAnalyser/location/location_compaines_rails.dart`

### Modelos
- `core/models/location.dart`
- `core/models/company.dart`

### Componentes
- `components/company_card.dart` - Card de empresa na lista

---

**Desenvolvido**: Sistema completo e funcional  
**Status**: ✅ Operacional  
**Última atualização**: 20/12/2024
