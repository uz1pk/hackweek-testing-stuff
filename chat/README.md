# chat

A bare-bones web chat UI for the `llm` stack, served over HTTPS at <https://offline.llm>.

One nginx container serves the page and reverse-proxies `/v1/` to the `llm` stack, adding the
bearer token server-side — so the page and API share an origin (no CORS) and the token never
reaches the browser.

Both hops are TLS, using the same committed cert from `../llm/certs/`. That directory must be
present alongside this one.

## Start

Needs the `llm` stack up first.

```bash
cd ../llm && docker compose up -d
cd ../chat && docker compose up -d
```

Add the host to `/etc/hosts` on every client that will open the page:

```
127.0.0.1  offline.llm
```

Use the Pi's LAN IP instead of `127.0.0.1` on other devices. Then open <https://offline.llm>.

Your browser will warn on the self-signed cert — accept it once, or import
`../llm/certs/offline.crt` as a trusted root.

## Commands

```bash
docker compose logs -f web
docker compose restart web
```

`nginx.conf` and `html/` are bind-mounted: page edits need only a reload, config edits need a
restart.

A `502` means `:8442` is not answering — `rest` waits for the model download to finish. Check
with `docker compose logs puller` in `../llm`.

## Clean up

```bash
docker compose down
```

## Caveats

- **No auth on the app itself.** Anyone who can reach the Pi can use your LLM.
- The cert expires **2026-09-06**; after that everything fails verification until rotated.
- History lives in a JS variable — reloading forgets everything.
- Needs 64-bit Raspberry Pi OS; `ollama/ollama` ships `arm64` only.
