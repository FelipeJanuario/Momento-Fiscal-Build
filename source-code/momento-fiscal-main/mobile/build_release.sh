#!/bin/bash
set -e

PUBSPEC="pubspec.yaml"

# Lê a versão atual: formato X.Y.Z+N
CURRENT=$(grep '^version:' "$PUBSPEC" | sed 's/version: //')
VERSION_NAME=$(echo "$CURRENT" | cut -d'+' -f1)   # X.Y.Z
VERSION_CODE=$(echo "$CURRENT" | cut -d'+' -f2)   # N

# Incrementa patch (Z) e versionCode (N)
MAJOR=$(echo "$VERSION_NAME" | cut -d'.' -f1)
MINOR=$(echo "$VERSION_NAME" | cut -d'.' -f2)
PATCH=$(echo "$VERSION_NAME" | cut -d'.' -f3)

NEW_PATCH=$((PATCH + 1))
NEW_CODE=$((VERSION_CODE + 1))

NEW_VERSION="${MAJOR}.${MINOR}.${NEW_PATCH}+${NEW_CODE}"

# Atualiza pubspec.yaml
sed -i '' "s/^version: .*/version: ${NEW_VERSION}/" "$PUBSPEC"

echo "✅ Versão atualizada: $CURRENT → $NEW_VERSION"
echo "🔨 Gerando .aab..."

# Executa o build
flutter build appbundle --release
