.PHONY: all linux musl windows help clean

# Configuration
OUTPUT_DIR ?= $(CURDIR)/dist

help:	## Show this help
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' | sed -e 's/##//'

all: linux windows ## Build everything

linux: ## Build Linux binaries
	@OUTPUT_DIR="$(OUTPUT_DIR)" build_scripts/build_linux.sh

musl: ## Build musl-linked Linux binaries (run on Alpine for true musl)
	@OUTPUT_DIR="$(OUTPUT_DIR)" build_scripts/build_musl.sh

windows: ## Build Windows binaries (run on Windows or use GitHub Actions)
	@OUTPUT_DIR="$(OUTPUT_DIR)" build_scripts/build_windows.sh

clean: ## Remove all build artifacts
	rm -rf dist/* build/* *.spec
