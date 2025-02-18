.PHONY: clean tests build publish install

SHELL := $(shell command -v bash)
DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
export BASH_ENV := $(DIR).envrc
basename := $(shell basename $(DIR))
next := $(shell bin/semver next)
tmp_build := $(shell mktemp -d)
tmp_publish := $(shell mktemp -d)

clean:
	@rm -rf $(DIR)build
	@rm -rf $(DIR)/dist
	@rm -rf $(DIR)/*.egg-info
	@bin/bats.sh --clean

tests: clean
	@bin/bats.sh --tests

build: tests
	@git commit -a -m "$(next): build" || true
	@python3.9 -m build -o $(tmp_build) $(DIR)

publish: build
	@git tag $(next)
	@git push --quiet
	@git push --quiet --tags
	@python3.9 -m build -o $(tmp_publish) $(DIR)
	@twine upload $(tmp_publish)/*
	@PYTHONWARNINGS="ignore" python3.9 -m pip install --force-reinstall --quiet $(tmp_publish)/*.whl
	@python3 -m pip show bindev | awk '/^Version: / { print $2 }'

verbose: clean
	@bin/bats.sh --verbose

install-fix:
	@sleep 1
	@python3 -m pip download --quiet $(basename)==$(next) --no-binary :all: || true
	@python3 -m pip download --quiet $(basename)==$(next) --no-binary :all: || true
	@python3 -m pip install --quiet $(basename)-$(next).tar.gz
	@#curl -sL -o /dev/null --head --fail -H 'Cache-Control: no-cache' https://pypi.org/simple/bindev/?$(date +%s)
	@#PYTHONWARNINGS="ignore" python3 -m pip install -vvv --no-cache-dir --force-reinstall --upgrade --quiet $(basename)
	@python3 -m pip show bindev | awk '/^Version: / { print $2 }'
	@#curl -sL -o /dev/null --head --fail https://pypi.org/manage/project/$(basename)/release/$(next)
	@curl -sL -o /dev/null --head --fail https://pypi.org/simple/bindev/$(basename)-$(next)-py3-none-any.whl
	@curl -sL -o /dev/null --head --fail https://pypi.org/simple/bindev/$(basename)-$(next)-tar.gz

	@python3 -m pip cache --quiet remove $(basename)
	@PYTHONWARNINGS="ignore" python3 -m pip install -vvv --no-cache-dir --force-reinstall --upgrade --quiet $(basename)
