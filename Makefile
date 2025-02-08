.PHONY: lint format syntax test ci
STYLUA := stylua

# Manual Targets
lint:
	$(STYLUA) --check .
format:
	stylua .
syntax:
	find lua -name "*.lua" -exec luac -p {} +

# Keep pipeline simple, only run tests
test:
	nvim --headless -u tests/init.lua \
		-c "set rtp+=~/.local/share/nvim/lazy/plenary.nvim" \
		-c "lua require('plenary.test_harness').test_directory('tests/', { minimal_init = 'tests/init.lua' })" \
		+qa
ci: test
