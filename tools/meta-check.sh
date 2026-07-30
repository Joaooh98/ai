#!/usr/bin/env bash
# Confere as METAS de qualidade declaradas do projeto contra os números que a
# rodada real produziu — para os Portões 3 e 4 e para a skill /setup.
#
#   tools/meta-check.sh [opções]
#
#     --resumo           poucas linhas, para injeção em skill
#     --baseline         imprime no stdout o baseline das metas de catraca
#     --meta <arquivo>   arquivo de metas (padrão: descoberto, ver abaixo)
#     --dir <raiz>       raiz do projeto (padrão: CLAUDE_PROJECT_DIR ou pwd)
#
# A pergunta que ele responde não é "o código está bom?" — é **"o projeto está
# dentro do que ELE mesmo declarou?"**. Meta é decisão do time, gravada uma vez
# no /setup; este script só confere, nunca negocia.
#
# NUNCA EXECUTA BUILD NEM TESTE. Ele lê o relatório que a rodada já produziu.
# Isso não é limitação, é a garantia: o número que ele compara veio da execução
# de verdade, não de um agente afirmando que rodou. Relatório ausente ou mais
# velho que o código é NÃO VERIFICÁVEL — e não verificável bloqueia, igual à
# regra que já vale em todos os portões.
#
# Exit: 0 todas as metas blocker atendidas (ou nenhuma meta configurada)
#       1 meta blocker não atendida, não verificável ou desatualizada
#       2 arquivo de metas malformado
#
# Só lê. Nunca escreve — nem o baseline: `--baseline` imprime, e quem chama
# redireciona. Congelar meta é decisão com dono, não efeito colateral de varredura.
# Sem rede.

set -uo pipefail

RESUMO=0
BASELINE=0
META=""
ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"

while [ $# -gt 0 ]; do
  case "$1" in
    --resumo)   RESUMO=1 ;;
    --baseline) BASELINE=1 ;;
    --meta)     META="${2:-}"; shift ;;
    --dir)      ROOT="${2:-}"; shift ;;
    -h|--help)  sed -n '2,30p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *)          echo "opção desconhecida: $1" >&2; exit 2 ;;
  esac
  shift
done

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=/dev/null
[ -r "$SELF_DIR/_workspace.sh" ] && . "$SELF_DIR/_workspace.sh"

# Sem o helper, a varredura de frescor pegaria `target/` e `node_modules/` — e
# arquivo gerado é sempre mais novo que o relatório, o que marcaria toda meta
# como desatualizada. Fallback próprio: este script precisa funcionar sozinho.
if ! declare -p _WS_PRUNE >/dev/null 2>&1; then
  _WS_PRUNE=( -name node_modules -o -name target -o -name dist -o -name build
              -o -name .venv -o -name venv -o -name vendor -o -name .next
              -o -name .gradle -o -name out -o -name .git )
fi

ROOT="$(cd "$ROOT" 2>/dev/null && pwd -P)" || { echo "raiz inexistente" >&2; exit 2; }

# ------------------------------------------------------------ achar as metas
# Ordem deliberada: `.claude/` primeiro porque meta descreve o PROJETO, não o
# ciclo — mesma natureza do toolbelt.md, e sobrevive quando docs/sdlc/ é limpo
# entre ciclos.
if [ -z "$META" ]; then
  for c in "$ROOT/.claude/meta.tsv" \
           "$ROOT/docs/sdlc/00-orchestration/meta.tsv"; do
    [ -f "$c" ] && { META="$c"; break; }
  done
fi

if [ -z "$META" ] || [ ! -f "$META" ]; then
  echo "NAO CONFIGURADO — nenhum arquivo de metas encontrado."
  echo
  echo "Procurei em:"
  echo "  .claude/meta.tsv                       (meta do projeto)"
  echo "  docs/sdlc/00-orchestration/meta.tsv    (meta do ciclo)"
  echo
  echo "AÇÃO: rode /setup — ele pergunta as metas e grava o arquivo."
  echo
  echo "Sem meta declarada, os portões caem no julgamento: 'orçamento de"
  echo "performance atendido, QUANDO EXISTIR' nunca existe, e cobertura vira"
  echo "opinião. Meta é o que torna o portão conferível."
  # Exit 0 de propósito: ausência de meta não é reprovação de código. Quem
  # transforma isso em bloqueio é o portão, que exige meta configurada.
  exit 0
fi

BASE="$(dirname "$META")/meta-baseline.tsv"

