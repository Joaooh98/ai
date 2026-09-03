---
name: setup
description: Calibra a equipe de agentes para ESTE projeto - detecta stack e capacidades, VERIFICA que os comandos funcionam de verdade, e grava o contexto que todo agente passa a carregar. Rode uma vez depois de instalar, e de novo quando a stack mudar.
argument-hint: [nada]
disable-model-invocation: true
allowed-tools: Bash(${CLAUDE_PROJECT_DIR}/.claude/ai-toolkit/tools/*.sh) Bash(${CLAUDE_PROJECT_DIR}/.claude/ai-toolkit/tools/*.sh *) Bash(git *) Bash(claude mcp *)
---

# Calibrar a equipe para este projeto

Instalar cria os links. **Calibrar é o que faz a equipe acertar.**

Sem isto, 28 agentes chegam sabendo o método e nada sobre o seu projeto — e método sem contexto
produz o palpite plausível: o comando de teste errado, a convenção ignorada, a afirmação de que
"a suíte passa" quando nem existe suíte.

---

## Detecção

!`${CLAUDE_PROJECT_DIR}/.claude/ai-toolkit/tools/calibrate.sh "${CLAUDE_PROJECT_DIR}"`

---

## Passo 1 — Verificar, não acreditar

A detecção leu arquivos. Agora **execute**, porque comando declarado não é comando que funciona:

| O que | Por que importa |
|---|---|
| O comando de teste, uma vez | É a afirmação que os agentes mais vão fazer. Se falha na sua máquina limpa, todo "os testes passam" depois é falso |
| O comando de build ou type-check | Idem |
| O linter | Define o que é "código correto" aqui |

Rode. Cole a saída real. Falhou? **Isso é a informação mais valiosa desta calibração** — registre
o erro no arquivo, para nenhum agente perder tempo redescobrindo.

Se o projeto tem venv, container ou passo de setup, descubra **agora** qual é a sequência que
funciona de fato, e registre.

## Passo 2 — Perfilar e configurar a fundo

Delegue ao `project-configurator`. Ele usa o `project-analyst` como etapa somente-leitura quando o
perfil ainda não existe:

> Configure este projeto para as próximas implementações. Classifique-o como brownfield,
> greenfield ou híbrido; registre arquitetura e convenções com evidência em
> `docs/sdlc/00-orchestration/project-configuration.md`; e crie regras concisas e verificáveis em
> `.claude/rules/`. Preserve instruções existentes e não altere código de produto.

Em brownfield, convenção observada vence preferência genérica. Em greenfield, o agente levanta
atributos de qualidade mensuráveis, compara opções atuais com fontes primárias e pede aprovação
antes de consolidar decisões caras ou difíceis de reverter. SOLID e Clean Code são padrões de
partida, não licença para criar abstrações sem necessidade.

## Passo 3 — Perguntar o que nenhuma detecção alcança

Essas respostas valem mais que tudo que foi detectado. Pergunte ao usuário, de forma direta:

1. **O que não pode ser mexido sem aprovação?** (migração, config de produção, contrato público)
2. **O que falta no ambiente?** (VPN, credencial, acesso a banco, serviço que não sobe local)
3. **Como se verifica de verdade que uma mudança funciona aqui?** Teste unitário? Subir a app e
   olhar no navegador? Chamar um endpoint?
4. **Que convenção do time o linter não pega?**
5. **Quais integrações externas são críticas?**

Faltando resposta, registre a pergunta em aberto em vez de assumir.

## Passo 4 — Habilitar as capacidades que faltam

A detecção acima diz o que **existe**. A seção **"MCP sugerido para esta stack"** diz o que
poderia existir: ela cruza os manifests deste projeto com `mcp/catalog.tsv` — o que a equipe já
avaliou — e traz o comando exato mais a ressalva de cada servidor.

**Ela sugere. Você pergunta. O usuário decide.** Nunca instale servidor MCP sem autorização
explícita: mexe na conta e na máquina dele.

Para cada item sugerido, pergunte usando o que a detecção já trouxe — não invente a pergunta do
zero, e **não omita a ressalva**. Ela é o que separa uma capacidade nova de uma nova fonte de
erro confiante:

> "Habilito o Context7 aqui? Ele responde a API atual da biblioteca em vez de eu responder de
> memória. Ressalva: a cobertura de versão varia — para as versões que ele não indexa, vale para
> conceito, e a autoridade sobre assinatura continua sendo o compilador."

Autorizado, rode **o comando exato que a detecção imprimiu** e confirme:

```bash
claude mcp list        # configurado ≠ conectado: confirme antes de contar com ele
```

O escopo não é detalhe. `--scope project` escreve `.mcp.json` na raiz, e é exatamente esse
arquivo que a detecção do `mcp-toolbelt` lê. Instalado como conector de conta, o servidor
funciona para você e fica **invisível** para os 28 agentes — eles recebem "nenhum servidor MCP em
arquivo de configuração" e seguem adivinhando.

Recusado, registre a recusa no toolbelt. "O usuário optou por não ter servidor de documentação" é
contexto útil; silêncio faz o próximo agente oferecer de novo.

**Servidor com ferramenta de escrita exige cuidado extra.** O `guard-artifacts.sh` casa
`Write|Edit|NotebookEdit` e **não alcança** ferramenta MCP: com edição ligada, agente de
especificação passa a poder alterar código de produção sem registro no `guard.tsv`. Configure o
servidor em modo somente-leitura, como a ressalva do catálogo manda. O aviso completo está em
`workflow/README.md`.

Nada sugerido, ou a sugestão veio com **ATENÇÃO de data**? Diga isso no relatório. Catálogo
conferido há muito tempo pode estar recomendando comando que já mudou.

## Passo 5 — Estabelecer as metas do projeto

Os Portões 3 e 4 pedem número: *"orçamentos de performance atendidos"*, *"critérios de rollback
numéricos"*. Sem meta declarada esses itens caem no julgamento e passam sempre. **Meta é o que
torna o portão conferível.**

A seção "Metas de qualidade" da detecção já diz de onde o número pode sair neste projeto. Com
isso na mão, pergunte:

1. **Qual cobertura de teste este projeto deve sustentar?** Se hoje está baixa, não invente um
   alvo — use catraca (`nao-cai`): não bloqueia o que já existe, e impede piorar.
2. **Existe orçamento de latência ou throughput?** Número e unidade, ou nada.
3. **O que nunca pode ir para produção?** Vira meta de contagem: achado BLOCK aberto, review com
   veredito BLOCK.
4. **Alguma meta é blocker de verdade, ou é aviso por enquanto?** Meta que ninguém pretende
   respeitar apodrece o portão inteiro — prefira `aviso` a um `blocker` que será ignorado.

Grave em `.claude/meta.tsv`, partindo do template em
`${CLAUDE_PROJECT_DIR}/.claude/ai-toolkit/skills/setup/meta.template.tsv`. Depois confira:

```bash
tools/meta-check.sh                                   # o que já atende, o que falta
tools/meta-check.sh --baseline > .claude/meta-baseline.tsv   # só se houver catraca
```

Regras que impedem a meta de virar teatro:

- **O número vem de relatório que a rodada real produziu.** `meta-check.sh` lê, nunca executa.
  Não existe relatório de cobertura? Ou habilita a geração, ou a meta é de contagem sobre os
  artefatos de `docs/sdlc/04-quality/`.
- **Relatório ausente ou mais velho que o código bloqueia**, igual a meta descumprida. Item não
  verificável nunca é item aprovado.
- **Meta sem dono não existe.** A coluna `origem` recebe o ADR, a política do time, ou `/setup`
  com a data.

Projeto sem nenhuma meta possível hoje: registre isso explicitamente no toolbelt, como lacuna.
É informação acionável — "os portões 3 e 4 não têm critério numérico aqui" — e não silêncio.

## Passo 6 — Gravar

Escreva `.claude/toolbelt.md` com o rascunho detectado **mais** o que foi verificado e respondido.
Regras:

- Fato que muda comportamento entra. Histórico e justificativa, não.
- Comando registrado é comando que você executou.
- O que falhou fica escrito, com o erro.
- Curto: cada linha é carregada em toda invocação de agente.

Este arquivo é versionado — quem clonar o repositório recebe a mesma calibração.

## Passo 7 — Reportar capacidades e lacunas

```
CALIBRADO — <projeto>
Stack:        <o que é, verificado>
Testes:       <comando> → <resultado real da execução>
Build:        <comando> → <resultado real>
Navegador:    <disponível como? ou: ausente, e o que isso limita>
MCP ativos:   <lista, com escopo: projeto ou usuário>
MCP recusados:<o que foi oferecido e o usuário dispensou>
Metas:        <n declaradas> → <saída real de tools/meta-check.sh>
Lacunas:      <o que impede a equipe de verificar algo>
Perguntas em aberto: <as que ficaram>
```

Seja explícito nas lacunas. "Sem navegador disponível, mudança de UI não pode ser verificada de
verdade — só por teste unitário" é informação acionável; silêncio vira falsa confiança depois.

## Quando rodar de novo

Stack mudou · ferramenta nova · comando de teste mudou · integração externa adicionada · algum
agente errou por falta de contexto — este último é sintoma de calibração desatualizada.
