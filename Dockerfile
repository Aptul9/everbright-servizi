# Caddy con la configurazione e la pagina dentro l'immagine: ogni modifica la ricrea.
FROM caddy:2.11.4-alpine
# l'immagine dà a caddy la capacità di aprire le porte basse; qui ascolta sopra la 1024 e il container parte senza capacità
# (cap_drop ALL in compose), con cui un eseguibile che ne chiede una non si avvia
RUN setcap -r /usr/bin/caddy
COPY Caddyfile /etc/caddy/Caddyfile
COPY site /srv/site
