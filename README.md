# Docker Dev Overlay

This repository provides a **reusable Docker-based development environment** that layers personal dev tools (Neovim, Claude Code, etc.) on top of arbitrary project images.

The goal is to run **personal dev tools inside the same container environment as the project**, while persisting their state across container restarts.

This avoids:

- reinstalling Neovim plugins / Mason binaries / Tree-sitter parsers
- re-authenticating Claude Code on every container start
- reinstalling Claude Code plugins
- recreating development tooling

while still letting the project control its own base image.

---

# Layout

- `ubuntu.Dockerfile` — layers personal dev tools (Neovim, Claude Code, zk) on top of a project-supplied base image (`BASE_IMAGE` build arg).
- `compose.base.yml` — shared Compose service template (build, XDG env, nvim/claude/notebook/X11/timezone mounts). Project compose files `extends:` this.
- `projects/<name>/docker-compose.yml` — per-project overlay: image/container name, GPU, networking, project-specific env, extra volumes.
- `projects/<name>/.env` — per-project config (paths, UID/GID, image name, secrets).
- `nvim-data/` — host-side persistent Neovim data (plugins, Mason binaries, Tree-sitter parsers).

---

# Features

- Neovim **nightly**
  - persistent plugin installations
  - persistent Mason binaries
  - persistent Tree-sitter parsers
  - host-mounted Neovim config
- Claude Code CLI
  - host-mounted `~/.claude/` and `~/.claude.json` (login, plugins, settings, sessions shared with host)
- `zk` notebook CLI with host-mounted notebook directory
- project code mounted inside container
- configurable runtime user
- works with arbitrary project base images

Note: Claude Code state is shared with the host. Avoid running Claude on the host and inside the container at the same time, or they will both write to the same `~/.claude/history.jsonl` and `sessions/`.

---

# Note

Matching the container UID/GID with the host user is recommended to avoid permission issues when writing to mounted directories.

You can find UID/GID in docker with:

```

docker run --rm gr00t-dev sh -c 'getent passwd | awk -F: '\''{printf "user=%s uid=%s gid=%s\n", $1, $3, $4}'\'''

````

# Usage

First, build your project's own base image (provided by the project, e.g. `gr00t-dev`) and reference it via `BASE_IMAGE` in the project's `.env`. This repo's `ubuntu.Dockerfile` layers the Neovim dev environment on top of that base.

From the project directory:

```
cd projects/gr00t
docker compose --env-file .env up -d --build
```

Enter the container:

```
docker exec -it gr00t-dev bash
```

Run Neovim:

```
nvim
```

Run Claude Code (login state and plugins are shared with the host):

```
claude
```

After developing, stop the container:

```
docker compose down
```

---

# Adding a new project

1. Create `projects/<name>/` with a `.env` (copy from `projects/gr00t/.env` and adjust `IMAGE_NAME`, `CONTAINER_NAME`, `BASE_IMAGE`, `WORKDIR`, host paths).
2. Create `projects/<name>/docker-compose.yml` that `extends` `../../compose.base.yml` service `dev`, and add only project-specific bits (GPU, network mode, extra env/volumes, `post_start`).
3. `cd projects/<name> && docker compose --env-file .env up -d --build`.
