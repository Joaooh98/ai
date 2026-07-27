"""LLM and observability platform clients."""
import os
from langsmith.wrappers import wrap_openai
from langsmith import Client as LangSmithClient
from openai import OpenAI
from langfuse import Langfuse
from dotenv import load_dotenv

# Load environment variables
load_dotenv()


def get_openai_client():
    """
    Returns OpenAI client with LangSmith tracing.

    Model and temperature are configurable via environment variables:
    - LLM_MODEL (default: gpt-4o-mini)
    - LLM_TEMPERATURE (default: 0)

    Returns:
        OpenAI client wrapped with LangSmith tracing
    """
    return wrap_openai(OpenAI())


def get_model_name() -> str:
    """
    Get configured model name from environment.

    Returns:
        Model name (default: gpt-4o-mini)
    """
    return os.getenv("LLM_MODEL", "gpt-4o-mini")


def get_temperature() -> float:
    """
    Get configured temperature from environment.

    Returns:
        Temperature value (default: 0)
    """
    return float(os.getenv("LLM_TEMPERATURE", "0"))


def get_langsmith_client():
    """
    Returns LangSmith client.

    Returns:
        LangSmith Client instance
    """
    return LangSmithClient()


def get_langfuse_client():
    """
    Returns Langfuse client.

    Returns:
        Langfuse client instance
    """
    return Langfuse()


def get_openai_client_langfuse():
    """
    Returns OpenAI client with Langfuse tracing.

    Model and temperature are configurable via environment variables:
    - LLM_MODEL (default: gpt-4o-mini)
    - LLM_TEMPERATURE (default: 0)

    Returns:
        OpenAI client wrapped with Langfuse tracing
    """
    from langfuse.openai import OpenAI as LangfuseOpenAI
    return LangfuseOpenAI()
