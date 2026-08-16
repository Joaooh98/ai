## Deep research como navegação longa da IA
Deep research é um modo de trabalho em que a IA não responde apenas com conhecimento imediato do modelo: ela navega por fontes, cruza informações e produz um documento longo de pesquisa. Isso importa quando a equipe precisa especificar uma feature sem depender apenas de memória, intuição ou conhecimento parcial do tema. No exemplo do rate limiter em Go, a pesquisa vira um insumo técnico para evitar que o detalhamento da feature seja escrito no escuro.

## Pesquisa técnica como insumo para documentos
Um documento extenso de pesquisa não é o objetivo final; ele funciona como contexto reutilizável para gerar artefatos posteriores com mais qualidade. Quando a IA recebe esse insumo, ela tende a produzir drafts mais completos e menos genéricos para documentos de design. Retomando o cenário do rate limiting, a pesquisa ajuda a sustentar decisões sobre estratégias, bibliotecas, restrições e pontos de atenção antes de transformar isso em especificação.

## Limite prático de modelos para documentos longos
Modelos diferentes se comportam de forma diferente ao gerar arquivos extensos. Em alguns casos, o Gemini produz documentos maiores e mais completos; em outros, o ChatGPT atende bem, e outras ferramentas como Claude também podem servir. A decisão prática não é ideológica: escolha o modelo que sustenta melhor volume, completude e consistência para o tipo de pesquisa que você precisa gerar.

## O erro mais comum ao pedir deep research
O problema mais frequente não está na ferramenta, mas na formulação do pedido. Pedir “faça uma pesquisa sobre X” costuma gerar um resultado amplo demais, superficial ou desalinhado com o uso real do documento. Deep research precisa de contexto explícito sobre problema, ambiente, profundidade, tecnologias relevantes e resultado esperado.

## Prompt em duas etapas
Um fluxo mais robusto separa a pesquisa em duas fases. Na primeira, a IA conduz uma entrevista curta e monta um resumo preparatório; na segunda, a pesquisa longa é disparada com base nesse resumo já calibrado. Essa divisão melhora a qualidade do resultado porque a navegação longa parte de um briefing técnico mais preciso, em vez de um pedido genérico.

## Resumo preparatório antes da pesquisa longa
O resumo preparatório consolida os campos que realmente orientam a pesquisa: tema técnico, motivação, foco principal, contexto de uso, profundidade desejada, stack relevante, necessidade de exemplos reais e resultado esperado. Esse artefato reduz ambiguidade e força o autor a explicitar o que quer aprender. Quando a pesquisa começa sem esse alinhamento, a IA tende a gastar esforço em tópicos irrelevantes ou a deixar lacunas justamente nas decisões que mais importam.

## Entrevista guiada aplicada à pesquisa
A entrevista guiada, já usada antes para estruturar documentos, aqui aparece com outra função: preparar a pesquisa, não gerar o documento final. A IA faz uma pergunta por vez e usa as respostas naturalmente para compor o briefing. No exemplo, perguntas sobre motivação, contexto HTTP em microserviços, profundidade e uso de Redis refinam o escopo antes de iniciar a busca longa.

## Como disparar a pesquisa depois da preparação
Depois que o resumo preparatório está pronto, o disparo da pesquisa pode ser simples: pedir que a IA realize a pesquisa com base naqueles aspectos. O ganho não está na sofisticação do comando final, mas na qualidade do contexto acumulado antes dele. Em termos operacionais, a etapa longa pode levar dezenas de minutos, então faz sentido tratá-la como um job de coleta e síntese, não como uma resposta instantânea.

## Por que não forçar um template na primeira fase
Na fase de deep research, a IA nem sempre respeita bem um esqueleto rígido de saída. Por isso, é mais eficaz deixar a pesquisa sair em formato livre e só depois adaptar o conteúdo para um template próprio. Essa escolha separa duas preocupações diferentes: primeiro obter conhecimento amplo e útil; depois reorganizar esse conhecimento para consumo recorrente.

## Segunda etapa: adaptar a pesquisa para formato reutilizável
Uma pesquisa de 27 páginas pode ser excelente como base técnica e ainda assim ruim como insumo operacional para o restante do fluxo. A segunda etapa existe para converter esse conteúdo em uma estrutura mais compatível com os templates usados pelo time, inclusive para gerar feature design docs depois. O valor está em transformar pesquisa bruta em contexto estruturado, pronto para alimentar novos prompts e novos documentos.