# -------------------------------------------------------------- ler as metas
# TSV: id <TAB> metrica <TAB> fonte <TAB> extrator <TAB> operador <TAB> valor
#      <TAB> severidade <TAB> origem
#
#   fonte      caminho do RELATÓRIO já produzido, relativo à raiz
#   extrator   como tirar o número do relatório (lista fechada, ver `extrai`)
#   operador   >= | <= | == | nao-cai | nao-sobe
#   valor      o alvo; "-" nos operadores de catraca, que leem o baseline
declare -a M_ID=() M_NOME=() M_FONTE=() M_EXTR=() M_OP=() M_VAL=() M_SEV=() M_ORIG=()
malformed=0
lineno=0

while IFS= read -r line || [ -n "$line" ]; do
  lineno=$((lineno + 1))
  case "$line" in ''|'#'*) continue ;; esac
  # Cabeçalho é conveniência para quem edita à mão, não dado.
  case "$line" in id$'\t'*) continue ;; esac

  IFS=$'\t' read -r id nome fonte extr op val sev orig <<<"$line"

  if [ -z "${orig:-}" ] || [ -z "${sev:-}" ] || [ -z "${val:-}" ] || \
     [ -z "${op:-}" ] || [ -z "${extr:-}" ] || [ -z "${fonte:-}" ] || [ -z "${nome:-}" ]; then
    printf 'METAS MALFORMADAS  %s:%s — esperava 8 campos separados por TAB\n' \
           "${META#"$ROOT"/}" "$lineno" >&2
    malformed=$((malformed + 1))
    continue
  fi

  case "$op" in
    '>='|'<='|'=='|nao-cai|nao-sobe) ;;
    *) printf 'METAS MALFORMADAS  %s:%s — operador desconhecido: %s\n' \
              "${META#"$ROOT"/}" "$lineno" "$op" >&2
       malformed=$((malformed + 1)); continue ;;
  esac

  case "$sev" in
    blocker|aviso) ;;
    *) printf 'METAS MALFORMADAS  %s:%s — severidade deve ser blocker ou aviso: %s\n' \
              "${META#"$ROOT"/}" "$lineno" "$sev" >&2
       malformed=$((malformed + 1)); continue ;;
  esac

  # Meta absoluta sem número é meta que nunca reprova — o pior modo de falha,
  # porque parece configurada. Catraca é a única que legitimamente usa "-".
  case "$op" in
    '>='|'<='|'==')
      case "$val" in
        ''|*[!0-9.]*) printf 'METAS MALFORMADAS  %s:%s — operador %s exige valor numérico: %s\n' \
                             "${META#"$ROOT"/}" "$lineno" "$op" "$val" >&2
                      malformed=$((malformed + 1)); continue ;;
      esac ;;
  esac

  M_ID+=("$id"); M_NOME+=("$nome"); M_FONTE+=("$fonte"); M_EXTR+=("$extr")
  M_OP+=("$op"); M_VAL+=("$val"); M_SEV+=("$sev"); M_ORIG+=("$orig")
done < "$META"

[ "$malformed" -gt 0 ] && {
  echo "Arquivo de metas inválido — $malformed linha(s). Nenhuma conferência rodou." >&2
  exit 2
}
[ "${#M_ID[@]}" -eq 0 ] && { echo "NAO CONFIGURADO — arquivo de metas sem nenhuma meta: ${META#"$ROOT"/}"; exit 0; }

# ------------------------------------------------------------- ler o baseline
# chave = id. Valor congelado na última vez que alguém decidiu congelar.
declare -A BASE_VAL=()
if [ -f "$BASE" ]; then
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in ''|'#'*|id$'\t'*) continue ;; esac
    IFS=$'\t' read -r bid bval _bdata <<<"$line"
    [ -n "${bid:-}" ] && [ -n "${bval:-}" ] && BASE_VAL["$bid"]="$bval"
  done < "$BASE"
fi

