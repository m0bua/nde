ARG IMAGE
FROM m0bua/${IMAGE}

ARG UserName=${UserName}
ARG GroupName=${UserID}
ARG UserID=${GroupName}
ARG GroupID=${GroupID}

RUN DISTRO="$(cat /etc/os-release | grep -E ^ID= | cut -d = -f 2)"; \
  if [ "${DISTRO}" = "debian" ] || [ "${DISTRO}" = "ubuntu" ]; then \
    DEBIAN_FRONTEND=noninteractive apt-get update -q -y; \
    DEBIAN_FRONTEND=noninteractive apt-get upgrade -q -y; \
    DEBIAN_FRONTEND=noninteractive apt-get install -qq -y sudo bash; \
    groupadd -g ${GroupID} -o ${GroupName}; \
    useradd -m -u ${UserID} -g ${GroupID} -o -s /bin/bash ${UserName}; \
  fi; \
  if [ "${DISTRO}" = "alpine" ]; then \
    packages="curl openssh git zip unzip zlib zlib-dev bash sudo npm"; \
    packages="${packages} automake make alpine-sdk nasm autoconf build-base shadow gcc musl-dev libtool pkgconf"; \
    packages="${packages} file tiff jpeg libpng libpng-dev libwebp libwebp-dev libjpeg-turbo libjpeg-turbo-dev"; \
    apk update --no-cache; apk upgrade --no-cache; apk add --no-cache ${packages}; rm /var/cache/apk/*; \
    yarn install; npm install --global gulp gulp-cli; deluser --remove-home node; \
    addgroup -g ${GroupID} -S ${GroupName}; \
    adduser -u ${UserID} -G ${GroupName} -s /bin/bash -S ${UserName} ; \
  fi; \
  sed -i 's/\/bin\/sh/\/bin\/bash/' /etc/passwd; \
  sed -i 's/\/bin\/ash/\/bin\/bash/' /etc/passwd; \
  echo "${UserName} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

USER ${GroupID}
