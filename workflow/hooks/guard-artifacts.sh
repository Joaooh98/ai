#!/usr/bin/env bash
# PreToolUse (Write|Edit|NotebookEdit) — impõe a propriedade de artefatos do time.
#
# Os agentes de análise, review e auditoria precisam da ferramenta Write para
# gravar seus relatórios, mas não devem tocar em código de produção nem nos
# artefatos de outros agentes. O frontmatter sozinho não expressa isso: ou o
# agente tem Write, ou não tem. Este hook fecha a lacuna por caminho.
#
# Entrada: JSON do Claude Code no stdin (.agent_type, .tool_input.file_path)
# Saída:   permissionDecision "deny" quando a escrita viola a propriedade.
#          Silêncio (exit 0) quando permitido.

set -euo pipefail

if ! command -v jq >/dev/null 2>&1; then
  # Sem jq não há como inspecionar a entrada; falha aberta para não travar a sessão.
  exit 0
fi

input="$(cat)"
agent="$(printf '%s' "$input" | jq -r '.agent_type // ""')"
path="$(printf '%s' "$input" | jq -r '.tool_input.file_path // .tool_input.notebook_path // ""')"

# Sem agente (sessão principal) ou sem caminho: nada a impor.
[ -z "$agent" ] && exit 0
[ -z "$path" ] && exit 0

# Toda negação vira registro. Sem isso não há como auditar se as fronteiras estão
# funcionando ou se estão atrapalhando — e regra de segurança que ninguém consegue
# medir vira regra que alguém desliga.
audit() {
  local project="${CLAUDE_PROJECT_DIR:-$(printf '%s' "$input" | jq -r '.cwd // "."')}"
  local log="$project/.claude/logs/guard.tsv"
  mkdir -p "$(dirname "$log")" 2>/dev/null || return 0
  [ -f "$log" ] || printf 'timestamp\tdecisao\tagente\tcaminho\tmotivo\n' > "$log"
  printf '%s\t%s\t%s\t%s\t%s\n' \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$1" "$agent" "$path" "$2" >> "$log"
}

deny() {
  audit "deny" "$1"
  jq -n --arg reason "$1" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: $reason
    }
  }'
  exit 0
}

# ---------------------------------------------------------------------------
# Regra 1 — o MANIFEST tem um único escritor.
# ---------------------------------------------------------------------------
case "$path" in
  */docs/sdlc/00-orchestration/MANIFEST.md)
    [ "$agent" = "context-manager" ] || \
      deny "MANIFEST.md só pode ser escrito pelo context-manager. Reporte o artefato a ele em vez de editar o registro diretamente."
    ;;
esac

# ---------------------------------------------------------------------------
# Regra 2 — agentes que só produzem especificação escrevem apenas no diretório
#           da sua fase. Qualquer outro caminho, inclusive código de produção,
#           é negado.
#
#           Agentes que legitimamente alteram o sistema (builders, devops, SRE,
#           test-engineer, performance-engineer, release-manager, tech-writer)
#           não aparecem aqui: para eles, o limite é o campo Boundaries do
#           próprio agente, não um caminho.
# ---------------------------------------------------------------------------
case "$agent" in
  context-manager|tech-lead-orchestrator|project-analyst)
    allowed="docs/sdlc/00-orchestration/" ;;
  product-owner|business-analyst|ux-researcher)
    allowed="docs/sdlc/01-discovery/" ;;
  solution-architect|api-designer|data-architect|ux-ui-designer|threat-modeler)
    allowed="docs/sdlc/02-design/" ;;
  code-reviewer|security-auditor)
    allowed="docs/sdlc/04-quality/" ;;
  # Incidente: o comandante segura o estado e não toca no sistema; o analista
  # investiga e propõe. Quem altera é o papel de operação. É a regra anti-freelancing
  # do manual de incidentes do Google SRE, imposta em vez de recomendada.
  incident-commander)
    allowed="docs/incidents/" ;;
  root-cause-analyst)
    allowed="docs/incidents/|docs/sdlc/04-quality/" ;;
  *)
    exit 0 ;;
esac

IFS='|' read -ra prefixes <<< "$allowed"
for p in "${prefixes[@]}"; do
  case "$path" in *"$p"*) exit 0 ;; esac
done

deny "$agent só pode escrever em ${allowed//|/ ou } — este agente analisa e reporta, não altera código nem artefatos de outras fases. Caminho recusado: $path"
