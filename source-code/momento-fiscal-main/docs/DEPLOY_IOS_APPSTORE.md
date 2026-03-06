# Deploy iOS – App Store via GitHub Actions

Este documento descreve todo o processo para publicar o app Momento Fiscal na App Store
utilizando o pipeline de CI/CD configurado no GitHub Actions.

---

## Visão Geral

O pipeline é disparado automaticamente ao criar uma **tag Git** com o formato correto:

| Tag | Destino |
|---|---|
| `v1.2.3-rc1` | **TestFlight** (homologação) |
| `v1.2.3` | **App Store** (revisão da Apple) |

---

## Pré-requisitos (feitos uma única vez)

Os itens abaixo já estão configurados. Consulte esta seção apenas se precisar recriar
algum recurso (ex: certificado expirado, novo membro da equipe etc.).

### 1. Certificado Apple Distribution (.p12)

Gerado a partir do Keychain Access + Apple Developer Portal.

**Como recriar (se o certificado expirar):**

1. Abra o **Keychain Access** no Mac
2. Menu **Acesso Chaves → Assistente de Certificado → Solicitar um Certificado de uma Autoridade Certificadora...**
3. Preencha o e-mail (Apple ID), marque **"Salvo no disco"** → salve o `.certSigningRequest`
4. Acesse [developer.apple.com/account/resources/certificates](https://developer.apple.com/account/resources/certificates)
5. Clique em **+** → selecione **Apple Distribution** → faça upload do `.certSigningRequest`
6. Baixe o `.cer` gerado e dê duplo clique para instalar no Keychain
7. No **Keychain Access → Meus Certificados**, clique com botão direito no certificado
   **Apple Distribution** → **Exportar** → formato `.p12` → defina uma senha forte
8. Converta para base64 e atualize o secret no GitHub:
   ```bash
   base64 -i ~/Desktop/Certificados.p12 | pbcopy
   ```
9. Atualize os secrets `APPLE_CERTIFICATE_BASE64` e `APPLE_CERTIFICATE_PASSWORD` no GitHub

> **Atenção:** Certificados Apple Distribution têm validade de **1 ano**.

---

### 2. Provisioning Profile

Vincula o App ID `br.com.momentofiscal` ao certificado de distribuição.

**Como recriar:**

1. Acesse [developer.apple.com/account/resources/profiles](https://developer.apple.com/account/resources/profiles)
2. Clique em **+** → **App Store Connect** (em Distribution)
3. Selecione o App ID `br.com.momentofiscal` → **Continue**
4. Selecione o certificado **Apple Distribution** → **Continue**
5. Nome do perfil: `Momento Fiscal` → **Generate** → **Download**
6. Converta e atualize o secret no GitHub:
   ```bash
   base64 -i ~/Downloads/Momento_Fiscal.mobileprovision | pbcopy
   ```
7. Atualize o secret `APPLE_PROVISIONING_PROFILE_BASE64` no GitHub

> O nome do perfil deve bater exatamente com o valor em `mobile/ios/ExportOptions.plist`.

---

### 3. App Store Connect API Key

Permite que o Fastlane faça upload sem precisar de usuário/senha com 2FA.

**Como recriar:**

1. Acesse [appstoreconnect.apple.com](https://appstoreconnect.apple.com) → **Usuários e Acesso → Integrações → App Store Connect API**
2. Clique em **+** → Nome: `GitHub Actions CI` → Acesso: `Gerenciador de App`
3. Anote o **Key ID** e o **Issuer ID** (fica no topo da página)
4. Baixe o arquivo `AuthKey_XXXXXXXX.p8` (disponível **apenas uma vez**)
5. Converta e atualize os secrets no GitHub:
   ```bash
   base64 -i ~/Downloads/AuthKey_XXXXXXXX.p8 | pbcopy
   ```
6. Atualize os três secrets: `APP_STORE_CONNECT_API_KEY_ID`, `APP_STORE_CONNECT_API_KEY_ISSUER_ID` e `APP_STORE_CONNECT_API_KEY_CONTENT`

---

### 4. Secrets no GitHub

Localização: **github.com/taiderapro/momento-fiscal → Settings → Secrets and variables → Actions**

| Secret | Descrição |
|---|---|
| `APPLE_CERTIFICATE_BASE64` | Certificado `.p12` em base64 |
| `APPLE_CERTIFICATE_PASSWORD` | Senha do `.p12` |
| `KEYCHAIN_PASSWORD` | Senha do keychain temporário do CI (qualquer UUID) |
| `APPLE_PROVISIONING_PROFILE_BASE64` | Provisioning Profile em base64 |
| `APP_STORE_CONNECT_API_KEY_ID` | Key ID da API Key |
| `APP_STORE_CONNECT_API_KEY_ISSUER_ID` | Issuer ID da API Key |
| `APP_STORE_CONNECT_API_KEY_CONTENT` | Arquivo `.p8` em base64 |

---

## Publicando uma nova versão

### Passo 1 — Atualizar a versão no pubspec.yaml

Abra `mobile/pubspec.yaml` e atualize a versão:

```yaml
# Formato: versão+build  (o build number deve ser incrementado a cada envio)
version: 1.2.3+10
```

> O número após o `+` é o **build number** — deve ser maior que o último enviado ao TestFlight/App Store.

---

### Passo 2 — Commitar as alterações

```bash
cd source-code/momento-fiscal-main

git add .
git commit -m "chore: bump version para 1.2.3"
git push origin main
```

---

### Passo 3 — Criar a tag e disparar o pipeline

**Para TestFlight** (recomendado antes de ir para produção):
```bash
git tag v1.2.3-rc1
git push origin v1.2.3-rc1
```

**Para App Store** (quando validado no TestFlight):
```bash
git tag v1.2.3
git push origin v1.2.3
```

---

### Passo 4 — Acompanhar o pipeline

1. Acesse [github.com/taiderapro/momento-fiscal/actions](https://github.com/taiderapro/momento-fiscal/actions)
2. Clique no workflow **"iOS – Publicar na App Store"**
3. Acompanhe cada etapa. O pipeline executa:
   - Instala Flutter e dependências
   - Roda os testes
   - Importa o certificado e o provisioning profile
   - Executa `flutter build ipa`
   - Faz upload via Fastlane para TestFlight ou App Store Connect

> Tempo estimado: **30–45 minutos** (o runner macOS do GitHub é mais lento).

---

### Passo 5 — Validar no TestFlight / submeter para revisão

**TestFlight:**
1. Acesse [appstoreconnect.apple.com](https://appstoreconnect.apple.com) → **Meus Apps → Momento Fiscal → TestFlight**
2. O build aparecerá em processamento (pode levar até 30 min após o upload)
3. Adicione testadores e distribua

**App Store:**
1. O build já é submetido automaticamente para revisão pelo Fastlane
2. Acompanhe o status em **App Store Connect → Momento Fiscal → Distribuição**

---

## Estrutura dos arquivos do CI

```
mobile/
├── Gemfile                        # Dependência do Fastlane
├── Gemfile.lock                   # Versões travadas (commitar sempre)
└── ios/
    ├── ExportOptions.plist        # Config de assinatura para flutter build ipa
    └── fastlane/
        ├── Appfile                # Bundle ID e Team ID
        └── Fastfile               # Lanes: testflight e appstore

.github/
└── workflows/
    └── ios-appstore.yml           # Pipeline principal do GitHub Actions
```

---

## Solução de problemas comuns

### Build falha em "Importar certificado"
- Verifique se o secret `APPLE_CERTIFICATE_BASE64` está correto (sem quebras de linha extras)
- Confirme se a senha em `APPLE_CERTIFICATE_PASSWORD` é a mesma usada ao exportar o `.p12`

### Erro "No profiles for br.com.momentofiscal were found"
- O Provisioning Profile pode ter expirado (validade de 1 ano)
- Recrie seguindo a seção **Provisioning Profile** acima

### Erro "Invalid API Key" no upload
- A API Key pode ter sido revogada. Recrie seguindo a seção **App Store Connect API Key**
- Confirme que o conteúdo do `.p8` foi convertido corretamente para base64

### Erro no ExportOptions.plist
- O nome do perfil em `mobile/ios/ExportOptions.plist` deve ser idêntico ao cadastrado na Apple Developer Portal
- Para verificar o nome exato do perfil:
  ```bash
  security cms -D -i ~/Downloads/Momento_Fiscal.mobileprovision 2>/dev/null | plutil -extract Name xml1 - -o - | sed -n 's/.*<string>\(.*\)<\/string>.*/\1/p'
  ```
