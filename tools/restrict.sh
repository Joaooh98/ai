#!/usr/bin/env bash
# Escolhe o que o agente NÃO pode ler, e grava a decisão como regra de permissão.
#
#   tools/restrict.sh [diretorio]        interativo: mostra e pergunta
#   tools/restrict.sh --minimo [dir]     só o mínimo, sem perguntar
#   tools/restrict.sh --listar [dir]     mostra o que faria, não grava nada
#
# Escreve em `.claude/settings.local.json` do projeto — o escopo pessoal, que é
# gitignorado. Nunca toca no `.claude/settings.json` versionado, porque decisão
# de restrição é sua e da sua máquina, não do repositório.
#
# Por que regra de permissão e não um hook: `permissions.deny` é imposto pelo
# harness antes da ferramenta rodar, não depende de bash, de jq nem de o script
# não quebrar, e a doc é explícita que `Read(.env)` casa em qualquer profundidade
# (semântica gitignore) e vale também para os comandos de arquivo que o Claude
# Code reconhece no Bash, como `cat`, `head` e `sed`.

set -uo pipefail

MODO="interativo"
case "${1:-}" in
  --minimo)  MODO="minimo";  shift ;;
  --listar)  MODO="listar";  shift ;;
  -h|--help) sed -n '2,17p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
esac

ROOT="${1:-${CLAUDE_PROJECT_DIR:-$(pwd)}}"
cd "$ROOT" 2>/dev/null || { echo "diretório não acessível: $ROOT" >&2; exit 1; }
ROOT="$(pwd)"
SETTINGS="$ROOT/.claude/settings.local.json"

# --------------------------------------------------------------- o mínimo
#
# Estas oito não são negociáveis, e vale saber qual delas sustenta o peso:
#
# `Read(~/.config/ai-secrets/token)` é a que importa de verdade. Sem esse token
# o CLI do vault não autentica — `vault kv get` falha com "missing client token"
# mesmo que o agente consiga rodar o comando. E o wrapper foi desenhado para que
# `VAULT_TOKEN` nunca exista no ambiente da sessão.
#
# As regras `Bash(vault …)` são quebra-molas, não muralha: regra de Bash é
# parseada por subcomando, mas `v=vault; $v kv get` escapa. Elas existem para o
# caso comum e para deixar rastro. Dizer que são infalíveis seria teatro.
MINIMO=(
  "Read(~/.config/ai-secrets/token)"
  "Read(~/.password-store/**)"
  "Read(~/.gnupg/**)"
  "Read(~/.claude/.credentials.json)"
  "Bash(vault kv get*)"
  "Bash(vault read*)"
  "Bash(vault kv list*)"
  "Bash(pass show*)"
)

NOMES_SENSIVEIS='(^|/)\.env($|\.)|(^|/)\.envrc$|\.pem$|\.p12$|\.pfx$|\.jks$|\.keystore$|\.ppk$|(^|/)id_(rsa|dsa|ecdsa|ed25519)|(^|/)\.netrc$|(^|/)\.pgpass$|(^|/)\.git-credentials$|(^|/)\.npmrc$|(^|/)\.pypirc$|credentials?\.(json|ya?ml|ini|toml)$|service[_-]?account.*\.json$|(^|/)kubeconfig$|\.kubeconfig$|terraform\.tfstate|\.tfvars$|secrets?\.(json|ya?ml|env|toml)$'
NOMES_TEMPLATE='\.(example|sample|template|dist|tpl)($|\.)|(^|/)(example|sample|template)\.'
PODA='(^|/)(\.git|node_modules|\.venv|venv|vendor|dist|build|target|\.next|__pycache__)/'

echo "=== O MÍNIMO (sempre aplicado) ==="
for r in "${MINIMO[@]}"; do printf '  %s\n' "$r"; done

# ------------------------------------------------------- candidatos no disco
candidatos=()
while IFS= read -r f; do
  candidatos+=("${f#./}")
done < <(find . -type f 2>/dev/null \
          | grep -vE "$PODA" \
          | grep -E "$NOMES_SENSIVEIS" \
          | grep -vE "$NOMES_TEMPLATE" \
          | sort)

