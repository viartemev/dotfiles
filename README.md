# dotfiles-zsh

Мой модульный zsh-конфиг для macOS.

## Что внутри

- быстрый `compinit` с кэшем
- `zoxide` + `cd='z'`
- `fzf` + `fd` + `bat` интеграции
- `atuin` для продвинутой истории
- `direnv` для project-local env
- `mise` как единый version manager
- git-алиасы + `delta` для красивых diff
- `lazygit`, `dust`, `duf`, `btop`, `tldr`
- функции:
  - `vf` — выбрать файл через `fzf` и открыть в editor
  - `cdf` — выбрать директорию и перейти в неё
  - `rgv <query>` — найти через `rg` и открыть в editor на нужной строке
  - `gbr` — выбрать git-ветку через `fzf`
  - `mkcd`, `extract`, `backup`, `profile_zsh_startup`

## Структура

```text
.zshrc
.zshrc.local.example
.config/
  starship.toml
  zsh/
    options.zsh
    env.zsh
    completion.zsh
    aliases.zsh
    functions.zsh
    integrations.zsh
    prompt.zsh
Brewfile
```

## Установка

### Вариант 1: просто скопировать

Скопируй файлы в `$HOME`.

### Вариант 2: через symlink

```bash
ln -sf "$PWD/.zshrc" ~/.zshrc
mkdir -p ~/.config
ln -snf "$PWD/.config/zsh" ~/.config/zsh
ln -sf "$PWD/.config/starship.toml" ~/.config/starship.toml
cp .zshrc.local.example ~/.zshrc.local
source ~/.zshrc
```

## Локальные настройки

Локальные, машинно-специфичные вещи держи в `~/.zshrc.local`.
Этот файл в репозиторий не коммитится.

## Инструменты

Основные утилиты можно поставить через Homebrew:

```bash
brew bundle --file Brewfile
```
