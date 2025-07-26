#!/bin/bash

# Скрипт для генерации конфигураций из шаблонов с использованием envsubst
# Автор: Zigbee Manager

set -e

# Цвета для вывода
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Пути к файлам
TEMPLATES_DIR="../templates"
CONFIG_DIR="../zigbee2mqtt/data"
MQTT_CONFIG_DIR="../mqtt/config"
ENV_FILE="../.env"

echo -e "${BLUE}🔧 Генерация конфигураций из шаблонов...${NC}"

# Проверка наличия envsubst
if [ ! -f /usr/bin/envsubst ]; then
    echo -e "${RED}❌ envsubst не найден. Установите gettext-base:${NC}"
    echo -e "${YELLOW}   sudo apt-get install gettext-base${NC}"
    exit 1
fi

# Проверка существования .env файла
if [ ! -f "$ENV_FILE" ]; then
    echo -e "${YELLOW}⚠️  Файл .env не найден. Создаем из примера...${NC}"
    cp ../env.example "$ENV_FILE"
    echo -e "${GREEN}✅ Файл .env создан из примера${NC}"
fi

# Загрузка переменных окружения
echo -e "${BLUE}📋 Загрузка переменных окружения...${NC}"
set -a
source "$ENV_FILE"
set +a

# Генерация случайных параметров Zigbee, если не заданы
if [ -z "$ZIGBEE_PAN_ID" ] || [ "$ZIGBEE_PAN_ID" = "0x6754" ]; then
    ZIGBEE_PAN_ID=$(printf "0x%04X" $((RANDOM % 65534 + 1)))
    echo -e "${GREEN}✅ Сгенерирован PAN ID: ${ZIGBEE_PAN_ID}${NC}"
fi

if [ -z "$ZIGBEE_EXTENDED_PAN_ID" ] || [ "$ZIGBEE_EXTENDED_PAN_ID" = "DD:DD:DD:DD:DD:DD:DD:DD" ]; then
    ZIGBEE_EXTENDED_PAN_ID=$(printf "%02X:%02X:%02X:%02X:%02X:%02X:%02X:%02X" \
        $((RANDOM % 256)) $((RANDOM % 256)) $((RANDOM % 256)) $((RANDOM % 256)) \
        $((RANDOM % 256)) $((RANDOM % 256)) $((RANDOM % 256)) $((RANDOM % 256)))
    echo -e "${GREEN}✅ Сгенерирован Extended PAN ID: ${ZIGBEE_EXTENDED_PAN_ID}${NC}"
fi

if [ -z "$ZIGBEE_NETWORK_KEY" ] || [ "$ZIGBEE_NETWORK_KEY" = "GENERATE" ]; then
    ZIGBEE_NETWORK_KEY=$(printf "%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X" \
        $((RANDOM % 256)) $((RANDOM % 256)) $((RANDOM % 256)) $((RANDOM % 256)) \
        $((RANDOM % 256)) $((RANDOM % 256)) $((RANDOM % 256)) $((RANDOM % 256)) \
        $((RANDOM % 256)) $((RANDOM % 256)) $((RANDOM % 256)) $((RANDOM % 256)) \
        $((RANDOM % 256)) $((RANDOM % 256)) $((RANDOM % 256)) $((RANDOM % 256)))
    echo -e "${GREEN}✅ Сгенерирован Network Key: ${ZIGBEE_NETWORK_KEY}${NC}"
fi

# Создание резервных копий
echo -e "${BLUE}📋 Создание резервных копий...${NC}"
if [ -f "${CONFIG_DIR}/configuration.yaml" ]; then
    BACKUP_FILE="${CONFIG_DIR}/configuration.yaml.backup.$(date +%Y%m%d_%H%M%S)"
    cp "${CONFIG_DIR}/configuration.yaml" "$BACKUP_FILE"
    echo -e "${GREEN}✅ Резервная копия Zigbee2MQTT: ${BACKUP_FILE}${NC}"
fi

