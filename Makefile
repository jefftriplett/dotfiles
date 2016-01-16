.PHONY: check clean-pyc dotfiles facts homebrew install node python ruby osx nginx sublime

help:
	@echo "check - run ansible checks"
	@echo "facts - view ansible facts"
	@echo "dotfiles - install dotfiles into home"
	@echo "homebrew - install homebrew packages"
	@echo "install - install everything"
	@echo "node - install node essentials"
	@echo "osx - install osx configs"
	@echo "python - install python essentials"
	@echo "ruby - install ruby essentials"

clean: clean-pyc

clean-pyc:
	find . -name '*.pyc' -exec rm -f {} +
	find . -name '*.pyo' -exec rm -f {} +

check:
	ANSIBLE_NOCOWS=1 ansible-playbook -i hosts playbook.yml --check --diff -c local

facts:
	ANSIBLE_NOCOWS=1 ansible all -i hosts -m setup -c local

install:
	ANSIBLE_NOCOWS=1 ansible-playbook -i hosts playbook.yml -c local --skip-tags sublime

# Tags

dotfiles:
	ANSIBLE_NOCOWS=1 ansible-playbook -i hosts playbook.yml -c local --tags dotfiles

homebrew:
	ANSIBLE_NOCOWS=1 ansible-playbook -i hosts playbook.yml -c local --tags homebrew

nginx:
	ANSIBLE_NOCOWS=1 ansible-playbook -i hosts playbook.yml -c local --tags nginx

node:
	ANSIBLE_NOCOWS=1 ansible-playbook -i hosts playbook.yml -c local --tags node

osx:
	ANSIBLE_NOCOWS=1 ansible-playbook -i hosts playbook.yml -c local --tags osx -vvv

python:
	ANSIBLE_NOCOWS=1 ansible-playbook -i hosts playbook.yml -c local --tags python

ruby:
	ANSIBLE_NOCOWS=1 ansible-playbook -i hosts playbook.yml -c local --tags ruby

sublime:
	ANSIBLE_NOCOWS=1 ansible-playbook -i hosts playbook.yml -c local --tags sublime
