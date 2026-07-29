#!/usr/bin/env bash
# Conformidade entre a arquitetura DECIDIDA e o código que existe — para a rotina
# /arch-conformance e para o Portão 3.
#
#   tools/arch-conformance.sh [opções]
#
#     --resumo            4 linhas, para injeção em skill
#     --baseline          imprime no stdout o ledger que congela as violações de hoje
#     --regras <arquivo>  arquivo de regras (padrão: descoberto, ver abaixo)
#     --dir <raiz>        raiz do projeto (padrão: CLAUDE_PROJECT_DIR ou pwd)
#
# A pergunta que ele responde não é "o código está bom?" — é **"esta mudança
# piorou a conformidade?"**. Violação já registrada no ledger não bloqueia; ela é
# dívida com dono e prazo. Violação nova bloqueia. É essa assimetria que permite
# exigir a arquitetura à risca sem parar a entrega: o número só pode cair.
#
# Exit: 0 conforme (só dívida registrada, ou não configurado)
#       1 há violação NOVA, ou isenção vencida
#       2 arquivo de regras malformado
#
# Só lê. Nunca escreve — nem o ledger: `--baseline` imprime, e quem chama redireciona.
# Sem rede.

set -uo pipefail

RESUMO=0
BASELINE=0
RULES=""
ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"

while [ $# -gt 0 ]; do
  case "$1" in
    --resumo)   RESUMO=1 ;;
    --baseline) BASELINE=1 ;;
    --regras)   RULES="${2:-}"; shift ;;
    --dir)      ROOT="${2:-}"; shift ;;
    -h|--help)  sed -n '2,20p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *)          echo "opção desconhecida: $1" >&2; exit 2 ;;
  esac
  shift
done

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=/dev/null
[ -r "$SELF_DIR/_workspace.sh" ] && . "$SELF_DIR/_workspace.sh"

# `_workspace.sh` traz a lista de diretórios que nunca contêm código nosso. Sem
# ele, a varredura pegaria `target/` e `node_modules/` — e uma violação em código
# gerado é ruído que ninguém pode corrigir. Fallback próprio em vez de exigir o
# helper: este script precisa funcionar mesmo instalado sozinho.
if ! declare -p _WS_PRUNE >/dev/null 2>&1; then
  _WS_PRUNE=( -name node_modules -o -name target -o -name dist -o -name build
              -o -name .venv -o -name venv -o -name vendor -o -name .next
              -o -name .gradle -o -name out )
fi

ROOT="$(cd "$ROOT" 2>/dev/null && pwd -P)" || { echo "raiz inexistente" >&2; exit 2; }
TODAY="$(date +%F)"

# ----------------------------------------------------------- achar as regras
# Ordem deliberada: o caminho do fluxo SDLC primeiro, depois onde projetos que
# já tinham arquitetura documentada antes da equipe costumam guardá-la.
if [ -z "$RULES" ]; then
  for c in "$ROOT/docs/sdlc/02-design/arch-rules.tsv" \
           "$ROOT/docs/arq/arch-rules.tsv" \
           "$ROOT/.claude/arch-rules.tsv"; do
    [ -f "$c" ] && { RULES="$c"; break; }
  done
fi

if [ -z "$RULES" ] || [ ! -f "$RULES" ]; then
  echo "NAO CONFIGURADO — nenhum arquivo de regras encontrado."
  echo
  echo "Procurei em:"
  echo "  docs/sdlc/02-design/arch-rules.tsv   (fluxo SDLC)"
  echo "  docs/arq/arch-rules.tsv              (arquitetura documentada fora do fluxo)"
  echo "  .claude/arch-rules.tsv"
  echo
  echo "AÇÃO: rode /arch-conformance — ele destila as regras da arquitetura decidida."
  # Exit 0 de propósito: ausência de configuração não é reprovação de código, e
  # tratar como reprovação transformaria a adoção da rotina num bloqueio de entrega.
  exit 0
fi

LEDGER="$(dirname "$RULES")/arch-debt.tsv"

# ------------------------------------------------------------- ler as regras
# TSV: id <TAB> tipo <TAB> alvo <TAB> argumento <TAB> severidade <TAB> origem
#
#   alvo       ERE casada contra o caminho relativo do arquivo
#   argumento  depende do tipo (ver `aplica` abaixo)
declare -a R_ID=() R_TIPO=() R_ALVO=() R_ARG=() R_SEV=() R_ORIG=()
malformed=0
lineno=0

