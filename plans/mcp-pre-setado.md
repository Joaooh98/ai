# MCP pré-setado por stack

**Status:** proposto
**Depende de:** o passo de habilitação de MCP do `/setup`, entregue no PR #3

---

## Problema

O `/setup` hoje **pergunta do zero**: "quer habilitar um servidor de documentação?". A pergunta é
correta — a decisão é do usuário — mas ela chega vazia. Quem responde precisa saber qual servidor
existe, se ele cobre a stack do projeto, e qual comando instala.

Na prática isso produz dois desfechos ruins:

1. **O usuário dispensa por não saber avaliar** — e o projeto segue sem a capacidade.
2. **O usuário aceita e a instalação fica pela metade**, porque o comando exato não estava na mão.

O passo certo não é perguntar menos. É perguntar **já com a resposta sugerida**, derivada do que
a detecção viu.

## Evidência

**A detecção é cega para conector de conta.** `skills/practices/mcp-toolbelt/detect-toolbelt.sh`
linhas 159–160 leem apenas `mcpServers` de `.mcp.json` (projeto) e `~/.claude.json` (usuário).
Servidor habilitado como conector claude.ai não está em nenhum dos dois.

Rodando a detecção neste repositório, o que os 27 agentes recebem é:

```
**Servidores MCP configurados**
- usuário: MCP_DOCKER hostinger-billing hostinger-dns hostinger-domains
           hostinger-ecommerce hostinger-hosting hostinger-reach hostinger-vps
- conectores da conta e plugins não aparecem aqui — descubra com `ToolSearch`.
```

Oito servidores, e o próprio `.claude/toolbelt.md` registra que `MCP_DOCKER` e `hostinger-*`
**não conectam** (`Connection closed`, verificado em 27/07/2026). Nenhum deles serve para
desenvolver. O que serviria — documentação — não aparece.

**A stack varia demais para uma sugestão genérica.** Medido nos projetos cadastrados:

| Projeto | Stack | Versões |
|---|---|---|
| `crm` | Quarkus + Next.js | Quarkus 3.33.1 / Java 25 · Next 15.1.11 / React 19 |
| `smart` | 17 repos | 11 Java/Maven em **6 versões** de Quarkus (3.4.2 → 3.25.1), Java 17 e 21 · 6 node/ts |

**E a cobertura do servidor de documentação é assimétrica.** Consultado o Context7 diretamente:

- **Next.js**: oferece `v15.1.11` — exatamente a versão do `crm_pro`. Consulta fixada por versão
  devolve doc presa ao tag git daquela release.
- **Quarkus**: oferece 3.20.3, 3.30.0, 3.31.2. As seis versões em uso **não têm interseção** com
  essas. Sete serviços estão abaixo da mais antiga indexada; o `crm-api` está acima da mais nova.

Ou seja: a sugestão não pode ser "instale Context7 e confie". Tem que vir com a regra de uso que
a stack exige.

## Proposta

**1. Catálogo de servidores, versionado aqui.** Um `mcp/catalog.tsv` com o que a equipe já
avaliou:

```
id  nome  tipo  comando-de-instalacao  cobre  ressalva
```

`tipo` na taxonomia que a skill `mcp-toolbelt` já usa: documentação, design, navegador,
rastreamento, infraestrutura, IDE. `cobre` casa contra os sinais que o `calibrate.sh` detecta
(`package.json`, `pom.xml`, `playwright.config.ts`…). `ressalva` é o texto que vai junto da
sugestão — é onde mora "Quarkus não tem a sua versão indexada, use para conceito, não para
assinatura".

**2. `calibrate.sh` cruza detecção × catálogo** e emite a sugestão pronta, com o comando exato:

```
## MCP sugerido para esta stack
- documentação (Context7) — cobre Next.js 15.1.11 (versão exata indexada)
    claude mcp add --scope project context7 <url>
  RESSALVA: Quarkus 3.33.1 não está indexado (disponíveis: 3.20.3, 3.30.0, 3.31.2).
            Use para conceito e direção; para assinatura, o compilador é a autoridade.
- nenhum servidor de grafo de código detectado — ver plans/grafo-de-codigo.md
```

**3. O `/setup` continua perguntando.** A sugestão não instala nada. Ela transforma
"quer um servidor de documentação?" em "instalo o Context7 com este comando, sabendo desta
ressalva?" — que é uma pergunta que dá para responder.

**4. `--scope project` sempre.** É o que escreve `.mcp.json` e torna o servidor visível para os
27 agentes. Conector de conta funciona para o operador e é invisível para a equipe.

## Custo

- `mcp/catalog.tsv` + leitura no `calibrate.sh`: pequeno, no padrão TSV que o repo já usa em
  `arch-rules.tsv` e `meta.tsv`.
- **Manutenção real e recorrente**: o catálogo envelhece. Cobertura de versão muda, servidor
  muda de URL, servidor morre. Sem alguém revisando, o catálogo passa a sugerir coisa errada —
  que é pior que não sugerir. A coluna `ressalva` precisa de data de verificação.

## Risco

- **Sugestão vira instalação automática por conveniência.** A tentação de pular a pergunta vai
  existir. Não pule: instalar MCP mexe na conta e na máquina do usuário.
- **Servidor com ferramenta de escrita fura a fronteira do repo.** Documentado em
  `workflow/README.md`: o `guard-artifacts.sh` casa `Write|Edit|NotebookEdit` e não alcança
  ferramenta MCP. O catálogo deve marcar quais servidores editam, e o `/setup` deve exigir modo
  somente-leitura nesses casos.
- **O que isto não resolve:** cobertura de versão. Se o Context7 não indexa Quarkus 3.7.3,
  nenhum catálogo conserta — a ressalva só torna o limite visível. Para versão antiga, a fonte
  autoritativa é o jar em `~/.m2/repository`, que já está no disco.

## Descartado no caminho

- **Instalar por padrão, sem perguntar.** Fere a regra 5 da `mcp-toolbelt` (escrita externa exige
  aprovação) e a decisão é do dono da máquina.
- **Detectar servidor por health check no `calibrate.sh`.** O script roda a cada invocação de
  agente; chamada de rede ali custa em todo turno. `claude mcp list` continua sendo o caminho
  para confirmar conectividade quando o resultado importa.
