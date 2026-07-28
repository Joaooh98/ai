# Postmortem — <título>

**Severidade:** SEV<n>
**Duração:** início <UTC> → resolução <UTC> (<X>h<Y>m)
**Detecção:** <UTC> — <como foi detectado>
**Autor:** · **Revisores:** · **Status:** rascunho | revisado

---

## Resumo em três linhas

O que quebrou, quem foi afetado, o que resolveu. Escrito para quem não estava presente.

## Impacto

| dimensão | medida |
|---|---|
| usuários afetados | |
| requisições afetadas | |
| dados perdidos ou corrompidos | |
| receita ou SLA | |
| duração do impacto real | |

Impacto medido, não estimado por impressão. Se não deu para medir, diga isso.

## Linha do tempo

| hora UTC | evento | tipo |
|---|---|---|
| | | fato / hipótese / mitigação / comunicação |

Inclua as tentativas que **não** funcionaram. São o registro mais útil do documento.

## Causa raiz

A causa, com evidência. Não o sintoma, não a última coisa mexida antes de melhorar.

**Cadeia causal:** o que permitiu que a causa existisse → o que fez ela se manifestar agora →
o que fez o impacto ser desse tamanho.

## As duas perguntas que importam

### Por que não foi detectado antes?

O alerta não existia? Existia e não disparou? Disparou e ninguém viu? Cada resposta gera uma
ação diferente. Tempo entre início e detecção é a métrica.

### Por que passou pelos testes e pelo review?

Faltava teste para esse caminho? O teste existia mas não cobria essa condição? O review olhou e
não viu — e por quê?

Sem essas duas seções, o postmortem apaga um incêndio e deixa a instalação elétrica intacta.

## O que funcionou bem

Não é formalidade: o que acelerou a resposta deve ser preservado e reforçado.

## O que atrapalhou

Ferramenta ausente, log inútil, runbook desatualizado, acesso faltando, alerta ruidoso demais
para se confiar nele.

## Ações

| # | ação | tipo | dono | prazo |
|---|---|---|---|---|
| 1 | | prevenir / detectar / mitigar mais rápido | | |

Ação sem dono e sem prazo é intenção. Prefira uma ação que realmente acontece a cinco que não.

Ao menos uma ação de **detecção** — se você só corrige a causa, o próximo incidente diferente vai
demorar o mesmo tanto para ser notado.

---

## Regras

- **Sem culpa a pessoas.** Quem agiu, agiu com a informação e as ferramentas que tinha. Se a
  ação parece errada em retrospecto, a pergunta é o que fez ela parecer certa na hora.
- **Sistema, não indivíduo.** "Fulano esqueceu de rodar a migração" é acusação; "o deploy permite
  subir código que depende de migração não aplicada" é causa raiz.
- **Retrospecto engana.** Ninguém sabia o final enquanto acontecia.
- **Publicado é melhor que perfeito.** Postmortem que fica em rascunho não ensina ninguém.
