#!/usr/bin/env bash
# Gera os quatro diagramas a partir dos .json ao lado.
#
#   docs/gerar.sh            gera os quatro
#   docs/gerar.sh porque     gera um só
#
# Os .html NÃO são versionados: são saída, e cada um embute o runtime do
# archify inteiro — CSS, JS e o botão de tema. Versionar os quatro colocava
# 2162 linhas duplicadas no repositório, medidas pelo SonarCloud, e voltava a
# colocar a cada regeração. A fonte é o .json; o .html se refaz em segundos.
#
# Requer a skill `archify` instalada em ~/.claude/skills/archify.

set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")" || exit 2

ARCHIFY="${ARCHIFY:-$HOME/.claude/skills/archify}"
BIN="$ARCHIFY/bin/archify.mjs"

if [ ! -f "$BIN" ]; then
  echo "archify não encontrado em $ARCHIFY" >&2
  echo "Instale a skill, ou aponte com: ARCHIFY=/caminho docs/gerar.sh" >&2
  exit 2
fi

# nome:tipo — o tipo decide o renderer.
DIAGRAMAS="porque:workflow fluxo:workflow sdlc:workflow arquitetura:architecture"

alvo="${1:-}"
falhas=0

for d in $DIAGRAMAS; do
  nome="${d%%:*}"; tipo="${d##*:}"
  [ -n "$alvo" ] && [ "$alvo" != "$nome" ] && continue

  # arquitetura usa .architecture.json; os workflows usam .workflow.json
  src="$nome.$tipo.json"
  [ -f "$src" ] || { echo "FONTE AUSENTE  $src" >&2; falhas=$((falhas + 1)); continue; }

  if node "$BIN" render "$tipo" "$src" "$nome.html" >/dev/null 2>&1; then
    printf 'ok   %-14s -> %s\n' "$src" "$nome.html"
  else
    printf 'FALHA %-13s — rode para ver o erro:\n      node %s render %s %s %s.html\n' \
           "$src" "$BIN" "$tipo" "$src" "$nome" >&2
    falhas=$((falhas + 1))
  fi
done

if [ "$falhas" -gt 0 ]; then
  echo >&2
  echo "$falhas diagrama(s) não gerado(s). O renderer FALHA em vez de emitir" >&2
  echo "diagrama ruim: a mensagem traz a correção com coordenada." >&2
  exit 1
fi

exit 0
