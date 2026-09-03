"""Report what a window of Claude Code sessions on this project cost."""

import argparse
import json
import statistics
import time
from collections import Counter
from pathlib import Path


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--days", type=int, default=7)
    args = parser.parse_args()

    project_dir = Path.home() / ".claude" / "projects" / "C--Users-dl13860-Documents-Meadow-meadow"
    if not project_dir.exists():
        print(f"session directory not found: {project_dir}")
        return 0

    cutoff = time.time() - args.days * 86400
    files = [f for f in project_dir.glob("*.jsonl") if f.stat().st_mtime >= cutoff]

    session_count = 0
    assistant_requests = 0
    context_sizes = []
    output_tokens_sum = 0
    session_opening_contexts = []
    tool_counts = Counter()

    for f in files:
        rows = []
        try:
            with f.open("r", encoding="utf-8") as fh:
                for line in fh:
                    try:
                        rows.append(json.loads(line))
                    except Exception:
                        continue
        except Exception:
            continue

        if len(rows) < 4:
            continue

        session_count += 1
        first_context = None

        for row in rows:
            if row.get("type") != "assistant":
                continue
            message = row.get("message", {})
            usage = message.get("usage")
            if not usage:
                continue

            assistant_requests += 1
            context_size = (
                usage.get("input_tokens", 0)
                + usage.get("cache_read_input_tokens", 0)
                + usage.get("cache_creation_input_tokens", 0)
            )
            context_sizes.append(context_size)
            output_tokens_sum += usage.get("output_tokens", 0)
            if first_context is None:
                first_context = context_size

            for block in message.get("content", []) or []:
                if isinstance(block, dict) and block.get("type") == "tool_use":
                    tool_counts[block.get("name", "?")] += 1

        if first_context is not None:
            session_opening_contexts.append(first_context)

    def median(values):
        return statistics.median(values) if values else 0

    def p90(values):
        if not values:
            return 0
        s = sorted(values)
        return s[int(len(s) * 0.9)]

    top_tools = ", ".join(f"{name}={count}" for name, count in tool_counts.most_common(6))

    print(f"sessions                     {session_count}")
    print(f"assistant requests           {assistant_requests}")
    print(f"context volume (tokens)      {sum(context_sizes)}")
    print(f"output tokens                {output_tokens_sum}")
    print(f"context/request median       {median(context_sizes)}")
    print(f"context/request p90          {p90(context_sizes)}")
    print(f"session-opening context      {median(session_opening_contexts)}")
    print(f"tool calls                   {sum(tool_counts.values())}")
    print(f"top tools                    {top_tools}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
