# FHIR Implementation Guide Toolbox

A docker image to help with FHIR Implementation Guide authoring using [FHIR Shorthand (FSH)](https://hl7.org/fhir/uv/shorthand/).

It contains:

- [SUSHI](https://fshschool.org/docs/sushi/), a FSH compiler. SUSHI converts FSH language to FHIR artifacts
- [GoFSH](https://fshschool.org/docs/gofsh/), a converter that takes FHIR artifacts (e.g., profiles, extensions, value sets, instances) and produces equivalent FSH
- [FHIR IG Publisher prerequisites](https://confluence.hl7.org/display/FHIR/IG+Publisher+Documentation): Java, Git, Ruby, Jekyll
- Some terminal utilities: [Firely Terminal](https://docs.fire.ly/projects/Firely-Terminal/index.html) and [bonFHIR CLI](https://bonfhir.dev/packages/cli)

> To learn how to author FHIR Implementation Guides using FSH, head over to the [FSH School](https://fshschool.org/).

## Usage

```shell
docker run -it --rm -v .:/workspace ghcr.io/bonfhir/ig-toolbox:latest
```

This will get you a shell where all the tools are available, and the current directory is volume-mounted.

To get started with a new sushi project, you can use [`sushi init`](https://fshschool.org/docs/sushi/project/#initializing-a-sushi-project); to use it directly from the docker image simply start with:

```shell
docker run -it --rm -v .:/workspace ghcr.io/bonfhir/ig-toolbox:latest sushi init
```

To use the [IG Puslisher](https://confluence.hl7.org/display/FHIR/IG+Publisher+Documentation), you'll need to execute the `./_updatePublisher.sh` script once after the project is generated.