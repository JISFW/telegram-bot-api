FROM alpine:3.20 as build

ADD . /telegram-bot-api

WORKDIR /telegram-bot-api

RUN apk add -U alpine-sdk linux-headers git zlib-dev openssl-dev gperf cmake

RUN mkdir -p build \
    && cd build \
    && cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX:PATH=.. .. \
    && cmake --build . --target install -j 4 \
    && file /telegram-bot-api/bin/telegram-bot-api

FROM alpine:3.20

ENV TELEGRAM_WORK_DIR="/opt/telegram-bot-api" \
    TELEGRAM_TEMP_DIR="/tmp/telegram-bot-api"

RUN apk add -U bash openssl libstdc++ zlib
COPY --from=build /telegram-bot-api/bin/telegram-bot-api /usr/local/bin/telegram-bot-api
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN addgroup -g 1001 -S telegram-bot-api \
    && adduser -S -D -H -u 1001 -h ${TELEGRAM_WORK_DIR} -s /sbin/nologin -G telegram-bot-api -g telegram-bot-api telegram-bot-api \
    && chmod +x /docker-entrypoint.sh \
    && mkdir -p ${TELEGRAM_WORK_DIR} ${TELEGRAM_TEMP_DIR} \
    && chown telegram-bot-api:telegram-bot-api ${TELEGRAM_WORK_DIR} ${TELEGRAM_TEMP_DIR}

EXPOSE 8081/tcp 8082/tcp
ENTRYPOINT ["/docker-entrypoint.sh"]
