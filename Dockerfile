ARG BASE_IMAGE=ubuntu:24.04
FROM ${BASE_IMAGE}

SHELL ["/bin/bash", "-o", "pipefail", "-lc"]

ENV DEBIAN_FRONTEND=noninteractive \
    TERM=xterm-256color \
    LOCAL_BIN_DIR=/root/.local/bin \
    CARGO_HOME=/root/.cargo \
    XDG_CONFIG_HOME=/root/.config \
    XDG_DATA_HOME=/root/.local/share \
    XDG_STATE_HOME=/root/.local/state \
    XDG_CACHE_HOME=/root/.cache \
    PATH=/root/.local/bin:/root/.cargo/bin:${PATH}

ARG TARGETARCH
ARG ZK_VERSION=v0.15.2

RUN mkdir -p \
      "${LOCAL_BIN_DIR}" \
      /workspace \
      "${XDG_CONFIG_HOME}/nvim" \
      "${XDG_DATA_HOME}/nvim" \
      "${XDG_STATE_HOME}/nvim" \
      "${XDG_CACHE_HOME}/nvim" \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      git \
      make \
      golang-go \
      ripgrep \
      fd-find \
      bat \
      build-essential \
      unzip \
      xz-utils \
    && rm -rf /var/lib/apt/lists/* \
    && if command -v fdfind >/dev/null 2>&1; then ln -sf "$(command -v fdfind)" "${LOCAL_BIN_DIR}/fd"; fi \
    && if command -v batcat >/dev/null 2>&1; then ln -sf "$(command -v batcat)" "${LOCAL_BIN_DIR}/bat"; fi

# rustup + tree-sitter
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
      | sh -s -- -y --profile minimal --default-toolchain stable \
    && cargo install --locked tree-sitter-cli

# fzf
RUN git clone --depth 1 https://github.com/junegunn/fzf.git /tmp/fzf \
    && /tmp/fzf/install --bin --no-update-rc \
    && install -m 0755 /tmp/fzf/bin/fzf "${LOCAL_BIN_DIR}/fzf" \
    && rm -rf /tmp/fzf

# latest Neovim
RUN case "${TARGETARCH}" in \
         amd64) NVIM_ARCH="x86_64" ;; \
         arm64) NVIM_ARCH="arm64" ;; \
         *) echo "Unsupported TARGETARCH: ${TARGETARCH}" >&2; exit 1 ;; \
    esac \
    && NVIM_TAG="$(basename "$(curl -fsSLI -o /dev/null -w '%{url_effective}' https://github.com/neovim/neovim/releases/latest)")" \
    && curl -fL "https://github.com/neovim/neovim/releases/download/${NVIM_TAG}/nvim-linux-${NVIM_ARCH}.tar.gz" \
      -o /tmp/nvim.tar.gz \
    && tar -C /tmp -xzf /tmp/nvim.tar.gz \
    && install -m 0755 "/tmp/nvim-linux-${NVIM_ARCH}/bin/nvim" "${LOCAL_BIN_DIR}/nvim" \
    && rm -rf /tmp/nvim.tar.gz "/tmp/nvim-linux-${NVIM_ARCH}"

# zk
RUN git clone --branch "${ZK_VERSION}" --depth 1 https://github.com/zk-org/zk.git /tmp/zk \
    && cd /tmp/zk \
    && make build \
    && install -m 0755 ./zk "${LOCAL_BIN_DIR}/zk" \
    && rm -rf /tmp/zk

WORKDIR /workspace
CMD ["sleep", "infinity"]
