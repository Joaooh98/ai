#!/usr/bin/env bash
# Escopo e área de risco de um diff — para code-reviewer, security-auditor e
# release-manager decidirem onde olhar com mais atenção.
#
#   tools/diff-scope.sh [base]     base padrão: main
#
# Num workspace (raiz sem git, com repositórios embaixo) percorre cada membro e
# reporta só os que têm diferença. Num repositório comum, comportamento de sempre.
#
# Só lê. Não altera nada.

set -uo pipefail
BASE="${1:-main}"

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=/dev/null
[ -r "$SELF_DIR/_workspace.sh" ] && . "$SELF_DIR/_workspace.sh"

ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"

# Resolve a base num repositório: nem todo membro usa o mesmo nome de branch.
resolve_base() {
  local d="$1" b
  for b in "$BASE" main master develop; do
    git -C "$d" rev-parse --verify "$b" >/dev/null 2>&1 && { printf '%s' "$b"; return 0; }
  done
  return 1
}

# scope_one <dir> — o relatório de um repositório. Devolve 1 quando não há diff.
scope_one() {
  local d="$1" base range files tests

  base="$(resolve_base "$d")" || {
    printf '  base não encontrada (tentei: %s, main, master, develop)\n' "$BASE"
    return 1
  }
  range="$base...HEAD"
  files="$(git -C "$d" diff --name-only "$range" 2>/dev/null)"
  [ -z "$files" ] && return 1

  printf '=== ESCOPO (%s) ===\n' "$range"
  git -C "$d" diff --stat "$range" | tail -1
  printf '\narquivos: %s\n' "$(printf '%s\n' "$files" | wc -l | tr -d ' ')"

  printf '\n=== ARQUIVOS ===\n'
  git -C "$d" diff --name-status "$range" | sed 's/^/  /'

  printf '\n=== AREAS DE RISCO ===\n'
  flag() {
    local label="$1" pattern="$2" hits
    hits="$(printf '%s\n' "$files" | grep -Ei "$pattern" || true)"
    if [ -n "$hits" ]; then
      printf -- '- %s:\n' "$label"
      printf '%s\n' "$hits" | sed 's/^/    /'
    fi
  }

  flag "AUTENTICACAO / AUTORIZACAO" 'auth|login|session|token|jwt|permission|role|guard|policy'
  flag "MIGRACAO DE BANCO"          'migration|migrate|schema|flyway|liquibase|alembic'
  flag "SEGREDOS / CONFIG"          '\.env|secret|credential|config\.(ya?ml|json|toml)$'
  flag "PIPELINE / INFRA"           '\.github/workflows|gitlab-ci|Dockerfile|compose|terraform|helm|k8s'
  flag "DEPENDENCIAS"               'package(-lock)?\.json|pom\.xml|requirements\.txt|go\.(mod|sum)|Cargo\.(toml|lock)|Gemfile'
  flag "ENTRADA EXTERNA"            'controller|route|handler|endpoint|webhook|upload|parser'

  printf '\n=== TESTES NO DIFF ===\n'
  tests="$(printf '%s\n' "$files" | grep -Ei '(^|/)(test|tests|spec|__tests__)/|\.(test|spec)\.' || true)"
  if [ -n "$tests" ]; then
    printf '%s\n' "$tests" | sed 's/^/  /'
  else
    echo "  NENHUM arquivo de teste no diff — verificar se a mudança deveria ter teste."
  fi

  printf '\n=== COMMITS ===\n'
  git -C "$d" log --oneline "$range" | sed 's/^/  /'
  return 0
}

# ------------------------------------------------------------------- workspace
MEMBERS=""
declare -F ws_members >/dev/null && MEMBERS="$(ws_members "$ROOT")"

if [ -n "$MEMBERS" ]; then
  total="$(printf '%s\n' "$MEMBERS" | wc -l | tr -d ' ')"
  printf '=== WORKSPACE: %s membros, base "%s" ===\n\n' "$total" "$BASE"

  changed=0 skipped=""
  while IFS= read -r m; do
    out="$(scope_one "$ROOT/$m")" || { skipped="$skipped $m"; continue; }
    changed=$((changed + 1))
    printf -- '---------- %s ----------\n' "$m"
    printf '%s\n\n' "$out"
  done <<< "$MEMBERS"

  if [ "$changed" -eq 0 ]; then
    echo "nenhum membro tem diferença contra a base — nada a revisar"
  else
    printf '=== RESUMO ===\n'
    printf '  %s de %s membros com diferença\n' "$changed" "$total"
  fi
  # Membro sem diff é o caso normal e não vira ruído; sem base é sinal de que o
  # nome do branch difere ali, e isso o revisor precisa saber.
  [ -n "$skipped" ] && printf '  sem diferença ou sem base: %s\n' "$skipped"
  exit 0
fi

# ------------------------------------------------------- repositório único
git -C "$ROOT" rev-parse --git-dir >/dev/null 2>&1 || { echo "não é um repositório git"; exit 1; }

if ! resolve_base "$ROOT" >/dev/null; then
  echo "base '$BASE' não existe. Use: tools/diff-scope.sh <branch-ou-commit>"
  exit 1
fi

scope_one "$ROOT" || echo "nenhuma diferença entre $BASE e HEAD"
exit 0
