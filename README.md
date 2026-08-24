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
- nginx terminates TLS and proxies to Kestrel
- GitHub Actions deploys on push to `main`

### GitHub secrets

| Secret | Example |
| --- | --- |
| `SSH_HOST` | `65.109.221.32` |
| `SSH_USER` | `root` |
| `SSH_PRIVATE_KEY` | private key used for deploy |
| `SSH_PORT` | `22` (optional) |

### First-time server bootstrap

```bash
scp deploy/nginx/aloestelam.ir.conf deploy/systemd/aloestelam.service deploy/scripts/bootstrap-server.sh root@65.109.221.32:/tmp/
ssh root@65.109.221.32 'chmod +x /tmp/bootstrap-server.sh && CERTBOT_EMAIL=admin@aloestelam.ir /tmp/bootstrap-server.sh'
```

DNS A records for `aloestelam.ir` and `www.aloestelam.ir` must point to `65.109.221.32` before certbot can issue certificates.

After DNS is ready:

```bash
scp deploy/nginx/aloestelam.ir.conf deploy/scripts/issue-cert.sh root@65.109.221.32:/tmp/
ssh root@65.109.221.32 'sed -i "s/\r$//" /tmp/issue-cert.sh && chmod +x /tmp/issue-cert.sh && /tmp/issue-cert.sh /tmp/aloestelam.ir.conf'
```
