#!/bin/zsh
# One headless Claude Code run of a browser task through one tool.
# Usage: harness/run.sh <arm> <task> <run number>
#   arm:  okyra (MCP), abmcp (agent-browser MCP), abcli (agent-browser CLI)
#   task: t1 read Hacker News, t2 Wikipedia search, t3 httpbin order form,
#         t4 login, t5 TodoMVC single page app, t6 pagination, t7 late content
# Needs: okyra on PATH or in $OKYRA; agent-browser on PATH or in $AGENT_BROWSER.
set -u
bench=${0:a:h}
arm=$1 task=$2 n=$3
out=$bench/out; mkdir -p $out
okyra=${OKYRA:-$(command -v okyra)}
ab=${AGENT_BROWSER:-$(command -v agent-browser)}
socket=${TMPDIR:-/tmp}/okyra-bench.sock

case $task in
  t1) goal='Open https://news.ycombinator.com and list the top 3 stories with their points. Reply with only the list.' ;;
  t2) goal='Go to https://en.wikipedia.org, type "Rust programming language" into the site search box and submit it, open the article, and tell me the year Rust first appeared according to its infobox. Reply with only the year.' ;;
  t3) goal='Fill in the order form at https://httpbin.org/forms/post: customer name Ana Silva, telephone 555 0101, email ana@example.com, pizza size Medium, toppings Bacon and Onion, preferred delivery time 19:30, comments "Ring twice". Submit it and reply with only the "form" JSON object the server returns.' ;;
  t4) goal='Log in at https://the-internet.herokuapp.com/login with username tomsmith and password SuperSecretPassword! and reply with only the message the site shows after logging in.' ;;
  t5) goal='Open https://todomvc.com/examples/react/dist/ and add three todos: "buy milk", "walk dog", "write report". Mark "walk dog" as completed, then reply with only the item counter text shown at the bottom of the list.' ;;
  t6) goal='Open https://quotes.toscrape.com, click the Next link until you reach page 3, and reply with only the author of the first quote on that page.' ;;
  t7) goal='Open https://the-internet.herokuapp.com/dynamic_loading/2, click Start, and reply with only the text that appears when loading finishes.' ;;
  *) echo "unknown task $task" >&2; exit 2 ;;
esac

# Both tools start warm: daemon and browser already up.
case $arm in
  okyra*)
    OKYRA_SOCKET=$socket $okyra goto about:blank >/dev/null
    print -r -- "{\"mcpServers\":{\"okyra\":{\"command\":\"$okyra\",\"args\":[\"mcp\"],\"env\":{\"OKYRA_SOCKET\":\"$socket\"}}}}" > $out/okyra-mcp.json
    prompt="Use the okyra browser tools. $goal"
    extra=(--mcp-config $out/okyra-mcp.json --allowedTools "mcp__okyra__*") ;;
  abmcp)
    $ab open about:blank >/dev/null
    print -r -- "{\"mcpServers\":{\"agent-browser\":{\"command\":\"$ab\",\"args\":[\"mcp\"]}}}" > $out/ab-mcp.json
    prompt="Use the agent-browser tools. $goal"
    extra=(--mcp-config $out/ab-mcp.json --allowedTools "mcp__agent-browser__*") ;;
  abcli)
    $ab open about:blank >/dev/null
    prompt="Use the agent-browser CLI through Bash. Run \`agent-browser skills get core\` first to learn it. $goal"
    extra=(--allowedTools "Bash(agent-browser:*)") ;;
  *) echo "unknown arm $arm" >&2; exit 2 ;;
esac

PATH=${ab:h}:$PATH command claude -p "$prompt" --output-format json --strict-mcp-config \
  --disallowedTools WebFetch WebSearch "${extra[@]}" < /dev/null > $out/$arm-$task-$n.json 2> $out/$arm-$task-$n.err
jq -c '{turns: .num_turns, cost: .total_cost_usd, result: .result[0:80]}' $out/$arm-$task-$n.json
