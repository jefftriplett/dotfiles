.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-24s\033[0m %s\n", $$1, $$2}'

.PHONY: bootstrap
bootstrap: ## install pre-dependencies needed to install everything
	PIP_REQUIRE_VIRTUALENV=false pip install -U -r requirements.txt
	pipx install ansible
	ansible-galaxy install -r requirements.yml

.PHONY: clean
clean: clean-pyc ## clean up temporary files

.PHONY: clean-pyc
clean-pyc: ## remove stray pyc files
	find . -name '*.pyc' -exec rm -f {} +
	find . -name '*.pyo' -exec rm -f {} +

.PHONY: check
check: ## run ansible checks
	ANSIBLE_NOCOWS=1 ansible-playbook -i ./playbooks/hosts ./playbooks/main.yml --check --diff -c local

.PHONY: deploy
deploy: ## push dotfiles to all the places
	git push origin master
	git push github master

.PHONY: facts
facts: ## view ansible facts
	ANSIBLE_NOCOWS=1 ansible all -i ./playbooks/hosts -m setup -c local

.PHONY: install
install: ## install everything
	ANSIBLE_NOCOWS=1 ansible-playbook -i ./playbooks/hosts ./playbooks/main.yml -c local --skip-tags sublime

# Tags

.PHONY: dotfiles
dotfiles: ## install dotfiles into home
	ANSIBLE_NOCOWS=1 ansible-playbook -i ./playbooks/hosts ./playbooks/main.yml -c local --tags dotfiles

.PHONY: homebrew
homebrew: ## install homebrew packages
	ANSIBLE_NOCOWS=1 ansible-playbook -i ./playbooks/hosts ./playbooks/main.yml -c local --tags homebrew

.PHONY: homebrew-casks
homebrew-casks: ## install homebrew casks packages
	ANSIBLE_NOCOWS=1 ansible-playbook -i ./playbooks/hosts ./playbooks/main.yml -c local --tags homebrew-casks

.PHONY: mas
mas: ## install Mapp App Store packages
	ANSIBLE_NOCOWS=1 ansible-playbook -i ./playbooks/hosts ./playbooks/main.yml -c local --tags mas

.PHONY: nginx
nginx: ## install nginx reverse proxy
	ANSIBLE_NOCOWS=1 ansible-playbook -i ./playbooks/hosts ./playbooks/main.yml -c local --tags nginx

.PHONY: node
node: ## install node essentials
	ANSIBLE_NOCOWS=1 ansible-playbook -i ./playbooks/hosts ./playbooks/main.yml -c local --tags node

.PHONY: osx
osx: ## install osx configs
	ANSIBLE_NOCOWS=1 ansible-playbook -i ./playbooks/hosts ./playbooks/main.yml -c local --tags osx

.PHONY: pipx
pipx: ## install pipx (python)
	ANSIBLE_NOCOWS=1 ansible-playbook -i ./playbooks/hosts ./playbooks/main.yml -c local --tags pipx

.PHONY: pyenv
pyenv: ## install pyenv (python)
	ANSIBLE_NOCOWS=1 ansible-playbook -i ./playbooks/hosts ./playbooks/main.yml -c local --tags pyenv

.PHONY: python
python: ## install python essentials
	ANSIBLE_NOCOWS=1 ansible-playbook -i ./playbooks/hosts ./playbooks/main.yml -c local --tags python

.PHONY: python_deps
python_deps: ## install python system dependencies
	ANSIBLE_NOCOWS=1 ansible-playbook -i ./playbooks/hosts ./playbooks/main.yml -c local --tags python_deps

.PHONY: ruby
ruby: ## install ruby essentials
	ANSIBLE_NOCOWS=1 ansible-playbook -i ./playbooks/hosts ./playbooks/main.yml -c local --tags ruby

.PHONY: shellcheck
shellcheck:
	shellcheck

.PHONY: sublime
sublime: ## install sublimetext3 configs
	ANSIBLE_NOCOWS=1 ansible-playbook -i ./playbooks/hosts ./playbooks/main.yml -c local --tags sublime
