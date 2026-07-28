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

`artifact-lint.sh` sai com código 1 quando encontra artefato ausente, incompleto ou vazio — é o
que permite usá-lo como portão real em `/sdlc-gate`, e não como sugestão.

## Por que separar de MCP

MCP resolve acesso a **sistemas externos** (GitLab, Figma, VPS, documentação). Estes scripts
resolvem **fatos locais do repositório**. Um agente sem nenhum servidor MCP configurado continua
tendo os três — é o piso de capacidade da equipe, não um extra.
