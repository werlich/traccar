#!/usr/bin/env bash
# Aplica conf + override SIGNAU + atributos de branding na instalação Traccar da VPS.
# Uso (na VPS, como root):
#   cd /opt/traccar-config   # ou clone deste repo
#   bash deploy/deploy.sh
# Variáveis opcionais:
#   TRACCAR_HOME=/opt/traccar
#   REPO_ROOT=diretório deste repositório
set -euo pipefail

TRACCAR_HOME="${TRACCAR_HOME:-/opt/traccar}"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ATTR_JSON="${REPO_ROOT}/deploy/branding-attributes.json"

if [[ ! -d "${TRACCAR_HOME}" ]]; then
  echo "Erro: TRACCAR_HOME não existe: ${TRACCAR_HOME}"
  echo "Instale o Traccar oficial primeiro (https://www.traccar.org/linux/)."
  exit 1
fi

if [[ ! -f "${ATTR_JSON}" ]]; then
  echo "Erro: falta ${ATTR_JSON}"
  exit 1
fi

echo "==> Copiando conf/"
install -d "${TRACCAR_HOME}/conf"
cp -f "${REPO_ROOT}/conf/traccar.xml" "${TRACCAR_HOME}/conf/traccar.xml"

echo "==> Copiando override/ (branding SIGNAU)"
install -d "${TRACCAR_HOME}/override"
rsync -a --delete "${REPO_ROOT}/override/" "${TRACCAR_HOME}/override/"

# Espelha assets críticos no web/ (alguns clients/cache usam esses paths)
for f in logo-signau.png logo.png styles.signau.css styles.css favicon.ico login-bg.svg; do
  if [[ -f "${TRACCAR_HOME}/override/${f}" ]]; then
    cp -f "${TRACCAR_HOME}/override/${f}" "${TRACCAR_HOME}/web/${f}"
  fi
done
if [[ -f "${TRACCAR_HOME}/override/index.html" ]]; then
  cp -f "${TRACCAR_HOME}/override/index.html" "${TRACCAR_HOME}/web/index.html"
fi

echo "==> Reaplicando atributos de branding no H2"
ATTRS="$(python3 - <<PY
import json
from pathlib import Path
print(json.dumps(json.loads(Path("${ATTR_JSON}").read_text()), separators=(",", ":")))
PY
)"
# Escape single quotes for SQL string literal
ATTRS_SQL="${ATTRS//\'/\'\'}"

systemctl stop traccar
sleep 2
cd "${TRACCAR_HOME}"
./jre/bin/java -cp "lib/*" org.h2.tools.Shell \
  -url "jdbc:h2:./data/database" -user sa -password "" \
  -sql "UPDATE TC_SERVERS SET ATTRIBUTES = '${ATTRS_SQL}';"
systemctl start traccar

# Aguarda API
for i in $(seq 1 30); do
  if curl -fsS -o /dev/null "http://127.0.0.1:8082/api/server" 2>/dev/null; then
    break
  fi
  sleep 2
done

echo "==> Branding atual:"
curl -fsS "http://127.0.0.1:8082/api/server" | python3 -c 'import sys,json; print(json.dumps(json.load(sys.stdin).get("attributes",{}), indent=2, ensure_ascii=False))'
echo "Deploy concluído ($(date -u +%Y-%m-%dT%H:%M:%SZ))"
