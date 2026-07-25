.PHONY: check
check:
	./tests/check.sh

.PHONY: install
install:
	./install.sh

.PHONY: install-dry-run
install-dry-run:
	./install.sh --dry-run
