FROM ghcr.io/foundry-rs/foundry:latest

WORKDIR /code

COPY www/. /code/

RUN forge build

ENTRYPOINT ["forge"]