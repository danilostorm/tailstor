#!/usr/bin/env sh
set -eu

if [ ! -f .env ]; then
  cp .env.example .env
  echo "Criado .env a partir de .env.example"
fi

if [ ! -f config/headscale/config.yaml ]; then
  cp config/headscale/config.yaml.example config/headscale/config.yaml
  echo "Criado config/headscale/config.yaml"
fi

if [ ! -f config/headplane/config.yaml ]; then
  cp config/headplane/config.yaml.example config/headplane/config.yaml
  echo "Criado config/headplane/config.yaml"
fi

echo
echo "Agora edite:"
echo "  .env"
echo "  config/headscale/config.yaml"
echo "  config/headplane/config.yaml"
echo
echo "Depois execute:"
echo "  docker compose config"
echo "  docker compose up -d headscale caddy"
