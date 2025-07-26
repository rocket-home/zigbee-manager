# Zigbee2MQTT с MQTT Broker

Этот проект содержит docker-compose конфигурацию для запуска Zigbee2MQTT совместно с MQTT сервером (Eclipse Mosquitto) с поддержкой протокола MQTT 3.11.

## Компоненты

- **MQTT Broker**: Eclipse Mosquitto 2.0.18
- **Zigbee2MQTT**: 1.42.0 (последняя стабильная версия до 2.0)
- **Протокол**: MQTT 3.11/4.0

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

# Первоначальная настройка
make setup

# Обнаружение Zigbee адаптера
make detect

# Настройка порта адаптера
make configure

# Запуск системы
make start

# Проверка статуса
make status

# Остановка системы
make stop

# Перезапуск системы
make restart

# Просмотр логов
make logs
make logs-mqtt
make logs-zigbee

# Обновление образов
make pull

# Тестирование MQTT
make test-mqtt

# Информация о системе
make info
```

### Использование скриптов

```bash
# Запуск системы
./start.sh

# Проверка статуса
./status.sh

# Остановка системы
./stop.sh
```
```

## Быстрый старт

### 1. Безопасная настройка

Для максимальной безопасности рекомендуется использовать автоматическую генерацию параметров:

```bash
# Полная безопасная настройка (рекомендуется)
make secure-setup

# Или пошаговая настройка
make setup
make generate-config
```

### 2. Настройка прав доступа

Для работы с Zigbee адаптером необходимо добавить пользователя в группу `dialout`:

```bash
# Автоматическая настройка прав
make permissions

# Применить группу без перезагрузки (опционально)
make apply-group

# Или перезайти в систему для применения изменений
```

### 2. Подготовка Zigbee адаптера

Убедитесь, что ваш Zigbee адаптер подключен и определите его порт:

```bash
ls -la /dev/ttyACM*
# или
ls -la /dev/ttyUSB*
```

### 2. Настройка порта адаптера

Отредактируйте `docker-compose.yml` и замените `/dev/ttyACM0` на ваш порт:

```yaml
volumes:
  - /dev/ttyACM0:/dev/ttyACM0  # Замените на ваш порт
devices:
  - /dev/ttyACM0:/dev/ttyACM0  # Замените на ваш порт
```

### 3. Запуск сервисов

```bash
# Автоматический запуск с проверками
./start.sh

# Или вручную (автоматически определит команду)
docker compose up -d
# или
docker-compose up -d

# Просмотр логов
docker compose logs -f
# или
docker-compose logs -f

# Остановка сервисов
./stop.sh
# или
docker compose down
# или
docker-compose down
```

## Доступ к сервисам

- **MQTT Broker**: `mqtt://localhost:1883`
- **MQTT WebSocket**: `ws://localhost:9001`
- **Zigbee2MQTT Web UI**: `http://localhost:8080`

## Настройка MQTT

### Основные топики

- `zigbee2mqtt/bridge/state` - статус моста
- `zigbee2mqtt/bridge/devices` - список устройств
- `zigbee2mqtt/[device_name]/set` - управление устройством
- `zigbee2mqtt/[device_name]/get` - получение состояния

### Пример подключения MQTT клиента

```bash
# Подписка на все топики
mosquitto_sub -h localhost -p 1883 -t "zigbee2mqtt/#" -v

# Отправка команды устройству
mosquitto_pub -h localhost -p 1883 -t "zigbee2mqtt/light/set" -m '{"state": "ON"}'
```

## Настройка безопасности (опционально)

### 1. Создание пользователей MQTT

```bash
# Создание файла паролей
docker exec -it mqtt-broker mosquitto_passwd -c /mosquitto/config/password_file admin
```

### 2. Настройка ACL

Создайте файл `mqtt/config/acl_file`:

```
user admin
topic readwrite #
```

### 3. Обновление конфигурации

Раскомментируйте строки в `mqtt/config/mosquitto.conf`:

```conf
password_file /mosquitto/config/password_file
acl_file /mosquitto/config/acl_file
```

