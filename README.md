# Next Token — how a language model writes

A 44-second looping classroom animation of how a large language model (LLM) produces text,
with bilingual captions (English · Spanish):

1. **Tokens** — a prompt is typed, split into tokens, and each token gets an ID number.
2. **Vectors** — each ID becomes a column of numbers (an embedding).
3. **Attention** — the last token looks back at the earlier ones; arcs show how much.
4. **Layers** — the vectors flow up through a stack of layers (a causal network).
5. **Prediction** — the last layer gives a probability for each candidate next token.
6. **Repeat** — one token is sampled, added to the text, and the next one is generated.

Then one rotating beat about how it learned and its limits (training, hallucinations, context
window and knowledge cutoff, randomness), and the sentence dissolves.

The example prompt changes every loop and alternates between English and Spanish (6 prompts).
Token IDs, attention weights and probabilities are **illustrative**, not taken from a real model.

## Install (Ubuntu 24.04, Firefox)

1. Copy this folder to the smartboard PC (USB drive or download).
2. Open a terminal in the folder and run:

       bash install.sh

   Use `bash install.sh --no-dock` if you don't want the icon added to the dock.
3. Start it from the dock, the app grid (search "Next Token"), or the desktop icon.
   If the desktop icon shows a lock or won't launch, right-click it → **Allow Launching**.

Touch the board or press any key to exit. Input is ignored for the first 1.5 s so the tap
that starts it doesn't close it.

## Remove

    bash uninstall.sh

## Preview on any computer

Open `next-token.html` in a browser. Optional URL parameters:

| Parameter | Effect |
|---|---|
| `?t=29` | Freeze at second 29 (0–44) |
| `?p=0` … `?p=5` | Force an example prompt |
| `?beat=0` … `?beat=3` | Force the end beat (training, hallucinations, limits, randomness) |
| `?fxw=1920` | Lower the canvas resolution if animation stutters on a 4K board (default 3840) |

## What the installer does

- Copies the page into `~/snap/firefox/common/next-token` (snap Firefox) or `~/.local/share/next-token`.
- Creates a separate, quiet Firefox profile there; your normal Firefox profile is untouched.
- Launches Firefox in kiosk mode and keeps the screen from blanking while it plays.
- No sudo, no internet needed: the page is a single self-contained HTML file with no dependencies.

## Editing

Everything is in `next-token.html`. Example prompts, captions, and end beats are at the top of its script
(`PROMPTS`, `SCENES`, `BEATS`); the timeline constants follow them.
