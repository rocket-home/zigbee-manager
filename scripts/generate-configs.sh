#!/usr/bin/env bash

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
done < "$ENV_FILE"

# Экспортируем все переменные для envsubst
export MQTT_PORT MQTT_WS_PORT MQTT_ALLOW_ANONYMOUS
export MQTT_LOG_FILE MQTT_LOG_TYPE MQTT_LOG_TIMESTAMP
export MQTT_PERSISTENCE MQTT_PERSISTENCE_LOCATION
export MQTT_MAX_INFLIGHT MQTT_MAX_QUEUED
export MQTT_PASSWORD_FILE MQTT_ACL_FILE MQTT_EXTRA_CONFIG

# Проверка и генерация параметров безопасности Zigbee
# Генерируем только если параметры не заданы или имеют значения по умолчанию
pan_id_generated=false
extended_pan_id_generated=false
network_key_generated=false

# PAN ID
if [ -z "$ZIGBEE_PAN_ID" ] || [ "$ZIGBEE_PAN_ID" = "0x6754" ]; then
    ZIGBEE_PAN_ID=$(printf "0x%04X" $((RANDOM % 65534 + 1)))
    echo -e "${GREEN}✅ Сгенерирован PAN ID: ${ZIGBEE_PAN_ID}${NC}"
    pan_id_generated=true
else
    echo -e "${BLUE}ℹ️  Используется существующий PAN ID: ${ZIGBEE_PAN_ID}${NC}"
fi

# Extended PAN ID
if [ -z "$ZIGBEE_EXTENDED_PAN_ID" ] || [ "$ZIGBEE_EXTENDED_PAN_ID" = "DD:DD:DD:DD:DD:DD:DD:DD" ]; then
    ZIGBEE_EXTENDED_PAN_ID=$(printf "%02X:%02X:%02X:%02X:%02X:%02X:%02X:%02X" \
        $((RANDOM % 256)) $((RANDOM % 256)) $((RANDOM % 256)) $((RANDOM % 256)) \
        $((RANDOM % 256)) $((RANDOM % 256)) $((RANDOM % 256)) $((RANDOM % 256)))
    echo -e "${GREEN}✅ Сгенерирован Extended PAN ID: ${ZIGBEE_EXTENDED_PAN_ID}${NC}"
    extended_pan_id_generated=true
else
    echo -e "${BLUE}ℹ️  Используется существующий Extended PAN ID: ${ZIGBEE_EXTENDED_PAN_ID}${NC}"
fi

# Network Key
if [ -z "$ZIGBEE_NETWORK_KEY" ] || [ "$ZIGBEE_NETWORK_KEY" = "GENERATE" ]; then
    ZIGBEE_NETWORK_KEY=$(printf "%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X" \
        $((RANDOM % 256)) $((RANDOM % 256)) $((RANDOM % 256)) $((RANDOM % 256)) \
        $((RANDOM % 256)) $((RANDOM % 256)) $((RANDOM % 256)) $((RANDOM % 256)) \
        $((RANDOM % 256)) $((RANDOM % 256)) $((RANDOM % 256)) $((RANDOM % 256)) \
        $((RANDOM % 256)) $((RANDOM % 256)) $((RANDOM % 256)) $((RANDOM % 256)))
    echo -e "${GREEN}✅ Сгенерирован Network Key: ${ZIGBEE_NETWORK_KEY}${NC}"
    network_key_generated=true
else
    echo -e "${BLUE}ℹ️  Используется существующий Network Key: ${ZIGBEE_NETWORK_KEY}${NC}"
fi

# Установка значений по умолчанию для отсутствующих переменных
# MQTT переменные
MQTT_PORT=${MQTT_PORT:-1883}
MQTT_WS_PORT=${MQTT_WS_PORT:-9001}
MQTT_ALLOW_ANONYMOUS=${MQTT_ALLOW_ANONYMOUS:-true}
MQTT_LOG_FILE=${MQTT_LOG_FILE:-/mosquitto/log/mosquitto.log}
MQTT_LOG_TYPE=${MQTT_LOG_TYPE:-all}
MQTT_LOG_TIMESTAMP=${MQTT_LOG_TIMESTAMP:-true}
MQTT_PERSISTENCE=${MQTT_PERSISTENCE:-true}
MQTT_PERSISTENCE_LOCATION=${MQTT_PERSISTENCE_LOCATION:-/mosquitto/data/}
MQTT_MAX_INFLIGHT=${MQTT_MAX_INFLIGHT:-20}
MQTT_MAX_QUEUED=${MQTT_MAX_QUEUED:-100}
MQTT_PASSWORD_FILE=${MQTT_PASSWORD_FILE:-}
MQTT_ACL_FILE=${MQTT_ACL_FILE:-}
MQTT_EXTRA_CONFIG=${MQTT_EXTRA_CONFIG:-}

