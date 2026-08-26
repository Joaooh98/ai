#!/usr/bin/env bash
# Confere a documentação DESTE repositório contra o repositório real.
#
#   tools/docs-lint.sh [raiz]
#
# Verifica o que dá para verificar sem julgamento: link quebrado, caminho citado
# que não existe, contagem declarada que não bate, pasta sem README, agente ou
# skill ou tool sem menção no README da sua pasta, e arquivo que nenhum
# documento alcança.
#
# NÃO julga se o texto está bom — julga se ele está VERDADEIRO. Documentação que
# mente sobre a própria estrutura é pior que documentação ausente: a ausente
# manda alguém ler o código, a que mente manda para o lugar errado.
#
# Exit: 0 tudo confere · 1 há divergência · 2 raiz inválida
#
# Só lê. Sem rede.

set -uo pipefail
R="${1:-${CLAUDE_PROJECT_DIR:-$(pwd)}}"
cd "$R" 2>/dev/null || { echo "raiz inexistente: $R" >&2; exit 2; }
[ -f README.md ] || { echo "sem README.md na raiz — não parece a raiz do repositório" >&2; exit 2; }

fails=0
falha(){ printf '%s\n' "$*"; fails=$((fails + 1)); }

# O que NÃO é documentação da oficina:
#   prompts/, .claude/     ciclo de vida próprio
#   docs/sdlc/, docs/incidents/   artefato de CICLO. Um plano descreve o que
#                          ainda vai ser construído: citar caminho inexistente
#                          é o propósito dele, não defeito. Medi-los faria o
#                          lint reprovar todo bootstrap de onda 00.
DOCS=$(find . -name '*.md' -not -path './.git/*' -not -path './.claude/*' \
                           -not -path './prompts/*' -not -path './node_modules/*' \
                           -not -path './docs/sdlc/*' -not -path './docs/incidents/*' | sort)

