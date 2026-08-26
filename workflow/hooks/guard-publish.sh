#!/usr/bin/env bash
# PreToolUse (Bash) — impede que artefato de planejamento chegue ao repositório.
#
# A regra do time: o repositório recebe **código desenvolvido**. PRD, ADR, plano,
# modelo de ameaças, manifesto, ledger e registro de incidente são material de
# trabalho — vivem no disco, ao lado do código, mas não são publicados.
#
# Por que é hook e não instrução: "não commite os artefatos" é exatamente o tipo
# de regra que sobrevive à primeira sessão e morre na quinta. O agente que acabou
# de escrever um plano tem todo incentivo para versioná-lo, e um `git add -A`
# leva o diretório inteiro junto sem ninguém decidir isso.
#
# Entrada: JSON do Claude Code no stdin (.tool_input.command, .cwd)
# Saída:   permissionDecision "deny" quando o comando publicaria planejamento.
#          Silêncio (exit 0) quando permitido.
#
# Escape: crie <projeto>/.claude/allow-planning-in-repo para desligar no projeto.

set -uo pipefail

if ! command -v jq >/dev/null 2>&1; then
  # Sem jq não há como inspecionar a entrada; falha aberta para não travar a sessão.
  exit 0
fi

input="$(cat)"
cmd="$(printf '%s' "$input" | jq -r '.tool_input.command // ""')"
[ -z "$cmd" ] && exit 0

# Só comandos git publicam. Qualquer outra coisa passa direto.
printf '%s' "$cmd" | grep -qE '(^|[;&|[:space:]])git([[:space:]]|$)' || exit 0

# ---------------------------------------------------------------------------
# Onde o git vai agir. `git -C <dir>` vence o cwd da sessão, porque é comum
# operar num repositório membro a partir da raiz de um workspace.
# ---------------------------------------------------------------------------
repo="$(printf '%s' "$cmd" | grep -oE '\-C[[:space:]]+[^[:space:];&|]+' | head -1 | sed -E 's/^-C[[:space:]]+//')"
if [ -z "$repo" ]; then
  repo="$(printf '%s' "$input" | jq -r '.cwd // ""')"
fi
[ -z "$repo" ] && repo="${CLAUDE_PROJECT_DIR:-.}"
[ -d "$repo" ] || exit 0

git -C "$repo" rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0
toplevel="$(git -C "$repo" rev-parse --show-toplevel 2>/dev/null)" || exit 0

# Desligado explicitamente neste projeto? Respeita e sai.
for base in "$toplevel" "${CLAUDE_PROJECT_DIR:-}"; do
  [ -n "$base" ] && [ -f "$base/.claude/allow-planning-in-repo" ] && exit 0
done

# Caminhos considerados planejamento. Relativos à raiz do repositório.
PLANNING_PATHS=(docs/sdlc docs/incidents)

audit() {  # audit <motivo>
  local project="${CLAUDE_PROJECT_DIR:-$toplevel}"
  local log="$project/.claude/logs/guard.tsv"
  mkdir -p "$(dirname "$log")" 2>/dev/null || return 0
  [ -f "$log" ] || printf 'timestamp\tdecisao\tagente\tcaminho\tmotivo\n' > "$log"
  printf '%s\t%s\t%s\t%s\t%s\n' \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "deny" "guard-publish" "$toplevel" "$1" >> "$log"
}

deny() {  # deny <o que foi detectado> <arquivos>
  local reason
  reason="$(printf '%s\n\nArquivos de planejamento envolvidos:\n%s\n\n%s' \
    "$1" \
    "$2" \
    'Regra deste fluxo: o repositório recebe apenas código desenvolvido. Plano, PRD, ADR, modelo de ameaças, MANIFEST, ledger e registro de incidente ficam no disco e não são publicados.

Como seguir:
  · tirar do índice:  git restore --staged <caminho>
  · ignorar de vez:   acrescente docs/sdlc/ ao .gitignore do repositório
  · já commitado:     git reset --soft HEAD~1 e refaça o commit só com o código
  · exceção neste projeto: crie .claude/allow-planning-in-repo')"

  audit "$1"
  jq -n --arg reason "$reason" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: $reason
    }
  }'
  exit 0
}

# git_planning <subcomando de listagem...> — nomes de arquivo de planejamento, ou vazio
git_planning() {
  git -C "$toplevel" "$@" -- "${PLANNING_PATHS[@]}" 2>/dev/null | grep -v '^$' | sort -u
}

# ---------------------------------------------------------------------------
# 1. O comando nomeia um caminho de planejamento explicitamente.
#    Pega `git add docs/sdlc/...` mesmo antes de qualquer coisa estar no índice.
# ---------------------------------------------------------------------------
if printf '%s' "$cmd" | grep -qE '(^|[[:space:]])git[[:space:]]+([^;&|]*[[:space:]])?(add|commit|push|stage)([[:space:]]|$)'; then
  named="$(printf '%s' "$cmd" | grep -oE '[^[:space:]"'"'"';&|]*docs/(sdlc|incidents)[^[:space:]"'"'"';&|]*' | sort -u)"
  if [ -n "$named" ]; then
    deny "O comando nomeia diretamente artefato de planejamento." "$named"
  fi
