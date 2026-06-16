# telegram-bot-api Helm chart

This chart deploys the Telegram Bot API server as a StatefulSet with a ClusterIP Service and persistent storage. Ingress and Traefik basic-auth middleware are optional.

## Install with chart-created API Secret

```bash
helm upgrade --install telegram-bot-api ./charts/telegram-bot-api \
  --set telegram.apiId="123456" \
  --set telegram.apiHash="your-api-hash"
```

## Install with an existing API Secret

The Secret must contain the keys configured by `telegram.apiIdKey` and `telegram.apiHashKey`, which default to `TELEGRAM_API_ID` and `TELEGRAM_API_HASH`.

```bash
helm upgrade --install telegram-bot-api ./charts/telegram-bot-api \
  --set telegram.existingSecret="telegram-bot-api"
```

## Enable Traefik ingress with chart-created basic auth

Generate a htpasswd entry first, then pass it as `basicAuth.auth`.

```bash
helm upgrade --install telegram-bot-api ./charts/telegram-bot-api \
  --set telegram.existingSecret="telegram-bot-api" \
  --set ingress.enabled=true \
  --set ingress.hosts[0].host="telegram.example.com" \
  --set ingress.tls[0].hosts[0]="telegram.example.com" \
  --set basicAuth.enabled=true \
  --set traefik.middleware.enabled=true \
  --set-string basicAuth.auth='telegram-bot-api:$apr1$example$replace-this-hash'
```

## Use an existing Traefik basic-auth Secret

The Secret must contain the `auth` key expected by Traefik basicAuth middleware.

```bash
helm upgrade --install telegram-bot-api ./charts/telegram-bot-api \
  --set telegram.existingSecret="telegram-bot-api" \
  --set ingress.enabled=true \
  --set ingress.hosts[0].host="telegram.example.com" \
  --set basicAuth.enabled=true \
  --set basicAuth.existingSecret="telegram-basic-auth" \
  --set traefik.middleware.enabled=true
```
