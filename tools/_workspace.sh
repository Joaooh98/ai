#!/usr/bin/env bash
# Helper interno — NÃO é um tool chamado por agente. É carregado com `source`
# por repo-facts.sh, diff-scope.sh, incident-evidence.sh e pelo detect-toolbelt
# da skill mcp-toolbelt.
#
# Define o que é um workspace: um diretório que **não** é repositório git mas
# contém repositórios. Um repo git comum devolve lista vazia, e cada chamador
# cai no caminho de sempre — é assim que o comportamento anterior fica intacto.
#
# Só lê. Sem rede.

# Diretórios que nunca contêm um membro e custam caro para varrer.
_WS_PRUNE=( -name node_modules -o -name target -o -name dist -o -name build
            -o -name .venv -o -name venv -o -name vendor -o -name .next
            -o -name .gradle -o -name out )

ws_is_repo() { git -C "$1" rev-parse --is-inside-work-tree >/dev/null 2>&1; }

# ws_members <dir> — membros de topo, um caminho relativo por linha.
#
# Vazio quando <dir> é um repositório git, ou quando não há repositório embaixo.
# Um repo dentro de outro membro NÃO é membro: contaria a mesma mudança duas
# vezes e daria ao agente a impressão de dois donos para o mesmo código.
ws_members() {
  local root="$1" g d rel a skip
  local -a accepted=()

  [ -d "$root" ] || return 0
  ws_is_repo "$root" && return 0

  while IFS= read -r g; do
    d="${g%/.git}"
    [ "$d" = "$root" ] && continue          # o .git da própria raiz, quando existe

    # Um `.git` vazio ou órfão não é repositório — a raiz do smart tem um assim.
    # Testar por arquivo em vez de chamar `git` evita um processo por candidato:
    # com 20 candidatos a diferença é de dezenas de ms, e isto roda em toda
    # invocação de agente.
    [ -f "$d/.git/HEAD" ] || [ -f "$d/.git" ] || continue

    rel="${d#"$root"/}"

    # Repo dentro de outro membro não é membro de topo.
    skip=0
    for a in ${accepted[@]+"${accepted[@]}"}; do
      case "$rel" in "$a"/*) skip=1; break ;; esac
    done
    [ "$skip" = 1 ] && continue

    accepted+=("$rel")
    printf '%s\n' "$rel"
  done < <(find "$root" -maxdepth 4 \( "${_WS_PRUNE[@]}" \) -prune -o \
                 -name .git -print 2>/dev/null | LC_ALL=C sort)
  # LC_ALL=C é obrigatório: o sort do locale ignora pontuação, e ".git" acabaria
  # DEPOIS de "flow/.git" — o filho apareceria antes do pai e o filtro de
  # aninhamento acima não pegaria nada.
}

# ws_is_workspace <dir> — verdadeiro quando há pelo menos um membro.
ws_is_workspace() { [ -n "$(ws_members "$1")" ]; }

# ws_stack <dir> — palpite de uma palavra sobre a stack, pelo manifest na raiz.
# Serve para o mapa do sistema ler rápido, não para substituir o repo-facts.
ws_stack() {
  local d="$1"
  [ -f "$d/pom.xml" ]            && { echo "java/maven";  return; }
  [ -f "$d/build.gradle" ] || [ -f "$d/build.gradle.kts" ] && { echo "java/gradle"; return; }
  [ -f "$d/package.json" ]       && { echo "node";        return; }
  [ -f "$d/pyproject.toml" ] || [ -f "$d/requirements.txt" ] && { echo "python"; return; }
  [ -f "$d/go.mod" ]             && { echo "go";          return; }
  [ -f "$d/Cargo.toml" ]         && { echo "rust";        return; }
  [ -f "$d/composer.json" ]      && { echo "php";         return; }
  [ -f "$d/Gemfile" ]            && { echo "ruby";        return; }
  [ -f "$d/pubspec.yaml" ]       && { echo "dart";        return; }
  echo "-"
}
