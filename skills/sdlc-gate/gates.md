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
- [ ] **Nenhuma violação NOVA de conformidade arquitetural** — `tools/arch-conformance.sh` sai com
      código 0. Violação já registrada no ledger **não** reprova aqui: ela é dívida com dono e
      prazo, e reprovar por ela seria parar a entrega por algo que já estava lá
- [ ] Nenhuma isenção arquitetural vencida (o mesmo script reprova por isso)
- [ ] Todo critério de aceite mapeia para teste nomeado que existe e passa
- [ ] Suíte roda repetidamente e em ordem aleatória sem falhar
- [ ] Orçamentos de performance atendidos, quando existirem
- [ ] Nenhum teste pulado sem dono e motivo registrado
- [ ] **A suíte roda sem rede** — nenhum teste depende de chamar o fornecedor de verdade
- [ ] Falhas do terceiro são testadas: timeout, 5xx, 429, resposta malformada, evento duplicado
- [ ] Webhook recebido verifica assinatura sobre o corpo cru, valida timestamp e deduplica

## Portão 4 — Release

Fonte: `docs/sdlc/05-delivery/` + todos os anteriores

- [ ] Cada portão anterior tem evidência anexada (caminho de arquivo, não afirmação)
- [ ] Versão coerente com semver
- [ ] Changelog derivado do diff real, não de mensagens de commit
- [ ] Critérios de rollback numéricos, com dono da decisão
- [ ] Ordem de deploy segura nas duas direções
- [ ] Observabilidade da funcionalidade nova existe **antes** do tráfego
- [ ] Breaking change tem caminho de migração publicado

---

## Verificação estrutural automática

Antes do julgamento humano, rode:

```bash
tools/artifact-lint.sh 01        # ou 02, 04, 05, all
tools/arch-conformance.sh        # no Portão 3 — conformidade com a arquitetura decidida
```

Exit 1 = artefato ausente, incompleto ou só o esqueleto do template. É reprovação.

No `arch-conformance.sh`, exit 1 = violação arquitetural **nova** ou isenção vencida, e também é
reprovação. Exit 2 = as regras não estão calibradas (nenhuma casou arquivo) — não é veredito de
código, é configuração quebrada, e tratar como aprovado seria falso verde. Exit 0 sem arquivo de
regras significa que o projeto ainda não destilou as regras: rode `/arch-conformance`.

O lint verifica **estrutura**; os itens acima verificam **conteúdo**. Passar no lint não aprova
o portão.
