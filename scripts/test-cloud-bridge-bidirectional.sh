#!/usr/bin/env bash

# Скрипт для тестирования двустороннего обмена сообщениями через облачный MQTT мост
# Проверяет: Локальный -> Облачный и Облачный -> Локальный

set -e

# Цвета для вывода
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функция для логирования
log() {
    echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
}

# Проверка наличия .env файла
if [ ! -f .env ]; then
    error "Файл .env не найден"
    exit 1
fi

# Загрузка переменных окружения
source .env

# Проверка обязательных переменных
if [ -z "$CLOUD_MQTT_HOST" ] || [ -z "$CLOUD_MQTT_PORT" ] || [ -z "$CLOUD_MQTT_USERNAME" ] || [ -z "$CLOUD_MQTT_PASSWORD" ]; then
    error "Не все переменные CLOUD_MQTT_* настроены в .env"
    exit 1
fi

# Проверка статуса моста
if [ "$CLOUD_MQTT_ENABLED" != "true" ]; then
    warning "Облачный MQTT мост отключен в .env"
    echo "Для включения выполните: make cloud-mqtt-enable"
    exit 1
fi

# Проверка статуса MQTT контейнера
if ! docker ps | grep -q "mqtt-broker"; then
    error "MQTT контейнер не запущен"
    echo "Запустите сервисы: make start"
    exit 1
fi

# Настройки теста
LOCAL_HOST="localhost"
LOCAL_PORT="1883"
LOCAL_USERNAME="admin"
LOCAL_PASSWORD="admin"
CLOUD_HOST="$CLOUD_MQTT_HOST"
CLOUD_PORT="$CLOUD_MQTT_PORT"
CLOUD_USERNAME="$CLOUD_MQTT_USERNAME"
CLOUD_PASSWORD="$CLOUD_MQTT_PASSWORD"

# Используем топики Zigbee2MQTT для более надежного тестирования
TEST_TOPIC="zigbee2mqtt/bridge/test"
TEST_MESSAGE="Test message from $(date '+%Y-%m-%d %H:%M:%S')"
TEST_CLIENT_ID="test-client-$$"
TIMEOUT=10

# Создание временных файлов
TEMP_DIR=$(mktemp -d)
LOCAL_RECEIVED="$TEMP_DIR/local_received.txt"
CLOUD_RECEIVED="$TEMP_DIR/cloud_received.txt"
LOCAL_PUBLISHED="$TEMP_DIR/local_published.txt"
CLOUD_PUBLISHED="$TEMP_DIR/cloud_published.txt"

# Функция очистки
cleanup() {
    log "Очистка временных файлов..."
    rm -rf "$TEMP_DIR"
    # Убиваем все фоновые процессы mosquitto_sub
    pkill -f "mosquitto_sub.*$TEST_TOPIC" 2>/dev/null || true
}

# Установка обработчика сигналов
trap cleanup EXIT INT TERM

echo "=========================================="
echo "🌐 Тест двустороннего обмена сообщениями"
echo "   через облачный MQTT мост"
echo "=========================================="
echo ""

# Проверка статуса моста в логах
log "Проверка статуса облачного моста..."
BRIDGE_STATUS=$(docker logs mqtt-broker --tail 50 2>/dev/null | grep -E "(bridge.*CONNACK|bridge.*connected|bridge.*error)" | tail -1)

if echo "$BRIDGE_STATUS" | grep -q "CONNACK"; then
    success "Облачный мост подключен"
elif echo "$BRIDGE_STATUS" | grep -q "error\|failed"; then
    error "Облачный мост имеет ошибки: $BRIDGE_STATUS"
    exit 1
else
    warning "Статус моста неопределен, продолжаем тест..."
fi

echo ""

# Тест 1: Локальный -> Облачный
log "Тест 1: Отправка сообщения из локального MQTT в облачный"
echo "   📤 Локальный MQTT -> Облачный MQTT"
echo "   Топик: $TEST_TOPIC"
echo "   Сообщение: $TEST_MESSAGE"
echo ""

