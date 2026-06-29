# This file is licensed under the Affero General Public License version 3 or
# later. See the COPYING file.
# @author Bernhard Posselt <dev@bernhard-posselt.com>
# @copyright Bernhard Posselt 2016

# Generic Makefile for building and packaging a Nextcloud app which uses npm and
# Composer.
#
# Dependencies:
# * make
# * php: used for Composer fallback installation
# * composer, or curl plus php so Composer can be fetched locally
# * tar: for building the archive
# * npm: for building and testing everything JS
#
# If no composer.json is in the app root directory, the Composer step
# will be skipped. The same goes for the package.json which can be located in
# the app root or the js/ directory.
#
# The npm command installs locked dependencies and launches the npm build script:
#
#    npm ci && npm run build

APP_ID ?= timetracker
app_name=$(notdir $(CURDIR))
build_tools_directory=$(CURDIR)/build/tools
source_build_directory=$(CURDIR)/build/artifacts/source
source_package_name=$(source_build_directory)/$(app_name)
appstore_build_directory=$(CURDIR)/build/artifacts/appstore
appstore_package_name=$(appstore_build_directory)/$(app_name)
composer_phar=$(build_tools_directory)/composer.phar
composer_installer=$(build_tools_directory)/composer-setup.php

NPM ?= npm
COMPOSER ?= composer
PHP ?= php
PHP_FLAGS ?= -dallow_url_fopen=On
CURL ?= curl
TAR ?= tar
TAR_OWNER_ARGS ?= --owner=0 --group=0
NEXTCLOUD_ROOT ?= $(CURDIR)/../..
NEXTCLOUD_BOOTSTRAP ?= $(NEXTCLOUD_ROOT)/lib/base.php
NEXTCLOUD_APP_DIR ?= $(NEXTCLOUD_ROOT)/apps/$(APP_ID)
default_phpunit = $(firstword $(wildcard $(NEXTCLOUD_ROOT)/vendor-bin/phpunit/vendor/bin/phpunit $(NEXTCLOUD_ROOT)/vendor/bin/phpunit $(CURDIR)/vendor/phpunit/phpunit/phpunit))
PHPUNIT ?= $(if $(default_phpunit),$(default_phpunit),$(NEXTCLOUD_ROOT)/vendor-bin/phpunit/vendor/bin/phpunit)

COMPOSER_ARGS ?= --prefer-dist --no-dev --no-interaction
COMPOSER_DEV_ARGS ?= --prefer-dist --no-interaction

define require_command
	@command -v "$(1)" >/dev/null 2>&1 || { \
		printf '%s\n' "Error: required command '$(1)' not found. Install it or rerun with $(2)=/path/to/$(1)." >&2; \
		exit 127; \
	}
endef

all: build

# Fetches the PHP and JS dependencies and compiles the JS. If no composer.json
# is present, the composer step is skipped, if no package.json or js/package.json
# is present, the npm step is skipped
.PHONY: build
build:
ifneq (,$(wildcard $(CURDIR)/composer.json))
	$(MAKE) composer
endif
ifneq (,$(wildcard $(CURDIR)/package.json))
	$(MAKE) npm
endif
ifneq (,$(wildcard $(CURDIR)/js/package.json))
	$(MAKE) npm
endif

# Installs and updates the composer dependencies. If composer is not installed
# a copy is fetched from the web
.PHONY: composer
composer:
	@if command -v "$(COMPOSER)" >/dev/null 2>&1; then \
		"$(COMPOSER)" install $(COMPOSER_ARGS); \
	else \
		if ! command -v "$(PHP)" >/dev/null 2>&1; then \
			printf '%s\n' "Error: composer is not installed and PHP command '$(PHP)' was not found. Install Composer, install PHP, or rerun with PHP=/path/to/php." >&2; \
			exit 127; \
		fi; \
		if ! command -v "$(CURL)" >/dev/null 2>&1; then \
			printf '%s\n' "Error: composer is not installed and curl command '$(CURL)' was not found. Install Composer, install curl, or rerun with CURL=/path/to/curl." >&2; \
			exit 127; \
		fi; \
		printf '%s\n' "No composer command available, downloading Composer to $(composer_phar)"; \
		mkdir -p "$(build_tools_directory)"; \
		"$(CURL)" -sS https://getcomposer.org/installer -o "$(composer_installer)"; \
		"$(PHP)" $(PHP_FLAGS) "$(composer_installer)" --install-dir="$(build_tools_directory)" --filename=composer.phar; \
		rm -f "$(composer_installer)"; \
		"$(PHP)" $(PHP_FLAGS) "$(composer_phar)" install $(COMPOSER_ARGS); \
	fi

.PHONY: composer-dev
composer-dev: COMPOSER_ARGS=$(COMPOSER_DEV_ARGS)
composer-dev: composer

# Installs npm dependencies
.PHONY: npm
npm:
	$(call require_command,$(NPM),NPM)
ifeq (,$(wildcard $(CURDIR)/package.json))
	cd js && $(NPM) ci && $(NPM) run build
