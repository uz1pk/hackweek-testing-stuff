# chat

A bare-bones web chat UI for the `llm` stack, served at <http://raspberry.pi.local>.

One nginx container does both jobs: it serves a single static page, and it reverse-proxies
`/v1/` to the `llm` stack while adding the `Authorization` header server-side. That means
the page and the API share an origin (**no CORS to configure**) and the bearer token never
reaches the browser — nothing in View Source contains it.

```
browser ──▶ :80 /            nginx serves html/index.html
        ──▶ :80 /v1/…        nginx adds Bearer token ──▶ host:8442 (llm stack)
```

## Run it locally

Needs the `llm` stack already up, since it proxies to `:8442` on the host.

```bash
cd ../llm && docker compose up -d
cd ../chat && docker compose up -d
```

Then <http://localhost>. Replies stream token-by-token.

## Deploy to the Pi

Both stacks run on the Pi. It must be **64-bit** Raspberry Pi OS — `ollama/ollama` publishes
`arm64` only, with no `arm/v7` variant, so a 32-bit install cannot run the LLM stack at all.

```bash
# on the Pi
git clone <this repo> && cd <repo>
cd llm  && docker compose up -d     # first run pulls the model
cd ../chat && docker compose up -d
```

### Making the hostname resolve

`raspberry.pi.local` has two labels, and Avahi only auto-publishes the single-label
`<hostname>.local` (a stock Pi is `raspberrypi.local`). Setting the Pi's hostname to
`raspberry.pi` will not work either — Avahi rejects dots in `host-name`. Publish it as an
explicit address record instead:

```bash
sudo apt install -y avahi-utils
sudo cp deploy/avahi-alias.service /etc/systemd/system/
sudo systemctl enable --now avahi-alias.service
```

Check it took:

```bash
avahi-resolve -n raspberry.pi.local
```

Once that resolves, every device on the LAN reaches the app at
<http://raspberry.pi.local> with no per-device `/etc/hosts` edits.

## Configure

Deliberately no `.env` — the two values that matter are literals:

| | | |
|---|---|---|
| bearer token | `nginx.conf`, `proxy_set_header Authorization` | Must match `LLM_BEARER_TOKEN` in `llm/.env`. Change both together. |
| model | `html/index.html`, `const MODEL` | Must be a model the `llm` stack has pulled. Check with `curl -H "Authorization: Bearer <token>" localhost:8442/v1/models`. |

The token is the same throwaway local-dev value `llm/.env` already commits. If you ever put
a real token in `llm/.env`, this file becomes a second place it leaks from.

`nginx.conf` and `html/` are both bind-mounted: page edits need only a reload, config edits
need `docker compose restart web`.

## Caveats

- **No auth on the chat app itself.** Anyone who can reach the Pi on your network can use
  your LLM. That's the trade for not having a login; add nginx `auth_basic` if your LAN
  isn't yours alone.
- **No TLS**, so this stays a LAN toy. Don't port-forward it.
- Inference on Pi-class CPUs is slow. `smollm2:135m` is roughly the usable ceiling, and it
  is a 135M-parameter model — expect it to be fast and not very bright.
- Conversation history lives in a JS variable. Reloading the page forgets everything.
- The Pi-side steps above (Avahi unit, arm64 deploy) are **written but not tested** — they
  were authored against `avahi-publish(1)` and the image manifests, not run on hardware.
