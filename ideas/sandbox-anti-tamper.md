# Sandbox: o anti-tamper que falta

**Estado:** em desenvolvimento
**Desde:** 2026-07-30
**Onde:** ainda não tem branch. Nasceu como limite conhecido do [vault-de-credenciais](vault-de-credenciais.md)

## O problema

A camada de restrição entregue no PR #2 tem um furo declarado: **`Bash` escreve
`.claude/settings.local.json` por redirecionamento.**

As regras `Edit()` param as ferramentas de arquivo do Claude Code. Não param um `>` no shell. Então um
agente confuso — ou um prompt injection vindo de página web, ticket ou README de dependência — pode
reescrever a própria política de permissão e, no turno seguinte, ler o que a política proibia. O
arquivo é gitignorado, então a alteração também não aparece em `git status`.

Isso não é hipótese: é a consequência direta de a camada declarativa e o shell serem impostos por
mecanismos diferentes.

## A decisão provável

O sandbox do Claude Code fecha exatamente isso. A doc é explícita:

> *the sandbox automatically denies write access to Claude Code's `settings.json` files at every scope
> and to the managed settings directory, so a sandboxed command can't modify its own policy*

E resolve symlink desde a v2.1.210, então trocar o arquivo por um link para outro lugar também não
passa. Além disso, o sandbox é a única camada que alcança o que a doc de permissões admite não
alcançar:

> *[deny rules] don't apply to arbitrary subprocesses that read or write files indirectly, like a
> Python or Node script that opens files itself. For OS-level enforcement that blocks all processes
> from accessing a path, enable the sandbox.*

Ou seja: sem sandbox, `python3 -c "print(open('.env').read())"` passa por cima de toda a camada de
caminho.

## Por que não entrou junto

Ligar o sandbox **muda o dia a dia de quem roda build local** — não é decisão para embutir de carona
num commit de segurança. Em particular:

- **`docker` é incompatível com o sandbox** e precisa entrar em `excludedCommands`. Como este projeto
  agora sobe um Vault em container, isso não é detalhe: é o primeiro comando que vai quebrar.
- `excludedCommands` **não tem travamento gerenciado**, então qualquer entrada ali é um furo permanente
  na fronteira.
- A rede do sandbox por padrão **não termina TLS**, e a própria doc alerta que permitir domínio amplo
  como `github.com` cria caminho de exfiltração.

## O terreno já está preparado

Verificado nesta máquina em 30/07/2026 — as dependências estão todas lá:

| Dependência | Estado |
|---|---|
| `bubblewrap` (`bwrap`) | instalado |
| `socat` | instalado |
| AppArmor restringindo userns | `kernel.apparmor_restrict_unprivileged_userns = 0` — **não restringe** |

Ou seja, `/sandbox` deve subir sem instalar nada. O que falta é decidir o custo de atrito, não
resolver dependência.

## O que falta

1. Rodar `/sandbox` e ver o que quebra num dia normal de trabalho, antes de qualquer configuração.
2. Montar `sandbox.credentials.files` para `~/.gnupg`, `~/.password-store` e o token do vault — a doc
   avisa que **não existe lista de credenciais embutida**: só é protegido o que for listado.
3. Decidir `excludedCommands` com a lista mais curta possível, sabendo que `docker *` vai precisar
   entrar.
4. Avaliar `network.allowedDomains` — e assumir que domínio amplo é caminho de exfiltração.
5. Só então considerar `allowUnsandboxedCommands: false`, que fecha a saída de emergência.