# ---------------------------------------------------------------- extratores
# Lista FECHADA de propósito. Um campo que aceitasse comando arbitrário faria do
# arquivo de metas um vetor de execução — e ele é editável por agente. Extrator
# novo se adiciona aqui, com revisão, não por configuração.
#
# Escreve o número no stdout. Silêncio = não conseguiu extrair.
extrai() {
  local extr="$1" arquivo="$2"

  case "$extr" in
    jacoco-line)
      # <counter type="LINE" missed="M" covered="C"/> → 100*C/(M+C).
      # O último LINE do arquivo é o agregado do relatório inteiro.
      grep -o '<counter type="LINE"[^/]*/>' "$arquivo" 2>/dev/null | tail -1 | awk '
        {
          match($0, /missed="[0-9]+"/);  m = substr($0, RSTART+8, RLENGTH-9)
          match($0, /covered="[0-9]+"/); c = substr($0, RSTART+9, RLENGTH-10)
          if (m + c > 0) printf "%.2f", 100 * c / (m + c)
        }'
      ;;
    lcov-line)
      # LF = linhas encontradas, LH = linhas atingidas, somadas no arquivo todo.
      awk -F: '/^LF:/ { f += $2 } /^LH:/ { h += $2 }
               END { if (f > 0) printf "%.2f", 100 * h / f }' "$arquivo" 2>/dev/null
      ;;
    json:*)
      # json:<caminho jq>, ex.: json:.metrics.p95
      command -v jq >/dev/null 2>&1 || return 0
      jq -r "${extr#json:} // empty" "$arquivo" 2>/dev/null | head -1
      ;;
    regex:*)
      # regex:<ERE com um grupo de captura>, primeiro casamento vence.
      sed -nE "s/.*${extr#regex:}.*/\1/p" "$arquivo" 2>/dev/null | head -1
      ;;
    count:*)
      # count:<ERE> — quantas linhas casam. Para "zero achados BLOCK".
      #
      # Sem `|| echo 0`: `grep -c` JÁ imprime 0 quando não casa nada, e só sai
      # com status 1. O fallback produziria duas linhas ("0\n0"), a soma daria
      # erro aritmético e a meta seria descartada em silêncio — portão liberado
      # por um bug. `|| true` só neutraliza o status de saída.
      grep -cE -- "${extr#count:}" "$arquivo" 2>/dev/null || true
      ;;
    *)
      return 0
      ;;
  esac
}

# Relatório mais velho que o código não descreve este código. Dizer "cobertura
# 82%" a partir de um jacoco de duas semanas atrás é a forma mais fácil de
# aprovar um portão com número falso — e a mais difícil de perceber depois.
esta_velho() {
  local arquivo="$1" achado
  achado="$(find "$ROOT" \( "${_WS_PRUNE[@]}" \) -prune -o \
                  -type f \( -name '*.java' -o -name '*.kt' -o -name '*.ts' \
                          -o -name '*.tsx' -o -name '*.js' -o -name '*.jsx' \
                          -o -name '*.py' -o -name '*.go' -o -name '*.rb' \
                          -o -name '*.cs' -o -name '*.php' \) \
                  -newer "$arquivo" -print -quit 2>/dev/null)"
  [ -n "$achado" ]
}

# Comparação numérica com decimal — bash só faz inteiro.
compara() {
  awk -v a="$1" -v op="$2" -v b="$3" 'BEGIN {
    if (op == ">=")  exit !(a >= b)
    if (op == "<=")  exit !(a <= b)
    if (op == "==")  exit !(a == b)
    exit 1
  }'
}

# ------------------------------------------------------------- classificar
declare -a OK=() FALHOU=() AVISOU=() NVERIF=() VELHO=() MELHOROU=()
declare -A ATUAL=()
blocker_ruim=0

