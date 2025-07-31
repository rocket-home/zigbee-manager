# Zigbee2MQTT с MQTT Broker

Этот проект содержит docker-compose конфигурацию для запуска Zigbee2MQTT совместно с MQTT сервером (Eclipse Mosquitto) с поддержкой протокола MQTT 3.11.

## Компоненты

- **MQTT Broker**: Eclipse Mosquitto 2.0.18
- **Zigbee2MQTT**: 1.42.0 (последняя стабильная версия до 2.0)
- **Протокол**: MQTT 3.11

## Структура проекта

```
zigbee-manager/
├── docker-compose.yml
├── mqtt/
│   ├── config/
│   │   └── mosquitto.conf
│   ├── data/
│   └── log/
└── zigbee2mqtt/
    └── data/
        └── configuration.yaml
```

## Управление сервисами

### Использование Makefile (рекомендуется)

```bash
# Показать справку по командам
make help
```
# Первоначальная настройка
```bash
make setup
```
# Обнаружение Zigbee адаптера
```bash
make detect
```
# Настройка порта адаптера
```bash
make configure
```
# Запуск системы
```bash
make start
```
# Проверка статуса
```bash
make status
```

# Остановка системы
```bash
make stop
```

# Перезапуск системы
```bash
make restart
```

# Просмотр логов
```bash
make logs
```
```bash
make logs-mqtt
```
```bash
make logs-zigbee
```

# Обновление образов
```bash
make pull
```
# Тестирование MQTT
```bash
make test-mqtt
```

# Информация о системе
```bash
make info
```

## 📚 Документация

- **[QUICK_START.md](QUICK_START.md)** - Быстрый старт за 5 минут ⚡
- **[README_USER.md](README_USER.md)** - Подробное руководство пользователя с примерами и FAQ
- **[MIGRATION.md](MIGRATION.md)** - Инструкция по миграции системы на новый хост
- **[MONITORING.md](MONITORING.md)** - Руководство по мониторингу устройств
- **[FILTER_EXAMPLES.md](FILTER_EXAMPLES.md)** - Мониторинг и примеры фильтров
- **[IMPROVEMENTS.md](IMPROVEMENTS.md)** - Описание улучшений документации
- **[README.md](README.md)** - Техническая документация для разработчиков
