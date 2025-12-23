TESTS_INIT=tests/plenary_testrc.lua
TESTS_DIR=tests/

.PHONY: test

# NOTE: deprecated: use `mise test` (or `mise test:plenary`) instead
test:
	@nvim \
		--headless \
		--noplugin \
		-u ${TESTS_INIT} \
		-c "PlenaryBustedDirectory ${TESTS_DIR} { minimal_init = '${TESTS_INIT}' }"
