#!/usr/bin/env bash
# Calibração: descobre o que este projeto É e o que a equipe PODE fazer nele.
#
# Sai um rascunho de .claude/toolbelt.md na saída padrão. A skill /setup revisa,
# completa com o que só o usuário sabe, e grava.
#
# Somente leitura. Sem rede. Não executa build nem teste — só relata o que
# encontrou declarado, para /setup verificar depois.
#
#   tools/calibrate.sh [diretorio-do-projeto]

set -uo pipefail

# Resolver o próprio caminho antes do `cd`, senão o relativo do source quebra.
SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=/dev/null
[ -r "$SELF_DIR/_workspace.sh" ] && . "$SELF_DIR/_workspace.sh"

P="${1:-${CLAUDE_PROJECT_DIR:-$(pwd)}}"
cd "$P" 2>/dev/null || { echo "diretório inacessível: $P" >&2; exit 1; }
P="$(pwd)"

WS_MEMBERS=""
declare -F ws_members >/dev/null && WS_MEMBERS="$(ws_members "$P")"
WS_COUNT=0
[ -n "$WS_MEMBERS" ] && WS_COUNT="$(printf '%s\n' "$WS_MEMBERS" | wc -l | tr -d ' ')"

has() { command -v "$1" >/dev/null 2>&1; }
first_of() { for f in "$@"; do [ -f "$f" ] && { echo "$f"; return; }; done; }

echo "# Ferramental deste projeto"
echo
echo "<!-- Rascunho gerado por tools/calibrate.sh. Revise: o que a detecção não alcança"
echo "     (VPN, tier de instância, convenção do time, o que NÃO mexer) importa mais"
echo "     que o que ela alcança. Cada linha é carregada em toda invocação de agente. -->"
echo

# ------------------------------------------------------------------ identidade
echo "## O que é este projeto"
echo

MANIFEST="$(first_of package.json pom.xml build.gradle build.gradle.kts pyproject.toml \
  requirements.txt go.mod Cargo.toml composer.json Gemfile pubspec.yaml)"

if [ -z "$MANIFEST" ] && [ -n "$WS_MEMBERS" ]; then
  # Workspace: cada membro é um repositório com stack própria. Chamar isso de
  # "monorepo" e listar três manifests ao acaso esconderia o que importa — que
  # são sistemas independentes, com git e deploy próprios.
  echo "- **Workspace**: a raiz não é repositório git, e há $WS_COUNT repositórios embaixo:"
  while IFS= read -r m; do
    printf -- '  - `%s` (%s)\n' "$m" "$(ws_stack "$P/$m")"
  done <<< "$WS_MEMBERS"
  echo "  Cada um tem histórico e dependências próprios: use \`git -C <membro>\`, porque"
  echo "  a raiz não responde a comando git, e \`tools/repo-facts.sh <membro>\` antes de"
  echo "  tocar em qualquer um."
  echo
  echo "  **Isto é layout, não arquitetura.** Estar em dezessete repositórios ou em um"
  echo "  só é história e conveniência de time. Não conclua daqui fronteira de serviço,"
  echo "  unidade de deploy nem contrato entre módulos — isso se descobre lendo o"
  echo "  código, e é trabalho do project-analyst, não desta detecção."
elif [ -z "$MANIFEST" ]; then
  sub="$(find . -maxdepth 3 -name 'package.json' -o -maxdepth 3 -name 'pom.xml' \
        -o -maxdepth 3 -name 'pyproject.toml' 2>/dev/null | grep -v node_modules | head -3)"
  if [ -n "$sub" ]; then
    echo "- **Monorepo ou multi-módulo**: sem manifest na raiz, mas há em subdiretórios:"
    printf '%s\n' "$sub" | sed 's|^\./|  - |'
    echo "  Rode \`tools/repo-facts.sh <subdir>\` antes de trabalhar em cada um."
  else
    echo "- Sem manifest de dependência detectado. Se não é projeto de código, diga aqui o que é."
  fi
