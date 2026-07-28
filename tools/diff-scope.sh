#!/usr/bin/env bash
# Escopo e área de risco de um diff — para code-reviewer, security-auditor e
# release-manager decidirem onde olhar com mais atenção.
#
#   tools/diff-scope.sh [base]     base padrão: main
#
# Só lê. Não altera nada.

set -uo pipefail
BASE="${1:-main}"

git rev-parse --git-dir >/dev/null 2>&1 || { echo "não é um repositório git"; exit 1; }

if ! git rev-parse --verify "$BASE" >/dev/null 2>&1; then
  echo "base '$BASE' não existe. Use: tools/diff-scope.sh <branch-ou-commit>"
  exit 1
fi

RANGE="$BASE...HEAD"
FILES="$(git diff --name-only "$RANGE" 2>/dev/null)"

if [ -z "$FILES" ]; then
  echo "nenhuma diferença entre $BASE e HEAD"
  exit 0
fi

printf '=== ESCOPO (%s) ===\n' "$RANGE"
git diff --stat "$RANGE" | tail -1
printf '\narquivos: %s\n' "$(printf '%s\n' "$FILES" | wc -l | tr -d ' ')"

printf '\n=== ARQUIVOS ===\n'
git diff --name-status "$RANGE" | sed 's/^/  /'

printf '\n=== AREAS DE RISCO ===\n'
flag() {
  local label="$1" pattern="$2"
  local hits
  hits="$(printf '%s\n' "$FILES" | grep -Ei "$pattern" || true)"
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
TESTS="$(printf '%s\n' "$FILES" | grep -Ei '(^|/)(test|tests|spec|__tests__)/|\.(test|spec)\.' || true)"
if [ -n "$TESTS" ]; then
  printf '%s\n' "$TESTS" | sed 's/^/  /'
else
  echo "  NENHUM arquivo de teste no diff — verificar se a mudança deveria ter teste."
fi

printf '\n=== COMMITS ===\n'
git log --oneline "$RANGE" | sed 's/^/  /'
