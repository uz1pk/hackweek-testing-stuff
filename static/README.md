# static

One nginx container serving one HTML page over plain HTTP. No auth, no upstream.

## Start

```bash
docker compose up -d
```

Then <http://localhost:8080>.

## Commands

```bash
curl http://localhost:8080
docker compose logs -f web
docker compose restart web
```

`html/` is bind-mounted, so page edits need only a reload. `nginx.conf` is read at start only,
so config edits need a restart.

To change the port, edit the left side of `"8080:80"` in `docker-compose.yml`.

## Clean up

```bash
docker compose down
```