else
	$(NPM) ci && $(NPM) run build
endif

# Removes the appstore build
.PHONY: clean
clean:
	rm -rf ./build

# Same as clean but also removes dependencies installed by composer, bower and
# npm
.PHONY: distclean
distclean: clean
	rm -rf vendor
	rm -rf node_modules
	rm -rf js/vendor
	rm -rf js/node_modules

.PHONY: nextcloud-link
nextcloud-link:
	@if [ ! -f "$(NEXTCLOUD_BOOTSTRAP)" ]; then \
		printf '%s\n' "Error: Nextcloud test bootstrap not found at $(NEXTCLOUD_BOOTSTRAP). Rerun with NEXTCLOUD_ROOT=/path/to/nextcloud." >&2; \
		exit 127; \
	fi
	@if [ "$(NEXTCLOUD_APP_DIR)" = "$(CURDIR)" ]; then \
		printf '%s\n' "App is already located at $(NEXTCLOUD_APP_DIR)"; \
	else \
		if [ -e "$(NEXTCLOUD_APP_DIR)" ] && [ ! -L "$(NEXTCLOUD_APP_DIR)" ]; then \
			printf '%s\n' "Error: $(NEXTCLOUD_APP_DIR) already exists and is not a symlink. Move it aside or set NEXTCLOUD_APP_DIR=/path/to/link." >&2; \
			exit 1; \
		fi; \
		mkdir -p "$$(dirname "$(NEXTCLOUD_APP_DIR)")"; \
		ln -sfn "$(CURDIR)" "$(NEXTCLOUD_APP_DIR)"; \
		printf '%s\n' "Linked $(CURDIR) -> $(NEXTCLOUD_APP_DIR)"; \
	fi

# Builds the source and appstore package
.PHONY: dist
dist:
	$(MAKE) source
	$(MAKE) appstore

# Builds the source package
.PHONY: source
source:
	$(call require_command,$(TAR),TAR)
	rm -rf $(source_build_directory)
	mkdir -p $(source_build_directory)
	$(TAR) czf $(source_package_name).tar.gz \
	--exclude-vcs \
	--exclude="../$(app_name)/build" \
	--exclude="../$(app_name)/js/node_modules" \
	--exclude="../$(app_name)/node_modules" \
	--exclude="../$(app_name)/*.log" \
	--exclude="../$(app_name)/js/*.log" \
	../$(app_name)

# Builds the source package for the app store, ignores php and js tests
.PHONY: appstore
appstore:
	$(call require_command,$(TAR),TAR)
	rm -rf $(appstore_build_directory)
	mkdir -p $(appstore_build_directory)
	echo $(app_name)
	pwd
	$(TAR)  \
	$(TAR_OWNER_ARGS) \
	--exclude-vcs \
	--exclude="$(app_name)/build" \
	--exclude="$(app_name)/tests" \
	--exclude="$(app_name)/Makefile" \
	--exclude="$(app_name)/*.log" \
	--exclude="$(app_name)/phpunit*xml" \
	--exclude="$(app_name)/composer.*" \
	--exclude="$(app_name)/js/node_modules" \
	--exclude="$(app_name)/js/tests" \
	--exclude="$(app_name)/js/test" \
	--exclude="$(app_name)/js/*.log" \
	--exclude="$(app_name)/js/package.json" \
	--exclude="$(app_name)/js/bower.json" \
	--exclude="$(app_name)/js/karma.*" \
	--exclude="$(app_name)/js/protractor.*" \
	--exclude="$(app_name)/package.json" \
	--exclude="$(app_name)/bower.json" \
	--exclude="$(app_name)/karma.*" \
	--exclude="$(app_name)/protractor\.*" \
	--exclude="$(app_name)/.*" \
	--exclude="$(app_name)/.git" \
	--exclude="$(app_name)/js/.*" \
	 -czf $(appstore_package_name).tar.gz ../$(app_name) 

.PHONY: test
test:
	sh tests/build/makefile-portability.sh
	@if [ ! -f "$(NEXTCLOUD_BOOTSTRAP)" ]; then \
		printf '%s\n' "Error: Nextcloud test bootstrap not found at $(NEXTCLOUD_BOOTSTRAP). Run this target from nextcloud/apps/$(APP_ID) or rerun with NEXTCLOUD_ROOT=/path/to/nextcloud." >&2; \
		exit 127; \
	fi
	$(MAKE) composer-dev
	@if [ ! -x "$(PHPUNIT)" ]; then \
		printf '%s\n' "Error: PHPUnit not found at $(PHPUNIT). Install Nextcloud PHPUnit dependencies or rerun with PHPUNIT=/path/to/phpunit." >&2; \
		exit 127; \
	fi
	NEXTCLOUD_ROOT="$(NEXTCLOUD_ROOT)" $(PHPUNIT) -c phpunit.xml
	NEXTCLOUD_ROOT="$(NEXTCLOUD_ROOT)" $(PHPUNIT) -c phpunit.integration.xml