i=0
while [ "$i" -lt "${#M_ID[@]}" ]; do
  id="${M_ID[$i]}"; nome="${M_NOME[$i]}"; fonte="${M_FONTE[$i]}"
  extr="${M_EXTR[$i]}"; op="${M_OP[$i]}"; val="${M_VAL[$i]}"
  sev="${M_SEV[$i]}"; orig="${M_ORIG[$i]}"
  # `fonte` aceita glob: artefato por item de trabalho (`review-<item>.md`) não
  # tem nome fixo. Zero arquivo casando é NÃO VERIFICÁVEL, nunca "zero achado" —
  # senão "ninguém escreveu o review" passaria como "review sem blocker", que é
  # exatamente o falso verde que a meta existe para impedir.
  arquivos=()
  while IFS= read -r a; do
    [ -n "$a" ] && [ -f "$ROOT/$a" ] && arquivos+=("$ROOT/$a")
  done < <(cd "$ROOT" 2>/dev/null && compgen -G "$fonte" 2>/dev/null || true)

  if [ "${#arquivos[@]}" -eq 0 ]; then
    NVERIF+=("$sev|$id|$nome|nenhum relatório casa \"$fonte\"|$orig")
    [ "$sev" = "blocker" ] && blocker_ruim=$((blocker_ruim + 1))
    i=$((i + 1)); continue
  fi

  # Agregar vários arquivos só faz sentido em contagem. Média de cobertura entre
  # relatórios diferentes seria um número que não descreve nada — melhor recusar
  # do que inventar.
  case "$extr" in
    count:*) ;;
    *) if [ "${#arquivos[@]}" -gt 1 ]; then
         NVERIF+=("$sev|$id|$nome|\"$fonte\" casa ${#arquivos[@]} arquivos; extrator '$extr' exige um só|$orig")
         [ "$sev" = "blocker" ] && blocker_ruim=$((blocker_ruim + 1))
         i=$((i + 1)); continue
       fi ;;
  esac

  velho=0
  for a in "${arquivos[@]}"; do
    esta_velho "$a" && { velho=1; fonte_velha="${a#"$ROOT"/}"; break; }
  done
  if [ "$velho" -eq 1 ]; then
    VELHO+=("$sev|$id|$nome|$fonte_velha é mais antigo que o código — rode a suíte de novo|$orig")
    [ "$sev" = "blocker" ] && blocker_ruim=$((blocker_ruim + 1))
    i=$((i + 1)); continue
  fi

  case "$extr" in
    count:*)
      atual=0
      for a in "${arquivos[@]}"; do
        n="$(extrai "$extr" "$a")"
        # Extrator que devolve lixo (regex inválido, arquivo binário) tem que
        # virar NÃO VERIFICÁVEL. Tratar como zero seria contar "nenhum achado"
        # a partir de uma medição que nunca aconteceu.
        case "$n" in
          ''|*[!0-9]*) atual=""; break ;;
        esac
        atual=$((atual + n))
      done ;;
    *) atual="$(extrai "$extr" "${arquivos[0]}")" ;;
  esac

  # Toda comparação daqui pra frente é numérica, feita em awk. Awk comparando
  # string com número não erra — ele responde algo. Validar aqui é o que impede
  # uma extração quebrada de virar "dentro da meta".
  case "${atual:-}" in
    '')            motivo="extrator '$extr' não achou número em $fonte" ;;
    *[!0-9.]*)     motivo="extrator '$extr' devolveu valor não numérico: '$atual'" ;;
    *.*.*)         motivo="extrator '$extr' devolveu número malformado: '$atual'" ;;
    *)             motivo="" ;;
  esac
  if [ -n "$motivo" ]; then
    NVERIF+=("$sev|$id|$nome|$motivo|$orig")
    [ "$sev" = "blocker" ] && blocker_ruim=$((blocker_ruim + 1))
    i=$((i + 1)); continue
  fi
  ATUAL["$id"]="$atual"

  case "$op" in
    nao-cai|nao-sobe)
      ref="${BASE_VAL[$id]:-}"
      if [ -z "$ref" ]; then
        NVERIF+=("$sev|$id|$nome|catraca sem baseline — congele com --baseline|$orig")
        [ "$sev" = "blocker" ] && blocker_ruim=$((blocker_ruim + 1))
        i=$((i + 1)); continue
      fi
      if [ "$op" = "nao-cai" ]; then cmp='>='; else cmp='<='; fi
      if compara "$atual" "$cmp" "$ref"; then
        # Melhorou de verdade: a catraca aperta, mas quem move o baseline é
        # uma decisão explícita — senão uma medição instável vira meta nova.
        if [ "$atual" != "$ref" ] && compara "$atual" "$cmp" "$ref"; then
          MELHOROU+=("$id|$nome|$ref → $atual")
        fi
        OK+=("$id|$nome|$atual ($op baseline $ref)")
      else
        FALHOU+=("$sev|$id|$nome|$atual piorou contra baseline $ref|$orig")
        [ "$sev" = "blocker" ] && blocker_ruim=$((blocker_ruim + 1))
      fi
      ;;
    *)
      if compara "$atual" "$op" "$val"; then
        OK+=("$id|$nome|$atual ($op $val)")
      else
        if [ "$sev" = "blocker" ]; then
          FALHOU+=("$sev|$id|$nome|$atual, meta é $op $val|$orig")
          blocker_ruim=$((blocker_ruim + 1))
        else
          AVISOU+=("$sev|$id|$nome|$atual, meta é $op $val|$orig")
        fi
      fi
      ;;
  esac
  i=$((i + 1))
done

# --------------------------------------------------------------- --baseline
if [ "$BASELINE" -eq 1 ]; then
  printf '# Baseline das metas de catraca. Congelado por decisão, não por varredura.\n'
  printf '# Mover um número aqui é assumir que ele não volta atrás.\n'
  printf 'id\tvalor\tdata\n'
  hoje="$(date +%F)"
  i=0
  while [ "$i" -lt "${#M_ID[@]}" ]; do
    case "${M_OP[$i]}" in
      nao-cai|nao-sobe)
        v="${ATUAL[${M_ID[$i]}]:-}"
        [ -n "$v" ] && printf '%s\t%s\t%s\n' "${M_ID[$i]}" "$v" "$hoje"
        ;;
    esac
    i=$((i + 1))
  done
  exit 0
