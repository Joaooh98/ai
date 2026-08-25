#!/usr/bin/env bash
# Funções compartilhadas pelos scripts de secrets/. Carregado com `source`, por
# isso o prefixo `_` — mesma convenção do tools/_workspace.sh.
#
# Falamos com o Vault pela API HTTP, com curl e jq, em vez do CLI `vault`.
# Motivo: o CLI não está instalado nesta máquina, e o wrapper roda a cada boot de
# servidor MCP — depender de mais um binário, ou de `docker exec`, é latência e
# um ponto de falha a mais no caminho quente.

VAULT_ADDR="${VAULT_ADDR:-http://127.0.0.1:8200}"
TOKEN_FILE="${AI_SECRETS_TOKEN_FILE:-$HOME/.config/ai-secrets/token}"
PASS_ENTRY="${AI_SECRETS_PASS_ENTRY:-ai/vault/init}"
KV_MOUNT="${AI_SECRETS_KV_MOUNT:-secret}"

precisa() {
  command -v "$1" >/dev/null 2>&1 && return 0
  printf 'falta a dependência: %s\n' "$1" >&2
  [ -n "${2:-}" ] && printf '  %s\n' "$2" >&2
  exit 1
}

# Chamada à API. Nunca ecoa corpo de resposta — quem chama decide o que fazer
# com ele, e nenhum caminho de erro daqui imprime segredo.
api() {
  local metodo="$1" caminho="$2" corpo="${3:-}" token="${4:-}"
  local args=(-fsS -m 15 -X "$metodo" "$VAULT_ADDR$caminho")
  [ -n "$token" ] && args+=(-H "X-Vault-Token: $token")
  [ -n "$corpo" ] && args+=(-H 'Content-Type: application/json' -d "$corpo")
  curl "${args[@]}" 2>/dev/null
}

vault_de_pe() {
  curl -fsS -m 3 "$VAULT_ADDR/v1/sys/seal-status" >/dev/null 2>&1
}

vault_selado() {
  local s
  s="$(curl -fsS -m 3 "$VAULT_ADDR/v1/sys/seal-status" 2>/dev/null | jq -r '.sealed // "erro"')"
  [ "$s" = "true" ]
}

vault_inicializado() {
  local i
  i="$(curl -fsS -m 3 "$VAULT_ADDR/v1/sys/init" 2>/dev/null | jq -r '.initialized // "erro"')"
  [ "$i" = "true" ]
}

exigir_vault_de_pe() {
  vault_de_pe && return 0
  cat >&2 <<EOF
o Vault não responde em $VAULT_ADDR.

  1. o Docker Desktop está rodando?   docker info
  2. o container subiu?               docker compose -f secrets/compose.yml ps
  3. subir:                           docker compose -f secrets/compose.yml up -d
EOF
  exit 1
}

# Token de acesso ao vault, lido do arquivo. É o arquivo que o
# `permissions.deny` protege — é ele que impede o agente de falar com o vault,
# muito mais do que as regras de Bash.
ler_token() {
  [ -f "$TOKEN_FILE" ] || {
    printf 'token ausente em %s — rode secrets/vault-unseal\n' "$TOKEN_FILE" >&2
    exit 1
  }
  local perm
  perm="$(stat -c '%a' "$TOKEN_FILE" 2>/dev/null || echo '')"
  if [ -n "$perm" ] && [ "$perm" != "600" ]; then
    printf 'aviso: %s está com permissão %s; corrigindo para 600\n' "$TOKEN_FILE" "$perm" >&2
    chmod 600 "$TOKEN_FILE" 2>/dev/null
  fi
  cat "$TOKEN_FILE"
}

gravar_token() {
  local t="$1"
  mkdir -p "$(dirname "$TOKEN_FILE")" 2>/dev/null
  chmod 700 "$(dirname "$TOKEN_FILE")" 2>/dev/null
  # Cria com permissão restrita ANTES de escrever: um instante com o arquivo
  # legível por todos já é um instante em que o token vazou.
  ( umask 077; printf '%s' "$t" > "$TOKEN_FILE" )
  chmod 600 "$TOKEN_FILE" 2>/dev/null
}
