.DEFAULT_GOAL := build

# Configuration
BINARY_NAME  := nmsample
MANIFEST_NAME := io.github.cpsdenis.json

# Paths
BINARY_SRC   := build/host/src/$(BINARY_NAME)
BINARY_DST   := /usr/local/bin/$(BINARY_NAME)
MANIFEST_SRC := host/$(MANIFEST_NAME)

# System and User Manifest Directories
SYS_CHROME_DIR   := /etc/opt/chrome/native-messaging-hosts
SYS_CHROMIUM_DIR := /etc/chromium/native-messaging-hosts
USER_CHROME_DIR  := $(HOME)/.config/google-chrome/NativeMessagingHosts

.PHONY: help
help: ## Display this help screen
	@grep -E '^[a-z.A-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: clean
clean: clean-build ## Clean project

.PHONY: clean-build
clean-build:
	rm -fr build

.PHONY: build
build: ## Build binary
	cmake -S . -B build
	cmake --build build -j$$(nproc)

.PHONY: rebuild
rebuild: clean build ## Clean and rebuild the binary from scratch

.PHONY: install
install: build ## Build and install binary and manifests (Requires sudo for system paths)
	@echo "Installing binary to $(BINARY_DST)..."
	sudo mkdir -p $(dir $(BINARY_DST))
	sudo cp $(BINARY_SRC) $(BINARY_DST)
	sudo chmod +x $(BINARY_DST)

	@echo "Installing system-wide Chrome manifest..."
	sudo mkdir -p $(SYS_CHROME_DIR)
	sudo cp $(MANIFEST_SRC) $(SYS_CHROME_DIR)/$(MANIFEST_NAME)

	@echo "Installing system-wide Chromium manifest..."
	sudo mkdir -p $(SYS_CHROMIUM_DIR)
	sudo cp $(MANIFEST_SRC) $(SYS_CHROMIUM_DIR)/$(MANIFEST_NAME)

	@echo "Installing user-specific Chrome manifest..."
	mkdir -p $(USER_CHROME_DIR)
	cp $(MANIFEST_SRC) $(USER_CHROME_DIR)/$(MANIFEST_NAME)
	@echo "Installation complete."

.PHONY: uninstall
uninstall: ## Remove installed binary and native messaging manifests
	@echo "Removing binary from $(BINARY_DST)..."
	sudo rm -f $(BINARY_DST)

	@echo "Removing system-wide Chrome manifest..."
	sudo rm -f $(SYS_CHROME_DIR)/$(MANIFEST_NAME)

	@echo "Removing system-wide Chromium manifest..."
	sudo rm -f $(SYS_CHROMIUM_DIR)/$(MANIFEST_NAME)

	@echo "Removing user-specific Chrome manifest..."
	rm -f $(USER_CHROME_DIR)/$(MANIFEST_NAME)
	@echo "Uninstallation complete."