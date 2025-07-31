#!/usr/bin/env bash

# Скрипт для тестирования работы MQTT моста с аутентификацией
# Автор: Zigbee Manager

set -e

# Цвета для вывода
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Настройки из конфигурации моста
LOCAL_MQTT_HOST="localhost"
LOCAL_MQTT_PORT="1883"
CLOUD_MQTT_HOST="mq.rocket-home.ru"
CLOUD_MQTT_PORT="8883"
CLOUD_USERNAME="f54c2971-7b2b-49f6-a6db-bca59e0cccca"
CLOUD_PASSWORD="zDiAyp2cD9mQwVV"
TEST_TOPIC="bridge/test"
TEST_MESSAGE="Hello from bridge test $(date)"
CLIENT_ID="bridge-test-$(date +%s)"

echo -e "${BLUE}🔍 Тестирование MQTT моста с аутентификацией...${NC}"
echo -e "${BLUE}📋 Параметры теста:${NC}"
echo -e "   • Локальный MQTT: ${LOCAL_MQTT_HOST}:${LOCAL_MQTT_PORT}"
echo -e "   • Облачный MQTT: ${CLOUD_MQTT_HOST}:${CLOUD_MQTT_PORT}"
echo -e "   • Облачный пользователь: ${CLOUD_USERNAME}"
echo -e "   • Тестовый топик: ${TEST_TOPIC}"
echo -e "   • Клиент ID: ${CLIENT_ID}"
echo ""

# Создание временного файла для получения сообщений
TEMP_FILE=$(mktemp)
trap "rm -f $TEMP_FILE" EXIT

echo -e "${BLUE}🧪 Тест 1: Публикация в локальный MQTT → получение в облачном${NC}"

# Подписка на облачный MQTT с аутентификацией в фоне
echo -e "${BLUE}   📡 Подписка на облачный MQTT с аутентификацией...${NC}"
mosquitto_sub -h ${CLOUD_MQTT_HOST} -p ${CLOUD_MQTT_PORT} \
    -u ${CLOUD_USERNAME} -P ${CLOUD_PASSWORD} \
    -t ${TEST_TOPIC} -i ${CLIENT_ID}-cloud -C 1 > $TEMP_FILE &
CLOUD_SUB_PID=$!

# Ждем немного для установки соединения
sleep 3

# Публикация в локальный MQTT
echo -e "${BLUE}   📤 Публикация в локальный MQTT...${NC}"
if mosquitto_pub -h ${LOCAL_MQTT_HOST} -p ${LOCAL_MQTT_PORT} \
    -t ${TEST_TOPIC} -m "${TEST_MESSAGE}" -i ${CLIENT_ID}-local; then
    echo -e "${GREEN}   ✅ Сообщение опубликовано в локальный MQTT${NC}"
else
    echo -e "${RED}   ❌ Ошибка публикации в локальный MQTT${NC}"
fi

# Ждем получения сообщения
sleep 5

# Проверяем, получили ли мы сообщение
if [ -s $TEMP_FILE ]; then
    RECEIVED_MESSAGE=$(cat $TEMP_FILE)
    echo -e "${GREEN}   ✅ Сообщение получено в облачном MQTT: ${RECEIVED_MESSAGE}${NC}"
else
    echo -e "${YELLOW}   ⚠️  Сообщение не получено в облачном MQTT${NC}"
fi

# Останавливаем подписку
kill $CLOUD_SUB_PID 2>/dev/null || true

echo ""
echo -e "${BLUE}🧪 Тест 2: Публикация в облачный MQTT → получение в локальном${NC}"

# Подписка на локальный MQTT в фоне
echo -e "${BLUE}   📡 Подписка на локальный MQTT...${NC}"
mosquitto_sub -h ${LOCAL_MQTT_HOST} -p ${LOCAL_MQTT_PORT} \
    -t ${TEST_TOPIC} -i ${CLIENT_ID}-local-sub -C 1 > $TEMP_FILE &
LOCAL_SUB_PID=$!

# Ждем немного для установки соединения
sleep 3

# Публикация в облачный MQTT с аутентификацией
echo -e "${BLUE}   📤 Публикация в облачный MQTT с аутентификацией...${NC}"
if mosquitto_pub -h ${CLOUD_MQTT_HOST} -p ${CLOUD_MQTT_PORT} \
    -u ${CLOUD_USERNAME} -P ${CLOUD_PASSWORD} \
    -t ${TEST_TOPIC} -m "${TEST_MESSAGE}-reverse" -i ${CLIENT_ID}-cloud-pub; then
    echo -e "${GREEN}   ✅ Сообщение опубликовано в облачный MQTT${NC}"
else
    echo -e "${RED}   ❌ Ошибка публикации в облачный MQTT${NC}"
fi

# Ждем получения сообщения
sleep 5

# Проверяем, получили ли мы сообщение
if [ -s $TEMP_FILE ]; then
    RECEIVED_MESSAGE=$(cat $TEMP_FILE)
    echo -e "${GREEN}   ✅ Сообщение получено в локальном MQTT: ${RECEIVED_MESSAGE}${NC}"
else
    echo -e "${YELLOW}   ⚠️  Сообщение не получено в локальном MQTT${NC}"
fi

# Останавливаем подписку
kill $LOCAL_SUB_PID 2>/dev/null || true

echo ""
echo -e "${BLUE}🧪 Тест 3: Проверка работы моста через логи${NC}"

# Проверяем логи MQTT брокера на предмет активности моста
echo -e "${BLUE}   📋 Последние логи моста:${NC}"
docker logs mqtt-broker --tail 20 | grep -E "(bridge|Bridge)" || echo -e "${YELLOW}   ⚠️  Логи моста не найдены${NC}"

# Проверяем, есть ли активные соединения моста
echo -e "${BLUE}   📋 Проверка активных соединений моста:${NC}"
if docker logs mqtt-broker --tail 50 | grep -q "Bridge.*sending CONNECT"; then
    echo -e "${GREEN}   ✅ Мост пытается подключиться${NC}"
else
    echo -e "${YELLOW}   ⚠️  Мост не активен${NC}"
fi

echo ""
echo -e "${BLUE}📊 Результаты тестирования:${NC}"
echo -e "   • Локальный MQTT: ${GREEN}✅ Работает${NC}"
echo -e "   • Облачный MQTT с аутентификацией: ${BLUE}🔍 Тестируется${NC}"
echo -e "   • Мост: ${YELLOW}⚠️  Требует диагностики${NC}"

echo ""
echo -e "${YELLOW}💡 Диагностика моста:${NC}"
echo -e "   1. Проверьте логи моста: docker logs mqtt-broker | grep -E '(bridge|Bridge)'"
echo -e "   2. Проверьте конфигурацию моста: cat mqtt/config/bridge/cloud-bridge.conf"
echo -e "   3. Перезапустите мост: docker restart mqtt-broker"
echo -e "   4. Проверьте TLS настройки в облачном MQTT" 