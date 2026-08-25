#!/usr/bin/env bash
# Teste do hook guard-publish.sh — monta repositórios git descartáveis e verifica
# cada decisão. Roda em segundos e não depende de sessão do Claude Code.
#
#   bash workflow/tests/guard-publish.test.sh
#
# Exit 0 se todas as decisões batem; 1 na primeira divergência contada.
#
# O que este teste protege: os falsos positivos. Guarda que bloqueia trabalho
# legítimo é guarda que alguém desliga no primeiro dia ruim — por isso metade
# dos casos aqui espera ALLOW.

set -uo pipefail

HOOK="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/hooks/guard-publish.sh"
[ -f "$HOOK" ] || { echo "hook não encontrado: $HOOK" >&2; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "jq ausente — o hook falha em modo aberto e o teste não vale" >&2; exit 1; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

fails=0
T=""

chk() {  # chk <ALLOW|DENY> <rótulo> <comando>
  local out got
  out="$(jq -n --arg c "$3" --arg d "$T" '{tool_input:{command:$c},cwd:$d}' | bash "$HOOK")"
  got=ALLOW
  printf '%s' "$out" | grep -q '"deny"' && got=DENY
  if [ "$got" = "$1" ]; then
    printf '  ok    %-5s %s\n' "$got" "$2"
  else
    printf '  FALHA esperado=%s obtido=%s — %s\n' "$1" "$got" "$2"
    fails=$((fails + 1))
  fi
}

new_repo() {  # new_repo <nome> — repositório com código e planejamento não versionados
  T="$TMP/$1"
  mkdir -p "$T"
  git init -q "$T"
  git -C "$T" config user.email t@t
  git -C "$T" config user.name t
  mkdir -p "$T/src" "$T/docs/sdlc/00-orchestration"
  echo 'class Foo {}' > "$T/src/Foo.java"
  echo '# plano'     > "$T/docs/sdlc/00-orchestration/plan.md"
}

echo "1. git add — o abrangente barra, o específico passa"
new_repo add
chk DENY  "git add ."                         "git add ."
chk DENY  "git add -A"                        "git add -A"
chk DENY  "git add docs"                      "git add docs"
chk DENY  "git add do caminho do artefato"    "git add docs/sdlc/00-orchestration/plan.md"
chk ALLOW "git add de arquivo de código"      "git add src/Foo.java"
chk ALLOW "git status"                        "git status"
chk ALLOW "comando que não é git"             "npm test"

# Sem nada de planejamento pendente, o add abrangente é inofensivo e passa.
git -C "$T" add -f docs/sdlc/00-orchestration/plan.md
git -C "$T" commit -q -m "plano já versionado"
chk ALLOW "git add . sem planejamento pendente" "git add ."

echo "2. git commit"
new_repo commit
git -C "$T" add src/Foo.java
chk ALLOW "commit com só código no índice"    'git commit -m "feat: foo"'
git -C "$T" add -f docs/sdlc/00-orchestration/plan.md
chk DENY  "commit com planejamento no índice" 'git commit -m "feat: foo"'

echo "3. commit -a sobre planejamento já versionado"
git -C "$T" commit -q -m base
echo v2 > "$T/docs/sdlc/00-orchestration/plan.md"
echo 'class Bar {}' > "$T/src/Bar.java"
chk DENY  "git commit -am"                    'git commit -am "chore: bar"'
chk ALLOW "git commit --amend (não é -a)"     'git commit --amend --no-edit'
chk ALLOW "git commit -m com índice vazio"    'git commit -m "chore"'

echo "4. git push"
new_repo push
chk ALLOW "push sem commit nenhum (nada a publicar)" "git push origin HEAD"
git -C "$T" add -f src/Foo.java docs/sdlc/00-orchestration/plan.md
git -C "$T" commit -q -m "base com plano"
chk DENY  "push de histórico inédito com planejamento" "git push origin HEAD"

R="$TMP/remote.git"
git init -q --bare "$R"
git -C "$T" remote add origin "$R"
git -C "$T" push -q origin HEAD:refs/heads/master
git -C "$T" fetch -q origin
chk ALLOW "push sem nada inédito"             "git push origin HEAD"
echo 'class Bar {}' > "$T/src/Bar.java"
git -C "$T" add src/Bar.java
git -C "$T" commit -q -m "feat: bar"
chk ALLOW "push com só código inédito"        "git push origin HEAD"
echo v3 > "$T/docs/sdlc/00-orchestration/plan.md"
git -C "$T" add -f docs/sdlc/00-orchestration/plan.md
git -C "$T" commit -q -m "docs: plano"
chk DENY  "push com planejamento inédito"     "git push origin HEAD"

echo "5. escape por projeto"
new_repo escape
mkdir -p "$T/.claude"
touch "$T/.claude/allow-planning-in-repo"
chk ALLOW "git add . com allow-planning-in-repo" "git add ."
rm "$T/.claude/allow-planning-in-repo"
chk DENY  "git add . sem o arquivo de escape"    "git add ."

echo "6. git -C aponta para outro repositório"
new_repo alvo
outside="$TMP/fora"
mkdir -p "$outside"
chk DENY  "git -C <repo> add . rodando de fora"  "git -C $T add ."

echo
if [ "$fails" -eq 0 ]; then
  echo "guard-publish: todas as decisões conferem"
else
  echo "guard-publish: $fails divergência(s)"
fi
exit $(( fails > 0 ? 1 : 0 ))
