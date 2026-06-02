.DEFAULT_GOAL := build

BINARY_NAME  := nmsample
MANIFEST_DST := io.github.cpsdenis.json

ifeq ($(OS),Windows_NT)
    UNAME_S := Windows
else
    UNAME_S := $(shell uname -s)
endif

ifeq ($(UNAME_S), Darwin)
    # macOS
    MANIFEST_FILENAME := io.github.cpsdenis.macos.json
    BINARY_DST        := /usr/local/bin/$(BINARY_NAME)
    SYS_CHROME_DIR    := /Library/Google/Chrome/NativeMessagingHosts
    SYS_CHROMIUM_DIR  := /Library/Application Support/Chromium/NativeMessagingHosts
    USER_CHROME_DIR   := $(HOME)/Library/Application Support/Google/Chrome/NativeMessagingHosts
    NPROC             := $(shell sysctl -n hw.ncpu)
    SUDO              := sudo
    SED_INPLACE       := sed -i ''
else ifeq ($(UNAME_S), Windows)
    # Windows (Run via Git Bash or MSYS2)
    MANIFEST_FILENAME := io.github.cpsdenis.windows.json
    BINARY_DST        := C:/Program Files/$(BINARY_NAME)/$(BINARY_NAME).exe
    # Registry keys are used on Windows instead of specific directories,
    # but we store the JSON in the program folder for simplicity.
    USER_CHROME_DIR   := $(USERPROFILE)/.config/google-chrome/NativeMessagingHosts
    NPROC             := $(NUMBER_OF_PROCESSORS)
    SUDO              := 
    SED_INPLACE       := sed -i
else
    # Linux
    MANIFEST_FILENAME := io.github.cpsdenis.linux.json
    BINARY_DST        := /usr/local/bin/$(BINARY_NAME)
    SYS_CHROME_DIR    := /etc/opt/chrome/native-messaging-hosts
    SYS_CHROMIUM_DIR  := /etc/chromium/native-messaging-hosts
    USER_CHROME_DIR   := $(HOME)/.config/google-chrome/NativeMessagingHosts
    NPROC             := $(shell nproc)
    SUDO              := sudo
    SED_INPLACE       := sed -i
endif

BINARY_SRC   := build/host/src/$(BINARY_NAME)
MANIFEST_SRC := host/$(MANIFEST_FILENAME)

.PHONY: help
help: ## Display this help screen
	@grep -E '^[a-z.A-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: clean
clean: ## Clean project
	rm -rf build

.PHONY: build
build: ## Build binary
	cmake -S . -B build
	cmake --build build -j$(NPROC)

.PHONY: rebuild
rebuild: clean build ## Clean and rebuild the binary from scratch

.PHONY: install
install: build ## Build and install binary and manifests (Requires sudo for system paths)
	@echo "Installing binary to $(BINARY_DST)..."
	$(SUDO) mkdir -p "$(dir $(BINARY_DST))"
	$(SUDO) cp "$(BINARY_SRC)" "$(BINARY_DST)"
	$(SUDO) chmod +x "$(BINARY_DST)"

ifeq ($(UNAME_S), Windows)
	@echo "Windows detected. Injecting path and updating Registry..."
	@# Double escape backslashes for Windows JSON format
	$(eval ESCAPED_PATH := $(subst /,\\,$(BINARY_DST)))
	$(eval ESCAPED_PATH := $(subst \\,\\\\,$(ESCAPED_PATH)))
	
	@# Update the JSON manifest with the absolute path
	mkdir -p "build/manifest"
	cp "$(MANIFEST_SRC)" "build/manifest/$(MANIFEST_DST)"
	$(SED_INPLACE) 's|__PATH__|$(ESCAPED_PATH)|g' "build/manifest/$(MANIFEST_DST)"
	
	@# Move manifest to target destination
	mkdir -p "$(USER_CHROME_DIR)"
	cp "build/manifest/$(MANIFEST_DST)" "$(USER_CHROME_DIR)/$(MANIFEST_DST)"
	
	@# Register the host in Windows Registry
	powershell -Command "New-Item -Path 'HKCU:\Software\Google\Chrome\NativeMessagingHosts' -Name 'io.github.cpsdenis' -Force | Out-Null"
	powershell -Command "Set-ItemProperty -Path 'HKCU:\Software\Google\Chrome\NativeMessagingHosts\io.github.cpsdenis' -Name '(Default)' -Value '$(shell cygpath -w $(USER_CHROME_DIR)/$(MANIFEST_DST))'"
else
	@echo "Unix detected. Injecting absolute path into manifests..."
	mkdir -p "build/manifest"
	cp "$(MANIFEST_SRC)" "build/manifest/$(MANIFEST_DST)"
	$(SED_INPLACE) 's|__PATH__|$(BINARY_DST)|g' "build/manifest/$(MANIFEST_DST)"

	@echo "Installing system-wide Chrome manifest..."
	$(SUDO) mkdir -p "$(SYS_CHROME_DIR)"
	$(SUDO) cp "build/manifest/$(MANIFEST_DST)" "$(SYS_CHROME_DIR)/$(MANIFEST_DST)"

	@echo "Installing system-wide Chromium manifest..."
	$(SUDO) mkdir -p "$(SYS_CHROMIUM_DIR)"
	$(SUDO) cp "build/manifest/$(MANIFEST_DST)" "$(SYS_CHROMIUM_DIR)/$(MANIFEST_DST)"

	@echo "Installing user-specific Chrome manifest..."
	mkdir -p "$(USER_CHROME_DIR)"
	cp "build/manifest/$(MANIFEST_DST)" "$(USER_CHROME_DIR)/$(MANIFEST_DST)"
endif
	@echo "Installation complete."

.PHONY: uninstall
uninstall: ## Remove installed binary and native messaging manifests
	@echo "Removing binary from $(BINARY_DST)..."
	$(SUDO) rm -f "$(BINARY_DST)"

ifeq ($(UNAME_S), Windows)
	powershell -Command "Remove-Item -Path 'HKCU:\Software\Google\Chrome\NativeMessagingHosts\io.github.cpsdenis' -ErrorAction SilentlyContinue"
	rm -f "$(USER_CHROME_DIR)/$(MANIFEST_DST)"
else
	@echo "Removing system-wide Chrome manifest..."
	$(SUDO) rm -f "$(SYS_CHROME_DIR)/$(MANIFEST_DST)"

	@echo "Removing system-wide Chromium manifest..."
	$(SUDO) rm -f "$(SYS_CHROMIUM_DIR)/$(MANIFEST_DST)"

	@echo "Removing user-specific Chrome manifest..."
	rm -f "$(USER_CHROME_DIR)/$(MANIFEST_DST)"
endif
	@echo "Uninstallation complete."

.PHONY: reinstall
reinstall: uninstall install ## Uninstall and install
