# Servizi Everbright

La pagina `https://servizi.everbright.it`: i link alle applicazioni Everbright (calendario, meet, sito, relay Teams) e il posto per il
password manager, che ancora non c'è. Ogni link si apre in una scheda nuova. Lo stile è quello di `www.everbright.it`.

## Com'è fatta

- `site/`: la pagina, statica (`index.html`, `icon.png`, `logo-icon.png`). Per aggiungere un servizio, o accendere il password manager,
  si cambia la sua scheda in `index.html`.
- `Caddyfile`, `Dockerfile`: Caddy con la pagina dentro l'immagine, HTTPS col certificato di Let's Encrypt. Fuori dai file della pagina
  ogni indirizzo torna alla radice.
- `docker-compose.yml`: il servizio `web`, sul localhost alla porta `HTTPS_PORT`, sola lettura e senza capacità. Monta in sola lettura
  `/opt/servizi/downloads` su `/download/`: le build che le pipeline delle app mettono sulla VM, pubbliche.
- `ci/`: `prepara-download.sh`, lanciato dal deploy, crea la cartella, installa `ricevi-build` in `/opt/servizi/bin` e aggiunge ad
  `authorized_keys` di `servizi` le chiavi di `chiavi-build.pub`. Quelle chiavi hanno `restrict,command=`: possono solo mandare uno ZIP
  su stdin con nome e sha256 (`ssh servizi@vm "<nome>.zip <sha256>" < file`), che entra intero e verificato o non entra.

## Download

Riquadro **Scarica i nostri prodotti**, che apre /prodotti/ (site/prodotti/index.html), un riquadro per prodotto:

| Voce | File | Da dove arriva |
|---|---|---|
| EverTranscript Windows | `/download/EverTranscript-Windows-x64.zip`, installer dal campo `setup` del JSON | `Aptul9/evertranscript-windows`, job di rilascio su main, chiave `evertranscript-windows@github-actions` |
| Agent Awake | il `file` di `/download/AgentAwake-Windows-x64.json` | finché il JSON non c'è la scheda è "In arrivo", senza link |
| AI Plan Usage | il `file` di `/download/AI-Plan-Usage-Windows-x64.json` | finché il JSON non c'è, link diretto all'asset 0.1.1 della release GitHub di `Aptul9/ai-plan-usage` |

Ogni prodotto mette in `/download/` un JSON con almeno `{"version","sha256","bytes","commit","file"}`, dove `file` è il nome del download nella stessa cartella. La pagina lo legge all'apertura (`data-versione="<url del JSON>"` sulla scheda) e mostra "Versione X del <data>": la data è il `Last-Modified` del JSON, cioè quando è arrivato sul server; `sha256` e `commit` nel tooltip. Se il JSON manca o è rotto la scheda resta com'è.

- Le schede con `data-dal-json` (Agent Awake, AI Plan Usage) prendono anche il link dal `file` del JSON, con il peso da `bytes`. Un `file` che non è un nome semplice `.zip`, `.exe` o `.msi` (percorsi, URL) vale come JSON assente.
- La scheda di EverTranscript apre un popup con due riquadri: "Installer (.exe)" da `setup: {"file","sha256","bytes"}` e "ZIP portatile" dai campi principali. Senza `setup` l'installer è "In arrivo" e lo ZIP funziona. Senza JavaScript la scheda scarica lo ZIP.
- `ci/ricevi-build.sh` oggi accetta solo `.zip` e `.json`: un installer `.exe` non entra da quella strada finché non la si allarga, e un prodotto nuovo ha bisogno della sua chiave in `chiavi-build.pub`.

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
