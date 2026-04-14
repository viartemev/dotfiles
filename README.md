# dotfiles-zsh

Быстрый, модульный и удобный набор `zsh + tmux` конфигов для macOS с упором на ежедневную разработку.

> Навигация через `zoxide`, поиск через `fzf + fd + rg`, история через `atuin`, project env через `direnv`, версии тулов через `mise`, красивые git diff через `delta`.

## Возможности

### Shell UX
- быстрый `compinit` с кэшем
- модульная структура конфига
- аккуратный `starship` prompt:
  - короткая директория
  - `git branch`
  - `git status`
- `zsh-autosuggestions`
- `zsh-syntax-highlighting`
- `zoxide` + привычный `cd='z'`

### Поиск и навигация
- `fzf` интеграции
- `fd` для поиска файлов и директорий
- `rg` для быстрого поиска по проекту
- `bat` preview внутри `fzf`
- `eza` для удобного `ls`

### Git workflow
- `git-delta` как глобальный pager для `git diff`, `show`, `log -p`
- глобальные git aliases
- `lazygit`
- `gbr` для переключения веток через `fzf`

### Environment / toolchain
- `atuin` для нормальной shell history
- `direnv` для project-local env
- `mise` как единый version manager
- fallback на `pyenv` / `fnm`, если `mise` не установлен

### Utility stack
- `btop`
- `dust`
- `duf`
- `tlrc`

### tmux
- единый `~/.tmux.conf` в репозитории
- привычная навигация `hjkl`
- сплиты/окна наследуют текущую директорию
- `tmux-resurrect + tmux-continuum`
- reload конфига через `prefix + r`

---

## Быстрые команды

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
| `tl <cmd>` | быстрые примеры по команде |
| `space` | показать, что занимает место на диске (`dust`) |
| `disk` | usage по файловым системам (`duf`) |
| `top` | открыть `btop` |
| `profile_zsh_startup` | профилировать startup `zsh` |
| `mkcd foo/bar` | создать директорию и зайти в неё |
| `extract file.tar.gz` | распаковать архив |
| `backup path` | создать timestamp backup |

---

## Git aliases

После установки доступны глобальные git aliases:

| Alias | Команда |
|---|---|
| `git st` | `git status -sb` |
| `git co` | `git checkout` |
| `git sw` | `git switch` |
| `git br` | `git branch` |
| `git ci` | `git commit` |
| `git ca` | `git commit --amend` |
| `git last` | `git log -1 HEAD --stat` |
| `git lg` | `git log --graph --decorate --oneline --all` |
| `git unstage` | `git restore --staged --` |
| `git discard` | `git restore --` |

---

## Структура

```text
.zshrc
.zshrc.local.example
.tmux.conf
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
Brewfile.lock.json
Makefile
install.sh
scripts/
  doctor.sh
  update-brew-lock.sh
```

---

## Установка

### 1. Клонировать репозиторий

```bash
git clone git@github.com:viartemev/dotfiles-zsh.git ~/dotfiles-zsh
cd ~/dotfiles-zsh
```

### 2. Установить всё одной командой

```bash
make install
```

Это эквивалентно:

```bash
./install.sh --brew
```

Скрипт:
- поставит зависимости из `Brewfile`
- сделает backup существующих файлов
- создаст symlink'и на `.zshrc`, `.config/zsh`, `starship.toml`, `.tmux.conf`
- создаст `~/.zshrc.local`, если его ещё нет
- настроит глобальный `git + delta + aliases`

### 3. Активировать конфиг

```bash
source ~/.zshrc
```

Если используешь tmux-плагины через TPM, внутри tmux один раз нажми:

```text
prefix + I
```

### 4. Импортировать историю в Atuin

```bash
atuin import auto
```

### 5. Для project-local env

```bash
direnv allow
```

---

## Make targets

| Команда | Что делает |
|---|---|
| `make install` | ставит brew-зависимости и разворачивает конфиг |
| `make link` | только symlink'и и git config, без brew install |
| `make brew` | ставит зависимости из `Brewfile` |
| `make check` | проверяет синтаксис zsh-конфигов и Brewfile |
| `make doctor` | запускает полную проверку окружения |
| `make lock` | обновляет `Brewfile.lock.json` |

---

## Doctor / checks

Проверить, что всё настроено корректно:

```bash
make doctor
```

Скрипт проверяет:
- symlink'и, включая `.tmux.conf`
- синтаксис `.zshrc` и модулей
- наличие инструментов из `Brewfile`
- ключевые глобальные git-настройки

---

## Brewfile lock

Для снапшота текущих версий Homebrew-пакетов используется:

```bash
make lock
```

Это обновляет `Brewfile.lock.json` через `brew info --json=v2` по формулам из `Brewfile`.

---

## Глобальный git + delta

`install.sh` автоматически включает красивые diff глобально. После этого:

- `git diff`
- `git show`
- `git log -p`

идут через `delta` по умолчанию.

Дополнительно настраиваются:
- side-by-side diff
- line numbers
- навигация по diff
- более аккуратные file / hunk / commit decorations
- `merge.conflictstyle = zdiff3`
- `diff.colorMoved = default`

---

## Локальные настройки

Всё машинно-специфичное и приватное держи в:

```bash
~/.zshrc.local
```

Например:
- рабочие autocomplete-скрипты
- PATH для внутренних тулов
- секретные env
- локальные alias/function overrides

---

## Полезный workflow

### Найти файл и открыть

```bash
vf
```

### Найти строку в проекте и сразу прыгнуть в редактор

```bash
rgv "TODO"
rgv "NewServer"
```

### Переключить ветку через fuzzy finder

```bash
gbr
```

### Выбрать commit и посмотреть его

```bash
glogf
```

### Сделать fixup commit для autosquash workflow

```bash
gfixup
```

### Открыть изменённый файл из git status

```bash
gcf
```

### Посмотреть красивые diff

```bash
git diff
git show
git st
git lg
```

### Проверить, что машина настроена правильно

```bash
make doctor
```

### Обновить lock-файл brew-пакетов

```bash
make lock
```

---

## Зависимости

Основной стек из `Brewfile`:

- `atuin`
- `bat`
- `btop`
- `direnv`
- `duf`
- `dust`
- `eza`
- `fd`
- `fzf`
- `git-delta`
- `lazygit`
- `mise`
- `ripgrep`
- `starship`
- `tlrc`
- `zoxide`

---

## Идея конфига

Этот конфиг не пытается быть огромным фреймворком. Цель — дать:
- быстрый shell startup
- удобную навигацию по проектам
- быстрый поиск по коду
- приятный git UX
- хороший bootstrap для новой машины
- минимальный, но мощный набор команд на каждый день

Если хочется машинно-специфичных доработок — они живут в `~/.zshrc.local`, а основной конфиг остаётся чистым и переносимым.
