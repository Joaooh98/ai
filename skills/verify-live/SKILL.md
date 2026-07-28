---
name: verify-live
description: Sobe a aplicacao num ambiente controlado e verifica a mudanca de verdade - navegando o fluxo no browser, chamando o endpoint, olhando o log - em vez de deduzir do codigo. Use antes do portao de qualidade sempre que a mudanca for visivel ao usuario.
argument-hint: [o que verificar]
allowed-tools: Bash(${CLAUDE_PROJECT_DIR}/tools/*.sh *) Bash(docker compose *) Bash(git *)
---

# Verificação no mundo real

Verificar: **$ARGUMENTS**

Teste verde prova que o código faz o que o teste diz. Não prova que o produto funciona. Esta skill
existe para fechar essa distância.

## O ambiente

!`${CLAUDE_PROJECT_DIR}/tools/preview-env.sh`

## Passo 1 — Escolher o ambiente, na ordem de preferência

| Ambiente | Quando | Por quê |
|---|---|---|
| **Compose / container local** | Existe `docker-compose.yml` ou equivalente | Isolado, reproduzível, descartável — o mais próximo de produção sem risco |
| **Dev server local** | Projeto tem script de start | Rápido, mas partilha estado com a sua máquina |
| **Preview / staging** | Existe ambiente de preview por branch | Realista, mas compartilhado — nunca use para teste destrutivo |
| **Produção** | **Nunca**, para verificar mudança | Se a única forma de verificar é produção, isso é a lacuna a reportar |

Nada disponível? Diga isso explicitamente no relatório — "não foi possível verificar em execução"
é informação acionável. "Deve funcionar" não é.

## Passo 2 — Subir com dados controlados

- Use o seed ou fixture do projeto. Se não existir, crie o mínimo e **registre o que criou**.
- Nunca aponte para banco de produção, nem para credencial de produção.
- Registre a porta e a URL — o relatório precisa ser reproduzível por outra pessoa.

## Passo 3 — Verificar o que importa

**Interface** — use o MCP de navegador da sessão (descubra com `ToolSearch`) ou o
Playwright/Cypress do projeto:

- [ ] O fluxo completo, do início ao fim, como o usuário faria
- [ ] O **estado de erro** — force a falha, não só o caminho feliz
- [ ] O estado vazio e o de carregamento
- [ ] Navegação **por teclado**, com foco visível
- [ ] Console sem erro novo · rede sem requisição falhando

**Endpoint** — chame de verdade:

- [ ] Sucesso, com o payload real
- [ ] Erro de validação e erro de autorização
- [ ] O caso de fronteira que o critério de aceite descreve

**Pipeline ou infra** — execute. Ler o YAML e concluir não é verificação.

## Passo 4 — Derrubar

Pare os containers, remova volumes temporários, apague os dados de teste que criou. Ambiente
que sobrou ligado vira o próximo incidente de "por que a porta 5432 está ocupada".

## Passo 5 — Reportar

```
VERIFICADO — <mudança>
Ambiente:     <compose | dev server | preview> · <URL>
Dados:        <seed usado ou criado>
Verificado:   <o que foi navegado/chamado, com o resultado>
Erro testado: <como forçou a falha, e o que o usuário viu>
Não coberto:  <o que não deu para verificar, e o que faltou>
Evidência:    <saída, screenshot, status code — não impressão>
```

O campo **Não coberto** é obrigatório e quase nunca vazio. Silêncio ali vira falsa confiança
no portão seguinte.

## Regras

1. **Impressão não é evidência.** "Pareceu funcionar" não entra no relatório; status code, saída
   de console e screenshot entram.
2. **Force o erro.** O caminho feliz é o menos informativo — quase todo defeito de produção mora
   no caminho que ninguém exercitou.
3. **Nunca verifique contra produção.** Se não há outro jeito, isso é a lacuna a reportar, não
   o procedimento a seguir.
4. **Derrube o que subiu.**
5. **Não conseguiu verificar? Diga.** É a informação mais útil que você pode devolver quando o
   projeto não tem como ser executado.
