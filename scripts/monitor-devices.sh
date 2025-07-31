#!/usr/bin/env bash

# Скрипт для мониторинга логов присоединения устройств
# Использование: ./monitor-devices.sh [options]

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Загрузка переменных окружения
if [ -f ../.env ]; then
    export $(grep -v '^#' ../.env | xargs)
fi

# Настройки по умолчанию
MQTT_BASE_TOPIC="${MQTT_BASE_TOPIC:-zigbee2mqtt}"
MQTT_SERVER="${MQTT_SERVER:-mqtt://localhost:1883}"
MQTT_USER="${MQTT_USER:-}"
MQTT_PASSWORD="${MQTT_PASSWORD:-}"

# Переменные для фильтрации
FILTER_DEVICES="${FILTER_DEVICES:-}"
SHOW_ALL="${SHOW_ALL:-false}"

# Функция для вывода справки
show_help() {
    echo -e "${BLUE}📡 Мониторинг присоединения устройств${NC}"
    echo ""
    echo -e "${YELLOW}💡 Использование: $0 [опции]${NC}"
    echo ""
    echo -e "${BLUE}📋 Опции:${NC}"
    echo "   -h, --help              Показать эту справку"
    echo "   -f, --filter PATTERN    Фильтровать сообщения по паттерну"
    echo "   -a, --all               Показать все сообщения (не только устройства)"

    echo "   -v, --verbose           Подробный вывод"
    echo ""
    echo -e "${BLUE}📋 Примеры:${NC}"
echo "   $0                      # Мониторинг только устройств"
echo "   $0 -a                   # Мониторинг всех сообщений"
echo "   $0 -f 'sensor'          # Фильтр по слову 'sensor'"
echo "   $0 -f 'join,left'       # Фильтр по нескольким словам"
echo "   $0 -f '+join,-error'    # Включить 'join', исключить 'error'"
echo "   $0 -f '-permit'         # Исключить все с 'permit'"

    echo ""
    echo -e "${BLUE}📋 Мониторимые топики:${NC}"
    echo "   • $MQTT_BASE_TOPIC/bridge/log     - Логи Zigbee2MQTT"
    echo "   • $MQTT_BASE_TOPIC/bridge/event   - События (подключение/отключение)"
    echo "   • $MQTT_BASE_TOPIC/bridge/response - Ответы на команды"
    echo ""
    echo -e "${YELLOW}💡 Для остановки нажмите Ctrl+C${NC}"
}

# Функция для форматирования времени
format_time() {
    date '+%H:%M:%S'
}

# Функция для обработки сообщений
process_message() {
    local topic="$1"
    local message="$2"
    local timestamp=$(format_time)
    
    # Сначала проверяем permit_join во всех сообщениях
    if echo "$message" | grep -qi "permit_join"; then
        if echo "$message" | grep -qi "true\|enabled\|on"; then
            echo -e "${GREEN}[$timestamp] 🔓 PERMIT JOIN ВКЛЮЧЕН${NC}"
            echo -e "${GREEN}   📡 $topic: $message${NC}"
        elif echo "$message" | grep -qi "false\|disabled\|off"; then
            echo -e "${YELLOW}[$timestamp] 🔒 PERMIT JOIN ВЫКЛЮЧЕН${NC}"
            echo -e "${YELLOW}   📡 $topic: $message${NC}"
        else
            echo -e "${CYAN}[$timestamp] 🔐 Permit join статус: $message${NC}"
            echo -e "${CYAN}   📡 $topic: $message${NC}"
        fi
        return
    fi
    
    # Определяем тип сообщения по топику
    case "$topic" in
        *"/bridge/log")
            # Логи Zigbee2MQTT
            if echo "$message" | grep -q "device"; then
                echo -e "${GREEN}[$timestamp] 📱 Устройство: $message${NC}"
            elif echo "$message" | grep -q "join\|joined"; then
                echo -e "${CYAN}[$timestamp] 🔗 Подключение: $message${NC}"
            elif echo "$message" | grep -q "leave\|left"; then
                echo -e "${YELLOW}[$timestamp] 🔌 Отключение: $message${NC}"
            elif echo "$message" | grep -q "error\|failed"; then
                echo -e "${RED}[$timestamp] ❌ Ошибка: $message${NC}"
            else
                if [ "$SHOW_ALL" = "true" ]; then
                    echo -e "${BLUE}[$timestamp] 📋 Лог: $message${NC}"
                fi
            fi
            ;;
            
        *"/bridge/event")
            # События
            if echo "$message" | grep -q "device_joined"; then
                echo -e "${GREEN}[$timestamp] 🎉 НОВОЕ УСТРОЙСТВО ПОДКЛЮЧЕНО!${NC}"
                echo -e "${GREEN}   📱 Детали: $message${NC}"
            elif echo "$message" | grep -q "device_left"; then
                echo -e "${YELLOW}[$timestamp] 👋 Устройство отключено${NC}"
                echo -e "${YELLOW}   📱 Детали: $message${NC}"
            elif echo "$message" | grep -q "device_announce"; then
                echo -e "${CYAN}[$timestamp] 📢 Объявление устройства${NC}"
                echo -e "${CYAN}   📱 Детали: $message${NC}"
            else
                if [ "$SHOW_ALL" = "true" ]; then
                    echo -e "${BLUE}[$timestamp] 📡 Событие: $message${NC}"
                fi
            fi
            ;;
            
        *"/bridge/response")
            # Ответы на команды
            if [ "$SHOW_ALL" = "true" ]; then
                echo -e "${BLUE}[$timestamp] 📤 Ответ: $message${NC}"
            fi
            ;;
            
        *)
            # Другие топики
            if [ "$SHOW_ALL" = "true" ]; then
                echo -e "${BLUE}[$timestamp] 📡 $topic: $message${NC}"
            fi
            ;;
    esac
}

