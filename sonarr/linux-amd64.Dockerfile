FROM alpine:3.20
LABEL "Maintainer"="Bas van Wetten <hi@bvw.email>"

ARG UID=1000
ARG GID=1000
ARG VERSION
ARG SBRANCH
ARG AMD64_URL
ARG PACKAGE_VERSION=${VERSION}

WORKDIR /usr/lib/sonarr

# Install dependencies
RUN apk add --no-cache \
    ca-certificates \
    curl

# Create sonarr user and group with specified UID and GID
RUN adduser -g "Sonarr" -u $UID -G users -H -D -h /config -s /bin/false sonarr && \
    # Change `users` GID to match the passed in $GID
    [ $(getent group users | cut -d: -f3) == $GID ] || \
            sed -i "s/users:x:[0-9]\+:/users:x:$GID:/" /etc/group

# Create config directory and set permissions
RUN mkdir /config && \
    chown -R sonarr:users /config

RUN mkdir "${APP_DIR}/bin" && \
    curl -fsSL "${AMD64_URL}" | tar xzf - -C "${APP_DIR}/bin" --strip-components=1 && \
    rm -rf "${APP_DIR}/bin/Sonarr.Update" && \
    echo -e "PackageVersion=${PACKAGE_VERSION}\nPackageAuthor=[QNimbus](https://github.com/QNimbus)\nUpdateMethod=Docker\nBranch=${SBRANCH}" > "${APP_DIR}/package_info" && \
    chmod -R u=rwX,go=rX "${APP_DIR}" && \
    chmod +x "${APP_DIR}/bin/Sonarr" "${APP_DIR}/bin/ffprobe"

# Download Sonarr: https://services.sonarr.tv/v1/download/main/latest?version=4&os=linux&arch=x64
# RUN curl -o /tmp/sonarr.tar.gz -L "https://services.sonarr.tv/v1/download/main/latest?version=4&os=linux&arch=x64" && \
#     tar -xzvf /tmp/sonarr.tar.gz -C /tmp && \
#     mv /tmp/Sonarr /usr/lib/sonarr && \
#     rm -rf /tmp/sonarr.tar.gz

# Cleanup
RUN rm -rf /var/cache/apk/*

# RUN apt-get update && \
#     apt-get install --no-install-recommends -qy ca-certificates gnupg software-properties-common && \
#     apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF && \
#     echo "deb https://download.mono-project.com/repo/ubuntu stable-focal main" | tee /etc/apt/sources.list.d/mono-official-stable.list && \
#     apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 2009837CBFFD68F45BC180471F4F90DE2A9B4BF8 && \
#     echo "deb https://apt.sonarr.tv/ubuntu focal main" | tee /etc/apt/sources.list.d/sonarr.list && \
# 	wget https://mediaarea.net/repo/deb/repo-mediaarea_1.0-19_all.deb && \
# 	dpkg -i repo-mediaarea_1.0-19_all.deb && \
# 	rm repo-mediaarea_1.0-19_all.deb && \
#     apt-get update && \
#     apt-get install -qy sonarr && \
#     sed -i "s/sonarr:x:[0-9]\+:/sonarr:x:$UID:/" /etc/passwd && \
#     # Change `users` GID to match the passed in $GID
#     [ $(getent group users | cut -d: -f3) == $GID ] || \
#             sed -i "s/users:x:[0-9]\+:/users:x:$GID:/" /etc/group && \
#     mkdir /config && \
#     chown -R sonarr:users /config && \
#     cert-sync /etc/ssl/certs/ca-certificates.crt && \
#     apt-get autoremove -qy gnupg software-properties-common wget && \
#     rm -rf /var/lib/apt/lists

EXPOSE 8989
# USER sonarr
VOLUME ["/config", "/data"]
