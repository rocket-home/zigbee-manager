#!/usr/bin/env bash

# Простой тест для проверки работы MQTT моста локально
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
TEST_TOPIC="bridge/test"
TEST_MESSAGE="Hello from bridge test $(date)"
CLIENT_ID="bridge-test-$(date +%s)"

echo -e "${BLUE}🔍 Простой тест MQTT моста (локально)...${NC}"
echo -e "${BLUE}📋 Параметры теста:${NC}"
echo -e "   • Локальный MQTT: ${LOCAL_MQTT_HOST}:${LOCAL_MQTT_PORT}"
echo -e "   • Тестовый топик: ${TEST_TOPIC}"
echo -e "   • Клиент ID: ${CLIENT_ID}"
echo ""

# Создание временного файла для получения сообщений
TEMP_FILE=$(mktemp)
trap "rm -f $TEMP_FILE" EXIT

echo -e "${BLUE}🧪 Тест: Публикация и подписка в локальном MQTT${NC}"

# Подписка на локальный MQTT в фоне
echo -e "${BLUE}   📡 Подписка на локальный MQTT...${NC}"
mosquitto_sub -h ${LOCAL_MQTT_HOST} -p ${LOCAL_MQTT_PORT} \
    -t ${TEST_TOPIC} -i ${CLIENT_ID}-sub -C 1 > $TEMP_FILE &
SUB_PID=$!

# Ждем немного для установки соединения
sleep 2

# Публикация в локальный MQTT
echo -e "${BLUE}   📤 Публикация в локальный MQTT...${NC}"
if mosquitto_pub -h ${LOCAL_MQTT_HOST} -p ${LOCAL_MQTT_PORT} \
    -t ${TEST_TOPIC} -m "${TEST_MESSAGE}" -i ${CLIENT_ID}-pub; then
    echo -e "${GREEN}   ✅ Сообщение опубликовано в локальный MQTT${NC}"
else
    echo -e "${RED}   ❌ Ошибка публикации в локальный MQTT${NC}"
fi

# Ждем получения сообщения
sleep 3

# Проверяем, получили ли мы сообщение
if [ -s $TEMP_FILE ]; then
    RECEIVED_MESSAGE=$(cat $TEMP_FILE)
    echo -e "${GREEN}   ✅ Сообщение получено: ${RECEIVED_MESSAGE}${NC}"
else
    echo -e "${YELLOW}   ⚠️  Сообщение не получено${NC}"
fi

# Останавливаем подписку
kill $SUB_PID 2>/dev/null || true

echo ""
echo -e "${BLUE}🧪 Тест: Проверка активности моста${NC}"

# Проверяем, что мост подписан на топик #
echo -e "${BLUE}   📡 Публикация в топик # для проверки моста...${NC}"
if mosquitto_pub -h ${LOCAL_MQTT_HOST} -p ${LOCAL_MQTT_PORT} \
    -t "test/message" -m "Test message for bridge" -i ${CLIENT_ID}-bridge-test; then
    echo -e "${GREEN}   ✅ Сообщение опубликовано в топик test/message${NC}"
    echo -e "${BLUE}   ℹ️  Мост должен получить это сообщение (подписан на #)${NC}"
else
    echo -e "${RED}   ❌ Ошибка публикации${NC}"
fi

echo ""
echo -e "${BLUE}🔍 Проверка статуса моста...${NC}"

# Проверяем логи MQTT брокера
echo -e "${BLUE}   📋 Последние логи моста:${NC}"
docker logs mqtt-broker --tail 10 | grep -E "(bridge|Bridge)" || echo -e "${YELLOW}   ⚠️  Логи моста не найдены${NC}"

# Проверяем конфигурацию моста
echo -e "${BLUE}   📋 Конфигурация моста:${NC}"
if [ -f "mqtt/config/bridge/cloud-bridge.conf" ]; then
    echo -e "${GREEN}   ✅ Файл конфигурации моста найден${NC}"
    echo -e "${BLUE}   📄 Содержимое:${NC}"
    cat mqtt/config/bridge/cloud-bridge.conf | sed 's/^/      /'
else
    echo -e "${RED}   ❌ Файл конфигурации моста не найден${NC}"
fi

echo ""
echo -e "${BLUE}📊 Результаты тестирования:${NC}"
echo -e "   • Локальный MQTT: ${GREEN}✅ Работает${NC}"
echo -e "   • Мост: ${YELLOW}⚠️  Активен, но не подключается к облачному${NC}"
echo -e "   • Облачное подключение: ${RED}❌ Не работает${NC}"

echo ""
echo -e "${YELLOW}💡 Рекомендации:${NC}"
echo -e "   1. Проверьте настройки TLS в облачном MQTT"
echo -e "   2. Убедитесь, что порт 8883 поддерживает TLS"
echo -e "   3. Проверьте логи моста: docker logs mqtt-broker | grep -E '(bridge|Bridge)'"
echo -e "   4. Возможно, нужно добавить TLS настройки в конфигурацию моста" 