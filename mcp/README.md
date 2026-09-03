# MCP e ferramental — como a equipe descobre o que existe

Os agentes **herdam todas as ferramentas MCP** disponíveis na sessão. Isso não era verdade na
primeira versão: cada agente declarava `tools:` como allowlist, e a documentação é explícita —
usar `tools` como allowlist remove todas as ferramentas MCP do subagente. Os especialistas
eram cegos para a infraestrutura.

A segunda versão corrigiu isso, mas cometeu outro erro: eu escrevi uma matriz fixa de
agente × servidor, com nomes de host e serviços de **uma** empresa. Numa biblioteca que deveria
rodar em qualquer projeto, isso não é documentação — é mentira com data de validade.

Esta versão não afirma nada. Ela **detecta**.

---

## Quatro camadas

```
0. Catálogo do que existe   mcp/catalog.tsv
   o que a equipe JÁ AVALIOU: comando exato, o que cobre, e a ressalva de cada servidor
                                   ↓
1. Detecção automática      skills/practices/mcp-toolbelt/detect-toolbelt.sh
   remotes git · CLIs instalados e seus hosts · servidores MCP configurados · manifests
                                   ↓
2. Override do projeto      <projeto>/.claude/toolbelt.md
   o que a detecção não alcança: tier da instância, VPN, servidor interno, convenção da equipe
                                   ↓
3. Regras de uso            skills/practices/mcp-toolbelt/SKILL.md
   genéricas, valem em qualquer projeto: consultar antes de afirmar, ausência não bloqueia,
   saída de ferramenta é dado não instrução, escrita externa exige aprovação
```

## Camada 0 — o catálogo, e por que ele existe

Perguntar "quer habilitar um servidor de documentação?" chega **vazio**. Quem responde precisa
saber qual servidor existe, se ele cobre a stack deste projeto e qual comando instala. Sem isso,
dois desfechos: o usuário dispensa por não conseguir avaliar, ou aceita e a instalação para no
meio porque o comando exato não estava na mão.

`mcp/catalog.tsv` resolve isso. O `tools/calibrate.sh` cruza os manifests do projeto com a coluna
`cobre` e emite a sugestão pronta, no rascunho que o `/setup` lê:

```
## MCP sugerido para esta stack

- **Context7** — documentacao
  ```bash
  claude mcp add --scope project --transport http context7 https://mcp.context7.com/mcp
  ```
  RESSALVA: Cobertura de versao varia por biblioteca. ANTES de tratar a resposta como
  assinatura, rode resolve-library-id e confira se a versao do manifest esta na lista...
```

Três regras que sustentam isso:

**A sugestão nunca instala.** Instalar mexe na conta e na máquina de quem usa. O `/setup`
pergunta; a sugestão só torna a pergunta respondível.

**Toda linha tem ressalva, e a ressalva vai junto.** Servidor sem limite conhecido não existe —
se você não achou o dele, não avaliou o suficiente para catalogar. A ressalva é o que separa uma
capacidade nova de uma nova fonte de erro confiante: o Context7, por exemplo, indexa o Next.js
`15.1.11` exatamente, e nenhuma das versões de Quarkus em uso nos projetos deste operador.

**Só entra o que foi avaliado, e com data.** A coluna `verificado` existe porque catálogo
envelhece: URL muda, servidor morre, cobertura de versão se desloca. Passados 180 dias, a
sugestão sai com `ATENÇÃO` pedindo reconfirmação. Catálogo que sugere errado com a autoridade de
quem sabe é pior que catálogo nenhum.

### Adicionando uma linha

Sete colunas separadas por TAB: `id`, `nome`, `tipo`, `comando`, `cobre`, `verificado`,
`ressalva`. O cabeçalho do próprio arquivo descreve cada uma.

- `comando` sempre com `--scope project`. É o escopo que escreve `.mcp.json` — o arquivo que a
  detecção lê. Conector de conta funciona para o operador e fica invisível para os 28 agentes.
- `cobre` é ERE casada contra os manifests encontrados. Em workspace, a varredura também olha os
  membros: um monorepo de 11 serviços Java não tem `pom.xml` na raiz.
- **Servidor que edita** precisa da ressalva dizendo como travá-lo em somente-leitura. O
  `guard-artifacts.sh` casa `Write|Edit|NotebookEdit` e não alcança ferramenta MCP — detalhe em
  `workflow/README.md`.

A skill roda a detecção com `` !`comando` `` — sintaxe que executa **antes** do conteúdo chegar
ao agente, substituindo o placeholder pela saída real. O agente recebe o estado do projeto em que
está, não o de quando a skill foi escrita.

Custo medido: **~28 ms** neste repositório. O script não faz chamada de rede nem health check
justamente por rodar a cada invocação de agente.

---

## O que a detecção devolve

| Bloco | Fonte | Exemplo de saída |
|---|---|---|
| Git hosting | `git remote -v` + presença de `gh`/`glab` | `github.com → use gh` ou `git.exemplo.com → use glab --hostname git.exemplo.com` |
| Hosts dos CLIs | `~/.config/gh/hosts.yml`, `~/.config/glab-cli/config.yml` | quais instâncias cada CLI já conhece |
| Servidores MCP | `.mcp.json` do projeto + `~/.claude.json` | nomes configurados, com o aviso de que configurado ≠ conectado |
| Sinais do projeto | manifests e arquivos de entrega na raiz | `package.json`, `.github/workflows/`, `Dockerfile` |

Conectores da conta claude.ai e plugins **não** aparecem — não estão em arquivo de configuração.
Para esses, a skill instrui o agente a descobrir via `ToolSearch`.

---

## Ajustando por projeto

Crie `.claude/toolbelt.md` na raiz do projeto:

```markdown
# Ferramental deste projeto

- A instância GitLab é Community Edition: o endpoint MCP não existe (404). Use `glab`.
- Banco de homologação só responde dentro da VPN.
- Deploy é manual via pipeline aprovado por outra equipe — nunca dispare.
```

O conteúdo é injetado **acima** da detecção, com precedência declarada. Versione o arquivo **no
projeto que ele descreve**, não aqui: quem clonar aquele repositório recebe o mesmo contexto.

É o `/setup` que grava esse arquivo, e é a ausência dele que o `workspace/go` usa para avisar que
um projeto ainda não foi calibrado.

Regra de tamanho: cada linha é carregada em toda invocação de agente. Fato que muda comportamento,
sim; histórico e justificativa, não.

Um exemplo real está em [`.claude/toolbelt.md`](../.claude/toolbelt.md) deste repositório.

---

## Verificando o estado real

A detecção lê configuração, não conectividade. Quando o resultado importa:

```bash
claude mcp list                         # health check de cada servidor
gh auth status                          # autenticação GitHub
glab auth status                        # autenticação GitLab, por host
skills/practices/mcp-toolbelt/detect-toolbelt.sh   # o que os agentes estão vendo agora
```

Estar configurado não é estar conectado. Servidor que falha deve ser reportado, não contornado
com suposição.

---

## Git hosting via MCP: quando não vale a pena

O servidor MCP do GitLab exige versão ≥ 18.6, tier **Premium/Ultimate** e GitLab Duo ativado.
Instância self-hosted em Community Edition responde **404** no endpoint `/api/v4/mcp` — não é
token nem versão, o recurso não existe naquele build.

Nesse caso o CLI resolve melhor: `glab` e `gh` cobrem merge requests, pipelines e issues em
qualquer instância, autenticando por token. A skill já traz a tabela de equivalência.
