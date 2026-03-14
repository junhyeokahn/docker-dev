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

# Note

Matching the container UID/GID with the host user is recommended to avoid permission issues when writing to mounted directories.

You can find UID/GID in docker with:

```

docker run --rm gr00t-dev sh -c 'getent passwd | awk -F: '\''{printf "user=%s uid=%s gid=%s\n", $1, $3, $4}'\'''

````

# Usage

Build the base image:

```
docker build -t gr00t-dev -f Dockerfile.base .
```

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

After developing, stop the container:

```
docker compose down
```
