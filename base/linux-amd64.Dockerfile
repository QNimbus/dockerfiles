ARG UPSTREAM_IMAGE
ARG UPSTREAM_DIGEST_AMD64

FROM alpine AS builder
ARG UNRAR_VER=7.0.9
ADD https://www.rarlab.com/rar/unrarsrc-${UNRAR_VER}.tar.gz /tmp/unrar.tar.gz
RUN apk --update --no-cache add build-base && \
    tar -xzf /tmp/unrar.tar.gz && \
    cd unrar && \
    sed -i 's|LDFLAGS=-pthread|LDFLAGS=-pthread -static|' makefile && \
    sed -i 's|CXXFLAGS=-march=native |CXXFLAGS=|' makefile && \
    make -f makefile && \
    install -Dm 755 unrar /usr/bin/unrar

FROM ${UPSTREAM_IMAGE}@${UPSTREAM_DIGEST_AMD64}

ARG UID=1000
ARG GID=1000
ARG IMAGE_STATS
ARG BUILD_ARCHITECTURE
ARG TZ=Etc/UTC
ENV IMAGE_STATS=${IMAGE_STATS} BUILD_ARCHITECTURE=${BUILD_ARCHITECTURE} \
    APP_DIR="/app" CONFIG_DIR="/config" PUID="${UID}" PGID="${GID}" UMASK="002" TZ="Europe/Amsterdam" \
    XDG_CONFIG_HOME="${CONFIG_DIR}/.config" XDG_CACHE_HOME="${CONFIG_DIR}/.cache" XDG_DATA_HOME="${CONFIG_DIR}/.local/share" \
    LANG="en_US.UTF-8" LANGUAGE="en_US:en" LC_ALL="en_US.UTF-8" \
    S6_BEHAVIOUR_IF_STAGE2_FAILS=2 S6_CMD_WAIT_FOR_SERVICES_MAXTIME=0 S6_SERVICES_GRACETIME=180000 S6_STAGE2_HOOK="/etc/s6-overlay/init-hook" \
    VPN_ENABLED="false" VPN_CONF="wg0" VPN_PROVIDER="generic" VPN_LAN_NETWORK="" VPN_LAN_LEAK_ENABLED="false" VPN_EXPOSE_PORTS_ON_LAN="" VPN_AUTO_PORT_FORWARD="true" VPN_AUTO_PORT_FORWARD_TO_PORTS="" VPN_KEEP_LOCAL_DNS="false" VPN_FIREWALL_TYPE="auto" VPN_HEALTHCHECK_ENABLED="false" PRIVOXY_ENABLED="false" UNBOUND_ENABLED="false" \
    VPN_PIA_USER="" VPN_PIA_PASS="" VPN_PIA_PREFERRED_REGION="" VPN_PIA_DIP_TOKEN="no" VPN_PIA_PORT_FORWARD_PERSIST="false"

VOLUME ["${CONFIG_DIR}"]

ENTRYPOINT ["/init"]

# install packages
RUN apk add --no-cache bash ca-certificates coreutils findutils grep jq python3 sed tzdata unzip curl wget && \
    apk add --no-cache --repository=https://dl-cdn.alpinelinux.org/alpine/edge/community figlet

COPY --from=builder /usr/bin/unrar /usr/bin/unrar

# https://github.com/just-containers/s6-overlay/releases
ARG VERSION_S6
RUN curl -fsSL "https://github.com/just-containers/s6-overlay/releases/download/v${VERSION_S6}/s6-overlay-noarch.tar.xz" | tar Jpxf - -C / && \
    curl -fsSL "https://github.com/just-containers/s6-overlay/releases/download/v${VERSION_S6}/s6-overlay-x86_64.tar.xz" | tar Jpxf - -C / && \
    curl -fsSL "https://github.com/just-containers/s6-overlay/releases/download/v${VERSION_S6}/s6-overlay-symlinks-noarch.tar.xz" | tar Jpxf - -C / && \
    curl -fsSL "https://github.com/just-containers/s6-overlay/releases/download/v${VERSION_S6}/s6-overlay-symlinks-arch.tar.xz" | tar Jpxf - -C /

# Make folders
RUN mkdir "${APP_DIR}" && \
    mkdir "${CONFIG_DIR}" && \
# Create group
    groupadd -g ${PGID} users && \
# Create user
    useradd -u ${PUID} -U -d "${CONFIG_DIR}" -s /bin/false qnimbus && \
    usermod -G users qnimbus

COPY root/ /
RUN chmod +x /etc/s6-overlay/init-hook
