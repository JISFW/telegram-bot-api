#!/bin/sh
set -e

if [ -n "${1}" ]; then
    exec "${*}"
fi

TELEGRAM_API_ID=${TELEGRAM_API_ID:?Need to set TELEGRAM_API_ID}
TELEGRAM_API_HASH=${TELEGRAM_API_HASH:?Need to set TELEGRAM_API_HASH}

# telegram-bot-api --help
# Usage: telegram-bot-api --api-id=<arg> --api-hash=<arg> [--local] [OPTION]...

# Telegram Bot API server. Options:
#   -h, --help                          display this help text and exit
#       --version                       display version number and exit
#       --local                         allow the Bot API server to serve local requests
#       --api-id=<arg>                  application identifier for Telegram API access, which can be obtained at https://my.telegram.org (defaults to the value of the TELEGRAM_API_ID environment variable)
#       --api-hash=<arg>                application identifier hash for Telegram API access, which can be obtained at https://my.telegram.org (defaults to the value of the TELEGRAM_API_HASH environment variable)
#   -p, --http-port=<arg>               HTTP listening port (default is 8081)
#   -s, --http-stat-port=<arg>          HTTP statistics port
#   -d, --dir=<arg>                     server working directory
#   -t, --temp-dir=<arg>                directory for storing HTTP server temporary files
#       --filter=<arg>                  "<remainder>/<modulo>". Allow only bots with 'bot_user_id % modulo == remainder'
#       --max-webhook-connections=<arg> default value of the maximum webhook connections per bot
#       --http-ip-address=<arg>         local IP address, HTTP connections to which will be accepted. By default, connections to any local IPv4 address are accepted
#       --http-stat-ip-address=<arg>    local IP address, HTTP statistics connections to which will be accepted. By default, statistics connections to any local IPv4 address are accepted
#   -l, --log=<arg>                     path to the file where the log will be written
#   -v, --verbosity=<arg>               log verbosity level
#       --memory-verbosity=<arg>        memory log verbosity level; defaults to 3
#       --log-max-file-size=<arg>       maximum size of the log file in bytes before it will be auto-rotated (default is 2000000000)
#   -u, --username=<arg>                effective user name to switch to
#   -g, --groupname=<arg>               effective group name to switch to
#   -c, --max-connections=<arg>         maximum number of open file descriptors
#       --cpu-affinity=<arg>            CPU affinity as 64-bit mask (defaults to all available CPUs)
#       --main-thread-affinity=<arg>    CPU affinity of the main thread as 64-bit mask (defaults to the value of the option --cpu-affinity)
#       --proxy=<arg>                   HTTP proxy server for outgoing webhook requests in the format http://host:port

# following variables are defined in Dockerfile, should not change
USERNAME=${USERNAME:-telegram-bot-api}
GROUPNAME=${GROUPNAME:-telegram-bot-api}
TELEGRAM_WORK_DIR=${TELEGRAM_WORK_DIR:-/opt/telegram-bot-api}
TELEGRAM_TEMP_DIR=${TELEGRAM_TEMP_DIR:-/tmp/telegram-bot-api}

# customizable variables
HTTP_PORT=${HTTP_PORT:-8081}
STAT_PORT=${STAT_PORT:-8082}

DEFAULT_ARGS="--http-port=${HTTP_PORT} --http-stat-port=${STAT_PORT} --dir=${TELEGRAM_WORK_DIR} --temp-dir=${TELEGRAM_TEMP_DIR} --username=${USERNAME} --groupname=${GROUPNAME}"
CUSTOM_ARGS=""

if [ -n "$TELEGRAM_LOG_FILE" ]; then
    CUSTOM_ARGS=" --log=${TELEGRAM_LOG_FILE}"
fi
if [ -n "$TELEGRAM_FILTER" ]; then
    CUSTOM_ARGS="${CUSTOM_ARGS} --filter=$TELEGRAM_FILTER"
fi
if [ -n "$TELEGRAM_MAX_WEBHOOK_CONNECTIONS" ]; then
    CUSTOM_ARGS="${CUSTOM_ARGS} --max-webhook-connections=$TELEGRAM_MAX_WEBHOOK_CONNECTIONS"
fi
if [ -n "$TELEGRAM_VERBOSITY" ]; then
    CUSTOM_ARGS="${CUSTOM_ARGS} --verbosity=$TELEGRAM_VERBOSITY"
fi
if [ -n "$TELEGRAM_MAX_CONNECTIONS" ]; then
    CUSTOM_ARGS="${CUSTOM_ARGS} --max-connections=$TELEGRAM_MAX_CONNECTIONS"
fi
if [ -n "$TELEGRAM_PROXY" ]; then
    CUSTOM_ARGS="${CUSTOM_ARGS} --proxy=$TELEGRAM_PROXY"
fi
if [ -n "$TELEGRAM_LOCAL" ]; then
    CUSTOM_ARGS="${CUSTOM_ARGS} --local"
fi
if [ -n "$TELEGRAM_HTTP_IP_ADDRESS" ]; then
    CUSTOM_ARGS="${CUSTOM_ARGS} --http-ip-address=$TELEGRAM_HTTP_IP_ADDRESS"
fi

COMMAND="telegram-bot-api ${DEFAULT_ARGS}${CUSTOM_ARGS}"

echo "$COMMAND"
exec $COMMAND
