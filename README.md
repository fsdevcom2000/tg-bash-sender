## Telegram Sender — Reliable CLI Message Delivery Script

This script provides a **robust, production‑grade** way to send messages to a Telegram chat using the Bot API. It includes strict error handling, retry logic with exponential backoff, rate‑limit awareness, system logging, and execution locking to prevent concurrent runs.

## Features

- Strict Bash safety (`set -euo pipefail`, safe `IFS`)
    
- Reads configuration from `config.json`
    
- Command‑line overrides for token, chat ID, and message
    
- Supports message input from stdin
    
- Execution lock via `flock` to avoid concurrent runs
    
- Exponential backoff retry mechanism
    
- Handles Telegram rate limits (`429`)
    
- Retries only on network errors and 5xx responses
    
- System logging via `logger`
    
- Clear and deterministic error reporting

## Requirements

The following commands must be available:

- `curl`
    
- `jq`
    
- `flock`
    
- `logger`

## Configuration

Create a `config.json` file in the same directory:

```json
{
  "token": "YOUR_TELEGRAM_BOT_TOKEN",
  "chat_id": "YOUR_CHAT_ID"
}
```

Values can be overridden via CLI arguments.

## Usage


```bash
./telegram_sender.sh [--token TOKEN] [--chat_id CHAT_ID] [--message MESSAGE]
```

### Examples

Send a message using config.json:


```bash
./telegram_sender.sh --message "Hello from script"
```

Override token and chat ID:


```bash
./telegram_sender.sh --token ABC123 --chat_id 987654 --message "Custom config"
```

Send message from stdin:


```bash
echo "Hello world" | ./telegram_sender.sh
```

## Locking Behavior

The script uses:


```bash
/run/telegram_sender.lock
```

If another instance is running, the script logs a warning and exits without sending.

## Logging

All events are logged via `logger` under the tag:


```bash
telegram_sender
```

This allows integration with systemd‑journal or syslog.

## Exit Codes

- `0` — success
    
- `1` — configuration or runtime error
    
- `>1` — fatal API or HTTP error
    

## Reliability Notes

- Retries use exponential backoff: 2s → 4s → 8s → …
    
- Rate limits (`429`) respect Telegram’s `retry_after`
    
- Fatal errors stop execution immediately
    
- Network or 5xx errors trigger retries
    

## Telegram Sender — Надёжный CLI‑скрипт для отправки сообщений

Этот скрипт обеспечивает **максимально надёжную**, production‑ориентированную отправку сообщений в Telegram через Bot API. Он включает строгую обработку ошибок, экспоненциальный backoff, учёт rate‑limit, системное логирование и блокировку выполнения.

## Возможности

- Жёсткие настройки безопасности Bash (`set -euo pipefail`, безопасный `IFS`)
    
- Чтение конфигурации из `config.json`
    
- Переопределение токена, chat_id и сообщения через аргументы
    
- Поддержка ввода сообщения из stdin
    
- Блокировка выполнения через `flock`
    
- Повторные попытки с экспоненциальным увеличением задержки
    
- Обработка Telegram rate‑limit (`429`)
    
- Повтор только при сетевых ошибках и 5xx
    
- Логирование через `logger`
    
- Чёткие и предсказуемые ошибки
    

## Требования

Необходимы следующие утилиты:

- `curl`
    
- `jq`
    
- `flock`
    
- `logger`
    

## Конфигурация

Создайте файл `config.json`:


```json
{
  "token": "ВАШ_ТОКЕН_БОТА",
  "chat_id": "ВАШ_CHAT_ID"
}
```

Значения можно переопределить аргументами командной строки.

## Использование


```bash
./telegram_sender.sh [--token TOKEN] [--chat_id CHAT_ID] [--message MESSAGE]
```

### Примеры

Отправка сообщения с использованием config.json:


```
./telegram_sender.sh --message "Message from script"
```

Переопределение токена и chat_id:


```bash
./telegram_sender.sh --token ABC123 --chat_id 123456789 --message "My configuration"
```

Отправка сообщения через stdin:

```bash
echo "Hello" | ./telegram_sender.sh
```

## Блокировка выполнения

Используется файл:


```bash
/run/telegram_sender.lock
```

Если скрипт уже запущен, новый экземпляр завершится с предупреждением.

## Логирование

Все события пишутся через `logger` с тегом:


```bash
telegram_sender
```

Это позволяет интеграцию с systemd‑journal или syslog.

## Коды выхода

- `0` — успешно
    
- `1` — ошибка конфигурации или выполнения
    
- `>1` — фатальная ошибка API или HTTP
    

## Примечания по надёжности

- Повторы используют экспоненциальный backoff: 2s → 4s → 8s → …
    
- При `429` используется значение `retry_after`
    
- Фатальные ошибки завершают выполнение
    
- Сетевые ошибки и 5xx вызывают повтор