while IFS= read -r line || [ -n "$line" ]; do
  lineno=$((lineno + 1))
  case "$line" in ''|'#'*) continue ;; esac

  IFS=$'\t' read -r id tipo alvo arg sev orig <<<"$line"

  if [ -z "${orig:-}" ] || [ -z "${sev:-}" ] || [ -z "${arg:-}" ] || [ -z "${alvo:-}" ]; then
    printf 'REGRAS MALFORMADAS  %s:%s — esperava 6 campos separados por TAB\n' \
           "${RULES#"$ROOT"/}" "$lineno" >&2
    malformed=$((malformed + 1))
    continue
  fi
  case "$tipo" in
    proibe-conteudo|exige-conteudo|limita-publico|exige-par) ;;
    *) printf 'REGRAS MALFORMADAS  %s:%s — tipo desconhecido: %s\n' \
              "${RULES#"$ROOT"/}" "$lineno" "$tipo" >&2
       malformed=$((malformed + 1)); continue ;;
  esac
  case "$sev" in
    blocker|aviso) ;;
    *) printf 'REGRAS MALFORMADAS  %s:%s — severidade deve ser blocker ou aviso: %s\n' \
              "${RULES#"$ROOT"/}" "$lineno" "$sev" >&2
       malformed=$((malformed + 1)); continue ;;
  esac

  R_ID+=("$id"); R_TIPO+=("$tipo"); R_ALVO+=("$alvo")
  R_ARG+=("$arg"); R_SEV+=("$sev"); R_ORIG+=("$orig")
done < "$RULES"

[ "$malformed" -gt 0 ] && {
  echo "Arquivo de regras inválido — $malformed linha(s). Nenhuma verificação rodou." >&2
  exit 2
}
[ "${#R_ID[@]}" -eq 0 ] && { echo "NAO CONFIGURADO — arquivo de regras sem nenhuma regra: ${RULES#"$ROOT"/}"; exit 0; }

# --------------------------------------------------------- ler o ledger
# chave = "<id da regra>:<caminho>". Linha e coluna mudam a cada refatoração; o
# par regra+arquivo é o que sobrevive. Duas violações da mesma regra no mesmo
# arquivo contam como uma — deliberado, porque quebrar um arquivo em dois não é
# progresso e não deveria abrir blocker novo.
declare -A LED_ESTADO=() LED_DONO=() LED_PRAZO=()
led_divida=0; led_isento=0

if [ -f "$LEDGER" ]; then
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in ''|'#'*|'chave'*) continue ;; esac
    IFS=$'\t' read -r chave _regra _arq estado dono prazo _nota <<<"$line"
    [ -z "${estado:-}" ] && continue
    LED_ESTADO["$chave"]="$estado"
    LED_DONO["$chave"]="${dono:--}"
    LED_PRAZO["$chave"]="${prazo:--}"
    case "$estado" in
      divida) led_divida=$((led_divida + 1)) ;;
      isento) led_isento=$((led_isento + 1)) ;;
    esac
  done < "$LEDGER"
fi

# ------------------------------------------------- inventário de arquivos
# Uma varredura só, reusada por todas as regras. Excluir saída de build não é
# otimização: `target/` contém .java gerado, e uma violação lá é ruído que
# ninguém pode corrigir.
FILES="$(mktemp)"; trap 'rm -f "$FILES" "${CAND:-}" "${ACHADOS:-}"' EXIT
find "$ROOT" \( -name .git -o "${_WS_PRUNE[@]}" \) -prune -o -type f -print 2>/dev/null \
  | sed "s|^$ROOT/||" | LC_ALL=C sort > "$FILES"
total_files="$(wc -l < "$FILES" | tr -d ' ')"

# ------------------------------------------------------------ aplicar regra
# Escreve no stdout uma linha por violação: "<caminho>"
CAND="$(mktemp)"

