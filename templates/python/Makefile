PYTHON ?= python3
PYTHONPATH := src
export PYTHONPATH

.PHONY: run
run:
	$(PYTHON) -m app

.PHONY: check
check:
	$(PYTHON) -m compileall -q src tests
	$(PYTHON) -m unittest discover -s tests

.PHONY: clean
clean:
	find . -type d -name __pycache__ -prune -exec rm -rf {} +
