# Tailstor

Tailstor é uma stack self-hosted para montar uma rede privada no estilo Tailscale, usando **Headscale** como control plane, **WireGuard/Tailscale clients** como data plane, **DERP próprio** como relay de fallback e **Headplane** como painel web.

> Status: MVP inicial. Rode em paralelo com sua Tailnet atual até validar conectividade, rotas e desempenho.

## Arquitetura

```text
                 Internet
                    |
          +---------+----------+
          |                    |
       Headscale          DERP embutido
     control plane        relay fallback
          |                    |
          +---------+----------+
                    |
        +-----------+-----------+
        |           |           |
      Unraid       PC        Celular
        |
        +-- subnet router -> 192.168.30.0/24
```

O tráfego entre peers tenta ser **P2P direto**. O DERP só entra no caminho quando a conexão direta não é possível.

## Componentes

- Headscale 0.29.3
- Headplane 0.7.1 (painel opcional)
- Caddy para HTTPS
- SQLite para persistência do Headscale
- DERP/STUN embutido no Headscale
- DERPs oficiais do Tailscale mantidos como fallback durante a fase inicial

## Portas da VPS

- TCP 80: ACME/redirect
- TCP 443: HTTPS (Headscale e painel)
- UDP 3478: STUN do DERP
- TCP 9090: métricas somente na rede Docker

## Início rápido

1. Clone o repositório.
2. Copie os arquivos de exemplo:

```bash
cp .env.example .env
cp config/headscale/config.yaml.example config/headscale/config.yaml
cp config/headplane/config.yaml.example config/headplane/config.yaml
```

3. Edite `.env` e `config/headscale/config.yaml` com seus domínios reais.
4. Aponte os DNS A/AAAA para a VPS.
5. Inicie a base:

```bash
docker compose up -d headscale caddy
```

6. Verifique:

```bash
curl https://vpn.seudominio.com/health
docker compose logs -f headscale
```

## Criar o primeiro usuário

```bash
docker compose exec headscale headscale users create danilo
```

## Conectar um cliente Tailscale ao Tailstor

No Linux:

```bash
sudo tailscale up --login-server=https://vpn.seudominio.com
```

O comando exibirá uma URL/chave de registro. Registre-a no Headscale:

```bash
docker compose exec headscale headscale auth register --auth-id <AUTH_ID> --user danilo
```

## Unraid como subnet router

Depois que o cliente do Unraid estiver conectado ao Tailstor:

```bash
tailscale up \
  --login-server=https://vpn.seudominio.com \
  --advertise-routes=192.168.30.0/24
```

A rota ainda precisa ser aprovada no Headscale. Confira os comandos disponíveis na versão instalada com:

```bash
docker compose exec headscale headscale nodes --help
docker compose exec headscale headscale routes --help
```

## Headplane (painel web)

O painel fica em um profile separado para que o Headscale funcione antes de existir uma API key.

Crie uma API key:

```bash
docker compose exec headscale headscale apikeys create
```

Coloque a chave em `config/headplane/config.yaml` e então:

```bash
docker compose --profile ui up -d
```

Acesse `https://admin.seudominio.com`.

## Benchmark Tailscale x Tailstor

Antes de migrar de vez, compare:

```bash
tailscale ping <peer>
iperf3 -s
iperf3 -c <ip-do-peer>
```

Anote se a conexão é `direct` ou `DERP`, além de ping e throughput.

## Segurança

- Não publique API keys, chaves privadas ou arquivos de banco.
- Não exponha 9090 publicamente.
- O painel Headplane deve ficar atrás de autenticação antes de uso em produção.
- Durante os testes, mantenha o Tailscale oficial ativo como caminho de recuperação.
- Revise a policy antes de adicionar mais usuários.

## Próximos passos

- autenticação OIDC no painel;
- health dashboard;
- métricas de direct/DERP;
- benchmark automatizado;
- backup do SQLite;
- DERP dedicado opcional;
- instalador específico para Unraid.
