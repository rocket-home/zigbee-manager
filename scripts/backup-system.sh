#!/usr/bin/env bash

# Скрипт для полного резервного копирования системы Zigbee2MQTT Manager
# Использование: ./backup-system.sh [описание_резервной_копии]

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Проверка аргументов
BACKUP_NAME="${1:-z2m_$(date +%Y-%m-%d_%M)}"
BACKUP_FILE="zigbee-manager-backup-${BACKUP_NAME}"

echo -e "${BLUE}🔐 Создание полной резервной копии системы...${NC}"
echo -e "${YELLOW}📝 Имя: $BACKUP_NAME${NC}"

# Проверка наличия .env файла
if [ ! -f ../.env ]; then
    echo -e "${RED}❌ Файл .env не найден${NC}"
    echo -e "${YELLOW}💡 Сначала выполните: make setup${NC}"
    exit 1
fi

# Создание временной директории для резервной копии
TEMP_DIR="../backups/temp-$(date +%Y%m%d_%H%M%S)"
mkdir -p "$TEMP_DIR"

echo -e "${BLUE}📁 Создание структуры резервной копии...${NC}"

# Создание директории для конфигураций
mkdir -p "$TEMP_DIR/config"
mkdir -p "$TEMP_DIR/data"
mkdir -p "$TEMP_DIR/logs"

# 1. Копирование конфигурационных файлов
echo -e "${BLUE}📋 Копирование конфигурационных файлов...${NC}"

# Основные конфигурации
cp ../.env "$TEMP_DIR/config/"
cp ../docker-compose.yml "$TEMP_DIR/config/"
cp ../Makefile "$TEMP_DIR/config/"

# Конфигурации MQTT
if [ -f ../mqtt/config/mosquitto.conf ]; then
    cp ../mqtt/config/mosquitto.conf "$TEMP_DIR/config/"
fi

# Конфигурации Zigbee2MQTT
if [ -f ../zigbee2mqtt/data/configuration.yaml ]; then
    cp ../zigbee2mqtt/data/configuration.yaml "$TEMP_DIR/config/"
fi

# Шаблоны
if [ -d ../templates ]; then
    cp -r ../templates "$TEMP_DIR/config/"
fi

# 2. Копирование данных (если система не запущена)
echo -e "${BLUE}💾 Копирование данных...${NC}"

# Проверяем, запущена ли система
if docker ps | grep -q "mqtt-broker\|zigbee2mqtt"; then
    echo -e "${YELLOW}⚠️  Система запущена. Остановите её для полного резервного копирования:${NC}"
    echo -e "${YELLOW}   make stop${NC}"
    echo -e "${YELLOW}   Затем запустите резервное копирование снова.${NC}"
    echo -e "${BLUE}💡 Создаем резервную копию конфигураций без данных...${NC}"
