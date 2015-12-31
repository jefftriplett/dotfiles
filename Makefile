.PHONY: check clean-pyc dotfiles facts homebrew install node python ruby

help:
	@echo "check - run ansible checks"
	@echo "facts - view ansible facts"
	@echo "install - install everything"
	@echo "dotfiles - install dotfiles into home"
	@echo "homebrew - install homebrew packages"
	@echo "node - install node essentials"
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
	ANSIBLE_NOCOWS=1 ansible-playbook -i hosts playbook.yml -c local

# Tags

dotfiles:
	ANSIBLE_NOCOWS=1 ansible-playbook -i hosts playbook.yml -c local --tags dotfiles

homebrew:
	ANSIBLE_NOCOWS=1 ansible-playbook -i hosts playbook.yml -c local --tags homebrew

node:
	ANSIBLE_NOCOWS=1 ansible-playbook -i hosts playbook.yml -c local --tags node

python:
	ANSIBLE_NOCOWS=1 ansible-playbook -i hosts playbook.yml -c local --tags python

ruby:
	ANSIBLE_NOCOWS=1 ansible-playbook -i hosts playbook.yml -c local --tags ruby
