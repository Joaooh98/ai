# `docs-drift` — deriva de documentação

Documentação errada é pior que documentação ausente, porque é confiada. Quem chega novo executa o
comando do README, ele falha, e a conclusão que a pessoa tira é sobre a própria competência — não
sobre o arquivo.

Deriva não acontece num commit: acontece quando o script muda de nome, a flag some, a porta muda.
Ninguém abre o README nesse momento.

| | |
|---|---|
| Agente | `tech-writer` |
| Cadência | Semanal |
| Saída | `docs/sdlc/06-docs/docs-drift-<AAAA-MM-DD>.md` |
| Altera código? | Não — nem a documentação. Reporta o que quebrou |

## Pré-condição

Precisa de um ambiente onde executar. Cloud agent tem clone limpo e nada rodando: comando que
depende de banco de pé vai falhar por ausência de ambiente, **não** por deriva. Classificar isso
errado enche o relatório de falso positivo e mata a rotina em duas semanas.

Antes de começar, rode `${CLAUDE_PROJECT_DIR}/.claude/ai-toolkit/tools/preview-env.sh` para saber
o que o projeto precisa de pé e o que já está — ele não sobe nada. Registre no relatório o que
**não** estava disponível.

## Procedimento

1. **Colete os comandos documentados.** Blocos cercados em `README.md`, `docs/**/*.md`,
   `CONTRIBUTING.md` e no `.claude/toolbelt.md`. O toolbelt é o mais importante: é ele que os 27
   agentes carregam em toda invocação — comando errado ali erra em todas as sessões, não só na de
   quem leu o README.

2. **Separe executável de ilustrativo.** Bloco de saída de exemplo, YAML de config e trecho de
   código não são comandos. Executar isso gera ruído.

3. **Recuse o que é destrutivo.** Esta é a regra que faz a rotina poder rodar sem ninguém olhando.
   **Não execute** comando que contenha: `rm`, `drop`, `delete`, `truncate`, `push`, `deploy`,
   `publish`, `terraform apply`, `kubectl apply/delete`, `docker system prune`, migração para
   frente ou para trás, ou qualquer coisa que fale com produção.

   Esses entram no relatório como **não verificado**, com o motivo. Documentação de comando
   perigoso continua podendo estar errada — mas descobrir isso não é trabalho de rotina noturna.

4. **Execute os seguros, em diretório descartável.** Instalação, build, teste, lint, `--help`,
   `--version`, geração. Um por vez, capturando saída e código de saída.

5. **Classifique cada falha.** Sem isto o relatório não distingue deriva de ambiente:

   | Classe | O que significa | Ação |
   |---|---|---|
   | Deriva | Comando não existe mais, flag inválida, caminho mudou | Corrigir a doc |
   | Ambiente | Falta serviço, credencial, rede | Nada — anotar como não verificado |
   | Quebra real | Comando certo, projeto quebrado | Vira defeito, não item de doc |

   A terceira é a mais valiosa e a que ninguém procura: o README está certo e o **projeto** é que
   parou de funcionar.

6. **Verifique também o que não é comando.** Link interno apontando para arquivo que não existe
   mais, e caminho citado no texto (`src/services/foo.ts`) que sumiu. Barato de checar, e é onde a
   deriva costuma começar.

7. **Não conserte a documentação.** A correção passa por quem sabe qual era a intenção. Rotina que
   reescreve README sozinha troca um comando errado por um comando plausível.

## Evidência obrigatória

Para cada falha: o comando exato, o arquivo e a linha onde está documentado, e a **saída real**
com o código de saída. Sem a saída, quem for corrigir não sabe se muda a doc ou o código.

## Saída

```markdown
# Deriva de documentação — <AAAA-MM-DD>

Arquivos varridos: <n>   ·   Comandos encontrados: <n>
Executados: <n>   ·   Recusados por segurança: <n>   ·   Sem ambiente: <n>

## Deriva confirmada

| Onde | Comando | Saída |
|---|---|---|
| README.md:42 | `npm run build:prod` | `Missing script: "build:prod"` (exit 1) |

### README.md:42
```
<saída real colada>
```
Scripts que existem hoje: `build`, `build:ci`. → provável renomeação.

## Quebra real (doc certa, projeto quebrado)
<lista — cada item vira defeito, não correção de texto>

## Não verificado
| Comando | Motivo |
|---|---|
| `terraform apply` | recusado — destrutivo |
| `docker compose up` | sem ambiente no cloud agent |

## Links e caminhos mortos
<arquivo:linha → alvo inexistente>

## Nada a fazer
<ou: "todos os N comandos executáveis rodaram como documentado.">
```

## Nada a fazer

Todo comando executável rodou com o resultado documentado, e nenhum caminho citado sumiu. Uma
linha — dizendo quantos foram executados e quantos ficaram sem verificação, senão "tudo ok"
esconde que 80% não foi testado.

## Agendamento

```
/schedule "toda quinta às 2h23, rode /nightly docs-drift no projeto <nome> e me mande o relatório"
```

## Quando desligar

- Mais da metade dos comandos cai em "sem ambiente" → a rotina está medindo o cloud agent, não a
  documentação. Ou dá ambiente a ela, ou roda em máquina que já tem o projeto de pé.
- Nenhuma deriva em dois meses **e** o projeto está em mudança ativa → suspeite da coleta antes de
  comemorar: provavelmente os comandos não estão sendo encontrados.
- O projeto tem poucos comandos e todos já rodam no CI → o CI é o lugar disso. Desligue.
