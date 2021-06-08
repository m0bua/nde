ARG IMAGE
FROM m0bua/${IMAGE}

ARG UserName=user
ARG GroupName=group
ARG UserID=1000
ARG GroupID=${UserID}

RUN DISTRO="$(cat /etc/os-release | grep -E ^ID= | cut -d = -f 2)"; \
  if [ "${DISTRO}" = "ubuntu" ]; then \
    DEBIAN_FRONTEND=noninteractive apt-get update -q -y; \
    DEBIAN_FRONTEND=noninteractive apt-get upgrade -q -y; \
    DEBIAN_FRONTEND=noninteractive apt-get install -qq -y sudo; \
    groupadd -g ${GroupID} -o ${UserName}; \
    useradd -m -u ${UserID} -g ${GroupID} -o -s /bin/bash ${UserName}; \
  fi; \
  if [ "${DISTRO}" = "alpine" ]; then \
    apk update; apk upgrade; apk add sudo; rm /var/cache/apk/*; \
    addgroup -g ${GroupID} -S ${GroupName}; \
    adduser -u ${UserID} -G ${GroupName} -s /bin/bash -S ${UserName} ; \
  fi; \
  sed -i 's/\/bin\/sh/\/bin\/bash/' /etc/passwd; \
  sed -i 's/\/bin\/ash/\/bin\/bash/' /etc/passwd; \
  echo "${UserName} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

USER ${UserName}