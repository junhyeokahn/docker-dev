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

ARG ZK_VERSION=v0.15.2

ENV HOME=${DEV_HOME} \
    USER=${DEV_USER} \
    WORKDIR=${WORKDIR} \
    XDG_CONFIG_HOME=${DEV_HOME}/.config \
    XDG_DATA_HOME=${DEV_HOME}/.local/share \
    XDG_STATE_HOME=${DEV_HOME}/.local/state \
    XDG_CACHE_HOME=${DEV_HOME}/.cache \
    CARGO_HOME=${DEV_HOME}/.cargo \
    PATH=${DEV_HOME}/.local/bin:${DEV_HOME}/.cargo/bin:/opt/nvim-linux-x86_64/bin:/opt/nvim-linux-arm64/bin:${PATH}

SHELL ["/bin/bash", "-lc"]

# Create user/group
RUN set -eux; \
    if ! getent group "${DEV_GID}" >/dev/null; then \
        groupadd -g "${DEV_GID}" "${DEV_USER}"; \
    fi; \
    if ! id -u "${DEV_USER}" >/dev/null 2>&1; then \
        useradd -m -d "${DEV_HOME}" -s /bin/bash -u "${DEV_UID}" -g "${DEV_GID}" "${DEV_USER}"; \
    fi; \
    mkdir -p "${DEV_HOME}" "${WORKDIR}"

# Base packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    unzip \
    xz-utils \
    ripgrep \
    fd-find \
    bat \
    fzf \
    build-essential \
    pkg-config \
    python3 \
    python3-pip \
    python3-venv \
    npm \
    locales \
    xclip \
    xauth \
    timg \
    clang \
    libclang-dev \
    && rm -rf /var/lib/apt/lists/*

# Compatibility symlinks for Ubuntu names
RUN ln -sf /usr/bin/fdfind /usr/local/bin/fd || true && \
    ln -sf /usr/bin/batcat /usr/local/bin/bat || true

# Install Neovim nightly
RUN set -eux; \
    arch="$(dpkg --print-architecture)"; \
    case "${arch}" in \
      amd64) nvim_arch="x86_64" ;; \
      arm64) nvim_arch="arm64" ;; \
      *) echo "Unsupported architecture: ${arch}" >&2; exit 1 ;; \
    esac; \
    curl -fL "https://github.com/neovim/neovim/releases/download/nightly/nvim-linux-${nvim_arch}.tar.gz" \
      -o /tmp/nvim-nightly.tar.gz; \
    rm -rf /opt/nvim-linux-${nvim_arch}; \
    tar -C /opt -xzf /tmp/nvim-nightly.tar.gz; \
    ln -sf "/opt/nvim-linux-${nvim_arch}/bin/nvim" /usr/local/bin/nvim; \
    rm -f /tmp/nvim-nightly.tar.gz

# Install zk
RUN set -eux; \
    arch="$(dpkg --print-architecture)"; \
    case "${arch}" in \
      amd64) zk_arch="amd64" ;; \
      arm64) zk_arch="arm64" ;; \
      *) echo "Unsupported architecture: ${arch}" >&2; exit 1 ;; \
    esac; \
    curl -fL "https://github.com/zk-org/zk/releases/download/${ZK_VERSION}/zk-${ZK_VERSION}-linux-${zk_arch}.tar.gz" \
      -o /tmp/zk.tar.gz; \
    tar -C /usr/local/bin -xzf /tmp/zk.tar.gz zk; \
    chmod +x /usr/local/bin/zk; \
    rm -f /tmp/zk.tar.gz

# Install rustup + tree-sitter CLI under the dev user's home
RUN curl https://sh.rustup.rs -sSf | su - "${DEV_USER}" -c "sh -s -- -y --no-modify-path" && \
    su - "${DEV_USER}" -c "source '${DEV_HOME}/.cargo/env' && cargo install tree-sitter-cli"

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

CMD ["sleep", "infinity"]