# Запуск подписки на облачном MQTT
log "Подписка на облачном MQTT для приема сообщения..."
mosquitto_sub -h "$CLOUD_HOST" -p "$CLOUD_PORT" -u "$CLOUD_USERNAME" -P "$CLOUD_PASSWORD" \
    --cafile /etc/ssl/certs/ca-certificates.crt \
    -t "$TEST_TOPIC" -C 1 > "$CLOUD_RECEIVED" &
CLOUD_SUB_PID=$!

# Небольшая задержка для установки подписки
sleep 2

# Отправка сообщения в локальный MQTT
log "Отправка сообщения в локальный MQTT..."
if mosquitto_pub -h "$LOCAL_HOST" -p "$LOCAL_PORT" -u "$LOCAL_USERNAME" -P "$LOCAL_PASSWORD" \
    -t "$TEST_TOPIC" -m "$TEST_MESSAGE" -i "$TEST_CLIENT_ID"; then
    success "Сообщение отправлено в локальный MQTT"
    echo "$TEST_MESSAGE" > "$LOCAL_PUBLISHED"
else
    error "Ошибка отправки сообщения в локальный MQTT"
    kill $CLOUD_SUB_PID 2>/dev/null || true
    exit 1
fi

# Ожидание получения сообщения на облачном MQTT
log "Ожидание получения сообщения на облачном MQTT..."
sleep 5

if [ -s "$CLOUD_RECEIVED" ]; then
    RECEIVED_MESSAGE=$(cat "$CLOUD_RECEIVED")
    if [ "$RECEIVED_MESSAGE" = "$TEST_MESSAGE" ]; then
        success "✅ Сообщение получено на облачном MQTT: $RECEIVED_MESSAGE"
    else
        error "❌ Получено неверное сообщение на облачном MQTT: $RECEIVED_MESSAGE"
    fi
else
    error "❌ Сообщение не получено на облачном MQTT"
fi

# Убиваем процесс подписки
kill $CLOUD_SUB_PID 2>/dev/null || true

echo ""

# Тест 2: Облачный -> Локальный
log "Тест 2: Отправка сообщения из облачного MQTT в локальный"
echo "   📤 Облачный MQTT -> Локальный MQTT"
echo "   Топик: $TEST_TOPIC"
echo "   Сообщение: $TEST_MESSAGE"
echo ""

# Запуск подписки на локальном MQTT
log "Подписка на локальном MQTT для приема сообщения..."
mosquitto_sub -h "$LOCAL_HOST" -p "$LOCAL_PORT" -u "$LOCAL_USERNAME" -P "$LOCAL_PASSWORD" \
    -t "$TEST_TOPIC" -C 1 > "$LOCAL_RECEIVED" &
LOCAL_SUB_PID=$!

# Небольшая задержка для установки подписки
sleep 2

# Отправка сообщения в облачный MQTT
log "Отправка сообщения в облачный MQTT..."
if mosquitto_pub -h "$CLOUD_HOST" -p "$CLOUD_PORT" -u "$CLOUD_USERNAME" -P "$CLOUD_PASSWORD" \
    --cafile /etc/ssl/certs/ca-certificates.crt \
    -t "$TEST_TOPIC" -m "$TEST_MESSAGE" -i "$TEST_CLIENT_ID"; then
    success "Сообщение отправлено в облачный MQTT"
    echo "$TEST_MESSAGE" > "$CLOUD_PUBLISHED"
else
    error "Ошибка отправки сообщения в облачный MQTT"
    kill $LOCAL_SUB_PID 2>/dev/null || true
    exit 1
fi

# Ожидание получения сообщения на локальном MQTT
log "Ожидание получения сообщения на локальном MQTT..."
sleep 5

