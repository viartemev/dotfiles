# agents

Единая точка правды для конфигов кодинг-агентов: `pi`, `claude`, `codex`, `bb`.

## Как это работает

`install.sh` читает `links.txt` и создаёт симлинки:

| префикс в `links.txt` | куда попадает |
|---|---|
| `pi/...` | `~/.pi/agent/...` (или `$PI_CODING_AGENT_DIR`) |
| `claude/...` | `~/.claude/...` |
| `codex/...` | `~/.codex/...` |
| `bb/...` | `~/.bb/...` |

Файл в репозитории — это и есть живой конфиг машины. Правит ли его пользователь или
агент — правка уже в git. Каталоги линкуются целиком, поэтому новый файл навыка,
промпта или темы в git появляется сам, без правки манифеста.

## Команды

```bash
./scripts/agent-sync.sh status    # линки, расхождения, незакоммиченное
./scripts/agent-sync.sh capture   # затащить live-файлы в репо (для неслинкованных путей)
./scripts/agent-sync.sh sync      # capture + commit + rebase-pull + push
./scripts/agent-sync.sh check     # искать креденшелы в agents/
./scripts/agent-sync.sh add pi/themes   # начать шарить новый путь
```

`check` запускается и из `.git/hooks/pre-commit` (ставится `install.sh`), поэтому
коммит с токеном не пройдёт.

## Что сюда не кладут

Всё, что содержит креденшелы или описывает конкретную машину:

- `pi`: `auth.json`, `mcp.json`, `secrets/`, `sessions/`, `npm/`, `certs/`, `models-store.json`
- `claude`: `.credentials.json`, `settings.local.json`, `projects/`, `sessions/`, `history.jsonl`, `plugins/`, `skills/` (их синкает bb)
- `codex`: `auth.json`, `sessions/`, `history.jsonl`, `log/`, `models_cache.json`, `config.toml` (`[projects."/Users/..."]` trust-пути различаются между машинами)
- `bb`: `auth.json`, `auth-secret`, `bb.db*`, `plugins/`, `logs/`, `pi-bridge-sessions/`

Секреты, на которые ссылается конфиг, живут вне репозитория. Пример — ключ pi:

```json
"apiKey": "!cat ~/.pi/agent/secrets/explabs-api.key"
```

`capture` сам выносит литеральные ключи из `models.json` в `secrets/` и подставляет
такую ссылку.

## Вторая машина

```bash
cd ~/dotfiles && git pull && ./install.sh
```

Существующие файлы уедут в `*.backup-<дата>`, после чего их можно сравнить с
репозиторием и перенести то, чего в репо ещё нет:

```bash
diff ~/.claude/settings.json.backup-<дата> agents/claude/settings.json
```

Если на машине есть конфиг, которого в репозитории нет вообще, — `./scripts/agent-sync.sh add <tool>/<path>`,
затем `./install.sh`.
