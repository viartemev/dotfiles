# dotfiles-zsh

Быстрый, модульный и удобный `zsh`-конфиг для macOS с упором на повседневную разработку.

> Навигация через `zoxide`, поиск через `fzf + fd + rg`, история через `atuin`, project env через `direnv`, версии тулов через `mise`, красивые git diff через `delta`.

## Что умеет

### Shell UX
- быстрый `compinit` с кэшем
- модульная структура конфига
- `starship` prompt
- `zsh-autosuggestions`
- `zsh-syntax-highlighting`
- `zoxide` + привычный `cd='z'`

### Поиск и навигация
- `fzf` интеграции
- `fd` для быстрого поиска файлов и директорий
- `rg` для быстрого поиска по коду
- `bat` preview внутри `fzf`
- `eza` для удобного `ls`

### Git workflow
- `git-delta` как глобальный pager для `git diff`, `show`, `log`
- `lazygit`
- git aliases для повседневных операций
- `gbr` для переключения веток через `fzf`

### Environment / toolchain
- `atuin` для нормальной истории команд
- `direnv` для проектных env
- `mise` как единый version manager
- fallback на `pyenv` / `fnm`, если `mise` не установлен

### Utility stack
- `btop`
- `dust`
- `duf`
- `tlrc` / `tldr`

---

## Быстрые команды

| Команда | Что делает |
|---|---|
| `vf` | выбрать файл через `fzf` и открыть в `$EDITOR` |
| `cdf` | выбрать директорию через `fzf` и перейти в неё |
| `rgv <query>` | найти в проекте через `rg` и открыть результат в редакторе |
| `gbr` | выбрать git-ветку через `fzf` |
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
install.sh
```

---

## Установка

### 1. Клонировать репозиторий

```bash
git clone git@github.com:viartemev/dotfiles-zsh.git ~/dotfiles-zsh
cd ~/dotfiles-zsh
```

### 2. Запустить установку

```bash
./install.sh --brew
```

Скрипт:
- поставит зависимости из `Brewfile`
- сделает backup существующих файлов
- создаст symlink'и на `.zshrc`, `.config/zsh`, `starship.toml`
- создаст `~/.zshrc.local`, если его ещё нет
- настроит глобальный `git + delta`

### 3. Активировать конфиг

```bash
source ~/.zshrc
```

### 4. Донастроить историю

```bash
atuin import auto
```

### 5. Для project-local env

```bash
direnv allow
```

---

## Глобальный git + delta

`install.sh` автоматически включает красивые diff глобально. После этого:

- `git diff`
- `git show`
- `git log -p`

будут открываться через `delta` по умолчанию.

Текущие глобальные настройки включают:
- `core.pager = delta`
- `interactive.diffFilter = delta --color-only`
- `delta.navigate = true`
- `delta.side-by-side = true`
- `delta.line-numbers = true`
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

### Посмотреть красивые diff

```bash
git diff
git show
```

### Посмотреть, что сжирает место

```bash
space
disk
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
- минимальный, но мощный набор команд на каждый день

Если хочется машинно-специфичных доработок — они живут в `~/.zshrc.local`, а основной конфиг остаётся чистым и переносимым.
