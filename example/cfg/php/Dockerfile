ARG IMAGE
FROM m0bua/${IMAGE}

ARG UserName=${UserName}
ARG GroupName=${UserID}
ARG UserID=${GroupName}
ARG GroupID=${GroupID}
ARG DockerGID=${DockerGID}

RUN apk update --no-cache; apk upgrade --no-cache; \
    addgroup -g ${DockerGID} -S docker; \
    addgroup -g ${GroupID} -S ${GroupName}; \
    adduser -u ${UserID} -G ${GroupName} -G docker -s /bin/bash -S ${UserName} ; \
  sed -i 's/\/bin\/sh/\/bin\/bash/' /etc/passwd; \
  sed -i 's/\/bin\/ash/\/bin\/bash/' /etc/passwd; \
  echo "${UserName} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

USER ${GroupID}
