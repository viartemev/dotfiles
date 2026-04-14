# dotfiles

Универсальные `dotfiles` для macOS: `zsh`, `tmux`, `git`, `starship`, Homebrew bootstrap и базовые macOS defaults для ежедневной разработки.

> Навигация через `zoxide`, поиск через `fzf + fd + rg`, история через `atuin`, project env через `direnv`, версии тулов через `mise`, fallback на `fnm`, красивые git diff через `delta`.

## Что внутри

### Shell UX
- модульный `zsh`-конфиг
- быстрый `compinit` с кэшем
- `starship` prompt
- `zoxide`, `fzf`, `fd`, `rg`, `bat`, `eza`
- `atuin` history
- `direnv`
- `mise` + fallback на `fnm`

### Git
- file-based `~/.gitconfig` из репозитория
- `delta` для `git diff/show/log -p`
- полезные aliases
- глобальный ignore-файл
- приватные настройки в `~/.gitconfig.local`

### tmux
- единый `~/.tmux.conf`
- `hjkl`-навигация по pane
- сплиты и окна наследуют cwd
- `tmux-resurrect + tmux-continuum`

### Bootstrap
- `Brewfile` для установки основного toolchain
- `install.sh` для symlink'ов и локальных шаблонов
- `scripts/macos-defaults.sh` для opt-in macOS defaults
- `scripts/doctor.sh` для проверки окружения

---

## Структура

```text
.gitconfig
.gitconfig.local.example
.tmux.conf
.zshrc
.zshrc.local.example
.config/
  git/
    ignore
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
Brewfile.lock.json
Makefile
install.sh
scripts/
  doctor.sh
  macos-defaults.sh
  update-brew-lock.sh
```

---

## Установка

### 1. Клонировать репозиторий

```bash
git clone git@github.com:viartemev/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

### 2. Развернуть конфиги

```bash
make install
```

Это эквивалентно:

```bash
./install.sh --brew
```

Скрипт:
- установит зависимости из `Brewfile`
- сделает backup существующих файлов
- создаст symlink'и на `.zshrc`, `.tmux.conf`, `.gitconfig`, `~/.config/zsh`, `starship.toml`, `~/.config/git/ignore`
- создаст `~/.zshrc.local` и `~/.gitconfig.local`, если их ещё нет

### 3. Заполнить приватные Git-настройки

Открой и отредактируй:

```bash
$EDITOR ~/.gitconfig.local
```

Минимум, что стоит заполнить:

```ini
[user]
    name = Your Name
    email = you@example.com
```

### 4. Активировать shell-конфиг

```bash
source ~/.zshrc
```

### 5. Установить tmux-плагины

Внутри tmux один раз нажми:

```text
prefix + I
```

### 6. Опционально применить macOS defaults

```bash
make macos
```

Скрипт включает:
- показ расширений файлов
- path/status bar в Finder
- быстрый key repeat
- autohide Dock
- отключение recent apps в Dock

---

## Make targets

| Команда | Что делает |
|---|---|
| `make install` | ставит brew-зависимости и разворачивает конфиги |
| `make link` | только symlink'и и локальные шаблоны |
| `make brew` | ставит зависимости из `Brewfile` |
| `make macos` | применяет macOS defaults |
| `make bootstrap` | `make install && make macos` |
| `make check` | проверяет синтаксис конфигов и скриптов |
| `make doctor` | запускает полную проверку окружения |
| `make lock` | обновляет `Brewfile.lock.json` |

---

## Doctor / checks

```bash
make doctor
```

Проверяет:
- symlink'и
- наличие локальных файлов `~/.zshrc.local` и `~/.gitconfig.local`
- синтаксис `zsh`/`bash` файлов
- наличие инструментов из `Brewfile`
- ключевые git-настройки
- доступность `node/npm` в текущем shell

---

## Brewfile

Основной стек:

- `atuin`
- `bat`
- `btop`
- `direnv`
- `duf`
- `dust`
- `eza`
- `fd`
- `fnm`
- `fzf`
- `git-delta`
- `lazygit`
- `mise`
- `ripgrep`
- `starship`
- `tlrc`
- `tmux`
- `zoxide`

---

## Полезные команды

| Команда | Что делает |
|---|---|
| `vf` | выбрать файл через `fzf` и открыть в `$EDITOR` |
| `cdf` | выбрать директорию через `fzf` и перейти в неё |
| `rgv <query>` | найти в проекте через `rg` и открыть результат в редакторе |
| `gbr` | выбрать git-ветку через `fzf` |
| `glogf` | выбрать commit через `fzf` и показать его |
| `gfixup` | выбрать commit и создать `fixup!` commit |
| `gcf` | выбрать изменённый файл через `fzf` и открыть в редакторе |
| `lg` | открыть `lazygit` |
| `profile_zsh_startup` | профилировать startup `zsh` |
| `mkcd foo/bar` | создать директорию и зайти в неё |
| `extract file.tar.gz` | распаковать архив |
| `backup path` | создать timestamp backup |

---

## Идея

Репозиторий остаётся переносимым:
- общий, versioned конфиг живёт в репо
- приватное и машинно-специфичное — в `~/.zshrc.local` и `~/.gitconfig.local`
- bootstrap новой машины — через `make install`, `make macos`, `make doctor`
