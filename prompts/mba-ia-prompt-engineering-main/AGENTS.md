# AGENTS.md

This file provides guidance to AI Agents when working with code in this repository.

## Folder-Specific Setup and Dependencies

### Chapter 1: Tipos de Prompts
```bash
cd 1-tipos-de-prompts/

# Setup
python -m venv venv
source venv/bin/activate  # macOS/Linux
pip install -r requirements.txt

# Configure environment
cp .env.example .env
# Edit .env and add: OPENAI_API_KEY=...
```

**Key Dependencies:**
- langchain==0.3.27
- langchain-openai==0.3.32
- openai==1.102.0
- rich==14.1.0
- python-dotenv==1.1.1

**Scripts:**
```bash
python 0-Role-prompting.py          # Role-based prompting
python 1-zero-shot.py               # Zero-shot prompting
python 2-one-few-shot.py            # One-shot and few-shot examples
python 3-CoT.py                     # Chain of Thought
python 3.1-CoT-Self-consistency.py  # CoT with self-consistency
python 4-ToT.py                     # Tree of Thoughts
python 5-SoT.py                     # Skeleton of Thought
python 6-ReAct.py                   # ReAct framework
python 7-Prompt-channing.py         # Prompt chaining (generates output file)
python 8-Least-to-most.py           # Least-to-most decomposition
```

### Chapter 4: Prompts e Workflow de Agentes
```bash
cd 4-prompts-e-workflow-de-agentes/

# No specific requirements.txt - uses root dependencies
# Structure:
#   agents/    - Agent implementations for architectural analysis
#   commands/  - Command implementations for agent orchestration
```

### Chapter 5: Gerenciamento e Versionamento de Prompts
```bash
cd 5-gerenciamento-e-versionamento-de-prompts/

# Setup
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Configure environment
cp .env.example .env
```

**Environment Variables:**
```bash
# Required
OPENAI_API_KEY=sk-your-api-key-here

# Optional (for LangSmith integration)
LANGCHAIN_TRACING_V2=false
LANGCHAIN_ENDPOINT=https://api.smith.langchain.com
LANGCHAIN_API_KEY=your-langsmith-key-here
LANGCHAIN_PROJECT=prompt-management-system
```

**Key Dependencies (updated versions):**
- langchain==1.0.0a5
- langchain-core==0.3.76
- langchain-openai==0.3.33
- langgraph==0.6.7
- langgraph-prebuilt==0.6.4
- langsmith==0.4.29
- pytest==8.3.4
- Jinja2==3.1.6

**Commands:**
```bash
# Run agents
python src/agent_code_reviewer.py
python src/agent_pull_request.py

# Run tests
pytest tests/test_prompts.py -v
pytest tests/ -v  # All tests
```

### Chapter 6: Prompt Enriquecido
```bash
cd 6-prompt-enriquecido/

# Setup
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Configure environment
cp .env.example .env
# Edit .env and add: OPENAI_API_KEY=KEY
```

**Key Dependencies (same as Chapter 5):**
- langchain==1.0.0a5
- langchain-core==0.3.76
- langchain-openai==0.3.33
- langgraph==0.6.7
- langsmith==0.4.29
- openai==1.108.0
- pytest==8.3.4

**Scripts:**
```bash
python 0-No-expansion.py          # Basic prompting without expansion
python 1-ITER_RETGEN.py           # Iterative retrieval generation
python 2-query-enrichment.py      # Query enrichment techniques
```

**Additional Resource:**
- `repo_langchain_1.0/`: Contains LangChain reference implementation for testing

### Chapter 7: Evaluation
```bash
cd 7-evaluation/

# Setup
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Configure environment
cp .env.example .env
# Edit .env and add keys
```

**Environment Variables:**
```bash
# LangSmith (examples 1-4)
LANGSMITH_API_KEY=your-api-key
LANGCHAIN_TRACING_V2=true

# OpenAI (all examples)
OPENAI_API_KEY=your-api-key

# Optional: Model configuration
LLM_MODEL=gpt-4o-mini
LLM_TEMPERATURE=0

# Langfuse (example 5 - optional)
LANGFUSE_SECRET_KEY=sk-lf-...
LANGFUSE_PUBLIC_KEY=pk-lf-...
LANGFUSE_HOST=http://localhost:3000
```

**Key Dependencies:**
- langchain==0.3.27
- langchain-openai==0.3.34
- langsmith==0.4.32
- langfuse==3.6.1
- openevals==0.1.0

**Shared Utilities Architecture:**
- `shared/clients.py` - LLM and observability clients (OpenAI, LangSmith, Langfuse)
- `shared/prompts.py` - YAML prompt loading and execution utilities
- `shared/datasets.py` - Dataset upload with metadata support
- `shared/evaluators.py` - Helper functions for prepare_data
- `shared/parsers.py` - JSON parsing with markdown removal