aplica() {
  local tipo="$1" alvo="$2" arg="$3"

  grep -E "$alvo" "$FILES" > "$CAND" 2>/dev/null || true
  # Regra cujo alvo não casa nenhum arquivo devolve "conforme" sem ter verificado
  # nada. É o pior modo de falha possível — falso verde — e a causa quase sempre
  # é o mesmo erro: padrão de caminho escrito para monorepo (`/src/main/java/`)
  # rodando em repositório de módulo único, onde não existe a barra inicial.
  # Por isso o chamador conta e denuncia; silêncio aqui seria perda de sinal.
  [ -s "$CAND" ] || return 9

  case "$tipo" in
    proibe-conteudo)
      # Arquivo que CASA o alvo e CONTÉM o padrão está violando.
      (cd "$ROOT" && tr '\n' '\0' < "$CAND" | xargs -0 -r grep -lE "$arg" 2>/dev/null) || true
      ;;
    exige-conteudo)
      # Arquivo que casa o alvo e NÃO contém o padrão está violando.
      (cd "$ROOT" && tr '\n' '\0' < "$CAND" | xargs -0 -r grep -LE "$arg" 2>/dev/null) || true
      ;;
    limita-publico)
      # Mais de N métodos públicos de nomes DISTINTOS.
      #
      # Distintos, e não assinaturas, de propósito: sobrecarga de `execute(...)`
      # continua sendo uma ação de negócio só — contar assinatura transformaria
      # `execute(a)` + `execute(a,b)` em violação e a regra viraria discussão em
      # vez de sinal. O que a arquitetura proíbe é o Use Case ganhar uma segunda
      # responsabilidade, e isso aparece como um segundo NOME.
      #
      # Construtor não conta: o padrão exige dois tokens antes do "(" (tipo de
      # retorno + nome), e `public Foo(` só tem um.
      local f n
      while IFS= read -r f; do
        [ -f "$ROOT/$f" ] || continue
        n="$(awk '
          {
            line = $0
            if (line ~ /^[[:space:]]*public[[:space:]]+(class|interface|enum|record|abstract|static|final)[[:space:]]/) next
            if (line ~ /^[[:space:]]*public[[:space:]]+[A-Za-z_][A-Za-z0-9_<>,.@\[\] \t]*[[:space:]]+[a-zA-Z_][A-Za-z0-9_]*[[:space:]]*\(/) {
              sub(/\(.*$/, "", line)            # corta do "(" para a frente
              sub(/[[:space:]]+$/, "", line)    # tira espaço à direita
              sub(/^.*[[:space:]]/, "", line)   # sobra o último token: o nome
              nomes[line] = 1
            }
          }
          END { n = 0; for (k in nomes) n++; print n }' "$ROOT/$f")"
        [ "${n:-0}" -gt "$arg" ] && printf '%s\n' "$f"
      done < "$CAND"
      ;;
    exige-par)
      # Para cada arquivo casado, exige que exista OUTRO arquivo cujo caminho
      # case o ERE do argumento, com %B expandido para o basename sem extensão.
      # É a regra "implementação sem a interface que o domínio deveria definir".
      local f base pat
      while IFS= read -r f; do
        base="$(basename "$f")"; base="${base%.*}"
        pat="${arg//%B/$base}"
        grep -qE "$pat" "$FILES" || printf '%s\n' "$f"
      done < "$CAND"
      ;;
  esac
}

# ------------------------------------------------------------- classificar
declare -a NOVAS=() DIVIDAS=() ISENTAS=() VENCIDAS=() SEM_ALVO=()
declare -A VISTAS=()
novas_blocker=0
ACHADOS="$(mktemp)"

i=0
while [ "$i" -lt "${#R_ID[@]}" ]; do
  id="${R_ID[$i]}"; sev="${R_SEV[$i]}"; orig="${R_ORIG[$i]}"
  aplica "${R_TIPO[$i]}" "${R_ALVO[$i]}" "${R_ARG[$i]}" > "$ACHADOS"
  [ $? -eq 9 ] && SEM_ALVO+=("$id|${R_ALVO[$i]}")
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    chave="$id:$f"
    VISTAS["$chave"]=1
    estado="${LED_ESTADO[$chave]:-}"
    case "$estado" in
      divida)
        DIVIDAS+=("$sev|$id|$f|${LED_DONO[$chave]}|${LED_PRAZO[$chave]}|$orig") ;;
      isento)
        prazo="${LED_PRAZO[$chave]}"
        if [ "$prazo" != "-" ] && [ "$prazo" \< "$TODAY" ]; then
          VENCIDAS+=("$sev|$id|$f|${LED_DONO[$chave]}|$prazo|$orig")
        else
          ISENTAS+=("$sev|$id|$f|${LED_DONO[$chave]}|$prazo|$orig")
        fi ;;
      *)
        NOVAS+=("$sev|$id|$f|-|-|$orig")
        [ "$sev" = "blocker" ] && novas_blocker=$((novas_blocker + 1)) ;;
    esac
  done < "$ACHADOS"
  i=$((i + 1))
