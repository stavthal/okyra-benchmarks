# okyra vs Vercel agent-browser: agent benchmark

Raw results, method and harness for the comparison between
okyra (STH Labs) and
[Vercel agent-browser](https://github.com/vercel-labs/agent-browser) as browser
tools for an AI agent. Every number here is computed from the JSON files in
`results/`, one file per run, exactly as Claude Code wrote them.

okyra was called kyma until 2026-10-13, so the result files use the arm names
`kyma` and `kyma2`. In `results/2026-10-13-v2/`, okyra is `kyma2` (the build
after the V2 fixes; `kyma` there is the build before them). In
`results/2026-10-13-round3/`, okyra is `kyma`. `abcli` is the agent-browser
CLI with its own skill, `abmcp` is the agent-browser MCP server.

## Headline

Across six browser tasks, 5 runs each, on Claude Opus 5.5 in Claude Code:

| Measure, average of the six task medians | okyra | agent-browser CLI | Difference |
| --- | ---: | ---: | ---: |
| Model turns per task | 3.3 | 6.0 | 44% fewer |
| Model cost per task (USD) | $0.059 | $0.114 | $0.054 less, 48% less |
| Model time per task | 9.3 s | 18.1 s | 8.8 s less, 49% less |
| Input tokens per task | 133,786 | 253,696 | 47% fewer |
| Output tokens per task | 508 | 919 | 45% fewer |
| Correct answers | 29 of 30 | 30 of 30 | the okyra miss was the test site being down, see Limits |

Cost saving per task on every task: $0.022 to $0.080, 26% to 58%.

## Method

| Item | Value |
| --- | --- |
| Dates | 2026-10-13 (both rounds) |
| Harness | Headless Claude Code, `claude -p --output-format json`, script `harness/run.sh`, summary `harness/report.py` |
| Model | `claude-opus-5-5`, standard speed, fast mode off (from `modelUsage` in each run) |
| Cost basis | `total_cost_usd` as Claude Code reports it, list price (`costBasis: "list"` in each run) |
| okyra build | the build after the V2 fixes (`kyma2` in v2, `kyma` in round 3), through its MCP server |
| agent-browser | 0.39.0, through its CLI in Bash with its own `core` skill (`abcli`), which is how Vercel recommends agents use it and was its best arm. Its MCP server (`abmcp`) ran in v2 only and was worse, see below |
| Browser | the same Brave install for both, both tools warm (daemon and browser up before each run) |
| Runs | 5 per tool per task. Medians reported, ranges kept below |
| Correctness | each answer checked by `correct()` in `harness/report.py` |
| Tasks | T2 Wikipedia search and read the infobox; T3 fill and submit the httpbin order form; T4 log in at the-internet.herokuapp.com; T5 TodoMVC React app, add three todos, complete one, read the counter; T6 quotes.toscrape.com, page to page 3, read the first author; T7 the-internet dynamic loading, read late content |
| Tuning | okyra was tuned after seeing T2 and T3. T4 to T7 were new to both tools |

Input tokens = `input_tokens + cache_creation_input_tokens + cache_read_input_tokens`. Model time = `duration_api_ms`.

## Per task, per tool (medians of 5)

| Task | Tool | Correct | Turns | Input tokens | Output tokens | Cost USD | Model s |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| T2 search | okyra | 5/5 | 4 | 157,871 | 543 | 0.050 | 10.4 |
| T2 search | agent-browser CLI | 5/5 | 7 | 286,612 | 1,156 | 0.118 | 22.2 |
| T2 search | agent-browser MCP | 5/5 | 9 | 238,589 | 851 | 0.171 | 15.3 |
| T3 form | okyra | 5/5 | 4 | 159,823 | 890 | 0.078 | 13.0 |
| T3 form | agent-browser CLI | 5/5 | 8 | 341,012 | 1,639 | 0.158 | 27.5 |
| T3 form | agent-browser MCP | 5/5 | 19 | 429,098 | 2,126 | 0.315 | 33.6 |
| T4 login | okyra | 4/5 | 3 | 120,897 | 310 | 0.060 | 9.2 |
| T4 login | agent-browser CLI | 5/5 | 4 | 170,980 | 475 | 0.082 | 13.1 |
| T5 single page app | okyra | 5/5 | 3 | 121,328 | 531 | 0.051 | 9.2 |
| T5 single page app | agent-browser CLI | 5/5 | 6 | 257,069 | 743 | 0.117 | 15.8 |
| T6 pagination | okyra | 5/5 | 3 | 121,359 | 320 | 0.069 | 6.7 |
| T6 pagination | agent-browser CLI | 5/5 | 6 | 251,389 | 808 | 0.100 | 14.9 |
| T7 late content | okyra | 5/5 | 3 | 121,439 | 452 | 0.046 | 7.0 |
| T7 late content | agent-browser CLI | 5/5 | 5 | 215,111 | 694 | 0.106 | 14.9 |

## okyra saving per task, against the agent-browser CLI

| Task | Turns saved | Saving USD | Saving % | Model time saved |
| --- | ---: | ---: | ---: | ---: |
| T2 search | 3 (43%) | $0.068 | 58% | 11.8 s |
| T3 form | 4 (50%) | $0.080 | 51% | 14.5 s |
| T4 login | 1 (25%) | $0.022 | 26% | 3.9 s |
| T5 single page app | 3 (50%) | $0.066 | 56% | 6.7 s |
| T6 pagination | 3 (50%) | $0.031 | 31% | 8.2 s |
| T7 late content | 2 (40%) | $0.060 | 57% | 7.9 s |
| **Average** | **2.7 (44%)** | **$0.054** | **48%** | **8.8 s** |
| **Lowest (conservative)** | 1 | **$0.022** | 26% | 3.9 s |

Against the agent-browser MCP arm (T2 and T3 only) the saving is larger, $0.121 and $0.237 per task, because that arm has no batch tool. We compare against the CLI arm because it is the stronger and fairer opponent.

### Ranges, so nobody reads a median as a promise

Cost per run, all five runs, in order:

| Task | okyra | agent-browser CLI |
| --- | --- | --- |
| T2 | 0.245, 0.070, 0.047, 0.050, 0.044 | 0.339, 0.099, 0.150, 0.100, 0.118 |
| T3 | 0.271, 0.091, 0.062, 0.064, 0.078 | 0.156, 0.163, 0.193, 0.154, 0.158 |
| T4 | 0.263, 0.227, 0.060, 0.044, 0.039 | 0.292, 0.267, 0.078, 0.082, 0.082 |
| T5 | 0.257, 0.234, 0.045, 0.040, 0.051 | 0.320, 0.300, 0.108, 0.117, 0.085 |
| T6 | 0.255, 0.230, 0.031, 0.069, 0.041 | 0.304, 0.298, 0.100, 0.082, 0.099 |
| T7 | 0.253, 0.233, 0.046, 0.043, 0.043 | 0.307, 0.294, 0.080, 0.106, 0.047 |

The first one or two runs of most cells cost $0.23 to $0.34 for both tools. Those runs wrote 25,000 to 40,000 tokens into the prompt cache (`cache_creation_input_tokens`); later runs read it. A cold cache costs about the same extra for either tool, so it shrinks the percentage but not the dollar saving:

| Way of averaging | okyra | agent-browser CLI | Saving |
| --- | ---: | ---: | ---: |
| Average of the six task medians (mostly warm cache) | $0.059 | $0.114 | $0.054, 48% |
| Mean of all 30 runs (cold and warm) | $0.118 | $0.169 | $0.052, 31% |

So the dollar saving per task is steady at about $0.05, while the percentage is 31% to 48% depending on how often the cache is cold. Agent fleets that run many tasks back to back sit near the warm end [assumed].

## Calculator

```
monthly saving (USD) = tasks per month x (agent-browser cost per task minus okyra cost per task)
agent hours saved    = tasks per month x model seconds saved per task / 3600
```

Inputs:

| Input | Typical (default) | Conservative |
| --- | ---: | ---: |
| agent-browser cost per task | $0.114 | $0.082 (T4) |
| okyra cost per task | $0.059 | $0.060 (T4) |
| Saving per task | $0.054 | $0.022 |
| Model seconds saved per task | 8.8 s | 3.9 s |

Worked rows (saving per task $0.0545 typical, $0.0216 conservative; 8.82 s typical model time saved):

| Tasks per month | Saving per month, typical | Saving per month, conservative | Saving per year, typical | Agent hours saved per month (model time) |
| ---: | ---: | ---: | ---: | ---: |
| 1,000 | $55 | $22 | $654 | 2.5 |
| 10,000 | $545 | $216 | $6,542 | 24.5 |
| 100,000 | $5,451 | $2,165 | $65,418 | 245 |
| 1,000,000 | $54,515 | $21,648 | $654,180 | 2,451 |

"Agent hours" here means time the model spent generating, summed over tasks. It is not wall clock time and not human time.

### Optional: other harnesses and models

Most of the saving comes from fewer turns. In Claude Code every turn re-reads about 40,000 tokens of context (system prompt, tools, history): okyra's 3 turn tasks used about 121,000 input tokens, agent-browser's 6 turn tasks about 255,000. A harness with a much smaller context per turn, or a cheaper model, saves fewer dollars per turn. A rough estimate for another setup, not measured:

```
saving per task ≈ 2.7 turns saved x context tokens per turn x input price per token
```

Only the Claude Code and Opus 5.5 numbers above are measured.

## Limits

- **Small sample.** n=5 per tool per task, six tasks, one day. The spread between runs is wide (see Ranges).
- **One model, one harness.** Opus 5.5 in Claude Code only. Not measured on Sonnet, Haiku, GPT or Gemini models, nor in custom agent loops, LangChain, the Agent SDK or browser-use.
- **Versions and dates.** agent-browser 0.39.0, okyra as built on 2026-10-13. A later agent-browser release can change the result. agent-browser already has a batch command, so its gap depends on how agents use it.
- **Tuning.** okyra was tuned after seeing T2 and T3. T4 to T7 were untuned for both tools and still show 25% to 57% savings.
- **The okyra miss.** One T4 run failed because Heroku served "Application Error"; okyra returned the error page and the agent reported the outage. It is counted as incorrect above.
- **Cold cache.** First runs carry a prompt cache write that costs the same for both tools. See Ranges.
- **Wall clock time is not claimed.** Median end to end time was 19 s for okyra and 68 s for agent-browser, but that includes harness start and Bash tool overhead that was not isolated. We will publish it once it is measured on its own.
- **Author's prompt hook.** The author's Claude Code setup adds a reply format rule to every prompt. It ran in every run of both tools, so a few answers start with an "Answer" label. It affects both tools equally.
- **Not compared.** Playwright MCP, Chrome DevTools MCP, browser-use and Stagehand were not benchmarked. No saving against them may be claimed.
- **Reproducible.** `harness/run.sh <arm> <task> <n>` then `harness/report.py harness/out`. Anyone can rerun it with their own Claude Code account.


## Rerun it

```sh
harness/run.sh abcli t5 1      # one run: arm, task, run number
harness/run.sh okyra t5 1
harness/report.py harness/out  # medians and correctness per arm and task
```

Needs Claude Code (`claude`), `jq`, a Chromium based browser, agent-browser
(`npm i agent-browser`, or set `$AGENT_BROWSER`) and okyra (on PATH, or set
`$OKYRA`). `report.py` skips run 0, which is meant as a harness smoke test.

## Files

| Path | What |
| --- | --- |
| `results/2026-10-13-v2/` | T2 and T3: okyra before and after fixes, agent-browser CLI and MCP |
| `results/2026-10-13-round3/` | T4 to T7: tasks new to both tools |
| `harness/run.sh` | one headless Claude Code run of one task through one tool; the task prompts are in it |
| `harness/report.py` | medians, token counts and the correctness checks |

## Licence

Scripts: MIT. Results and text: [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).
Copyright 2026 Stavros Thalassinos, trading as STH Labs. "Vercel" and
"agent-browser" belong to their owners; this repo is not affiliated with Vercel.
