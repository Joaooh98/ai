#!/usr/bin/env bash
# Sincroniza o bloco "hooks" de um settings.json com o snippet versionado.
#
#   workflow/hooks-sync.sh <settings.json> <snippet.json>
#
# Imprime UM token de status em stdout; quem chama decide como falar com o
# operador. Nunca escreve mensagem de usuário — evita duas vozes diferentes
# saindo do mesmo lugar.
#
#   criado         não existia; snippet copiado inteiro
#   ja-atualizado  já idêntico ao snippet
#   atualizado     bloco era do toolkit e ficou para trás; substituído
#   mesclado       settings existia sem 'hooks'; snippet acrescentado
#   divergente     há hook que NÃO é do toolkit; nada foi tocado
#   sem-jq         jq ausente e settings já existe; nada foi tocado
#
# Por que "atualizado" existe: sem ele, todo projeto já fiado congela na versão
# de hooks do dia em que foi fiado. Um hook novo no toolkit nunca chega a
# lugar nenhum, porque "diferente do esperado" trata desatualizado e
# customizado como o mesmo caso — e um deles é seguro de substituir.

set -uo pipefail

settings="${1:?uso: hooks-sync.sh <settings.json> <snippet.json>}"
snippet="${2:?uso: hooks-sync.sh <settings.json> <snippet.json>}"

if [ ! -f "$settings" ]; then
  mkdir -p "$(dirname "$settings")"
  cp "$snippet" "$settings"
  echo "criado"; exit 0
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "sem-jq"; exit 0
fi

# Já idêntico?
if diff -q <(jq -S '.hooks' "$settings" 2>/dev/null) <(jq -S '.hooks' "$snippet") >/dev/null 2>&1; then
  echo "ja-atualizado"; exit 0
fi

# Não tem bloco 'hooks': acrescenta sem tocar no resto.
if ! jq -e '.hooks' "$settings" >/dev/null 2>&1; then
  tmp="$(mktemp)"
  if jq -s '.[0] * .[1]' "$settings" "$snippet" > "$tmp" 2>/dev/null; then
    mv "$tmp" "$settings"; echo "mesclado"
  else
    rm -f "$tmp"; echo "divergente"
  fi
  exit 0
fi

# Tem bloco 'hooks' diferente. A pergunta que decide: ele é INTEIRAMENTE do
# toolkit? Se todo comando aponta para .claude/ai-toolkit/workflow/hooks/,
# não há nada do operador ali para preservar — está apenas velho.
toolkit_owned="$(jq -r '
  [ (.hooks // {}) | .[] | .[]? | (.hooks // [])[] | (.command // "") ] as $c
  | if ($c | length) > 0 and ($c | all(test("ai-toolkit/workflow/hooks/")))
    then "sim" else "nao" end
' "$settings" 2>/dev/null)"

if [ "$toolkit_owned" != "sim" ]; then
  echo "divergente"; exit 0
fi

tmp="$(mktemp)"
if jq --slurpfile s "$snippet" '.hooks = $s[0].hooks' "$settings" > "$tmp" 2>/dev/null; then
  mv "$tmp" "$settings"; echo "atualizado"
else
  rm -f "$tmp"; echo "divergente"
fi
