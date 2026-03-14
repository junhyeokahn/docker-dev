# Docker Dev Overlay

This repository provides a **reusable Docker-based Neovim development environment** that can be layered on top of arbitrary project images.

The goal is to run **Neovim inside the same container environment as the project**, while persisting editor tooling across container restarts.

This avoids:

- reinstalling plugins
- reinstalling Mason binaries
- rebuilding Tree-sitter parsers
- recreating development tooling

while still letting the project control its own base image.

---

# Features

- Neovim **nightly**
- persistent plugin installations
- persistent Mason binaries
- persistent Tree-sitter parsers
- host-mounted Neovim config
- project code mounted inside container
- configurable runtime user
- works with arbitrary project base images

---

# Repository Layout

```

docker-dev/
├── Dockerfile
├── projects/
│   └── foo/
│       ├── docker-compose.yml
│       └── .env
└── nvim-data/
    └── foo/

```

---

# Example Configuration

## `.env`

```

BASE_IMAGE=foo-base:local

IMAGE_NAME=foo-dev:local
CONTAINER_NAME=foo-dev

DEV_USER=dev
DEV_UID=1000
DEV_GID=1000
DOCKER_HOME=/home/dev

WORKDIR=/workspace

HOST_PROJECT_DIRECTORY=/absolute/path/to/foo
HOST_NVIM_CONFIG_DIRECTORY=/absolute/path/to/nvim
HOST_NVIM_DATA_DIRECTORY=/absolute/path/to/docker-dev/nvim-data/foo
HOST_NOTEBOOK_DIRECTORY=/absolute/path/to/notebook

```

Matching the container UID/GID with the host user is recommended to avoid permission issues when writing to mounted directories.

You can find your host UID/GID with:

```

id -u
id -g

````

---

# Docker Compose

Example `projects/foo/docker-compose.yml`:

```yaml
services:
  foo-dev:
    build:
      context: ../..
      dockerfile: Dockerfile
      args:
        BASE_IMAGE: ${BASE_IMAGE}
        DEV_USER: ${DEV_USER}
        DEV_UID: ${DEV_UID}
        DEV_GID: ${DEV_GID}
        DEV_HOME: ${DOCKER_HOME}
        WORKDIR: ${WORKDIR}

    image: ${IMAGE_NAME}
    container_name: ${CONTAINER_NAME}
    working_dir: ${WORKDIR}

    stdin_open: true
    tty: true

    volumes:
      - ${HOST_PROJECT_DIRECTORY}:${WORKDIR}
      - ${HOST_NVIM_CONFIG_DIRECTORY}:${DOCKER_HOME}/.config/nvim
      - ${HOST_NVIM_DATA_DIRECTORY}:${DOCKER_HOME}/.local/share/nvim

    command: sleep infinity
````

---

# Usage

From the project directory:

```
cd projects/foo
docker compose --env-file .env up -d --build
```

Enter the container:

```
docker exec -it foo-dev bash
```

Run Neovim:

```
nvim
```

---

# Workflow

Typical workflow:

1. Build the project base image

```
docker build -t foo-base:local /path/to/project
```

2. Start the dev container

```
docker compose up -d --build
```

3. Enter container

```
docker exec -it foo-dev bash
```

4. Run Neovim

```
nvim
```

Plugins, Mason binaries, and Tree-sitter parsers will persist between container restarts.
