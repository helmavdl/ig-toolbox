SHELL := /bin/bash

.DEFAULT_GOAL := help

YELLOW := \033[1;33m
GREEN  := \033[1;32m
CYAN   := \033[1;36m
RESET  := \033[0m

# Load IMAGE_NAME from .env (assumes a line like: IMAGE_NAME=ig-toolbox)
IMAGE_NAME := $(shell sed -n 's/^IMAGE_NAME=\(.*\)/\1/p' .env)

.PHONY: help setup build build-amd64 build-arm64 test alias clean clean-old purge

help:
	@echo -e "$(GREEN)Available targets:$(RESET)"
	@echo
	@echo -e "  $(CYAN)make setup$(RESET)"
	@echo -e "      Initializes Docker Buildx and CPU emulation (required for cross-building)."
	@echo
	@echo -e "  $(CYAN)make build$(RESET)"
	@echo -e "      Builds $(IMAGE_NAME) for the current machine architecture."
	@echo -e "      Produces a tag like: $(IMAGE_NAME):<date>-git-<sha>-<arch>"
	@echo
	@echo -e "  $(CYAN)make build-amd64$(RESET)"
	@echo -e "      Cross-builds an amd64 (Intel) image, even if running on Apple Silicon."
	@echo -e "      Requires: make setup"
	@echo
	@echo -e "  $(CYAN)make build-arm64$(RESET)"
	@echo -e "      Cross-builds an arm64 (Apple Silicon) image, even if running on Intel."
	@echo -e "      Requires: make setup"
	@echo
	@echo -e "  $(CYAN)make test$(RESET)"
	@echo -e "      Runs smoke tests against the matching-architecture image:"
	@echo -e "      Node, Java, .NET, SUSHI, GoFSH, BonFHIR, IG Publisher, Validator, etc."
	@echo
	@echo -e "  $(CYAN)make alias$(RESET)"
	@echo -e "      Retags the most recent matching-arch image as:"
	@echo -e "          $(YELLOW)$(IMAGE_NAME):local$(RESET)"
	@echo -e "      This makes it easy to run:"
	@echo -e "          docker run -it $(IMAGE_NAME):local"
	@echo -e "      (Optional: you do NOT need to run this unless you want a shell in the container.)"
	@echo
	@echo -e "  $(CYAN)make clean$(RESET)"
	@echo -e "      Stops and removes all containers using $(IMAGE_NAME) images,"
	@echo -e "      then removes all $(IMAGE_NAME) images themselves."
	@echo
	@echo -e "  $(CYAN)make clean-old$(RESET)"
	@echo -e "      Keeps only the most recent 5 $(IMAGE_NAME) images by default,"
	@echo -e "      and removes older ones (including any containers using them)."
	@echo -e "      Examples:"
	@echo -e "          make clean-old             # keep 5 newest"
	@echo -e "          N=10 make clean-old        # keep 10 newest"
	@echo -e "          DRY_RUN=1 make clean-old   # preview what would be deleted"
	@echo
	@echo -e "  $(CYAN)make purge$(RESET)"
	@echo -e "      Runs 'make clean', then prunes dangling Docker layers (safe)."
	@echo

setup:
	@scripts/buildx-setup.sh

build:
	@scripts/build.sh

build-amd64:
	@scripts/build-amd64.sh

build-arm64:
	@scripts/build-arm64.sh

test:
	@scripts/test.sh

alias:
	@scripts/alias-local.sh

clean:
	@scripts/clean.sh

clean-old:
	@scripts/clean-old.sh

purge:
	@scripts/clean.sh
	@echo "Pruning unused Docker layers..."
	@docker image prune -f >/dev/null
	@echo "Purge complete."
