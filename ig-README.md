# IG Toolbox: Dev Containers (Docker) + 1Password + Multi-Project NGINX

This setup lets you spin up and manage one or more **FHIR IG** dev containers that:

- mount your workspace into the container
- optionally inject **Firely** credentials from **1Password** at start time (no secrets on disk)
- serve **multiple IG projects** under `/workspaces/projects`
- expose NGINX at `http://localhost:<port>/<project>/index.html`
- provide a **single CLI** (`igctl`) for `start`, `enter`, `restart`, `stop`, etc.

---

## Requirements

- **Docker** (Desktop or Engine)  
- **Docker Compose v2** (`docker compose …`)  
- **Bash** (for the `igctl` script)  
- **1Password CLI (`op`)** – optional, only if you want secrets injected automatically
  - signed in (`eval "$(op signin)"`) before using the wrapper that resolves secrets
- An image named **`ig-toolbox:latest`** built from your Dockerfile (or pulled from your registry)

> macOS tip: Docker Desktop already includes Compose v2.  
> Linux tip: install `docker`, `docker compose`, and `lsof`.

---

## Directory Layout

Recommended repository structure (host side):

```
your-repo/
├─ docker-compose.yml                 # compose file using env vars for port & name
├─ igctl                              # single CLI to start/enter/stop/etc.
├─ .env                               # (optional) non-secret defaults (e.g., TZ)
├─ .env.op                            # 1Password secret refs (no cleartext)
├─ projects/                          # place IG projects here
│  ├─ project-a/
│  │  ├─ input/fsh/                   # used to detect “valid” projects
│  │  └─ output/index.html            # served at /project-a/index.html
│  └─ project-b/
│     ├─ input/fsh/
│     └─ output/index.html
└─ ig-toolbox/                        # optional; shared scripts & helpers
   └─ scripts/
      └─ (optional extra helper scripts)
```

Note: the ig-toolbox subdir might also be in a central location outside the repo.

Inside the **container** the relevant paths are:

- `/workspaces` (your repo root)
- `/workspaces/projects` (all IGs live here)
- NGINX is configured by the container’s `start-nginx-multi.sh` to serve:
  - `http://localhost:<port>/<project>/index.html` → `/workspaces/projects/<project>/output/index.html`
  - a generated root index at `http://localhost:<port>/`

---

## Files

### `docker-compose.yml`
Note: this is an indication, check the docker-compose.yml.template file for the most up-to-date version.

```yaml
services:
  ig-toolbox:
    image: ig-toolbox:latest
    container_name: ${CONTAINER_NAME}
    working_dir: /workspaces
    volumes:
      - .:/workspaces
      - ./projects:/workspaces/projects
    environment:
      FIRELY_USERNAME: ${FIRELY_USERNAME}
      FIRELY_PASSWORD: ${FIRELY_PASSWORD}
      TZ: ${TZ:-Europe/Amsterdam}
    ports:
      - "${PORT_BIND}:80"
    stdin_open: true
    tty: true
```
Copy the `docker-compose.yml.template` to `/path/to/your-repo/docker-compose.yml`

### `.env` (optional, non-secret)

```dotenv
# Non-secrets (optional)
TZ=Europe/Amsterdam

# You can also set defaults:
# PORT_BIND=8080
# CONTAINER_NAME=ig-toolbox-8080
```

### `.env.op` (1Password secret references)

```dotenv
FIRELY_USERNAME=op://<vault>/<item>/email
FIRELY_PASSWORD=op://<vault>/<item>/password
```

> The `.env.op` file holds **only** `op://…` references, not actual secrets.

### `igctl` (the single CLI modeled after Lando)

Start a new container in the directory 
```bash
cd path/to/your-repo
./igctl start
```

or, in case you want to use the script from a central location

```bash
cd path/to/your-repo
../central-location/igctl start
```
If `op` is present and `.env.op` exists, `igctl start` runs:
```
op run --env-file .env.op -- docker compose up -d
```
Otherwise it falls back to `docker compose up -d` (provide `FIRELY_*` via `.env` or shell).