MQTT_BASE_TOPIC=${MQTT_BASE_TOPIC:-zigbee2mqtt}
MQTT_SERVER=${MQTT_SERVER:-mqtt://mqtt:1883}
MQTT_CLIENT_ID=${MQTT_CLIENT_ID:-zigbee2mqtt_bridge}
MQTT_KEEPALIVE=${MQTT_KEEPALIVE:-60}
MQTT_VERSION=${MQTT_VERSION:-4}
MQTT_CLEAN=${MQTT_CLEAN:-true}
MQTT_RECONNECT_PERIOD=${MQTT_RECONNECT_PERIOD:-10}
MQTT_REJECT_UNAUTHORIZED=${MQTT_REJECT_UNAUTHORIZED:-false}
ZIGBEE_ADAPTER=${ZIGBEE_ADAPTER:-zstack}
ZIGBEE_CHANNELS=${ZIGBEE_CHANNELS:-[11, 15, 20, 25]}
ZIGBEE_SECURITY_NETWORK_KEY=${ZIGBEE_SECURITY_NETWORK_KEY:-true}
ZIGBEE_SECURITY_APPLICATION_KEY=${ZIGBEE_SECURITY_APPLICATION_KEY:-true}
ZIGBEE_SECURITY_TC_LINK_KEY=${ZIGBEE_SECURITY_TC_LINK_KEY:-true}
ZIGBEE_DEVICE_LEGACY=${ZIGBEE_DEVICE_LEGACY:-false}
ZIGBEE_LOG_LEVEL=${ZIGBEE_LOG_LEVEL:-info}
ZIGBEE_LOG_OUTPUT=${ZIGBEE_LOG_OUTPUT:-console}
ZIGBEE2MQTT_HOST=${ZIGBEE2MQTT_HOST:-0.0.0.0}
ZIGBEE_HOMEASSISTANT=${ZIGBEE_HOMEASSISTANT:-false}
PERMIT_JOIN=${PERMIT_JOIN:-false}

# Облачный MQTT брокер (мост)
CLOUD_MQTT_ENABLED=${CLOUD_MQTT_ENABLED:-false}
CLOUD_MQTT_HOST=${CLOUD_MQTT_HOST:-mq.rocket-home.ru}
CLOUD_MQTT_PORT=${CLOUD_MQTT_PORT:-1883}
CLOUD_MQTT_PROTOCOL=${CLOUD_MQTT_PROTOCOL:-3.11}
CLOUD_MQTT_USERNAME=${CLOUD_MQTT_USERNAME:-}
CLOUD_MQTT_PASSWORD=${CLOUD_MQTT_PASSWORD:-}
CLOUD_MQTT_CLIENT_ID=${CLOUD_MQTT_CLIENT_ID:-zigbee-manager-bridge}
CLOUD_MQTT_KEEPALIVE=${CLOUD_MQTT_KEEPALIVE:-60}
CLOUD_MQTT_CLEAN=${CLOUD_MQTT_CLEAN:-true}
CLOUD_MQTT_BRIDGE_TOPIC=${CLOUD_MQTT_BRIDGE_TOPIC:-home/zigbee/#}
CLOUD_MQTT_LOCAL_TOPIC=${CLOUD_MQTT_LOCAL_TOPIC:-zigbee2mqtt/#}

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
    # Экспортируем переменные для envsubst
    export ZIGBEE_PAN_ID ZIGBEE_EXTENDED_PAN_ID ZIGBEE_NETWORK_KEY
    export MQTT_BASE_TOPIC MQTT_SERVER MQTT_USER MQTT_PASSWORD MQTT_CLIENT_ID
    export MQTT_KEEPALIVE MQTT_VERSION MQTT_CLEAN MQTT_RECONNECT_PERIOD MQTT_REJECT_UNAUTHORIZED
    export ZIGBEE_ADAPTER_PORT ZIGBEE_ADAPTER ZIGBEE_CHANNELS
    export ZIGBEE_SECURITY_NETWORK_KEY ZIGBEE_SECURITY_APPLICATION_KEY ZIGBEE_SECURITY_TC_LINK_KEY
    export ZIGBEE_DEVICE_LEGACY ZIGBEE_LOG_LEVEL ZIGBEE_LOG_OUTPUT
    export ZIGBEE2MQTT_PORT ZIGBEE2MQTT_HOST ZIGBEE_HOMEASSISTANT PERMIT_JOIN
    
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
    # Экспортируем переменные для MQTT
    export MQTT_PORT MQTT_WS_PORT MQTT_ALLOW_ANONYMOUS
    export MQTT_LOG_FILE MQTT_LOG_TYPE MQTT_LOG_TIMESTAMP
    export MQTT_PERSISTENCE MQTT_PERSISTENCE_LOCATION
    export MQTT_MAX_INFLIGHT MQTT_MAX_QUEUED
    export MQTT_PASSWORD_FILE MQTT_ACL_FILE MQTT_EXTRA_CONFIG
    if envsubst < "${TEMPLATES_DIR}/mosquitto.conf.template" > "${MQTT_CONFIG_DIR}/mosquitto.conf" 2>/dev/null; then
        echo -e "${GREEN}✅ Конфигурация MQTT сгенерирована${NC}"
        
        # Создаем директорию для конфигураций мостов, если она не существует
        mkdir -p "${MQTT_CONFIG_DIR}/bridge"
        
        # Добавляем конфигурацию моста в отдельный файл, если мост включен
        if [ "$CLOUD_MQTT_ENABLED" = "true" ] && [ -f "${MQTT_CONFIG_DIR}/mosquitto-bridge.conf" ]; then
            mv "${MQTT_CONFIG_DIR}/mosquitto-bridge.conf" "${MQTT_CONFIG_DIR}/bridge/cloud-bridge.conf"
            echo -e "${BLUE}   ✅ Конфигурация моста перемещена в директорию bridge${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  Не удалось создать конфигурацию MQTT (проблемы с правами доступа)${NC}"
    fi
else
    echo -e "${RED}❌ Шаблон MQTT не найден: ${TEMPLATES_DIR}/mosquitto.conf.template${NC}"
fi

# Генерация конфигурации моста (если включен)
if [ "$CLOUD_MQTT_ENABLED" = "true" ]; then
    echo -e "${BLUE}📝 Генерация конфигурации моста к облачному MQTT...${NC}"
    if [ -f "${TEMPLATES_DIR}/mosquitto-bridge.conf.template" ]; then
        # Создаем директорию для конфигураций мостов, если она не существует
        mkdir -p "${MQTT_CONFIG_DIR}/bridge"
        
        # Экспортируем переменные для моста
        export CLOUD_MQTT_ENABLED
        export CLOUD_MQTT_HOST CLOUD_MQTT_PORT CLOUD_MQTT_PROTOCOL
        export CLOUD_MQTT_USERNAME CLOUD_MQTT_PASSWORD CLOUD_MQTT_CLIENT_ID
        export CLOUD_MQTT_KEEPALIVE CLOUD_MQTT_CLEAN
        export CLOUD_MQTT_BRIDGE_TOPIC CLOUD_MQTT_LOCAL_TOPIC
        
        if envsubst < "${TEMPLATES_DIR}/mosquitto-bridge.conf.template" > "${MQTT_CONFIG_DIR}/bridge/cloud-bridge.conf" 2>/dev/null; then
            echo -e "${GREEN}✅ Конфигурация моста сгенерирована в директории bridge${NC}"
            echo -e "${BLUE}   • Хост: ${CLOUD_MQTT_HOST}:${CLOUD_MQTT_PORT}${NC}"
            echo -e "${BLUE}   • Протокол: MQTT ${CLOUD_MQTT_PROTOCOL}${NC}"
            echo -e "${BLUE}   • Топики: ${CLOUD_MQTT_LOCAL_TOPIC} ↔ ${CLOUD_MQTT_BRIDGE_TOPIC}${NC}"
        else
            echo -e "${YELLOW}⚠️  Не удалось создать конфигурацию моста (проблемы с правами доступа)${NC}"
        fi
    else
        echo -e "${RED}❌ Шаблон моста не найден: ${TEMPLATES_DIR}/mosquitto-bridge.conf.template${NC}"
    fi
else
    echo -e "${YELLOW}ℹ️  Мост к облачному MQTT отключен (CLOUD_MQTT_ENABLED=false)${NC}"
    # Удаляем старую конфигурацию моста, если она существует
    if [ -f "${MQTT_CONFIG_DIR}/bridge/cloud-bridge.conf" ]; then
        rm "${MQTT_CONFIG_DIR}/bridge/cloud-bridge.conf"
        echo -e "${GREEN}✅ Старая конфигурация моста удалена${NC}"
    fi
fi

# Обновление .env файла только для сгенерированных параметров
echo -e "${BLUE}📝 Обновление .env файла...${NC}"
env_updated=false

if [ "$pan_id_generated" = "true" ]; then
    if grep -q "^ZIGBEE_PAN_ID=" "$ENV_FILE" 2>/dev/null; then
        sed -i "s/^ZIGBEE_PAN_ID=.*/ZIGBEE_PAN_ID=${ZIGBEE_PAN_ID}/" "$ENV_FILE"
    else
        echo "ZIGBEE_PAN_ID=${ZIGBEE_PAN_ID}" >> "$ENV_FILE"
    fi
    env_updated=true
fi

if [ "$extended_pan_id_generated" = "true" ]; then
    if grep -q "^ZIGBEE_EXTENDED_PAN_ID=" "$ENV_FILE" 2>/dev/null; then
        sed -i "s/^ZIGBEE_EXTENDED_PAN_ID=.*/ZIGBEE_EXTENDED_PAN_ID=${ZIGBEE_EXTENDED_PAN_ID}/" "$ENV_FILE"
    else
        echo "ZIGBEE_EXTENDED_PAN_ID=${ZIGBEE_EXTENDED_PAN_ID}" >> "$ENV_FILE"
    fi
    env_updated=true
fi

if [ "$network_key_generated" = "true" ]; then
    if grep -q "^ZIGBEE_NETWORK_KEY=" "$ENV_FILE" 2>/dev/null; then
        sed -i "s/^ZIGBEE_NETWORK_KEY=.*/ZIGBEE_NETWORK_KEY=${ZIGBEE_NETWORK_KEY}/" "$ENV_FILE"
    else
        echo "ZIGBEE_NETWORK_KEY=${ZIGBEE_NETWORK_KEY}" >> "$ENV_FILE"
    fi
    env_updated=true
fi

if [ "$env_updated" = "true" ]; then
    echo -e "${GREEN}✅ .env файл обновлен${NC}"
else
    echo -e "${BLUE}ℹ️  .env файл не требует обновления (параметры не изменялись)${NC}"
fi

echo ""
echo -e "${GREEN}✅ Все конфигурации сгенерированы!${NC}"
echo ""

# Показываем информацию о параметрах безопасности
if [ "$pan_id_generated" = "true" ] || [ "$extended_pan_id_generated" = "true" ] || [ "$network_key_generated" = "true" ]; then
    echo -e "${BLUE}📋 Параметры безопасности Zigbee:${NC}"
    if [ "$pan_id_generated" = "true" ]; then
        echo -e "   • PAN ID: ${ZIGBEE_PAN_ID} $(echo -e "${GREEN}[НОВЫЙ]${NC}")"
    else
        echo -e "   • PAN ID: ${ZIGBEE_PAN_ID} $(echo -e "${BLUE}[СУЩЕСТВУЮЩИЙ]${NC}")"
    fi
    
    if [ "$extended_pan_id_generated" = "true" ]; then
        echo -e "   • Extended PAN ID: ${ZIGBEE_EXTENDED_PAN_ID} $(echo -e "${GREEN}[НОВЫЙ]${NC}")"
    else
        echo -e "   • Extended PAN ID: ${ZIGBEE_EXTENDED_PAN_ID} $(echo -e "${BLUE}[СУЩЕСТВУЮЩИЙ]${NC}")"
    fi
    
    if [ "$network_key_generated" = "true" ]; then
        echo -e "   • Network Key: ${ZIGBEE_NETWORK_KEY} $(echo -e "${GREEN}[НОВЫЙ]${NC}")"
    else
        echo -e "   • Network Key: ${ZIGBEE_NETWORK_KEY} $(echo -e "${BLUE}[СУЩЕСТВУЮЩИЙ]${NC}")"
    fi
    
    if [ "$pan_id_generated" = "true" ] || [ "$extended_pan_id_generated" = "true" ] || [ "$network_key_generated" = "true" ]; then
        echo ""
        echo -e "${YELLOW}💡 Сохраните новые параметры в безопасном месте!${NC}"
    fi
else
    echo -e "${BLUE}📋 Параметры безопасности Zigbee (без изменений):${NC}"
    echo -e "   • PAN ID: ${ZIGBEE_PAN_ID}"
    echo -e "   • Extended PAN ID: ${ZIGBEE_EXTENDED_PAN_ID}"
    echo -e "   • Network Key: ${ZIGBEE_NETWORK_KEY}"
fi

echo -e "${YELLOW}💡 Для применения изменений перезапустите сервисы: make restart${NC}" 