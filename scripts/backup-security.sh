#!/usr/bin/env bash

# Скрипт для создания резервных копий параметров безопасности Zigbee
# Использование: ./backup-security.sh

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔐 Создание резервных копий параметров безопасности...${NC}"

# Проверка наличия .env файла
if [ ! -f ../.env ]; then
    echo -e "${RED}❌ Файл .env не найден${NC}"
    echo -e "${YELLOW}💡 Сначала выполните: make setup${NC}"
    exit 1
fi

# Создание директории для резервных копий
BACKUP_DIR="../backups/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo -e "${BLUE}📁 Создание резервной копии .env...${NC}"
cp ../.env "$BACKUP_DIR/.env.backup"
echo -e "${GREEN}✅ .env скопирован в $BACKUP_DIR/.env.backup${NC}"

# Создание резервной копии конфигурации Zigbee2MQTT
if [ -f ../zigbee2mqtt/data/configuration.yaml ]; then
    echo -e "${BLUE}📁 Создание резервной копии конфигурации Zigbee2MQTT...${NC}"
    cp ../zigbee2mqtt/data/configuration.yaml "$BACKUP_DIR/configuration.yaml.backup"
    echo -e "${GREEN}✅ Конфигурация скопирована в $BACKUP_DIR/configuration.yaml.backup${NC}"
else
    echo -e "${YELLOW}⚠️  Файл конфигурации Zigbee2MQTT не найден${NC}"
fi

# Создание документа с параметрами безопасности
echo -e "${BLUE}📝 Создание документа с параметрами безопасности...${NC}"
cat > "$BACKUP_DIR/zigbee-security-params.txt" << EOF
Zigbee Network Security Parameters
==================================
Дата создания: $(date)
Версия: 1.0

ВАЖНО: Сохраните эти параметры в безопасном месте!
Потеря этих параметров приведет к потере доступа ко всем устройствам.

PAN ID: $(grep ZIGBEE_PAN_ID ../.env | cut -d= -f2)
Extended PAN ID: $(grep ZIGBEE_EXTENDED_PAN_ID ../.env | cut -d= -f2)
Network Key: $(grep ZIGBEE_NETWORK_KEY ../.env | cut -d= -f2)

Инструкции по восстановлению:
1. Скопируйте .env.backup в .env
2. Скопируйте configuration.yaml.backup в zigbee2mqtt/data/configuration.yaml
3. Перезапустите систему: make restart

Рекомендации по хранению:
- Пароль-менеджер (KeePass, Bitwarden)
- Зашифрованный файл
- Физическая запись в сейфе
- Облачное хранилище с шифрованием
EOF

echo -e "${GREEN}✅ Документ создан: $BACKUP_DIR/zigbee-security-params.txt${NC}"

# Создание архива
echo -e "${BLUE}📦 Создание архива...${NC}"
cd "$(dirname "$BACKUP_DIR")"
tar -czf "$(basename "$BACKUP_DIR").tar.gz" "$(basename "$BACKUP_DIR")"
cd - > /dev/null

echo -e "${GREEN}✅ Архив создан: $(dirname "$BACKUP_DIR")/$(basename "$BACKUP_DIR").tar.gz${NC}"

echo ""
echo -e "${GREEN}🎉 Резервные копии созданы успешно!${NC}"
echo ""
echo -e "${BLUE}📋 Созданные файлы:${NC}"
echo "   • $BACKUP_DIR/.env.backup"
if [ -f ../zigbee2mqtt/data/configuration.yaml ]; then
    echo "   • $BACKUP_DIR/configuration.yaml.backup"
fi
echo "   • $BACKUP_DIR/zigbee-security-params.txt"
echo "   • $(dirname "$BACKUP_DIR")/$(basename "$BACKUP_DIR").tar.gz"
echo ""
echo -e "${YELLOW}⚠️  ВАЖНО: Сохраните эти файлы в безопасном месте!${NC}"
echo -e "${YELLOW}💡 Рекомендуется: пароль-менеджер, зашифрованный файл или сейф${NC}"
echo ""
echo -e "${BLUE}📖 Для восстановления используйте:${NC}"
echo "   ./restore-security.sh $BACKUP_DIR" 