# Diagramas

Três diagramas interativos, gerados pela skill `archify` a partir dos `.json` ao lado. Cada
`.html` é autocontido: abre direto no navegador, sem servidor e sem rede.

| Diagrama | Responde | Fonte |
|---|---|---|
| [`arquitetura.html`](arquitetura.html) | **Como o repositório é feito** — o que mora na oficina, o que fica no projeto alvo, e a âncora que liga os dois | `arquitetura.architecture.json` |
| [`fluxo.html`](fluxo.html) | **Como se usa** — do cadastro do projeto até produção, com o portão e o desvio de emergência | `fluxo.workflow.json` |
| [`sdlc.html`](sdlc.html) | **O que acontece dentro de uma invocação** — ler o disco, despachar a onda, avaliar o portão, e o caminho da reprovação | `sdlc.workflow.json` |

Os três começam onde o anterior para: a arquitetura mostra **onde as peças moram**, o fluxo mostra
**a jornada do operador**, e o `/sdlc` abre **uma única invocação** por dentro.

## A regra: o `.html` é derivado, o `.json` é a fonte

Nunca edite o `.html`. Ele é saída. Mudou a estrutura da equipe, edite o `.json` e regere — a
seção abaixo tem os comandos.

Essa regra existe por um caso concreto. Havia um `sdlc-dark.png` solto na raiz, export de um
diagrama sem `.json` correspondente. Ele não podia ser regerado, só refeito — e, pior, tinha
envelhecido: mostrava o portão como `artifact-lint.sh` sozinho, quando os Portões 3 e 4 passaram
a exigir também o `meta-check.sh`. **Diagrama que contradiz o código é pior que diagrama nenhum,
porque é lido como verdade.** O arquivo foi apagado e substituído por `sdlc.workflow.json` +
`sdlc.html`, que agora se regeneram como os outros.

Abrir:

```bash
xdg-open docs/arquitetura.html
xdg-open docs/fluxo.html
xdg-open docs/sdlc.html
```

## O que dá para fazer neles

- **Alternar tema** — o botão no canto superior direito troca claro/escuro e a escolha persiste
- **Exportar** — PNG na área de transferência, ou baixar PNG/JPEG/WebP em até 4× a resolução
- **SVG de tema duplo** — segue o `prefers-color-scheme` de quem embute, ideal para colar num README

## Regerar depois de mudar o repositório

A fonte é o `.json`; o `.html` é derivado. Editou a estrutura da equipe, regere:

```bash
ARCHIFY=~/.claude/skills/archify
node $ARCHIFY/bin/archify.mjs render architecture docs/arquitetura.architecture.json docs/arquitetura.html
node $ARCHIFY/bin/archify.mjs render workflow     docs/fluxo.workflow.json           docs/fluxo.html
node $ARCHIFY/bin/archify.mjs render workflow     docs/sdlc.workflow.json            docs/sdlc.html
```

O renderer **falha** em vez de gerar um diagrama ruim: sobreposição de nó, label mais largo que a
caixa, aresta cruzando nó não relacionado, legenda invadida. A mensagem de erro traz a correção
com coordenada — aplique em vez de chutar offset.

Conferir sem abrir o navegador:

```bash
node $ARCHIFY/bin/archify.mjs validate workflow docs/fluxo.workflow.json
node $ARCHIFY/bin/archify.mjs check    docs/fluxo.html
```

`validate` sai com erro **e a coordenada da correção**: `labelDy +11`, `labelAt [365, 415]`,
"mova para outra coluna". Aplique o que ele diz; chutar offset custa mais rodadas que ler.

Dois erros aparecem com frequência ao acrescentar nó, e a saída para eles é a mesma:

- **"Nodes X e Y a menos de 8px na raia Z"** — dois nós vizinhos na mesma raia não cabem lado a
  lado. Ou espalhe as colunas, ou junte os dois num nó só. Foi o que aconteceu ao tentar separar
  `artifact-lint` e `meta-check` em duas caixas: viraram um portão com os dois no sublabel.
- **"Edge X -> Y muito curta"** — mesma causa. Rotear por `bottom-channel` resolve sem mexer no
  layout.

## Por que aqui e não em docs/sdlc/

`docs/sdlc/` é o contrato de artefatos que os agentes escrevem **nos projetos alvo**. Estes
diagramas descrevem esta oficina, não um ciclo de trabalho — por isso ficam na raiz de `docs/`,
fora do caminho que os hooks observam.
