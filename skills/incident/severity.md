# Severidade

A severidade decide **quanto processo roda**. É dosagem: SEV1 com processo de SEV4 vira caos;
SEV4 com processo de SEV1 vira teatro e faz o time parar de declarar incidente.

## Escala

| Sev | Critério | Resposta |
|---|---|---|
| **SEV1** | Serviço indisponível para a maioria · perda ou corrupção de dados · brecha de segurança ativa · impossível transacionar | Comando formal, mitigação imediata, atualização a cada 30 min, postmortem obrigatório |
| **SEV2** | Degradação séria · funcionalidade central quebrada para parte relevante · sem contorno viável | Comando formal, mitigação prioritária, atualização a cada 30 min, postmortem obrigatório |
| **SEV3** | Funcionalidade secundária quebrada · existe contorno · impacto limitado | Investigação direta, sem comando formal, correção no fluxo normal |
| **SEV4** | Defeito cosmético ou de baixo impacto · nenhum usuário bloqueado | Vira item de backlog, entra pelo `/sdlc` |

## Declaração

Declare incidente assim que **qualquer** um for verdade:

- O impacto é perceptível pelo cliente
- Um segundo time precisa entrar
- Uma hora de análise focada sem solução
- Há perda ou corrupção de dados, ou suspeita
- Há suspeita de comprometimento de segurança

Declarar cedo e cancelar custa quase nada. Declarar tarde é o que transforma degradação em
desastre — e o custo aparece todo de uma vez.

## Reclassificação

Severidade não é imutável. Subiu o impacto, sobe o SEV — e a comunicação acompanha. Descobriu que
era menor, desce e diga por quê.

Reclassificar para baixo **sem evidência** é o jeito mais comum de fechar um incidente que ainda
está acontecendo.

## Ajuste por projeto

Esta escala é genérica. Domínios com regulação, SLA contratual ou risco à segurança física
precisam da própria — coloque em `docs/incidents/severity.md` do projeto, que tem precedência
sobre esta.
