FROM mhart/alpine-node:latest
RUN mkdir -p /src && mkdir -p /opt && chmod -R 777 /opt
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
	apk --update add --no-cache --virtual .run_deps bash openssl && \
	npm config set user root
COPY install/config /src/config
COPY install/init_install.sh /src/init_install.sh
RUN bash /src/init_install.sh
COPY install/haraka_inst.sh /src/haraka_inst.sh
RUN bash /src/haraka_inst.sh
COPY install/wildduck_inst.sh /src/wildduck_inst.sh
RUN bash /src/wildduck_inst.sh
COPY install/zonemta_inst.sh /src/zonemta_inst.sh
RUN bash /src/zonemta_inst.sh
RUN apk del .install_deps

FROM mhart/alpine-node:slim
COPY --from=0 /opt /opt
COPY --from=0 /root /root
COPY --from=0 /etc/zone-mta /etc/zone-mta
COPY --from=0 /src /src
RUN apk --update add --no-cache --virtual .run_deps dumb-init monit bash openssl curl pwgen rspamd gettext
EXPOSE 8080/tcp 25/tcp 143/tcp 993/tcp 587/tcp 995/tcp 2812/tcp
WORKDIR /src
ENTRYPOINT ["/usr/bin/dumb-init", "--", "bash", "/src/run.sh"]
VOLUME ["/opt/zone-mta/keys/" "/etc/zone-mta/" "/etc/wildduck"]
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
	PATH=/opt/.npm-global/bin:$PATH \
	MMONIT_ENABLED=false\
	MMONIT_HOST=host.docker.internal \
	MMONIT_PORT=8080 \
	MMONIT_USER=admin \
	MMONIT_PASS=swordfish
COPY install/deploy.sh  install/haraka.sh install/run.sh install/wildduck.sh install/zonemta.sh install/rspamd.sh install/config.sh /src/


