ARG BASE_IMAGE=ubuntu:24.04
FROM ${BASE_IMAGE}

USER root

ARG DEBIAN_FRONTEND=noninteractive

# Runtime user config
ARG DEV_USER=dev
ARG DEV_UID=1000
ARG DEV_GID=1000
ARG DEV_HOME=/home/${DEV_USER}
ARG WORKDIR=/workspace

ARG DOTFILES_REF=main

ENV HOME=${DEV_HOME} \
    USER=${DEV_USER} \
    WORKDIR=${WORKDIR} \
    XDG_CONFIG_HOME=${DEV_HOME}/.config \
    XDG_DATA_HOME=${DEV_HOME}/.local/share \
    XDG_STATE_HOME=${DEV_HOME}/.local/state \
    XDG_CACHE_HOME=${DEV_HOME}/.cache \
    CARGO_HOME=${DEV_HOME}/.cargo \
    PATH=${DEV_HOME}/.local/bin:${DEV_HOME}/.cargo/bin:${PATH}

SHELL ["/bin/bash", "-lc"]

# Create user/group. If a user already exists at DEV_UID (e.g. the default
# "ubuntu" user on ubuntu:24.04), rename it to DEV_USER and move its home
# instead of creating a new account.
RUN set -eux; \
    existing_user="$(getent passwd "${DEV_UID}" | cut -d: -f1 || true)"; \
    if [ -n "${existing_user}" ] && [ "${existing_user}" != "${DEV_USER}" ]; then \
        existing_group="$(getent group "${DEV_GID}" | cut -d: -f1 || true)"; \
        if [ -n "${existing_group}" ] && [ "${existing_group}" != "${DEV_USER}" ]; then \
            groupmod -n "${DEV_USER}" "${existing_group}"; \
        fi; \
        usermod -l "${DEV_USER}" -d "${DEV_HOME}" -m -s /bin/bash "${existing_user}"; \
    elif ! id -u "${DEV_USER}" >/dev/null 2>&1; then \
        if ! getent group "${DEV_GID}" >/dev/null; then \
            groupadd -g "${DEV_GID}" "${DEV_USER}"; \
        fi; \
        useradd -m -d "${DEV_HOME}" -s /bin/bash -u "${DEV_UID}" -g "${DEV_GID}" "${DEV_USER}"; \
    fi; \
    mkdir -p "${DEV_HOME}" "${WORKDIR}"

# Grant passwordless sudo to dev user (needed by -bin.sh scripts)
RUN echo "${DEV_USER} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/90-${DEV_USER} \
    && chmod 0440 /etc/sudoers.d/90-${DEV_USER}

# Base packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    unzip \
    xz-utils \
    build-essential \
    pkg-config \
    python3 \
    python3-pip \
    python3-venv \
    locales \
    sudo \
    gnupg \
    && curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/*

# Create XDG dirs and workspace, then fix ownership
RUN mkdir -p \
    "${XDG_CONFIG_HOME}" \
    "${XDG_DATA_HOME}" \
    "${XDG_STATE_HOME}" \
    "${XDG_CACHE_HOME}" \
    "${DEV_HOME}/notebook" \
    "${WORKDIR}" && \
    chown -R "${DEV_UID}:${DEV_GID}" "${DEV_HOME}" "${WORKDIR}"

WORKDIR ${WORKDIR}
USER ${DEV_USER}

# Install nvim and zk binaries via dotfiles remote installers
RUN curl -fsSL "https://raw.githubusercontent.com/junhyeokahn/dotfiles/${DOTFILES_REF}/install/nvim-bin.sh" | bash \
 && curl -fsSL "https://raw.githubusercontent.com/junhyeokahn/dotfiles/${DOTFILES_REF}/install/zk-bin.sh"  | bash

CMD ["sleep", "infinity"]
