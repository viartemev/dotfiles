---
name: "victoria-logs-search"
description: "Search k8s logs via victoria-logs MCP: wrap OR filters in parens to keep namespace isolation, fast-path level/id filters, post-process truncated output. Use for any project's log debugging through victoria_logs_query."
version: 2
created: "2026-07-29"
updated: "2026-08-07"
---
## When to Use
Use when searching k8s pod logs through victoria-logs MCP (victoria_logs_query, victoria_logs_streams, victoria_logs_field_names, victoria_logs_hits). Any namespace. Triggers: "search logs", "find in logs", "victoria logs", "loki", "pod logs", "debug in prod/dev/uat", "find errors", "trace meeting/recording/order/trace id", "logsql".

## Procedure
1. FAST PATH — skip discovery if you already know namespace+cluster. Go straight to victoria_logs_query. Most log searches need ONE query, not three.
2. Pass namespace (required, exact) and cluster (optional: dev/prod/uat, empty = all) as SEPARATE MCP params. NEVER put namespace/cluster/_stream selectors inside logsql_filter — policy guardrail builds `{namespace="X"} <filter>` from separate params and rejects inline selectors.
3. Time window: pass start/end as RFC3339. Compute with `date -u -v-5M +%Y-%m-%dT%H:%M:%SZ` (macOS/BSD) or `date -u -d '5 min ago' +%Y-%m-%dT%H:%M:%SZ` (GNU). Default window is short — for any historical investigation always set explicit start/end.
4. logsql_filter uses LogsQL: bare word = substring in _msg; field:word = filter field; "phrase" = exact phrase; i(word) = case-insensitive; `*` = all. Pipes: `| stats by level`, `| field_values field`, `| count by field`.
5. CRITICAL — OR-PAREN RULE: ANY logsql_filter containing OR MUST be wrapped in parentheses. MCP builds `{namespace="X"} <filter>` without adding parens. LogsQL parses OR weaker than implicit-AND, so `level:error OR level:warn` becomes `({ns="X"} level:error) OR level:warn` — OR branches lose the stream selector and match ALL namespaces AND clusters. FIX (verified 2026-08-07): wrap the whole filter → `(level:error OR level:warn)`. Then `{ns} (level:error OR level:warn)` parses correctly, namespace isolation holds. This applies to ALL multi-term OR: levels, fields, ids.
6. Known-good patterns (namespace isolated): single level → `level:error` / `level:warn` / `level:info`; multiple levels → `(level:error OR level:warn)` (PARENS REQUIRED); by id → `recording_id:VLU...` / `meeting_id:ABC...` / `trace_id:hex`; substring in _msg → bare word; exact phrase → "quoted phrase"; everything → `*`.
7. If you forget parens and see foreign namespaces in results — that IS the OR-leak. Re-run with parens. Do NOT fall back to `*`+manual grep; that wastes a round-trip on a bigger payload. Do NOT run separate per-level queries; one parenthesized query is cheaper.
8. Discovery flow ONLY when namespace unknown or fields unclear: (a) victoria_logs_streams → list pods/containers + hit counts, confirms namespace exists; (b) victoria_logs_field_names → available fields (level, meeting_id, recording_id, trace_id, etc.); (c) victoria_logs_query → fetch lines. Skip (a)/(b) if you already know what to query.
9. Output truncates at ~200 lines / ~150-190 KiB, full text saved to temp file (path in truncation notice: /var/folders/.../output-<hash>.txt). Post-filter that file, never read all rows from tool response. Count levels: `grep -o '"level":"[a-z]*"' FILE | sort | uniq -c`. Extract _msg: `python3 -c 'import sys,json;[print(json.loads(l)["_msg"]) for l in sys.stdin]' < FILE`. Verify namespace isolation: `grep -c '"namespace":"<ns>"' FILE` must equal row count.
10. Verify: zero rows → widen filter/time range, check namespace/cluster spelling, confirm namespace deploys to that cluster. victoria_logs_hits gives counts without row payload. victoria_logs_streams empty values[] → wrong namespace.

## Pitfalls
- OR-without-parens is the #1 time sink. `level:error OR level:warn` leaks ALL namespaces. ALWAYS wrap: `(level:error OR level:warn)`. Verified fix 2026-08-07: parenthesized filter keeps namespace+cluster isolation, returns only requested namespace.
- MCP requires exact namespace — regex/wildcard/negative rejected. Guess-and-check via victoria_logs_streams (empty values[] = wrong namespace).
- Do NOT include _stream{...}, namespace:, cluster: selectors in logsql_filter — policy layer rejects inline selectors. namespace/cluster go as separate MCP params.
- cluster empty string = ALL clusters. Wrong cluster = empty results even with right namespace. Some namespaces only deploy to specific clusters (e.g. dev only, not prod/uat).
- LogsQL word filter matches tokenized words, not raw substring. Use quoted "phrase" for exact multi-word match.
- Default time window is short (hours). Historical investigation → always pass explicit start/end RFC3339.
- victoria_logs_query returns bounded rows (~200 lines). For counts use victoria_logs_hits; for field exploration victoria_logs_field_names / victoria_logs_streams. Don't burn a query call just to count.
- Truncated output temp file (/var/folders/.../output-<hash>.txt) — always grep/python3 that file. Reading full tool response = wasted context.

## Verification
1. After any OR query: grep output file for `"namespace":"<expected-ns>"` count == total rows. If fewer → OR-leak (missing parens); re-run with `(...)` wrapper.
2. victoria_logs_streams with namespace returns non-empty values[] → namespace exists in that cluster.
3. victoria_logs_query with single-term `level:error` or parenthesized `(level:error OR level:warn)` returns ONLY rows where `_stream` contains `namespace="<expected-ns>"` and `cluster="<expected-cluster>"`.
4. victoria_logs_hits count > 0 for `*` confirms cluster+namespace combo valid.