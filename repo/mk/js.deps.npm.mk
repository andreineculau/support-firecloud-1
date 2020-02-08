# Adds 'deps-npm' and 'deps-npm-prod' internal targets to install all and respectively prod-only npm dependencies.
# The 'deps-npm' target is automatically included in the 'deps' target via SF_DEPS_TARGETS.
#
# In addition to 'npm install' functionality, we also:
# * install babel-preset-firecloud and eslint-config-firecloud peer dependencies
# * 'npm update' also the git dependencies (to the latest compatible version)
# * check (and fail) for unmet peer dependencies.
#
# The check for unmet peer dependencies can be silenced on a case-by-case basis
# by commiting a package.json.unmet-peer file that contains the 'peer dep missing' lines
# produced by 'npm list' that you want to ignore e.g.:
# npm ERR! peer dep missing: tslint@^5.16.0, required by tslint-config-firecloud
#
# For leaf repositories (i.e. not libraries), package-lock.json may present some stability.
# In order to create a lock, add to your Makefile:
# SF_DEPS_TARGETS += deps-npm-package-lock
# and commit package-lock.json.
#
# ------------------------------------------------------------------------------

NPM = $(call which,NPM,npm)
$(foreach VAR,NPM,$(call make-lazy,$(VAR)))

NPM_CI_OR_INSTALL := install
ifeq (true,$(CI))
ifneq (,$(wildcard package-lock.json))
# npm ci doesn't play nice with git dependencies
ifeq (,$(shell $(CAT) package.json | \
	$(JQ)  ".dependencies + .devDependencies" | \
	$(JQ) "to_entries" | \
	$(JQ) ".[] | select(.value | contains(\"git\"))" | \
	$(JQ) -r ".key"))
NPM_CI_OR_INSTALL := ci
endif
endif
endif

SF_CLEAN_FILES += \
	node_modules \

SF_DEPS_TARGETS += \
	deps-npm \

SF_CHECK_TARGETS += \
	check-package-json \
	check-package-lock-json \

ifdef SF_ECLINT_FILES_IGNORE
SF_ECLINT_FILES_IGNORE += \
	-e "^package-lock.json$$" \
	-e "^package.json.unmet-peer$$" \

endif

# ------------------------------------------------------------------------------

.PHONY: deps-npm-unmet-peer
deps-npm-unmet-peer:
	$(eval NPM_LIST_TMP := $(shell $(MKTEMP)))
	$(eval UNMET_PEER_DIFF_TMP := $(shell $(MKTEMP)))
	$(NPM) list --depth=0 >$(NPM_LIST_TMP) 2>&1 || true
	diff -U0 \
		<(cat package.json.unmet-peer 2>/dev/null | \
			$(GREP) --only-matching -e "npm ERR! peer dep missing: [^,]\+, required by @\?[^@]\+" | \
			$(SORT) -u || true) \
		<(cat $(NPM_LIST_TMP) 2>/dev/null | \
			$(GREP) --only-matching -e "npm ERR! peer dep missing: [^,]\+, required by @\?[^@]\+" | \
			$(SORT) -u || true) \
		>$(UNMET_PEER_DIFF_TMP) || $(TOUCH) $(UNMET_PEER_DIFF_TMP)
	if $(CAT) $(UNMET_PEER_DIFF_TMP) | $(GREP) -q -e "^\+npm"; then \
		$(ECHO_ERR) "Found new unmet peer dependencies."; \
		$(ECHO_INFO) "If you cannot fix the unmet peer dependencies, and want to ignore them instead,"; \
		$(ECHO_INFO) "please edit package.json.unmet-peer, and append these line(s):"; \
		$(CAT) $(UNMET_PEER_DIFF_TMP) | $(GREP) -e "^\+npm" | $(SED) "s/^\+//g"; \
		$(ECHO); \
	fi
	if $(CAT) $(UNMET_PEER_DIFF_TMP) | $(GREP) -q -e "^\-npm"; then \
		$(ECHO_ERR) "Found outdated unmet peer dependencies."; \
		$(ECHO_INFO) "Please edit package.json.unmet-peer, and remove these line(s):"; \
		$(CAT) $(UNMET_PEER_DIFF_TMP) | $(GREP) -e "^\-npm" | $(SED) "s/^\-//g"; \
		$(ECHO); \
	fi
	if [[ -s $(UNMET_PEER_DIFF_TMP) ]]; then \
		exit 1; \
	fi


.PHONY: deps-npm-ci
deps-npm-ci:
	$(NPM) ci


