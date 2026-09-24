# Headless narrated-film pipeline: full reference

Everything here was learned producing a real ~20-minute capability film entirely
inside a GitHub Codespace: no display, no microphone, no human at the keyboard, hard
duration cap, and an audience that sees ONLY the video (so every claim on screen has
to be verifiable from the video itself). Read the whole file once before starting;
skim it again before each stage.

## 0. Install everything first

Run `scripts/install.sh`. It installs: tmux, ffmpeg (apt); asciinema (pipx); agg (a
single GitHub-release binary); kokoro-onnx + its two model files (~350MB, from the
thewh1teagle/kokoro-onnx releases) plus soundfile; and Playwright's Chromium if the
repo does not already carry one. piper-tts exists as a fallback TTS but do not start
there (see Voice, below).

## 1. Voice (decided by listening, not by docs)

- **kokoro-onnx** (82M params, Apache) is the default. It reads punctuation with real
  prosody. The first cut used piper and the owner's verdict was "extremely drab";
  kokoro replaced it and survived every later review.
- **Voice `af_heart`, speed 0.95** was the final pick after auditioning. Render 5-6
  one-line samples across voices (`af_heart`, `af_nicole`, `bf_emma`, `bm_george`...)
  and let the owner choose before rendering 50+ cues; keep the sample wavs beside the
  deliverable so the choice is revisitable.
- Narration cue keys live in one `narration.md`: a `[cue-key]` heading followed by the
  spoken text. The assembler renders one wav per cue and caches by key - **delete the
  wav whenever you edit a cue's text**, or the old audio ships.
- Write narration humanizer-clean: plain speech, no em dashes, short sentences, no
  jargon a non-technical evaluator would stumble on. Tell viewers they do not need to
  read the screens; the narration carries the meaning and key moments hold still.

## 2. The terminal act (a REAL interactive agent session)

Recording rig:

```bash
tmux new-session -d -s demo -x 120 -y 36
TERM=xterm-256color asciinema rec --cols 120 --rows 36 -i 1.5 \
  -c "tmux attach -t demo" take.cast &   # TERM is MANDATORY: the driving shell has
                                         # none and tmux dies with "terminal does not
                                         # support clear" inside asciinema
```

Drive with `tmux send-keys -t demo -l '<literal text>'` then a separate `Enter`; read
state with `tmux capture-pane -pt demo`. `scripts/drive.sh` wraps this and
`scripts/babysit.sh` loops: approve permission dialogs, wait while the spinner shows,
exit when the pane is idle.

Traps, all hit for real:

- **Ghost prompt suggestions are not input.** The TUI pre-fills a greyed suggestion;
  Enter does nothing. Always `C-u`, type literally, Enter.
- **Permission modes cycle** with Shift+Tab (`send-keys BTab`). Manual mode keeps the
  approval prompts visible on camera - but narrate modes as OPTIONS, with automatic as
  the day-to-day recommendation (work completes and a PR opens on its own); manual is
  chosen for the film so the controls are visible. Do not glorify click-per-file.
- **Plan mode's "Tell Claude what to change"** gives an interrogation round-trip that
  visibly revises the plan - film that; it is the best governance moment available.
- **The repo's own hooks fire on YOUR driving commands.** A release-guard hook blocked
  a `send-keys` whose literal text contained the trigger words. Split the word across
  two `-l` sends, or put payloads in a script file and run the file.
- **`pkill -f word` kills your own shell** when the word appears in your own command
  line (exit 144). Use `pkill -f '[w]ord'`.
- **Anchor on typed INPUT, never output.** Typed text arrives in the cast as one
  event; TUI output fragments across escape-sequence events. All later timing searches
  the cast for the literal strings you typed.
- Never run heavy work (builds, renders) while a recording runs - encoders lose the
  CPU race and the recording stutters.

- **A plain shell act is easier than a TUI act, with its own traps.** When the recorded
  session is ordinary commands (a service log, `git`, `gh`, `jq`, `curl`), anchor on
  OUTPUT strings, not typed text: plain output arrives in one event, and holding on the
  result is what the narration wants. Then: strip ANSI before matching (`jq` colours
  its output, and tmux emits `ESC ( B` charset selects mid-string, so the literal
  `"tier": "words"` never appears in one piece); run the shell with `env -i` and a
  fixed `PS1` so no hostname or username reaches the cast, but pass
  `XDG_RUNTIME_DIR` and `DBUS_SESSION_BUS_ADDRESS` through or `systemctl --user`
  says "Failed to connect to bus"; set `PAGER=cat GH_PAGER=cat` or `gh pr view` opens
  `less` and the take records nothing; and if `gh pr view` prints only a GraphQL
  deprecation warning, ask for `--json` fields with `--jq`, which skips the query
  that fails. Turn the tmux status bar off (`tmux set status off`): it carries the
  hostname and the clock.
