
# Because Alpine Linux uses 'musl' instead of 'glibc', AWS CLI v2 bundled
# installer/binaries do not work on Alpine images. The 'libc6-compat'
# package allows running other libc binaries like 'hub' (GitHub CLI).
# But, unfortunately, this is not possible with AWS CLI v2.

# To be able to use AWS CLI v2 on Alpine, we must rely on source code and
# PyInstaller, which will generate a self-contained binary. This means we
# need to use a multi-stage Docker build to install AWS CLI v2 on Alpine.

ARG ALPINE_VERSION=3.13

# Build stage
FROM python:3-alpine${ALPINE_VERSION} AS installer

RUN apk add --no-cache \
    acl \
    binutils \
    curl \
    fcgi \
    file \
    g++ \
    gcc \
    gettext \
    git \
    libc-dev \
    libffi-dev \
    linux-headers \
    musl-dev \
    openssl-dev \
    pwgen \
    py3-pip \
    python3-dev \
    unzip \
    zlib-dev

ARG AWS_CLI_VERSION=2.1.30
ARG AWS_CLI_URL=https://github.com/aws/aws-cli.git
RUN git clone --recursive --depth 1 --branch ${AWS_CLI_VERSION} ${AWS_CLI_URL}

WORKDIR aws-cli

RUN pip install --upgrade pip \
    && pip install pycrypto \
    && git clone --depth 1 --branch v$(grep PyInstaller requirements-build.txt | cut -d'=' -f3) https://github.com/pyinstaller/pyinstaller.git /tmp/pyinstaller \
    && cd /tmp/pyinstaller/bootloader \
    && CFLAGS="-Wno-stringop-overflow -Wno-stringop-truncation" python ./waf configure --no-lsb all \
    && pip install .. \
    && rm -Rf /tmp/pyinstaller \
    && cd -

RUN scripts/installers/make-exe
RUN unzip dist/awscli-exe.zip && \
    ./aws/install --bin-dir /aws-cli-bin/

# Install stage
FROM alpine:${ALPINE_VERSION}

# Package dependencies
RUN apk add --update --no-cache groff openssh libc6-compat bash make

# AWS CLI v2
COPY --from=installer /usr/local/aws-cli/ /usr/local/aws-cli/
COPY --from=installer /aws-cli-bin/ /usr/local/bin/

# Git
# ARG GIT_VERSION=  Alpine only maintains latest version of packages
RUN apk add --update --no-cache git

# Hub - GitHub CLI∫
ARG HUB_VERSION=2.14.2
ARG HUB_URL=https://github.com/github/hub/releases/download/v${HUB_VERSION}/hub-linux-amd64-${HUB_VERSION}.tgz
RUN wget ${HUB_URL} -O hub.tgz && \
  tar zxvf hub.tgz hub-linux-amd64-${HUB_VERSION}/bin/hub --strip-components=2 && \
  rm -f hub.tgz && mv hub /usr/bin/ && \
  chmod +x /usr/bin/hub

# Docker CLI
ARG DOCKER_VERSION=20.10.2
ARG DOCKER_URL=https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_VERSION}.tgz
RUN wget ${DOCKER_URL} -O docker.tar.gz && \
  tar zxvf docker.tar.gz docker/docker --strip-components=1 && \
  rm -f docker.tar.gz && mv docker /usr/bin/ && \
  chmod +x /usr/bin/docker

# ECR Credential Helper
ARG ECR_HELPER_VERSION=0.5.0
ARG ECR_HELPER_URL=https://amazon-ecr-credential-helper-releases.s3.us-east-2.amazonaws.com/${ECR_HELPER_VERSION}/linux-amd64/docker-credential-ecr-login
RUN wget ${ECR_HELPER_URL} -O /usr/bin/docker-credential-ecr-login && \
  chmod +x /usr/bin/docker-credential-ecr-login

# Helm CLI
ARG HELM_VERSION=3.5.3
ARG HELM_URL=https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz
RUN wget ${HELM_URL} -O helm.tar.gz && \
  tar zxvf helm.tar.gz linux-amd64/helm --strip-components=1 && \
  rm -f helm.tar.gz && mv helm /usr/bin/ && \
  chmod +x /usr/bin/helm

# jx-release-version
ARG JX_RELEASE_VERSION=2.2.4
ARG JX_RELEASE_URL=https://github.com/jenkins-x-plugins/jx-release-version/releases/download/v${JX_RELEASE_VERSION}/jx-release-version-linux-amd64.tar.gz
RUN wget ${JX_RELEASE_URL} -O jx-release.tar.gz && \
  tar xzvf jx-release.tar.gz jx-release-version && \
  rm -f jx-release.tar.gz && mv jx-release-version /usr/bin/ && \
  chmod +x /usr/bin/jx-release-version

# git-secrets
ARG GIT_SECRETS_VERSION=1.3.0
ARG GIT_SECRETS_URL=https://github.com/awslabs/git-secrets.git
RUN git clone --recursive --depth 1 --branch ${GIT_SECRETS_VERSION} ${GIT_SECRETS_URL} && \
  cp git-secrets/git-secrets && /usr/local/bin && \
  chmod 755 /usr/local/bin/git-secrets && rm -rf git-secrets

# RUN wget https://releases.hashicorp.com/terraform/0.14.5/terraform_0.14.5_linux_amd64.zip && \
#     unzip terraform_0.14.5_linux_amd64.zip && mv terraform /usr/bin && \
#     apk add --update --no-cache bash openssh libc6-compat git && \
#     wget https://github.com/github/hub/releases/download/v2.14.2/hub-linux-amd64-2.14.2.tgz -O hub.tgz && \
#     mkdir /hub && tar -xvf hub.tgz -C /hub --strip-components 1 && alias git=hub && \
#     bash /hub/install && rm -rf /hub hub.tgz