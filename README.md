# tg-bash-sender

Простой и удобный Bash-скрипт для отправки сообщений в Telegram через Bot API.  
A simple and convenient Bash script to send messages to Telegram via Bot API.

---

## Особенности / Features

- Чтение конфигурации из JSON-файла (`config.json`)  
  Reads configuration from a JSON file (`config.json`)
- Переопределение токена и chat_id через параметры командной строки  
  Override token and chat_id via command-line arguments
- Интерактивный ввод текста сообщения или передача сообщения сразу через параметр `--message`  
  Interactive message input or passing the message immediately via the `--message` parameter
- Проверка успешной отправки сообщения с помощью `jq`  
  Checks message sending success using `jq`
- Минимальные зависимости (требуется `curl`, `jq`, `python3`)  
  Minimal dependencies (`curl`, `jq`, `python3` required)

---

## Установка / Installation

1. Склонируйте репозиторий или скачайте скрипт:  
   Clone the repository or download the script:

   ```bash
   git clone https://github.com/fsdevcom2000/tg-bash-sender.git
   cd tg-bash-sender
   chmod +x send_telegram.sh
