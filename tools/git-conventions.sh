#!/usr/bin/env bash
# Como esta equipe usa git: formato de commit, nomenclatura de branch, e se
# merge request é o caminho para a branch de integração.
#
# É o ÚNICO tipo de conclusão que se tira do git com honestidade. Layout de
# repositório — um repo ou dezessete — é história e conveniência de time, não
# desenho de sistema: nada aqui infere arquitetura, fronteira de serviço ou
# unidade de deploy. Isso se descobre lendo o código.
#
# Num workspace percorre os membros e mostra onde a convenção diverge, que é
# justamente o que um contribuidor novo erra.
#
# Somente leitura. Sem rede.
#
#   tools/git-conventions.sh [diretorio] [n-commits]     padrão: 200 commits
#   tools/git-conventions.sh --resumo [diretorio]        4 linhas, para o toolbelt
#
# O modo --resumo existe porque o .claude/toolbelt.md é carregado em TODA
# invocação de agente: o relatório completo ali seria abuso de contexto.

set -uo pipefail

RESUMO=0
[ "${1:-}" = "--resumo" ] && { RESUMO=1; shift; }

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=/dev/null
[ -r "$SELF_DIR/_workspace.sh" ] && . "$SELF_DIR/_workspace.sh"

ROOT="${1:-${CLAUDE_PROJECT_DIR:-$(pwd)}}"
N="${2:-200}"
cd "$ROOT" 2>/dev/null || { echo "diretório inacessível: $ROOT" >&2; exit 1; }
ROOT="$(pwd)"

# ------------------------------------------------------------------ por repo

# subjects <dir> — assuntos de commit, sem os merges automáticos.
subjects() { git -C "$1" log -n "$N" --no-merges --format='%s' 2>/dev/null; }

conv_report() {  # conv_report <dir> <rotulo>
  local d="$1" label="$2" s total conv lower upper types tickets

  s="$(subjects "$d")"
  total="$(printf '%s' "$s" | grep -c . || true)"
  [ "${total:-0}" -eq 0 ] && { printf '  %-38s (sem commits)\n' "$label"; return; }

  # Conventional Commits: tipo(escopo opcional)(!): descrição
  conv="$(printf '%s\n' "$s" | grep -cE '^[a-zA-Z]+(\([^)]+\))?!?: ' || true)"
  lower="$(printf '%s\n' "$s" | grep -cE '^[a-z]+(\([^)]+\))?!?: ' || true)"
  upper=$((conv - lower))

  types="$(printf '%s\n' "$s" | sed -nE 's/^([a-zA-Z]+)(\([^)]+\))?!?: .*/\1/p' \
           | tr 'A-Z' 'a-z' | sort | uniq -c | sort -rn | head -6 \
           | awk '{printf "%s(%s) ", $2, $1}')"

  # Chave de ticket no assunto: ABC-123
  tickets="$(printf '%s\n' "$s" | grep -cE '[A-Z]{2,}-[0-9]+' || true)"

  printf '  %-38s %s/%s convencionais' "$label" "$conv" "$total"
  [ "$upper" -gt 0 ] && printf ' · %s com caixa alta' "$upper"
  [ "$tickets" -gt 0 ] && printf ' · %s com ticket' "$tickets"
  printf '\n'
  [ -n "$types" ] && printf '  %-38s tipos: %s\n' "" "$types"
}

