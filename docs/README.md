# Diagramas

Quatro diagramas interativos, gerados pela skill `archify` a partir dos `.json` ao lado. Cada
`.html` é autocontido: abre direto no navegador, sem servidor e sem rede.

**Leia nesta ordem.** Cada um responde uma pergunta, e a ordem importa: quem começa pela
arquitetura vê um monte de pasta sem entender para que serve.

| # | Diagrama | Pergunta que responde | Fonte |
|---|---|---|---|
| 1 | [`porque.html`](porque.html) | **Por quê?** O mesmo pedido percorrendo os dois caminhos — com e sem a equipe | `porque.workflow.json` |
| 2 | [`fluxo.html`](fluxo.html) | **Como eu uso?** Do cadastro do projeto até produção, com o portão e o desvio de emergência | `fluxo.workflow.json` |
| 3 | [`sdlc.html`](sdlc.html) | **O que acontece quando eu digito `/sdlc`?** Ler o disco, despachar a onda, avaliar o portão | `sdlc.workflow.json` |
| 4 | [`arquitetura.html`](arquitetura.html) | **Onde isso tudo mora?** O que fica na oficina, o que fica no projeto alvo, e a âncora | `arquitetura.architecture.json` |

## Os `.html` não são versionados

`docs/*.html` está no `.gitignore`. **Gere antes de abrir, uma vez por clone:**

```bash
docs/gerar.sh            # os quatro
docs/gerar.sh porque     # um só
```

Não é preciosismo. Cada `.html` é autocontido de propósito — abre sem servidor e sem rede — e
para isso embute o runtime inteiro do `archify`: CSS, JS e o botão de tema. Versionar os quatro
colocava **2162 linhas duplicadas** no repositório, e recolocava a cada regeração. Medido pelo
SonarCloud: 64% de duplicação em código novo, sendo que os scripts escritos à mão tinham **zero**.

A escolha foi apagar a duplicação, não escondê-la de quem mede. A fonte é o `.json`, o `.html` se
refaz em segundos, e a regra "nunca edite o `.html`" deixa de depender de disciplina: o arquivo
nem está no git.

Requer a skill `archify` em `~/.claude/skills/archify`, ou `ARCHIFY=/caminho docs/gerar.sh`.

### O caso que ensinou a regra

Havia um `sdlc-dark.png` solto na raiz, export de um diagrama sem `.json` correspondente. Ele não podia ser regerado, só refeito — e, pior, tinha
envelhecido: mostrava o portão como `artifact-lint.sh` sozinho, quando os Portões 3 e 4 passaram
a exigir também o `meta-check.sh`. **Diagrama que contradiz o código é pior que diagrama nenhum,
porque é lido como verdade.** O arquivo foi apagado e substituído por `sdlc.workflow.json` +
`sdlc.html`, que agora se regeneram como os outros.

Abrir, depois de gerar:

```bash
xdg-open docs/porque.html
```

## O que dá para fazer neles

- **Alternar tema** — o botão no canto superior direito troca claro/escuro e a escolha persiste
- **Exportar** — PNG na área de transferência, ou baixar PNG/JPEG/WebP em até 4× a resolução
- **SVG de tema duplo** — segue o `prefers-color-scheme` de quem embute, ideal para colar num README

## Regerar depois de mudar o repositório

Editou a estrutura da equipe, edite o `.json` e regere:

```bash
docs/gerar.sh
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
