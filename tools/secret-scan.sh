#!/usr/bin/env bash
# Inventário de dado sensível do projeto — a evidência de onde estão as
# credenciais, para decidir o que migrar para o vault e o que restringir.
#
#   tools/secret-scan.sh [diretorio]
#
# Só lê. Não altera arquivo, não acessa a rede, não escreve política.
#
# Exit 1 quando encontra arquivo sensível RASTREADO pelo git — é o único
# resultado que exige ação, e é o que permite usar isto como portão.
#
# ---------------------------------------------------------------------------
# Imprime `arquivo:linha` e a CLASSE do achado. Nunca o valor. O motivo está no
# cabeçalho do `_secret-shapes.sh`: relatório de segredo que ecoa o segredo
# espalha o problema em vez de resolver, inclusive para dentro do contexto do
# modelo que pediu a varredura.
# ---------------------------------------------------------------------------

set -uo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
SHAPES="$SELF_DIR/_secret-shapes.sh"

ROOT="${1:-${CLAUDE_PROJECT_DIR:-$(pwd)}}"
cd "$ROOT" 2>/dev/null || { echo "diretório não acessível: $ROOT" >&2; exit 1; }
ROOT="$(pwd)"

hr() { printf '\n=== %s ===\n' "$1"; }

# Nome de arquivo que costuma guardar credencial. Não é prova — é onde olhar.
NOMES_SENSIVEIS='(^|/)\.env($|\.)|(^|/)\.envrc$|\.pem$|\.p12$|\.pfx$|\.jks$|\.keystore$|\.ppk$|(^|/)id_(rsa|dsa|ecdsa|ed25519)|(^|/)\.netrc$|(^|/)\.pgpass$|(^|/)\.git-credentials$|(^|/)\.npmrc$|(^|/)\.pypirc$|credentials?\.(json|ya?ml|ini|toml)$|service[_-]?account.*\.json$|(^|/)kubeconfig$|\.kubeconfig$|(^|/)\.vault-token$|terraform\.tfstate|\.tfvars$|secrets?\.(json|ya?ml|env|toml)$'

# Sufixo de template. `.env.example` casa o padrão de nome sensível acima, mas
# é justamente o arquivo que DEVE estar versionado: ele documenta quais chaves
# existem, sem valor nenhum. Acusá-lo é o falso positivo que desmoraliza a
# varredura inteira — quem vê quatro "problemas" que não são problema para de ler.
NOMES_TEMPLATE='\.(example|sample|template|dist|tpl)($|\.)|(^|/)(example|sample|template)\.'

# Caminho onde uma forma de segredo é esperada e não significa vazamento:
# fixture, exemplo de documentação, e os próprios arquivos que definem os
# padrões. Sem esta lista, o scanner acusa a si mesmo e some no ruído.
EXEMPLOS='(^|/)(test|tests|spec|__tests__|fixtures?|testdata|examples?|docs?)/|(^|/)README|\.example($|\.)|\.sample($|\.)|(^|/)tools/_secret-shapes\.sh$|(^|/)tools/secret-scan\.sh$|(^|/)prompts/'

# Diretório que só produz ruído e volume. É ERE, não glob de shell.
PODA='(^|/)(\.git|node_modules|\.venv|venv|vendor|dist|build|target|\.next|__pycache__)/'

IS_GIT=0
git rev-parse --git-dir >/dev/null 2>&1 && IS_GIT=1

tracked=""
[ "$IS_GIT" -eq 1 ] && tracked="$(git ls-files 2>/dev/null)"

esta_rastreado() {
  [ "$IS_GIT" -eq 1 ] || return 1
  printf '%s\n' "$tracked" | grep -qxF -- "$1"
}

esta_ignorado() {
  [ "$IS_GIT" -eq 1 ] || return 1
  git check-ignore -q -- "$1" 2>/dev/null
}

# Situação de versionamento de um caminho. É o dado que importa: um .env
# ignorado é higiene normal; o mesmo .env rastreado é um segredo publicado.
situacao() {
  if esta_rastreado "$1"; then printf 'RASTREADO'
  elif esta_ignorado "$1"; then printf 'ignorado'
  else printf 'nao-versionado'; fi
}

problemas=0

# ------------------------------------------------------------ nome sensível
hr "ARQUIVOS COM NOME DE CREDENCIAL"
achou_nome=0
while IFS= read -r f; do
  rel="${f#./}"
  st="$(situacao "$rel")"
  achou_nome=1
  if [ "$st" = "RASTREADO" ]; then
    printf '  %-14s %s   <-- está no git\n' "$st" "$rel"
    problemas=$((problemas + 1))
  else
    printf '  %-14s %s\n' "$st" "$rel"
  fi
done < <(find . -type f 2>/dev/null \
          | grep -vE "$PODA" \
          | grep -E "$NOMES_SENSIVEIS" \
          | grep -vE "$NOMES_TEMPLATE" \
          | sort)
