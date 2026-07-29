---
name: arch-conformance
description: Mantem o codigo fiel a arquitetura decidida sem parar a entrega - destila as regras verificaveis da arquitetura, congela a divida que ja existe com dono e prazo, bloqueia violacao nova e paga a divida antiga por orcamento. Use quando a arquitetura tem que valer a risca mas a entrega nao pode parar, e como rotina recorrente de conformidade.
argument-hint: [quantos itens de dívida pagar nesta rodada, ou vazio para 1]
disable-model-invocation: true
allowed-tools: Bash(${CLAUDE_PROJECT_DIR}/.claude/ai-toolkit/tools/arch-conformance.sh) Bash(${CLAUDE_PROJECT_DIR}/.claude/ai-toolkit/tools/arch-conformance.sh *) Bash(${CLAUDE_PROJECT_DIR}/.claude/ai-toolkit/tools/*.sh) Bash(${CLAUDE_PROJECT_DIR}/.claude/ai-toolkit/tools/*.sh *) Bash(git *)
---

# Conformidade arquitetural

Orçamento desta rodada: **$ARGUMENTS** (vazio = 1 item de dívida)

## Estado, lido do disco

!`${CLAUDE_PROJECT_DIR}/.claude/ai-toolkit/tools/arch-conformance.sh --resumo`

## A tensão que esta rotina resolve

> "A arquitetura tem que ser seguida à risca, mas eu não posso comprometer a entrega."

As duas coisas só brigam se você tentar cobrar tudo de uma vez. Cobrar conformidade total num
portão para uma base que já divergiu é parar a entrega; não cobrar nada é a divergência crescer
até refatorar ficar mais caro que reescrever.

A saída é uma **catraca**, e ela vale por uma assimetria só:

| Situação | O que acontece |
|---|---|
| Violação **nova**, que esta mudança introduziu | **Bloqueia.** É barata agora e cara depois. |
| Violação **antiga**, registrada no ledger | **Não bloqueia.** É dívida com dono e prazo. |
| Violação antiga que **desapareceu** | Sai do ledger, e volta a bloquear se reaparecer. |
| Violação nova que **você decidiu aceitar** | Isenção explícita: dono, prazo, motivo. Vence e bloqueia. |

O número de violações só pode cair. A entrega nunca para por dívida que já estava lá — e a
arquitetura passa a valer à risca **daqui para frente**, que é o único lugar onde ainda dá para
escolher.

**O que esta rotina nunca faz:** baixar a barra. Se uma violação incomoda, o caminho é corrigir o
código ou registrar isenção com prazo. Editar a regra para o achado desaparecer é a única forma de
transformar esta rotina em teatro.

## O estado decide a onda

Não decore a ordem — leia o resumo acima e escolha:

| O resumo diz | Onda |
|---|---|
| `NAO CONFIGURADO` | **A — destilar** as regras da arquitetura decidida |
| `LEDGER AUSENTE` | **B — baselinar** a dívida que já existe |
| `REGRAS NAO CALIBRADAS` (exit 2) | **A**, corrigindo os alvos: nada foi verificado |
| `NOVAS: n` com n > 0 | **C — devolver** ao autor da mudança |
| `VEREDITO: conforme` | **D — pagar** a dívida pelo orçamento |

Rodar mais de uma onda por invocação é permitido quando a anterior fecha limpa (destilar e
baselinar, tipicamente, acontecem juntas na primeira vez).

---

## Onda A — destilar as regras

Dono: **`solution-architect`**. Saída: `docs/sdlc/02-design/arch-rules.tsv`, ou `docs/arq/arch-rules.tsv`
em projeto que já documentava arquitetura antes da equipe chegar.

A entrada **não é a sua opinião sobre boa arquitetura** — é o que este projeto já decidiu:
`docs/sdlc/02-design/architecture.md` e os ADRs, ou o padrão que o projeto mantém fora do fluxo
(`docs/arq/`, `CLAUDE.md`, `AGENTS.md`). Toda regra cita a seção de origem, e regra sem origem não
entra: ela é preferência sua disfarçada de arquitetura, e vai ser discutida em vez de corrigida.

Formato — TSV, seis campos, uma regra por linha:

```
id <TAB> tipo <TAB> alvo <TAB> argumento <TAB> severidade <TAB> origem
```

| Campo | O que é |
|---|---|
| `id` | Estável e curto (`UC-NO-INFRA`). Entra no ledger — mudar o id órfã a dívida. |
| `tipo` | `proibe-conteudo` · `exige-conteudo` · `limita-publico` · `exige-par` |
| `alvo` | ERE casada contra o **caminho** relativo do arquivo |
| `argumento` | ERE de conteúdo; ou o limite (`limita-publico`); ou o par esperado com `%B` = basename |
| `severidade` | `blocker` (violação nova reprova) ou `aviso` (aparece, não reprova) |
| `origem` | Documento e seção que decidiram isso |

Os quatro tipos, e a pergunta que cada um responde:

| Tipo | Verifica |
|---|---|
| `proibe-conteudo` | Arquivo no alvo **não pode** conter o padrão — import proibido, anotação de framework no núcleo, tipo de fornecedor vazando |
| `exige-conteudo` | Arquivo no alvo **tem que** conter o padrão — implementação declarando o contrato do domínio |
| `limita-publico` | No máximo N métodos públicos de **nomes distintos** — sobrecarga não conta, porque continua sendo uma ação só |
| `exige-par` | Para cada arquivo do alvo, existe outro casando o padrão — o teste do use case, a interface do adapter |

Barra de qualidade, e ela importa mais que a quantidade:

1. **Toda regra tem que casar arquivo.** Alvo que não casa nada devolve "conforme" sem ter
   verificado nada — falso verde. O script denuncia, e se **nenhuma** casar ele sai com código 2 em
   vez de aprovar. A causa quase sempre é padrão de monorepo (`/src/main/java/`) em repositório de
   módulo único: escreva `(^|/)src/main/java/`.
2. **Só regra mecânica.** "Controller não contém regra de negócio" é verdadeira e não é
   verificável por padrão de texto — isso é trabalho do `code-reviewer`. Regra aqui é o que uma
   máquina decide sem julgamento.
3. **Dez regras que pegam o essencial ganham de cinquenta que geram ruído.** A rotina morre no dia
   em que o relatório fica grande o bastante para ninguém ler.
4. **Vale só para código de produção.** Teste importa framework e instancia de propósito; cobrar
   arquitetura de teste produz achado sem defeito.
5. **Regra com zero violação no baseline é a melhor que existe** — está segurando a linha. Não é
   candidata a remoção; é a que impede a regressão.

Verifique cada regra antes de fechar: rode o script e confira que o que ela acusa é violação de
verdade, abrindo dois ou três arquivos acusados. Regra que acusa código correto será desativada
pela primeira pessoa que ela atrapalhar, e com razão.

---

## Onda B — baselinar

Congela o que já existe. Sem isso, a primeira execução reprova a base inteira e a rotina é
abandonada no mesmo dia.

```bash
tools/arch-conformance.sh --baseline > docs/.../arch-debt.tsv
```

O script **não escreve** — ele imprime, e você redireciona. Ledger é decisão, não efeito colateral
de uma varredura.

O baseline sai com `?` em dono e prazo. **Preencher é parte da onda.** Dívida sem dono não é
dívida: é uma lista que envelhece. Se não há dono plausível para um item, o honesto é registrar
isenção com prazo e motivo — pelo menos ela vence e volta a cobrar.

Depois de preencher, rode de novo e confirme `VEREDITO: conforme`. É a prova de que a catraca
está armada sem ter parado nada.

---

## Onda C — devolver a violação nova

Violação nova não é assunto de negociação nem de próxima sprint: o custo de corrigir agora é a
menor cifra que ela vai ter. Devolva ao agente que escreveu, com o item específico:

> `UC-NO-INFRA` em `.../CreateObligationUseCase.java` — o Use Case importa
> `com.amm.infra.data.entitys.PanacheObligation`. A arquitetura (`clean-arq.md` §8) diz que o
> núcleo depende de `IRepository` e trabalha em BO; Entity não atravessa a fronteira. Corrija a
> dependência, não a regra.

Três saídas, e só três:

1. **Corrigir** — o caminho normal.
2. **Isentar** — quando a entrega não pode esperar. Linha no ledger com `estado=isento`, **dono** e
   **prazo**, e o motivo. Vence, e no dia seguinte bloqueia igual.
3. **Mudar a arquitetura** — quando a regra é que está errada. Aí a mudança é um ADR, o
   `solution-architect` atualiza a arquitetura **e** a regra, e a origem passa a apontar para o ADR
   novo. Nunca edite a regra sem esse rastro: seis meses depois ninguém sabe se aquilo foi uma
   decisão ou uma fuga.

A isenção é o que faz esta rotina compatível com prazo. Ela não é derrota — é dívida com data. O
que não pode existir é a quarta saída: apagar a regra.

---

## Onda D — pagar a dívida

Esta é a onda de **execução**, e ela é o motivo de a rotina existir: validação sozinha só produz
um relatório que cresce.

Pegue os primeiros **$ARGUMENTS** itens (padrão 1) da seção `ORDEM DE PAGAMENTO` do relatório
completo — ela ordena por severidade e por churn de 90 dias, porque violação em arquivo que ninguém
toca é barata de conviver, e violação em arquivo que muda toda semana cobra juros em cada mudança.

Para cada item:

1. **Roteie ao dono técnico** pela camada — `backend-engineer` para Java de serviço,
   `frontend-engineer` para UI, `integration-engineer` quando a violação é de fronteira com
   fornecedor.
2. **Teste primeiro.** Pagamento de dívida arquitetural é refatoração, e refatoração é
   *behavior-preserving*: sem teste que fixe o comportamento atual, você não está pagando dívida,
   está trocando um defeito conhecido por um desconhecido. Se o módulo não tem suíte, o teste que
   cobre o caminho **é parte do pagamento** — e é assim que a dívida de arquitetura e a de
   cobertura se pagam na mesma passada.
3. **Corrija a violação, não o sintoma.** Se `UC-NO-INFRA` acusa a Entity dentro do Use Case, a
   correção é o BO e o mapper na fronteira; não é `import` movido de lugar.
4. **Rode a suíte do módulo** e cole a saída real. Sem isso não houve pagamento.
5. **Rode o checker.** O item precisa aparecer em `RESOLVIDAS`. Tire a linha do ledger — e a
   catraca aperta sozinha: se aquilo reaparecer amanhã, volta a bloquear.

Fecha com o relatório em `docs/sdlc/04-quality/arch-conformance-<data>.md`: quantas violações
existiam, quantas foram pagas, quais isenções venceram ou vão vencer, e o número novo. **O número
é o produto da rotina** — é como você sabe que está convergindo em vez de discutindo.

---

## Regras da rotina

1. **Orçamento pequeno e constante ganha de mutirão.** Um item por rodada, sempre, paga 20 por
   mês. Mutirão de 88 é a tarefa que nunca começa — e revisar 88 arquivos de refatoração junto é
   como se aprova um defeito por engano.
2. **Dívida sem dono não é dívida.** É uma lista que envelhece.
3. **Isenção vencida bloqueia.** É o único mecanismo que impede a isenção de virar permanente.
4. **A regra nunca cede para o achado.** Se a regra está errada, corrija com ADR e rastro. Se está
   certa, corrija o código. Não existe terceira opção que preserve o sentido de "à risca".
5. **Regra que passa sempre é a melhor regra.** Ao contrário das outras rotinas do `/nightly`,
   aqui zero violação não é sinal de checagem quebrada — é a linha sendo segurada. O que você
   verifica é o oposto: regra que **não casa arquivo nenhum** não está verificando nada.
6. **A conformidade entra no Portão 3, não num portão novo.** Critério em
   `../sdlc-gate/gates.md`. Portão paralelo é portão que alguém pula.

## Agendar

O trabalho recorrente desta rotina é a onda D — pagar o orçamento — mais a varredura que detecta
isenção prestes a vencer. Mecanismos e o porquê de cada um: `../nightly/SKILL.md`, entrada
`arch-drift`.

Para amarrar a validação na entrega em vez de depender de alguém lembrar, o checker sai com código
1 quando há violação nova: chame-o na CI do projeto, junto do teste. É a diferença entre um portão
real e uma sugestão.

## Saída

Onda executada · número antes e depois · itens pagos com evidência de teste · isenções criadas ou
vencidas · próximo item da ordem de pagamento.