branch_report() {  # branch_report <dir> <rotulo>
  local d="$1" label="$2" prefixes integ tickets

  prefixes="$(git -C "$d" for-each-ref --format='%(refname:short)' refs/heads refs/remotes 2>/dev/null \
              | sed 's|^origin/||' | grep '/' | sed -E 's|^([^/]+)/.*|\1|' \
              | sort | uniq -c | sort -rn | head -5 | awk '{printf "%s(%s) ", $2, $1}')"

  tickets="$(git -C "$d" for-each-ref --format='%(refname:short)' refs/heads refs/remotes 2>/dev/null \
             | grep -cE '[A-Za-z]{2,}-[0-9]+' || true)"

  # Branch de integração: o alvo real dos merges, não o que a doc diz.
  integ="$(git -C "$d" log -n "$N" --merges --format='%s' 2>/dev/null \
           | sed -nE "s/.*into '([^']+)'.*/\1/p" | sort | uniq -c | sort -rn | head -2 \
           | awk '{printf "%s(%s) ", $2, $1}')"
  [ -z "$integ" ] && integ="$(git -C "$d" rev-parse --abbrev-ref HEAD 2>/dev/null) (HEAD; sem merge no histórico)"

  printf '  %-38s integra em: %s\n' "$label" "$integ"
  [ -n "$prefixes" ] && printf '  %-38s prefixos: %s\n' "" "$prefixes"
  [ "$tickets" -gt 0 ] && printf '  %-38s %s branch(es) com chave de ticket\n' "" "$tickets"
}

mr_report() {  # mr_report <dir> <rotulo>
  local d="$1" label="$2" merges direct
  merges="$(git -C "$d" log -n "$N" --merges --format='%s' 2>/dev/null | grep -c "into '" || true)"
  direct="$(git -C "$d" log -n "$N" --no-merges --format='%s' 2>/dev/null | grep -c . || true)"
  if [ "${merges:-0}" -gt 0 ]; then
    printf '  %-38s %s merge(s) no formato de MR/PR — o caminho é por merge request\n' "$label" "$merges"
  else
    printf '  %-38s nenhum merge no formato de MR/PR nos últimos %s commits\n' "$label" "$N"
    printf '  %-38s (%s commits diretos — confirme com o time se MR é obrigatório)\n' "" "$direct"
  fi
}

# ------------------------------------------------------------------ resumo

# Agrega os números de um ou mais repositórios em poucas linhas.
resumo() {  # resumo <dir>...
  local d s tot=0 conv=0 low=0 tick=0 repos=0 mrs=0
  local prefixes="" integs=""

  for d in "$@"; do
    repos=$((repos + 1))
    s="$(subjects "$d")"
    tot=$((tot + $(printf '%s\n' "$s" | grep -c . || true)))
    conv=$((conv + $(printf '%s\n' "$s" | grep -cE '^[a-zA-Z]+(\([^)]+\))?!?: ' || true)))
    low=$((low + $(printf '%s\n' "$s" | grep -cE '^[a-z]+(\([^)]+\))?!?: ' || true)))
    tick=$((tick + $(printf '%s\n' "$s" | grep -cE '[A-Z]{2,}-[0-9]+' || true)))
    [ "$(git -C "$d" log -n "$N" --merges --format='%s' 2>/dev/null | grep -c "into '" || true)" -gt 0 ] \
      && mrs=$((mrs + 1))
    prefixes="$prefixes$(git -C "$d" for-each-ref --format='%(refname:short)' refs/heads refs/remotes 2>/dev/null \
                | sed 's|^origin/||' | grep '/' | sed -E 's|^([^/]+)/.*|\1|')"$'\n'
    integs="$integs$(git -C "$d" log -n "$N" --merges --format='%s' 2>/dev/null \
              | sed -nE "s/.*into '([^']+)'.*/\1/p")"$'\n'
  done

  [ "$tot" -eq 0 ] && { echo "- Sem histórico de commits para inferir convenção."; return; }

  local pct=$(( conv * 100 / tot )) upper=$(( conv - low ))
  printf -- '- **Commit**: %s%% seguem Conventional Commits (%s de %s analisados)' "$pct" "$conv" "$tot"
  [ "$upper" -gt 0 ] && printf ', mas %s usam caixa alta (`Fix:` em vez de `fix:`)' "$upper"
  printf '.\n'
  if [ "$tick" -eq 1 ]; then
    printf -- '- **Ticket** aparece no assunto de 1 commit (formato `ABC-123`).\n'
  elif [ "$tick" -gt 1 ]; then
    printf -- '- **Ticket** aparece no assunto de %s commits (formato `ABC-123`).\n' "$tick"
  fi

  local top_pref top_integ
  top_pref="$(printf '%s' "$prefixes" | grep -v '^$' | sort | uniq -c | sort -rn | head -4 \
              | awk '{printf "`%s/`(%s) ", $2, $1}')"
  [ -n "$top_pref" ] && printf -- '- **Branch**: prefixos em uso — %s\n' "$top_pref"

  top_integ="$(printf '%s' "$integs" | grep -v '^$' | sort | uniq -c | sort -rn | head -3 \
               | awk '{printf "`%s`(%s) ", $2, $1}')"
  [ -n "$top_integ" ] && printf -- '- **Integração**: os merges vão para %s\n' "$top_integ"

  if [ "$repos" -gt 1 ] && [ "$mrs" -eq "$repos" ]; then
    printf -- '- **MR**: todos os %s repositórios usam merge request.\n' "$repos"
  elif [ "$repos" -gt 1 ]; then
    printf -- '- **MR**: %s de %s repositórios usam merge request; nos outros os commits vão direto.\n' "$mrs" "$repos"
  elif [ "$mrs" -eq 1 ]; then
    printf -- '- **MR**: o caminho para a branch de integração é por merge request.\n'
  else
    printf -- '- **MR**: nenhum merge de MR no histórico recente — confirme se é obrigatório.\n'
  fi

  printf -- '- Detalhe por repositório: `tools/git-conventions.sh`. **Não** conclua arquitetura\n'
  printf -- '  daqui: isto descreve como o time versiona, não como o sistema é desenhado.\n'
}

