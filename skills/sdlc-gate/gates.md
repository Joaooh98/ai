# Critérios dos portões

Fonte única. As skills de fase e `/sdlc-gate` referenciam este arquivo em vez de repetir os
critérios — repetido em seis lugares, ele diverge no primeiro ajuste.

Regra que vale para todos: **item que você não conseguiu verificar não é aprovado.** Marque como
não verificável e explique o que faltou. Isso bloqueia igual a uma falha.

---

## Portão 1 — Requisitos testáveis

Fonte: `docs/sdlc/01-discovery/`

- [ ] Todo critério de aceite é observável de fora do sistema
- [ ] Todo critério tem caminho de erro, não só o feliz
- [ ] Nenhum requisito cita classe, tabela, endpoint ou framework
- [ ] Lista de fora-de-escopo não está vazia
- [ ] Toda pergunta em aberto tem dono e prazo
- [ ] Tabelas de decisão completas, sem "caso contrário" implícito

## Portão 2 — Design implementável

Fonte: `docs/sdlc/02-design/`

- [ ] Todo NFR tem número e unidade
- [ ] Todo ADR lista ao menos duas alternativas e as consequências aceitas
- [ ] Toda chamada entre componentes tem timeout e comportamento de falha
- [ ] Todo endpoint de lista pagina, com default e máximo
- [ ] Todo índice aponta para um padrão de acesso listado
- [ ] Migrações são expand/contract com rollback
- [ ] Requisitos de segurança são testáveis e têm dono
- [ ] Toda tela documenta estado vazio e de erro
- [ ] **Os artefatos não se contradizem** — contrato × modelo de dados × ux-spec

Havendo integração externa, também:

- [ ] A interface interna foi definida no vocabulário do nosso domínio, não do fornecedor
- [ ] Toda operação externa tem timeout e comportamento de falha definido
- [ ] Toda integração crítica tem degradação definida e aprovada por produto
- [ ] Credenciais são rotacionáveis sem deploy

Contradição entre artefatos é blocker, e volta para os dois agentes envolvidos.

## Portão 3 — Pronto para merge

Fonte: `docs/sdlc/04-quality/` + a suíte de testes

- [ ] `code-reviewer` sem blocker aberto
- [ ] `security-auditor` sem achado BLOCK não remediado
- [ ] Todo critério de aceite mapeia para teste nomeado que existe e passa
- [ ] Suíte roda repetidamente e em ordem aleatória sem falhar
- [ ] **`tools/meta-check.sh` sai com 0** — as metas declaradas do projeto são atendidas
- [ ] Nenhum teste pulado sem dono e motivo registrado
- [ ] **A suíte roda sem rede** — nenhum teste depende de chamar o fornecedor de verdade
- [ ] Falhas do terceiro são testadas: timeout, 5xx, 429, resposta malformada, evento duplicado
- [ ] Webhook recebido verifica assinatura sobre o corpo cru, valida timestamp e deduplica

## Portão 4 — Release

Fonte: `docs/sdlc/05-delivery/` + todos os anteriores

- [ ] Cada portão anterior tem evidência anexada (caminho de arquivo, não afirmação)
- [ ] **`tools/meta-check.sh` sai com 0 na medição desta release** — não na do portão 3
- [ ] Versão coerente com semver
- [ ] Changelog derivado do diff real, não de mensagens de commit
- [ ] Critérios de rollback numéricos, com dono da decisão
- [ ] Ordem de deploy segura nas duas direções
- [ ] Observabilidade da funcionalidade nova existe **antes** do tráfego
- [ ] Breaking change tem caminho de migração publicado

---

## Verificação automática

Antes do julgamento humano, rode as duas. Cada uma responde uma pergunta diferente, e nenhuma
substitui a outra:

```bash
tools/artifact-lint.sh 01   # ou 02, 04, 05, all — o artefato está completo?
tools/meta-check.sh         # portões 3 e 4 — o projeto está dentro do que declarou?
```

| | Exit 1 significa | Verifica |
|---|---|---|
| `artifact-lint.sh` | artefato ausente, incompleto ou só o esqueleto | **estrutura** |
| `meta-check.sh` | meta blocker fora, não verificável ou desatualizada | **número** |

Os itens marcados acima verificam **conteúdo**, e é aí que entra o julgamento. Passar nas duas
automáticas não aprova o portão; reprovar em qualquer uma reprova.

**Sobre `meta-check.sh`:** ele lê relatório, nunca executa build ou teste. Rode a suíte **antes**
de avaliar o portão; avaliar com número velho é aprovar com evidência que não descreve este código.

### Bloqueio de meta não é tudo a mesma coisa

Exit 1 tem quatro causas com **donos diferentes**. Tratar todas como "defeito de código" devolve
trabalho ao agente errado e queima uma onda sem consertar nada. A saída do script já traz a linha
`AÇÃO:` de cada caso — siga-a em vez de deduzir:

| O que o script diz | Isto é | Para onde vai |
|---|---|---|
| **FORA DA META** | defeito de qualidade real | agente dono da métrica: cobertura → `test-engineer`, latência → `performance-engineer`, achado aberto → quem implementou |
| **SEM FERRAMENTA** | lacuna de calibração | instalar a ferramenta e rodar `/setup`. **Não** mexa no código |
| **NÃO VERIFICÁVEL** | a suíte não rodou nesta onda | rode o comando que gera o relatório e reavalie. Persistindo, o caminho ou o extrator em `.claude/meta.tsv` está errado |
| **DESATUALIZADA** | mediu antes da última mudança | rode a suíte de novo e reavalie |

Quando **nenhuma** meta está fora e o bloqueio é só de medição, o script diz isso em voz alta:
*"o bloqueio é de medição, resolva antes de devolver trabalho a qualquer agente"*. Nesse caso o
portão está bloqueado e **ninguém tem defeito para corrigir** — a ação é medir.

O que continua valendo: **não afrouxe a meta para o portão passar.** A meta foi decidida no
`/setup`, com dono registrado na coluna `origem`. Mudá-la é decisão do time fora do portão, não
manobra para destravar uma entrega.

Projeto sem `.claude/meta.tsv` faz `meta-check.sh` sair com 0 e avisar que não está configurado.
Isso **não** é aprovação: é a ausência do critério. Registre como lacuna e rode `/setup`.
Exit 2 é arquivo de metas malformado — problema de configuração, não de código.
