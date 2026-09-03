# Requires: pip install langchain-community numpy
"""
Embedding distance evaluation: Semantic similarity measurement.

Demonstrates deterministic evaluator using vector embeddings.
"""
from langsmith import evaluate
from langsmith.evaluation import LangChainStringEvaluator
from pathlib import Path

from shared.clients import get_openai_client
from shared.prompts import load_yaml_prompt, execute_text_prompt
from shared.evaluators import prepare_with_reference

# Configuration
DATASET_NAME = "evaluation_basic_dataset"
BASE_DIR = Path(__file__).parent

# Setup
oai_client = get_openai_client()
# This prompt is more detailed and specific, generating outputs more similar to expected
prompt = load_yaml_prompt("embedding_distance_eval.yaml")


def run_embedding_evaluation(inputs: dict) -> dict:
    """Target function for evaluate()."""
    return execute_text_prompt(prompt, inputs, oai_client, input_key="code")


# Embedding Distance: Deterministic evaluator (doesn't use LLM)
# - Converts prediction and reference to embeddings (vectors)
# - Calculates cosine distance between vectors
# - Returns score: the LOWER, the more semantically similar
# - Uses OpenAI embeddings by default
# - Faster and cheaper than LLM-based evaluators
evaluators = [
    LangChainStringEvaluator(
        "embedding_distance",
        prepare_data=prepare_with_reference
    )
]

# Run evaluation
results = evaluate(
    run_embedding_evaluation,
    data=DATASET_NAME,
    evaluators=evaluators,
    experiment_prefix="EmbeddingDistanceEval",
    max_concurrency=2
)

print("="*80)
print(f"EXPERIMENT: {results.experiment_name}")
print("="*80)
