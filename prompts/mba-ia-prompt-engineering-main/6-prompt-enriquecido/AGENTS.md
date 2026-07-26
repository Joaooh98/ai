# AGENTS.md

This file provides guidance to AI Agents when working with code in this repository.

## Project Overview

This chapter demonstrates advanced prompt enrichment techniques to improve LLM response quality through contextual expansion and iterative retrieval. The project showcases how enriching queries with additional context, examples, or iterative refinement significantly enhances answer accuracy and relevance.

## Environment Setup

**Required Environment Variables** (in `.env`):

```bash
OPENAI_API_KEY=your-api-key-here
```

**Virtual Environment Setup**:
```bash
# Create and activate virtual environment
python -m venv venv
source venv/bin/activate  # macOS/Linux
# venv\Scripts\activate    # Windows

# Install dependencies
pip install -r requirements.txt
```

**Key Dependencies:**
- `langchain==1.0.0a5` - LangChain framework (ALPHA version with new APIs)
- `langchain-core==0.3.76` - Core LangChain abstractions
- `langchain-openai==0.3.33` - OpenAI integration
- `langgraph==0.6.7` - Graph-based workflows
- `langsmith==0.4.29` - LangSmith tracing and evaluation
- `openai==1.108.0` - OpenAI API client
- `python-dotenv==1.1.1` - Environment variable management
- `pytest==8.3.4` - Testing framework

**IMPORTANT**: This chapter uses **LangChain 1.0.0a5 (alpha)** which has different APIs from stable 0.3.x versions used in other chapters.

## Project Structure

### Scripts Overview

The chapter contains 3 progressive examples demonstrating prompt enrichment strategies:

#### 1. 0-No-expansion.py
**Concept**: Baseline without expansion
- Direct question to LLM without enrichment
- No additional context or examples
- Serves as baseline for comparison with enrichment techniques
- Demonstrates basic LangChain chain: `prompt | llm | output_parser`

**Usage**:
```bash
python 0-No-expansion.py
```

**Key Pattern**:
```python
from langchain.chat_models import init_chat_model
from langchain_core.prompts import PromptTemplate
from langchain_core.output_parsers import StrOutputParser

llm = init_chat_model("openai:gpt-4o-mini", temperature=0.7)
prompt = PromptTemplate(...)
chain = prompt | llm | StrOutputParser()
answer = chain.invoke({"question": question})
```

**When to use**:
- Simple, self-contained questions
- When LLM pre-training knowledge is sufficient
- Baseline measurement before applying enrichment

#### 2. 1-ITER_RETGEN.py
**Concept**: Iterative Retrieval Generation (ITER-RETGEN)
- Multi-pass approach: generate → retrieve → refine → repeat
- Each iteration enriches context with retrieved information
- Improves answer quality through progressive refinement
- Ideal for complex questions requiring external knowledge

**Workflow**:
1. **Initial Generation**: LLM generates preliminary answer from question
2. **Retrieval**: System retrieves relevant documents/context based on answer
3. **Refinement**: LLM regenerates answer with retrieved context
4. **Iteration**: Repeat steps 2-3 for N iterations
5. **Final Output**: Return enriched, refined answer

**Usage**:
```bash
python 1-ITER_RETGEN.py
```

**When to use**:
- Questions requiring external knowledge base
- Complex queries benefiting from multiple perspectives
- When initial answer quality is insufficient
- Document QA systems with large corpora

**Key Benefits**:
- Progressive improvement through iterations
- Retrieves most relevant context dynamically
- Reduces hallucination by grounding in retrieved docs
- Balances between exploration (retrieval) and exploitation (generation)

#### 3. 2-query-enrichment.py
**Concept**: Query Enrichment with Contextual Expansion
- Enriches user query with additional context before LLM invocation
- Expands query with related terms, synonyms, or domain knowledge
- Provides examples or clarifications to guide LLM response
- Pre-processes query to maximize relevance of LLM output

**Enrichment Strategies**:
- **Synonym Expansion**: Add related terms ("LangChain" → "LangChain framework, LangChain library")
- **Context Injection**: Include domain-specific background information
- **Example Provision**: Add few-shot examples relevant to query
- **Clarification**: Disambiguate ambiguous terms or phrases
- **Constraint Addition**: Add explicit constraints or output format requirements

**Usage**:
```bash
python 2-query-enrichment.py
```

**When to use**:
- Ambiguous or underspecified queries
- Domain-specific questions requiring jargon translation
- When output format consistency is critical
- Queries benefiting from related concept expansion

