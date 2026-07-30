# Ideas — o que está pensado, o que está em obra, o que ficou de fora

O caderno da oficina. Uma ideia por arquivo, com o estado dela em cima.

Existe porque decisão boa se perde. O raciocínio que levou a uma escolha — e principalmente as
alternativas descartadas e **por quê** — não cabe numa mensagem de commit e não sobrevive numa
conversa. Seis meses depois alguém (você) olha o código e refaz a mesma investigação para chegar na
mesma conclusão, ou pior, na conclusão contrária sem saber que ela já tinha sido testada.

## Isto não é o `docs/sdlc/`

| | `docs/sdlc/` | `ideas/` |
|---|---|---|
| Onde nasce | No **projeto alvo**, durante um ciclo de trabalho | Aqui, na oficina |
| O que é | Artefato formal de fase, com contrato de saída e portão | Nota de trabalho, sem cerimônia |
| Quando morre | Quando o ciclo fecha | Fica — inclusive as ideias descartadas |
| Quem escreve | Os agentes | Você, ou um agente a seu pedido |

Trabalho de produto continua não acontecendo aqui dentro. Estes arquivos são sobre **a própria
oficina**: o que ela ganha, o que falta nela, e o que já foi tentado.

## Convenção

Um arquivo por ideia, kebab-case, com este cabeçalho:

```markdown
# <título>

**Estado:** ideia | em desenvolvimento | entregue | descartada
**Desde:** AAAA-MM-DD
**Onde:** branch, PR ou issue, se já existir
```

Depois, na ordem que importa para quem chega depois:

1. **O problema** — o que dói, com evidência. Não "seria legal ter X".
2. **A decisão** — o que foi escolhido.
3. **O que foi descartado, e por quê** — a parte mais valiosa e a que mais se perde.
4. **O que falta** — se não estiver entregue.

Ideia descartada **não se apaga**. Vira `descartada` com o motivo. Apagar convida a redescobrir o
mesmo beco sem saída.

## Índice

| Ideia | Estado | Resumo |
|---|---|---|
| [vault-de-credenciais](vault-de-credenciais.md) | entregue | Tira a credencial do disco em vez de bloquear caminho. O agente não lê o que não existe |
| [sandbox-anti-tamper](sandbox-anti-tamper.md) | em desenvolvimento | Só o sandbox impede o agente de reescrever a própria política por `>` no shell |
| [deteccao-pii-lgpd](deteccao-pii-lgpd.md) | ideia | Uma skill já promete área de risco "dados pessoais" que nenhum script detecta |
| [unificar-padroes-de-segredo](unificar-padroes-de-segredo.md) | ideia | Dois scripts têm listas divergentes de padrão de segredo; agora existe um detector único |
