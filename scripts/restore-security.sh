#!/usr/bin/env bash

# Скрипт для восстановления параметров безопасности Zigbee из резервной копии
# Использование: ./restore-security.sh <путь_к_резервной_копии>

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Проверка аргументов
if [ $# -eq 0 ]; then
    echo -e "${RED}❌ Ошибка: Не указан путь к резервной копии${NC}"
    echo -e "${YELLOW}💡 Использование: $0 <путь_к_резервной_копии>${NC}"
    echo -e "${BLUE}📋 Пример: $0 backups/20250726_143022${NC}"
    exit 1
fi

BACKUP_DIR="$1"

echo -e "${BLUE}🔄 Восстановление параметров безопасности из резервной копии...${NC}"

# Проверка существования директории резервной копии
if [ ! -d "$BACKUP_DIR" ]; then
    echo -e "${RED}❌ Директория резервной копии не найдена: $BACKUP_DIR${NC}"
    exit 1
fi

echo -e "${BLUE}📁 Восстановление .env файла...${NC}"
if [ -f "$BACKUP_DIR/.env.backup" ]; then
    cp "$BACKUP_DIR/.env.backup" .env
    echo -e "${GREEN}✅ .env файл восстановлен${NC}"
else
    echo -e "${RED}❌ Файл .env.backup не найден в резервной копии${NC}"
    exit 1
fi

echo -e "${BLUE}📁 Восстановление конфигурации Zigbee2MQTT...${NC}"
if [ -f "$BACKUP_DIR/configuration.yaml.backup" ]; then
    # Создаем директорию если её нет
    mkdir -p zigbee2mqtt/data
    cp "$BACKUP_DIR/configuration.yaml.backup" zigbee2mqtt/data/configuration.yaml
    echo -e "${GREEN}✅ Конфигурация Zigbee2MQTT восстановлена${NC}"
else
    echo -e "${YELLOW}⚠️  Файл configuration.yaml.backup не найден в резервной копии${NC}"
fi

# Показываем восстановленные параметры
echo -e "${BLUE}📋 Восстановленные параметры безопасности:${NC}"
echo "   • PAN ID: $(grep ZIGBEE_PAN_ID .env | cut -d= -f2)"
echo "   • Extended PAN ID: $(grep ZIGBEE_EXTENDED_PAN_ID .env | cut -d= -f2)"
echo "   • Network Key: $(grep ZIGBEE_NETWORK_KEY .env | cut -d= -f2)"

echo ""
echo -e "${GREEN}🎉 Восстановление завершено успешно!${NC}"
echo ""
echo -e "${BLUE}📋 Следующие шаги:${NC}"
echo "   1. Проверьте конфигурацию: make config-check"
echo "   2. Перезапустите систему: make restart"
echo "   3. Проверьте статус: make status"
echo ""
echo -e "${YELLOW}⚠️  ВАЖНО: Убедитесь, что все устройства находятся в зоне действия!${NC}" 