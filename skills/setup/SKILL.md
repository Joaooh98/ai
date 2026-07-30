---
name: setup
description: Calibra a equipe de agentes para ESTE projeto - detecta stack e capacidades, VERIFICA que os comandos funcionam de verdade, e grava o contexto que todo agente passa a carregar. Rode uma vez depois de instalar, e de novo quando a stack mudar.
argument-hint: [nada]
disable-model-invocation: true
allowed-tools: Bash(${CLAUDE_PROJECT_DIR}/.claude/ai-toolkit/tools/*.sh) Bash(${CLAUDE_PROJECT_DIR}/.claude/ai-toolkit/tools/*.sh *) Bash(git *)
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

## Passo 4 — Gravar

Escreva `.claude/toolbelt.md` com o rascunho detectado **mais** o que foi verificado e respondido.
Regras:

- Fato que muda comportamento entra. Histórico e justificativa, não.
- Comando registrado é comando que você executou.
- O que falhou fica escrito, com o erro.
- Curto: cada linha é carregada em toda invocação de agente.

Este arquivo é versionado — quem clonar o repositório recebe a mesma calibração.

## Passo 5 — Reportar capacidades e lacunas

```
CALIBRADO — <projeto>
Stack:        <o que é, verificado>
Testes:       <comando> → <resultado real da execução>
Build:        <comando> → <resultado real>
Navegador:    <disponível como? ou: ausente, e o que isso limita>
MCP ativos:   <lista>
Lacunas:      <o que impede a equipe de verificar algo>
Perguntas em aberto: <as que ficaram>
```

Seja explícito nas lacunas. "Sem navegador disponível, mudança de UI não pode ser verificada de
verdade — só por teste unitário" é informação acionável; silêncio vira falsa confiança depois.

## Quando rodar de novo

Stack mudou · ferramenta nova · comando de teste mudou · integração externa adicionada · algum
agente errou por falta de contexto — este último é sintoma de calibração desatualizada.
