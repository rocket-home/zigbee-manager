# Миграция на новую структуру конфигурации MQTT

## ✅ Успешная миграция завершена!

Проект был успешно обновлен для использования директивы `include_dir` согласно [документации Mosquitto](https://mosquitto.org/man/mosquitto-conf-5.html) для более гибкого управления конфигурациями мостов.

## Что изменилось

### 1. Структура директорий

**Было:**
```
mqtt/config/
├── mosquitto.conf
└── mosquitto-bridge.conf
```

**Стало:**
```
mqtt/config/
├── mosquitto.conf
└── bridge/
    ├── cloud-bridge.conf.disabled.backup
    ├── test-bridge.conf
    └── README.md
```

### 2. Конфигурационный файл

**Было:**
```bash
# Встроенная конфигурация моста прямо в mosquitto.conf
include /mosquitto/config/mosquitto-bridge.conf
```

**Стало:**
```bash
# Автоматическое подключение всех .conf файлов из директории bridge
include_dir /mosquitto/config/bridge/
```

### 3. Преимущества новой структуры

- **Модульность**: Каждый мост в отдельном файле
- **Масштабируемость**: Легко добавлять новые мосты
- **Управляемость**: Файлы загружаются в алфавитном порядке
- **Стандартность**: Соответствует рекомендациям Mosquitto

## ✅ Проверка работы

### Логи MQTT брокера показывают успешную работу:

```bash
# Загрузка конфигурации моста
1753587319: Loading config file /mosquitto/config/bridge//test-bridge.conf

# Успешная инициализация моста
1753587319: Bridge local.6a8d3ed95f7c.test-bridge doing local SUBSCRIBE on topic test/#

# Подключение к удаленному брокеру
1753587319: Connecting bridge test-bridge (test.mosquitto.org:1883)

# MQTT брокер запущен
1753587319: mosquitto version 2.0.11 running

# Zigbee2MQTT подключается
1753587319: New client connected from 172.18.0.3:33516 as zigbee2mqtt_bridge
```

### Проверка структуры файлов:

```bash
ls -la mqtt/config/bridge/
# Результат:
# - test-bridge.conf (рабочая конфигурация)
# - cloud-bridge.conf.disabled.backup (отключенная конфигурация)
# - README.md (документация)
```

## Как это работает

### Директива include_dir

Согласно документации Mosquitto, директива `include_dir` работает следующим образом:

```bash
include_dir <directory>
```

- Включает все файлы с расширением `.conf` из указанной директории
- Файлы загружаются в алфавитном порядке
- Позволяет разделить конфигурацию на несколько файлов

### Пример использования

1. **Основной конфиг** (`mosquitto.conf`):
   ```bash
   # Основные настройки MQTT брокера
   listener 1883
   protocol mqtt
   allow_anonymous true
   
   # Подключение конфигураций мостов
   include_dir /mosquitto/config/bridge/
   ```

2. **Конфигурация моста** (`bridge/test-bridge.conf`):
   ```bash
   connection test-bridge
   address test.mosquitto.org:1883
   topic test/# out 1
   ```

## Миграция существующих конфигураций

### Автоматическая миграция

Скрипт `generate-configs.sh` автоматически:
- Создает директорию `mqtt/config/bridge/`
- Перемещает существующие конфигурации мостов
- Обновляет основной конфигурационный файл

### Ручная миграция

Если у вас есть собственные конфигурации мостов:

1. Создайте директорию:
   ```bash
   mkdir -p mqtt/config/bridge/
   ```

2. Переместите файлы конфигураций мостов:
   ```bash
   mv mqtt/config/your-bridge.conf mqtt/config/bridge/
   ```

3. Обновите основной конфиг:
   ```bash
   # Добавьте в mosquitto.conf:
   include_dir /mosquitto/config/bridge/
   ```

## Добавление новых мостов

### Через скрипты

1. Настройте переменные в `.env`:
   ```bash
   CLOUD_MQTT_ENABLED=true
   CLOUD_MQTT_HOST=your-broker.com
   CLOUD_MQTT_PORT=8883
   # ... другие параметры
   ```

2. Запустите генерацию:
   ```bash
   ./scripts/generate-configs.sh
   ```

### Вручную

1. Создайте файл в `mqtt/config/bridge/`:
   ```bash
   # mqtt/config/bridge/my-bridge.conf
   connection my-bridge
   address my-broker.com:1883
   topic my-topic/# out 1
   ```

2. Перезапустите сервисы:
   ```bash
   make restart
   ```

## Проверка работы

### Проверка конфигурации

```bash
# Проверить структуру файлов
ls -la mqtt/config/bridge/

# Проверить основной конфиг
cat mqtt/config/mosquitto.conf | grep include_dir

# Проверить конфигурации мостов
cat mqtt/config/bridge/*.conf
```

### Проверка в контейнере

```bash
# Проверить, что Mosquitto видит конфигурации
docker exec mqtt-broker ls -la /mosquitto/config/bridge/

# Проверить логи Mosquitto
docker logs mqtt-broker | grep -i bridge
```

## Обратная совместимость

- Старые конфигурации автоматически мигрируются
- Скрипты обновлены для работы с новой структурой
- Docker Compose конфигурация не изменилась

## Устранение неполадок

### Проблема: Мосты не загружаются

1. Проверьте права доступа:
   ```bash
   ls -la mqtt/config/bridge/
   ```

2. Проверьте синтаксис конфигурации:
   ```bash
   docker exec mqtt-broker mosquitto -c /mosquitto/config/mosquitto.conf --test-config
   ```

3. Проверьте логи:
   ```bash
   docker logs mqtt-broker
   ```

### Проблема: Конфликты имен мостов

- Убедитесь, что каждый мост имеет уникальное имя `connection`
- Файлы загружаются в алфавитном порядке

### Проблема: Неподдерживаемые параметры

В Mosquitto 2.0.11 некоторые параметры bridge могут иметь другие имена. Используйте минимальную конфигурацию:

```bash
connection bridge-name
address remote-broker:port
topic topic-pattern direction qos
```

## Дополнительные ресурсы

- [Документация Mosquitto](https://mosquitto.org/man/mosquitto-conf-5.html)
- [Руководство по мостам](https://mosquitto.org/documentation/bridge-configuration/)
- [Примеры конфигураций](https://github.com/eclipse/mosquitto/tree/master/docker)

## 🎉 Результат

✅ **Миграция успешно завершена!**

- Директива `include_dir` работает корректно
- MQTT брокер загружает конфигурации мостов из директории `bridge/`
- Zigbee2MQTT подключается и работает
- Система готова к добавлению новых мостов 