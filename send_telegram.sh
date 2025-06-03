#!/bin/bash

CONFIG_FILE="./config.json"

usage() {
  echo "Использование: $0 [--token TOKEN] [--chat_id CHAT_ID] [--message MESSAGE]"
  echo
  echo "Если параметры не заданы, значения берутся из $CONFIG_FILE"
  echo
  echo "Параметры:"
  echo "  --token TOKEN       Токен Telegram бота"
  echo "  --chat_id CHAT_ID   ID чата Telegram"
  echo "  --message MESSAGE   Текст сообщения для отправки (если не указан, будет запрос)"
  echo "  -h, --help          Показать это сообщение"
}

# Проверяем наличие jq
if ! command -v jq >/dev/null 2>&1; then
  echo "Ошибка: для работы скрипта требуется jq."
  echo "Установите jq: sudo apt install jq"
  exit 1
fi

# Проверяем наличие конфига
if [[ ! -f $CONFIG_FILE ]]; then
  echo "Ошибка: файл конфигурации $CONFIG_FILE не найден."
  exit 1
fi

# Читаем токен и чат айди из JSON
TOKEN=$(jq -r '.token // empty' "$CONFIG_FILE")
CHAT_ID=$(jq -r '.chat_id // empty' "$CONFIG_FILE")

MESSAGE=""

# Разбираем параметры командной строки
while [[ $# -gt 0 ]]; do
  case "$1" in
    --token)
      TOKEN="$2"
      shift 2
      ;;
    --chat_id)
      CHAT_ID="$2"
      shift 2
      ;;
    --message|-m)
      MESSAGE="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Неизвестный параметр: $1"
      usage
      exit 1
      ;;
  esac
done

# Проверяем, что токен и чат айди заданы
if [[ -z $TOKEN || -z $CHAT_ID ]]; then
  echo "Ошибка: не задан токен или chat_id."
  usage
  exit 1
fi

# Если сообщение не передано в параметре, запрашиваем его
if [[ -z $MESSAGE ]]; then
  echo "Введите текст сообщения:"
  read -r MESSAGE
fi

# Кодируем сообщение
ENCODED_MESSAGE=$(python3 -c "import urllib.parse; print(urllib.parse.quote('''$MESSAGE'''))")

# Отправляем сообщение и получаем ответ
RESPONSE=$(curl -s "https://api.telegram.org/bot$TOKEN/sendMessage?chat_id=$CHAT_ID&text=$ENCODED_MESSAGE")

# Проверяем ответ
OK=$(echo "$RESPONSE" | jq -r '.ok')
if [[ "$OK" == "true" ]]; then
  echo "Сообщение успешно отправлено!"
else
  DESCRIPTION=$(echo "$RESPONSE" | jq -r '.description // "нет описания ошибки"')
  echo "Ошибка отправки сообщения: $DESCRIPTION"
fi
