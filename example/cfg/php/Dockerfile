ARG IMAGE
FROM m0bua/${IMAGE}

ARG UserName=${UserName}
ARG GroupName=${UserID}
ARG UserID=${GroupName}
ARG GroupID=${GroupID}

RUN apk update --no-cache; apk upgrade --no-cache; \
    addgroup -g ${GroupID} -S ${GroupName}; \
    adduser -u ${UserID} -G ${GroupName} -s /bin/bash -S ${UserName} ; \
    # yarn install; npm install --global gulp gulp-cli; deluser --remove-home node; \
  sed -i 's/\/bin\/sh/\/bin\/bash/' /etc/passwd; \
  sed -i 's/\/bin\/ash/\/bin\/bash/' /etc/passwd; \
  echo "${UserName} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

USER ${GroupID}
