#!/usr/bin/env bash
# Descobre como subir este projeto num ambiente controlado, e o que já está de pé.
#
# Somente leitura: NÃO sobe, NÃO derruba, NÃO altera nada. Só relata o que existe,
# para a skill verify-live decidir.
#
#   tools/preview-env.sh [diretorio]

set -uo pipefail
P="${1:-${CLAUDE_PROJECT_DIR:-$(pwd)}}"
cd "$P" 2>/dev/null || exit 0

has() { command -v "$1" >/dev/null 2>&1; }

echo "### Ambiente controlado disponível"
echo

found=0

# --------------------------------------------------------------- compose
compose="$(ls docker-compose.yml docker-compose.yaml compose.yml compose.yaml 2>/dev/null | head -1)"
if [ -n "$compose" ]; then
  found=1
  echo "**Compose: \`$compose\`** — preferido (isolado e descartável)"
  if has docker; then
    echo '```'
    echo "docker compose up -d      # subir"
    echo "docker compose ps         # conferir"
    echo "docker compose logs -f    # acompanhar"
    echo "docker compose down -v    # DERRUBAR e limpar volumes"
    echo '```'
    grep -E '^\s{2,}[a-zA-Z0-9_-]+:' "$compose" 2>/dev/null | head -8 | sed 's/^/  serviço:/'
  else
    echo "  ⚠ \`docker\` não está instalado — compose não pode ser usado aqui."
  fi
  echo
fi

# ------------------------------------------------------------ dev server
if [ -f package.json ] && has jq; then
  starts="$(jq -r '.scripts // {} | to_entries[] | select(.key|test("^(dev|start|serve|preview)$")) | "\(.key): \(.value)"' package.json 2>/dev/null)"
  if [ -n "$starts" ]; then
    found=1
    pm="npm"; [ -f pnpm-lock.yaml ] && pm="pnpm"; [ -f yarn.lock ] && pm="yarn"; [ -f bun.lockb ] && pm="bun"
    echo "**Dev server** (compartilha estado com a sua máquina)"
    printf '%s\n' "$starts" | sed "s/^/  $pm run /"
    echo
  fi
fi

for f in manage.py app.py main.py; do
  [ -f "$f" ] && { found=1; echo "**Python**: possível entrada \`$f\` — confirme o comando real com o usuário"; echo; break; }
done

[ -f pom.xml ] && { found=1; echo "**Maven**: \`mvn spring-boot:run\` (confirme o plugin no pom.xml)"; echo; }

# ----------------------------------------------------------- já de pé?
echo "**Já em execução**"
if has docker; then
  running="$(docker compose ps --format '{{.Service}} {{.Status}}' 2>/dev/null | head -8)"
  if [ -n "$running" ]; then
    printf '%s\n' "$running" | sed 's/^/  /'
    echo "  ⚠ Já há serviço de pé. Reaproveite em vez de subir outro, ou derrube antes."
  else
    echo "  nenhum serviço compose ativo"
  fi
else
  echo "  (docker ausente — não dá para checar)"
fi

# ------------------------------------------------------ dados de teste
echo
echo "**Dados de teste**"
seeds=0
for d in seeds seed fixtures factories testdata; do
  [ -d "$d" ] && { echo "  diretório: $d"; seeds=1; }
done
find . -maxdepth 2 -iname '*seed*' -not -path './node_modules/*' -not -path './.git/*' 2>/dev/null | head -3 | sed 's/^/  arquivo: /'
[ "$seeds" -eq 0 ] && echo "  nenhum seed detectado — crie o mínimo e registre o que criou"

# -------------------------------------------------------------- browser
echo
echo "**Verificação de navegador**"
bfound=0
for c in playwright.config.ts playwright.config.js cypress.config.ts cypress.config.js; do
  [ -f "$c" ] && { echo "  no projeto: $c"; bfound=1; }
done
[ -d node_modules/@playwright ] && { echo "  Playwright instalado em node_modules"; bfound=1; }
[ "$bfound" -eq 0 ] && echo "  nada no projeto — procure um MCP de navegador na sessão com ToolSearch"

if [ "$found" -eq 0 ]; then
  echo
  echo "⚠ NENHUMA forma de subir a aplicação foi detectada. Confirme com o usuário como se"
  echo "  executa este projeto e registre a resposta em .claude/toolbelt.md — sem isso,"
  echo "  nenhuma mudança visível pode ser verificada de verdade."
fi
exit 0
