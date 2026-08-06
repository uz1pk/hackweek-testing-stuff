# static

One nginx container serving one HTML page over plain HTTP. No auth, no TLS, no upstream.

## Start

```bash
docker compose up -d
```

Then open <http://localhost:8080> or:

```bash
curl http://localhost:8080
```

## Layout

| | |
|---|---|
| `html/` | Bind-mounted to nginx's web root. Edit and reload — no restart, no rebuild. |
| `nginx.conf` | The whole config, mounted over the image's default. Read at start only, so config edits need `docker compose restart web`. |

Anything with no matching file returns nginx's stock `404`, as HTML rather than JSON — this server has no opinion about your API.

## Change the port

`8080` appears once, in `docker-compose.yml`:

```yaml
ports:
  - "8080:80"
```

Only the left side is yours to pick; nginx listens on `80` inside the container regardless.
