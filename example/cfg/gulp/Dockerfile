FROM alpine

ARG UserName=${UserName}
ARG GroupName=${UserID}
ARG UserID=${GroupName}
ARG GroupID=${GroupID}

RUN packages="curl openssh git zip unzip bash sudo npm"; \
    apk update; apk upgrade; apk add ${packages}; rm /var/cache/apk/*; \
    npm install --global gulp gulp-cli; \
    addgroup -g ${GroupID} -S ${GroupName}; \
    adduser -u ${UserID} -G ${GroupName} -s /bin/bash -S ${UserName} ; \
    sed -i 's/\/bin\/sh/\/bin\/bash/' /etc/passwd; \
    sed -i 's/\/bin\/ash/\/bin\/bash/' /etc/passwd; \
    echo "${UserName} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

USER ${UserName}

CMD tail -f /dev/null