### 4. Обновление конфигурации Zigbee2MQTT

Добавьте учетные данные в `zigbee2mqtt/data/configuration.yaml`:

```yaml
mqtt:
  user: admin
  password: your_password
```

## Устранение неполадок

### Проверка статуса сервисов

```bash
docker compose ps
# или
docker-compose ps
```

### Просмотр логов

```bash
# Логи MQTT
docker compose logs mqtt
# или
docker-compose logs mqtt

# Логи Zigbee2MQTT
docker compose logs zigbee2mqtt
# или
docker-compose logs zigbee2mqtt
```

### Проверка подключения Zigbee адаптера

```bash
# Проверка доступности порта
ls -la /dev/ttyACM0

# Проверка прав доступа
sudo chmod 666 /dev/ttyACM0
```

### Сброс конфигурации

```bash
# Остановка сервисов
docker-compose down

# Удаление данных
sudo rm -rf mqtt/data/* zigbee2mqtt/data/*

# Перезапуск
docker-compose up -d
```

## Команды Makefile

### Основные команды

| Команда | Описание |
|---------|----------|
| `make help` | Показать справку по всем командам |
| `make setup` | Первоначальная настройка системы |
| `make secure-setup` | Полная безопасная настройка с генерацией параметров |
| `make generate-config` | Сгенерировать безопасные параметры Zigbee сети |
| `make detect` | Обнаружить доступные Zigbee адаптеры |
| `make configure` | Настроить порт Zigbee адаптера |
| `make permissions` | Настроить права доступа к адаптеру (добавить в группу dialout) |
| `make apply-group` | Применить группу dialout без перезагрузки |

### Управление сервисами

| Команда | Описание |
|---------|----------|
| `make start` | Запустить все сервисы |
| `make stop` | Остановить все сервисы |
| `make restart` | Перезапустить все сервисы |
| `make status` | Показать статус всех сервисов |
| `make restart-mqtt` | Перезапустить только MQTT сервер |
| `make restart-zigbee` | Перезапустить только Zigbee2MQTT |

### Логи и мониторинг

| Команда | Описание |
|---------|----------|
| `make logs` | Показать логи всех сервисов |
| `make logs-mqtt` | Показать логи MQTT сервера |
| `make logs-zigbee` | Показать логи Zigbee2MQTT |

### Обслуживание

| Команда | Описание |
|---------|----------|
| `make pull` | Обновить Docker образы |
| `make config-check` | Проверить конфигурацию |
| `make test-mqtt` | Протестировать подключение к MQTT |
| `make info` | Показать информацию о системе |
| `make clean` | Очистить все данные (ОСТОРОЖНО!) |

## Полезные команды

```bash
# Обновление образов
docker compose pull
# или
docker-compose pull

# Перезапуск конкретного сервиса
docker compose restart zigbee2mqtt
# или
docker-compose restart zigbee2mqtt

# Просмотр использования ресурсов
docker stats
```

## Безопасность

### Генерация безопасных параметров

Система автоматически генерирует криптографически стойкие параметры для Zigbee сети:

- **PAN ID**: Случайный 16-битный идентификатор сети
- **Extended PAN ID**: Случайный 64-битный расширенный идентификатор
- **Network Key**: Случайный 128-битный ключ шифрования

### Рекомендации по безопасности

1. **Используйте автоматическую генерацию**: `make secure-setup`
2. **Сохраните параметры**: Запишите сгенерированные значения в безопасном месте
3. **Регулярно обновляйте**: Перегенерируйте параметры при необходимости
4. **Ограничьте доступ**: Настройте MQTT аутентификацию
5. **Мониторьте логи**: Регулярно проверяйте логи на подозрительную активность

### Команды безопасности

```bash
# Генерация новых безопасных параметров
make generate-config

# Проверка текущей конфигурации
make config-check

# Просмотр логов для мониторинга
make logs
```

## Поддерживаемые Zigbee адаптеры

- CC2531
- CC2530
- CC26X2R1
- EFR32MG21
- EFR32MG13
- EFR32MG12
- И другие совместимые адаптеры

## Лицензия

MIT License 