# Diagramas

Dois diagramas interativos, gerados pela skill [`archify`](https://github.com/) a partir dos
`.json` ao lado. Cada `.html` é autocontido: abre direto no navegador, sem servidor e sem rede.

| Arquivo | Responde |
|---|---|
| [`arquitetura.html`](arquitetura.html) | **Como o repositório é feito** — o que mora na oficina, o que fica no projeto alvo, e a âncora que liga os dois |
| [`fluxo.html`](fluxo.html) | **Como se usa** — do cadastro do projeto até produção, com o portão, e o desvio de emergência |

Abrir:

```bash
xdg-open docs/arquitetura.html
xdg-open docs/fluxo.html
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
```

O renderer **falha** em vez de gerar um diagrama ruim: sobreposição de nó, label mais largo que a
caixa, aresta cruzando nó não relacionado, legenda invadida. A mensagem de erro traz a correção
com coordenada — aplique em vez de chutar offset.

Conferir sem abrir o navegador:

```bash
node $ARCHIFY/bin/archify.mjs validate workflow docs/fluxo.workflow.json
node $ARCHIFY/bin/archify.mjs check    docs/fluxo.html
```

## Por que aqui e não em docs/sdlc/

`docs/sdlc/` é o contrato de artefatos que os agentes escrevem **nos projetos alvo**. Estes
diagramas descrevem esta oficina, não um ciclo de trabalho — por isso ficam na raiz de `docs/`,
fora do caminho que os hooks observam.