# Функция для фильтрации сообщений
filter_message() {
    local message="$1"
    
    # Если фильтр не задан, показываем все
    if [ -z "$FILTER_DEVICES" ]; then
        return 0
    fi
    
    # Разделяем фильтр на включения и исключения
    local include_patterns=""
    local exclude_patterns=""
    
    # Парсим фильтр: +pattern для включения, -pattern для исключения
    IFS=',' read -ra FILTER_PARTS <<< "$FILTER_DEVICES"
    for pattern in "${FILTER_PARTS[@]}"; do
        pattern=$(echo "$pattern" | xargs) # Убираем пробелы
        if [[ "$pattern" == -* ]]; then
            # Исключение (начинается с -)
            exclude_patterns="$exclude_patterns|${pattern#-}"
        else
            # Включение (начинается с + или без префикса)
            if [[ "$pattern" == +* ]]; then
                pattern="${pattern#+}"
            fi
            include_patterns="$include_patterns|$pattern"
        fi
    done
    
    # Убираем лишний | в начале
    include_patterns="${include_patterns#|}"
    exclude_patterns="${exclude_patterns#|}"
    
    # Проверяем исключения (если есть)
    if [ -n "$exclude_patterns" ]; then
        if echo "$message" | grep -qiE "$exclude_patterns"; then
            return 1 # Исключаем
        fi
    fi
    
    # Проверяем включения (если есть)
    if [ -n "$include_patterns" ]; then
        if echo "$message" | grep -qiE "$include_patterns"; then
            return 0 # Включаем
        else
            return 1 # Не включаем
        fi
    fi
    
    # Если нет включений, но есть исключения - показываем все, кроме исключенных
    if [ -n "$exclude_patterns" ] && [ -z "$include_patterns" ]; then
        return 0
    fi
    
    # Если нет ни включений, ни исключений - показываем все
    return 0
}

# Парсинг аргументов
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -f|--filter)
            FILTER_DEVICES="$2"
            shift 2
            ;;
        -a|--all)
            SHOW_ALL="true"
            shift
            ;;

        -v|--verbose)
            set -x
            shift
            ;;
        *)
            echo -e "${RED}❌ Неизвестная опция: $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

# Проверка подключения к MQTT
echo -e "${BLUE}🔍 Проверка подключения к MQTT...${NC}"
if ! mosquitto_pub -h localhost -p 1883 -t "test/connection" -m "test" >/dev/null 2>&1; then
    echo -e "${RED}❌ Не удается подключиться к MQTT брокеру${NC}"
    echo -e "${YELLOW}💡 Убедитесь, что система запущена: make start${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Подключение к MQTT установлено${NC}"



# Вывод информации о настройках
echo -e "${BLUE}📡 Начало мониторинга устройств...${NC}"
echo -e "${YELLOW}   Базовый топик: $MQTT_BASE_TOPIC${NC}"
if [ -n "$FILTER_DEVICES" ]; then
    echo -e "${YELLOW}   Фильтр: $FILTER_DEVICES${NC}"
fi
if [ "$SHOW_ALL" = "true" ]; then
    echo -e "${YELLOW}   Режим: показать все сообщения${NC}"
else
    echo -e "${YELLOW}   Режим: только устройства${NC}"
fi
echo -e "${YELLOW}💡 Для остановки нажмите Ctrl+C${NC}"
echo ""

# Формируем команду mosquitto_sub
cmd="mosquitto_sub -h localhost -p 1883 -t '$MQTT_BASE_TOPIC/#'"

# Добавляем аутентификацию если указана
if [ -n "$MQTT_USER" ]; then
    cmd="$cmd -u '$MQTT_USER'"
fi

if [ -n "$MQTT_PASSWORD" ]; then
    cmd="$cmd -P '$MQTT_PASSWORD'"
fi

# Запускаем мониторинг
echo -e "${GREEN}🎯 Мониторинг активен...${NC}"
echo ""

eval "$cmd" | while read -r line; do
    # Парсим топик и сообщение
    topic=$(echo "$line" | cut -d' ' -f1)
    message=$(echo "$line" | cut -d' ' -f2-)
    
    # Применяем фильтр
    if filter_message "$message"; then
        process_message "$topic" "$message"
    fi
done 