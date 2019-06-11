FROM quay.io/mhart/alpine-node
RUN mkdir -p /src && mkdir -p /opt && chmod -R 777 /opt
ADD install /src
WORKDIR /src
USER root
ENV HOST=localhost \
	SECURE=false \
	WD_ACCESS_TOKEN=wildduck \
	WD_ACCTOK_REQ=false \
	HMAC_SECRET=wildduck \
	TLS_KEYPATH=/dev/null \
	TLS_CERTPATH=/dev/null \
	TLS_CAPATH=/dev/null \
	WD_RDNS_IDENT=com.wildduck.example \
	WD_DISP_NAME=WildDuck \
	WD_ORG=com.wildduck \
	MONGO_HOST=host.docker.internal \
	MONGO_PORT=27017 \
	REDIS_HOST=host.docker.internal \
	REDIS_PORT=6379 \
	STARTTLS=false \
	PLUGINS_ADDITIONAL='' \
	PLUGINS_ADDITIONAL_INSTALL='echo No Additional Plugin Install Required' \
	NPM_CONFIG_PREFIX=/opt/.npm-global \
	PATH=/opt/.npm-global/bin:$PATH
RUN apk --update add --no-cache --virtual .install_deps python pwgen lsof make g++ git gettext && \
	apk --update add --no-cache --virtual .run_deps dubm-init bash openssl curl clamav && \
	npm config set user root && \
	bash /src/install.sh && \
	apk del .install_deps
VOLUME ["/var/lib/clamav"]
EXPOSE 8080/tcp 25/tcp 143/tcp 993/tcp 587/tcp 995/tcp
ENTRYPOINT ["/usr/bin/dumb-init", "--", "bash", "/src/run.sh"]

