# 🚀 Быстрый старт Zigbee2MQTT Manager

## ⚡ 5 минут до работающей системы

### 1️⃣ Подготовка (30 секунд)
```bash
git clone https://github.com/rocket-home/zigbee-manager.git
cd zigbee-manager
```

### 2️⃣ Настройка (1 минута)

```bash
# Обнаружить Zigbee адаптер
make detect
```

```bash
# Настроить права доступа
make permissions
```

```bash
# Безопасная настройка с генерацией параметров
make secure-setup
```

**💡 Примечание:** При повторных запусках `make generate-configs` существующие параметры безопасности сохраняются.

### 3️⃣ Запуск (30 секунд)

```bash
# Запустить систему
make start
```

```bash
# Проверить статус
make status
```

### 4️⃣ Доступ к интерфейсам
- **Zigbee2MQTT Web UI**: http://localhost:8081
- **MQTT Broker**: localhost:1883

### 5️⃣ Подключение устройств

```bash
# Включить режим подключения на 5 минут
make permit-join-temp MINUTES=5
```

```bash
# Открыть веб-интерфейс: http://localhost:8081
```

```bash
# Мониторинг подключения (в отдельном терминале)
make monitor-devices
```

# Подключение Zigbee устройств: следуйте инструкциям конкретных устройств

## ☁️ Облачный MQTT (опционально)

```bash
# Настроить подключение к облачному брокеру
make cloud-mqtt-setup
```

```bash
# Включить мост
make cloud-mqtt-enable
```

```bash
# Перезапустить для применения
make restart
```

## 🔐 Резервное копирование (рекомендуется)

```bash
# Создать полную резервную копию системы
make backup-system NAME=initial-setup
```

```bash
# Или только параметры безопасности
make backup
```

## 📚 Что дальше?

- **[README_USER.md](README_USER.md)** - Подробное руководство пользователя
- **[README.md](README.md)** - Техническая документация

## 🆘 Если что-то пошло не так

```bash
# Проверить конфигурацию
make config-check
```

```bash
# Посмотреть логи
make logs
```

```bash
# Перезапустить систему
make restart
```

---

**🎉 Готово! Ваша Zigbee сеть работает!** 