---
name: setup
description: Calibra a equipe de agentes para ESTE projeto - detecta stack e capacidades, VERIFICA que os comandos funcionam de verdade, e grava o contexto que todo agente passa a carregar. Rode uma vez depois de instalar, e de novo quando a stack mudar.
argument-hint: [nada]
disable-model-invocation: true
allowed-tools: Bash(${CLAUDE_PROJECT_DIR}/.claude/ai-toolkit/tools/*.sh) Bash(${CLAUDE_PROJECT_DIR}/.claude/ai-toolkit/tools/*.sh *) Bash(git *) Bash(claude mcp *)
---

# Calibrar a equipe para este projeto

Instalar cria os links. **Calibrar é o que faz a equipe acertar.**

Sem isto, 27 agentes chegam sabendo o método e nada sobre o seu projeto — e método sem contexto
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

## Passo 2 — Perfilar a fundo

Delegue ao `project-analyst`:

> Perfile este repositório em `docs/sdlc/00-orchestration/stack-profile.md`, com evidência
> (caminho de arquivo) para cada afirmação e a lista do que não conseguiu determinar.

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

A detecção acima diz o que **existe**. Este passo decide o que **passa a existir** — e a decisão
é do usuário, não sua. Nunca instale servidor MCP sem perguntar: é a máquina e a conta dele.

Olhe a seção de capacidades da detecção e pergunte, uma pergunta por lacuna real:

| Lacuna detectada | Pergunte | Resolve |
|---|---|---|
| Nenhum servidor de documentação | "Habilito um servidor de documentação (Context7)? Ele responde a API atual da biblioteca em vez de eu responder de memória." | Versão errada de API no código |
| Nenhum grafo de código | "Habilito busca semântica por símbolo? Responde 'quem chama isto' pelo compilador, não por grep." | Afirmação errada sobre impacto de mudança |
| Nenhum navegador | "Habilito navegador para verificar UI de verdade?" | Mudança visual aprovada sem ninguém olhar |

Autorizado, instale **com escopo de projeto**:

```bash
claude mcp add --scope project <nome> <comando-ou-url>
claude mcp list        # configurado ≠ conectado: confirme antes de contar com ele
```

O escopo importa mais do que parece. `--scope project` escreve `.mcp.json` na raiz, e é
exatamente esse arquivo que a detecção do `mcp-toolbelt` lê. Instalado como conector de conta, o
servidor funciona para você e fica **invisível** para os 27 agentes — eles recebem "nenhum
servidor MCP em arquivo de configuração" e seguem adivinhando.

Recusado, registre a recusa no toolbelt. "O usuário optou por não ter servidor de documentação"
é contexto útil; silêncio faz o próximo agente perguntar de novo.

**Antes de habilitar qualquer servidor com ferramenta de escrita**, leia o aviso em
`workflow/README.md` sobre fronteiras: o hook que impede agente de especificação de editar código
casa `Write|Edit|NotebookEdit` e não alcança ferramenta MCP. Servidor de leitura é seguro;
servidor que edita precisa ser configurado em modo somente-leitura.

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
