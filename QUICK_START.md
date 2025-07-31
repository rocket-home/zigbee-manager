# 🚀 Zigbee2MQTT + Облачный MQTT

## 📋 Требования

### Системные требования:
- **ОС**: Linux (Ubuntu 20.04+, Debian 11+)
- **RAM**: минимум 2GB, рекомендуется 4GB+
- **Диск**: минимум 1GB свободного места
- **Сеть**: доступ к интернету для загрузки образов

### Оборудование:
- **Zigbee адаптер**: USB-адаптер (CC2531, CC2530, CC2652P, и др.) и подключен
- **Устройства**: Zigbee-совместимые устройства

### Программное обеспечение:
- **Docker**: версия 20.10+ ([инструкция по установке](DOCKER_INSTALL.md))
- **Docker Compose**: версия 2.0+ (входит в Docker)
- **Git**: для клонирования репозитория

---

### 📋 Что вы получите:
- ✅ Локальный Zigbee2MQTT сервер
- ✅ MQTT брокер для устройств
- ✅ Подключение к облачному MQTT
- ✅ Веб-интерфейс для управления
- ✅ Автоматическая синхронизация данных


---

## 🚀 Быстрый старт

```bash
git clone https://github.com/rocket-home/zigbee-manager.git
cd zigbee-manager
make env                    # Создает .env из env.example
make setup                  # Обычная настройка системы
# ИЛИ
make secure-setup           # Настройка с генерацией безопасности
make cloud-mqtt-credentials # Ввод имени и пароля для подключения к облачному MQTT
AUTO=true make generate-configs && make restart
make status                 # Проверить статус
# Открыть: http://localhost:8084
```

---

## 📱 Подключение устройств

### Включить режим подключения:
```bash
# На 5 минут
make permit-join-temp MINUTES=5

# Или постоянно (небезопасно)
make permit-join-enable
```

### Отслеживать подключения:
```bash
# Мониторинг в реальном времени
make monitor-devices
```

---

## 🔧 Основные команды

```bash
# Управление системой
make start          # Запуск
make stop           # Остановка
make restart        # Перезапуск
make status         # Статус

# Управление облачным MQTT
make cloud-mqtt-credentials    # Настройка учетных данных
make cloud-mqtt-status         # Статус моста
make cloud-mqtt-test           # Тест подключения

# Управление устройствами
make permit-join-enable        # Разрешить обнаружение устройств
make permit-join-disable       # Запретить обнаружение устройств
make monitor-devices           # Мониторинг устройств

# Резервное копирование
make backup-system NAME=backup # Полная резервная копия
make restore-system            # Восстановление
```

---

## 🆘 Решение проблем

### Система не запускается:
```bash
make logs              # Посмотреть логи
make config-check      # Проверить конфигурацию
make restart           # Перезапустить
```

### Устройства не подключаются:
```bash
make permit-join-enable    # Включить режим подключения
make monitor-devices       # Проверить статус устройств
```

### Облачный MQTT не работает:
```bash
make cloud-mqtt-status     # Проверить статус моста
make cloud-mqtt-test       # Запустить тест
make cloud-mqtt-credentials # Перенастроить учетные данные
```

### Zigbee адаптер не обнаружен:
```bash
# Проверить подключенные USB устройства
ls -la /dev/ttyACM* /dev/ttyUSB*

# Найти адаптер в системе
dmesg | grep -i tty

# Ручная настройка в .env файле
nano .env
# или
code .env
# или
vim .env

# Найти и изменить строку:
# ZIGBEE_ADAPTER_PORT=/dev/ttyACM0
# На ваш порт, например:
# ZIGBEE_ADAPTER_PORT=/dev/ttyUSB0

# Перегенерировать конфигурации
AUTO=true make generate-configs

# Перезапустить систему
make restart
```

**💡 Как найти правильный порт:**
```bash
# Подключите адаптер и выполните:
ls -la /dev/ttyACM* /dev/ttyUSB*

# Обычно адаптеры появляются как:
# /dev/ttyACM0  (CC2531, CC2652P)
# /dev/ttyUSB0  (CC2530, Sonoff Zigbee)
# /dev/ttyACM1  (если уже есть другие устройства)

# Проверить права доступа
ls -la /dev/ttyACM0
# Должно быть: crw-rw---- 1 root dialout

# Если нет прав, добавить пользователя в группу dialout:
sudo usermod -aG dialout $USER
newgrp dialout
```

### Проблемы с портами:
```bash
# Проверить занятые порты
sudo lsof -i :1883
sudo lsof -i :8084

# Остановить процессы на портах
sudo kill -9 <PID>
```

---

## 📚 Дополнительная информация

- **[DOCKER_INSTALL.md](DOCKER_INSTALL.md)** - Установка Docker и Docker Compose
- **[README_USER.md](README_USER.md)** - Подробное руководство пользователя
- **[README.md](README.md)** - Техническая документация
- **[MONITORING.md](MONITORING.md)** - Мониторинг и диагностика

---

## 🎉 Готово!

**Ваша система работает!** 

- 🌐 **Веб-интерфейс**: http://localhost:8084
- ☁️ **Облачный MQTT**: автоматически синхронизируется
- 📱 **Устройства**: подключаются через permit_join
- 🔄 **Данные**: синхронизируются между локальным и облачным MQTT

**Следующий шаг**: Подключите свои Zigbee устройства! 🚀 