#!/usr/bin/env bash

# Скрипт для настройки облачного MQTT брокера (упрощённая версия)
# Автор: Zigbee Manager

set -e

# Цвета для вывода
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Пути к файлам
ENV_FILE="../.env"

# Значения по умолчанию
CLOUD_MQTT_HOST="mq.rocket-home.ru"
CLOUD_MQTT_PORT=8883
CLOUD_MQTT_PROTOCOL=3.11
CLOUD_MQTT_KEEPALIVE=60
CLOUD_MQTT_CLEAN=true
CLOUD_MQTT_TOPIC="#"
CLOUD_MQTT_TOPIC_DIRECTION="both"
CLOUD_MQTT_TOPIC_QOS=2

# Проверка существования .env файла
if [ ! -f "$ENV_FILE" ]; then
    echo -e "${RED}❌ Файл .env не найден. Сначала выполните: make setup${NC}"
    exit 1
fi

# Функция для обновления переменной в .env файле
update_env_var() {
    local var_name="$1"
    local var_value="$2"
    # Используем awk для безопасного обновления файла
    if grep -q "^${var_name}=" "$ENV_FILE"; then
        awk -v var="$var_name" -v val="$var_value" 'BEGIN{FS=OFS="="} $1==var {$2=val} 1' "$ENV_FILE" > "$ENV_FILE.tmp" && mv "$ENV_FILE.tmp" "$ENV_FILE"
    else
        echo "${var_name}=${var_value}" >> "$ENV_FILE"
    fi
}

# Имя пользователя
read -p "$(echo -e "${YELLOW}Имя пользователя (remote_username): ${NC}")" username

# Пароль
echo -n -e "${YELLOW}Пароль (remote_password): ${NC}"
read -s password
echo

# Идентификатор клиента
read -p "$(echo -e "${YELLOW}Идентификатор клиента [zigbee-manager-bridge]: ${NC}")" client_id
client_id=${client_id:-zigbee-manager-bridge}

echo ""
echo -e "${BLUE}📋 Параметры для проверки:${NC}"
echo -e "   • Хост: ${CLOUD_MQTT_HOST}:${CLOUD_MQTT_PORT} (TLS)"
echo -e "   • Протокол: MQTT ${CLOUD_MQTT_PROTOCOL}"
echo -e "   • Клиент ID: ${client_id}"
echo -e "   • Пользователь: ${username}"
echo -e "   • Топик: # (both, QoS 2)"
echo -e "   • TLS: включён по умолчанию"
echo ""

read -p "$(echo -e "${YELLOW}Продолжить с этими параметрами? [y/N]: ${NC}")" confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Операция отменена.${NC}"
    exit 0
fi

# Обновление .env файла
echo -e "${BLUE}📝 Обновление .env файла...${NC}"
update_env_var "CLOUD_MQTT_ENABLED" "true"
update_env_var "CLOUD_MQTT_HOST" "$CLOUD_MQTT_HOST"
update_env_var "CLOUD_MQTT_PORT" "$CLOUD_MQTT_PORT"
update_env_var "CLOUD_MQTT_PROTOCOL" "$CLOUD_MQTT_PROTOCOL"
update_env_var "CLOUD_MQTT_USERNAME" "$username"
update_env_var "CLOUD_MQTT_PASSWORD" "$password"
update_env_var "CLOUD_MQTT_CLIENT_ID" "$client_id"
update_env_var "CLOUD_MQTT_KEEPALIVE" "$CLOUD_MQTT_KEEPALIVE"
update_env_var "CLOUD_MQTT_CLEAN" "$CLOUD_MQTT_CLEAN"
update_env_var "CLOUD_MQTT_TOPIC" "$CLOUD_MQTT_TOPIC"
update_env_var "CLOUD_MQTT_TOPIC_DIRECTION" "$CLOUD_MQTT_TOPIC_DIRECTION"
update_env_var "CLOUD_MQTT_TOPIC_QOS" "$CLOUD_MQTT_TOPIC_QOS"

echo -e "${GREEN}✅ .env файл обновлен${NC}"

# Генерация конфигураций
echo -e "${BLUE}🔧 Генерация конфигураций...${NC}"
./generate-configs.sh

# Проверка создания файла конфигурации моста
if [ -f "../mqtt/config/bridge/cloud-bridge.conf" ]; then
    echo -e "${GREEN}✅ Конфигурация моста создана: ../mqtt/config/bridge/cloud-bridge.conf${NC}"
else
    echo -e "${YELLOW}⚠️  Конфигурация моста не найдена в ожидаемом месте${NC}"
fi

# Перезапуск контейнера mqtt для применения bridge-конфига
if command -v docker-compose >/dev/null 2>&1; then
    DOCKER_CMD="docker-compose"
else
    DOCKER_CMD="docker compose"
fi

# Перезапуск только mqtt
if $DOCKER_CMD ps mqtt >/dev/null 2>&1; then
    echo -e "${BLUE}🔄 Перезапуск контейнера MQTT...${NC}"
    $DOCKER_CMD restart mqtt
    echo -e "${GREEN}✅ MQTT брокер перезапущен, мостовое соединение применено!${NC}"
else
    echo -e "${YELLOW}⚠️  Контейнер MQTT не найден. Запустите make start для запуска сервисов.${NC}"
fi

echo ""
echo -e "${GREEN}✅ Облачный MQTT брокер настроен!${NC}"
echo -e "${BLUE}📋 Следующие шаги:${NC}"
echo -e "   1. Перезапустите сервисы: make restart"
echo -e "   2. Проверьте статус моста: make cloud-mqtt-status"
echo -e "   3. Проверьте логи моста: make logs-mqtt"
echo ""
echo -e "${YELLOW}💡 Для отключения моста установите CLOUD_MQTT_ENABLED=false в .env${NC}" 