# Production Prompt Library

Biblioteca de prompts para uso diário com Gemini, Claude e Codex.

Os prompts são independentes de modelo e não pressupõem nomes específicos de
ferramentas. O agente deve usar os recursos disponíveis no ambiente e declarar
limitações quando não conseguir verificar algo.

## Catálogo

| Necessidade | Prompt |
| --- | --- |
| Criar uma solicitação nova | `prompts/base-task.prompt.yaml` |
| Entender um projeto desconhecido | `prompts/repository-analysis.prompt.yaml` |
| Descobrir a causa de um problema | `prompts/problem-investigation.prompt.yaml` |
| Alterar ou criar código | `prompts/change-implementation.prompt.yaml` |
| Revisar código, diff ou pull request | `prompts/code-review.prompt.yaml` |
| Verificar dependências e vulnerabilidades | `prompts/dependency-audit.prompt.yaml` |
| Pesquisar um tema com fontes | `prompts/evidence-research.prompt.yaml` |
| Comparar prompts ou respostas | `prompts/result-evaluation.prompt.yaml` |

## Estrutura

Cada arquivo executável usa o mesmo contrato:

| Campo | Finalidade |
| --- | --- |
| `id` | Identificador estável para código, logs e avaliações |
| `version` | Versão semântica do prompt |
| `description` | Quando utilizar |
| `input_variables` | Entradas necessárias ou opcionais |
| `template` | Instrução enviada ao modelo |
| `metadata` | Categoria, idioma, fornecedores e tags |

Os arquivos Markdown são documentação. Os arquivos `*.prompt.yaml` são os
artefatos executáveis e versionáveis.

## Uso manual

1. Abra o YAML adequado.
2. Copie somente o conteúdo de `template`.
3. Substitua as variáveis `{{nome_da_variavel}}`.
4. Remova linhas opcionais que não se aplicam.

## Uso por código

Carregue o YAML, valide `input_variables`, renderize `template` com um mecanismo
que suporte `{{variavel}}` e registre `id` e `version` junto da execução.

Não combine todos os prompts em uma única solicitação. Prefira o menor prompt
capaz de produzir o resultado desejado.

## Princípios desta coleção

- objetivo e critérios de sucesso explícitos;
- evidências antes de conclusões;
- autonomia limitada ao escopo solicitado;
- preservação de alterações existentes;
- verificação proporcional ao risco;
- perguntas apenas quando uma decisão material não puder ser inferida;
- saída curta por padrão, detalhada quando a tarefa exigir;
- nenhuma solicitação para expor raciocínio interno;
- nenhuma dependência de comandos exclusivos de um fornecedor.

## Gemini, Claude e Codex

Use o mesmo conteúdo nos três. Consulte `PROVIDER_GUIDE.md` somente quando precisar
definir instruções persistentes ou ajustar o comportamento ao ambiente.

## Garantia de qualidade

- `registry.yaml`: relaciona prompts e datasets;
- `datasets/`: casos iniciais de regressão;
- `evaluators/`: critérios determinísticos e subjetivos;
- `schemas/`: contratos para validação automática;
- `experiments/`: protocolo de comparação e promoção.

Os exemplos são uma base inicial. A equipe deve acrescentar incidentes e falhas
reais do próprio domínio, removendo ou anonimizando dados sensíveis.

Antes de publicar mudanças, execute a validação compartilhada:

```bash
python3 -m pip install -r ../requirements-prompt-library.txt
python3 ../validate_prompt_libraries.py
```

As regras de interpolação, segurança e promoção estão em
`../RENDERING_POLICY.md`.