# ------------------------------------------------------------------ despacho

MEMBERS=""
declare -F ws_members >/dev/null && MEMBERS="$(ws_members "$ROOT")"

if [ "$RESUMO" -eq 1 ]; then
  if [ -n "$MEMBERS" ]; then
    dirs=(); while IFS= read -r m; do dirs+=("$ROOT/$m"); done <<< "$MEMBERS"
    resumo "${dirs[@]}"
  elif git -C "$ROOT" rev-parse --git-dir >/dev/null 2>&1; then
    resumo "$ROOT"
  else
    echo "- Sem git: não há convenção de commit, branch ou MR a detectar."
  fi
  exit 0
fi

if [ -n "$MEMBERS" ]; then
  total="$(printf '%s\n' "$MEMBERS" | wc -l | tr -d ' ')"
  echo "=== CONVENÇÃO DE GIT — $total repositórios, últimos $N commits de cada ==="
  echo
  echo "--- FORMATO DE COMMIT ---"
  while IFS= read -r m; do conv_report "$ROOT/$m" "$m"; done <<< "$MEMBERS"
  echo
  echo "--- BRANCH ---"
  while IFS= read -r m; do branch_report "$ROOT/$m" "$m"; done <<< "$MEMBERS"
  echo
  echo "--- MERGE REQUEST ---"
  while IFS= read -r m; do mr_report "$ROOT/$m" "$m"; done <<< "$MEMBERS"
  echo
  echo "NOTA: divergência entre repositórios acima é fato, não defeito — pode ser"
  echo "história ou times diferentes. Pergunte antes de padronizar."
  exit 0
fi

git -C "$ROOT" rev-parse --git-dir >/dev/null 2>&1 || { echo "não é um repositório git"; exit 0; }

echo "=== CONVENÇÃO DE GIT — últimos $N commits ==="
echo
echo "--- FORMATO DE COMMIT ---"; conv_report "$ROOT" "$(basename "$ROOT")"
echo
echo "--- BRANCH ---";            branch_report "$ROOT" "$(basename "$ROOT")"
echo
echo "--- MERGE REQUEST ---";     mr_report "$ROOT" "$(basename "$ROOT")"
exit 0
