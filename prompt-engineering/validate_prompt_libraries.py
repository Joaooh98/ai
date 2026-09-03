#!/usr/bin/env python3
"""Validate both production prompt libraries without calling a model."""

import re
import sys
from pathlib import Path

import yaml

ROOTS = [Path(__file__).parent / "prompt-library", Path(__file__).parent / "prompt-library-en"]
PLACEHOLDER = re.compile(r"\{\{([a-z][a-z0-9_]*)\}\}")
SEMVER = re.compile(r"^[0-9]+\.[0-9]+\.[0-9]+$")


def load(path):
    value = yaml.safe_load(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise ValueError(f"{path}: root must be a mapping")
    return value


def validate(root):
    errors, prompts = [], {}
    for path in sorted((root / "prompts").glob("*.prompt.yaml")):
        data = load(path)
        fields = {"id", "version", "description", "input_variables", "metadata", "template"}
        if fields - data.keys():
            errors.append(f"{path}: missing fields {sorted(fields-data.keys())}")
            continue
        prompt_id = data["id"]
        if prompt_id in prompts:
            errors.append(f"{path}: duplicate prompt id {prompt_id}")
        prompts[prompt_id] = data
        if not SEMVER.fullmatch(str(data["version"])):
            errors.append(f"{path}: invalid version")
        variables = data["input_variables"]
        required, optional = set(variables["required"]), set(variables["optional"])
        used = set(PLACEHOLDER.findall(data["template"]))
        if required | optional != used:
            errors.append(f"{path}: declared variables differ from placeholders")
        if required & optional:
            errors.append(f"{path}: required and optional variables overlap")

    registry = load(root / "registry.yaml")
    registered = set()
    for entry in registry["entries"]:
        prompt_id = entry["prompt"]
        registered.add(prompt_id)
        if prompt_id not in prompts or not (root / entry["path"]).is_file():
            errors.append(f"{root}: invalid registry entry {prompt_id}")
        if entry.get("dataset") and not (root / entry["dataset"]).is_file():
            errors.append(f"{root}: missing dataset for {prompt_id}")
    if registered != set(prompts):
        errors.append(f"{root}: registry and prompt files differ")

    case_ids = set()
    for path in sorted((root / "datasets").glob("*.dataset.yaml")):
        for case in load(path)["cases"]:
            case_id, prompt_id = case["id"], case["prompt_id"]
            if case_id in case_ids:
                errors.append(f"{path}: duplicate case {case_id}")
            case_ids.add(case_id)
            if prompt_id not in prompts:
                errors.append(f"{path}: unknown prompt {prompt_id}")
                continue
            variables = prompts[prompt_id]["input_variables"]
            required = set(variables["required"])
            allowed = required | set(variables["optional"])
            supplied = set(case["input"])
            if required - supplied:
                errors.append(f"{path}: {case_id} misses {sorted(required-supplied)}")
            if supplied - allowed:
                errors.append(f"{path}: {case_id} has unknown inputs")
            if not case.get("expected"):
                errors.append(f"{path}: {case_id} has no expectations")

    for path in sorted((root / "evaluators").glob("*.criteria.yaml")):
        weights = [item.get("weight") for item in load(path)["criteria"]]
        if any(not isinstance(w, (int, float)) for w in weights) or abs(sum(weights)-1) > 1e-9:
            errors.append(f"{path}: weights must be numeric and sum to 1")
    return errors


failures = [error for root in ROOTS for error in validate(root)]
if failures:
    print("\n".join(f"ERROR: {error}" for error in failures))
    sys.exit(1)
print("Both prompt libraries are valid.")

