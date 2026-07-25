PYTHON ?= python3
PYTHONPATH := src
export PYTHONPATH

.PHONY: run
run:
	$(PYTHON) -m app

.PHONY: check
check:
	$(PYTHON) -c 'import sys; assert sys.version_info >= (3, 11), "Python 3.11 or newer is required"'
	$(PYTHON) -m compileall -q src tests
	$(PYTHON) -m unittest discover -s tests

.PHONY: clean
clean:
	find . -type d -name __pycache__ -prune -exec rm -rf {} +
