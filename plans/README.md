# Plans — decidido, ainda não construído

Esta pasta guarda **uma coisa só**: trabalho que já foi analisado a ponto de ser executável, e
que ainda não foi feito. Nada aqui está no ar.

Ela existe porque análise sem registro apodrece. Uma decisão tomada em conversa — com a medição
que a sustenta — se perde na semana seguinte, e a próxima sessão refaz o mesmo estudo para chegar
à mesma conclusão. Um plano escrito é a diferença entre "acho que a gente já discutiu isso" e
abrir o arquivo.

## O que entra

Um plano só entra quando responde às seis perguntas abaixo. Faltando alguma, não é plano — é
vontade, e vontade fica na cabeça de quem teve.

| Seção | Obrigatória | O que tem que estar lá |
|---|---|---|
| **Problema** | sim | O que quebra hoje. Não "seria bom ter" |
| **Evidência** | sim | Número medido, saída de comando, caminho de arquivo. Sem isso o plano é palpite bem escrito |
| **Proposta** | sim | O que se constrói, concretamente |
| **Custo** | sim | Esforço, dependência nova, o que passa a precisar de manutenção |
| **Risco** | sim | O que pode dar errado, e o que já sabemos que não resolve |
| **Status** | sim | `proposto` · `aceito` · `em andamento` · `descartado` |

Plano `descartado` **fica no repositório**, com o motivo. É o registro mais barato que existe
contra refazer a mesma análise para chegar à mesma recusa.

## O que não entra

- **Bug** — isso é trabalho, vai para o fluxo ou para o rastreador.
- **Trabalho em andamento** — se já tem código, o lugar é um PR, não aqui.
- **Ideia sem medição** — volte quando tiver o número.
- **Documentação do que já existe** — isso vive no README da pasta que descreve.

## Como um plano sai daqui

Quando for executado, o plano vira PR e o `Status` passa a `em andamento` com o link. Entregue,
o conteúdo migra para a documentação da pasta correspondente — `tools/README.md`, `mcp/README.md`,
o README central — e o arquivo de plano é **apagado**. Plano entregue que fica aqui vira
documentação duplicada, e documentação duplicada diverge.

## Índice

| Plano | Sobre | Status |
|---|---|---|
| [`mcp-pre-setado.md`](mcp-pre-setado.md) | Servidores MCP sugeridos por stack detectada, em vez de perguntados do zero | proposto |
| [`grafo-de-codigo.md`](grafo-de-codigo.md) | Grafo de símbolos para os agentes pararem de afirmar por inferência | proposto |
