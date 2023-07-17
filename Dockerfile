FROM debian:11

RUN apt-get update && apt-get install jq curl -y

COPY . /usr/app
WORKDIR /usr/app

CMD ./api.sh
