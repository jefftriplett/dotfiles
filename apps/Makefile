# OBJ = $(wildcard */Makefile)
SRCDIRS := $(shell find . -name 'Makefile' -exec dirname {} \; | uniq | sort)


define make-repo
	for dir in $(SRCDIRS); \
	do \
		echo $$dir; \
	done
endef


build:
	@$(call make-repo)