else
  echo "- Manifest principal: \`$MANIFEST\`"
  case "$MANIFEST" in
    package.json)
      if has jq; then
        pm="npm"
        [ -f pnpm-lock.yaml ] && pm="pnpm"; [ -f yarn.lock ] && pm="yarn"; [ -f bun.lockb ] && pm="bun"
        echo "- Gerenciador de pacotes: \`$pm\` (pelo lockfile)"
        jq -r '.scripts // {} | to_entries[] | "- script: `'"$pm"' run \(.key)` → \(.value)"' \
          package.json 2>/dev/null | head -8
      fi ;;
    pom.xml)          echo "- Build: \`mvn\`" ;;
    build.gradle*)    echo "- Build: \`gradle\` ou \`./gradlew\`" ;;
    pyproject.toml|requirements.txt)
      echo "- Python. **Verifique se há venv por módulo** antes de instalar qualquer coisa." ;;
    go.mod)           echo "- Build: \`go build ./...\` · testes: \`go test ./...\`" ;;
    Cargo.toml)       echo "- Build: \`cargo build\` · testes: \`cargo test\`" ;;
  esac
fi

# ------------------------------------------------------------------- qualidade
qa=""
for c in .eslintrc .eslintrc.json eslint.config.js .prettierrc ruff.toml .flake8 \
         checkstyle.xml .rubocop.yml .editorconfig; do
  [ -f "$c" ] && qa="$qa \`$c\`"
done
[ -n "$qa" ] && echo "- Qualidade configurada:$qa — obrigatório, não sugestão."

# ---------------------------------------------------------------------- testes
echo
echo "## Testes"
echo
tdir=""
for d in test tests src/test spec __tests__ e2e cypress; do
  [ -d "$d" ] && tdir="$tdir \`$d\`"
done
if [ -n "$tdir" ]; then
  echo "- Diretórios:$tdir"
else
  echo "- **Nenhum diretório de teste detectado.** Confirme antes que um agente afirme que"
  echo "  \"a suíte passa\" — pode não haver suíte."
fi
for c in jest.config.js jest.config.ts vitest.config.ts playwright.config.ts \
         cypress.config.ts pytest.ini phpunit.xml; do
  [ -f "$c" ] && echo "- Config: \`$c\`"
done

# ---------------------------------------------------------------- capacidades
echo
echo "## Capacidades disponíveis"
echo

# navegador — o que permite verificar de verdade, e não só rodar teste unitário
browser="não detectado"
[ -f playwright.config.ts ] || [ -f playwright.config.js ] && browser="Playwright no projeto"
[ -d node_modules/@playwright ] && browser="Playwright instalado"
[ -f cypress.config.ts ] || [ -d cypress ] && browser="Cypress no projeto"
echo "- **Navegador (verificação real de UI):** $browser"
echo "  Havendo MCP de navegador na sessão, use-o para confirmar comportamento em vez de"
echo "  deduzir do código. Descubra com \`ToolSearch\`."

for cli in gh glab docker kubectl terraform; do
  has "$cli" && echo "- CLI disponível: \`$cli\`"
done

echo
echo "## Entrega"
echo
found=0
[ -d .github/workflows ] && { echo "- CI: \`.github/workflows/\`"; found=1; }
for c in .gitlab-ci.yml Jenkinsfile Dockerfile docker-compose.yml compose.yaml vercel.json; do
  [ -f "$c" ] && { echo "- \`$c\`"; found=1; }
done
[ "$found" -eq 0 ] && echo "- Nenhum pipeline detectado — deploy pode ser manual. Confirme com o usuário."

# ------------------------------------------------------------ convenção de git
# O histórico do git responde honestamente a UMA pergunta: como este time
# versiona. Formato de commit, nomenclatura de branch e se MR é o caminho.
# Nada além disso — layout de repositório não descreve arquitetura.
echo
echo "## Convenção de git"
echo
if [ -x "$SELF_DIR/git-conventions.sh" ]; then
  "$SELF_DIR/git-conventions.sh" --resumo "$P" 2>/dev/null \
    || echo "- Detecção de convenção falhou; rode \`tools/git-conventions.sh\` à mão."
else
  echo "- \`tools/git-conventions.sh\` não encontrado."
fi

# ------------------------------------------------------------------ a preencher
echo
echo "## A preencher — o que a detecção NÃO alcança"
echo
echo "Estas linhas valem mais que todas as acima. Substitua ou apague."
echo
echo "- [ ] O que **não** pode ser mexido sem aprovação:"
echo "- [ ] Restrições de ambiente (VPN, acesso a banco, credenciais que faltam):"
echo "- [ ] Convenções do time que o linter não pega:"
echo "- [ ] Integrações externas críticas e o que quebra se caírem:"
echo "- [ ] Como verificar de verdade que uma mudança funciona neste projeto:"
exit 0
