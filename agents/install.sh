#!/usr/bin/env bash
# Instala a equipe (agentes + skills + hooks) no Claude Code.
#
#   ./agents/install.sh              -> escopo projeto (.claude/)
#   ./agents/install.sh --user       -> escopo usuário (~/.claude/) — sem hooks
#   ./agents/install.sh --check      -> apenas valida, não instala
#   ./agents/install.sh --no-hooks   -> instala agentes e skills, pula os hooks
#
# As fontes ficam versionadas em agents/, skills/ e workflow/hooks/. O instalador
# só cria links simbólicos: editar a fonte reflete no Claude Code sem reinstalar.

set -euo pipefail

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SRC_DIR/.." && pwd)"
SKILL_DIR="$REPO_ROOT/skills"
HOOK_DIR="$REPO_ROOT/workflow/hooks"
MODE="project"
CHECK_ONLY=0
WITH_HOOKS=1

for arg in "$@"; do
  case "$arg" in
    --user)     MODE="user" ;;
    --check)    CHECK_ONLY=1 ;;
    --no-hooks) WITH_HOOKS=0 ;;
    -h|--help)
      sed -n '2,12p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
      exit 0 ;;
    *)
      echo "opção desconhecida: $arg" >&2
      exit 2 ;;
  esac
done

errors=0
fail() { echo "ERRO  $1" >&2; errors=$((errors + 1)); }

frontmatter() { awk 'NR>1 && /^---$/{exit} NR>1{print}' "$1"; }

# ------------------------------------------------------------ validar agentes
agent_count=0
declare -A seen_agents

while IFS= read -r -d '' file; do
  agent_count=$((agent_count + 1))
  rel="${file#"$REPO_ROOT"/}"

  if [ "$(head -n 1 "$file")" != "---" ]; then
    fail "$rel: não começa com frontmatter '---'"
    continue
  fi

  front="$(frontmatter "$file")"
  name="$(printf '%s\n' "$front"  | sed -n 's/^name:[[:space:]]*//p'  | head -n 1)"
  desc="$(printf '%s\n' "$front"  | sed -n 's/^description:[[:space:]]*//p' | head -n 1)"
  model="$(printf '%s\n' "$front" | sed -n 's/^model:[[:space:]]*//p' | head -n 1)"

  if [ -z "$name" ]; then
    fail "$rel: campo obrigatório 'name' ausente"
  elif ! printf '%s' "$name" | grep -Eq '^[a-z0-9]+(-[a-z0-9]+)*$'; then
    fail "$rel: 'name' deve ser kebab-case minúsculo (encontrado: $name)"
  elif [ -n "${seen_agents[$name]:-}" ]; then
    fail "$rel: 'name' duplicado '$name' (já usado em ${seen_agents[$name]})"
  else
    seen_agents[$name]="$rel"
  fi

  [ -z "$desc" ] && fail "$rel: campo obrigatório 'description' ausente"

  if [ -n "$model" ] && ! printf '%s' "$model" | grep -Eq '^(opus|sonnet|haiku|fable|inherit|claude-[a-z0-9.-]+)$'; then
    fail "$rel: 'model' inválido: $model"
  fi
done < <(find "$SRC_DIR" -name '*.md' ! -name 'README.md' -print0 | sort -z)

# ------------------------------------------------------------- validar skills
# Uma skill é qualquer diretório que contenha SKILL.md, em qualquer profundidade.
# O nome do diretório vira o nome do comando, então precisa ser único.
skill_count=0
declare -A seen_skills
declare -a skill_dirs=()

