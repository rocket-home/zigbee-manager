#!/usr/bin/env bash

# Скрипт для проверки статуса Zigbee2MQTT с MQTT Broker
# Автор: Zigbee Manager

# Определение команды Docker Compose
if command -v docker &> /dev/null && docker compose version &> /dev/null; then
    DOCKER_COMPOSE_CMD="docker compose"
elif command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE_CMD="docker-compose"
else
    echo "❌ Docker Compose не установлен."
    exit 1
fi

echo "📊 Статус Zigbee2MQTT с MQTT Broker..."
echo ""

# Проверка статуса контейнеров
echo "🐳 Статус Docker контейнеров:"
$DOCKER_COMPOSE_CMD ps

echo ""
echo "📋 Информация о сервисах:"
echo "   • MQTT Broker: mqtt://localhost:${MQTT_PORT:-1883}"
echo "   • MQTT WebSocket: ws://localhost:${MQTT_WS_PORT:-9001}"
echo "   • Zigbee2MQTT Web UI: http://localhost:${ZIGBEE2MQTT_PORT:-8080}"

echo ""
echo "📝 Полезные команды:"
echo "   • Просмотр логов: $DOCKER_COMPOSE_CMD logs -f"
echo "   • Перезапуск: $DOCKER_COMPOSE_CMD restart"
echo "   • Остановка: $DOCKER_COMPOSE_CMD down" 