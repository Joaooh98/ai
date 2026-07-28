#!/usr/bin/env bash
# PostToolUse (Write|Edit) — registra automaticamente todo artefato do SDLC.
#
# O context-manager mantém o MANIFEST curado; este hook mantém o livro-razão
# bruto, que é a evidência de que o artefato existe e quem o produziu. Nunca
# bloqueia nada — só observa.
#
# Entrada: JSON do Claude Code no stdin
# Saída:   linha TSV em docs/sdlc/00-orchestration/artifact-ledger.tsv

set -euo pipefail

command -v jq >/dev/null 2>&1 || exit 0

input="$(cat)"
path="$(printf '%s' "$input" | jq -r '.tool_input.file_path // ""')"
[ -z "$path" ] && exit 0

# Só interessa o que está sob docs/sdlc/
case "$path" in
  */docs/sdlc/*|docs/sdlc/*) ;;
  *) exit 0 ;;
esac

agent="$(printf '%s' "$input" | jq -r '.agent_type // "main-session"')"
session="$(printf '%s' "$input" | jq -r '.session_id // "-"')"
cwd="$(printf '%s' "$input" | jq -r '.cwd // "."')"
project="${CLAUDE_PROJECT_DIR:-$cwd}"

ledger="$project/docs/sdlc/00-orchestration/artifact-ledger.tsv"
mkdir -p "$(dirname "$ledger")"

if [ ! -f "$ledger" ]; then
  printf 'timestamp\tagent\tpath\tsession\n' > "$ledger"
fi

# Deduplica: uma linha por (agente, caminho). A mais recente vence.
stamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
rel="${path#"$project"/}"

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT
awk -F'\t' -v a="$agent" -v p="$rel" 'NR==1 || !($2==a && $3==p)' "$ledger" > "$tmp"
printf '%s\t%s\t%s\t%s\n' "$stamp" "$agent" "$rel" "$session" >> "$tmp"
mv "$tmp" "$ledger"
trap - EXIT

exit 0
