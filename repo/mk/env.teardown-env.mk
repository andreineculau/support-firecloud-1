# ------------------------------------------------------------------------------

.PHONY: teardown-env
teardown-env: ## Teardown env
	$(GIT) diff --cached --exit-code --quiet || { \
		$(ECHO_ERR) "Unstage your changes before calling 'make teardown-env'."; \
		exit 1; \
	}
	$(GIT) commit --allow-empty -m "[sf teardown-$(ENV_NAME)]"
	$(GIT) push -f
