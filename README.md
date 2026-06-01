# FHIR Implementation Guide Toolbox

A Docker-based toolbox for authoring FHIR Implementation Guides with
[FHIR Shorthand (FSH)](https://hl7.org/fhir/uv/shorthand/). Everything you need
to write FSH, run SUSHI/GoFSH, validate, and publish an IG lives inside the
container — you don't install Java, Node, Ruby, etc. on your Mac.

> This is a fork of [bonfhir/ig-toolbox](https://github.com/bonfhir/ig-toolbox)
> with updates and extras (nginx for browsing the IG, the official FHIR
> validator, helper scripts, multi-project workspaces, deploy helpers).

What's in the container:

- [SUSHI](https://fshschool.org/docs/sushi/) — the FSH compiler
- [GoFSH](https://fshschool.org/docs/gofsh/) — convert FHIR → FSH
- FHIR IG Publisher + prerequisites (Java, Git, Ruby, Jekyll)
- [HAPI FHIR CLI](https://hapifhir.io/hapi-fhir/docs/tools/hapi_fhir_cli.html),
  [Firely Terminal](https://docs.fire.ly/projects/Firely-Terminal/index.html),
  [bonFHIR CLI](https://bonfhir.dev/packages/cli), `jq`
- The official FHIR validator
- nginx, so you can browse the rendered IG in your browser
- Oh My Bash for a nicer shell

---

## How this is organised

This repo is a **generic toolbox** — it builds the Docker image and provides
the `igctl` launcher and shared `toolbox-scripts/`. Your actual IG projects
live in a **separate workspace directory** of your choosing, with its own
`docker-compose.yml` and `.env` files. That keeps the toolbox reusable across
multiple unrelated FSH workspaces.

Note: in the example below the ig-toolbox is installed in `~/dev/ig-toolbox` with the projects in `~/FHS/projects`. This is simply a way of organizing the ig-toolbox. There is no compelling reason to install it in `~/dev/` any other directory is fine.

```
~/dev/ig-toolbox/            ← this repo (builds image, provides igctl)
│   ├── Makefile
│   ├── igctl
│   └── toolbox-scripts/

~/FSH/                       ← your workspace (you create this)
    ├── docker-compose.yml   ← copied from ig-toolbox/docker-compose.yml.template
    ├── .env                 ← copied from ig-toolbox/env.example
    ├── .env.op              ← optional, only if you use 1Password
    └── projects/
        └── my-first-ig/
            ├── sushi-config.yaml
            └── ...
```

You run `igctl` **from the workspace directory**, pointing at the toolbox:
```bash
cd ~/FSH
~/dev/ig-toolbox/igctl start
```

---

## Getting started on a Mac

### 1. Install the prerequisites (one-time)

You need three things on your Mac. Everything else runs inside Docker.

1. **Docker Desktop** — download from
   <https://www.docker.com/products/docker-desktop/> and install it. Open it
   once so it finishes setting up; you should see the whale icon in the menu
   bar. Give it enough RAM (Settings → Resources → at least 8 GB, ideally 12+).
2. **Xcode Command Line Tools** (gives you `git` and `make`). In Terminal:
   ```bash
   xcode-select --install
   ```
   Click through the installer dialog.
3. A Terminal app. The built-in **Terminal** (in Applications → Utilities) is
   fine.

Verify:
```bash
docker --version
git --version
make --version
```

### 2. Clone this toolbox repo

```bash
mkdir -p ~/dev && cd ~/dev
git clone <REPO-URL> ig-toolbox
cd ig-toolbox
```

### 3. Build the Docker image (one-time, ~15–30 min)

```bash
make build
make alias
```

- `make build` builds the image for your Mac (Intel or Apple Silicon, whichever
  you have). The first build downloads a lot — go grab coffee.
- `make alias` tags the freshly-built image as `ig-toolbox:local` so the
  workspace `docker-compose.yml` can find it.

Optional: `make test` runs a smoke test that all the tools inside the image
actually work.

You don't normally need to rebuild this image until you want a tool upgrade.

### 4. Create your workspace directory

Pick a location for your IG work — it does NOT need to be inside the toolbox
repo. In fact, it is preferable to keep the toolbox and your projects separate.

Create or use a project directory for the projects in which the actual work takes place.
In the example below `~/FSH` is used as generic toplevel directory with the actual projects inside `projects`. The rationale is that you don't want the docker-related files clutter your actual projects.

If you prefer a different setup, just adjust the paths.

```bash
mkdir -p ~/FSH/projects
cd ~/FSH

# Copy the workspace templates from the toolbox repo
cp ~/dev/ig-toolbox/docker-compose.yml.template ./docker-compose.yml
cp ~/dev/ig-toolbox/env.example                  ./.env
# Optional, only if you use 1Password:
cp ~/dev/ig-toolbox/env.op.example               ./.env.op
```

Open `./docker-compose.yml` and `./.env` in a text editor and adjust as needed
(timezone, default port, etc.).

Drop your IG project(s) under `./projects/`, e.g.:
```
~/FSH/projects/my-first-ig/
    sushi-config.yaml
    input/
    ...
```
(If you're starting from scratch, you can `sushi init` from inside the
container — see step 6.)

#### How the workspace maps into the container

The workspace `docker-compose.yml` mounts the **entire workspace directory**
(the directory `igctl` is run from) at `/workspaces` inside the container:

```yaml
volumes:
  - .:/workspaces                                 # your workspace → /workspaces
  - ${TOOLBOX_SCRIPTS}:/workspaces/scripts:ro     # toolbox scripts (read-only)
  - ./output:/host_output                         # persistent output for copy-back
```

So inside the container you'll find:

| Inside container       | What it is                                          |
|------------------------|-----------------------------------------------------|
| `/workspaces/projects` | Your IG projects (`~/FSH/projects` on the host)     |
| `/workspaces/scripts`  | Read-only helper scripts from the toolbox repo      |
| `/workspaces/output`   | Scratch space (tmpfs, RAM-backed — wiped on stop)   |
| `/workspaces/temp`     | Scratch space (tmpfs, RAM-backed — wiped on stop)   |
| `/host_output`         | A real directory on the host (`~/FSH/output`) for results you want to keep |

That means any folder you keep under your workspace dir (e.g. `~/FSH/scripts`,
`~/FSH/Makefile`) is also visible at `/workspaces/...` — handy for project-wide
helpers shared across IGs.

If you want a different layout (e.g. only mount `./projects` instead of the
whole workspace, or skip the deploy/SSH bits), edit your workspace
`docker-compose.yml` — the template is a starting point, not a contract.

### 5. Start the container

From inside your workspace directory:

```bash
cd ~/FSH
~/dev/ig-toolbox/igctl start
```

Tip: add an alias to your `~/.zshrc` so you can just type `igctl`:
```bash
echo 'alias igctl="$HOME/dev/ig-toolbox/igctl"' >> ~/.zshrc
source ~/.zshrc
```

`igctl start` picks a free port (in the `8080–8099` range), starts the
container, and drops you into a bash shell inside it. You'll see something
like `Starting container 'ig-toolbox-8080' on http://localhost:8080/`. That
URL serves the IG (via nginx) once you've built it.

Other handy commands (run from the workspace directory):

| Command         | What it does                                       |
|-----------------|----------------------------------------------------|
| `igctl enter`   | Open another shell into the running container      |
| `igctl stop`    | Stop the container                                 |
| `igctl restart` | Stop and start again                               |
| `igctl list`    | Show all toolbox containers                        |
| `igctl logs`    | Tail the container logs                            |
| `igctl url`     | Print the `http://localhost:PORT/` URL             |
| `igctl rebuild` | Tear down and recreate the container               |

NOTE: you only use `igctl start` once to build the container. On every subsequent start use `igctl restart`

### 6. Work on your IG

Inside the container shell, your IG projects live under `/workspaces/projects`:

```bash
cd /workspaces/projects/my-first-ig
sushi .                  # compile FSH → FHIR
./_genonce.sh            # run the IG Publisher
```

Then open <http://localhost:8080/> (or whatever port `igctl start` reported)
in your browser to view the rendered IG.

To leave the container shell, type `exit`. The container keeps running until
you `igctl stop`.

---

## Optional configuration

### Environment variables

Edit `.env` in your workspace directory to change the timezone, default port,
or container name. See [`env.example`](env.example) for the available knobs.

### Firely Terminal login

If you have a Firely account, set `FIRELY_USERNAME` / `FIRELY_PASSWORD` in
your workspace `.env` (or in your shell) and `igctl start` will log you in
automatically inside the container.

### 1Password integration (advanced — skip if you don't use 1Password)

If you use the 1Password CLI (`op`), copy
[`env.op.example`](env.op.example) into your workspace as `.env.op` and fill
in your vault references. `igctl start` will detect `op` and inject secrets at
runtime — they never touch disk.

---

## Helper scripts (inside the container)

- `add-profile <name>` — scaffold a new FSH profile + matching `pagecontent/`
  markdown file.
- `add-fhir-resource-diagram <name>` — create a
  [PlantUML](https://plantuml.com/) class diagram for FHIR resources.
- `add-vscode-files` — drop a `.devcontainer/` + `.vscode/tasks.json` into the
  current project for VS Code dev container use.

Custom validators and publish helpers live in
[`toolbox-scripts/`](toolbox-scripts/); they are mounted read-only into the
container at `/workspaces/scripts`.

---

## Maintaining the toolbox image

From the toolbox repo directory:
```bash
make clean-old           # keep the 5 newest images, remove the rest
N=7 make clean-old       # keep 7 instead
DRY_RUN=1 make clean-old # preview without deleting
make purge               # nuke all ig-toolbox images and dangling layers
```

To upgrade tool versions, edit [`.env`](.env) in the toolbox repo (bumps the
build args), then `make build && make alias` again.

See [docs/USAGE.md](docs/USAGE.md) for build-related notes, and
[docs/ig-README.md](docs/ig-README.md) for the original upstream README.

---

## Troubleshooting

- **`docker: command not found`** — Docker Desktop isn't running, or wasn't
  installed. Open it from Applications.
- **`make: command not found`** — Run `xcode-select --install`.
- **Port already in use** — pass a specific port: `igctl start 8090`.
- **`Image not found ig-toolbox:local`** — you skipped `make alias` after
  `make build`. Run it now from the toolbox repo.
- **`Compose file not found: docker-compose.yml`** — you ran `igctl` from
  somewhere other than your workspace directory. `cd ~/FSH` first.
- **Build is super slow / runs out of memory** — give Docker Desktop more RAM
  in Settings → Resources.

## License

See [LICENSE](LICENSE).
