## Entrevista guiada para gerar um HLD
Um prompt de HLD pode operar como uma entrevista guiada: em vez de pedir um texto livre, ele conduz a coleta de contexto por perguntas estruturadas e transforma as respostas em um draft inicial. Isso reduz o esforço de começar do zero e força a cobertura de seções que costumam ser esquecidas, como riscos, observabilidade e interfaces públicas. O valor não está em automatizar a arquitetura inteira, mas em organizar a extração de contexto técnico de forma repetível.

## PRD e documentos complementares como insumo
Retomando o encadeamento já estabelecido, o PRD entra aqui como insumo para que o HLD não nasça apenas de respostas improvisadas durante a entrevista. Quando o prompt recebe também documentos técnicos, anotações de reunião ou pesquisa prévia, o draft sai mais próximo da realidade do problema e exige menos preenchimento manual. A qualidade do resultado depende menos da eloquência do prompt e mais da densidade do contexto anexado.

## Template reutilizável
Um template reutilizável fixa o formato esperado do documento antes da geração, com seções como contexto, arquitetura geral, componentes, fluxo de requisição, modelo de dados, interfaces públicas, escalabilidade, segurança, observabilidade e riscos. Isso evita que a IA produza texto solto ou reorganize o HLD de maneira inconsistente a cada execução. O template também facilita revisão humana, comparação entre documentos e adaptação ao padrão interno do time.

## Defaults inteligentes no prompt
Defaults inteligentes são valores ou decisões assumidas pelo prompt quando a informação ainda não foi fornecida explicitamente, desde que isso seja feito de forma controlada. Eles existem para reduzir fricção na geração inicial e impedir que o processo pare por falta de detalhes menores. O uso correto desses defaults acelera o draft, mas exige revisão posterior porque uma suposição plausível ainda pode estar errada para a empresa ou para a feature.

## JSON como formato operacional
JSON funciona como formato operacional para o HLD gerado por IA porque transforma seções do documento em uma estrutura previsível e manipulável por ferramentas. Em vez de depender apenas de texto corrido, o time pode validar campos, reaproveitar blocos, versionar estruturas e até alimentar outros fluxos automatizados. O objetivo não é substituir a leitura humana, mas tornar a geração mais consistente e integrável.

## Checagem de consistência entre seções
Checagem de consistência é a etapa em que o prompt verifica se as partes do HLD não se contradizem antes de finalizar o draft. Se a arquitetura geral sugere um componente centralizado, por exemplo, o fluxo principal, os riscos e as preocupações de escalabilidade precisam refletir essa escolha. Essa validação evita documentos formalmente bonitos, mas internamente incoerentes.

## IA como aceleradora, não autora única
A IA acelera a produção do HLD porque ajuda a estruturar perguntas, preencher o esqueleto e expandir partes técnicas recorrentes. Ainda assim, ela não gera sozinha um documento confiável para contextos específicos de empresa, domínio e funcionalidade. O papel humano continua sendo decidir, corrigir, complementar e remover generalizações inadequadas.

## Adaptação ao fluxo de trabalho do time
O prompt não deve ser tratado como peça fixa; ele precisa ser modificado conforme o workflow do time, o tipo de projeto e o nível de documentação já existente. Em alguns contextos, a entrevista será o ponto de partida; em outros, o processo começa com PRD, pesquisa técnica e um template já preenchido parcialmente. Adaptar o prompt ao processo real reduz atrito e aumenta a utilidade do draft gerado.

## Aplicação prática no exemplo de rate limiting
Retomando o HLD de rate limiting já conhecido, a nova camada aqui não é redesenhar a solução, mas reconstruí-la por meio de insumos, perguntas e um esqueleto de documento. O prompt pode pedir objetivos técnicos, componentes, fluxo principal, riscos e preocupações transversais, usando aquele documento como referência estrutural. Com isso, o time passa de escrita manual integral para geração assistida de um primeiro rascunho revisável.

## Workflow operacional de geração
O fluxo mais útil é: reunir insumos, executar a entrevista guiada, gerar o draft no template escolhido, rodar checagem de consistência e revisar manualmente. Esse processo reduz a fricção de começar do zero sem terceirizar o raciocínio arquitetural. O resultado esperado não é um documento final perfeito, mas um draft inicial mais mastigado e mais barato de evoluir.

https://app.notion.com/p/Prompt-para-gera-o-de-um-HLD-fcb11da75aff8281937901fcb2f9054f