[ "$achou_nome" -eq 0 ] && echo "  nenhum"

# --------------------------------------------------- forma de segredo no conteúdo
# Duas passadas: um grep rápido para achar candidatos, e o detector completo só
# neles. Rodar 20 expressões em todo arquivo do repositório é lento sem ganho.
hr "FORMA DE SEGREDO NO CONTEÚDO"
RAPIDO='AKIA|ASIA|gh[pousr]_|github_pat_|glpat-|xox[abporsa]-|AIza|sk-ant-|sk_live_|rk_live_|npm_[A-Za-z0-9]{30}|SG\.|eyJ[A-Za-z0-9]|BEGIN( [A-Z]+)* PRIVATE KEY|PuTTY-User-Key-File|(postgres|postgresql|mysql|mongodb|redis|amqp)://[^:@/ ]+:[^@/ ]+@|service_account|(password|passwd|senha|secret|token|api[_-]?key|apikey)["'"'"']?[[:space:]]*[:=]'

achou_conteudo=0
while IFS= read -r f; do
  rel="${f#./}"
  [ -r "$rel" ] || continue
  # >2MB é dump ou build; varrer isso é caro e o achado seria inútil.
  sz=$(wc -c < "$rel" 2>/dev/null || echo 0)
  [ "${sz:-0}" -gt 2097152 ] && continue

  saida="$("$SHAPES" "$rel" 2>/dev/null)"
  [ -z "$saida" ] && continue

  st="$(situacao "$rel")"
  exemplo=0
  printf '%s' "$rel" | grep -qE "$EXEMPLOS" && exemplo=1

  while IFS=$'\t' read -r linha classe; do
    [ -n "${linha:-}" ] || continue
    achou_conteudo=1
    if [ "$exemplo" -eq 1 ]; then
      printf '  exemplo        %s:%s  [%s]\n' "$rel" "$linha" "$classe"
    elif [ "$st" = "RASTREADO" ]; then
      printf '  RASTREADO      %s:%s  [%s]   <-- está no git\n' "$rel" "$linha" "$classe"
      problemas=$((problemas + 1))
    else
      printf '  %-14s %s:%s  [%s]\n' "$st" "$rel" "$linha" "$classe"
    fi
  done <<< "$saida"
done < <(find . -type f 2>/dev/null \
          | grep -vE "$PODA" \
          | xargs -r grep -lIE "$RAPIDO" 2>/dev/null \
          | sort -u)
[ "$achou_conteudo" -eq 0 ] && echo "  nenhuma"

# -------------------------------------------------------- estado da proteção
hr "ESTADO DA PROTEÇÃO"

if curl -fsS -m 2 http://127.0.0.1:8200/v1/sys/health >/dev/null 2>&1; then
  selado="$(curl -fsS -m 2 http://127.0.0.1:8200/v1/sys/seal-status 2>/dev/null \
            | grep -o '"sealed":[a-z]*' | cut -d: -f2)"
  case "$selado" in
    false) echo "  vault:      de pé e DESTRAVADO" ;;
    true)  echo "  vault:      de pé, mas LACRADO — rode secrets/vault-unseal" ;;
    *)     echo "  vault:      de pé, estado indeterminado" ;;
  esac
else
  echo "  vault:      não responde em 127.0.0.1:8200 (suba com secrets/compose.yml)"
fi

tok="$HOME/.config/ai-secrets/token"
if [ -f "$tok" ]; then
  perm="$(stat -c '%a' "$tok" 2>/dev/null || echo '?')"
  if [ "$perm" = "600" ]; then
    echo "  token:      presente, permissão 600"
  else
    echo "  token:      presente mas com permissão $perm — deveria ser 600"
    problemas=$((problemas + 1))
  fi
else
  echo "  token:      ausente (o wrapper não conseguirá ler o vault)"
fi

local_settings="$ROOT/.claude/settings.local.json"
if [ -f "$local_settings" ] && grep -q 'ai-secrets/token' "$local_settings" 2>/dev/null; then
  echo "  restrição:  regras de deny instaladas"
else
  echo "  restrição:  AUSENTE — rode tools/restrict.sh"
fi

# ------------------------------------------------------------------ veredito
hr "VEREDITO"
if [ "$problemas" -gt 0 ]; then
  echo "  $problemas problema(s) que pedem ação."
  echo
  echo "  Arquivo sensível RASTREADO no git é o caso grave: já está no histórico,"
  echo "  e tirar do working tree não tira do histórico. Migre o valor para o"
  echo "  vault, remova o arquivo, e trate o histórico à parte (git filter-repo)."
  echo "  Rotacione a credencial: assuma que o que foi versionado vazou."
else
  echo "  Nada rastreado no git com cara de segredo."
fi
echo
echo "  Próximo passo: tools/restrict.sh — escolher o que o agente não pode ler."

[ "$problemas" -gt 0 ] && exit 1
exit 0