if [ -s "$LOCAL_RECEIVED" ]; then
    RECEIVED_MESSAGE=$(cat "$LOCAL_RECEIVED")
    if [ "$RECEIVED_MESSAGE" = "$TEST_MESSAGE" ]; then
        success "✅ Сообщение получено на локальном MQTT: $RECEIVED_MESSAGE"
    else
        error "❌ Получено неверное сообщение на локальном MQTT: $RECEIVED_MESSAGE"
    fi
else
    error "❌ Сообщение не получено на локальном MQTT"
fi

# Убиваем процесс подписки
kill $LOCAL_SUB_PID 2>/dev/null || true

echo ""

# Проверка логов моста
log "Проверка логов моста для подтверждения пересылки..."
BRIDGE_LOGS=$(docker logs mqtt-broker --tail 20 2>/dev/null | grep -E "(bridge.*PUBLISH|bridge.*SUBSCRIBE)" | tail -5)

if [ -n "$BRIDGE_LOGS" ]; then
    success "Активность моста обнаружена в логах:"
    echo "$BRIDGE_LOGS" | sed 's/^/   • /'
else
    warning "Активность моста в логах не обнаружена"
fi

echo ""

# Дополнительная проверка: проверяем, что сообщения Zigbee2MQTT пересылаются
log "Дополнительная проверка: пересылка сообщений Zigbee2MQTT..."
ZIGBEE_MESSAGES=$(docker logs mqtt-broker --tail 50 2>/dev/null | grep -E "zigbee2mqtt.*PUBLISH" | tail -3)

if [ -n "$ZIGBEE_MESSAGES" ]; then
    success "Сообщения Zigbee2MQTT пересылаются в облако:"
    echo "$ZIGBEE_MESSAGES" | sed 's/^/   • /'
else
    warning "Сообщения Zigbee2MQTT в логах не обнаружены"
fi

echo ""

# Итоговый результат
log "Итоговый результат тестирования:"

LOCAL_TO_CLOUD_SUCCESS=false
CLOUD_TO_LOCAL_SUCCESS=false

if [ -s "$CLOUD_RECEIVED" ] && [ "$(cat "$CLOUD_RECEIVED")" = "$TEST_MESSAGE" ]; then
    LOCAL_TO_CLOUD_SUCCESS=true
fi

if [ -s "$LOCAL_RECEIVED" ] && [ "$(cat "$LOCAL_RECEIVED")" = "$TEST_MESSAGE" ]; then
    CLOUD_TO_LOCAL_SUCCESS=true
fi

echo "   📤 Локальный -> Облачный: $([ "$LOCAL_TO_CLOUD_SUCCESS" = true ] && echo "✅ Успешно" || echo "❌ Неудачно")"
echo "   📤 Облачный -> Локальный: $([ "$CLOUD_TO_LOCAL_SUCCESS" = true ] && echo "✅ Успешно" || echo "❌ Неудачно")"

if [ "$LOCAL_TO_CLOUD_SUCCESS" = true ] && [ "$CLOUD_TO_LOCAL_SUCCESS" = true ]; then
    echo ""
    success "🎉 Двусторонний обмен сообщениями работает корректно!"
    success "Облачный MQTT мост настроен правильно и функционирует в обоих направлениях."
    exit 0
else
    echo ""
    error "❌ Двусторонний обмен сообщениями работает частично или не работает."
    if [ "$LOCAL_TO_CLOUD_SUCCESS" = false ]; then
        echo "   • Проблема с направлением: Локальный -> Облачный"
    fi
    if [ "$CLOUD_TO_LOCAL_SUCCESS" = false ]; then
        echo "   • Проблема с направлением: Облачный -> Локальный"
    fi
    echo ""
    echo "Рекомендации для диагностики:"
    echo "   • Проверьте логи моста: make logs-mqtt"
    echo "   • Проверьте статус моста: make cloud-mqtt-status"
    echo "   • Проверьте конфигурацию: mqtt/config/bridge/cloud-bridge.conf"
    echo "   • Проверьте, что мост подписан на топик # в обоих направлениях"
    exit 1
fi 