#!/usr/bin/env bash
# Detector de formas de segredo. Helper carregado pelos tools, não um tool que
# agente chama — por isso o prefixo `_`, mesma convenção do `_workspace.sh`.
#
#   tools/_secret-shapes.sh [arquivo]     sem argumento, lê stdin
#
# Saída: uma linha por achado, no formato `numero-da-linha<TAB>classe`.
# Exit 1 quando acha alguma coisa, 0 quando está limpo — convenção do
# artifact-lint.sh, que é o que permite usar isto como portão.
#
# ---------------------------------------------------------------------------
# REGRA QUE NÃO SE QUEBRA: este script NUNCA imprime o valor casado.
#
# Um detector de segredo que ecoa o que encontrou copia o segredo para todo lugar
# por onde a saída passa — terminal, log, e o contexto do modelo que pediu a
# varredura. Por isso a saída é só (linha, classe): o `cut -d: -f1` logo depois
# de cada grep existe exatamente para descartar o conteúdo antes de qualquer
# impressão. Se um dia alguém precisar do valor, o lugar de olhar é o arquivo,
# com os olhos, fora da sessão.
# ---------------------------------------------------------------------------
#
# Motor: `grep -E`. NÃO use awk aqui. O awk padrão de Ubuntu é o mawk, que não
# suporta intervalo em ERE: `awk '/AKIA[A-Z0-9]{16}/'` não casa
# `AKIAIOSFODNN7EXAMPLE`. Como quase toda forma de segredo depende de contagem,
# um detector em awk falharia em silêncio — parece instalado, não acha nada.
# Verificado com GNU grep 3.7 e ugrep 7.5.

set -uo pipefail

# Valor que parece segredo mas é enfeite de template. Sem este filtro, todo
# README com `password: "changeme"` vira achado, e achado falso em volume é o
# que faz alguém desligar a varredura.
# `\$\(` e a crase cobrem o caso que apareceu na própria varredura deste repo:
# `token="$(ler_token)"` casa a forma de atribuição, mas o valor é substituição
# de comando — é código, não credencial. Valor que se resolve em tempo de
# execução nunca é o segredo em si.
PLACEHOLDER='changeme|change[_-]?me|your[_-]|yourkey|placeholder|example|exemplo|redacted|dummy|fake|sample|xxxx|\.\.\.|<[a-z_-]+>|\$\{|\$\(|`|\$[A-Z_]+|senha123|password123|test123|foobar|s3cret'

# classe<TAB>expressão. Tab é o separador porque toda ERE aqui usa `|`.
# Ordenado por confiança: o que está em cima praticamente não dá falso positivo.
read_patterns() {
  cat <<'PATTERNS'
chave-privada	-----BEGIN( [A-Z]+)* PRIVATE KEY-----
chave-privada-putty	PuTTY-User-Key-File-[0-9]
aws-access-key	\b(AKIA|ASIA|ABIA|ACCA)[A-Z0-9]{16}\b
aws-secret-atribuida	aws_secret_access_key[[:space:]]*=[[:space:]]*[A-Za-z0-9/+=]{40}
github-token	\bgh[pousr]_[A-Za-z0-9]{36}\b
github-pat-fino	\bgithub_pat_[A-Za-z0-9_]{22,}
gitlab-token	\bglpat-[A-Za-z0-9_-]{20}
slack-token	\bxox[abporsa]-[A-Za-z0-9-]{10,}
slack-webhook	hooks\.slack\.com/services/[A-Za-z0-9/]{20,}
google-api-key	\bAIza[0-9A-Za-z_-]{35}\b
gcp-service-account	"type"[[:space:]]*:[[:space:]]*"service_account"
anthropic-key	\bsk-ant-[A-Za-z0-9_-]{20,}
openai-key	\bsk-(proj-)?[A-Za-z0-9]{32,}
stripe-live	\b(sk|rk)_live_[0-9a-zA-Z]{16,}
npm-token	\bnpm_[A-Za-z0-9]{36}\b
sendgrid-key	\bSG\.[A-Za-z0-9_-]{16,}\.[A-Za-z0-9_-]{16,}
jwt	\beyJ[A-Za-z0-9_=-]{8,}\.[A-Za-z0-9_=-]{8,}\.[A-Za-z0-9_=-]{8,}
uri-com-senha	\b(postgres|postgresql|mysql|mongodb|mongodb\+srv|redis|rediss|amqp|amqps|ftp|smtp)://[^:@/[:space:]]+:[^@/[:space:]]+@
hostinger-token	\bhostinger_[A-Za-z0-9]{20,}
PATTERNS
}

# Atribuição genérica fica fora do bloco acima porque é a única que precisa do
# filtro de placeholder. É também a de menor confiança: mantida por pegar o
# segredo caseiro que nenhum prefixo conhecido acha.
GENERIC='(password|passwd|senha|secret|token|api[_-]?key|apikey|client[_-]?secret|private[_-]?key)["'"'"']?[[:space:]]*[:=][[:space:]]*["'"'"'][^"'"'"']{8,}["'"'"']'

src="${1:-}"
tmp=""
if [ -z "$src" ]; then
  tmp="$(mktemp)" || exit 0
  trap 'rm -f "$tmp"' EXIT
  cat > "$tmp"
  src="$tmp"
fi

[ -r "$src" ] || exit 0
# Binário não é varrido: regex em bytes aleatórios só produz ruído, e um PNG
# com token embutido não é achável por expressão regular de qualquer forma.
grep -Iq . "$src" 2>/dev/null || exit 0

found=0

emit() {
  local classe="$1"
  while IFS= read -r n; do
    [ -n "$n" ] || continue
    printf '%s\t%s\n' "$n" "$classe"
    found=1
  done
}

while IFS=$'\t' read -r classe regex; do
  [ -n "${classe:-}" ] || continue
  # `cut -d: -f1` descarta o conteúdo da linha ANTES de qualquer impressão.
  emit "$classe" < <(grep -nE -- "$regex" "$src" 2>/dev/null | cut -d: -f1)
done < <(read_patterns)

emit "atribuicao-generica" < <(
  grep -nE -- "$GENERIC" "$src" 2>/dev/null | grep -viE -- "$PLACEHOLDER" | cut -d: -f1
)

[ "$found" -eq 1 ] && exit 1
exit 0
