#!/usr/bin/env python3
"""
Heuristic observability classifier for Receipts.

Walks a repo, applies regex signals (positive + negative), and assigns each
file one of: fully | partial | minimal | none. Output is markdown by default,
JSON with --json.

Usage:
    scan-observability.py [--md|--json] [path ...]

Limits:
    Pattern-based, not AST-based. Treats results as a *starting point* for the
    agent to verify, not a verdict. Excludes node_modules, .git, dist, build,
    __pycache__, vendor, target, .next.
"""
from __future__ import annotations

import json
import os
import re
import sys
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Iterable

EXTENSIONS = {".ts", ".tsx", ".js", ".jsx", ".mjs", ".cjs",
              ".py", ".go", ".rb", ".java", ".kt", ".cs", ".rs", ".php"}
EXCLUDE_DIRS = {"node_modules", ".git", "dist", "build", "__pycache__",
                "vendor", "target", ".next", ".nuxt", ".turbo", "coverage"}

POSITIVE_PATTERNS: list[tuple[re.Pattern, str, int]] = [
    (re.compile(r"\b(?:from|import)\s+['\"]?(?:pino|winston|bunyan|structlog|loguru|zap|logrus|serilog|tracing|slog)\b"), "logger-imported", 2),
    (re.compile(r'"log/slog"'), "slog-imported", 2),
    (re.compile(r"\bcorrelation[_-]?id\b", re.IGNORECASE), "correlation-aware", 1),
    (re.compile(r"\b(?:request|trace|span)[_-]?id\b", re.IGNORECASE), "trace-aware", 1),
    (re.compile(r"\berror_code\b|\bE_[A-Z]+_[A-Z_]+\b"), "error-codes", 2),
    (re.compile(r"\bduration_ms\b"), "latency-tracked", 1),
    (re.compile(r"\bredact\b|\bsanitize\b", re.IGNORECASE), "redaction-aware", 1),
    (re.compile(r"\b(?:logger|log)\.(?:info|warn|error|debug)\b"), "structured-log-call", 1),
]

NEGATIVE_PATTERNS: list[tuple[re.Pattern, str, int]] = [
    (re.compile(r"catch\s*\([^)]*\)\s*\{\s*\}"), "empty-catch-js", 3),
    (re.compile(r"except\b[^:]*:\s*\n\s*pass\b"), "empty-except-py", 3),
    (re.compile(r"^\s*console\.log\b", re.MULTILINE), "console-log", 1),
    (re.compile(r"^\s*print\s*\(", re.MULTILINE), "print-debug", 1),
    (re.compile(r"throw\s+new\s+Error\(['\"]\w+['\"]?\)"), "raw-error-throw", 1),
    (re.compile(r"raise\s+Exception\(['\"]"), "raw-exception-raise", 1),
    (re.compile(r"//\s*TODO|//\s*FIXME|#\s*TODO|#\s*FIXME"), "todo-fixme", 1),
]

# files to skip entirely (config, type-only, vendor)
SKIP_FILE_PATTERNS = [
    re.compile(r"\.d\.ts$"),
    re.compile(r"\.config\.(js|ts|mjs|cjs)$"),
    re.compile(r"vite\.config\."),
    re.compile(r"webpack\.config\."),
    re.compile(r"jest\.config\."),
    re.compile(r"tailwind\.config\."),
]


@dataclass
class Result:
    path: str
    score: int
    classification: str
    signals: list[str] = field(default_factory=list)


def is_skipped(path: Path) -> bool:
    name = path.name
    return any(pat.search(name) for pat in SKIP_FILE_PATTERNS)


def classify(path: Path) -> Result | None:
    try:
        text = path.read_text(errors="ignore")
    except (OSError, UnicodeDecodeError):
        return None

    if not text.strip():
        return None

    signals: list[str] = []
    score = 0

    for pat, name, weight in POSITIVE_PATTERNS:
        if pat.search(text):
            signals.append(name)
            score += weight

    for pat, name, weight in NEGATIVE_PATTERNS:
        if pat.search(text):
            signals.append(name)
            score -= weight

    if not signals:
        return None

    if score >= 4:
        cls = "fully"
    elif score >= 1:
        cls = "partial"
    elif score >= -2:
        cls = "minimal"
    else:
        cls = "none"

    return Result(path=str(path), score=score, classification=cls, signals=signals)


def walk(root: Path) -> Iterable[Path]:
    for dp, dns, fns in os.walk(root):
        dns[:] = [d for d in dns if d not in EXCLUDE_DIRS and not d.startswith(".")]
        for fn in fns:
            p = Path(dp) / fn
            if p.suffix.lower() in EXTENSIONS and not is_skipped(p):
                yield p


def render_md(results: list[Result]) -> str:
    ts = datetime.now(timezone.utc).isoformat()
    counts = {"fully": 0, "partial": 0, "minimal": 0, "none": 0}
    for r in results:
        counts[r.classification] += 1
    out: list[str] = [
        f"# Observability Scan — {ts}",
        "",
        f"**Summary:** {counts['fully']} fully · {counts['partial']} partial · "
        f"{counts['minimal']} minimal · {counts['none']} not observable · "
        f"({sum(counts.values())} files with signal)",
        "",
        "> Heuristic classifier output. Treat as a starting point — verify with",
        "> agent reasoning before acting on individual files.",
        "",
        "## Worst offenders (lowest scores)",
        "",
        "| File | Score | Class | Signals |",
        "|---|---|---|---|",
    ]
    for r in sorted(results, key=lambda x: x.score)[:25]:
        out.append(f"| `{r.path}` | {r.score} | {r.classification} | "
                   f"{', '.join(r.signals)} |")
    out.append("")
    out.append("## Full table")
    out.append("")
    out.append("| File | Score | Class | Signals |")
    out.append("|---|---|---|---|")
    for r in sorted(results, key=lambda x: (x.score, x.path)):
        out.append(f"| `{r.path}` | {r.score} | {r.classification} | "
                   f"{', '.join(r.signals)} |")
    return "\n".join(out)


def render_json(results: list[Result]) -> str:
    payload = {
        "scanned_at": datetime.now(timezone.utc).isoformat(),
        "counts": {
            "fully": sum(1 for r in results if r.classification == "fully"),
            "partial": sum(1 for r in results if r.classification == "partial"),
            "minimal": sum(1 for r in results if r.classification == "minimal"),
            "none": sum(1 for r in results if r.classification == "none"),
            "total": len(results),
        },
        "files": [
            {
                "path": r.path,
                "score": r.score,
                "classification": r.classification,
                "signals": r.signals,
            }
            for r in sorted(results, key=lambda x: x.score)
        ],
    }
    return json.dumps(payload, indent=2)


def main() -> int:
    args = sys.argv[1:]
    fmt = "md"
    paths: list[str] = []
    for a in args:
        if a == "--json":
            fmt = "json"
        elif a == "--md":
            fmt = "md"
        elif a in ("-h", "--help"):
            print(__doc__)
            return 0
        else:
            paths.append(a)
    if not paths:
        paths = ["."]

    results: list[Result] = []
    for p in paths:
        root = Path(p).resolve()
        if not root.exists():
            print(f"warn: path does not exist: {p}", file=sys.stderr)
            continue
        for f in walk(root):
            res = classify(f)
            if res:
                results.append(res)

    if fmt == "json":
        print(render_json(results))
    else:
        print(render_md(results))
    return 0


if __name__ == "__main__":
    sys.exit(main())
