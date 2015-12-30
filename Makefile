
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
