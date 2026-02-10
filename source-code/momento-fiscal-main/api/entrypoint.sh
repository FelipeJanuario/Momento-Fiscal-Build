#!/bin/bash
set -e

# Function to put secrets on environment variables
# If the direct ENV var exists, use it. Otherwise read from file.
function put_secret_on_env {
  local secret_name=$1
  local secret_file=$2
  
  # Se a variável já existe, não sobrescrever
  if [ -n "${!secret_name}" ]; then
    echo "Using existing ${secret_name} from environment"
    return
  fi
  
  # Se o arquivo existe, ler dele
  if [ -n "$secret_file" ] && [ -f "$secret_file" ]; then
    local secret_value=$(cat "$secret_file")
    export ${secret_name}="${secret_value}"
    echo "Loaded ${secret_name} from ${secret_file}"
  fi
}

# Put secrets on environment variables
put_secret_on_env SECRET_KEY_BASE                              ${SECRET_KEY_BASE_FILE:-}
put_secret_on_env DATABASE_PASSWORD                            ${DATABASE_PASSWORD_FILE:-}
put_secret_on_env MAIL_SMTP_PASSWORD                           ${MAIL_SMTP_PASSWORD_FILE:-}
put_secret_on_env LOCKBOX_MASTER_KEY                           ${LOCKBOX_MASTER_KEY_FILE:-}
put_secret_on_env ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY         ${ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY_FILE:-}
put_secret_on_env ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY   ${ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY_FILE:-}
put_secret_on_env ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT ${ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT_FILE:-}
put_secret_on_env BIDDINGS_ANALYSER_API_KEY                    ${BIDDINGS_ANALYSER_API_KEY_FILE:-}
put_secret_on_env STRIPE_SECRET_KEY                            ${STRIPE_SECRET_KEY_FILE:-}
put_secret_on_env PJE_AUTH_PFX                                 ${PJE_AUTH_PFX_FILE:-}
put_secret_on_env PJE_AUTH_PFX_PASSWORD                        ${PJE_AUTH_PFX_PASSWORD_FILE:-}
put_secret_on_env PJE_AUTH_CERTCHAIN                           ${PJE_AUTH_CERTCHAIN_FILE:-}
put_secret_on_env GOOGLE_API_PFX_BASE64                        ${GOOGLE_API_PFX_BASE64_FILE:-}

# Remove a potentially pre-existing server.pid for Rails.
rm -f /app/tmp/pids/*.pid

# If running the rails server then create or migrate existing database
# DISABLED: db:prepare will be run manually after first start
# if [ "${1}" == "./bin/rails" ] && [ "${2}" == "server" ]; then
#   ./bin/rails db:prepare
# fi

# Then exec the container's main process (what's set as CMD in the Dockerfile).
exec "$@"
