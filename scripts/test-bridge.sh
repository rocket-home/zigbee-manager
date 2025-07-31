#!/usr/bin/env bash

# Скрипт для тестирования работы MQTT моста
# Автор: Zigbee Manager

set -e

# Цвета для вывода
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Настройки
LOCAL_MQTT_HOST="localhost"
LOCAL_MQTT_PORT="1883"
CLOUD_MQTT_HOST="mq.rocket-home.ru"
CLOUD_MQTT_PORT="8883"
TEST_TOPIC="bridge/test"
TEST_MESSAGE="Hello from bridge test $(date)"
CLIENT_ID="bridge-test-$(date +%s)"

echo -e "${BLUE}🔍 Тестирование MQTT моста...${NC}"
echo -e "${BLUE}📋 Параметры теста:${NC}"
echo -e "   • Локальный MQTT: ${LOCAL_MQTT_HOST}:${LOCAL_MQTT_PORT}"
echo -e "   • Облачный MQTT: ${CLOUD_MQTT_HOST}:${CLOUD_MQTT_PORT}"
echo -e "   • Тестовый топик: ${TEST_TOPIC}"
echo -e "   • Клиент ID: ${CLIENT_ID}"
echo ""

# Проверка доступности локального MQTT
echo -e "${BLUE}🔍 Проверка локального MQTT брокера...${NC}"
if timeout 5 bash -c "</dev/tcp/${LOCAL_MQTT_HOST}/${LOCAL_MQTT_PORT}" 2>/dev/null; then
    echo -e "${GREEN}✅ Локальный MQTT брокер доступен${NC}"
else
    echo -e "${RED}❌ Локальный MQTT брокер недоступен${NC}"
    exit 1
fi

# Проверка доступности облачного MQTT
echo -e "${BLUE}🔍 Проверка облачного MQTT брокера...${NC}"
if timeout 10 bash -c "</dev/tcp/${CLOUD_MQTT_HOST}/${CLOUD_MQTT_PORT}" 2>/dev/null; then
    echo -e "${GREEN}✅ Облачный MQTT брокер доступен${NC}"
else
    echo -e "${YELLOW}⚠️  Облачный MQTT брокер недоступен (возможно, требует TLS)${NC}"
fi

# Создание временного файла для получения сообщений
TEMP_FILE=$(mktemp)
trap "rm -f $TEMP_FILE" EXIT

echo ""
echo -e "${BLUE}🧪 Тест 1: Публикация в локальный MQTT → получение в облачном${NC}"

# Подписка на облачный MQTT в фоне
echo -e "${BLUE}   📡 Подписка на облачный MQTT...${NC}"
mosquitto_sub -h ${CLOUD_MQTT_HOST} -p ${CLOUD_MQTT_PORT} -t ${TEST_TOPIC} -i ${CLIENT_ID}-cloud -C 1 > $TEMP_FILE &
CLOUD_SUB_PID=$!

# Ждем немного для установки соединения
sleep 3

# Публикация в локальный MQTT
echo -e "${BLUE}   📤 Публикация в локальный MQTT...${NC}"
if mosquitto_pub -h ${LOCAL_MQTT_HOST} -p ${LOCAL_MQTT_PORT} -t ${TEST_TOPIC} -m "${TEST_MESSAGE}" -i ${CLIENT_ID}-local; then
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
mosquitto_sub -h ${LOCAL_MQTT_HOST} -p ${LOCAL_MQTT_PORT} -t ${TEST_TOPIC} -i ${CLIENT_ID}-local-sub -C 1 > $TEMP_FILE &
LOCAL_SUB_PID=$!

# Ждем немного для установки соединения
sleep 3

# Публикация в облачный MQTT
echo -e "${BLUE}   📤 Публикация в облачный MQTT...${NC}"
if mosquitto_pub -h ${CLOUD_MQTT_HOST} -p ${CLOUD_MQTT_PORT} -t ${TEST_TOPIC} -m "${TEST_MESSAGE}-reverse" -i ${CLIENT_ID}-cloud-pub; then
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
echo -e "${BLUE}🔍 Проверка статуса моста...${NC}"

# Проверяем логи MQTT брокера
echo -e "${BLUE}   📋 Последние логи MQTT брокера:${NC}"
docker logs mqtt-broker --tail 10 | grep -E "(bridge|Bridge)" || echo -e "${YELLOW}   ⚠️  Логи моста не найдены${NC}"

echo ""
echo -e "${BLUE}📊 Результаты тестирования:${NC}"
echo -e "   • Локальный MQTT: ${GREEN}✅ Работает${NC}"
echo -e "   • Облачный MQTT: ${YELLOW}⚠️  Требует проверки${NC}"
echo -e "   • Мост: ${YELLOW}⚠️  Требует диагностики${NC}"

echo ""
echo -e "${YELLOW}💡 Рекомендации:${NC}"
echo -e "   1. Проверьте настройки аутентификации в облачном MQTT"
echo -e "   2. Убедитесь, что TLS настройки корректны"
echo -e "   3. Проверьте логи моста: docker logs mqtt-broker | grep bridge"
echo -e "   4. Для отладки используйте: docker exec mqtt-broker mosquitto -c /mosquitto/config/mosquitto.conf --test-config" 