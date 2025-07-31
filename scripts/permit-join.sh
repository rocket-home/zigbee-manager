#!/usr/bin/env bash

# Скрипт для управления permit_join через MQTT
# Использование: ./permit-join.sh [enable|disable|enable-temp <минуты>]

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Загрузка переменных окружения
if [ -f ../.env ]; then
    # Загружаем переменные, исключая системные
    while IFS='=' read -r key value; do
        # Пропускаем комментарии и пустые строки
        [[ $key =~ ^[[:space:]]*# ]] && continue
        [[ -z $key ]] && continue
        
        # Убираем пробелы в начале и конце
        key=$(echo "$key" | xargs)
        value=$(echo "$value" | xargs)
        
        # Пропускаем системные переменные
        [[ $key == "UID" ]] && continue
        [[ $key == "GID" ]] && continue
        
        # Экспортируем переменную
        export "$key=$value"
    done < ../.env
fi

# Настройки по умолчанию
MQTT_BASE_TOPIC="${MQTT_BASE_TOPIC:-zigbee2mqtt}"
MQTT_SERVER="${MQTT_SERVER:-mqtt://localhost:1883}"
MQTT_USER="${MQTT_USER:-}"
MQTT_PASSWORD="${MQTT_PASSWORD:-}"

# Функция для отправки MQTT команды
send_mqtt_command() {
    local topic="$1"
    local payload="$2"
    
    echo -e "${BLUE}📡 Отправка MQTT команды...${NC}"
    echo -e "${YELLOW}   Топик: $topic${NC}"
    echo -e "${YELLOW}   Команда: $payload${NC}"
    
    # Формируем команду mosquitto_pub
    local cmd="mosquitto_pub -h localhost -p 1883 -t '$topic' -m '$payload'"
    
    # Добавляем аутентификацию если указана
    if [ -n "$MQTT_USER" ]; then
        cmd="$cmd -u '$MQTT_USER'"
    fi
    
    if [ -n "$MQTT_PASSWORD" ]; then
        cmd="$cmd -P '$MQTT_PASSWORD'"
    fi
    
    # Выполняем команду
    if eval "$cmd"; then
        echo -e "${GREEN}✅ Команда отправлена успешно${NC}"
        return 0
    else
        echo -e "${RED}❌ Ошибка отправки команды${NC}"
        return 1
    fi
}

# Функция для проверки статуса permit_join
check_permit_join_status() {
    echo -e "${BLUE}🔍 Проверка текущего статуса permit_join...${NC}"
    
    # Подписываемся на топик и ждем ответ
    local topic="$MQTT_BASE_TOPIC/bridge/response/permit_join"
    local temp_file=$(mktemp)
    
    # Запускаем mosquitto_sub в фоне
    mosquitto_sub -h localhost -p 1883 -t "$topic" -C 1 > "$temp_file" &
    local sub_pid=$!
    
    # Ждем немного для подключения
    sleep 1
    
    # Запрашиваем статус
    send_mqtt_command "$MQTT_BASE_TOPIC/bridge/request/permit_join" "get" > /dev/null
    
    # Ждем ответ
    sleep 2
    
    # Останавливаем подписку
    kill $sub_pid 2>/dev/null || true
    
    # Читаем результат
    if [ -s "$temp_file" ]; then
        local status=$(cat "$temp_file")
        echo -e "${GREEN}📊 Текущий статус: $status${NC}"
        rm "$temp_file"
        return 0
    else
        echo -e "${YELLOW}⚠️  Не удалось получить статус${NC}"
        rm "$temp_file"
        return 1
    fi
}

# Основная логика
case "${1:-}" in
    "enable")
        echo -e "${BLUE}🔓 Включение permit_join...${NC}"
        send_mqtt_command "$MQTT_BASE_TOPIC/bridge/request/permit_join" "true"
        echo -e "${GREEN}✅ Permit join включен${NC}"
        echo -e "${YELLOW}💡 Устройства могут подключаться к сети${NC}"
        ;;
        
    "disable")
        echo -e "${BLUE}🔒 Выключение permit_join...${NC}"
        send_mqtt_command "$MQTT_BASE_TOPIC/bridge/request/permit_join" "false"
        echo -e "${GREEN}✅ Permit join выключен${NC}"
        echo -e "${YELLOW}💡 Устройства не могут подключаться к сети${NC}"
        ;;
        
    "enable-temp")
        if [ -z "$2" ]; then
            echo -e "${RED}❌ Ошибка: Не указано время в минутах${NC}"
            echo -e "${YELLOW}💡 Использование: $0 enable-temp <минуты>${NC}"
            echo -e "${BLUE}📋 Пример: $0 enable-temp 5${NC}"
            exit 1
        fi
        
        minutes="$2"
        echo -e "${BLUE}⏰ Включение permit_join на $minutes минут...${NC}"
        
        # Включаем permit_join
        send_mqtt_command "$MQTT_BASE_TOPIC/bridge/request/permit_join" "true"
        echo -e "${GREEN}✅ Permit join включен на $minutes минут${NC}"
        
        # Запускаем таймер для автоматического выключения
        (
            sleep $((minutes * 60))
            echo -e "${YELLOW}⏰ Автоматическое выключение permit_join...${NC}"
            send_mqtt_command "$MQTT_BASE_TOPIC/bridge/request/permit_join" "false" > /dev/null
            echo -e "${GREEN}✅ Permit join автоматически выключен${NC}"
        ) &
        
        echo -e "${YELLOW}💡 Устройства могут подключаться в течение $minutes минут${NC}"
        echo -e "${BLUE}💡 Permit join будет автоматически выключен через $minutes минут${NC}"
        ;;
        
    "status")
        check_permit_join_status
        ;;
        
    *)
        echo -e "${RED}❌ Ошибка: Неверная команда${NC}"
        echo -e "${YELLOW}💡 Использование: $0 [enable|disable|enable-temp <минуты>|status]${NC}"
        echo ""
        echo -e "${BLUE}📋 Доступные команды:${NC}"
        echo "   • enable        - Включить permit_join"
        echo "   • disable       - Выключить permit_join"
        echo "   • enable-temp N - Включить permit_join на N минут"
        echo "   • status        - Проверить текущий статус"
        echo ""
        echo -e "${BLUE}📋 Примеры:${NC}"
        echo "   • $0 enable"
        echo "   • $0 disable"
        echo "   • $0 enable-temp 5"
        echo "   • $0 status"
        exit 1
        ;;
esac 