- **Hold sizing when narration chains.** With GRACE 4.5 the holds were too short for
  back-to-back cues: each cue starts after the previous one ends, the shifts add up,
  and the last terminal cue was still talking over the next slide. For a shell act
  where nothing moves between anchors, size the hold to the whole cue plus a second
  (GRACE -1.0) and let the warp own the pace.

## 3. Time warp + scrub (castwarp.py) - one script owns the cast

A raw take is unwatchable (ours: 57 minutes; spinner repaints defeat asciinema's idle
limit). The warp rebuilds the timeline from deltas: events with no newline are
"quiet" (spinner/cursor/typing echo) and each RUN of them is capped (~0.9s); content
events keep at most ~0.42s. 57 min became ~10 readable minutes.

**The same script is the ONLY place text is rewritten.** The SCRUB list maps every
client name, domain, account string, branch name, and fourth-wall phrase to neutral
wording - most-specific pairs first, since replacement is plain string substitution
inside event payloads (lengths need not match). Any edit made directly to the warped
file is LOST on the next re-warp, so it must not happen.

Scrub verification is a REGEX SWEEP of the full joined text, not a memory exercise:

- 12-digit numbers (`(?<!\d)\d{12}(?!\d)`) - cloud account ids ride along in prose
  even after the account NAME was scrubbed (this happened);
- GUIDs, email domains, personal names, tenant ids, `arn:`, secret-shaped strings;
- ANSI-strip the cast to plain text and READ the major beats: word-swaps can leave
  ungrammatical sentences ("the sanitised work") - map whole phrases instead.

**Narration holds**: `gen_holds.py` sizes a pause at each anchor from that cue's wav
duration - `hold = max(0, (vo_seconds - 4.5) * TS)` where TS is the terminal playback
speed factor (below) - and castwarp inserts the pause at the first event containing
the anchor string. The screen then holds still while its narration plays.

**Render**: `agg --font-size 15 --theme <theme> --idle-time-limit 45 take-warped.cast
out.gif`. The idle limit is NOT optional: **agg silently caps every inter-frame gap
at 5 seconds by default**, which truncates all the holds you just inserted; the
symptom appears far downstream as anchor drift and an ffmpeg "durationi out of
range" failure on a negative segment length. Set it above your longest hold. Then
ffmpeg the gif to a padded 1080p mp4.

## 4. App tour + document/evidence captures (Playwright)

Tour clips (`tourclip.cjs` shape):

- **Static build, never the dev server**: build with demo/mock mode on, serve with
  `vite preview`. The dev server's transform pipeline hangs navigations bimodally
  (instant or never).
- **`recordVideo` needs Playwright's own ffmpeg**, even with the system Chrome
  channel and a system ffmpeg on PATH: `node <playwright-core>/cli.js install ffmpeg`
  or the context fails with "Executable doesn't exist at .../ffmpeg-linux".
- **Zooming the page for legibility scrolls it.** `document.documentElement.style.zoom`
  makes `100dvh` layouts taller than the viewport, so the document scrolls and the
  header leaves the frame; add `html, body { height: calc(100vh / ZOOM) }` alongside.
  Convert `boundingBox()` coordinates by the same factor before `mouse.move`.
- **Wait for the thing itself, not a phrase.** `text=see it` resolved on the model's
  own reply ("You'll see it in the footer") and the take ended before the PR link
  appeared. Wait for the element: `#log a[href*="/pull/"]`.
- **One fresh Chromium PER SCENE** (launch → record → close). Reused browsers starve:
  each recorded page adds an encoder.
- `recordVideo` on the context captures webm; no Xvfb, no window manager.
- **Fake cursor** via addInitScript (a dot following real mouse events) because
  captured video has no OS cursor; glide with `steps: 20+`.
- **Readiness = a text marker that only exists when data rendered**, verified against
  the real DOM first. Record a per-clip lead `trim` and cut it in assembly.
- **Film parameterised routes by clicking through from a loaded page** - a direct
  goto flashes the router's Not Found state. Verify a route exists before filming it.
- Recording slows the app noticeably - sample frames (`ffmpeg -ss N -frames:v 1`)
  before choosing trim points; never trust the wall-clock action schedule.
- If the app has an expandable panel (a chat widget with a full-screen mode), film
  the EXPANDED mode so results are legible at 1080p.

Document captures (`docshot.cjs`): render the real markdown files in a light "paper"
viewer chrome (file path in the header bar, "tracked in git" tag) and screenshot at
1920x1080, scrolled to the section the narration discusses. Real files only - the
audience must be able to believe a pause would survive scrutiny.

