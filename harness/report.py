#!/usr/bin/env python3
"""Median turns, tokens, cost and model time per arm and task from bench/out.

Usage: harness/report.py [harness/out]
"""
import json, re, statistics, sys
from pathlib import Path

out = Path(sys.argv[1] if len(sys.argv) > 1 else Path(__file__).parent / "out")


def correct(task, result):
    if task == "t1":
        return result.count("points") >= 3
    if task == "t2":
        return "2012" in result
    if task == "t4":
        return "You logged into a secure area!" in result
    if task == "t5":
        return re.search(r"\b2 items? left", result) is not None
    if task == "t6":
        return "Pablo Neruda" in result
    if task == "t7":
        return "Hello World!" in result
    match = re.search(r"\{.*\}", result, re.S)
    try:
        form = json.loads(match.group(0))
    except (AttributeError, ValueError):
        return False
    return (form.get("size"), sorted(form.get("topping", [])), form.get("delivery"), form.get("custname")) == (
        "medium", ["bacon", "onion"], "19:30", "Ana Silva")


groups = {}
for path in sorted(out.glob("*-t[0-9]-*.json")):
    if path.stat().st_size == 0:
        continue
    arm, task, n = path.stem.rsplit("-", 2)
    if n == "0":  # smoke test of the harness, not a measured run
        continue
    run = json.loads(path.read_text())
    usage = run["usage"]
    groups.setdefault((task, arm), []).append({
        "ok": correct(task, run.get("result", "")),
        "turns": run["num_turns"],
        "input": usage["input_tokens"] + usage["cache_creation_input_tokens"] + usage["cache_read_input_tokens"],
        "output": usage["output_tokens"],
        "cost": run["total_cost_usd"],
        "model_s": run["duration_api_ms"] / 1000,
    })

print("| Task | Arm | Correct | Turns | Input tokens | Output tokens | Cost USD | Model s |")
print("| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |")
for (task, arm), runs in sorted(groups.items()):
    med = lambda k: statistics.median(r[k] for r in runs)
    ok = sum(r["ok"] for r in runs)
    print(f"| {task} | {arm} | {ok}/{len(runs)} | {med('turns'):g} | {med('input'):,.0f} | {med('output'):,.0f} | {med('cost'):.3f} | {med('model_s'):.1f} |")
