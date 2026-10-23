PYTHON ?= python3

.PHONY: help setup run test
help:
	@echo 'make setup | make run | make test'
	@echo 'Python 3.11+ required; select it with make setup PYTHON=python3.12'

setup:
	@$(PYTHON) -c 'import sys; sys.exit("Python 3.11+ required. Retry make setup PYTHON=python3.12" if sys.version_info < (3,11) else 0)'
	$(PYTHON) -m venv .venv
	.venv/bin/python -m pip install -r requirements.txt

run:
	.venv/bin/python src/run.py

test:
	.venv/bin/python -m unittest discover -s tests