# Caminhos que descrevem o PROJETO ALVO, não este repositório. Eles não existem
# aqui por definição — é a oficina, não o produto.
alvo() {
  case "$1" in
    docs/sdlc|docs/sdlc/*|docs/incidents|docs/incidents/*|.claude/*) return 0 ;;
    *) return 1 ;;
  esac
}

# `docs/*.html` é GERADO e não versionado. Conferir se o arquivo existe daria
# verde aqui, onde ele acabou de ser gerado, e mentiria para quem clonou agora.
# O que tem que existir é a FONTE: o .json ao lado. Sem esta regra o lint
# aprovaria link para diagrama que ninguém consegue abrir.
fonte_do_html() {
  local base tipo
  base="$(basename "$1" .html)"
  for tipo in workflow architecture sequence dataflow lifecycle; do
    [ -f "docs/$base.$tipo.json" ] && return 0
  done
  return 1
}

echo "== links markdown =="
for f in $DOCS; do
  d=$(dirname "$f")
  while IFS= read -r link; do
    case "$link" in http*|mailto*|'#'*|'') continue ;; esac
    link="${link%%#*}"
    [ -z "$link" ] && continue
    alvo "$link" && continue
    # Diagrama gerado: vale a fonte, não o arquivo.
    case "$link" in
      *.html) fonte_do_html "$link" && continue ;;
    esac
    [ -e "$d/$link" ] || [ -e "$link" ] || falha "  link quebrado  $f -> $link"
  done < <(grep -oE '\]\([^)#][^)]*\)' "$f" 2>/dev/null | sed 's/^](//; s/)$//')
done

echo "== caminhos citados em crase =="
for f in $DOCS; do
  # Plano descreve o que ainda não existe — é o propósito. Vale para `plans/`
  # e para qualquer `plano-*.md`, que é como eles aparecem fora da pasta.
  case "$f" in ./plans/*|*/plano-*.md|./plano-*.md) continue ;; esac
  # Sem esta linha, `$d` carrega o valor do último documento do laço ANTERIOR e
  # todo caminho relativo é resolvido contra a pasta errada — em silêncio.
  d=$(dirname "$f")
  while IFS= read -r p; do
    p="${p%/}"
    alvo "$p" && continue
    # Caminho citado justamente para dizer que não existe mais.
    grep -qF "$p" <(grep -iE 'não existe|nao existe|removid|apagad' "$f") && continue
    # Glob é padrão, não caminho: basta que case alguma coisa.
    case "$p" in
      *'**'*) continue ;;   # glob recursivo: compgen não expande, não dá para conferir
      *'*'*) compgen -G "$p" >/dev/null 2>&1 || falha "  glob sem correspondência  $f -> $p"
             continue ;;
    esac
    [ -e "$p" ] || falha "  caminho inexistente  $f -> $p"
  done < <(grep -oE '`(agents|skills|tools|workflow|workspace|mcp|docs|design-docs|plans)/[A-Za-z0-9_./*-]*`' "$f" 2>/dev/null | tr -d '`' | sort -u)

  # Caminho RELATIVO ao próprio documento. O README de uma pasta descreve o que
  # está dentro dela e escreve `context/intro/resum.md`, sem o prefixo da pasta —
  # a checagem acima, ancorada em pasta de topo, passa direto por isso. Foi assim
  # que uma reestruturação de `design-docs/` deixou cinco linhas mentindo sem o
  # lint reclamar.
  #
  # Só conta como afirmação de caminho quando o PRIMEIRO segmento existe como
  # diretório ao lado do documento. Sem essa âncora, qualquer `a/b` em prosa
  # viraria falso positivo.
  while IFS= read -r p; do
    p="${p%/}"
    alvo "$p" && continue
    # `./algo` é invocação de comando a partir da RAIZ do repositório, não
    # caminho relativo ao documento que a cita.
    base="$d"
    case "$p" in ./*) base="." ;; esac
    [ -d "$base/${p%%/*}" ] || continue
    grep -qF "$p" <(grep -iE 'não existe|nao existe|removid|apagad' "$f") && continue
    case "$p" in
      *'*'*) ( cd "$base" && compgen -G "$p" >/dev/null 2>&1 ) \
               || falha "  glob relativo sem correspondência  $f -> $p"
             continue ;;
    esac
    [ -e "$base/$p" ] || falha "  caminho relativo inexistente  $f -> $p"
  done < <(grep -oE '`[A-Za-z0-9_.*-]+/[A-Za-z0-9_./*-]*`' "$f" 2>/dev/null | tr -d '`' | sort -u)

  # Bloco de código costuma listar a estrutura da pasta, uma linha por arquivo,
  # sem crase nenhuma. É exatamente onde o índice de um README envelhece.
  while IFS= read -r p; do
    p="${p%/}"
    alvo "$p" && continue
    base="$d"
    case "$p" in ./*) base="." ;; esac
    [ -d "$base/${p%%/*}" ] || continue
    [ -e "$base/$p" ] || falha "  caminho em bloco de código inexistente  $f -> $p"
  done < <(awk '/^```/{fence=!fence; next} fence' "$f" 2>/dev/null \
           | grep -oE '^[[:space:]]*[A-Za-z0-9_.-]+/[A-Za-z0-9_./-]*' \
           | tr -d ' ' | grep -vE '\*' | sort -u)
done

echo "== contagens declaradas =="
n_ag=$(find agents -name '*.md' -not -name 'README.md' 2>/dev/null | wc -l | tr -d ' ')
n_sk=$(find skills -name 'SKILL.md' 2>/dev/null | wc -l | tr -d ' ')
n_hk=$(find workflow/hooks -name '*.sh' 2>/dev/null | wc -l | tr -d ' ')
n_tl=$(find tools -name '*.sh' -not -name '_*' 2>/dev/null | wc -l | tr -d ' ')

# Declaração histórica é legítima: "quando esta skill foi criada, com 24 agentes".
# Só conta como divergência a que fala do estado ATUAL.
# Plano fica de fora: o numero ali e ALVO ("vamos ter 66 skills"), nao estado.
DOCS_ESTADO=$(printf '%s\n' $DOCS | grep -vE '(^|/)plano-[^/]*\.md$|^\./plans/')

confere_contagem() {
  local termo="$1" real="$2"
  grep -rnoE "[0-9]+ $termo" $DOCS_ESTADO 2>/dev/null | while IFS= read -r hit; do
    local arq num linha
    arq="${hit%%:*}"; linha=$(printf '%s' "$hit" | cut -d: -f2)
    num=$(printf '%s' "$hit" | sed "s/.*:\([0-9]*\) $termo/\1/")
    [ "$num" = "$real" ] && continue
    if sed -n "${linha}p" "$arq" 2>/dev/null | grep -qiE 'quando|antes|na época|criada|histór'; then
      continue
    fi
    printf '  contagem divergente  %s:%s diz %s %s, real é %s\n' "$arq" "$linha" "$num" "$termo" "$real"
  done
}
div_antes=$fails
c_out=$( { confere_contagem agentes "$n_ag"; confere_contagem skills "$n_sk"; \
           confere_contagem hooks "$n_hk"; confere_contagem tools "$n_tl"; } )
if [ -n "$c_out" ]; then printf '%s\n' "$c_out"; fails=$((fails + $(printf '%s\n' "$c_out" | wc -l))); fi
[ "$fails" -eq "$div_antes" ] && echo "  ok — $n_ag agentes, $n_sk skills, $n_hk hooks, $n_tl tools"

echo "== toda pasta de topo tem README e aparece no README central =="
for d in */; do
  d="${d%/}"
  case "$d" in .*|node_modules) continue ;; esac
  # O que o git ignora nao e conteudo do repositorio — e saida de ferramenta.
  # Sem isto, rodar o graphify uma vez fazia o lint exigir README para
  # `graphify-out/`, que nem versionado esta.
  git check-ignore -q "$d" 2>/dev/null && continue
  [ -f "$d/README.md" ] || falha "  sem README próprio  $d/"
  grep -q "$d/" README.md || falha "  ausente do README central  $d/"
