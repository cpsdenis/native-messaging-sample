.DEFAULT_GOAL := build
VARS_DEBUG    := $(.VARIABLES)

NATIVE_HOST_FILE_NAME    := nmsample
OUTPUT_DIR               := build
HOST_MANIFEST_NAME_VALUE := io.github.cpsdenis
HOST_MANIFEST_FILE       := $(HOST_MANIFEST_NAME_VALUE).json

ifeq ($(OS),Windows_NT)
    UNAME_S := Windows
else
    UNAME_S := $(shell uname -s)
endif

ifeq ($(UNAME_S), Darwin)
    USER_DIR             := $(HOME)
    NPROC                := $(shell sysctl -n hw.ncpu)
    SED_INPLACE          := sed -i ''
    USER_CHROME_DIR      := $(HOME)/Library/Application Support/Google/Chrome/NativeMessagingHosts
    USER_CHROMIUM_DIR    := $(HOME)/Library/Application Support/Chromium/NativeMessagingHosts
	NATIVE_HOST_FILE_EXT := 
else ifeq ($(UNAME_S), Windows)
    USER_DIR             := $(subst \,/,$(USERPROFILE))
    NPROC                := $(NUMBER_OF_PROCESSORS)
    SED_INPLACE          := sed -i
	GOOGLE_NM_REG_KEY    := "HKCU\\SOFTWARE\\Google\\Chrome\\NativeMessagingHosts
	NMCPP_REG_PATH       := $(GOOGLE_NM_REG_KEY)\\$(HOST_MANIFEST_NAME_VALUE)"
	NATIVE_HOST_FILE_EXT := .exe
else
    USER_DIR             := $(HOME)
    NPROC                := $(shell nproc)
    SED_INPLACE          := sed -i
    USER_CHROME_DIR      := $(HOME)/.config/google-chrome/NativeMessagingHosts
    USER_CHROMIUM_DIR    := $(HOME)/.config/chromium/NativeMessagingHosts
	NATIVE_HOST_FILE_EXT := 
endif

NATIVE_HOST_SRC_DIR         := $(OUTPUT_DIR)/host/src
NATIVE_HOST_SRC_FULLPATH    := $(NATIVE_HOST_SRC_DIR)/$(NATIVE_HOST_FILE_NAME)$(NATIVE_HOST_FILE_EXT)
NATIVE_HOST_DEST_DIR        := $(USER_DIR)/.local/share/$(NATIVE_HOST_FILE_NAME)
NATIVE_HOST_DEST_FULLPATH   := $(NATIVE_HOST_DEST_DIR)/$(NATIVE_HOST_FILE_NAME)$(NATIVE_HOST_FILE_EXT)

HOST_MANIFEST_SRC_DIR       := host
HOST_MANIFEST_SRC_FULLPATH  := $(HOST_MANIFEST_SRC_DIR)/$(HOST_MANIFEST_FILE)
HOST_MANIFEST_DEST_DIR      := $(NATIVE_HOST_DEST_DIR)
HOST_MANIFEST_DEST_FULLPATH := $(NATIVE_HOST_DEST_DIR)/$(HOST_MANIFEST_FILE)
HOST_MANIFEST_TEMP_DIR      := $(OUTPUT_DIR)/manifest
HOST_MANIFEST_TEMP_FULLPATH := $(HOST_MANIFEST_TEMP_DIR)/$(HOST_MANIFEST_FILE)

.PHONY: help
help: ## Display this help screen
	@grep -E '^[a-z.A-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: clean
clean: ## Clean project output
ifeq ($(strip $(OUTPUT_DIR)),)
	$(error Error: OUTPUT_DIR variable is empty or not set!)
endif
ifeq ($(OUTPUT_DIR),/)
	$(error Error: Attempted to delete the root directory!)
endif
	rm -rf "$(CURDIR)/$(OUTPUT_DIR)"

.PHONY: build
build: ## Build native host application
	cmake -S . -B $(OUTPUT_DIR)
	cmake --build $(OUTPUT_DIR) -j$(NPROC)
	@echo "Build complete."

.PHONY: rebuild
rebuild: clean build ## Clean and build the binary from scratch

.PHONY: install
install: build ## Build native host and install binary and manifests (User-space, no sudo)
	mkdir -p "$(HOST_MANIFEST_TEMP_DIR)"
	cp "$(HOST_MANIFEST_SRC_FULLPATH)" "$(HOST_MANIFEST_TEMP_DIR)"
	$(SED_INPLACE) 's|__PATH__|$(NATIVE_HOST_DEST_FULLPATH)|g' "$(HOST_MANIFEST_TEMP_FULLPATH)"

	mkdir -p "$(NATIVE_HOST_DEST_DIR)"
	cp "$(NATIVE_HOST_SRC_FULLPATH)" "$(NATIVE_HOST_DEST_FULLPATH)"
	chmod +x "$(NATIVE_HOST_DEST_FULLPATH)"

ifeq ($(UNAME_S), Windows)
	reg add $(NMCPP_REG_PATH) //ve //d "$(HOST_MANIFEST_DEST_FULLPATH)" //f
	cp "$(HOST_MANIFEST_TEMP_FULLPATH)" "$(HOST_MANIFEST_DEST_FULLPATH)"
else
	mkdir -p "$(USER_CHROME_DIR)"
	cp "$(HOST_MANIFEST_TEMP_FULLPATH)" "$(USER_CHROME_DIR)"

	mkdir -p "$(USER_CHROMIUM_DIR)"
	cp "$(HOST_MANIFEST_TEMP_FULLPATH)" "$(USER_CHROMIUM_DIR)"
endif
	@echo "Install complete."

.PHONY: uninstall
uninstall: ## Remove installed binary and native messaging manifests
	rm -f "$(NATIVE_HOST_DEST_FULLPATH)"
ifeq ($(UNAME_S), Windows)
	-reg delete $(NMCPP_REG_PATH) //f
	rm -f "$(HOST_MANIFEST_DEST_FULLPATH)"
else
	rm -f "$(USER_CHROME_DIR)/$(HOST_MANIFEST_FILE)"
	rm -f "$(USER_CHROMIUM_DIR)/$(HOST_MANIFEST_FILE)"
endif
	-rmdir --ignore-fail-on-non-empty "$(NATIVE_HOST_DEST_DIR)"
	-rmdir --ignore-fail-on-non-empty "$(HOST_MANIFEST_DEST_DIR)"
	@echo "Uninstall complete."

.PHONY: reinstall
reinstall: uninstall install ## Uninstall and install

.PHONY: purge
purge: uninstall clean ## Uninstall and clean
	@echo "Purge complete."

.PHONY: debug
debug: ## Print local makefile variables
	$(foreach v, $(sort $(filter-out $(VARS_DEBUG) VARS_DEBUG, $(.VARIABLES))), $(info $(v) = $($(v))))
