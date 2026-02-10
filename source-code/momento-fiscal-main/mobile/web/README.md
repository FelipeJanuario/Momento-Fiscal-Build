# 🗺️ Configuração do Google Maps - Quick Start

## Para testar o mapa agora

### Opção 1: Arquivo env.js (Recomendado)

```bash
# 1. Copiar arquivo de exemplo
cp env.js.example env.js

# 2. Editar env.js e adicionar sua API key
# GOOGLE_MAPS_API_KEY: 'sua_api_key_aqui'

# 3. Rodar Flutter
flutter run -d chrome
```

### Opção 2: Direto no index.html (Rápido mas não recomendado)

Edite `index.html` e substitua `YOUR_API_KEY_HERE` pela sua API key.

⚠️ **NÃO commite o arquivo com a API key real!**

## Obter API Key do Google Maps

1. Acesse [Google Cloud Console](https://console.cloud.google.com/)
2. Crie/selecione um projeto
3. Habilite **Maps JavaScript API**
4. Vá em **Credentials** > **+ CREATE CREDENTIALS** > **API key**
5. Copie a API key gerada

## Mais Informações

Veja o guia completo em: `../GOOGLE_MAPS_WEB_CONFIG.md`

## 💰 Custos

- **$200 gratuito por mês** (suficiente para ~28.000 carregamentos de mapa)
- Desenvolvimento local geralmente fica no free tier
- Configure alertas de billing no Google Cloud Console

---

✅ **env.js** está no .gitignore (não será commitado)
