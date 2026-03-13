# Personal Dev Container Overlay

This repository provides a reusable Docker-based Neovim development environment for project containers.

The idea is simple:

- start from a project base image
- layer Neovim and editor-related CLI tools on top
- mount your local Neovim config so you can iterate quickly
- persist Neovim data such as plugins, Mason packages, and Tree-sitter parsers across container restarts
- optionally mount your local zk notebook and X11 sockets for GUI support

This setup is meant for cases where I want:

- the editor to run **inside** the same container environment as the project
- language servers, CLI tools, and project dependencies to match the container
- Neovim plugins and tool installations to persist
- my local Neovim Lua config to remain the source of truth

---

## What this is

This is a Docker Compose template for a per-project dev container with:

- a root `Dockerfile` that acts as a Neovim overlay image
- a per-project `docker-compose.yml`
- persistent Neovim data mounted from the host
- host Neovim config mounted into the container
- an optional notebook mount for `zk`
- optional X11 and GPU support

Typical mounts:

- project source → `/workspace`
- Neovim data → `${DOCKER_HOME}/.local/share/nvim`
- Neovim config → `${DOCKER_HOME}/.config/nvim`
- notebook → `${DOCKER_HOME}/notebook`

---

## Why use this

### 1. Editor environment matches the container

Neovim runs inside the container, so:

- LSP servers see the same Python, CUDA, Go, system libraries, and project dependencies
- project-local binaries and tools resolve correctly
- debugging editor issues is easier because the environment is consistent

### 2. Plugins and tools persist

Neovim data is stored in a host-mounted directory, so I do not have to reinstall:

- plugins
- Mason packages
- Tree-sitter parsers
- other Neovim runtime data

every time the container is rebuilt or restarted.

### 3. Config stays easy to edit

My local `~/.config/nvim` is mounted into the container, so I can change my Lua config on the host and test it immediately in the container.

---

## How to use

### 1. Prepare the project files

For each project, create:

- `docker-compose.yml`
- `.env`

Example layout:

```text
.
├── Dockerfile
├── nvim-data
│   └── ubuntu2404-amd64
└── projects
    └── foo
        ├── docker-compose.yml
        └── .env
````

### 2. Fill in `.env`

Example:

```dotenv
BUILD_CONTEXT=../..
DOCKERFILE_PATH=Dockerfile
BASE_IMAGE=ubuntu:24.04
IMAGE_NAME=foo-nvim:local

DOCKER_HOME=/root
WORKDIR=/workspace

HOST_PROJECT_DIRECTORY=/absolute/path/to/projects/foo
HOST_NVIM_DATA_DIRECTORY=/absolute/path/to/nvim-data/ubuntu2404-amd64
HOST_NVIM_CONFIG_DIRECTORY=/home/yourname/.config/nvim
HOST_NOTEBOOK_DIRECTORY=/home/yourname/notebook
HOST_XAUTHORITY_FILE=/home/yourname/.Xauthority
```

### 3. Build and start the container

```bash
cd projects/foo
docker compose up -d --build
```

This builds the Neovim overlay image, starts the dev container, and keeps it running in the background.

### 4. Open a shell or Neovim in the container

```bash
docker compose exec dev bash
docker compose exec dev nvim
```

---

## Day-to-day workflow

Start the container:

```bash
cd projects/foo
docker compose up -d
```

Open Neovim:

```bash
docker compose exec dev nvim
```

Open a shell when needed:

```bash
docker compose exec dev bash
```

Rebuild after changing the Dockerfile or installed tools:

```bash
docker compose up -d --build
```

Stop the container when done:

```bash
docker compose down
```
