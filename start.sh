#!/bin/bash

# Скрипт для запуска Zigbee2MQTT с MQTT Broker
# Автор: Zigbee Manager

set -e

echo "🚀 Запуск Zigbee2MQTT с MQTT Broker..."

# Проверка наличия Docker
if ! command -v docker &> /dev/null; then
    echo "❌ Docker не установлен. Установите Docker и попробуйте снова."
    exit 1
fi

# Определение команды Docker Compose
if command -v docker &> /dev/null && docker compose version &> /dev/null; then
    DOCKER_COMPOSE_CMD="docker compose"
    echo "✅ Используется: docker compose"
elif command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE_CMD="docker-compose"
    echo "✅ Используется: docker-compose"
else
    echo "❌ Docker Compose не установлен. Установите Docker Compose и попробуйте снова."
    exit 1
fi

# Создание .env файла если его нет
if [ ! -f .env ]; then
    echo "📝 Создание файла .env из примера..."
    cp env.example .env
    echo "✅ Файл .env создан. Отредактируйте его под свои нужды."
fi

# Проверка Zigbee адаптера
echo "🔍 Проверка Zigbee адаптера..."
if [ -e "/dev/ttyACM0" ]; then
    echo "✅ Zigbee адаптер найден на /dev/ttyACM0"
elif [ -e "/dev/ttyUSB0" ]; then
    echo "✅ Zigbee адаптер найден на /dev/ttyUSB0"
    echo "📝 Обновите ZIGBEE_ADAPTER_PORT в .env файле на /dev/ttyUSB0"
else
    echo "⚠️  Zigbee адаптер не найден. Проверьте подключение."
    echo "📝 Убедитесь, что ZIGBEE_ADAPTER_PORT в .env файле указан правильно."
fi

# Проверка прав доступа к адаптеру
echo "🔐 Проверка прав доступа к Zigbee адаптеру..."
if ! groups $USER | grep -q dialout; then
    echo "⚠️  Пользователь $USER не в группе dialout"
    echo "💡 Для настройки прав выполните: make permissions"
    echo "   или добавьте пользователя в группу dialout вручную"
else
    echo "✅ Пользователь $USER в группе dialout"
fi

# Создание необходимых директорий
echo "📁 Создание директорий..."
mkdir -p mqtt/config mqtt/data mqtt/log zigbee2mqtt/data

# Запуск сервисов
echo "🐳 Запуск Docker контейнеров..."
$DOCKER_COMPOSE_CMD up -d

# Ожидание запуска сервисов
echo "⏳ Ожидание запуска сервисов..."
sleep 10

# Проверка статуса
echo "📊 Статус сервисов:"
$DOCKER_COMPOSE_CMD ps

echo ""
echo "🎉 Система запущена!"
echo ""
echo "📋 Доступные сервисы:"
echo "   • MQTT Broker: mqtt://localhost:${MQTT_PORT:-1883}"
echo "   • MQTT WebSocket: ws://localhost:${MQTT_WS_PORT:-9001}"
echo "   • Zigbee2MQTT Web UI: http://localhost:${ZIGBEE2MQTT_PORT:-8080}"
echo ""
echo "📝 Полезные команды:"
echo "   • Просмотр логов: $DOCKER_COMPOSE_CMD logs -f"
echo "   • Остановка: $DOCKER_COMPOSE_CMD down"
echo "   • Перезапуск: $DOCKER_COMPOSE_CMD restart"
echo ""
echo "🔧 Для настройки безопасности отредактируйте файлы:"
echo "   • mqtt/config/mosquitto.conf"
echo "   • zigbee2mqtt/data/configuration.yaml" 