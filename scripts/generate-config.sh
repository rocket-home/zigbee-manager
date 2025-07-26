#!/bin/bash

# Скрипт для генерации безопасных конфигурационных параметров Zigbee сети
# Автор: Zigbee Manager

set -e

# Цвета для вывода
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

CONFIG_FILE="../zigbee2mqtt/data/configuration.yaml"

echo -e "${BLUE}🔐 Генерация безопасных параметров Zigbee сети...${NC}"

# Генерация PAN ID (16-битное значение, 0x0001-0xFFFE)
PAN_ID=$(printf "%04X" $((RANDOM % 65534 + 1)))
echo -e "${GREEN}✅ PAN ID: 0x${PAN_ID}${NC}"

# Генерация Extended PAN ID (64-битное значение)
EXTENDED_PAN_ID=$(printf "%02X:%02X:%02X:%02X:%02X:%02X:%02X:%02X" \
    $((RANDOM % 256)) $((RANDOM % 256)) $((RANDOM % 256)) $((RANDOM % 256)) \
    $((RANDOM % 256)) $((RANDOM % 256)) $((RANDOM % 256)) $((RANDOM % 256)))
echo -e "${GREEN}✅ Extended PAN ID: ${EXTENDED_PAN_ID}${NC}"

# Генерация Network Key (128-битный ключ)
NETWORK_KEY=$(printf "%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X" \
    $((RANDOM % 256)) $((RANDOM % 256)) $((RANDOM % 256)) $((RANDOM % 256)) \
    $((RANDOM % 256)) $((RANDOM % 256)) $((RANDOM % 256)) $((RANDOM % 256)) \
    $((RANDOM % 256)) $((RANDOM % 256)) $((RANDOM % 256)) $((RANDOM % 256)) \
    $((RANDOM % 256)) $((RANDOM % 256)) $((RANDOM % 256)) $((RANDOM % 256)))
echo -e "${GREEN}✅ Network Key: ${NETWORK_KEY}${NC}"

# Проверка существования файла конфигурации
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${YELLOW}⚠️  Файл конфигурации не найден: ${CONFIG_FILE}${NC}"
    echo -e "${YELLOW}💡 Сначала выполните: make setup${NC}"
    exit 1
fi

# Создание резервной копии
BACKUP_FILE="${CONFIG_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
cp "$CONFIG_FILE" "$BACKUP_FILE"
echo -e "${BLUE}📋 Создана резервная копия: ${BACKUP_FILE}${NC}"

# Обновление конфигурации
echo -e "${BLUE}📝 Обновление конфигурации...${NC}"

# Обновление PAN ID
sed -i "s/pan_id: [0-9]*/pan_id: 0x${PAN_ID}/" "$CONFIG_FILE"

# Обновление Extended PAN ID (более точное сопоставление)
sed -i "s/extended_pan_id: '[0-9A-F:]*'/extended_pan_id: '${EXTENDED_PAN_ID}'/" "$CONFIG_FILE"

# Обновление Network Key
sed -i "s/network_key: GENERATE/network_key: '${NETWORK_KEY}'/" "$CONFIG_FILE"

echo -e "${GREEN}✅ Конфигурация обновлена!${NC}"
echo ""
echo -e "${BLUE}📋 Сгенерированные параметры:${NC}"
echo -e "   • PAN ID: 0x${PAN_ID}"
echo -e "   • Extended PAN ID: ${EXTENDED_PAN_ID}"
echo -e "   • Network Key: ${NETWORK_KEY}"
echo ""
echo -e "${YELLOW}💡 Сохраните эти параметры в безопасном месте!${NC}"
echo -e "${YELLOW}💡 Для применения изменений перезапустите Zigbee2MQTT: make restart-zigbee${NC}" 