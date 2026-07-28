#!/usr/bin/env bash
# Estado real do ciclo SDLC, lido do disco. Usado pela skill /sdlc para decidir
# a próxima ação sem depender da memória da conversa.
#
# Somente leitura. Rápido: sem rede, sem health check.
#
#   tools/sdlc-state.sh [diretorio-do-projeto]

set -uo pipefail
ROOT="${1:-${CLAUDE_PROJECT_DIR:-$(pwd)}}"
SDLC="$ROOT/docs/sdlc"

if [ ! -d "$SDLC" ]; then
  echo "ESTADO: nenhum ciclo iniciado (docs/sdlc/ não existe)"
  echo "AÇÃO: bootstrap, se houver objetivo; senão pergunte qual é"
  exit 0
fi

# Conta artefatos com conteúdo real, ignorando esqueleto de template.
substantive() {
  local dir="$1" n=0 f
  [ -d "$dir" ] || { echo 0; return; }
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    local body
    body="$(grep -vE '^\s*$|^#|^\|[-: |]+\|$' "$f" 2>/dev/null | wc -l | tr -d ' ')"
    [ "$body" -ge 10 ] && n=$((n + 1))
  done < <(find "$dir" -type f \( -name '*.md' -o -name '*.yaml' -o -name '*.json' \) 2>/dev/null)
  echo "$n"
}

echo "ESTADO DAS FASES (artefatos com conteúdo real / arquivos presentes)"
last_complete=""
for phase in 00-orchestration 01-discovery 02-design 03-build 04-quality 05-delivery 06-docs; do
  total=$(find "$SDLC/$phase" -type f 2>/dev/null | wc -l | tr -d ' ')
  real=$(substantive "$SDLC/$phase")
  if [ "$real" -gt 0 ]; then
    printf '  %-18s %s real / %s arquivo(s)\n' "$phase" "$real" "$total"
    last_complete="$phase"
  elif [ "$total" -gt 0 ]; then
    printf '  %-18s 0 real / %s arquivo(s)  <-- só esqueleto\n' "$phase" "$total"
  else
    printf '  %-18s vazio\n' "$phase"
  fi
done

echo
echo "PLANO"
if [ -f "$SDLC/00-orchestration/plan.md" ]; then
  echo "  docs/sdlc/00-orchestration/plan.md existe"
  grep -E '^## (Wave|Onda|Gate)' "$SDLC/00-orchestration/plan.md" 2>/dev/null | head -8 | sed 's/^/    /'
else
  echo "  ausente — o bootstrap ainda não rodou"
fi

echo
echo "ÚLTIMOS ARTEFATOS REGISTRADOS"
ledger="$SDLC/00-orchestration/artifact-ledger.tsv"
if [ -f "$ledger" ] && [ "$(wc -l < "$ledger")" -gt 1 ]; then
  tail -n +2 "$ledger" | tail -5 | awk -F'\t' '{printf "  %s  %s  (%s)\n", $1, $3, $2}'
else
  echo "  nenhum"
fi

echo
echo "FASE ATUAL: ${last_complete:-nenhuma}"
echo "Confirme com tools/artifact-lint.sh antes de considerar qualquer portão aprovado."
exit 0
