#!/usr/bin/env bash
# Inventário factual do repositório, para o project-analyst e qualquer agente que
# precise das convenções antes de escrever a primeira linha.
#
# Só lê. Não instala, não builda, não acessa a rede.
#
#   tools/repo-facts.sh [diretorio]
#
# Num workspace (raiz sem git, com repositórios embaixo) abre com o mapa do
# sistema — quem são os membros, stack, remote e atividade — e segue com os fatos
# da raiz. Num repositório comum, comportamento de sempre.

set -uo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=/dev/null
[ -r "$SELF_DIR/_workspace.sh" ] && . "$SELF_DIR/_workspace.sh"

ROOT="${1:-$(pwd)}"
cd "$ROOT" || exit 1
ROOT="$(pwd)"

hr() { printf '\n=== %s ===\n' "$1"; }
show() { [ -f "$1" ] && printf -- '- %s\n' "$1"; }

# --------------------------------------------------------------- mapa do sistema
MEMBERS=""
declare -F ws_members >/dev/null && MEMBERS="$(ws_members "$ROOT")"

if [ -n "$MEMBERS" ]; then
  total="$(printf '%s\n' "$MEMBERS" | wc -l | tr -d ' ')"
  hr "WORKSPACE — $total REPOSITÓRIOS"
  echo "A raiz NÃO é repositório git. Inventário do que existe embaixo:"
  echo
  printf '  %-38s %-12s %-14s %s\n' "MEMBRO" "STACK" "ATIVIDADE" "REMOTE"
  while IFS= read -r m; do
    printf '  %-38s %-12s %-14s %s\n' \
      "$m" \
      "$(ws_stack "$ROOT/$m")" \
      "$(git -C "$ROOT/$m" log -1 --format='%cr' 2>/dev/null || echo '-')" \
      "$(git -C "$ROOT/$m" remote get-url origin 2>/dev/null || echo '(sem remote)')"
  done <<< "$MEMBERS"
  echo
  echo "  Perfil completo de um repositório:  tools/repo-facts.sh $ROOT/<membro>"
  echo "  Convenção de commit, branch e MR:   tools/git-conventions.sh"
  echo
  echo "  LIMITE DESTA DETECÇÃO: a tabela acima é layout de repositório, e layout"
  echo "  não é arquitetura. Estar separado em dezessete repositórios ou junto em"
  echo "  um só é história e conveniência de time — não implica fronteira de"
  echo "  serviço, unidade de deploy nem dependência entre módulos."
  echo "  Quem chama quem, e por qual contrato, se descobre lendo o código."
fi

hr "MANIFESTS"
for m in package.json pom.xml build.gradle build.gradle.kts requirements.txt pyproject.toml \
         go.mod Cargo.toml Gemfile composer.json pubspec.yaml deno.json; do
  show "$m"
done
find . -maxdepth 3 -name '*.csproj' -not -path './node_modules/*' 2>/dev/null | sed 's/^/- /'

hr "VERSOES DECLARADAS"
[ -f package.json ] && grep -E '"(name|version|engines|packageManager)"' package.json | head -6
[ -f pom.xml ] && grep -oE '<(java\.version|maven\.compiler\.release|version)>[^<]+' pom.xml | head -6
[ -f pyproject.toml ] && grep -E '^(name|version|requires-python)' pyproject.toml | head -4
[ -f go.mod ] && head -3 go.mod
[ -f Cargo.toml ] && grep -E '^(name|version|edition)' Cargo.toml | head -4

hr "COMANDOS DECLARADOS (nao executados)"
if [ -f package.json ] && command -v jq >/dev/null 2>&1; then
  jq -r '.scripts // {} | to_entries[] | "  npm run \(.key)  ->  \(.value)"' package.json 2>/dev/null | head -20
fi
[ -f Makefile ] && grep -E '^[a-zA-Z_-]+:' Makefile | head -15 | sed 's/^/  make /'
[ -f justfile ] && grep -E '^[a-zA-Z_-]+:' justfile | head -15 | sed 's/^/  just /'

hr "TESTES"
for d in test tests src/test spec __tests__ e2e; do
  [ -d "$d" ] && printf -- '- diretorio: %s (%s arquivos)\n' "$d" "$(find "$d" -type f | wc -l | tr -d ' ')"
done
for c in pytest.ini jest.config.js jest.config.ts vitest.config.ts phpunit.xml karma.conf.js; do
  show "$c"
done

hr "QUALIDADE E CONVENCOES"
for c in .editorconfig .eslintrc .eslintrc.json eslint.config.js .prettierrc .prettierrc.json \
         ruff.toml .flake8 checkstyle.xml .rubocop.yml .commitlintrc.json; do
  show "$c"
done

hr "ENTREGA"
[ -d .github/workflows ] && find .github/workflows -type f | sed 's/^/- /'
for c in .gitlab-ci.yml Jenkinsfile Dockerfile docker-compose.yml compose.yaml; do
  show "$c"
done
find . -maxdepth 2 -type d \( -name terraform -o -name infra -o -name helm -o -name k8s \) \
  -not -path './node_modules/*' 2>/dev/null | sed 's/^/- /'

hr "MIGRACOES"
find . -maxdepth 4 -type d \( -name migrations -o -name migration -o -name flyway \) \
  -not -path './node_modules/*' 2>/dev/null | head -5 | sed 's/^/- /'

hr "GIT"
git rev-parse --abbrev-ref HEAD 2>/dev/null | sed 's/^/branch: /'
git log --oneline -5 2>/dev/null | sed 's/^/  /'
printf 'alteracoes pendentes: %s\n' "$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')"

hr "TAMANHO"
printf 'arquivos versionados: %s\n' "$(git ls-files 2>/dev/null | wc -l | tr -d ' ')"

printf '\nNOTA: tudo acima foi lido de arquivos. Nada foi executado nem inferido.\n'