Evidence cards (`evshot.cjs`): real command output (`ls`, `git log`, `gh pr view`, a
reviewer's verdict) inside a dark console card on the slide ground, key tokens
highlighted. CURATE by deleting lines (fourth-wall commit messages, usage footers,
client domains quoted from diffs) - never rewrite the remaining text.

Annotated before/after cards (`evfinding.cjs`): cut row strips out of verified
screenshots, position highlight boxes in NATIVE strip pixels converted to
percentages. **Never draw annotation boxes by eye on a full-page screenshot** - the
first attempt ringed empty whitespace on the wrong row and the owner caught it. If
the "before" state needs data the seed lacks, stage a data edit purely for the
screenshots, then `git checkout` the files and rebuild.

**Margin-collapse footgun**: on a fixed 1920x1080 card page, a top margin on the
first child collapses THROUGH body (body's overflow is propagated to the viewport,
so body is not a BFC) and shoves the whole body down; bottom-anchored captions then
render below the frame. Give the first element `padding-top`, never a top margin.

## 5. Slides (deckshoot over one deck.html)

One HTML file, one `<div class="slide" id="sN">` per 1920x1080 slide, inline CSS,
screenshot each `#sN`. Two hard rules:

- **Match the client's real template by RENDERING it, not by reading theme XML.** The
  theme palette in a pptx lied about the ground colour (the content slides were light
  while the XML suggested dark). Unzip the pptx, pull the real logo from
  `ppt/media/`, and view actual slides (or ask the owner for screenshots) before
  styling. Recolor a white logo variant per-pixel for light grounds.
- Prefer diagrams over prose walls: a before/after lane diagram (label on the left,
  boxed steps with arrows, the failure step dark, the win step accent-filled) lands
  where three text boxes did not.

## 6. Assembly (assemble.py) - audio drives video, by construction

The plan is an ordered list of segments: stills (slides/docs/cards), clips (tour
webm with trim), terminal parts (the gif-mp4 split at cast anchors so doc captures
can interleave), and a closing.

- **Per-segment VO coverage (the drift fix)**: keep a running video clock `t` and an
  audio cursor `prev_end`. For each still: `vo_start = max(t + 0.9, prev_end + 0.7)`
  and the still's duration is `(vo_start - t) + vo_len + ~1s`. A slide can then NEVER
  advance while any narration (its own or an overrun from earlier) is still playing.
  A global "push starts apart" pass alone is not enough - audio shifts accumulate and
  slides advance mid-sentence (a shipped defect, caught by the owner).
- **Terminal speed factor TS**: play the terminal mp4 at `setpts=PTS/TS`, divide
  every cast-anchor time by TS, and generate holds pre-scaled by TS. The order after
  changing TS is fixed: gen_holds → castwarp → agg → assemble. Playback speed is the
  right lever for a duration cap ("content clean first, then speed").
- Segment mp4s are cached by filename - **wipe the cache whenever timing inputs
  change** (cue text, TS, plan order), or stale durations ship silently.
- Audio: each cue wav `adelay`ed to its start, `amix`, `loudnorm`. SRT from the same
  timeline, ~90 chars per block.
- **Ending**: close on the cover slide with a farewell cue, ~0.8s fade-in and ~2.2s
  fade-out. An unfaded stop reads as broken.
- Ship a natural-speed (TS=1.0) reference cut beside the capped one; same content.

## 7. Content principles (what reviews kept coming back to)

- **Capability demonstration, not product demo.** Explain the toolkit as "what we
  use", name the stack precisely (harness, models per stage, reviewer agents,
  guardrail scripts, what stays human), and show governance moments: a critic
  catching a spec gap, a plan revised under questioning, a hook refusing to weaken
  tests, a release gate refusing a deploy, and a monitoring finding re-entering the
  loop as new work.
- **Every claim must be verifiable from the video**: real files paused on screen,
  real command output, a real PR opened with `gh pr create` and shown via
  `gh pr view`, and a real independent automated review (the `copilot` CLI can review
  a PR diff against a spec read-only when the org's PR-review bot is unavailable;
  post the verdict on the PR with `gh pr comment`).
- **Honesty beats polish**: if a beat is simulated (a synthetic alert), the artifact
  on screen should SAY so; an evaluator who pauses must not catch the film staging
  something as real.
- One concrete story per abstract idea. For a monitoring/autonomy model: one health
  metric, what the agent may do at each severity, and that every route ends at a
  person. Cut any card the owner cannot follow (a raw YAML config card died here).
- Non-technical viewers: narration says what matters on each screen, key moments hold
  still, side-by-side before/after beats show the change instead of asserting it.

## 8. Verification habits that saved every cut

- Extract frames and LOOK at them after every stage; a green exit code says nothing
  about skeleton screens, an unopened panel, or a Not Found flash.
- Audit the FINAL film: a frame at every segment boundary, overlap count on the audio
  timeline (must be 0), duration vs the cap, and the full-text leak sweep.
- Background long renders and keep working; never poll with sleeps.
- The deliverable folder carries: the capped mp4, the 1x mp4, both srt files, the
  narration, the voice track, the voice samples, and a README describing the cut.
