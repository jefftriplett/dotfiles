.PHONY: check clean-pyc dotfiles facts homebrew install node python ruby osx nginx sublime

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-24s\033[0m %s\n", $$1, $$2}'

clean: clean-pyc ## clean up temporary files

clean-pyc: ## remove stray pyc files
	find . -name '*.pyc' -exec rm -f {} +
	find . -name '*.pyo' -exec rm -f {} +

check: ## run ansible checks
	ANSIBLE_NOCOWS=1 ansible-playbook -i hosts playbook.yml --check --diff -c local

deploy: ## push dotfiles to all the places
	git push origin master
	git push github master

facts: ## view ansible facts
	ANSIBLE_NOCOWS=1 ansible all -i hosts -m setup -c local

install: ## install everything
	ANSIBLE_NOCOWS=1 ansible-playbook -i hosts playbook.yml -c local --skip-tags sublime

# Tags

dotfiles: ## install dotfiles into home
	ANSIBLE_NOCOWS=1 ansible-playbook -i hosts playbook.yml -c local --tags dotfiles

homebrew: ## install homebrew packages
	ANSIBLE_NOCOWS=1 ansible-playbook -i hosts playbook.yml -c local --tags homebrew

homebrew-casks: ## install homebrew casks packages
	ANSIBLE_NOCOWS=1 ansible-playbook -i hosts playbook.yml -c local --tags homebrew-casks

nginx: ## install nginx reverse proxy
	ANSIBLE_NOCOWS=1 ansible-playbook -i hosts playbook.yml -c local --tags nginx

node: ## install node essentials
	ANSIBLE_NOCOWS=1 ansible-playbook -i hosts playbook.yml -c local --tags node

osx: ## install osx configs
	ANSIBLE_NOCOWS=1 ansible-playbook -i hosts playbook.yml -c local --tags osx

pipsi: ## install pipsi (python)
	ANSIBLE_NOCOWS=1 ansible-playbook -i hosts playbook.yml -c local --tags pipsi

pyenv: ## install pyenv (python)
	ANSIBLE_NOCOWS=1 ansible-playbook -i hosts playbook.yml -c local --tags pyenv

python: ## install python essentials
	ANSIBLE_NOCOWS=1 ansible-playbook -i hosts playbook.yml -c local --tags python

ruby: ## install ruby essentials
	ANSIBLE_NOCOWS=1 ansible-playbook -i hosts playbook.yml -c local --tags ruby

sublime: ## install sublimetext3 configs
	ANSIBLE_NOCOWS=1 ansible-playbook -i hosts playbook.yml -c local --tags sublime
