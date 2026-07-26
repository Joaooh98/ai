# AGENTS.md

This file provides guidance to AI Agents when working with code in this repository.

## Project Overview

This chapter demonstrates fundamental prompt engineering techniques through 9 practical examples. Each script showcases a different prompting strategy, progressing from basic techniques to advanced multi-step reasoning approaches.

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
- `langchain==0.3.27` - LangChain framework for LLM interactions
- `langchain-openai==0.3.32` - OpenAI integration
- `openai==1.102.0` - OpenAI API client
- `rich==14.1.0` - Terminal formatting and output styling
- `python-dotenv==1.1.1` - Environment variable management

## Project Structure

### Scripts Overview

The chapter contains 9 progressive examples demonstrating different prompting techniques:

#### 1. 0-Role-prompting.py
**Concept**: Role-based prompting
- Assigns a specific role/persona to the LLM (e.g., "You are a helpful assistant")
- Influences response style and expertise level
- Foundation for all other prompting techniques

**Usage**:
```bash
python 0-Role-prompting.py
```

#### 2. 1-zero-shot.py
**Concept**: Zero-shot prompting
- Direct question without examples
- LLM relies entirely on pre-training knowledge
- Simplest prompting approach
- Use when task is straightforward or widely understood

**Usage**:
```bash
python 1-zero-shot.py
```

#### 3. 2-one-few-shot.py
**Concept**: One-shot and Few-shot learning
- Provides 1-3 examples before the actual task
- Demonstrates desired input-output format
- Significantly improves accuracy for specific tasks
- Use when you need consistent formatting or domain-specific responses

**Usage**:
```bash
python 2-one-few-shot.py
```

#### 4. 3-CoT.py
**Concept**: Chain of Thought (CoT)
- Prompts LLM to show step-by-step reasoning
- Uses "Let's think step by step" or similar phrases
- Dramatically improves performance on complex reasoning tasks
- Essential for mathematical, logical, or multi-step problems

**Usage**:
```bash
python 3-CoT.py
```

#### 5. 3.1-CoT-Self-consistency.py
**Concept**: Chain of Thought with Self-Consistency
- Generates multiple CoT reasoning paths
- Aggregates results to find most consistent answer
- Reduces variance and improves reliability
- Best for critical decisions requiring high confidence

**Usage**:
```bash
python 3.1-CoT-Self-consistency.py
```

#### 6. 4-ToT.py
**Concept**: Tree of Thoughts (ToT)
- Explores multiple reasoning branches simultaneously
- Evaluates and prunes less promising paths
- Maintains tree structure of thought process
- Use for complex problems requiring exploration of alternatives

**Usage**:
```bash
python 4-ToT.py
```

#### 7. 5-SoT.py
**Concept**: Skeleton of Thought (SoT)
- First generates high-level outline/skeleton
- Then fills in details for each section
- Improves structure and coherence of long-form content
- Ideal for essays, reports, or structured documentation

**Usage**:
```bash
python 5-SoT.py
```

#### 8. 6-ReAct.py
**Concept**: ReAct (Reasoning + Acting)
- Interleaves reasoning steps with actions
- Combines thought process with tool use or information retrieval
- Format: Thought → Action → Observation → Repeat
- Essential for agents that interact with external systems

**Usage**:
```bash
python 6-ReAct.py
```

#### 9. 7-Prompt-channing.py
**Concept**: Prompt Chaining
- Breaks complex task into sequence of simpler prompts
- Output of one prompt becomes input for next
- Improves accuracy by decomposing complexity
- Generates intermediate artifacts (see note below)

**Usage**:
```bash
python 7-Prompt-channing.py
```

**Output File**: Creates `prompt_chaining_result.md` with chained results

#### 10. 8-Least-to-most.py
**Concept**: Least-to-Most Prompting
- Decomposes problem from simple to complex
- Solves easiest sub-problems first
- Uses solutions as building blocks for harder problems
- Similar to dynamic programming approach

**Usage**:
```bash
python 8-Least-to-most.py
```

### Shared Utilities

**utils.py**:
- `print_response(response)` - Formats LLM responses using Rich library
- Provides consistent terminal output styling across all scripts
- Used by all example scripts for formatted display

## Running Examples

