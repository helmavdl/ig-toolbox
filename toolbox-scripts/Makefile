# Makefile for FHIR build process

# Helps in documenting which scripts to run when

# Absolute directory of this Makefile
MAKEFILE_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

# Location of scripts directory
SCRIPTS := $(MAKEFILE_DIR)

# Variables
FHIR := fhir
DOTNET_TOOLS := $(HOME)/.dotnet/tools

# Detect whether this is a FSH/SUSHI environment
SUSHI_CONFIG := $(wildcard sushi-config.yaml)

# Only try to extract info if sushi-config.yaml exists
ifeq ($(SUSHI_CONFIG),)
 	# No sushi-config
	VERSION :=
	PACKAGE_NAME :=
else
	# Fetch version from sushi-config.yaml with error handling
	VERSION := $(shell grep '^version:' sushi-config.yaml | sed 's/version: //' | tr -d '[:space:]')
	ifeq ($(VERSION),)
	     $(error Could not extract version from sushi-config.yaml)
	endif
	
	# Fetch package name from sushi-config.yaml with error handling
	PACKAGE_NAME := $(shell grep '^id:' sushi-config.yaml | sed 's/id: //' | tr -d '[:space:]')
	ifeq ($(PACKAGE_NAME),)
		$(error "Could not extract package id from sushi-config.yaml")
	endif
endif

export VERSION
export PACKAGE_NAME

# Export PATH with dotnet tools
export PATH := $(PATH):$(DOTNET_TOOLS)


# Make 'help' the default target
.DEFAULT_GOAL := help

# -------------------------------------------------------------------
# Auto-generated help 
# -------------------------------------------------------------------
### General
.PHONY: help
help: ## Show this help message
	@python3 "$(SCRIPTS)/make-help.py" "$(MAKEFILE_DIR)/Makefile"

### FHIR tools
.PHONY: init 
init: login install-helper-scripts install-dependencies set-txoption

.PHONY: build
build: install-dependencies build-ig ## Build IG (with dependencies install)

.PHONY: build-minimal 
build-minimal: install-dependencies build-ig-minimal ## Build minimal package (without narratives)

.PHONY: login 
login: ## Login to Simplifier
	@$(FHIR) login email=$(FIRELY_USERNAME) password=$(FIRELY_PASSWORDD)

.PHONY: set-txoption 
set-txoption: ## Run the mitmproxy for NTS
	@echo "Setting the tx option"
	@$(SCRIPTS)/set-tx-server.sh
	
package.json: ## Build package.json from sushi-config
ifeq ($(SUSHI_CONFIG),)
	@echo "Sushiconfig: " $(SUSHI_CONFIG)
	@echo $(error no package.json found)
else
	@yq -r -f $(SCRIPTS)/sushi2pkg.yq sushi-config.yaml > package.json
endif

fhirpkg.lock.json: package.json ## Restore packages and create fhirpkg.lock.json
	fhir restore


### Validators
fvnext: ## Set Firely Terminal to Advanced validator (vnext)
	fhir config Validator Advanced


fvold: ## Set Firely Terminal to Regular validator (the old one)
	fhir config Validator Regular


### Helpers
.PHONY: install-dependencies 
install-dependencies: package.json ## Install dependencies
	@$(SCRIPTS)/install-fhir-dependencies.sh


.PHONY: install-helper-scripts
install-helper-scripts: ## Symlink helper scripts in /usr/local/bin
	@ln -fs $(SCRIPTS)/fval.sh /usr/local/bin/fval
	@ln -fs $(SCRIPTS)/ival.sh /usr/local/bin/ival
	@ln -fs $(SCRIPTS)/vval.sh /usr/local/bin/vval


.PHONY: inflate-nictiz
inflate-nictiz: ## inflate Nictiz packages so they will contain snapshots
	@$(SCRIPTS)/inflate_nictiz-packages.sh

### Building
.PHONY: build-local 
build-local: fhirpkg.lock.json package.json ## Build a local version of a package and add to fhir cache
	@$(SCRIPTS)/build-local.sh

.PHONY: build-ig
build-ig: ## Build Implementation Guide (Full with documentation)
	@echo "Building Full Implementation Guide of $(PACKAGE_NAME) with version $(VERSION)..."
	@publisher -ig ig.ini
# 	@echo "Fixing extension version references..."
# 	@python3 scripts/fix_extension_versions.py output
	@if [ ! -f ./output/package.tgz ]; then \
		echo "ERROR: Build did not create ./output/package.tgz"; \
		exit 1; \
	fi
	@echo "Copying package.tgz to: ./output/$(PACKAGE_NAME)-$(VERSION).tgz"
	@cp ./output/package.tgz ./output/$(PACKAGE_NAME)-$(VERSION).tgz
	@echo "Successfully created: ./output/$(PACKAGE_NAME)-$(VERSION).tgz"
	@fhir install ./output/$(PACKAGE_NAME)-$(VERSION).tgz --file
	@echo "Removing circular references in package.json"
	@jq --arg pkg "$(PACKAGE_NAME)" 'del(.dependencies[$$pkg])' package.json > package.tmp.json
	@mv package.tmp.json package.json


.PHONY: publish
publish: build-ig login ## Publish package to Simplifier.net, not tested.
	cd fsh-generated/resources && $(FHIR) bake
	cd fsh-generated/resources && $(FHIR) pack
	cd fsh-generated/resources && $(FHIR) publish-package