It is also possible to put the script in your PATH and run it from a single location.

### Commands
```
igctl start [PORT] [NAME]   Start new container (saves NAME/PORT per directory in .igctl)
igctl enter|bash [NAME]     Exec into running container (defaults to saved/first)
igctl restart [NAME]        Start a stopped container (defaults to saved/first)
igctl stop [NAME]           Stop running container (defaults to saved/first)
igctl list                  List all ig-toolbox containers
igctl logs [NAME]           Follow logs (defaults to saved/first)
igctl url                   Show http://localhost:<port>/ for saved/first running
igctl rebuild               Destroy the container and start a new one
```

## Environment Variables
- `IMAGE_NAME` (default: `ig-toolbox:latest`)
- `PORT_RANGE` (default: `8080..8099`)
- `ENV_OP_FILE` (default: `.env.op`)
- `COMPOSE_FILE` (default: `docker-compose.yml`)
- `STATE_FILE` (default: `.igctl`)

Override per invocation, e.g.:
```bash
PORT_RANGE="9000..9050" ./igctl start
```

## Typical Workflow

1) Start a container (let it pick a free port and name):
```bash
./igctl start
# prints: http://localhost:808x/
```

2) Enter the container:
```bash
./igctl enter
```

3) Put or symlink your IG projects into `projects/`:
```
projects/my-ig/
├─ input/fsh/
└─ output/index.html
```

4) Open your browser:
```
http://localhost:808x/                 # auto-generated index
http://localhost:808x/my-ig/index.html
```

5) Stop later:
```bash
./igctl stop ig-toolbox-808x
```

---

## Multi-Project Serving (NGINX)

The container’s `start-nginx-multi.sh` (baked into your image) does:

- Creates **one** server block on port 80.
- Adds `location /<project>/ { alias /workspaces/projects/<project>/output/; … }`
- Builds `/workspaces/index.html` listing projects that have **both**:
  - `/workspaces/projects/<project>/input/fsh/`
  - `/workspaces/projects/<project>/output/index.html`

So only “valid” IGs show up.

---

## Credentials (Firely) via 1Password

- Put item references in `.env.op` (no secrets on disk):
  ```
  FIRELY_USERNAME=op://<vault>/<item>/username
  FIRELY_PASSWORD=op://<vault>/<item>/password
  ```
- Sign into 1Password once in your shell:
  ```bash
  eval "$(op signin)"
  ```
- `./igctl start` will run Compose via:
  ```bash
  op run --env-file .env.op -- docker compose up -d
  ```
- Inside the container, your `.bashrc` (or startup hook) can auto-login:
  ```bash
  if [[ -n "$FIRELY_USERNAME" && -n "$FIRELY_PASSWORD" ]]; then
    fhir login --username "$FIRELY_USERNAME" --password "$FIRELY_PASSWORD" && unset FIRELY_USERNAME FIRELY_PASSWORD
  fi
  ```

---

## Customization

- **Port range**: `PORT_RANGE="9000..9050" ./igctl start`
- **Image**: `IMAGE_NAME=myrepo/ig-toolbox:tag ./igctl start`
- **Project mount**: `MOUNT_PROJECT=/path/to/root ./igctl start`
- **Timezone**: set `TZ` in `.env` or your environment.
- **Scripts**: mount extra helpers into the repo (`ig-toolbox/scripts`) and call them from inside the container; or bake them into the image.

---

## Troubleshooting

- **Port already in use”**: pick a port (`./igctl start 8087`) or adjust `PORT_RANGE`.
- **No 1Password**: just set `FIRELY_*` in your shell or `.env` and run `./igctl start`.
- **Container removed on exit**: this setup uses **detached** containers (no `--rm`) so they persist; use `enter` to hop back in.
- **Compose file not found**: ensure you’re running in a directory that contains `docker-compose.yml` or set `COMPOSE_FILE`.
- **Duplicate workspace prompts in VS Code**: open the folder, not the `.code-workspace` inside the mounted path; or place the `.code-workspace` outside the mounted root.
