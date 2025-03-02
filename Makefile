.PHONY: lint format syntax tests docs ci
STYLUA := stylua
NV_HEADLESS := nvim --headless
NV_TESTINIT := tests/init.lua
NV_PLENARYP := ~/.local/share/nvim/lazy/plenary.nvim
NV_PLENARYF := require('plenary.test_harness').test_directory
NV_TESTARGS := 'tests/', { minimal_init = '$(NV_TESTINIT)' }
NV_TESTSCMD := -c "lua $(NV_PLENARYF)($(NV_TESTARGS))"

# -------------------------------------------------------------------------------------------------
# Manual Targets
# -------------------------------------------------------------------------------------------------
lint:
	$(STYLUA) --check .
format:
	stylua .
syntax:
	find . -type f -name "*.lua" -exec luac -p {} +
docs:
	nvim --headless -c "luafile scripts/generate-docs.lua" -c "q"

# -------------------------------------------------------------------------------------------------
# Pipeline Targets (By Default, workflow dependent)
# -------------------------------------------------------------------------------------------------
tests:
	$(NV_HEADLESS) -u $(NV_TESTINIT) \
		-c "set rtp+=$(NV_PLENARYP)" \
		$(NV_TESTSCMD) \
		+qa

# -------------------------------------------------------------------------------------------------
# Pipeline
# -------------------------------------------------------------------------------------------------
ci: tests
