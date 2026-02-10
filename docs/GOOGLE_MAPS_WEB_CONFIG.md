cd c:\momento-fiscal-transferencia\source-code\momento-fiscal-main\mobile; flutter run -d chrome# 🗺️ Configuração do Google Maps para Flutter Web

## ⚠️ Erro Corrigido

**Problema**: `TypeError: Cannot read properties of undefined (reading 'maps')`

**Causa**: Google Maps JavaScript API não estava carregada no `index.html`

---

## 🔧 Solução Aplicada

### 1. Script Adicionado no index.html

Foi adicionado o script do Google Maps no arquivo `web/index.html`:

```html
<!-- Google Maps JavaScript API -->
<script src="https://maps.googleapis.com/maps/api/js?key=YOUR_API_KEY_HERE"></script>
```

### 2. Proteções Platform API

Todas as chamadas a `Platform.isIOS` e `Platform.isAndroid` foram protegidas com `!kIsWeb`:

**Arquivos corrigidos**:
- `components/plan_card.dart`
- `main.dart`
- `pages/dashboard/dashboad_page.dart`
- `pages/plans/verify_plans_page.dart`
- `core/services/billing/in_app_purchase_service.dart`
- `core/services/billing/google_play_billing_service.dart`

**Exemplo de correção**:
```dart
// ❌ ANTES (erro na Web)
if (Platform.isIOS) {
  // código
}

// ✅ DEPOIS (compatível com Web)
if (!kIsWeb && Platform.isIOS) {
  // código
}
```

---

## 🔑 Obter API Key do Google Maps

### Passo 1: Criar/Acessar Projeto no Google Cloud

