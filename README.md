# SIGNAU Traccar — configurações

Repositório de **configuração e branding** do Traccar em [traccar.signau.cc](https://traccar.signau.cc).

Não contém o binário do Traccar (JRE, libs, `web/` upstream). Instale o release oficial e aplique este repo.

## Conteúdo

| Caminho | Descrição |
|---------|-----------|
| `conf/traccar.xml` | Configuração do servidor (locale, URL, H2, override) |
| `override/` | Logo SIGNAU, CSS, favicons, `index.html` |
| `deploy/branding-attributes.json` | Atributos do servidor (cores, darkMode, logo, título) |
| `deploy/nginx/traccar.signau.cc.conf` | Site Nginx |
| `deploy/systemd/traccar.service` | Unit systemd |
| `deploy/deploy.sh` | Restaura conf + override + atributos na VPS |

## Restaurar branding após upgrade

Na VPS (como root), com o Traccar já instalado em `/opt/traccar`:

```bash
git clone https://github.com/werlich/traccar.git /opt/traccar-config
cd /opt/traccar-config
bash deploy/deploy.sh
```

Ou, se o clone já existir:

```bash
cd /opt/traccar-config
git pull --ff-only
bash deploy/deploy.sh
```

## Nginx / systemd (primeira vez)

```bash
cp deploy/systemd/traccar.service /etc/systemd/system/traccar.service
systemctl daemon-reload
systemctl enable --now traccar

cp deploy/nginx/traccar.signau.cc.conf /etc/nginx/sites-available/traccar.signau.cc
ln -sfn /etc/nginx/sites-available/traccar.signau.cc /etc/nginx/sites-enabled/
certbot --nginx -d traccar.signau.cc   # se ainda não houver certificado
nginx -t && systemctl reload nginx
```

## O que não vai neste repo

- Banco H2 (`data/`) — usuários e dispositivos ficam só na VPS
- Logs, mídia, JRE e JARs do Traccar

## Branding atual

- Primary: `#053050` (navy SIGNAU)
- Secondary: `#c2a35b` (gold)
- `darkMode: true`
- Logo: `/logo-signau.png`