echo
echo "=== CANDIDATOS ENCONTRADOS NESTE PROJETO ==="
if [ ${#candidatos[@]} -eq 0 ]; then
  echo "  nenhum arquivo com nome de credencial no disco."
  echo "  (é o resultado esperado depois de migrar tudo para o vault)"
else
  i=1
  for c in "${candidatos[@]}"; do
    st="no disco"
    git rev-parse --git-dir >/dev/null 2>&1 && {
      git ls-files --error-unmatch -- "$c" >/dev/null 2>&1 && st="RASTREADO no git"
    }
    printf '  %2d) %-50s [%s]\n' "$i" "$c" "$st"
    i=$((i + 1))
  done
fi

escolhidos=()
case "$MODO" in
  listar)
    echo
    echo "Modo --listar: nada foi gravado."
    exit 0 ;;
  minimo)
    echo
    echo "Modo --mínimo: só as regras acima." ;;
  interativo)
    if [ ${#candidatos[@]} -gt 0 ]; then
      echo
      echo "Quais desses o agente NÃO deve conseguir ler?"
      echo "  números separados por espaço (ex: 1 3), 'todos', ou vazio para nenhum"
      printf '> '
      # Lê do terminal para funcionar com a saída redirecionada, mas cai para o
      # stdin quando não há terminal (job em background, CI, pipe). Testar
      # `[ -r /dev/tty ]` não basta: o arquivo existe e tem permissão, e ainda
      # assim a abertura falha sem terminal de controle — e aí a escolha do
      # usuário some em silêncio, que é o pior desfecho possível aqui.
      resposta=""
      if ! read -r resposta < /dev/tty 2>/dev/null; then
        read -r resposta || resposta=""
      fi
      case "${resposta:-}" in
        todos|TODOS|t) escolhidos=("${candidatos[@]}") ;;
        "") ;;
        *)
          for n in $resposta; do
            case "$n" in
              ''|*[!0-9]*) echo "  ignorando '$n': não é número" >&2; continue ;;
            esac
            idx=$((n - 1))
            if [ "$idx" -ge 0 ] && [ "$idx" -lt ${#candidatos[@]} ]; then
              escolhidos+=("${candidatos[$idx]}")
            else
              echo "  ignorando '$n': fora da lista" >&2
            fi
          done ;;
      esac
    fi ;;
esac

# ------------------------------------------------------------------ gravar
regras=("${MINIMO[@]}")
for e in "${escolhidos[@]:-}"; do
  [ -n "$e" ] || continue
  regras+=("Read($e)")
done

echo
if ! command -v jq >/dev/null 2>&1; then
  echo "jq não está instalado — não dá para mesclar o JSON com segurança."
  echo "Cole isto em $SETTINGS, dentro de \"permissions\":"
  echo
  printf '  "deny": [\n'
  for r in "${regras[@]}"; do printf '    "%s",\n' "$r"; done | sed '$ s/,$//'
  printf '  ]\n'
  exit 1
fi

mkdir -p "$(dirname "$SETTINGS")"
[ -f "$SETTINGS" ] || echo '{}' > "$SETTINGS"

# Backup antes de tocar em configuração que não é minha.
cp "$SETTINGS" "$SETTINGS.bak.$(date +%Y%m%d%H%M%S)-$$" 2>/dev/null

tmp="$(mktemp)" || exit 1
trap 'rm -f "$tmp"' EXIT

# Mescla sem duplicar e sem remover o que já existia — o `allow` que você tiver
# configurado continua intacto. Invocação verificada: entrada por stdin porque
# com `--args` o jq trata o resto da linha como argumento posicional, não arquivo.
if jq --args \
     '.permissions = (.permissions // {})
      | .permissions.deny = (((.permissions.deny // []) + $ARGS.positional) | unique)' \
     "${regras[@]}" < "$SETTINGS" > "$tmp" 2>/dev/null && [ -s "$tmp" ]; then
  mv "$tmp" "$SETTINGS"
  trap - EXIT
  echo "gravado em $SETTINGS"
  echo "  ${#regras[@]} regra(s) no total (mínimo + ${#escolhidos[@]} escolhida(s) por você)"
  echo
  echo "As regras valem a partir da PRÓXIMA sessão do Claude Code."
  echo "Confira com /permissions, e que o startup não avise regra ignorada."
else
  echo "falha ao mesclar o JSON — $SETTINGS não foi alterado." >&2
  exit 1
fi