.PHONY: deps-npm-install
deps-npm-install:
	$(eval PACKAGE_JSON_WAS_CHANGED := $(shell $(GIT) diff --exit-code package.json && echo false || echo true))
	$(NPM) install
#	convenience. install peer dependencies from babel/eslint firecloud packages
	[[ ! -f node_modules/babel-preset-firecloud/package.json ]] || \
		$(SUPPORT_FIRECLOUD_DIR)/bin/npm-install-peer-deps \
			node_modules/babel-preset-firecloud/package.json
	[[ ! -f node_modules/eslint-config-firecloud/package.json ]] || \
		$(SUPPORT_FIRECLOUD_DIR)/bin/npm-install-peer-deps \
			node_modules/eslint-config-firecloud/package.json
#	hack. sort dependencies in package.json
	if $(CAT) package.json | $(GREP) -q "\"dependencies\""; then \
		$(NPM) remove --save-prod some-pkg-that-doesnt-exist; \
	fi
	if $(CAT) package.json | $(GREP) -q "\"devDpendencies\""; then \
		$(NPM) remove --save-dev some-pkg-that-doesnt-exist; \
	fi
#	check that installing peer dependencies didn't modify package.json
	$(GIT) diff --exit-code package.json || [[ "$(PACKAGE_JSON_WAS_CHANGED)" = "true" ]] || { \
		$(NPM) install; \
		$(ECHO_ERR) "package.json has changed."; \
		$(ECHO_ERR) "Please review and commit the changes."; \
		exit 1; \
	}
#	remove extraneous dependencies
	$(NPM) prune
#	update git dependencies with semver range. 'npm install' doesn't
	[[ -f "package-lock.json" ]] || { \
		$(CAT) package.json | \
			$(JQ)  ".dependencies + .devDependencies" | \
			$(JQ) "to_entries" | \
			$(JQ) ".[] | select(.value | contains(\"git\"))" | \
			$(JQ) -r ".key" | \
			$(XARGS) -L1 -I{} $(RM) node_modules/{}; \
		$(NPM) update --no-save --development; \
	}


.PHONY: deps-npm
deps-npm: deps-npm-$(NPM_CI_OR_INSTALL)
#	'npm ci' should be more stable and faster if there's a 'package-lock.json'
	$(NPM) list --depth=0 || $(MAKE) deps-npm-unmet-peer


.PHONY: deps-npm-ci-prod
deps-npm-ci-prod:
	$(NPM) ci


.PHONY: deps-npm-install-prod
deps-npm-install-prod:
	$(NPM) install --production
#	remove extraneous dependencies
	$(NPM) prune --production
#	update git dependencies with semver range. 'npm install' doesn't
	[[ -f "package-lock.json" ]] || { \
		$(CAT) package.json | \
			$(JQ)  ".dependencies" | \
			$(JQ) "to_entries" | \
			$(JQ) ".[] | select(.value | contains(\"git\"))" | \
			$(JQ) -r ".key" | \
			$(XARGS) -L1 -I{} $(RM) node_modules/{}; \
		$(NPM) update --no-save --production; \
	}


.PHONY: deps-npm-prod
deps-npm-prod: deps-npm-$(NPM_CI_OR_INSTALL)
#	'npm ci' should be more stable and faster if there's a 'package-lock.json'
	$(NPM) list --depth=0 || $(MAKE) deps-npm-unmet-peer


.PHONY: deps-npm-package-lock
deps-npm-package-lock:
	[[ "$$($(NPM) config get package-lock)" = "true" ]] || { \
		$(ECHO_ERR) "npm's package-lock flag is not on. Please check your .npmrc file."; \
		exit 1; \
	}
	$(MAKE) package-lock.json


package-lock.json: package.json
	$(RM) package-lock.json
	$(NPM) install


.PHONY: check-package-json
check-package-json:
	$(GIT) diff --exit-code package.json || { \
		$(ECHO_ERR) "package.json has changed. Please commit your changes."; \
		exit 1; \
	}


.PHONY: check-package-lock-json
check-package-lock-json: check-package-json
	if $(GIT_LS) | $(GREP) -q "^package-lock.json$$"; then \
		$(GIT) diff --exit-code package-lock.json || { \
			$(ECHO_ERR) "package-lock.json has changed. Please commit your changes."; \
			exit 1; \
		}; \
		[[ "$$($(GIT) log -1 --format='%at' -- package-lock.json)" -ge \
			"$$($(GIT) log -1 --format='%at' -- package.json)" ]] || { \
			$(ECHO_ERR) "package.json is newer than package-lock.json."; \
			$(ECHO_ERR) "Please run 'make package-lock.json' and commit your changes."; \
			exit 1; \
		}; \
	fi
