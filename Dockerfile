FROM quay.io/mhart/alpine-node
RUN mkdir -p /src
ADD install /src
RUN apk add --update --no-cache bash pwgen git lsof python make openssl g++ gettext curl clamav
RUN npm config set unsafe-perm true
WORKDIR /src
ENV HOST localhost
ENV SECURE false
ENV WD_ACCESS_TOKEN wildduck
ENV WD_ACCTOK_REQ false
ENV HMAC_SECRET wildduck
ENV TLS_KEYPATH /dev/null
ENV TLS_CERTPATH /dev/null
ENV TLS_CAPATH /dev/null
ENV WD_RDNS_IDENT com.wildduck.example
ENV WD_DISP_NAME WildDuck
ENV WD_ORG com.wildduck
ENV MONGO_HOST host.docker.internal
ENV MONGO_PORT 27017
ENV REDIS_HOST host.docker.internal
ENV REDIS_PORT 6379
ENV STARTTLS false
ENV PLUGINS_ADDITIONAL ''
ENV PLUGINS_ADDITIONAL_INSTALL 'echo No Additional Plugin Install Required'
RUN freshclam
VOLUME ["/var/lib/clamav"]
RUN bash /src/install.sh
RUN set +e
RUN apk del pwgen lsof make g++ gettext
RUN rm -rf /var/cache/apk/*
ENTRYPOINT ["bash", "/src/run.sh"]
