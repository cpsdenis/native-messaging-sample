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
	BINARY_SRC        := build/host/src/$(BINARY_NAME)
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
	BINARY_SRC        := build/host/src/Debug/$(BINARY_NAME).exe
    MANIFEST_FILENAME := io.github.cpsdenis.win.json
    BINARY_DST_FOLDER := C:/nmsample/
    BINARY_DST        := $(BINARY_DST_FOLDER)/$(BINARY_NAME).exe
	REG_KEY           := "HKCU\\SOFTWARE\\Google\\Chrome\\NativeMessagingHosts\\io.github.cpsdenis"
    USER_CHROME_DIR   := $(USERPROFILE)/.config/google-chrome/NativeMessagingHosts
    NPROC             := $(NUMBER_OF_PROCESSORS)
    SUDO              := 
    SED_INPLACE       := sed -i
else
    # Linux
	BINARY_SRC        := build/host/src/$(BINARY_NAME)
    MANIFEST_FILENAME := io.github.cpsdenis.linux.json
    BINARY_DST        := /usr/local/bin/$(BINARY_NAME)
    SYS_CHROME_DIR    := /etc/opt/chrome/native-messaging-hosts
    SYS_CHROMIUM_DIR  := /etc/chromium/native-messaging-hosts
    USER_CHROME_DIR   := $(HOME)/.config/google-chrome/NativeMessagingHosts
    NPROC             := $(shell nproc)
    SUDO              := sudo
    SED_INPLACE       := sed -i
endif

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
	cp "build/manifest/$(MANIFEST_DST)" "$(BINARY_DST_FOLDER)/$(MANIFEST_DST)"
	reg add $(REG_KEY) //ve //d "C:\\nmsample\\io.github.cpsdenis.json" //f
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
	reg delete $(REG_KEY) //f
	rm -rf "$(BINARY_DST_FOLDER)"
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