1. Acesse [Google Cloud Console](https://console.cloud.google.com/)
2. Crie um novo projeto ou selecione um existente
3. Navegue até **APIs & Services** > **Credentials**

### Passo 2: Habilitar APIs Necessárias

1. Vá em **APIs & Services** > **Library**
2. Habilite as seguintes APIs:
   - **Maps JavaScript API** (obrigatória para Web)
   - **Maps SDK for Android** (se usar Android)
   - **Maps SDK for iOS** (se usar iOS)
   - **Geocoding API** (para busca de endereços)
   - **Places API** (para autocomplete de lugares)

### Passo 3: Criar API Key

1. Vá em **APIs & Services** > **Credentials**
2. Clique em **+ CREATE CREDENTIALS** > **API key**
3. Copie a API key gerada

### Passo 4: Restringir API Key (Recomendado)

Para segurança, restrinja a API key:

1. Clique no nome da API key criada
2. Em **Application restrictions**, escolha:
   - **HTTP referrers (web sites)** para Web
3. Adicione os domínios permitidos:
   ```
   http://localhost:*
   https://seudominio.com.br/*
   ```
4. Em **API restrictions**, selecione:
   - Maps JavaScript API
   - Geocoding API
   - Places API (se usar)
5. Salve

---

## 💰 Custos e Limites

### Plano Gratuito (Free Tier)

O Google Maps oferece **$200 de crédito gratuito por mês**, que equivale a:

- **Maps JavaScript API**: ~28.000 carregamentos/mês
- **Geocoding API**: ~40.000 requests/mês
- **Places API**: ~10.000 requests/mês

### Após o Free Tier

| API | Preço (após $200 grátis) |
|-----|--------------------------|
| Maps JavaScript API | $7 por 1.000 carregamentos |
| Geocoding API | $5 por 1.000 requests |
| Places API (Autocomplete) | $2.83 por 1.000 sessions |

**Para apps em desenvolvimento/teste local**: O custo é **ZERO** se você ficar dentro do free tier.

---

## 🛠️ Configuração no Projeto

### Para Web (Obrigatório)

Edite `mobile/web/index.html` e substitua `YOUR_API_KEY_HERE`:

```html
<script src="https://maps.googleapis.com/maps/api/js?key=SUA_API_KEY_AQUI"></script>
```

### Para Android (Opcional)

Edite `mobile/android/app/src/main/AndroidManifest.xml`:

```xml
<application>
  <meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="SUA_API_KEY_AQUI"/>
</application>
```

### Para iOS (Opcional)

Edite `mobile/ios/Runner/AppDelegate.swift`:

```swift
import GoogleMaps

GMSServices.provideAPIKey("SUA_API_KEY_AQUI")
```

---

## 🧪 Teste Local (Sem API Key Real)

### Opção 1: Usar API Key de Desenvolvimento

Crie uma API key **sem restrições** apenas para desenvolvimento local:
- Adicione na `index.html`
- **NÃO commite no Git** (adicione ao `.gitignore`)

### Opção 2: Desabilitar Google Maps Temporariamente

Se não quiser configurar agora, comente o GoogleMap no código:

```dart
// Em search_by_location_page.dart
return Scaffold(
  body: Center(
    child: Text('Google Maps desabilitado para Web'),
  ),
);
```

---

## 🔒 Segurança: NÃO Commitar API Keys

### 1. Criar arquivo de variáveis de ambiente

Crie `mobile/web/env.js`:
```javascript
const ENV = {
  GOOGLE_MAPS_API_KEY: 'SUA_API_KEY_AQUI'
};
```

### 2. Adicionar ao .gitignore

```
mobile/web/env.js
```

### 3. Carregar no index.html

```html
<script src="env.js"></script>
<script>
  const script = document.createElement('script');
  script.src = `https://maps.googleapis.com/maps/api/js?key=${ENV.GOOGLE_MAPS_API_KEY}`;
  document.head.appendChild(script);
</script>
```

---

## 🐛 Troubleshooting

### Erro: "This page can't load Google Maps correctly"

**Causa**: API key inválida ou não habilitada para Maps JavaScript API

**Solução**:
1. Verifique se a API key está correta no `index.html`
2. Confirme que **Maps JavaScript API** está habilitada no Google Cloud
3. Aguarde 1-2 minutos para propagação das mudanças

### Erro: "Cannot read properties of undefined (reading 'maps')"

**Causa**: Script não carregado antes do Flutter tentar usar

**Solução**:
1. Confirme que o `<script>` do Google Maps está ANTES do `flutter_bootstrap.js`
2. Faça hard refresh no navegador (Ctrl+Shift+R)

### Erro: "ApiNotActivatedMapError"

**Causa**: API não habilitada no projeto

**Solução**:
1. Acesse Google Cloud Console
2. Habilite **Maps JavaScript API**
3. Aguarde alguns minutos

---

## ✅ Checklist de Configuração

- [ ] Criar projeto no Google Cloud Console
- [ ] Habilitar Maps JavaScript API
- [ ] Criar API key
- [ ] Restringir API key (segurança)
- [ ] Adicionar API key no `web/index.html`
- [ ] Adicionar `env.js` ao `.gitignore`
- [ ] Testar no navegador (`flutter run -d chrome`)
- [ ] Verificar se mapa carrega sem erros

---

## 📚 Documentação Oficial

- [Google Maps Platform](https://developers.google.com/maps)
- [Maps JavaScript API](https://developers.google.com/maps/documentation/javascript)
- [Flutter Google Maps Plugin](https://pub.dev/packages/google_maps_flutter)
- [Pricing Calculator](https://mapsplatformtransition.withgoogle.com/calculator)

---

## 🚨 Importante

**Para produção**:
1. ✅ SEMPRE restrinja a API key por domínio
2. ✅ NUNCA commite API keys no Git
3. ✅ Use variáveis de ambiente
4. ✅ Monitore uso no Google Cloud Console
5. ✅ Configure alertas de billing

**Para desenvolvimento local**:
- Você pode usar uma API key sem restrições APENAS para testes
- Mantenha essa key em arquivo local não versionado
- O free tier de $200/mês é mais que suficiente para desenvolvimento

---

**Status**: ✅ Configuração básica concluída. Adicione sua API key para testar!
