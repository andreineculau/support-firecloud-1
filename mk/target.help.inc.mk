.PHONY: help
help: ## Show this help message.
	$(eval RANDOM_MARKER := $(shell hexdump -n 16 -e '4/4 "%08X" 1 "\n"' /dev/random))
	@echo "usage: $(MAKE:$(firstword $(MAKE))=$$(basename $(firstword $(MAKE)))) [targets]"
	@echo
	@echo "Available targets:"
	@for Makefile in $(MAKEFILE_LIST); do \
		$(CAT) $${Makefile} | \
		$(SED) "s|^\([^#.\$$\t][^=]\{1,\}\):[^=]\{0,\}[[:space:]]##[[:space:]]\{1,\}\(.\{1,\}\)\$$|$(RANDOM_MARKER)  \1##\2|g"; \
	done | \
		$(GREP) "^$(RANDOM_MARKER)" | \
		$(SED) "s|^$(RANDOM_MARKER)||g" | \
		sort -u | \
		column -t -s "##"


.PHONY: help-all
help-all: ## Show this help message, including all intermediary targets and source Makefiles.
	$(eval RANDOM_MARKER := $(shell hexdump -n 16 -e '4/4 "%08X" 1 "\n"' /dev/random))
	@echo "usage: $(MAKE:$(firstword $(MAKE))=$$(basename $(firstword $(MAKE)))) [targets]"
	@echo
	@echo "Available targets:"
	@for Makefile in $(MAKEFILE_LIST); do \
		$(CAT) $${Makefile} | \
		$(SED) "s|^\([^#.\$$\t][^=]\{1,\}\):[^=]\{0,\}\$$|$(RANDOM_MARKER)  \1##$${Makefile#$(MAKE_PATH)/}##|g" | \
		$(SED) "s|^\([^#.\$$\t][^=]\{1,\}\):[^=]\{0,\}\([[:space:]]##[[:space:]]\{1,\}\(.\{1,\}\)\)\?\$$|$(RANDOM_MARKER)  \1##$${Makefile#$(MAKE_PATH)/}##\3|g"; \
	done | \
		$(GREP) "^$(RANDOM_MARKER)" | \
		$(SED) "s|^$(RANDOM_MARKER)||g" | \
		sort -u | \
		column -t -s "##"
