# Zigbee2MQTT с MQTT Broker

Этот проект содержит docker-compose конфигурацию для запуска Zigbee2MQTT совместно с MQTT сервером (Eclipse Mosquitto) с поддержкой протокола MQTT 3.11 и интеграцией с облачным MQTT брокером.

## 🚀 Быстрый старт

Для быстрого запуска используйте **[QUICK_START.md](QUICK_START.md)** - полное руководство за 5 минут!

## Компоненты

- **MQTT Broker**: Eclipse Mosquitto 2.0.18
- **Zigbee2MQTT**: 1.42.0 (последняя стабильная версия до 2.0)
- **Протокол**: MQTT 3.11
- **Облачная интеграция**: Мост к облачному MQTT брокеру

## Структура проекта

```
zigbee-manager/
├── docker-compose.yml          # Docker Compose конфигурация
├── Makefile                    # Автоматизация команд
├── env.example                 # Пример переменных окружения
├── .env                        # Ваши настройки (создается из env.example)
├── templates/                  # Шаблоны конфигураций
│   ├── mosquitto.conf.template
│   ├── mosquitto-bridge.conf.template
│   └── zigbee2mqtt-config.yaml.template
├── mqtt/                       # MQTT Broker данные
│   ├── config/
│   │   ├── mosquitto.conf      # Основная конфигурация
│   │   └── bridge/
│   │       └── cloud-bridge.conf # Мост к облачному MQTT
│   ├── data/                   # Данные MQTT
│   └── log/                    # Логи MQTT
├── zigbee2mqtt/                # Zigbee2MQTT данные
│   └── data/
│       └── configuration.yaml  # Конфигурация Zigbee2MQTT
├── scripts/                    # Вспомогательные скрипты
├── backups/                    # Резервные копии
└── docs/                       # Документация
```

## 🛠️ Управление сервисами

### Основные команды

```bash
# Показать справку по командам
make help

# Первоначальная настройка
make env                    # Создать .env из env.example
make setup                  # Полная настройка системы
make secure-setup           # Настройка с генерацией безопасности

# Управление сервисами
make start                  # Запустить все сервисы
make stop                   # Остановить все сервисы
make restart                # Перезапустить все сервисы
make status                 # Проверить статус
make logs                   # Просмотр логов

# Обнаружение и настройка
make detect                 # Обнаружить Zigbee адаптеры
make configure              # Настроить порт адаптера
make permissions            # Настройка прав доступа
make apply-group            # Применить группу dialout

# Конфигурация
make generate-configs       # Сгенерировать конфигурации
make config-check           # Проверить конфигурацию

# Облачный MQTT
make cloud-mqtt-credentials # Настроить учетные данные
make cloud-mqtt-enable      # Включить облачный мост
make cloud-mqtt-disable     # Отключить облачный мост
make cloud-mqtt-status      # Статус облачного моста
make cloud-mqtt-test        # Тест облачного моста

# Управление устройствами
make permit-join-enable     # Включить подключение устройств
make permit-join-disable    # Отключить подключение устройств
make permit-join-status     # Статус подключения устройств
make monitor-devices        # Мониторинг устройств

# Резервное копирование
make backup                 # Резервная копия безопасности
make restore                # Восстановление безопасности
make backup-system          # Полная резервная копия
make restore-system         # Полное восстановление

# Тестирование
make test-mqtt              # Тест MQTT подключения
make mqtt-subscribe         # Подписка на топики
make mqtt-publish           # Публикация сообщений

# Обслуживание
make pull                   # Обновить Docker образы
make clean                  # Очистить все данные (ОСТОРОЖНО!)
make info                   # Информация о системе
```

## 📚 Документация

- **[QUICK_START.md](QUICK_START.md)** - Быстрый старт за 5 минут ⚡
- **[DOCKER_INSTALL.md](DOCKER_INSTALL.md)** - Установка Docker и Docker Compose
- **[README_USER.md](README_USER.md)** - Подробное руководство пользователя с примерами и FAQ
- **[MIGRATION.md](MIGRATION.md)** - Инструкция по миграции системы на новый хост
- **[MONITORING.md](MONITORING.md)** - Руководство по мониторингу устройств

## 🔧 Требования

- **ОС**: Linux (Ubuntu 20.04+, Debian 11+)
- **Docker**: 20.10+
- **Docker Compose**: 2.0+
- **Zigbee адаптер**: CC2531, CC2538, CC2652P или совместимый (и подключен)

## 🌐 Доступные интерфейсы

После запуска системы доступны:

- **MQTT Broker**: `mqtt://localhost:1883`
- **MQTT WebSocket**: `ws://localhost:9001`
- **Zigbee2MQTT Web UI**: `http://localhost:8083`

## 🔐 Безопасность

- Автоматическая генерация PAN ID, Extended PAN ID и Network Key
- Поддержка TLS для облачного MQTT моста
- Управление правами доступа к Zigbee адаптеру
- Резервное копирование параметров безопасности

## 🤝 Поддержка

Для получения помощи:
1. Проверьте **[QUICK_START.md](QUICK_START.md)**
2. Изучите **[README_USER.md](README_USER.md)**
3. Используйте `make help` для списка команд
4. Проверьте логи: `make logs`
