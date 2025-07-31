#!/usr/bin/env bash

# Скрипт для восстановления системы Zigbee2MQTT Manager из полной резервной копии
# Использование: ./restore-system.sh <путь_к_архиву>

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Проверка аргументов
if [ $# -eq 0 ]; then
    echo -e "${RED}❌ Ошибка: Не указан путь к архиву резервной копии${NC}"
    echo -e "${YELLOW}💡 Использование: $0 <путь_к_архиву>${NC}"
    echo -e "${BLUE}📋 Пример: $0 ../backups/zigbee-manager-backup-20250726_143022.tar.gz${NC}"
    exit 1
fi

BACKUP_FILE="$1"

echo -e "${BLUE}🔄 Восстановление системы из полной резервной копии...${NC}"

# Проверка существования архива
if [ ! -f "$BACKUP_FILE" ]; then
    echo -e "${RED}❌ Архив резервной копии не найден: $BACKUP_FILE${NC}"
    exit 1
fi

# Проверка формата архива
if [[ ! "$BACKUP_FILE" =~ \.tar\.gz$ ]]; then
    echo -e "${RED}❌ Неверный формат архива. Ожидается .tar.gz${NC}"
    exit 1
fi

# Создание временной директории для распаковки
TEMP_DIR="../backups/restore-temp-$(date +%Y%m%d_%H%M%S)"
mkdir -p "$TEMP_DIR"

echo -e "${BLUE}📦 Распаковка архива...${NC}"
cd "$TEMP_DIR"
tar -xzf "$BACKUP_FILE"
cd - > /dev/null

# Поиск распакованной директории
RESTORE_DIR=$(find "$TEMP_DIR" -maxdepth 1 -type d -name "temp-*" | head -1)
if [ -z "$RESTORE_DIR" ]; then
    echo -e "${RED}❌ Не удалось найти распакованную директорию${NC}"
    rm -rf "$TEMP_DIR"
    exit 1
fi

echo -e "${BLUE}📋 Проверка содержимого резервной копии...${NC}"

# Проверка наличия основных файлов
if [ ! -f "$RESTORE_DIR/config/.env" ]; then
    echo -e "${RED}❌ Файл .env не найден в резервной копии${NC}"
    rm -rf "$TEMP_DIR"
    exit 1
fi

if [ ! -f "$RESTORE_DIR/config/docker-compose.yml" ]; then
    echo -e "${RED}❌ Файл docker-compose.yml не найден в резервной копии${NC}"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Показываем информацию о резервной копии
if [ -f "$RESTORE_DIR/backup-info.txt" ]; then
    echo -e "${BLUE}📋 Информация о резервной копии:${NC}"
    cat "$RESTORE_DIR/backup-info.txt"
    echo ""
fi

# Остановка системы если запущена
echo -e "${BLUE}🛑 Проверка запущенной системы...${NC}"
if docker ps | grep -q "mqtt-broker\|zigbee2mqtt"; then
    echo -e "${YELLOW}⚠️  Система запущена. Останавливаем...${NC}"
    docker-compose down 2>/dev/null || true
    echo -e "${GREEN}✅ Система остановлена${NC}"
else
    echo -e "${GREEN}✅ Система не запущена${NC}"
fi

# Создание необходимых директорий
echo -e "${BLUE}📁 Создание структуры директорий...${NC}"
mkdir -p mqtt/config mqtt/data mqtt/log zigbee2mqtt/data scripts templates

# Восстановление конфигурационных файлов
echo -e "${BLUE}📋 Восстановление конфигурационных файлов...${NC}"

# Основные конфигурации
cp "$RESTORE_DIR/config/.env" .env
cp "$RESTORE_DIR/config/docker-compose.yml" docker-compose.yml
cp "$RESTORE_DIR/config/Makefile" Makefile

# Конфигурации MQTT
if [ -f "$RESTORE_DIR/config/mosquitto.conf" ]; then
    cp "$RESTORE_DIR/config/mosquitto.conf" mqtt/config/
    echo -e "${GREEN}✅ Конфигурация MQTT восстановлена${NC}"
fi

# Конфигурации Zigbee2MQTT
if [ -f "$RESTORE_DIR/config/configuration.yaml" ]; then
    cp "$RESTORE_DIR/config/configuration.yaml" zigbee2mqtt/data/
    echo -e "${GREEN}✅ Конфигурация Zigbee2MQTT восстановлена${NC}"
fi

# Шаблоны
if [ -d "$RESTORE_DIR/config/templates" ]; then
    cp -r "$RESTORE_DIR/config/templates" ./
    echo -e "${GREEN}✅ Шаблоны восстановлены${NC}"
fi

# Восстановление данных
echo -e "${BLUE}💾 Восстановление данных...${NC}"

if [ -d "$RESTORE_DIR/data" ] && [ "$(ls -A "$RESTORE_DIR/data")" ]; then
    # Данные MQTT
    if [ -d "$RESTORE_DIR/data" ]; then
        cp -r "$RESTORE_DIR/data"/* mqtt/data/ 2>/dev/null || true
        echo -e "${GREEN}✅ Данные MQTT восстановлены${NC}"
    fi
    
    # Данные Zigbee2MQTT
    if [ -d "$RESTORE_DIR/data" ]; then
        cp -r "$RESTORE_DIR/data"/* zigbee2mqtt/data/ 2>/dev/null || true
        echo -e "${GREEN}✅ Данные Zigbee2MQTT восстановлены${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Данные не найдены в резервной копии${NC}"
fi

# Восстановление логов
echo -e "${BLUE}📋 Восстановление логов...${NC}"

if [ -d "$RESTORE_DIR/logs" ] && [ "$(ls -A "$RESTORE_DIR/logs")" ]; then
    cp -r "$RESTORE_DIR/logs"/* mqtt/log/ 2>/dev/null || true
    echo -e "${GREEN}✅ Логи восстановлены${NC}"
else
    echo -e "${YELLOW}⚠️  Логи не найдены в резервной копии${NC}"
fi

# Очистка временной директории
rm -rf "$TEMP_DIR"

# Показываем восстановленные параметры безопасности
echo -e "${BLUE}🔐 Восстановленные параметры безопасности:${NC}"
if [ -f .env ]; then
    echo "   • PAN ID: $(grep ZIGBEE_PAN_ID .env | cut -d= -f2)"
    echo "   • Extended PAN ID: $(grep ZIGBEE_EXTENDED_PAN_ID .env | cut -d= -f2)"
    echo "   • Network Key: $(grep ZIGBEE_NETWORK_KEY .env | cut -d= -f2)"
fi

echo ""
echo -e "${GREEN}🎉 Восстановление системы завершено успешно!${NC}"
echo ""
echo -e "${BLUE}📋 Следующие шаги:${NC}"
echo "   1. Проверьте конфигурацию: make config-check"
echo "   2. Настройте права доступа: make permissions"
echo "   3. Запустите систему: make start"
echo "   4. Проверьте статус: make status"
echo ""
echo -e "${YELLOW}⚠️  ВАЖНО: Убедитесь, что все устройства находятся в зоне действия!${NC}"
echo -e "${YELLOW}💡 Если устройства не подключаются, попробуйте перезапустить их${NC}" 