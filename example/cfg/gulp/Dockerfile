FROM node:alpine

ARG UserName=${UserName}
ARG GroupName=${UserID}
ARG UserID=${GroupName}
ARG GroupID=${GroupID}

RUN packages="curl openssh git zip unzip zlib zlib-dev bash sudo"; \
    packages="${packages} automake make alpine-sdk nasm autoconf build-base shadow gcc musl-dev libtool pkgconf"; \
    packages="${packages} file tiff jpeg libpng libpng-dev libwebp libwebp-dev libjpeg-turbo libjpeg-turbo-dev"; \
    apk update --no-cache; apk upgrade --no-cache; apk add --no-cache ${packages}; rm /var/cache/apk/*; \
    yarn install; npm install --global gulp gulp-cli; \
    deluser --remove-home node; \
    addgroup -g ${GroupID} -S ${GroupName}; \
    adduser -u ${UserID} -G ${GroupName} -s /bin/bash -S ${UserName} ; \
    sed -i 's/\/bin\/sh/\/bin\/bash/' /etc/passwd; \
    sed -i 's/\/bin\/ash/\/bin\/bash/' /etc/passwd; \
    echo "${UserName} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

USER ${GroupID}

CMD tail -f /dev/null