else
    echo -e "${GREEN}✅ Система остановлена, копируем все данные...${NC}"
    
    # Данные MQTT
    if [ -d ../mqtt/data ] && [ "$(ls -A ../mqtt/data)" ]; then
        cp -r ../mqtt/data/* "$TEMP_DIR/data/"
    fi
    
    # Данные Zigbee2MQTT
    if [ -d ../zigbee2mqtt/data ] && [ "$(ls -A ../zigbee2mqtt/data)" ]; then
        cp -r ../zigbee2mqtt/data/* "$TEMP_DIR/data/"
    fi
    
    # Логи
    if [ -d ../mqtt/log ] && [ "$(ls -A ../mqtt/log)" ]; then
        cp -r ../mqtt/log/* "$TEMP_DIR/logs/"
    fi
fi

# 3. Создание метаданных резервной копии
echo -e "${BLUE}📝 Создание метаданных...${NC}"

cat > "$TEMP_DIR/backup-info.txt" << EOF
Zigbee2MQTT Manager - Полная резервная копия системы
==================================================
Дата создания: $(date)
Имя: $BACKUP_NAME
Версия системы: 1.0

Содержимое резервной копии:
- Конфигурационные файлы (.env, docker-compose.yml, Makefile)
- Конфигурации MQTT (mosquitto.conf)
- Конфигурации Zigbee2MQTT (configuration.yaml)
- Шаблоны конфигураций (templates/)
- Данные MQTT и Zigbee2MQTT (если система была остановлена)
- Логи системы (если система была остановлена)

Параметры безопасности Zigbee:
PAN ID: $(grep ZIGBEE_PAN_ID ../.env | cut -d= -f2)
Extended PAN ID: $(grep ZIGBEE_EXTENDED_PAN_ID ../.env | cut -d= -f2)
Network Key: $(grep ZIGBEE_NETWORK_KEY ../.env | cut -d= -f2)

Инструкции по восстановлению:
1. Распакуйте архив в пустую директорию
2. Выполните: make setup
3. Выполните: make restore-system BACKUP_FILE=путь_к_архиву
4. Запустите систему: make start

ВАЖНО: Сохраните эту резервную копию в безопасном месте!
EOF

# 4. Создание скрипта восстановления
echo -e "${BLUE}🔧 Создание скрипта восстановления...${NC}"

cat > "$TEMP_DIR/restore.sh" << 'EOF'
#!/usr/bin/env bash

# Скрипт восстановления системы из резервной копии
# Использование: ./restore.sh

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔄 Восстановление системы из резервной копии...${NC}"

# Проверка наличия файлов
if [ ! -f config/.env ]; then
    echo -e "${RED}❌ Файл .env не найден в резервной копии${NC}"
    exit 1
fi

# Остановка системы если запущена
if docker ps | grep -q "mqtt-broker\|zigbee2mqtt"; then
    echo -e "${YELLOW}🛑 Остановка запущенной системы...${NC}"
    docker-compose down 2>/dev/null || true
fi

# Создание необходимых директорий
mkdir -p mqtt/config mqtt/data mqtt/log zigbee2mqtt/data

# Восстановление конфигураций
echo -e "${BLUE}📁 Восстановление конфигураций...${NC}"
cp config/.env .env
cp config/docker-compose.yml docker-compose.yml
cp config/Makefile Makefile

if [ -f config/mosquitto.conf ]; then
    cp config/mosquitto.conf mqtt/config/
fi

if [ -f config/configuration.yaml ]; then
    cp config/configuration.yaml zigbee2mqtt/data/
fi

if [ -d config/templates ]; then
    cp -r config/templates ./
fi

# Восстановление данных
if [ -d data ] && [ "$(ls -A data)" ]; then
    echo -e "${BLUE}💾 Восстановление данных...${NC}"
    cp -r data/* mqtt/data/ 2>/dev/null || true
    cp -r data/* zigbee2mqtt/data/ 2>/dev/null || true
fi

# Восстановление логов
if [ -d logs ] && [ "$(ls -A logs)" ]; then
    echo -e "${BLUE}📋 Восстановление логов...${NC}"
    cp -r logs/* mqtt/log/ 2>/dev/null || true
fi

echo -e "${GREEN}✅ Восстановление завершено!${NC}"
echo -e "${BLUE}📋 Следующие шаги:${NC}"
echo "   1. Проверьте конфигурацию: make config-check"
echo "   2. Запустите систему: make start"
echo "   3. Проверьте статус: make status"
EOF

chmod +x "$TEMP_DIR/restore.sh"

# 5. Создание архива
echo -e "${BLUE}📦 Создание архива...${NC}"
cd "$(dirname "$TEMP_DIR")"
tar -czf "${BACKUP_FILE}.tar.gz" "$(basename "$TEMP_DIR")"
cd - > /dev/null

# 6. Очистка временной директории
rm -rf "$TEMP_DIR"

# 7. Вывод результатов
echo ""
echo -e "${GREEN}🎉 Полная резервная копия создана успешно!${NC}"
echo ""
echo -e "${BLUE}📋 Информация о резервной копии:${NC}"
echo "   • Имя файла: ${BACKUP_FILE}.tar.gz"
echo "   • Размер: $(du -h "$(dirname "$TEMP_DIR")/${BACKUP_FILE}.tar.gz" | cut -f1)"
echo "   • Расположение: $(dirname "$TEMP_DIR")/${BACKUP_FILE}.tar.gz"
echo ""
echo -e "${BLUE}📋 Содержимое резервной копии:${NC}"
echo "   • Конфигурационные файлы (.env, docker-compose.yml, Makefile)"
echo "   • Конфигурации MQTT и Zigbee2MQTT"
echo "   • Шаблоны конфигураций"
echo "   • Данные системы (если была остановлена)"
echo "   • Логи системы (если была остановлена)"
echo "   • Скрипт восстановления (restore.sh)"
echo "   • Информация о резервной копии (backup-info.txt)"
echo ""
echo -e "${YELLOW}⚠️  ВАЖНО: Сохраните этот архив в безопасном месте!${NC}"
echo -e "${YELLOW}💡 Рекомендуется: внешний диск, облачное хранилище или сейф${NC}"
echo ""
echo -e "${BLUE}📖 Для восстановления используйте:${NC}"
echo "   make restore-system BACKUP_FILE=$(dirname "$TEMP_DIR")/${BACKUP_FILE}.tar.gz" 