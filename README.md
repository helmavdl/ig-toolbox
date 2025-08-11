# FHIR Implementation Guide Toolbox

A docker image to help with FHIR Implementation Guide authoring using [FHIR Shorthand (FSH)](https://hl7.org/fhir/uv/shorthand/).

It contains:

- [SUSHI](https://fshschool.org/docs/sushi/), a FSH compiler. SUSHI converts FSH language to FHIR artifacts
- [GoFSH](https://fshschool.org/docs/gofsh/), a converter that takes FHIR artifacts (e.g., profiles, extensions, value sets, instances) and produces equivalent FSH
- [FHIR IG Publisher prerequisites](https://confluence.hl7.org/display/FHIR/IG+Publisher+Documentation): Java, Git, Ruby, Jekyll
- Some terminal utilities:
  - [HAPI FHIR CLI](https://hapifhir.io/hapi-fhir/docs/tools/hapi_fhir_cli.html)
  - [Firely Terminal](https://docs.fire.ly/projects/Firely-Terminal/index.html)
  - [bonFHIR CLI](https://bonfhir.dev/packages/cli)
  - [jq](https://github.com/jqlang/jq)
- And [Oh My Bash](https://ohmybash.nntoan.com/) for a better shell experience

# 2025-08-06 forked version

This fork is based on this excellent idea but adds updates and extras:
- updates to all the components
- add nginx to make navigation in the IG easier
- add the official FHIR validator
- add helper scripts to make running the publisher and the validators easier
- use my own version of the docker image
- helper script to rebuild and start the container from a project directory
- allow for multiple projects in one workspace
- use helper scripts from the ig-toolbox/scripts inside the image

# Original README content

> To learn how to get started, head over to our tutorial at https://bonfhir.dev/docs/guides/ig-toolbox

## Usage

```shell
docker run -it --rm -v .:/workspaces ghcr.io/bonfhir/ig-toolbox
```

This will get you a shell where all the tools are available, and the current directory is volume-mounted.

To get started with a new sushi project, you can use [`sushi init`](https://fshschool.org/docs/sushi/project/#initializing-a-sushi-project); to use it directly from the docker image simply start with:

```shell
docker run -it --rm -v .:/workspaces ghcr.io/bonfhir/ig-toolbox sushi init
```

To use the [IG Puslisher](https://confluence.hl7.org/display/FHIR/IG+Publisher+Documentation), you'll need to execute the `./_updatePublisher.sh` script once after the project is generated.

## Usage with VS Code and dev containers

You can simply setup a [VS Code dev container setup](https://code.visualstudio.com/docs/devcontainers/containers) in the current directory by running:

```shell
docker run -it --rm -v .:/workspaces ghcr.io/bonfhir/ig-toolbox add-vscode-files
```

(Or simply run `add-vscode-files` if you are already in the container).

This will create 2 files:

1. `.devcontainer/devcontainer.json`:

```json
{
  "name": "FSH in VS Code",
  "image": "ghcr.io/bonfhir/ig-toolbox",
  "remoteUser": "root",
  "customizations": {
    "vscode": {
      "extensions": [
        "MITRE-Health.vscode-language-fsh",
        "jebbs.plantuml"
      ]
    }
  }
}
```

2. `.vscode/tasks.json` to define tasks tp launch SUSHI and the IG Publisher:

```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Run SUSHI",
      "type": "shell",
      "command": "sushi .",
      "group": {
        "kind": "build",
        "isDefault": true
      },
      "presentation": {
        "reveal": "always",
        "focus": false,
        "panel": "shared",
        "clear": false
      },
      "problemMatcher": []
    },
    {
      "label": "Run IG Publisher",
      "type": "shell",
      "command": "./_genonce.sh",
      "group": {
        "kind": "build"
      },
      "presentation": {
        "reveal": "always",
        "focus": false,
        "panel": "shared",
        "clear": false
      },
      "problemMatcher": []
    }
  ]
}
```

## Helper scripts

### Add profile

Use the `add-profile <profile-name>` script to create a new Profile FSH file, and its companion Markdown file in the `pagecontent` folder.

### Add FHIR resource diagram

Use the `add-fhir-resource-diagram <diagram-name>` to create a [PlantUML class diagram](https://plantuml.com/) that can be used to represent FHIR resources relationships.