# Tools — Scripts de apoio da equipe

Scripts determinísticos que os agentes chamam via Bash. Existem porque reconstruir a mesma
informação a cada execução do modelo é caro, lento e inconsistente — um script devolve o mesmo
resultado sempre, e o agente gasta o raciocínio no julgamento, não na coleta.

Todos são **somente leitura**. Nenhum instala, builda, acessa a rede ou altera arquivo.

| Script | Devolve | Usado por |
|---|---|---|
| `repo-facts.sh [dir]` | Manifests, versões declaradas, comandos de build/teste, config de qualidade, CI, migrações, estado do git | `project-analyst`, qualquer builder antes da primeira linha |
| `diff-scope.sh [base]` | Escopo do diff + áreas de risco (auth, migração, segredos, infra, dependências, entrada externa) e se há teste no diff | `code-reviewer`, `security-auditor`, `release-manager` |
| `artifact-lint.sh [fase]` | Verifica se cada artefato do `docs/sdlc/` tem as seções obrigatórias do contrato de saída; detecta artefato que é só o esqueleto do template | `/sdlc-gate`, `/sdlc-status` |
| `arch-conformance.sh` | Violações da arquitetura decidida, separando **nova** (bloqueia) de dívida já registrada com dono e prazo (não bloqueia). `--baseline` imprime o ledger que congela o que já existe; `--resumo` devolve 4 linhas | `/arch-conformance`, `/sdlc-gate` (Portão 3), CI |
| `sdlc-state.sh` | Fase atual lida do disco, separando artefato real de esqueleto | `/sdlc`, `/sdlc-status` |
| `incident-evidence.sh [horas]` | O que mudou na janela: commits, arquivos por frequência, áreas de risco tocadas, tags, candidatos a bissecção | `/incident`, `root-cause-analyst` |

## Uso

```bash
tools/repo-facts.sh                    # repositório atual
tools/repo-facts.sh caminho/do/modulo  # subdiretório específico

tools/diff-scope.sh                    # diff contra main
tools/diff-scope.sh develop            # diff contra outra base

tools/artifact-lint.sh                 # todas as fases
tools/artifact-lint.sh 02              # só design
```

```bash
tools/arch-conformance.sh              # relatório completo
tools/arch-conformance.sh --resumo     # 4 linhas, para injeção em skill
tools/arch-conformance.sh --baseline > docs/sdlc/02-design/arch-debt.tsv
```

`artifact-lint.sh` sai com código 1 quando encontra artefato ausente, incompleto ou vazio — é o
que permite usá-lo como portão real em `/sdlc-gate`, e não como sugestão. O `arch-conformance.sh`
sai com 1 quando há violação arquitetural **nova**, e é o que permite chamá-lo na CI do projeto.

O `--baseline` é a consequência visível da regra "nenhum tool escreve": ele **imprime** o ledger no
stdout e quem chama redireciona. Congelar dívida arquitetural é uma decisão com dono e prazo, não
efeito colateral de uma varredura — e um script que reescreve o ledger sozinho pode apagar a
isenção que alguém registrou ontem.

## Por que separar de MCP

MCP resolve acesso a **sistemas externos** (GitLab, Figma, VPS, documentação). Estes scripts
resolvem **fatos locais do repositório**. Um agente sem nenhum servidor MCP configurado continua
tendo os três — é o piso de capacidade da equipe, não um extra.
