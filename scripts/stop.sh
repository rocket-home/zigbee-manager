#!/usr/bin/env bash

# Скрипт для остановки Zigbee2MQTT с MQTT Broker
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

echo "🛑 Остановка Zigbee2MQTT с MQTT Broker..."

# Остановка сервисов
echo "🐳 Остановка Docker контейнеров..."
$DOCKER_COMPOSE_CMD down

echo ""
echo "✅ Все сервисы остановлены!"
echo ""
echo "📝 Для полной очистки данных выполните:"
echo "   $DOCKER_COMPOSE_CMD down -v"
echo "   sudo rm -rf mqtt/data/* zigbee2mqtt/data/*" 