SHELL := /bin/bash

.PHONY: install link brew check doctor git-config lock

install:
	./install.sh --brew

link:
	./install.sh

brew:
	brew bundle --file ./Brewfile

check:
	zsh -n ./.zshrc
	find ./.config/zsh -type f -name '*.zsh' -print0 | xargs -0 -n1 zsh -n
	brew bundle check --file ./Brewfile || true

doctor:
	./scripts/doctor.sh

git-config:
	./install.sh --skip-git-config && ./install.sh

lock:
	./scripts/update-brew-lock.sh