while IFS= read -r -d '' sk; do
  d="$(dirname "$sk")"
  skill_count=$((skill_count + 1))
  skill_dirs+=("$d")
  rel="${sk#"$REPO_ROOT"/}"
  base="$(basename "$d")"

  if [ -n "${seen_skills[$base]:-}" ]; then
    fail "$rel: nome de skill duplicado '$base' (já usado em ${seen_skills[$base]})"
  else
    seen_skills[$base]="$rel"
  fi

  if [ "$(head -n 1 "$sk")" != "---" ]; then
    fail "$rel: skill sem frontmatter '---'"
    continue
  fi
  front="$(frontmatter "$sk")"
  printf '%s\n' "$front" | grep -q '^description:' || fail "$rel: skill sem 'description'"

  # A doc recomenda manter SKILL.md abaixo de 500 linhas e mover referência para
  # arquivos de apoio — o conteúdo inteiro entra no contexto quando a skill ativa.
  lines="$(wc -l < "$sk" | tr -d ' ')"
  [ "$lines" -gt 500 ] && fail "$rel: $lines linhas (máx. 500 — mova referência para arquivo de apoio)"

  # Toda injeção !`comando` precisa casar com algum padrão de allowed-tools.
  # Sem isto a skill falha em runtime pedindo aprovação, e o erro só aparece no
  # primeiro uso real — longe de quem escreveu. O caso clássico é o padrão
  # `.../x.sh *`, que exige argumento, contra uma chamada sem nenhum.
  allowed="$(printf '%s\n' "$front" | sed -n 's/^allowed-tools:[[:space:]]*//p')"
  if [ -n "$allowed" ]; then
    declare -a pats=()
    while IFS= read -r p; do pats+=("$p"); done \
      < <(printf '%s\n' "$allowed" | grep -oE 'Bash\([^)]*\)' | sed -E 's/^Bash\(//; s/\)$//')
    while IFS= read -r call; do
      cmd="${call#\!\`}"; cmd="${cmd%\`}"
      matched=0
      for pat in ${pats[@]+"${pats[@]}"}; do
        # shellcheck disable=SC2053  — glob proposital: o padrão é um glob
        [[ "$cmd" == $pat ]] && { matched=1; break; }
      done
      [ "$matched" -eq 0 ] && \
        fail "$rel: a injeção \`$cmd\` não casa com nenhum padrão de allowed-tools"
    done < <(grep -oE '!`[^`]+`' "$sk" 2>/dev/null || true)
  fi
done < <(find "$SKILL_DIR" -name 'SKILL.md' -print0 2>/dev/null | sort -z)

# Scripts empacotados em skills rodam na injeção `!`comando``, antes do conteúdo
# chegar ao agente. Erro de sintaxe aqui quebra a skill inteira.
while IFS= read -r -d '' s; do
  bash -n "$s" 2>/dev/null || fail "${s#"$REPO_ROOT"/}: erro de sintaxe no script da skill"
  [ -x "$s" ] || chmod +x "$s"
done < <(find "$SKILL_DIR" -name '*.sh' -print0 2>/dev/null | sort -z)

# Referências 'skills:' no frontmatter dos agentes precisam resolver.
while IFS= read -r ref; do
  [ -z "$ref" ] && continue
  [ -n "${seen_skills[$ref]:-}" ] || fail "agente referencia skill inexistente: '$ref'"
done < <(find "$SRC_DIR" -name '*.md' ! -name 'README.md' -exec grep -h '^skills:' {} + 2>/dev/null \
         | sed 's/^skills:[[:space:]]*//' | tr ',' '\n' | tr -d ' ' | sort -u)

# -------------------------------------------------------------- validar hooks
hook_count=0
if [ -d "$HOOK_DIR" ]; then
  while IFS= read -r -d '' file; do
    hook_count=$((hook_count + 1))
    bash -n "$file" 2>/dev/null || fail "${file#"$REPO_ROOT"/}: erro de sintaxe no hook"
  done < <(find "$HOOK_DIR" -name '*.sh' -print0 | sort -z)
fi

# --------------------------------------------------- validar tools e o launcher
# Os agentes chamam tools/ a cada onda, e o operador chama workspace/go todo dia.
# Erro de sintaxe aqui só apareceria em uso, longe de quem escreveu.
tool_count=0
while IFS= read -r -d '' f; do
  # `_nome.sh` é helper carregado com source, não um tool que agente chama —
  # validado igual, mas fora da contagem que a documentação afirma.
  case "$(basename "$f")" in _*) ;; *) tool_count=$((tool_count + 1)) ;; esac
  bash -n "$f" 2>/dev/null || fail "${f#"$REPO_ROOT"/}: erro de sintaxe"
  [ -x "$f" ] || chmod +x "$f"
done < <(find "$REPO_ROOT/tools" -name '*.sh' -print0 2>/dev/null | sort -z)

if [ -f "$REPO_ROOT/workspace/go" ]; then
  bash -n "$REPO_ROOT/workspace/go" 2>/dev/null || fail "workspace/go: erro de sintaxe"
  [ -x "$REPO_ROOT/workspace/go" ] || chmod +x "$REPO_ROOT/workspace/go"
fi

if [ "$errors" -gt 0 ]; then
  echo "" >&2
  echo "validação falhou: $errors erro(s)" >&2
  exit 1
fi

echo "validação ok: $agent_count agentes, $skill_count skills, $hook_count hooks, $tool_count tools"
[ "$CHECK_ONLY" -eq 1 ] && exit 0

