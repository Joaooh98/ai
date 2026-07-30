# Vault de credenciais

**Estado:** entregue
**Desde:** 2026-07-30
**Onde:** branch `worktree-vault-secrets`, PR #2

## O problema

As credenciais deste ambiente precisavam morar em algum lugar. Moravam em **nenhum**, e isso não era
teoria: os 7 servidores MCP do Hostinger em `~/.claude.json` tinham apenas `USER_AGENT` no `env` e
nenhum token de API. O `.claude/toolbelt.md` já registrava o sintoma — `Connection closed`, verificado
em 27/07/2026 — sem que a causa estivesse identificada. **Os MCP não conectavam por falta de
credencial, e não havia onde guardá-la.**

A saída natural — colar o token num `.env` ou direto no `~/.claude.json` — cria exatamente o arquivo
que o agente consegue ler. E o repositório não tinha defesa nenhuma: a única detecção de segredo
existente eram dois `grep` sobre **nomes** de arquivo (`tools/diff-scope.sh:61`,
`tools/incident-evidence.sh:31`), feitos para priorizar revisão, não para bloquear. Detecção por
conteúdo não existia em lugar nenhum, e regra de segredo em agente era prosa — 12 agentes dizem
alguma variação de *"secrets never live in code"*, o que é um pedido, não uma fronteira.

## A decisão

**Tirar o segredo do sistema de arquivos, em vez de bloquear caminhos.** O modelo não lê o que não
existe, e a lista de restrição encolhe de ~30 regras para 8.

O detalhe que faz funcionar, e que quase passou batido: **o token não pode entrar no ambiente da
sessão.** O caminho óbvio seria o `workspace/go` buscar do vault, exportar e abrir o `claude`. Não
serve — a documentação do sandbox é explícita:

> *sandboxed Bash commands inherit the parent process environment by default, including any
> credentials set there*

Com o token exportado na sessão, todo `Bash` do agente o herda e um `printenv` o lê. Fechar isso pelo
ambiente exigiria ligar o sandbox, `credentials.envVars: deny` e `allowUnsandboxedCommands: false` —
muita máquina, e ainda com o furo do `excludedCommands`, que a doc diz não ter travamento gerenciado.

Em vez disso, o `.mcp.json` chama um wrapper que busca do vault e faz `exec` do servidor MCP:

```jsonc
"hostinger-vps": { "command": ".../secrets/with-secrets",
  "args": ["hostinger", "--", "npx", "--package=hostinger-api-mcp@latest", "hostinger-vps-mcp"] }
```

O valor vive **só no processo do servidor MCP**. Não está em arquivo, e o ambiente da sessão nunca o
recebe.

## O que foi descartado, e por quê

Esta é a parte que não cabe no commit.

**Um hook `PreToolUse` em bash classificando caminho e parseando comando.** Era o plano inicial, com
~250 linhas. Morreu quando a documentação mostrou que seria uma reimplementação **mais fraca** do que
o harness já impõe:

- `Read(.env)` segue semântica gitignore e casa em qualquer profundidade — `Read(.env)` ≡
  `Read(**/.env)`. O glob `*/.env` que eu tinha escrito não pegava `.env` relativo puro, que é o caso
  mais comum de todos.
- Deny rules de `Read`/`Edit` valem também para os comandos de arquivo que o Claude Code reconhece no
  Bash (`cat`, `head`, `tail`, `sed`), com parse real de subcomando, `$()` e crase. Extração de
  palavra por regex é furada por `f=.e''nv; cat $f`.
- Regras de caminho para `Write`, `Glob` e `NotebookEdit` são **aceitas e nunca consultadas**. Só
  `Read()` e `Edit()` valem — o desenho original teria esse bug.

