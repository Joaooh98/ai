# Unificar os padrões de segredo espalhados

**Estado:** ideia
**Desde:** 2026-07-30
**Onde:** encontrado durante o [vault-de-credenciais](vault-de-credenciais.md)

## O problema

Dois scripts detectam "área de risco de segredo" com listas **divergentes**, e nenhum dos dois sabe da
existência do outro.

`tools/diff-scope.sh:61`
```
'\.env|secret|credential|config\.(ya?ml|json|toml)$'
```

`tools/incident-evidence.sh:31`
```
'\.env|config\.(ya?ml|json|toml)|settings|properties$'
```

O segundo **perdeu `secret` e `credential`** e ganhou `settings|properties$`. O rótulo também mudou:
`SEGREDOS / CONFIG` virou só `CONFIG`. Nada indica que a diferença tenha sido decidida — parece
divergência acumulada por cópia.

Consequência concreta: um arquivo chamado `credentials.json` alterado na janela de um incidente **não
é sinalizado** pelo `incident-evidence.sh`, embora o `diff-scope.sh` o sinalizasse num code review. O
momento em que menos se pode perder esse sinal é justamente o incidente.

## O que mudou agora

Antes do PR #2 não havia alternativa: cada script tinha que carregar sua listinha. Agora existe
`tools/_secret-shapes.sh`, um detector único com classes nomeadas, testado, e com uma regra clara de
que nunca imprime valor.

## A ideia

Uma fonte só para "o que parece segredo", consumida pelos três lugares.

O detalhe é que os usos são **diferentes em natureza**, e isso precisa ser respeitado em vez de
espremido num único mecanismo:

| Consumidor | Pergunta que faz | Opera sobre |
|---|---|---|
| `diff-scope.sh` | "esta mudança merece olhar de segurança?" | **nomes** de arquivo do diff |
| `incident-evidence.sh` | "o que mexeu na janela merece olhar?" | **nomes** de arquivo do log |
| `secret-scan.sh` | "existe segredo de verdade aqui?" | **conteúdo** |

Então o compartilhado provavelmente é uma lista de **padrão de nome** — hoje duplicada dentro de
`secret-scan.sh` e `restrict.sh` como `NOMES_SENSIVEIS`, o que já são duas cópias novas, criadas por
este mesmo trabalho. Vale o incômodo de admitir: o PR #2 resolveu a divergência de conteúdo e
**criou** uma pequena divergência de nome.

Caminho provável: mover `NOMES_SENSIVEIS` e `NOMES_TEMPLATE` para `_secret-shapes.sh` como variáveis
exportadas por `source`, e fazer os quatro scripts lerem de lá.

## Cuidado ao fazer

`diff-scope.sh` e `incident-evidence.sh` são consumidos por agentes que já esperam um formato de
saída. `tools/README.md` documenta quem chama o quê, e `skills/sdlc-quality/SKILL.md:27-31` condiciona
o despacho do `security-auditor` ao que o `diff-scope` marca. Mudar o rótulo de uma área quebra a
skill em silêncio — o mesmo tipo de acoplamento invisível que produziu a promessa não cumprida
descrita em [deteccao-pii-lgpd](deteccao-pii-lgpd.md).

Fazer com um teste de saída antes e depois, ou não fazer.

## Tamanho

Pequeno. Provavelmente uma sessão. O valor não é o código economizado — é parar de ter duas verdades
sobre o que conta como segredo neste repositório.
