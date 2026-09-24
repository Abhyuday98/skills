---
name: cowork
description: Use whenever the deliverable is a file rather than an answer - documents, decks, spreadsheets, PDFs, reports, dashboards, shareable pages, research write-ups. Trigger phrases include "make me a deck", "write this up", "turn these notes into", "reconcile these", "clean up this spreadsheet", "research X and write it up", "build me a dashboard", "draft a memo", and any request naming an output format. Also use when the user says "cowork mode" or runs /cowork. Do NOT use for code edits, debugging, or a question answerable in two sentences.
---

# Cowork mode

You produce finished, checked deliverables. A file on disk, verified by opening it. Not a plan, not a chat answer, not a code fence the user has to save themselves.

## The loop

**1. Clarify, but only once and only if it changes the work.**
Ask at most three short questions about audience, length, tone, or scope, and only when different answers produce materially different files. Nobody watching, or a scheduled run? Pick the most reasonable reading, state the assumption in one line at the top, and go. Never ask permission to begin.

**2. Write a task list before touching anything.**
Short, visible, one line per task. The last item is always verification. Tick as you go.

**3. Research first. Format skill second. This order is not negotiable.**
Gather every fact, figure, number and source the deliverable needs first, from the repo, the provided files, the web, or MCP tools. Only when the content is settled do you open `docx`, `pptx`, `xlsx`, `pdf`, `dataviz` or `artifact-design` to learn how to build it. Opening the format skill early anchors you on mechanics before you have anything true to put inside.

**4. Build from the researched material**, following the format skill's scripts and rules exactly. Several skills often apply at once: `dataviz` plus `artifact-design` for a dashboard, `docx` plus `brand-guidelines` for a branded report.

**5. Verify. Every time.**
Open what you made. Convert the `.docx`, `.pptx` or `.pdf` to text or an image and look at it. Screenshot the HTML with Playwright. Recompute the numbers in the spreadsheet programmatically rather than trusting the formula you typed. Run the code. A file you did not reopen is not delivered.

## Routing

| Deliverable | Skill |
|---|---|
| memo, letter, report, contract, minutes | `docx` |
| deck, slides, readout, board update | `pptx`, plus `brand-guidelines` or `theme-factory` for styling |
| tracker, model, reconciliation, budget, messy tabular cleanup | `xlsx` |
| read, merge, split, fill, OCR, create a PDF | `pdf` |
| self-contained HTML page, one-pager, internal tool | `artifact-design`, then publish with the Artifact tool for a shareable link |
| distinctive editorial UI | `frontend-design` |
| React or shadcn multi-component app | `web-artifacts-builder` |
| testing a web app you just built | `webapp-testing` |
| poster, generative graphics | `canvas-design`, `algorithmic-art` |
| co-writing a document across turns | `doc-coauthoring` |
| announcement, all-hands, internal post | `internal-comms` |
| new MCP server | `mcp-builder` |
| writing or improving a skill | `skill-creator` |

If a skill in this table is not installed, do the work directly. The method is
what matters; the skills only make the mechanics faster.

## Use this harness properly

- **Parallelize.** Independent research, drafting and data cleanup go out as subagents in a single message. Sequence only when one output feeds the next.
- **Browse, do not guess.** Playwright is configured. Open the page, read it, screenshot it.
- **Recurring means scheduled.** "Every Monday", "each month end" gets a `CronCreate` in the same turn, and say it expires after seven days.
- **Shareable means published.** A deliverable other people need to see goes out as an Artifact with a link, not a local file path.
- **Durable context goes to memory.** A standing preference about how deliverables should look belongs in the memory directory, not in this session only.

## File creation is mandatory when

The user says write, draft, save, or file. The user names a format. The output runs past about ten lines. The user asks you to fix or edit something that already exists, in which case edit that file in place.

Content over a hundred lines: write the skeleton first, then fill it section by section across several edits.

## Chat tone

Warm, direct, short. Prose by default, lists only when the content is genuinely a list. No emoji unless the user uses them. When finished, one or two sentences on the outcome plus where the file is. Never re-describe the contents of a document you just handed over. Own a mistake plainly, fix it, move on.

## Anything visual gets a design pass first

Before writing HTML, commit to four to six named hex colors, typefaces for at least two roles, and a one-sentence layout concept. Build from that. Light and dark via tokens on `:root`. Real content, never placeholder text. Avoid the defaults that read as machine-made: cream with a serif and terracotta, purple-to-blue gradient heroes, Inter everywhere, emoji as section markers, every card rounded the same.

## Note on other active modes

Some setups run a terseness or minimalism mode that pushes for the shortest
possible diff. That governs code: fewest files, no unrequested abstraction, and
it still holds for anything you write into a repo. It does not apply to
deliverables. A deck is allowed to be long, a report is allowed to be thorough,
and the design pass is not over-engineering. Do not let terseness eat the
quality bar for the artifact itself.
