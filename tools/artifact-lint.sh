#!/usr/bin/env bash
# Verifica se os artefatos do fluxo SDLC têm as seções obrigatórias do contrato
# de saída de cada agente. Usado por /sdlc-gate e /sdlc-status.
#
#   tools/artifact-lint.sh [fase]    fase: 01 | 02 | 04 | 05 | all (padrão: all)
#
# Saída: uma linha por artefato. Exit 1 se algum estiver incompleto.
# Só lê. Nunca altera artefato.

set -uo pipefail
PHASE="${1:-all}"
ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"
SDLC="$ROOT/docs/sdlc"

[ -d "$SDLC" ] || { echo "docs/sdlc/ não existe — nenhum ciclo iniciado."; exit 0; }

fails=0
checked=0

check() {
  local file="$1"; shift
  local rel="${file#"$ROOT"/}"

  if [ ! -f "$file" ]; then
    printf 'AUSENTE   %s\n' "$rel"
    fails=$((fails + 1))
    return
  fi

  checked=$((checked + 1))
  local missing=()
  local section
  for section in "$@"; do
    grep -qi -- "$section" "$file" || missing+=("$section")
  done

  # Um artefato que só tem o esqueleto do template não conta como pronto.
  local body
  body="$(grep -vE '^\s*$|^#|^\|[-: |]+\|$' "$file" | wc -l | tr -d ' ')"

  if [ ${#missing[@]} -gt 0 ]; then
    printf 'INCOMPLETO %s — falta: %s\n' "$rel" "$(IFS=', '; echo "${missing[*]}")"
    fails=$((fails + 1))
  elif [ "$body" -lt 10 ]; then
    printf 'ESQUELETO %s — %s linhas de conteúdo, parece só o template\n' "$rel" "$body"
    fails=$((fails + 1))
  else
    printf 'OK        %s\n' "$rel"
  fi
}

if [ "$PHASE" = "01" ] || [ "$PHASE" = "all" ]; then
  echo "--- 01 discovery ---"
  check "$SDLC/01-discovery/prd.md" "Problem" "Success metrics" "Out of scope" "Given" "Open questions"
  [ -f "$SDLC/01-discovery/domain.md" ] && \
    check "$SDLC/01-discovery/domain.md" "language" "rules" "Decision tables"
  [ -f "$SDLC/01-discovery/ux-research.md" ] && \
    check "$SDLC/01-discovery/ux-research.md" "Personas" "journey" "severity"
fi

if [ "$PHASE" = "02" ] || [ "$PHASE" = "all" ]; then
  echo "--- 02 design ---"
  check "$SDLC/02-design/architecture.md" "NFR" "Target state" "Integration patterns" "Migration" "Risks"
  [ -f "$SDLC/02-design/data-model.md" ] && \
    check "$SDLC/02-design/data-model.md" "Access patterns" "Indexes" "Migration"
  [ -f "$SDLC/02-design/threat-model.md" ] && \
    check "$SDLC/02-design/threat-model.md" "STRIDE" "Security requirements" "Residual risk"
  [ -f "$SDLC/02-design/ux-spec.md" ] && \
    check "$SDLC/02-design/ux-spec.md" "state" "Accessibility" "tokens"
  [ -f "$SDLC/02-design/integrations.md" ] && \
    check "$SDLC/02-design/integrations.md" "Interface interna" "timeout" "Degrada" "Credenciais"
  adr_count=$(find "$SDLC/02-design/adr" -name 'ADR-*.md' 2>/dev/null | wc -l | tr -d ' ')
  printf 'INFO      %s ADR(s) em 02-design/adr/\n' "$adr_count"
  [ "$adr_count" -eq 0 ] && { echo "AVISO     nenhum ADR — toda decisão estrutural deveria ter um"; fails=$((fails+1)); }
fi

if [ "$PHASE" = "04" ] || [ "$PHASE" = "all" ]; then
  echo "--- 04 quality ---"
  check "$SDLC/04-quality/test-plan.md" "Traceability" "Results"
  for f in "$SDLC"/04-quality/review-*.md; do
    [ -e "$f" ] || continue
    check "$f" "Verdict" "Failure scenario" "Test assessment"
  done
  [ -f "$SDLC/04-quality/security-audit.md" ] && \
    check "$SDLC/04-quality/security-audit.md" "Verdict" "Attack path" "requirement verification"
fi

if [ "$PHASE" = "05" ] || [ "$PHASE" = "all" ]; then
  echo "--- 05 delivery ---"
  for f in "$SDLC"/05-delivery/release-*.md; do
    [ -e "$f" ] || continue
    check "$f" "Decision" "Gate verification" "Rollback criteria"
  done
  [ -f "$SDLC/05-delivery/observability.md" ] && \
    check "$SDLC/05-delivery/observability.md" "SLO" "Alerts" "runbook"
fi

printf '\n%s artefato(s) verificado(s), %s problema(s)\n' "$checked" "$fails"
[ "$fails" -gt 0 ] && exit 1
exit 0
