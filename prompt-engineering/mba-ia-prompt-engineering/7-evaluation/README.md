# Prompt Evaluation - Guia Prático

Projeto educacional demonstrando estratégias sistemáticas de avaliação de prompts para medir e comparar variações objetivamente.

## Estrutura do Projeto

Este projeto está organizado em **5 exemplos progressivos**, cada um construindo sobre conceitos anteriores:

### Índice

1. [**1-basic/**](1-basic/README.md) - Evaluators Básicos
2. [**2-precision/**](2-precision/README.md) - Métricas de Classificação (P/R/F1)
3. [**3-pairwise/**](3-pairwise/README.md) - Comparação Pairwise
4. [**4-pairwise-doc/**](4-pairwise-doc/README.md) - Pairwise com Métricas Individuais
5. [**5-langfuse/**](5-langfuse/README.md) - Langfuse (Alternativa Open-Source)

---

## 1. Evaluators Básicos

**Pasta:** [`1-basic/`](1-basic/)

**Demonstra:** Como diferentes tipos de evaluators revelam diferentes aspectos de qualidade das saídas de LLMs.

**Evaluators Cobertos:**
- **Validadores de formato**: Validade JSON, validação de schema (determinístico)
- **Juízes LLM binários**: Avaliação passa/falha (criteria)
- **Juízes LLM contínuos**: Avaliação com score 0-1 (score_string)
- **Baseados em referência**: Avaliação de correção com ground truth
- **Critérios customizados**: Evaluators específicos de domínio (faithfulness, aderência a formato)
- **Distância de embedding**: Similaridade semântica sem LLM

**Inclui:** 6 exemplos de prompts bem projetados + 4 exemplos de prompts problemáticos (verboso, alucinação, problemas de formato, respostas não úteis)

**Dataset:** 18 exemplos de code review em Go

[Documentação completa →](1-basic/README.md)

---

## 2. Precision/Recall/F1

**Pasta:** [`2-precision/`](2-precision/)

**Demonstra:** Uso de ground truth estruturado para avaliação objetiva com métricas de classificação.

**Conceitos:**
- **Precision**: Mede taxa de falsos positivos (quantos problemas reportados são reais)
- **Recall**: Mede taxa de falsos negativos (quantos problemas reais foram encontrados)
- **F1 Score**: Média harmônica balanceando precision e recall
- **Trade-offs estratégicos**: Abordagens conservadoras vs agressivas vs balanceadas

**Estratégias de Avaliação:**
- Prompts conservadores (priorizam precision)
- Prompts agressivos (priorizam recall)
- Prompts balanceados (otimizam F1)

**Dataset:** 10 exemplos com ground truth estruturado (tipos de problemas esperados, severidades, funções)

[Documentação completa →](2-precision/README.md)

---

## 3. Comparação Pairwise

**Pasta:** [`3-pairwise/`](3-pairwise/)

**Demonstra:** Comparação direta de prompts usando LLM-as-Judge para evolução mensurável de prompts.

**Conceitos:**
- **LLM-as-Judge**: Uso de LLM para comparar duas saídas
- **Rastreamento de win rate**: Comparação sistemática ao longo do dataset
- **Versionamento de prompts**: Evolução V1 → V2 com impacto mensurável
- **Especialização vs generalização**: Prompts focados vs multifocados

**Workflow:**
1. Upload do dataset no LangSmith
2. Criação de versões de prompts (A e B)
3. Execução de comparação pairwise
4. Atualização de prompts baseada em insights
5. Re-execução para medir melhoria

**Dataset:** 10 exemplos (problemas de segurança + performance)

[Documentação completa →](3-pairwise/README.md)

---

## 4. Pairwise com Métricas Individuais

**Pasta:** [`4-pairwise-doc/`](4-pairwise-doc/)

**Demonstra:** Entender POR QUE um prompt vence ao combinar julgamento pairwise com métricas individuais granulares.

**Camadas de Avaliação:**
- **6 métricas individuais** (concisão, coerência, detalhe, utilidade, faithfulness, completude)
- **Juiz LLM 5-dimensional** com raciocínio estruturado (completude estrutural, precisão técnica, clareza, alinhamento com referência, concisão vs detalhe)
- **Justificativas detalhadas** para cada dimensão

**Diferença Principal da Fase 3:** Não apenas "A vence", mas "A vence por causa de X, Y, Z com breakdown detalhado"

**Dataset:** Projetos Python para geração de documentação

[Documentação completa →](4-pairwise-doc/README.md)

---

## 5. Langfuse (Open-Source)

**Pasta:** [`5-langfuse/`](5-langfuse/)

**Demonstra:** Implementação de conceitos de avaliação usando uma plataforma open-source auto-hospedada como alternativa ao LangSmith.

**Diferenças Principais:**
- **Hospedagem**: Auto-hospedado (Docker) ou cloud
- **Open Source**: Licença MIT, acesso completo ao código
- **Implementação**: Lógica pairwise manual vs APIs nativas
- **Controle**: Controle granular sobre o fluxo de avaliação

**Conceitos:** Mesmos princípios de avaliação, plataforma de implementação diferente

**Dataset:** Mesmo conceito da Fase 4 (geração de documentação)

[Documentação completa →](5-langfuse/README.md)

---

## Setup Rápido

**Importante:** Este capítulo é auto-contido e possui seu próprio `requirements.txt` e ambiente virtual (`venv/`), independente dos demais capítulos do curso.

### Pré-requisitos

```bash
# 1. Criar virtual environment (específico deste capítulo)
python -m venv venv
source venv/bin/activate  # Linux/Mac
# ou
venv\Scripts\activate  # Windows

# 2. Instalar dependências (do requirements.txt local)
pip install -r requirements.txt
```

### Variáveis de Ambiente

Criar arquivo `.env` na raiz:

```bash
# LangSmith (exemplos 1-4)
LANGSMITH_API_KEY=seu-api-key
LANGCHAIN_TRACING_V2=true

# OpenAI (todos os exemplos)
OPENAI_API_KEY=seu-api-key

# Opcional: Configuração do modelo
LLM_MODEL=gpt-4o-mini
LLM_TEMPERATURE=0

# Langfuse (exemplo 5 - opcional)
LANGFUSE_SECRET_KEY=sk-lf-...
LANGFUSE_PUBLIC_KEY=pk-lf-...
LANGFUSE_HOST=http://localhost:3000
```

### Executando os Exemplos

Cada pasta tem seu próprio workflow:

```bash
# Ativar venv
source venv/bin/activate

# Evaluators básicos
cd 1-basic
python 1-format-eval.py

# Precision/Recall
cd ../2-precision
python 1-conservative-high-precision.py

# Pairwise
cd ../3-pairwise
python upload_dataset.py  # primeira vez apenas
python create_prompts.py  # primeira vez apenas
python run.py

# Pairwise com métricas
cd ../4-pairwise-doc
python upload_dataset.py  # primeira vez apenas
python create_prompt.py   # primeira vez apenas
python run.py

# Langfuse
cd ../5-langfuse
python upload_dataset.py  # primeira vez apenas
python create_prompts.py  # primeira vez apenas
python run.py
```

---

## Caminho de Aprendizado

**Progressão recomendada:**

1. **Fase 1 (Básico)**: Entender diferentes tipos de evaluators e quando usar cada um
2. **Fase 2 (Precision/Recall)**: Aprender métricas de classificação com ground truth
3. **Fase 3 (Pairwise)**: Dominar LLM-as-Judge para comparação de prompts
4. **Fase 4 (Pairwise + Métricas)**: Combinar pairwise com métricas individuais para insights profundos
5. **Fase 5 (Langfuse)**: Explorar plataformas alternativas e implementação manual

---

## Recursos Adicionais

- **Documentação técnica completa:** Veja [`AGENTS.md`](AGENTS.md)
- **LangSmith Dashboard:** https://smith.langchain.com/
- **Langfuse Docs:** https://langfuse.com/docs
- **LangChain Evaluation Guide:** https://python.langchain.com/docs/guides/productionization/evaluation/
