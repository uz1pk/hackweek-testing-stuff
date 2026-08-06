# hackweek-testing-stuff

Three independent Docker Compose stacks. Each is brought up on its own.

| | | |
|---|---|---|
| [`llm/`](llm/) | `:8442` | An open-weight LLM behind a token-checked, OpenAI-compatible `/v1/` front door. |
| [`static/`](static/) | `:8080` | Plain nginx serving one HTML page. No auth, no upstream. |
| [`chat/`](chat/) | `:80` | Bare-bones web chat UI for the LLM, served at [raspberry.pi.local](http://raspberry.pi.local). |

```bash
cd llm    && docker compose up -d
cd static && docker compose up -d
cd chat   && docker compose up -d
```

`llm/` and `static/` share nothing at all. `chat/` is the one exception: it reverse-proxies
to `llm/` over the host's published port, so it needs that stack up — but it still runs as
its own project on its own network, reachable or not.

Nothing here uses TLS, and `chat/` puts an unauthenticated door in front of the LLM for
anyone on the same network. Keep all three on a network you trust.

`chat/` is meant to run on a Raspberry Pi alongside `llm/`; see [`chat/README.md`](chat/README.md)
for the deploy and mDNS hostname steps.
