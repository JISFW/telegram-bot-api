# Telegram Bot API Wrapper

This repository packages [tdlib/telegram-bot-api](https://github.com/tdlib/telegram-bot-api) as a Docker image and tracks upstream through the `telegram-bot-api/` git submodule.

## Repository Layout

- `telegram-bot-api/`: upstream source as a git submodule
- `Dockerfile`: container build for the upstream Bot API server
- `docker-entrypoint.sh`: runtime entrypoint and environment variable mapping
- `.github/workflows/build.yaml`: release build on wrapper tags such as `v9.6`
- `.github/workflows/sync-upstream.yaml`: scheduled/manual upstream sync and tag creation

## Release Model

- `master` advances linearly as upstream `master` moves.
- A version tag is created only when upstream first introduces a new Bot API version in `telegram-bot-api/CMakeLists.txt`.
- Only tag pushes publish container images.
- Image tags match the Bot API version, for example `9.6`.

## Local Setup

```bash
git submodule update --init --recursive
```

## Sync Logic

The scheduled workflow fetches upstream `master`, identifies the newest commit in the updated range that changes `project(TelegramBotApi VERSION X.Y ...)`, then:

1. creates a wrapper commit tagged `vX.Y` that points the submodule at that upstream commit
2. creates one more wrapper commit to move `master` to the latest upstream head if needed

The decision logic is implemented in [`scripts/plan_upstream_sync.sh`](scripts/plan_upstream_sync.sh) and covered by [`tests/test_plan_upstream_sync.sh`](tests/test_plan_upstream_sync.sh).
