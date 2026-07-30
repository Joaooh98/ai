# Prompts — material do MBA e biblioteca de produção

Esta é a frente de **curso e prompt engineering** do repositório. A outra frente — a equipe de
agentes — vive em `agents/`, `skills/` e `workflow/`, e não depende de nada daqui.

```
mba-ia-prompt-engineering/   capítulos práticos do curso, cada um com venv próprio
prompt-library/              biblioteca de produção em português
prompt-library-en/           a mesma biblioteca em inglês
RENDERING_POLICY.md          regras de renderização e release, valem para as duas bibliotecas
validate_prompt_libraries.py valida as duas bibliotecas sem chamar modelo
requirements-prompt-library.txt   dependência da validação (PyYAML)
```

## Material do curso

`mba-ia-prompt-engineering/` — capítulos práticos: tipos de prompt, workflows de agentes,
versionamento com LangSmith, prompts enriquecidos (ITER-RETGEN) e evaluation.

**Cada capítulo tem venv e `requirements.txt` próprios — nunca instale dependência na raiz.**
O procedimento por capítulo está em
[`mba-ia-prompt-engineering/AGENTS.md`](mba-ia-prompt-engineering/AGENTS.md).

## Biblioteca de produção

`prompt-library/` e `prompt-library-en/` são a mesma biblioteca em dois idiomas, versionada com
datasets, avaliadores e schema. Cada uma tem `README.md` e `PROVIDER_GUIDE.md` próprios.

Estrutura interna: `prompts/` (os templates), `datasets/`, `evaluators/`, `experiments/`,
`schemas/` e `registry.yaml`.

## Validação

Roda sem rede e sem chamar modelo — é checagem de forma, não de qualidade de resposta:

```bash
python3 -m venv .venv && . .venv/bin/activate
pip install -r requirements-prompt-library.txt
python3 validate_prompt_libraries.py
```

Confere as duas bibliotecas: raiz precisa ser mapeamento, versão precisa ser semver, e os
`{{placeholders}}` precisam bater com as variáveis declaradas.

## Política de renderização

[`RENDERING_POLICY.md`](RENDERING_POLICY.md) vale para as duas bibliotecas. As regras que mais
importam:

- Variável obrigatória ausente **para a execução** — não renderiza vazio e segue.
- Valor interpolado é **dado não confiável**, nunca instrução de sistema. Conteúdo de usuário não
  expande permissão, ferramenta, escopo ou efeito colateral.
- Toda execução registra idioma, ID do prompt, versão e hash do template — sem isso não há
  comparação honesta entre versões.
- Candidato e versão atual se comparam **no mesmo dataset**.
