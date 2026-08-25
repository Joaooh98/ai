# stack — especialistas por tecnologia

Skills de **stack específica**, acionadas pelos agentes de build quando o projeto usa
aquela tecnologia. Diferente das outras skills do repositório, que descrevem *fluxo*
(`sdlc-*`) ou *disciplina* (`practices/`), estas descrevem **como se escreve bem** numa
tecnologia concreta.

## Por que existem

O `sdlc-build` roteava todo item de trabalho para o engenheiro genérico. Um `frontend-engineer`
sem contexto de Next.js resolve o problema como qualquer outro framework resolveria — e perde
o que é idiomático. Estas skills entram como conhecimento de stack, sem trocar o agente.

## Ligação

Nenhuma delas é carregada sozinha. Cada uma é referenciada no frontmatter `skills:` do agente
que a usa, e o `install.sh` valida que a referência resolve:

| Agente | Skills de stack |
|---|---|
| `frontend-engineer` | `typescript-pro`, `react-expert`, `nextjs-developer` |
| `mobile-engineer` | `typescript-pro`, `react-native-expert` |

## Procedência

Todas vêm de [Jeffallan/claude-skills](https://github.com/Jeffallan/claude-skills), licença
MIT, com a autoria preservada no frontmatter de cada `SKILL.md`. Foram auditadas antes da
adoção — markdown puro, sem hooks, sem scripts, sem chamada de rede. O laudo e o critério
estão em [`design-docs/plano-skills-comunidade.md`](../../design-docs/plano-skills-comunidade.md).

## Por que só estas quatro

A seleção seguiu a stack **real** dos projetos cadastrados em `workspace/`, não o catálogo
do repositório de origem:

- **Next.js 14 e 15, React 18 e 19** — `crm_pro`, `solve-report`, `solve-checkout-front`,
  `dafe-report-front`, `gestor-clinicas-next`
- **React Native 0.77** — `dafepay-app`, que até aqui só tinha o `mobile-engineer` genérico

O `spring-boot-engineer` do mesmo repositório foi **descartado**: a base é Quarkus (13 `pom.xml`
com Quarkus, zero com Spring Boot), e já existem `quarkus-senior-developer` e
`fullstack-quarkus-expert`, ambos mais específicos. Absorver uma skill de Spring injetaria
idioma errado.

Ao adicionar outra skill de stack aqui: rode `./agents/install.sh --check` antes de commitar —
nome duplicado derruba a instalação da equipe inteira, não só a skill nova.
