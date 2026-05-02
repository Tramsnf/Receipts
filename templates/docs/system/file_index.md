# File Ownership and Purpose Index

> Critical files only. Updated when files are added, removed, or significantly refactored.
> Use this to answer "what does this file do, who owns it, and what breaks if it fails?"

---

## Index

| Path | Purpose | Owner / domain | Inputs | Outputs | Side effects | Blast radius | Observability |
|---|---|---|---|---|---|---|---|
| | | | | | | | fully \| partial \| minimal \| none |

---

## Observability classification key

- **fully observable** — boundary logs + structured errors + safe context + correlation IDs propagated
- **partially observable** — some logs, but missing failure paths, missing context, or missing IDs
- **minimally observable** — sparse prints, no structured errors, no correlation
- **not observable** — silent execution, no useful logs, swallowed errors

---

## Remediation queue

<!-- Files below `fully observable` and what's missing. Move to "Done" once upgraded. -->

### To do

| Path | Current state | Missing | Recommended fix | Risk if left |
|---|---|---|---|---|
| | | | | |

### Done

| Path | Upgraded to | Ledger entry | Date |
|---|---|---|---|
| | | | |