done
rm -f "$ACHADOS"

# Registrado no ledger mas não encontrado no código: foi resolvido. A catraca
# aperta sozinha — some do ledger e volta a bloquear se reaparecer.
declare -a RESOLVIDAS=()
for chave in "${!LED_ESTADO[@]}"; do
  [ -n "${VISTAS[$chave]:-}" ] && continue
  RESOLVIDAS+=("$chave|${LED_ESTADO[$chave]}")
done

# ------------------------------------------------------------------ baseline
if [ "$BASELINE" -eq 1 ]; then
  printf 'chave\tregra\tarquivo\testado\tdono\tprazo\tnota\n'
  for e in ${DIVIDAS[@]+"${DIVIDAS[@]}"} ${ISENTAS[@]+"${ISENTAS[@]}"} ${VENCIDAS[@]+"${VENCIDAS[@]}"}; do
    IFS='|' read -r _sev id f dono prazo _orig <<<"$e"
    printf '%s:%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$id" "$f" "$id" "$f" \
           "${LED_ESTADO["$id:$f"]}" "$dono" "$prazo" "-"
  done
  for e in ${NOVAS[@]+"${NOVAS[@]}"}; do
    IFS='|' read -r _sev id f _dono _prazo _orig <<<"$e"
    printf '%s:%s\t%s\t%s\tdivida\t?\t?\tcongelada no baseline de %s\n' \
           "$id" "$f" "$id" "$f" "$TODAY"
  done
  exit 0
fi

# -------------------------------------------------------------------- resumo
n_novas="${#NOVAS[@]}"; n_div="${#DIVIDAS[@]}"
n_isen="${#ISENTAS[@]}"; n_venc="${#VENCIDAS[@]}"; n_res="${#RESOLVIDAS[@]}"
n_sem="${#SEM_ALVO[@]}"

# Nenhuma regra casou arquivo nenhum: o checker não verificou nada, e dizer
# "conforme" aqui seria mentira útil para quem quer o portão verde. Falha de
# configuração, não veredito de código — daí exit 2, o mesmo das regras
# malformadas, e não 1.
if [ "$n_sem" -eq "${#R_ID[@]}" ]; then
  printf 'REGRAS NAO CALIBRADAS — nenhuma das %s regras casou um único arquivo.\n' "${#R_ID[@]}" >&2
  printf 'Nada foi verificado. Causa provável: padrão de caminho de monorepo\n' >&2
  printf '(`/src/main/java/`) num repositório de módulo único — use `(^|/)src/...`.\n' >&2
  printf 'Regras: %s\n' "${RULES#"$ROOT"/}" >&2
  exit 2
fi

if [ "$RESUMO" -eq 1 ]; then
  printf 'CONFORMIDADE: %s regra(s) sobre %s arquivo(s) — %s\n' \
         "${#R_ID[@]}" "$total_files" "${RULES#"$ROOT"/}"
  printf 'NOVAS: %s (%s blocker) · DIVIDA: %s · ISENCAO: %s (%s vencida) · RESOLVIDAS: %s\n' \
         "$n_novas" "$novas_blocker" "$n_div" "$n_isen" "$n_venc" "$n_res"
  [ "$n_sem" -gt 0 ] && printf 'ATENCAO: %s regra(s) nao casaram arquivo nenhum — verifique o alvo.\n' "$n_sem"
  if [ ! -f "$LEDGER" ]; then
    printf 'LEDGER AUSENTE — nada foi baselinado ainda, então TODA violação conta como nova.\n'
  fi
  if [ "$novas_blocker" -gt 0 ] || [ "$n_venc" -gt 0 ]; then
    printf 'VEREDITO: BLOQUEADO\n'
  else
    printf 'VEREDITO: conforme (a dívida registrada não bloqueia)\n'
  fi
  [ "$novas_blocker" -gt 0 ] || [ "$n_venc" -gt 0 ] && exit 1
  exit 0
fi

# ------------------------------------------------------------------ relatório
printf '=== CONFORMIDADE ARQUITETURAL ===\n'
printf 'regras   %s (%s regra(s))\n' "${RULES#"$ROOT"/}" "${#R_ID[@]}"
if [ -f "$LEDGER" ]; then
  printf 'ledger   %s (%s dívida, %s isenção)\n' "${LEDGER#"$ROOT"/}" "$led_divida" "$led_isento"
