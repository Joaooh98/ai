# Secrets — vault local para as credenciais

Um Vault em container onde ficam as credenciais deste ambiente — token de MCP, chave de API — em
vez de um `.env` no disco.

**A ideia não é bloquear o acesso do agente a trinta caminhos. É não ter o que ler.** O modelo não lê
o que não existe em arquivo nenhum, e por isso a lista de restrição é curta.

---

## O que faz isso funcionar

O caminho óbvio seria buscar o token e exportar no ambiente antes de abrir o `claude`. **Não serve.**
A documentação do sandbox é explícita: *"sandboxed Bash commands inherit the parent process
environment by default, including any credentials set there"*. Com o token no ambiente da sessão,
todo `Bash` que o agente rodar herda ele, e um `printenv` lê.

Então o token **nunca entra no ambiente da sessão**. O `.mcp.json` chama o wrapper, e o wrapper busca
do vault e faz `exec` do servidor MCP:

```jsonc
// antes — o token teria que estar aqui, em texto puro
"hostinger-vps": { "command": "npx",
  "args": ["--package=hostinger-api-mcp@latest", "hostinger-vps-mcp"],
  "env": { "APITOKEN": "<<segredo em arquivo que o agente lê>>" } }

// depois — o arquivo guarda o CAMINHO no vault, nunca o valor
"hostinger-vps": { "command": ".../secrets/with-secrets",
  "args": ["hostinger", "--", "npx", "--package=hostinger-api-mcp@latest", "hostinger-vps-mcp"] }
```

O valor passa a existir **só no processo do servidor MCP**. Não está em `~/.claude.json`, não está em
`.env`, e o ambiente da sessão nunca o recebe.

---

## Começar

**Pré-requisitos:** Docker rodando, e `pass` inicializado com uma chave GPG (`pass init <sua-chave>`).
`curl` e `jq` você já tem.

```bash
# 1. subir o vault
docker compose -f secrets/compose.yml up -d

# 2. inicializar — UMA vez na vida deste vault
secrets/vault-init

# 3. destravar — uma vez por boot. O GPG abre um popup pedindo sua senha
secrets/vault-unseal

# 4. guardar um segredo (o valor não aparece na tela)
secrets/vault-put hostinger APITOKEN

# 5. religar os MCP. Mostra o diff e não altera nada sem --apply
secrets/wire-mcp
secrets/wire-mcp --apply
```

Reinicie o Claude Code e confira com `/mcp`.

---

## O ciclo do dia a dia

| Quando | Comando |
|---|---|
| Ligou a máquina | `secrets/vault-unseal` — um popup, e pronto |
| Vai guardar credencial nova | `secrets/vault-put <caminho> <CHAVE>` |
| Vai sair da máquina | `secrets/vault-seal` |
| Quer ver o estado | `tools/secret-scan.sh` |

O `gpg-agent` guarda sua senha depois do primeiro popup, então é **um popup por boot**, não por
comando. Sem ambiente gráfico (SSH, tty), o GPG cai para o `pinentry-curses` e pergunta no terminal.

---

## Os arquivos

| Arquivo | O que é |
|---|---|
| `compose.yml` | O Vault. Porta presa em `127.0.0.1`, volume nomeado para o segredo sobreviver a restart |
| `vault.hcl` | Config do Vault. Storage de arquivo, sem TLS **porque nunca sai do loopback** |
| `vault-init` | Inicializa e guarda as chaves no `pass`. Roda uma vez |
| `vault-unseal` | Destrava e renova o token do wrapper. Uma vez por boot |
| `vault-seal` | Lacra |
| `vault-put` | Guarda um segredo, digitado sem eco |
| `with-secrets` | O wrapper: busca e executa |
| `wire-mcp` | Reescreve as entradas de MCP. `--dry-run` é o padrão |
| `_lib.sh` | Funções compartilhadas. Helper, não script que se chama |

Nenhum deles imprime valor de segredo, em nenhum caminho de erro. O `with-secrets` não tem flag de
verbose, e isso é decisão de segurança e não esquecimento: toda saída extra é uma chance de vazar.

---

## Sobre a chave-mestra

O Vault guarda tudo cifrado no disco. Quando o container reinicia, ele acorda **lacrado**: os dados
estão lá, mas ele não consegue decifrar sem a chave-mestra.

Na inicialização essa chave é dividida em 3 pedaços, e 2 destravam. Os três ficam no `pass`,
cifrados pela sua chave GPG — **nunca em texto puro, em lugar nenhum**. É por isso que destravar pede
sua senha: ela abre o GPG, o GPG abre o `pass`, o `pass` devolve as chaves.

**Se você perder a chave GPG, perde o cofre.** Não existe recuperação — é o que significa cifrar de
verdade. Faça backup da sua chave GPG do jeito que você já faz backup do que não pode perder.

O `vault-init` grava as chaves em arquivo protegido **antes** de tentar o `pass`, e só apaga depois de
confirmar que consegue ler de volta. Se o `pass` falhar no meio, ele para e diz onde está o arquivo,
em vez de deixar você com um cofre inicializado que ninguém consegue abrir.

---

## O que isto protege, e o que não protege

**Protege:**

- o token não existe em arquivo nenhum — não há o que ler;
- o ambiente da sessão não carrega o token — `printenv` do agente não acha;
- a chave-mestra fica cifrada pela sua chave GPG;
- todo acesso fica no log de auditoria do Vault, coisa que `.env` nunca deu.

**Não protege, e é melhor estar escrito:**

1. **Se você pedir ao agente para ler um segredo, ele lê.** A camada protege de acidente, de confusão
   e de prompt injection — não de você.
2. **Vault destravado é vault legível por quem tem o token.** É para isso que existe o `vault-seal`.
   Enquanto destravado, o que separa o agente do segredo é o arquivo de token, e é por isso que a
   regra `Read(~/.config/ai-secrets/token)` é a que sustenta o peso — as regras `Bash(vault …)` são
   quebra-molas, já que `v=vault; $v kv get` escapa de qualquer regra de comando.
3. **`Bash` escreve `settings.local.json` por redirecionamento.** Regras `Edit()` param as ferramentas
   de arquivo, não um `>` no shell. Anti-tamper de verdade exige o sandbox do Claude Code, que nega
   escrita em `settings.json` em todo escopo. Fica como passo separado: as dependências (`bwrap`,
   `socat`) já estão instaladas nesta máquina.
4. **Segredo que já está em arquivo continua lá até você migrar.** `tools/secret-scan.sh` é a lista de
   trabalho dessa migração.

---

## Quando algo falha

| Sintoma | Causa provável |
|---|---|
| `o Vault não responde em 127.0.0.1:8200` | Docker Desktop parado, ou container não subiu |
| `o Vault está lacrado` | Reiniciou a máquina — rode `secrets/vault-unseal` |
| Popup do GPG não aparece | Sem sessão gráfica: o `pinentry-curses` pergunta no terminal |
| MCP parou de conectar depois de religar | Vault lacrado, ou o segredo não está no caminho que o `wire-mcp` configurou |
| Quer desfazer o religamento | `secrets/wire-mcp --revert --apply` — restaura a config exatamente como estava |

O `wire-mcp` faz backup datado antes de qualquer alteração, e a ida e volta foi verificada:
aplicar e reverter devolve o `~/.claude.json` byte a byte.