# ---------------------------------------------------------------- instalação
if [ "$MODE" = "user" ]; then BASE="$HOME/.claude"; else BASE="$REPO_ROOT/.claude"; fi

link() {  # link <origem> <destino>  — preserva o que não for symlink
  local src="$1" target="$2"
  if [ -L "$target" ]; then rm "$target"
  elif [ -e "$target" ]; then
    echo "PULADO  $target existe e não é link simbólico — preservado" >&2
    return 1
  fi
  ln -s "$src" "$target"
}

mkdir -p "$BASE/agents" "$BASE/skills"

# Âncora do toolkit. Skills e hooks referenciam scripts por
# ${CLAUDE_PROJECT_DIR}/.claude/ai-toolkit/... — um único caminho que resolve
# tanto aqui quanto em qualquer projeto alvo fiado por workspace/go. Sem isto,
# só funcionaria no repo onde o toolkit está fisicamente.
mkdir -p "$REPO_ROOT/.claude"
ln -sfn "$REPO_ROOT" "$REPO_ROOT/.claude/ai-toolkit"
echo "toolkit: âncora em .claude/ai-toolkit -> $REPO_ROOT"

a=0
while IFS= read -r f; do link "$f" "$BASE/agents/$(basename "$f")" && a=$((a + 1))
done < <(find "$SRC_DIR" -name '*.md' ! -name 'README.md' | sort)
echo "agentes: $a link(s) em $BASE/agents"

s=0
for d in "${skill_dirs[@]}"; do link "$d" "$BASE/skills/$(basename "$d")" && s=$((s + 1)); done
echo "skills:  $s link(s) em $BASE/skills"

# --------------------------------------------------------------------- hooks
if [ "$WITH_HOOKS" -eq 1 ]; then
  if [ "$MODE" = "user" ]; then
    echo "hooks: pulados em --user (usam \${CLAUDE_PROJECT_DIR}, relativo ao projeto)"
  else
    chmod +x "$HOOK_DIR"/*.sh 2>/dev/null || true
    SETTINGS="$BASE/settings.json"
    SNIPPET="$REPO_ROOT/workflow/settings.hooks.json"

    if [ ! -f "$SETTINGS" ]; then
      mkdir -p "$BASE"; cp "$SNIPPET" "$SETTINGS"
      echo "hooks: $SETTINGS criado"
    elif command -v jq >/dev/null 2>&1; then
      if diff -q <(jq -S '.hooks' "$SETTINGS" 2>/dev/null) <(jq -S '.hooks' "$SNIPPET") >/dev/null 2>&1; then
        echo "hooks: $SETTINGS já está atualizado"
      elif jq -e '.hooks' "$SETTINGS" >/dev/null 2>&1; then
        echo "hooks: $SETTINGS define 'hooks' DIFERENTE do esperado — não foi alterado."
        echo "       Compare com workflow/settings.hooks.json e mescle à mão."
      else
        tmp="$(mktemp)"; jq -s '.[0] * .[1]' "$SETTINGS" "$SNIPPET" > "$tmp" && mv "$tmp" "$SETTINGS"
        echo "hooks: mesclados em $SETTINGS"
      fi
    else
      echo "hooks: jq ausente e $SETTINGS já existe — mescle à mão"
    fi

    command -v jq >/dev/null 2>&1 || {
      echo "AVISO  jq não instalado: os hooks falham em modo aberto (não bloqueiam)."
      echo "       sudo apt install jq"; }
  fi
fi

echo
echo "Reinicie o Claude Code se $BASE/agents ou $BASE/skills não existiam antes desta sessão."
echo
if [ -f "$REPO_ROOT/.claude/toolbelt.md" ]; then
  echo "PRÓXIMO PASSO  .claude/toolbelt.md existe. Rode /setup de novo se a stack mudou."
else
  echo "╭──────────────────────────────────────────────────────────────────────────╮"
  echo "│  PRÓXIMO PASSO:  rode  /setup                                            │"
  echo "│                                                                          │"
  echo "│  Instalar cria os links. Calibrar é o que faz a equipe acertar:          │"
  echo "│  detecta a stack, VERIFICA que os comandos funcionam de verdade, e grava │"
  echo "│  o contexto que todo agente passa a carregar.                            │"
  echo "│                                                                          │"
  echo "│  Sem isso, 27 agentes chegam sabendo o método e nada sobre o SEU projeto.│"
  echo "╰──────────────────────────────────────────────────────────────────────────╯"
fi