else
  printf 'ledger   AUSENTE (%s) — sem baseline, toda violação conta como nova\n' "${LEDGER#"$ROOT"/}"
fi
printf 'escopo   %s arquivo(s)\n' "$total_files"

mostra() {
  local titulo="$1"; shift
  [ "$#" -eq 0 ] && return 0
  printf '\n=== %s ===\n' "$titulo"
  printf '%s\n' "$@" | LC_ALL=C sort | while IFS='|' read -r sev id f dono prazo orig; do
    printf '%-8s %-12s %s\n' "$sev" "$id" "$f"
    printf '         %s%s\n' "$orig" \
      "$( [ "$dono" != "-" ] && printf ' · dono %s' "$dono"; [ "$prazo" != "-" ] && printf ' · prazo %s' "$prazo" )"
  done
}

mostra "NOVAS — bloqueiam o merge" ${NOVAS[@]+"${NOVAS[@]}"}
mostra "ISENÇÕES VENCIDAS — bloqueiam o merge" ${VENCIDAS[@]+"${VENCIDAS[@]}"}
mostra "DÍVIDA REGISTRADA — não bloqueia, é paga por orçamento" ${DIVIDAS[@]+"${DIVIDAS[@]}"}
mostra "ISENÇÕES NO PRAZO" ${ISENTAS[@]+"${ISENTAS[@]}"}

if [ "$n_sem" -gt 0 ]; then
  printf '\n=== REGRAS QUE NÃO CASARAM NENHUM ARQUIVO — não verificaram nada ===\n'
  printf '%s\n' "${SEM_ALVO[@]}" | while IFS='|' read -r id alvo; do
    printf '  %-16s alvo: %s\n' "$id" "$alvo"
  done
  printf '  Regra que não casa arquivo não protege nada. Corrija o alvo ou remova a regra.\n'
fi

if [ "$n_res" -gt 0 ]; then
  printf '\n=== RESOLVIDAS — tire do ledger, e voltam a bloquear se reaparecerem ===\n'
  printf '%s\n' "${RESOLVIDAS[@]}" | LC_ALL=C sort | sed 's/|/  (estava como /; s/$/)/' | sed 's/^/  /'
fi

# ---------------------------------------------- qual dívida pagar primeiro
# Risco = severidade × churn. Arquivo que ninguém toca há meses tem violação
# barata de conviver; a que muda toda semana cobra juros em cada mudança.
if [ "$n_div" -gt 0 ] && git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  CHURN="$(mktemp)"
  git -C "$ROOT" log --since="90 days ago" --name-only --pretty=format: 2>/dev/null \
    | grep -v '^$' | LC_ALL=C sort | uniq -c | awk '{print $2"\t"$1}' > "$CHURN"
  printf '\n=== ORDEM DE PAGAMENTO — por severidade e churn de 90 dias ===\n'
  printf '%s\n' "${DIVIDAS[@]}" | while IFS='|' read -r sev id f dono prazo _orig; do
    c="$(awk -F'\t' -v k="$f" '$1==k{print $2; exit}' "$CHURN")"
    printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
           "$( [ "$sev" = blocker ] && echo 0 || echo 1 )" "$((999 - ${c:-0}))" \
           "$sev" "$id" "$f" "${c:-0}"
  done | LC_ALL=C sort | head -10 | \
    awk -F'\t' '{printf "  %-8s %-12s %s  (%s commit(s) em 90d)\n", $3, $4, $5, $6}'
  rm -f "$CHURN"
fi

printf '\nRESUMO: %s nova(s) (%s blocker) · %s dívida · %s isenção (%s vencida) · %s resolvida(s)\n' \
       "$n_novas" "$novas_blocker" "$n_div" "$n_isen" "$n_venc" "$n_res"

if [ "$novas_blocker" -gt 0 ] || [ "$n_venc" -gt 0 ]; then
  printf 'VEREDITO: BLOQUEADO — violação nova ou isenção vencida.\n'
  printf 'Corrija a violação nova, ou registre isenção com dono e prazo em %s.\n' "${LEDGER#"$ROOT"/}"
  exit 1
fi
printf 'VEREDITO: conforme. A dívida registrada não bloqueia — pague pelo orçamento da rotina.\n'
exit 0
