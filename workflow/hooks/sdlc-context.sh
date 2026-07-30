#!/usr/bin/env bash
# SessionStart — injeta o estado atual do fluxo SDLC no contexto da sessão.
#
# Sem isso, cada sessão nova começa cega: não sabe em que fase o trabalho está
# nem quais artefatos já existem. Silencioso quando o projeto não usa o fluxo.

set -euo pipefail

project="${CLAUDE_PROJECT_DIR:-$(pwd)}"
sdlc="$project/docs/sdlc"

[ -d "$sdlc" ] || exit 0

phase_line() {
  local dir="$1" label="$2"
  local n
  n=$(find "$sdlc/$dir" -type f -name '*.md' 2>/dev/null | wc -l | tr -d ' ')
  if [ "$n" -gt 0 ]; then
    printf -- '- %s: %s artefato(s)\n' "$label" "$n"
  else
    printf -- '- %s: vazio\n' "$label"
  fi
}

{
  printf 'Fluxo SDLC ativo neste projeto (docs/sdlc/).\n\n'
  phase_line "00-orchestration" "00 orquestração"
  phase_line "01-discovery"     "01 discovery"
  phase_line "02-design"        "02 design"
  phase_line "03-build"         "03 build"
  phase_line "04-quality"       "04 quality"
  phase_line "05-delivery"      "05 delivery"
  phase_line "06-docs"          "06 docs"

  if [ -f "$sdlc/00-orchestration/plan.md" ]; then
    printf '\nPlano de execução: docs/sdlc/00-orchestration/plan.md\n'
  else
    printf '\nSem plano de execução ainda. Use /sdlc "objetivo" para criar um.\n'
  fi

  ledger="$sdlc/00-orchestration/artifact-ledger.tsv"
  if [ -f "$ledger" ] && [ "$(wc -l < "$ledger")" -gt 1 ]; then
    printf 'Últimos artefatos registrados:\n'
    tail -n +2 "$ledger" | tail -n 5 | awk -F'\t' '{printf "  %s  %s  (%s)\n", $1, $3, $2}'
  fi
} > /tmp/sdlc-context.$$ 2>/dev/null || exit 0

context="$(cat /tmp/sdlc-context.$$)"
rm -f /tmp/sdlc-context.$$

if command -v jq >/dev/null 2>&1; then
  jq -n --arg ctx "$context" '{
    hookSpecificOutput: {
      hookEventName: "SessionStart",
      additionalContext: $ctx
    }
  }'
fi

exit 0
