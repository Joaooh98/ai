# `deps` — varredura de dependências

Advisory novo em pacote que você já usava, pacote sem manutenção há anos, lockfile que não bate com
o manifest, runtime que saiu de suporte. Nada disso muda quando você não mexe no projeto — o mundo
lá fora é que muda, e o projeto envelhece parado.

| | |
|---|---|
| Agente | `security-auditor` |
| Cadência | Semanal |
| Saída | `docs/sdlc/04-quality/deps-<AAAA-MM-DD>.md` |
| Altera código? | Não — não roda `audit fix`, não sobe versão |

`security-auditor` só pode escrever em `docs/sdlc/04-quality/` (`guard-artifacts.sh`, regra 2).
O caminho acima não é preferência.

## Pré-condição

- **Precisa de rede.** As bases de advisory são remotas. Sem rede, a rotina não roda — diga isso
  em vez de reportar "nenhuma vulnerabilidade".
- Precisa de manifest e lockfile. Sem lockfile, o resultado é sobre faixas de versão, não sobre o
  que está instalado — **diga isso no relatório**, porque muda o que a lista significa.

## Procedimento

1. **Inventarie o que existe.** Não presuma um ecossistema só:

   ```bash
   ${CLAUDE_PROJECT_DIR}/.claude/ai-toolkit/tools/repo-facts.sh
   ```

   Em workspace, ele abre com o mapa dos membros. Cada membro tem o próprio manifest e a própria
   varredura. Um relatório por workspace, seções por membro.

2. **Rode a varredura do ecossistema.** A do próprio gerenciador, não uma ferramenta nova:

   | Ecossistema | Comando |
   |---|---|
   | npm / pnpm / yarn | `npm audit --json` · `pnpm audit --json` · `yarn npm audit` |
   | Python | `pip-audit` |
   | Go | `govulncheck ./...` |
   | Maven / Gradle | `mvn org.owasp:dependency-check-maven:check` · `gradle dependencyCheckAnalyze` |
   | Rust | `cargo audit` |

   Ferramenta que não está instalada **não se instala aqui**. Registre "sem varredura disponível
   para <ecossistema>" e siga — é lacuna de ferramental, e mentir sobre ela é pior que tê-la.

3. **Confira a divergência do lockfile.** Manifest e lockfile fora de sincronia significam que o
   que você testa não é o que instala em produção. `npm ci` falha nesse caso; em Maven, compare o
   `dependency:tree` com o que está declarado.

4. **Triagem por alcance, não por severidade.** É aqui que a rotina se paga — `npm audit` sozinho
   você já tinha. Para cada advisory:

   | Pergunta | Efeito |
   |---|---|
   | É dependência de produção ou só de build/teste? | Dev-only cai de prioridade |
   | O código do projeto chama o caminho vulnerável? | Não alcançável cai muito |
   | Entrada externa chega até lá? | Alcançável por usuário sobe para o topo |
   | Existe versão corrigida? | Sem correção vira mitigação, não upgrade |

   Diga **como** você concluiu alcance: `grep` da API vulnerável, `file:line` de quem chama.
   "Provavelmente não é usado" não é conclusão, é palpite.

5. **Cheque abandono e fim de suporte.** Pacote sem release há mais de dois anos com issues
   abertas de segurança é risco mesmo sem advisory. Runtime fora de suporte (Node, Python, JDK)
   é o mesmo problema numa escala maior — e nunca aparece em `audit`.

6. **Compare com o relatório anterior.** Leia o `deps-*.md` mais recente. O que interessa é o
   **delta**: advisory novo desde a última varredura. Lista idêntica sete semanas seguidas é
   ruído, e é assim que a rotina deixa de ser lida.

## Saída

```markdown
# Dependências — <AAAA-MM-DD>

Ecossistemas varridos: <lista>   ·   Sem ferramenta: <lista ou nenhum>
Comparado com: deps-<data anterior>.md

## Novo desde a última varredura

| Pacote | Versão | Advisory | Sev. | Prod? | Alcançável? | Correção |
|---|---|---|---|---|---|---|
| <nome> | <v> | <id> | alta | sim | sim — <file:line> | <versão> |

## Persistente (já reportado, sem mudança)
<lista curta — só nome e desde quando>

## Lockfile
<em sincronia | divergente: o quê>

## Abandono e fim de suporte
<pacotes e runtimes, com data do último release / fim de suporte>

## Recomendação
<o que subir primeiro e por quê — no máximo três itens>
```

## Nada a fazer

Nenhum advisory novo, lockfile em sincronia, nada saiu de suporte. Uma linha, com a data da
varredura anterior para deixar claro qual janela foi coberta.

## Agendamento

```
/schedule "toda terça às 4h13, rode /nightly deps no projeto <nome> e me mande o relatório"
```

Semanal e **não** na segunda: advisory publicado no fim de semana chega na terça com o ruído do
lançamento já assentado, e você não começa a semana com uma lista.

## Quando desligar

- Dois meses sem nada novo → provável projeto com poucas dependências diretas. Passe para mensal.
- Todo relatório sai igual ao anterior → a triagem por alcance não está sendo feita, ou ninguém
  age. Conserte a triagem antes de culpar a rotina.
- O CI já roda a mesma varredura em todo PR e falha nela → a rotina é redundante para advisory
  novo em código novo, mas **continua valendo** para advisory novo em código parado. Reduza o
  escopo a isso, ou desligue sabendo o que perdeu.