**Destravamento por variável de ambiente (`DLP_UNLOCK=1`).** Parecia exclusivo do operador, porque o
modelo não altera o ambiente do processo pai pelo Bash. Mas a doc de settings confirma que o bloco
`env` é *"applied to every session and to subprocesses"* — o modelo escreveria
`{"env":{"DLP_UNLOCK":"1"}}` em `.claude/settings.local.json`, que é **gitignorado** e não aparece em
`git status`. Destravamento forjável não é destravamento.

**Detector em `awk`.** Descartado por medição, não por gosto: o `awk` desta máquina é `mawk`, sem
suporte a intervalo em ERE, e não há `gawk`. `awk '/AKIA[A-Z0-9]{16}/'` não casa
`AKIAIOSFODNN7EXAMPLE`. Como quase toda forma de segredo depende de contagem, um detector em awk
falharia **em silêncio** — o pior defeito possível num controle de segurança: parece instalado e não
acha nada. O detector usa `grep -E`, verificado no GNU grep 3.7 e no ugrep 7.5.

**Detecção de PII/LGPD.** Cortada do escopo por decisão do operador. Virou
[deteccao-pii-lgpd](deteccao-pii-lgpd.md).

**Modo dev do Vault.** Zero atrito, mas perde todo segredo a cada restart do container. Não serve para
guardar credencial de verdade. O compose usa storage de arquivo em volume nomeado.

## O que ficou entregue

`secrets/` com o compose do Vault, o ciclo `init`/`unseal`/`seal`, `vault-put` (digitação sem eco),
`with-secrets` (o wrapper) e `wire-mcp` (religa os MCP, `--dry-run` por padrão, `--revert` restaura
byte a byte). `tools/secret-scan.sh` mostra onde as credenciais estão hoje e `tools/restrict.sh`
aplica o mínimo deixando o operador escolher o resto.

A chave-mestra fica no `pass`, cifrada pela chave GPG do operador — que já existia na máquina, junto
com `pinentry-gnome3`. Destravar abre um popup gráfico pedindo a senha; o `gpg-agent` cacheia, então é
um popup por boot.

## O que falta

1. **O ciclo do vault nunca rodou ao vivo.** O daemon do Docker Desktop está parado nesta máquina, e
   subir isso não me pareceu decisão para tomar sozinho. É também o teste que prova o desenho inteiro:
   se os 7 MCP aparecerem em `/mcp`, a credencial saiu do vault e chegou no processo certo.
   ```bash
   docker compose -f secrets/compose.yml up -d && secrets/vault-init && secrets/vault-unseal
   secrets/vault-put hostinger APITOKEN && secrets/wire-mcp --apply
   ```
2. **Confirmar que `Read()` deny cobre `Grep`.** A doc sustenta `Glob` (manda usar `Read()` no lugar
   de `Glob()`), mas não achei a frase para `Grep` nem `LSP`. Se não cobrir, é um furo real na camada
   declarativa. Teste: negar `Read` de um `.env` e tentar `Grep` no mesmo caminho.
3. **`.playwright-mcp/` está rastreado no git** — 6 arquivos, 2 deles PNG. A varredura não achou forma
   de segredo, então é risco e não achado; mas screenshot de página autenticada é o caso clássico de
   token que regex nunca vê, porque não é texto.
4. **Anti-tamper de verdade** — ver [sandbox-anti-tamper](sandbox-anti-tamper.md).

## O que isto explicitamente não protege

Está no `secrets/README.md` e vale repetir aqui, porque é o tipo de coisa que some com o tempo e
deixa a camada parecer mais forte do que é:

- **Se o operador pedir um segredo ao agente, ele lê.** A camada protege de acidente, de confusão e de
  prompt injection vinda de página web, ticket ou README de dependência. Não do dono da máquina.
- **Vault destravado é legível por quem tem o token.** Daí o `vault-seal`.
- **Das 8 regras, uma sustenta o peso:** `Read(~/.config/ai-secrets/token)`. As `Bash(vault …)` são
  quebra-molas — `v=vault; $v kv get` escapa de qualquer regra de comando.
