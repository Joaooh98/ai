## Rational Unified Process
RUP é um processo de desenvolvimento criado pela Rational Software e depois incorporado pela IBM para oferecer uma alternativa mais iterativa ao modelo sequencial já conhecido. A mudança central não foi abandonar documentação, mas reorganizá-la dentro de um fluxo com ciclos menores e pontos de revisão mais frequentes. Isso torna o projeto menos rígido que o waterfall, sem abrir mão de forte controle sobre artefatos, planejamento e coordenação.

## Disciplinas organizadas no processo
O RUP estrutura o desenvolvimento em disciplinas como levantamento de requisitos, análise, design, implementação, teste e gerenciamento de configuração. A função dessa divisão é modularizar o trabalho e deixar explícito o que precisa ser produzido, acompanhado e validado ao longo do projeto. Retomando o cenário de registrar decisões do projeto, esse contexto deixa de ficar preso a um único pacote documental inicial e passa a ser distribuído entre disciplinas que evoluem ao longo das iterações.

## Iteração como mecanismo de feedback
As fases do RUP se repetem de forma iterativa, o que cria feedback loops mais curtos do que em processos puramente lineares. Em vez de documentar por longos períodos para só então implementar, o time revisa continuamente o que foi definido, construído e aprendido. O ganho prático é descobrir problemas antes, quando o custo de ajuste ainda é menor.

## Inception
Inception é a fase em que o projeto define escopo, objetivos e viabilidade de negócio. Ela existe para responder se vale a pena iniciar o esforço e qual problema o sistema realmente pretende resolver. Sem essa base, as iterações seguintes podem ser eficientes na execução, mas desalinhadas quanto ao propósito.

## Elaboration
Elaboration aprofunda o projeto ao detalhar a arquitetura, identificar riscos e refinar os requisitos principais. É nessa fase que ambiguidades começam a aparecer com mais clareza, porque decisões de mais baixo nível testam a consistência do escopo inicial. Quando a elaboração revela contradições, o projeto precisa decidir se ajusta a arquitetura ou se revisa o próprio escopo.

## Construction
Construction corresponde ao desenvolvimento incremental do produto com base na arquitetura já aprovada. O sistema passa a ser construído em partes progressivas, em vez de esperar uma especificação total e imutável antes de começar a codificação. Isso permite entregar blocos funcionais coerentes com as decisões arquiteturais tomadas anteriormente.

## Transition
Transition cobre a entrega do sistema, o treinamento dos usuários e a correção de falhas observadas na passagem para uso real. Essa fase existe porque software pronto para desenvolvimento interno ainda não está necessariamente pronto para adoção operacional. A transição fecha o ciclo técnico com preocupações de implantação, adaptação do usuário e estabilização.

## Casos de uso como eixo dos requisitos
O RUP usa fortemente casos de uso para modelar requisitos a partir da interação do usuário com o sistema. Se o usuário precisa cadastrar um novo produto para disponibilizá-lo em estoque e verificar esse estoque, esse fluxo vira um caso de uso documentado e implementável. Quando um caso de uso fica pronto, o projeto não ganha apenas texto aprovado: ganha um pedaço funcional do sistema alinhado ao comportamento esperado.

## Arquitetura centralizada
A arquitetura ocupa posição central no RUP porque o processo busca consolidar uma base técnica sólida antes de ampliar a construção do produto. Isso reduz o risco de cada iteração seguir em direções incompatíveis e ajuda a manter coerência entre decisões locais e estrutura global do sistema. Retomando o contexto de decisões do projeto, a arquitetura passa a ser o ponto de referência que organiza o que cada iteração pode construir com segurança.

## Papéis definidos
O RUP explicita papéis como analistas, desenvolvedores e testadores para distribuir responsabilidades com clareza. Em especial, o papel do analista de sistemas concentra atividades de conversar com o cliente, estruturar fluxos, produzir diagramas e preparar insumos para implementação. Essa separação melhora coordenação em ambientes mais formais, mas também aumenta dependências entre funções e etapas.

## Gerenciamento de configuração e documentação forte
Gerenciamento de configuração integra o conjunto de disciplinas para controlar versões, mudanças e consistência dos artefatos do projeto. Esse controle combina com a documentação forte do RUP, na qual o avanço depende de registros formais e planejamento detalhado. O benefício é maior rastreabilidade; o custo é mais burocracia e maior esforço operacional.

## Vantagens e limitações em relação ao waterfall
Em comparação com o waterfall, o RUP permite revisões e ajustes a cada iteração, reduz riscos por validação progressiva e melhora a comunicação entre times e stakeholders. Ainda assim, ele continua mais complexo de gerenciar, exige muita documentação e pode ser caro demais para projetos pequenos. A lição importante dessa transição histórica é que o problema não era documentar ou não documentar, mas encontrar um equilíbrio entre documentação, iteração e coordenação.