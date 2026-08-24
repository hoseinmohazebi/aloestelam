# Aloestelam

ASP.NET Core Razor Pages app with Clean Architecture.

## Structure

- `src/Aloestelam.Domain` — entities and domain rules
- `src/Aloestelam.Application` — use-case contracts
- `src/Aloestelam.Infrastructure` — implementations
- `src/Aloestelam.Web` — Razor Pages UI
- `deploy/` — nginx, systemd, and server scripts

## Local run

```bash
dotnet run --project src/Aloestelam.Web
```

## Production

- Domain: `aloestelam.ir`
- App listens on `127.0.0.1:5090`
- nginx terminates TLS and proxies only `aloestelam.ir` / `www.aloestelam.ir` to Kestrel
- GitHub Actions deploys on push to `main`
- TLS is issued automatically when DNS/Cloudflare becomes reachable (`aloestelam-cert.timer` + scheduled workflow)

### Cloudflare

1. A records for `@` and `www` → `65.109.221.32`
2. SSL/TLS mode: **Full** (after origin cert is issued) or **Flexible** temporarily
3. For first certificate: keep HTTP reachable to origin (do not force HTTPS-only redirect until cert exists)

No manual `scp` / certbot commands are required after DNS propagates.

### GitHub secrets

| Secret | Example |
| --- | --- |
| `SSH_HOST` | `65.109.221.32` |
| `SSH_USER` | `root` |
| `SSH_PRIVATE_KEY` | private key used for deploy |
| `SSH_PORT` | `22` (optional) |