```bash
# Activate virtual environment first
source venv/bin/activate

# Run any example
python 0-Role-prompting.py
python 1-zero-shot.py
python 2-one-few-shot.py
python 3-CoT.py
python 3.1-CoT-Self-consistency.py
python 4-ToT.py
python 5-SoT.py
python 6-ReAct.py
python 7-Prompt-channing.py
python 8-Least-to-most.py

# Deactivate when done
deactivate
```

## Key Concepts

### Prompting Technique Selection Guide

| Technique | Use Case | Complexity | Best For |
|-----------|----------|------------|----------|
| **Role Prompting** | Any task | Low | Setting context and tone |
| **Zero-shot** | Simple, well-defined tasks | Low | Quick queries, general knowledge |
| **Few-shot** | Format-specific tasks | Low-Med | Classification, structured output |
| **Chain of Thought** | Multi-step reasoning | Medium | Math, logic, analysis |
| **CoT Self-Consistency** | High-stakes reasoning | Medium-High | Critical decisions |
| **Tree of Thoughts** | Complex exploration | High | Strategy, planning |
| **Skeleton of Thought** | Long-form content | Medium | Essays, documentation |
| **ReAct** | Tool-using agents | High | API calls, searches, actions |
| **Prompt Chaining** | Complex workflows | Medium | Multi-stage processing |
| **Least-to-Most** | Decomposable problems | Medium-High | Algorithmic tasks |

### Progressive Learning Path

**Recommended Order for Learning:**
1. Start with `0-Role-prompting.py` - Understand role assignment
2. Master `1-zero-shot.py` - Learn basic prompting
3. Add context with `2-one-few-shot.py` - Understand examples
4. Learn reasoning with `3-CoT.py` - Enable step-by-step thinking
5. Improve reliability with `3.1-CoT-Self-consistency.py` - Multiple attempts
6. Explore alternatives with `4-ToT.py` - Branching reasoning
7. Structure output with `5-SoT.py` - Outline-first approach
8. Combine reasoning and actions with `6-ReAct.py` - Agent behavior
9. Chain operations with `7-Prompt-channing.py` - Sequential processing
10. Decompose complexity with `8-Least-to-most.py` - Bottom-up solving

### Common Patterns

**All scripts follow this pattern:**
```python
from dotenv import load_dotenv
from langchain_openai import ChatOpenAI
from utils import print_response

# Load environment
load_dotenv()

# Initialize LLM
llm = ChatOpenAI(model="gpt-4o-mini", temperature=0)

# Create and execute prompt
response = llm.invoke(prompt)

# Display formatted output
print_response(response.content)
```

### Output Formatting

All examples use the `utils.print_response()` function for consistent terminal output:
- Rich library provides colored, formatted display
- Markdown rendering for structured content
- Code block syntax highlighting
- Clean separation between examples

## Important Notes

- **Always activate venv** before running scripts: `source venv/bin/activate`
- **API Key Required**: All scripts require valid `OPENAI_API_KEY` in `.env`
- **Model Selection**: Scripts use `gpt-4o-mini` by default (configurable in code)
- **Temperature**: Set to `0` for deterministic outputs (reproducibility)
- **Output File**: Only `7-Prompt-channing.py` creates a file (`prompt_chaining_result.md`)
- **Dependencies**: Uses LangChain 0.3.27 stable version (not alpha)

## Troubleshooting

**"No module named 'dotenv'"**:
```bash
pip install python-dotenv
```

**"No API key provided"**:
- Ensure `.env` file exists in current directory
- Check `OPENAI_API_KEY` is set correctly
- Verify no trailing spaces in `.env` file

**"Module 'langchain' has no attribute 'X'"**:
- Ensure using correct LangChain version (0.3.27)
- Check import statements match current API

## Best Practices

1. **Start Simple**: Begin with zero-shot, add complexity only when needed
2. **Use Few-shot for Format**: When you need specific output structure
3. **Enable CoT for Reasoning**: Complex logic always benefits from step-by-step thinking
4. **Chain for Complexity**: Break down multi-stage tasks into sequential prompts
5. **Test Temperature**: Use 0 for consistency, higher values for creativity

## Additional Resources

- LangChain Documentation: https://python.langchain.com/
- OpenAI API Reference: https://platform.openai.com/docs/
- Prompt Engineering Guide: https://www.promptingguide.ai/

## Version Compatibility

- **Python**: 3.9+ (f-strings, type hints)
- **LangChain**: 0.3.27 stable
- **OpenAI API**: Latest (tested with v1.102.0)
- **Rich**: 14.1.0 (terminal formatting)
