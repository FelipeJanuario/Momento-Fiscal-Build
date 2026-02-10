# 🚀 Rodando em Modo Desenvolvimento

## Configuração Rápida

### Modo Dev (localhost:3000)
```bash
flutter run -d chrome --dart-define=DEV_MODE=true
```

### Modo Produção (proxy Nginx)
```bash
flutter run -d chrome --dart-define=DEV_MODE=false
# ou simplesmente
flutter run -d chrome
```

---

## Como funciona?

A flag `DEV_MODE` controla qual URL da API será usada:

| DEV_MODE | URL da API | Uso |
|----------|------------|-----|
| `true` | `http://localhost:3000` | Desenvolvimento local |
| `false` | `` (vazio) | Produção com Nginx |

---

## Pré-requisitos

### Backend Rails rodando
```powershell
cd C:\momento-fiscal-transferencia\source-code\momento-fiscal-main
docker-compose -f docker-compose.local.yml up -d
```

### Verificar se está respondendo
```powershell
Invoke-RestMethod -Uri "http://localhost:3000/api/health/up"
```

---

## Comandos Úteis

### Hot Reload (desenvolvimento)
```bash
# Inicia com hot reload
flutter run -d chrome --dart-define=DEV_MODE=true

# Depois de mudanças no código, pressione 'r' no terminal
```

### Build de Produção
```bash
# Web
flutter build web --dart-define=DEV_MODE=false

# Android
flutter build apk --dart-define=DEV_MODE=false

# iOS
flutter build ios --dart-define=DEV_MODE=false
```

---

## Troubleshooting

### Erro 404 no login
- ✅ Confirmar que `DEV_MODE=true`
- ✅ Backend Rails rodando em `localhost:3000`
- ✅ CORS habilitado no backend (DEV_MODE=true no docker-compose)

### CORS Error
Verificar no backend se `DEV_MODE=true`:
```powershell
docker-compose -f docker-compose.local.yml config | Select-String "DEV_MODE"
```

---

**Última atualização:** 09/01/2026