**Examples Structure:**
```bash
# 1-basic/ - Basic evaluators
python 1-basic/1-format-eval.py

# 2-precision/ - Classification metrics (P/R/F1)
python 2-precision/1-conservative-high-precision.py

# 3-pairwise/ - Pairwise comparison
cd 3-pairwise
python upload_dataset.py  # first time only
python create_prompts.py  # first time only
python run.py

# 4-pairwise-doc/ - Pairwise with individual metrics
cd 4-pairwise-doc
python upload_dataset.py
python create_prompt.py
python run.py

# 5-langfuse/ - Langfuse (open-source alternative)
cd 5-langfuse
python upload_dataset.py
python create_prompts.py
python run.py
```

## Project Architecture

### Core Structure
- **1-tipos-de-prompts/**: Técnicas fundamentais de prompt engineering
  - 9 scripts demonstrando várias estratégias de prompting
  - `utils.py`: Utilitário compartilhado para saída formatada com Rich
  - Próprio `requirements.txt` e configuração `.env`

- **4-prompts-e-workflow-de-agentes/**: Implementações de workflows baseados em agentes
  - `agents/`: Agentes especializados para análise de código
  - `commands/`: Camada de comando para coordenação de agentes
  - Usa dependências do projeto raiz

- **5-gerenciamento-e-versionamento-de-prompts/**: Gerenciamento avançado de prompts
  - `src/`: Implementações de agentes para code review e criação de PRs
  - `tests/`: Validação de prompts baseada em pytest
  - `prompts/`: Armazenamento versionado de prompts com sistema de registry
  - Suporta gerenciamento local e remoto via LangSmith
  - Próprio `requirements.txt` com versões mais recentes de LangChain e LangGraph

- **6-prompt-enriquecido/**: Técnicas avançadas de enriquecimento de prompts
  - Exemplos de expansão e enriquecimento de queries
  - Implementação ITER-RETGEN (Iterative Retrieval Generation)
  - Usa mesmas dependências do Capítulo 5
  - Inclui repositório LangChain para referência

- **7-evaluation/**: Avaliação sistemática de prompts e LLMs
  - 5 exemplos progressivos de evaluation
  - Métricas básicas, precision/recall/F1, comparação pairwise
  - Integração com LangSmith e Langfuse
  - Datasets para code review e documentação
  - Próprio `requirements.txt` e configuração `.env`

### Padrões Comuns Entre Todas as Pastas

**IMPORTANTE: Cada pasta é auto-contida**, possuindo:
- Próprio ambiente virtual (`venv/`)
- Próprio arquivo de dependências (`requirements.txt`)
- Própria configuração de variáveis de ambiente (`.env`)

Padrões compartilhados:
- Todas usam `python-dotenv` para configuração de ambiente
- LangChain como framework principal de interação com LLMs
- Rich library para saída formatada no terminal (Capítulo 1)
- Flexibilidade de modelos com alternativas comentadas
- Tratamento de erros consistente com mensagens descritivas

### Diferenças de Versões Entre Pastas

**Capítulos 1 e 7 (exemplos básicos e evaluation):**
- Usa LangChain 0.3.27 estável
- Dependências básicas para demonstrações de prompt engineering

**Capítulos 5 e 6 (recursos avançados):**
- Usa LangChain 1.0.0a5 (versão alpha)
- Inclui LangGraph para workflows baseados em grafos
- Adiciona Jinja2 para processamento de templates
- Inclui pytest para testes

## Comandos de Teste
```bash
# Capítulos 5 e 6 (com pytest)
cd 5-gerenciamento-e-versionamento-de-prompts/
pytest tests/ -v                    # Todos os testes
pytest tests/test_prompts.py -v     # Arquivo de teste específico
pytest -k "test_name" -v            # Teste por padrão de nome
```

## Arquivos de Saída
- **Capítulo 1:** `prompt_chaining_result.md` - Gerado por 7-Prompt-channing.py
- **Capítulo 5:** Vários arquivos `.json` e `.yaml` para versionamento de prompts no diretório `prompts/`

## Início Rápido para Cada Capítulo
```bash
# Capítulo 1 - Prompt Engineering Básico
cd 1-tipos-de-prompts && python -m venv venv && source venv/bin/activate
pip install -r requirements.txt && cp .env.example .env
# Adicionar OPENAI_API_KEY ao .env
python 1-zero-shot.py

# Capítulo 5 - Gerenciamento de Prompts
cd 5-gerenciamento-e-versionamento-de-prompts && python -m venv venv && source venv/bin/activate
pip install -r requirements.txt && cp .env.example .env
# Adicionar OPENAI_API_KEY e opcionalmente chaves LangSmith ao .env
python src/agent_code_reviewer.py

# Capítulo 6 - Prompts Enriquecidos
cd 6-prompt-enriquecido && python -m venv venv && source venv/bin/activate
pip install -r requirements.txt && cp .env.example .env
# Adicionar OPENAI_API_KEY ao .env
python 2-query-enrichment.py

# Capítulo 7 - Evaluation
cd 7-evaluation && python -m venv venv && source venv/bin/activate
pip install -r requirements.txt && cp .env.example .env
# Adicionar OPENAI_API_KEY e LANGSMITH_API_KEY ao .env
python 1-basic/1-format-eval.py
```