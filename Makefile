SHELL := /bin/bash

.PHONY: install link brew macos check doctor lock bootstrap sync sync-status sync-check

install:
	./install.sh --brew

link:
	./install.sh

brew:
	brew bundle --file ./Brewfile

macos:
	./scripts/macos-defaults.sh

bootstrap: install macos

check:
	zsh -n ./.zshrc
	find ./.config/zsh -type f -name '*.zsh' -print0 | xargs -0 -n1 zsh -n
	bash -n ./install.sh
	find ./scripts -type f -name '*.sh' -print0 | xargs -0 -n1 bash -n
	brew bundle check --file ./Brewfile || true

doctor:
	./scripts/doctor.sh

sync:
	./scripts/agent-sync.sh sync

sync-status:
	./scripts/agent-sync.sh status

sync-check:
	./scripts/agent-sync.sh check

lock:
	./scripts/update-brew-lock.sh
