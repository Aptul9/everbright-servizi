# Servizi Everbright

La pagina `https://servizi.everbright.it`: i link alle applicazioni Everbright (calendario, meet, sito, relay Teams) e il posto per il
password manager, che ancora non c'è. Ogni link si apre in una scheda nuova. Lo stile è quello di `www.everbright.it`.

## Com'è fatta

- `site/`: la pagina, statica (`index.html`, `icon.png`, `logo-icon.png`). Per aggiungere un servizio, o accendere il password manager,
  si cambia la sua scheda in `index.html`.
- `Caddyfile`, `Dockerfile`: Caddy con la pagina dentro l'immagine, HTTPS col certificato di Let's Encrypt. Fuori dai file della pagina
  ogni indirizzo torna alla radice.
- `docker-compose.yml`: il servizio `web`, sul localhost alla porta `HTTPS_PORT`, sola lettura e senza capacità.

## Sul server

La VM è quella di OE Copilot e TeamsRelay (217.76.49.98). La 443 è di sslh, che gira il TLS per nome (SNI): `servizi.everbright.it` va
a `127.0.0.1:4446`, questo Caddy. Il certificato arriva col TLS-ALPN, passando da sslh (la 80 è del Caddy di TeamsRelay). Nel
`/etc/sslh.cfg`:

```
{ name: "tls"; host: "127.0.0.1"; port: "4446"; sni_hostnames: [ "servizi.everbright.it" ]; },
```

Gira come utente `servizi` (nel gruppo `docker`), in `/opt/servizi`: `app/` la versione che gira, `app.prima/` quella di prima,
`.env` scritto dalla pipeline. Il DNS: record A `servizi` su `everbright.it` (Top Host) verso 217.76.49.98.

## Pipeline

`.github/workflows/ci-cd.yml`: a ogni pull request costruisce l'immagine, valida il Caddyfile e prova la pagina (titolo, file, ritorno
alla radice, link in una scheda nuova). Su main, se passa, copia i file sul server, scrive `.env`, ricostruisce e controlla che
`https://<DEPLOY_DOMAIN>/` risponda.

| Dove | Nome | Cosa |
|---|---|---|
| Variabile | `DEPLOY_DOMAIN` | `servizi.everbright.it` |
| Variabile | `HTTPS_PORT` | `4446`, la porta su cui sslh manda il nome |
| Segreto | `DEPLOY_HOST` | indirizzo della VM |
| Segreto | `DEPLOY_USER` | `servizi` |
| Segreto | `DEPLOY_SSH_KEY` | chiave privata di deploy (`servizi-deploy@github-actions`) |
| Segreto | `DEPLOY_KNOWN_HOSTS` | chiave della VM, per non accettarne un'altra |

Tornare alla versione di prima, sul server: `cd /opt/servizi && rm -rf app && mv app.prima app && cd app && docker compose --env-file ../.env up -d --build`.