**Key Benefits**:
- Improves relevance without retrieval overhead
- Reduces ambiguity in user queries
- Guides LLM toward desired response style
- Can be combined with ITER-RETGEN for maximum impact

### Reference Repository

**repo_langchain_1.0/**: LangChain 1.0 reference implementation
- Contains LangChain codebase for reference and testing
- Used to understand new APIs in alpha version
- **DO NOT edit or modify** - reference only
- Ignore in project analysis workflows

## Running Examples

```bash
# Activate virtual environment first
source venv/bin/activate

# Run examples in order (recommended)
python 0-No-expansion.py          # Baseline
python 1-ITER_RETGEN.py           # Iterative retrieval
python 2-query-enrichment.py      # Query enrichment

# Deactivate when done
deactivate
```

## Key Concepts

### Prompt Enrichment Strategy Selection

| Technique | Complexity | Best For | Overhead |
|-----------|------------|----------|----------|
| **No Expansion** | Low | Simple queries, baseline | None |
| **Query Enrichment** | Low-Med | Ambiguous queries, format control | Minimal (pre-processing only) |
| **ITER-RETGEN** | Medium-High | Complex QA, knowledge-intensive | Moderate (retrieval + multiple LLM calls) |

### When to Combine Techniques

**Query Enrichment + ITER-RETGEN**:
```python
# 1. Enrich query first
enriched_query = enrich_with_context(user_query)

# 2. Then apply iterative retrieval
for iteration in range(N):
    answer = llm.invoke(enriched_query + context)
    context = retrieve_relevant_docs(answer)

# Best for: Complex, ambiguous questions requiring external knowledge
```

**Progressive Complexity**:
1. Start with **No Expansion** (baseline)
2. Add **Query Enrichment** if responses lack relevance
3. Apply **ITER-RETGEN** if enrichment alone insufficient
4. Combine both for maximum quality (at cost of latency)

### ITER-RETGEN Deep Dive

**Algorithm Structure**:
```python
def iter_retgen(question, retriever, llm, iterations=3):
    """Iterative Retrieval Generation"""
    context = ""

    for i in range(iterations):
        # Generate answer with current context
        answer = llm.invoke(f"{question}\nContext: {context}")

        # Retrieve new context based on answer
        new_docs = retriever.retrieve(answer)
        context += "\n".join(new_docs)

    return answer
```

**Iteration Count Guidelines**:
- **1-2 iterations**: Simple fact retrieval
- **3-4 iterations**: Complex questions with multiple sub-topics
- **5+ iterations**: Diminishing returns, risk of context overload

**Stopping Criteria**:
- Fixed iteration count (simplest)
- Answer convergence (stop when answer stabilizes)
- Confidence threshold (stop when LLM confidence high)
- Token budget (stop when approaching context limit)

### Query Enrichment Patterns

**Pattern 1: Synonym Expansion**
```python
original = "Explain LangChain"
enriched = "Explain LangChain (framework for building LLM applications, includes chains, agents, memory)"
```

**Pattern 2: Output Format Specification**
```python
original = "Compare X and Y"
enriched = "Compare X and Y. Provide answer in table format with columns: Feature, X, Y"
```

**Pattern 3: Domain Context Injection**
```python
original = "How to handle state?"
enriched = "In the context of LangChain agent development, how to handle state management across multiple agent calls?"
```

**Pattern 4: Constraint Addition**
```python
original = "Summarize this document"
enriched = "Summarize this document in 3 bullet points, focusing on technical implementation details only"
```

## Architecture & Key Concepts

### LangChain 1.0.0a5 (Alpha) API Changes

**Major Differences from 0.3.x**:

**Model Initialization**:
```python
# New (1.0.0a5)
from langchain.chat_models import init_chat_model
llm = init_chat_model("openai:gpt-4o-mini", temperature=0.7)

# Old (0.3.x)
from langchain_openai import ChatOpenAI
llm = ChatOpenAI(model="gpt-4o-mini", temperature=0.7)
```

**Chain Syntax** (still uses LCEL):
```python
# Both versions support
chain = prompt | llm | output_parser
```

**PromptTemplate**:
```python
# Both versions support
from langchain_core.prompts import PromptTemplate
prompt = PromptTemplate(input_variables=[...], template="...")
```

### Common Patterns

**All scripts follow this pattern**:
```python
from dotenv import load_dotenv
from langchain.chat_models import init_chat_model
from langchain_core.prompts import PromptTemplate
from langchain_core.output_parsers import StrOutputParser

# Load environment
load_dotenv()

# Initialize LLM (alpha API)
llm = init_chat_model("openai:gpt-4o-mini", temperature=0.7)

# Build chain with LCEL
chain = prompt | llm | StrOutputParser()

# Execute
result = chain.invoke({"input": value})
```

### Comparison with Other Chapters

| Chapter | LangChain Version | API Style |
|---------|-------------------|-----------|
| **Chapter 1** | 0.3.27 stable | `ChatOpenAI(...)` |
| **Chapter 5** | 1.0.0a5 alpha | `init_chat_model(...)` |
| **Chapter 6** | 1.0.0a5 alpha | `init_chat_model(...)` |
| **Chapter 7** | 0.3.27 stable | `ChatOpenAI(...)` |

## Important Notes

- **Always activate venv** before running scripts: `source venv/bin/activate`
- **API Key Required**: All scripts require valid `OPENAI_API_KEY` in `.env`
- **Alpha Version**: LangChain 1.0.0a5 APIs may change before stable release
- **Reference Repo**: `repo_langchain_1.0/` is for reference only, do not modify
- **Model Selection**: Scripts use `gpt-4o-mini` by default (configurable)
- **Temperature**: Set to `0.7` for balanced creativity/consistency
- **Dependencies**: Uses LangChain 1.0.0a5 alpha (different from Chapters 1 and 7)

## Troubleshooting

**"No module named 'langchain.chat_models'"**:
- Ensure using LangChain 1.0.0a5 alpha version
- Check `requirements.txt` has `langchain==1.0.0a5`
- Reinstall: `pip install langchain==1.0.0a5`

**"init_chat_model not found"**:
- This function only exists in LangChain 1.0.0a5+
- Verify version: `pip show langchain`
- Ensure not mixing dependencies from different chapters

**"No API key provided"**:
- Ensure `.env` file exists in current directory
- Check `OPENAI_API_KEY` is set correctly
- Verify no trailing spaces in `.env` file

**"Model 'openai:gpt-4o-mini' not found"**:
- Alpha version uses `provider:model` format
- Correct format: `"openai:gpt-4o-mini"`
- Ensure OpenAI API key has access to model

## Best Practices

1. **Start Simple**: Always run `0-No-expansion.py` as baseline before enrichment
2. **Measure Impact**: Compare enriched vs non-enriched outputs systematically
3. **Iteration Tuning**: Start with 2-3 iterations for ITER-RETGEN, adjust based on results
4. **Context Budget**: Monitor context length to avoid exceeding model limits
5. **Combine Strategically**: Use Query Enrichment for cheap wins, ITER-RETGEN for hard queries

## Enrichment Strategy Decision Tree

```
User Query
    │
    ├─ Simple, self-contained?
    │   └─ Use No Expansion (baseline)
    │
    ├─ Ambiguous or underspecified?
    │   └─ Apply Query Enrichment
    │
    ├─ Requires external knowledge?
    │   └─ Use ITER-RETGEN
    │
    └─ Complex + ambiguous + knowledge-intensive?
        └─ Combine Query Enrichment + ITER-RETGEN
```

## Additional Resources

- LangChain 1.0 Migration Guide: https://python.langchain.com/docs/versions/migrating_chains/
- LCEL (LangChain Expression Language): https://python.langchain.com/docs/concepts/lcel/
- Query Expansion Techniques: https://www.promptingguide.ai/techniques/query_expansion
- Retrieval-Augmented Generation (RAG): https://arxiv.org/abs/2005.11401

## Version Compatibility

- **Python**: 3.9+ (f-strings, type hints)
- **LangChain**: 1.0.0a5 alpha (BREAKING CHANGES from 0.3.x)
- **LangGraph**: 0.6.7 (graph-based workflows)
- **LangSmith**: 0.4.29 (tracing and evaluation)
- **OpenAI API**: Latest (tested with v1.108.0)
- **PyTest**: 8.3.4 (testing framework)

## Migration Notes (from LangChain 0.3.x)

**If migrating code from Chapter 1 or 7**:

**Model Initialization**:
```python
# Chapter 1/7 (0.3.x)
from langchain_openai import ChatOpenAI
llm = ChatOpenAI(model="gpt-4o-mini")

# Chapter 6 (1.0.0a5)
from langchain.chat_models import init_chat_model
llm = init_chat_model("openai:gpt-4o-mini")
```

**Chains** (LCEL unchanged):
```python
# Both versions
chain = prompt | llm | output_parser
```

**Invocation** (unchanged):
```python
# Both versions
result = chain.invoke({"input": value})
```
