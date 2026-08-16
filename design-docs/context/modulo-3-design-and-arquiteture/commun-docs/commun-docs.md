## Encadeamento entre documentos
Documentos de design e arquitetura formam uma cadeia de abstração que começa no problema de produto e termina na implementação e no registro das decisões. Retomando a noção de níveis de abstração já estabelecida, a diferença aqui é a pergunta que cada artefato responde: o PRD descreve o problema e o valor esperado, o HLD organiza a solução em alto nível, o Feature Design Doc detalha uma feature específica, o LLD aproxima a solução do código, a RFC delibera alternativas e o ADR registra a decisão tomada. Nem todo projeto precisa de todos esses artefatos; a adequação depende do porte da mudança, do risco técnico e da necessidade de alinhamento entre áreas.

## HLD
HLD, ou High Level Design, descreve como o sistema é estruturado sem entrar em detalhes finos de implementação. Ele existe para transformar contexto de produto em visão técnica compartilhada, mostrando componentes, responsabilidades, integrações e limites da solução. Seu papel costuma aparecer depois do PRD, quando já existe clareza sobre o problema e é preciso discutir a forma geral da solução. Se a mudança for pequena, esse nível pode ser condensado ou até absorvido por um documento mais específico.

## Feature Design Doc e FRD
Feature Design Doc especifica como uma feature ou módulo será implementado, com foco maior que o HLD e menor que o LLD. Ele responde perguntas como escopo técnico da feature, fluxo principal, impactos no sistema e escolhas necessárias para entregar aquele recurso. A sigla FRD aparece em muitas organizações como nomenclatura legada, próxima desse mesmo papel documental, com herança de uma abordagem mais centrada em requisitos funcionais. O nome importa menos que a função: tornar explícito como uma parte específica do sistema será construída.

## Quando o Feature Design Doc pode bastar
Uma feature pequena ou isolada nem sempre exige um HLD completo antes do detalhamento. Nesses casos, o próprio Feature Design Doc pode concentrar o nível de decisão necessário para alinhar implementação, dependências e impacto técnico. Quando a mudança afeta múltiplos módulos, envolve arquitetura mais ampla ou exige coordenação entre times, faz sentido subir um nível e produzir antes um artefato mais high level. A escolha do documento, portanto, é contextual e não ritualística.

## LLD
LLD, ou Low Level Design, aproxima o design da implementação concreta. Ele detalha endpoints, contratos de comunicação, campos de API, patterns adotados e outras decisões que já orientam diretamente o código. A diferença para o Feature Design Doc está no grau de precisão: o documento de feature pode dizer que haverá determinados endpoints, enquanto o LLD define quais endpoints existirão e como seus contratos serão estruturados. Por isso, o LLD é útil quando a equipe precisa reduzir ambiguidade técnica antes de implementar.

## RFC
RFC, ou Request for Comments, é um documento de deliberação técnica. Ele circula uma proposta para receber comentários, objeções e alternativas antes da decisão final, sendo especialmente comum em projetos open source e em mudanças com impacto relevante, como novas features ou breaking changes. Seu valor está em expor o raciocínio enquanto a decisão ainda está aberta, permitindo revisão coletiva em vez de validação tardia. RFC não registra a decisão definitiva; ela organiza a discussão que antecede essa decisão.

## ADR
ADR, ou Architecture Decision Record, registra uma decisão arquitetural já tomada, junto com sua justificativa e seu contexto. Diferentemente da RFC, que é deliberativa, o ADR é o artefato de memória técnica: ele responde por que uma tecnologia, stack, banco de dados ou abordagem foi escolhida e em que condições essa escolha faz sentido. Um ADR pode ficar ativo, ser substituído ou tornar-se inativo quando a decisão deixa de valer. Esse histórico evita que o time precise redescobrir continuamente o motivo das escolhas anteriores.

## RFC e ADR na linha do tempo
A diferença central entre RFC e ADR é temporal e funcional. A RFC aparece antes, quando ainda há debate sobre a melhor alternativa; o ADR aparece depois, quando a organização precisa registrar a decisão que venceu esse debate. Em um fluxo maduro, a RFC captura argumentos e contrapontos, e o ADR consolida a decisão técnica de forma clara e sucinta. Nem toda decisão exige os dois documentos, mas confundir discussão com registro costuma gerar perda de contexto.

## Tabela comparativa
| Documento | Pergunta principal | Nível de detalhe | Momento de uso |
|---|---|---|---|
| PRD | Qual problema de produto precisa ser resolvido? | Baixo detalhe técnico | Antes do desenho técnico |
| HLD | Como a solução se organiza em alto nível? | Alto nível técnico | Após clareza de produto e antes do detalhamento da feature |
| Feature Design Doc / FRD | Como uma feature ou módulo será implementado? | Detalhe intermediário | Quando o escopo da feature já está definido |
| LLD | Como a implementação será estruturada concretamente? | Alto detalhe técnico | Próximo da codificação |
| RFC | Quais alternativas estão em discussão antes da decisão? | Variável, orientado a debate | Antes da decisão técnica |
| ADR | Qual decisão arquitetural foi tomada e por quê? | Registro objetivo da decisão | Depois da decisão técnica |

## Aplicação no mesmo problema ao longo da cadeia
Retomando o mesmo problema de produto já contextualizado anteriormente, o PRD define o objetivo e as restrições do recurso. O HLD transforma isso em visão estrutural da solução; o Feature Design Doc desce para a implementação daquela feature específica; o LLD fixa contratos, endpoints e detalhes executáveis; se houver dúvida relevante entre alternativas, a discussão pode passar por uma RFC; quando a escolha é feita, ela deve ser registrada em ADR. O valor do ecossistema documental está justamente nesse encadeamento: cada artefato responde uma pergunta diferente sem competir com os demais.