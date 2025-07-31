# 📡 Мониторинг устройств Zigbee2MQTT

## 🎯 Обзор

Система мониторинга позволяет отслеживать в реальном времени:
- Подключение новых устройств
- Отключение устройств
- События сети
- Ошибки подключения
- Статус permit_join

## 🚀 Быстрый старт

### Базовый мониторинг

```bash
# Мониторинг только устройств
make monitor-devices
```

### Расширенный мониторинг

```bash
# Все MQTT сообщения
make monitor-devices-all
```

```bash
# С фильтром по ключевому слову
make monitor-devices-filter FILTER=join
```


```

## 📋 Типы событий

### 🎉 Подключение устройств

```
[14:30:25] 🎉 НОВОЕ УСТРОЙСТВО ПОДКЛЮЧЕНО!
   📱 Детали: {"data":{"friendly_name":"0x00158d0009b1b2b3","ieee_address":"0x00158d0009b1b2b3"},"type":"device_joined"}
```

### 👋 Отключение устройств

```
[14:35:10] 👋 Устройство отключено
   📱 Детали: {"data":{"friendly_name":"0x00158d0009b1b2b3","ieee_address":"0x00158d0009b1b2b3"},"type":"device_left"}
```

### 📢 Объявления устройств

```
[14:32:15] 📢 Объявление устройства
   📱 Детали: {"data":{"friendly_name":"0x00158d0009b1b2b3"},"type":"device_announce"}
```

### 🔐 Permit Join статус

```
[14:30:00] 🔐 Permit join статус: true
```

### ❌ Ошибки

```
[14:30:05] ❌ Ошибка: Failed to join device
```

## 🔧 Опции мониторинга

### Фильтрация

```bash
# Только события подключения
make monitor-devices-filter FILTER=joined
```

```bash
# Только ошибки
make monitor-devices-filter FILTER=error
```

```bash
# Только конкретное устройство
make monitor-devices-filter FILTER=0x00158d0009b1b2b3
```

```bash
# Несколько паттернов (через запятую)
make monitor-devices-filter FILTER=join,left
```

```bash
# Включения и исключения
make monitor-devices-filter FILTER=+join,-error
```

```bash
# Только исключения (показать все, кроме)
make monitor-devices-filter FILTER=-permit,-announce
```

**Синтаксис фильтров:**
- `pattern` - включить сообщения с паттерном
- `+pattern` - явно включить сообщения с паттерном
- `-pattern` - исключить сообщения с паттерном
- `pattern1,pattern2` - несколько паттернов через запятую



### Комбинированные опции

```bash
# Фильтр (через скрипт)
cd scripts
./monitor-devices.sh --filter "join"
```

```bash
# Сложные фильтры
./monitor-devices.sh --filter "+join,+left,-error,-permit"
```

### Примеры фильтров

```bash
# Только подключения и отключения
FILTER=join,left

# Подключения, но не ошибки
FILTER=+join,-error

# Все, кроме permit_join сообщений
FILTER=-permit

# Конкретное устройство, но не ошибки
FILTER=0x00158d0009b1b2b3,-error

# Только события устройств (не логи)
FILTER=+device_joined,+device_left,+device_announce

# Исключить все служебные сообщения
FILTER=-permit,-announce,-response
```

## 📊 Мониторимые топики

| Топик | Описание |
|-------|----------|
| `zigbee2mqtt/bridge/log` | Логи Zigbee2MQTT |
| `zigbee2mqtt/bridge/event` | События (подключение/отключение) |
| `zigbee2mqtt/bridge/response` | Ответы на команды |

## 🎮 Практические сценарии

### Сценарий 1: Подключение нового устройства

```bash
# Терминал 1: Включить permit_join
make permit-join-enable
```

```bash
# Терминал 2: Мониторинг
make monitor-devices
```

```bash
# Терминал 1: Подключить устройство к питанию
# Терминал 2: Наблюдать за подключением
```

```bash
# Терминал 1: Выключить permit_join
make permit-join-disable
```

### Сценарий 2: Диагностика проблем

```bash
# Мониторинг всех сообщений
make monitor-devices-all
```

```bash
# Или фильтр по ошибкам
make monitor-devices-filter FILTER=error
```

### Сценарий 3: Мониторинг сети

```bash
# Длительный мониторинг в фоне
nohup make monitor-devices > monitoring.log 2>&1 &
```

```bash
# Или с фильтром
nohup make monitor-devices-filter FILTER=join > join-monitoring.log 2>&1 &
```

## 🔍 Цветовая схема

- 🟢 **Зеленый** - Успешные события (подключения, устройства)
- 🔵 **Синий** - Информационные сообщения
- 🟡 **Желтый** - Предупреждения (отключения)
- 🔴 **Красный** - Ошибки
- 🟣 **Фиолетовый** - Permit join статус

## ⚙️ Настройка

### Переменные окружения

```bash
# В файле .env
MQTT_BASE_TOPIC=zigbee2mqtt
MQTT_USER=your_username
MQTT_PASSWORD=your_password
```

### Пользовательские фильтры

```bash
# Создать алиас для часто используемых фильтров
alias monitor-join='make monitor-devices-filter FILTER=join'
```

```bash
alias monitor-errors='make monitor-devices-filter FILTER=error'
```

```bash
alias monitor-device='make monitor-devices-filter FILTER=0x00158d0009b1b2b3'
```

## 🆘 Устранение проблем

### Проблема: "Не удается подключиться к MQTT брокеру"

```bash
# Проверить статус системы
make status
```

```bash
# Запустить систему
make start
```

```bash
# Проверить MQTT
make test-mqtt
```

### Проблема: "Нет сообщений"

```bash
# Проверить все сообщения
make monitor-devices-all
```

```bash
# Проверить логи Zigbee2MQTT
make logs-zigbee
```

### Проблема: "Мониторинг не останавливается"

```bash
# Принудительная остановка
pkill -f "monitor-devices.sh"

# Или найти и остановить процесс
ps aux | grep monitor-devices
kill <PID>
```

## 💡 Советы

1. **Используйте фильтры** для фокусировки на нужных событиях
2. **Используйте Ctrl+C** для остановки мониторинга
3. **Мониторьте в отдельном терминале** при подключении устройств
4. **Сохраняйте логи** для анализа проблем
5. **Используйте цветовую схему** для быстрой идентификации событий

## 📚 Связанные команды

- `make permit-join-enable` - Включить режим подключения
- `make permit-join-disable` - Выключить режим подключения
- `make logs-zigbee` - Просмотр логов Zigbee2MQTT
- `make status` - Статус системы

---

**🎯 Удачного мониторинга!** 