done

echo "== agentes, skills e tools documentados =="
for a in $(find agents -name '*.md' -not -name 'README.md' -exec basename {} .md \; 2>/dev/null | sort); do
  grep -q "$a" agents/README.md 2>/dev/null || falha "  agente sem menção em agents/README.md: $a"
done
for s in $(find skills -name 'SKILL.md' 2>/dev/null); do
  dir=$(basename "$(dirname "$s")")
  nome=$(grep -m1 '^name:' "$s" | sed 's/^name: *//')
  [ "$dir" = "$nome" ] || falha "  skill com nome divergente do diretório: $dir vs $nome"
  grep -q "$dir" skills/README.md 2>/dev/null || falha "  skill ausente de skills/README.md: $dir"
done
for t in $(find tools -name '*.sh' -not -name '_*' -exec basename {} \; 2>/dev/null | sort); do
  grep -q "$t" tools/README.md 2>/dev/null || falha "  tool ausente de tools/README.md: $t"
done

echo "== flags de tool documentadas =="
for t in tools/*.sh; do
  base=$(basename "$t")
  [ "$base" = "_workspace.sh" ] && continue
  for fl in $(grep -oE '^[[:space:]]+--[a-z-]+\)' "$t" 2>/dev/null | tr -d ' )' | sort -u); do
    grep -q -- "$fl" tools/README.md || falha "  flag não documentada  $base $fl"
  done
done

echo "== arquivos que nenhum documento alcança =="
# "Alcança" inclui documentar o DIRETÓRIO: um README que descreve `context/*/img/`
# cobre o que está lá dentro. Exigir menção a cada arquivo transformaria o lint
# em ruído e ele seria desligado.
for f in $(git ls-files '*.sh' '*.png' '*.tsv' 2>/dev/null \
           | grep -vE '^(prompts|workflow/hooks)/' | sort); do
  base=$(basename "$f")
  if grep -rqlF "$base" $DOCS 2>/dev/null; then continue; fi
  dir=$(dirname "$f"); coberto=0
  while [ "$dir" != "." ] && [ "$dir" != "/" ]; do
    grep -rqlF "$dir" $DOCS 2>/dev/null && { coberto=1; break; }
    dir=$(dirname "$dir")
  done
  [ "$coberto" -eq 1 ] || falha "  órfão  $f"
done

echo
if [ "$fails" -gt 0 ]; then
  printf '%s divergência(s) entre documentação e repositório.\n' "$fails"
  exit 1
fi
echo "documentação confere com o repositório."
exit 0