fi

# ---------------------------------------------------------------------------
# 2. git add abrangente — `.`, `-A`, `--all`, `-u`, ou um diretório que contém
#    os artefatos. São as formas que arrastam o diretório inteiro sem ninguém
#    decidir isso. Um `git add src/Foo.java` com planejamento sujo ao lado NÃO
#    é bloqueado: guarda que dá falso positivo é guarda que alguém desliga.
# ---------------------------------------------------------------------------
if printf '%s' "$cmd" | grep -qE '(^|[[:space:]])git[[:space:]]+(-C[[:space:]]+[^[:space:]]+[[:space:]]+)?add([[:space:]]|$)'; then
  # Argumentos do `git add` até o próximo separador de comando.
  add_args="$(printf '%s' "$cmd" \
    | sed -nE 's/.*(^|[[:space:]])git[[:space:]]+(-C[[:space:]]+[^[:space:]]+[[:space:]]+)?add[[:space:]]+([^;&|]*).*/\3/p')"

  broad=0
  for tok in $add_args; do
    case "$tok" in
      -A|--all|-u|--update|.|./|'*'|:/) broad=1 ;;
      -*) ;;  # demais flags não ampliam o alcance
      *)
        # Um diretório que é prefixo de algum caminho de planejamento também é amplo.
        for p in "${PLANNING_PATHS[@]}"; do
          case "$p/" in "${tok%/}/"*) broad=1 ;; esac
        done
        ;;
    esac
  done

  if [ "$broad" = 1 ]; then
    pending="$( { git_planning diff --name-only; \
                  git_planning ls-files --others --exclude-standard; } | sort -u )"
    if [ -n "$pending" ]; then
      deny "Este 'git add' abrangente colocaria artefato de planejamento no índice." "$pending"
    fi
  fi
fi

# ---------------------------------------------------------------------------
# 3. git commit — o que já está no índice, mais o que -a arrastaria.
# ---------------------------------------------------------------------------
if printf '%s' "$cmd" | grep -qE '(^|[[:space:]])git[[:space:]]+(-C[[:space:]]+[^[:space:]]+[[:space:]]+)?commit([[:space:]]|$)'; then
  # `--diff-filter=d` EXCLUI deleções. Sem isso o hook barra o commit que
  # REMOVE um artefato do índice — que é exatamente a correção que a própria
  # mensagem de negação recomenda ("acrescente docs/sdlc/ ao .gitignore").
  # O guarda ficava impedindo a única saída que ele mesmo oferece.
  staged="$(git_planning diff --cached --name-only --diff-filter=d)"
  if [ -n "$staged" ]; then
    deny "Há artefato de planejamento no índice — este commit o levaria junto." "$staged"
  fi

  # -a isolado ou dentro de um agrupamento curto (-am, -avm). `--amend` e `-m`
  # não casam: o `[a-zA-Z]*` depois do traço único não atravessa o segundo traço.
  if printf '%s' "$cmd" | grep -qE '[[:space:]](-[a-zA-Z]*a[a-zA-Z]*|--all)([[:space:]]|$)'; then
    tracked="$(git_planning diff --name-only)"
    if [ -n "$tracked" ]; then
      deny "'git commit -a' arrastaria artefato de planejamento já versionado." "$tracked"
    fi
  fi
fi

# ---------------------------------------------------------------------------
# 4. git push — o que ainda não está em nenhum remoto. Cobre o caso em que o
#    planejamento entrou no histórico antes deste hook existir.
# ---------------------------------------------------------------------------
if printf '%s' "$cmd" | grep -qE '(^|[[:space:]])git[[:space:]]+(-C[[:space:]]+[^[:space:]]+[[:space:]]+)?push([[:space:]]|$)'; then
  # Sem nenhuma ref remota (repositório recém-criado, nunca publicado), o
  # histórico inteiro é inédito. Com refs remotas, o inédito é o que não está
  # em nenhuma delas — cobre também a branch nova que nunca foi publicada.
  if [ -n "$(git -C "$toplevel" for-each-ref --count=1 refs/remotes 2>/dev/null)" ]; then
    range=(HEAD --not --remotes)
  else
    range=(HEAD)
  fi

  unpushed="$(git -C "$toplevel" log --name-only --pretty=format: "${range[@]}" \
                -- "${PLANNING_PATHS[@]}" 2>/dev/null | grep -v '^$' | sort -u)"
  if [ -n "$unpushed" ]; then
    deny "Há commit não publicado que altera artefato de planejamento." "$unpushed"
  fi
fi

exit 0