### Helpers

.PHONY: to-json

# Usage:
#   make to-json SRC=Patient.xml
#   make to-json SRC="profiles/*.xml"

to-json: ## convert FHIR resources in XML to JSON
	@if [ -z "$(SRC)" ]; then \
		echo "ERROR: Please specify SRC=<file or wildcard>"; \
		echo "Example: make to-json SRC=Patient.xml"; \
		echo "         make to-json SRC=\"profiles/*.xml\""; \
		exit 1; \
	fi
	@for f in $(SRC); do \
		if [ ! -f "$$f" ]; then \
			echo "Skipping $$f (not a file)"; \
			continue; \
		fi; \
		out="$${f%.xml}.json"; \
		echo "Converting $$f -> $$out"; \
		fhir clear >/dev/null 2>&1 || true; \
		fhir push "$$f"; \
		fhir save "$$out"; \
		fhir clear >/dev/null 2>&1 || true; \
	done

.PHONY: version
version: ## Show version
	@echo "Version: $(VERSION)"
	@echo "Package: $(PACKAGE_NAME)" 

# ##############################################################
# remaining Koppeltaal stuff
# ##############################################################


# Build Implementation Guide (Minimal for servers with snapshots)
# This target creates a minimal FHIR package optimized for FHIR server deployment by:
# 1. Using SUSHI/IG Publisher to generate resources with snapshots
# 2. Converting IG Publisher output back to package.json using Python script
# 3. Stripping only narratives and mappings while keeping snapshots
# 4. Creating final package without regenerating snapshots
.PHONY: build-ig-minimalk
build-ig-minimalk: install-dependencies build-igk convert-ig-minimal pack-minimal

# Convert ImplementationGuide back to package.json for minimal package using Python script
.PHONY: convert-ig-minimal
convert-ig-minimal:
	@echo "Converting ImplementationGuide to minimal package.json using Python script..."
	@python3 scripts/convert_ig_to_package.py output/ImplementationGuide-koppeltaalv2.00.json package.json

# Pack FHIR resources for minimal package using Firely CLI (keeping snapshots, removing only narratives/mappings)
.PHONY: pack-minimal
pack-minimal: login
	@echo "Creating minimal FHIR package with snapshots retained..."
	@mkdir -p output-minimal
	@echo "Restoring package dependencies..."
	$(FHIR) restore
	@echo "Copying FHIR resources from output to output-minimal..."
	@find output -name "*.json" -type f -not -name "*usage-stats*" -not -name "*qa*" -not -name "*manifest*" -not -name "*fragment*" -not -name "*canonicals*" -not -name "*list*" -not -name "*expansions*" -exec cp {} output-minimal/ \;
	@echo "Stripping narratives and mappings from FHIR resources (keeping snapshots)..."
	@python3 scripts/strip_narratives.py output-minimal/ --keep-snapshots
	@echo "Verifying minimal package creation..."
	@if [ -f output-minimal/StructureDefinition-KT2Patient.json ]; then \
		SIZE=$$(wc -c < output-minimal/StructureDefinition-KT2Patient.json); \
		echo "StructureDefinition-KT2Patient.json is $$SIZE bytes (with snapshots retained)"; \
	fi
	@echo "Copying package.json to output-minimal..."
	@cp package.json output-minimal/
	@echo "Creating minimal package manually (avoiding Firely CLI snapshot regeneration)..."
	@echo "Preparing package structure..."
	@mkdir -p output-minimal/package
	@echo "Moving stripped JSON files to package directory..."
	@find output-minimal -maxdepth 1 -name "*.json" -type f ! -name "package.json" -exec mv {} output-minimal/package/ \;
	@echo "Moving package.json to package directory..."
	@mv output-minimal/package.json output-minimal/package/
	@echo "Creating .index.json..."
	@cd output-minimal && python3 ../scripts/create_index.py
	@echo "Creating package tarball..."
	@cd output-minimal && tar -czf koppeltaalv2.$(VERSION).tgz package/
	@echo "Verifying minimal package was created..."
	@if ! ls output-minimal/*.tgz >/dev/null 2>&1; then \
		echo "ERROR: Minimal package creation failed - no .tgz file found"; \
		exit 1; \
	fi
	@echo "Renaming generated package for GitHub Actions compatibility..."
	@cd output-minimal && \
	for file in *.tgz; do \
		if [ -f "$$file" ]; then \
			cp "$$file" package.tgz; \
			cp "$$file" koppeltaalv2-$(VERSION)-minimal.tgz; \
			break; \
		fi; \
	done
	@echo "Successfully created minimal FHIR package: ./output-minimal/koppeltaalv2-$(VERSION)-minimal.tgz"
	@echo "Package also available as: ./output-minimal/package.tgz"
	@echo "Final package size: $$(du -h ./output-minimal/koppeltaalv2-$(VERSION)-minimal.tgz | cut -f1)"
	@echo "Package structure matches working Simplifier format - ready for HAPI FHIR deployment"


# Clean target (optional)
.PHONY: clean
clean:
	@echo "Clean target not implemented - add cleanup commands if needed"

show-make: ## Show MAKEFILE paths (for debugging purposes)
	@echo 'MAKEFILE_LIST='$(MAKEFILE_LIST)
	@echo 'MAKEFILE_DIR='$(MAKEFILE_DIR)
	@echo 'SCRIPTS='$(SCRIPTS)