if [ -f "${MQTT_CONFIG_DIR}/mosquitto.conf" ]; then
    MQTT_BACKUP="${MQTT_CONFIG_DIR}/mosquitto.conf.backup.$(date +%Y%m%d_%H%M%S)"
    if cp "${MQTT_CONFIG_DIR}/mosquitto.conf" "$MQTT_BACKUP" 2>/dev/null; then
        echo -e "${GREEN}✅ Резервная копия MQTT: ${MQTT_BACKUP}${NC}"
    else
        echo -e "${YELLOW}⚠️  Не удалось создать резервную копию MQTT (файл может не существовать)${NC}"
    fi
fi

# Генерация конфигурации Zigbee2MQTT
echo -e "${BLUE}📝 Генерация конфигурации Zigbee2MQTT...${NC}"
if [ -f "${TEMPLATES_DIR}/zigbee2mqtt-config.yaml.template" ]; then
    envsubst < "${TEMPLATES_DIR}/zigbee2mqtt-config.yaml.template" > "${CONFIG_DIR}/configuration.yaml"
    echo -e "${GREEN}✅ Конфигурация Zigbee2MQTT сгенерирована${NC}"
else
    echo -e "${RED}❌ Шаблон Zigbee2MQTT не найден: ${TEMPLATES_DIR}/zigbee2mqtt-config.yaml.template${NC}"
fi

# Генерация конфигурации MQTT
echo -e "${BLUE}📝 Генерация конфигурации MQTT...${NC}"
if [ -f "${TEMPLATES_DIR}/mosquitto.conf.template" ]; then
    # Создаем директорию, если она не существует
    mkdir -p "${MQTT_CONFIG_DIR}"
    if envsubst < "${TEMPLATES_DIR}/mosquitto.conf.template" > "${MQTT_CONFIG_DIR}/mosquitto.conf" 2>/dev/null; then
        echo -e "${GREEN}✅ Конфигурация MQTT сгенерирована${NC}"
    else
        echo -e "${YELLOW}⚠️  Не удалось создать конфигурацию MQTT (проблемы с правами доступа)${NC}"
    fi
else
    echo -e "${RED}❌ Шаблон MQTT не найден: ${TEMPLATES_DIR}/mosquitto.conf.template${NC}"
fi

# Обновление .env файла с новыми значениями
echo -e "${BLUE}📝 Обновление .env файла...${NC}"
if [ -n "$ZIGBEE_PAN_ID" ]; then
    sed -i "s/^ZIGBEE_PAN_ID=.*/ZIGBEE_PAN_ID=${ZIGBEE_PAN_ID}/" "$ENV_FILE" 2>/dev/null || \
    echo "ZIGBEE_PAN_ID=${ZIGBEE_PAN_ID}" >> "$ENV_FILE"
fi

if [ -n "$ZIGBEE_EXTENDED_PAN_ID" ]; then
    sed -i "s/^ZIGBEE_EXTENDED_PAN_ID=.*/ZIGBEE_EXTENDED_PAN_ID=${ZIGBEE_EXTENDED_PAN_ID}/" "$ENV_FILE" 2>/dev/null || \
    echo "ZIGBEE_EXTENDED_PAN_ID=${ZIGBEE_EXTENDED_PAN_ID}" >> "$ENV_FILE"
fi

if [ -n "$ZIGBEE_NETWORK_KEY" ]; then
    sed -i "s/^ZIGBEE_NETWORK_KEY=.*/ZIGBEE_NETWORK_KEY=${ZIGBEE_NETWORK_KEY}/" "$ENV_FILE" 2>/dev/null || \
    echo "ZIGBEE_NETWORK_KEY=${ZIGBEE_NETWORK_KEY}" >> "$ENV_FILE"
fi

echo -e "${GREEN}✅ .env файл обновлен${NC}"

echo ""
echo -e "${GREEN}✅ Все конфигурации сгенерированы!${NC}"
echo ""
echo -e "${BLUE}📋 Сгенерированные параметры Zigbee:${NC}"
echo -e "   • PAN ID: ${ZIGBEE_PAN_ID}"
echo -e "   • Extended PAN ID: ${ZIGBEE_EXTENDED_PAN_ID}"
echo -e "   • Network Key: ${ZIGBEE_NETWORK_KEY}"
echo ""
echo -e "${YELLOW}💡 Сохраните эти параметры в безопасном месте!${NC}"
echo -e "${YELLOW}💡 Для применения изменений перезапустите сервисы: make restart${NC}" 