fi

# ------------------------------------------------------------------ resumo
if [ "$RESUMO" -eq 1 ]; then
  printf 'metas    %s (%s)\n' "${META#"$ROOT"/}" "${#M_ID[@]} declarada(s)"
  printf 'atende   %s ok · %s falhou · %s não verificável · %s desatualizada\n' \
         "${#OK[@]}" "${#FALHOU[@]}" "${#NVERIF[@]}" "${#VELHO[@]}"
  [ "$blocker_ruim" -gt 0 ] && printf 'PORTÃO   BLOQUEADO — %s meta(s) blocker fora\n' "$blocker_ruim"
  [ "$blocker_ruim" -eq 0 ] && printf 'PORTÃO   liberado pelas metas\n'
  [ "$blocker_ruim" -gt 0 ] && exit 1
  exit 0
fi

# ----------------------------------------------------------------- relatório
printf 'METAS DO PROJETO — %s\n' "${META#"$ROOT"/}"
if [ -f "$BASE" ]; then
  printf 'baseline %s (%s congelada)\n' "${BASE#"$ROOT"/}" "${#BASE_VAL[@]}"
else
  printf 'baseline AUSENTE (%s) — meta de catraca não tem contra o que comparar\n' "${BASE#"$ROOT"/}"
fi
printf '\n'

if [ "${#FALHOU[@]}" -gt 0 ]; then
  printf '=== FORA DA META — bloqueia o portão ===\n'
  for e in "${FALHOU[@]}"; do
    IFS='|' read -r sev id nome detalhe orig <<<"$e"
    printf '  [%s] %-8s %s\n           %s\n           origem: %s\n' "$sev" "$id" "$nome" "$detalhe" "$orig"
  done
  printf '\n'
fi

if [ "${#NVERIF[@]}" -gt 0 ]; then
  printf '=== NÃO VERIFICÁVEL — bloqueia igual a falha ===\n'
  for e in "${NVERIF[@]}"; do
    IFS='|' read -r sev id nome detalhe orig <<<"$e"
    printf '  [%s] %-8s %s\n           %s\n' "$sev" "$id" "$nome" "$detalhe"
  done
  printf '\n'
fi

if [ "${#VELHO[@]}" -gt 0 ]; then
  printf '=== DESATUALIZADA — o número não descreve este código ===\n'
  for e in "${VELHO[@]}"; do
    IFS='|' read -r sev id nome detalhe orig <<<"$e"
    printf '  [%s] %-8s %s\n           %s\n' "$sev" "$id" "$nome" "$detalhe"
  done
  printf '\n'
fi

if [ "${#AVISOU[@]}" -gt 0 ]; then
  printf '=== AVISO — não bloqueia, mas é dívida declarada ===\n'
  for e in "${AVISOU[@]}"; do
    IFS='|' read -r sev id nome detalhe orig <<<"$e"
    printf '  %-8s %s — %s\n' "$id" "$nome" "$detalhe"
  done
  printf '\n'
fi

if [ "${#OK[@]}" -gt 0 ]; then
  printf '=== DENTRO DA META ===\n'
  for e in "${OK[@]}"; do
    IFS='|' read -r id nome detalhe <<<"$e"
    printf '  %-8s %s — %s\n' "$id" "$nome" "$detalhe"
  done
  printf '\n'
fi

if [ "${#MELHOROU[@]}" -gt 0 ]; then
  printf '=== MELHOROU — aperte a catraca com --baseline ===\n'
  for e in "${MELHOROU[@]}"; do
    IFS='|' read -r id nome delta <<<"$e"
    printf '  %-8s %s — %s\n' "$id" "$nome" "$delta"
  done
  printf '\n'
fi

printf '%s meta(s): %s ok, %s fora, %s não verificável, %s desatualizada\n' \
       "${#M_ID[@]}" "${#OK[@]}" "${#FALHOU[@]}" "${#NVERIF[@]}" "${#VELHO[@]}"

if [ "$blocker_ruim" -gt 0 ]; then
  printf '\nPORTÃO BLOQUEADO — %s meta(s) blocker fora, não verificável ou desatualizada.\n' "$blocker_ruim"
  exit 1
fi

printf '\nPORTÃO LIBERADO pelas metas declaradas.\n'
exit 0
