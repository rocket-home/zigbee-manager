# Makefile для Zigbee2MQTT с MQTT Broker
# Автор: Zigbee Manager

# Переменные
DOCKER_COMPOSE_CMD := $(shell if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then echo "docker compose"; elif command -v docker-compose >/dev/null 2>&1; then echo "docker-compose"; else echo "docker-compose"; fi)
PROJECT_NAME := zigbee-manager
ENV_FILE := .env

# Цвета для вывода
GREEN := \033[0;32m
YELLOW := \033[1;33m
RED := \033[0;31m
BLUE := \033[0;34m
NC := \033[0m # No Color

.PHONY: help start stop restart status logs clean detect configure setup

# Основная команда помощи
help: ## Показать справку по командам
	@echo "$(BLUE)Zigbee2MQTT с MQTT Broker - Команды управления$(NC)"
	@echo ""
	@echo "$(GREEN)Основные команды:$(NC)"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(YELLOW)%-15s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
	@echo "$(GREEN)Используемая команда Docker Compose:$(NC) $(DOCKER_COMPOSE_CMD)"

# Настройка и инициализация
setup: ## Первоначальная настройка системы
	@echo "$(BLUE)🔧 Настройка Zigbee2MQTT с MQTT Broker...$(NC)"
	@if [ ! -f $(ENV_FILE) ]; then \
		echo "$(YELLOW)📝 Создание файла .env из примера...$(NC)"; \
		cp env.example $(ENV_FILE); \
		echo "$(GREEN)✅ Файл .env создан. Отредактируйте его под свои нужды.$(NC)"; \
	else \
		echo "$(GREEN)✅ Файл .env уже существует.$(NC)"; \
	fi
	@echo "$(YELLOW)📁 Создание необходимых директорий...$(NC)"
	@mkdir -p mqtt/config mqtt/data mqtt/log zigbee2mqtt/data scripts templates
	@echo "$(GREEN)✅ Директории созданы.$(NC)"
	@if [ ! -f zigbee2mqtt/data/configuration.yaml ]; then \
		echo "$(YELLOW)📝 Создание файла конфигурации Zigbee2MQTT...$(NC)"; \
		cp zigbee2mqtt/data/configuration.yaml.example zigbee2mqtt/data/configuration.yaml 2>/dev/null || \
		echo "$(YELLOW)⚠️  Файл конфигурации не найден. Создайте его вручную или используйте make generate-config$(NC)"; \
	fi

# Обнаружение Zigbee адаптера
detect: ## Обнаружить доступные Zigbee адаптеры
	@echo "$(BLUE)🔍 Поиск Zigbee адаптеров...$(NC)"
	@echo "$(YELLOW)Проверка /dev/ttyACM*:$(NC)"
	@if ls /dev/ttyACM* 2>/dev/null; then \
		echo "$(GREEN)✅ Найдены адаптеры на /dev/ttyACM*$(NC)"; \
	else \
		echo "$(RED)❌ Адаптеры на /dev/ttyACM* не найдены$(NC)"; \
	fi
	@echo "$(YELLOW)Проверка /dev/ttyUSB*:$(NC)"
	@if ls /dev/ttyUSB* 2>/dev/null; then \
		echo "$(GREEN)✅ Найдены адаптеры на /dev/ttyUSB*$(NC)"; \
	else \
		echo "$(RED)❌ Адаптеры на /dev/ttyUSB* не найдены$(NC)"; \
	fi
	@echo ""
	@echo "$(BLUE)📋 Информация о правах доступа:$(NC)"
	@for port in /dev/ttyACM* /dev/ttyUSB*; do \
		if [ -e "$$port" ]; then \
			echo "$(YELLOW)$$port:$(NC) $$(ls -la $$port | awk '{print $$1, $$3, $$4}')"; \
		fi; \
	done

# Настройка порта Zigbee адаптера
configure: ## Настроить порт Zigbee адаптера
	@echo "$(BLUE)⚙️  Настройка Zigbee адаптера...$(NC)"
	@if [ ! -f $(ENV_FILE) ]; then \
		echo "$(RED)❌ Файл .env не найден. Выполните 'make setup' сначала.$(NC)"; \
		exit 1; \
	fi
	@echo "$(YELLOW)Доступные порты:$(NC)"
	@make detect
	@echo ""
	@echo "$(YELLOW)Текущая настройка в .env:$(NC)"
	@if grep -q "ZIGBEE_ADAPTER_PORT" $(ENV_FILE); then \
		grep "ZIGBEE_ADAPTER_PORT" $(ENV_FILE); \
	else \
		echo "$(RED)ZIGBEE_ADAPTER_PORT не настроен$(NC)"; \
	fi
	@echo ""
	@echo "$(BLUE)Для изменения порта отредактируйте файл .env$(NC)"
	@echo "$(YELLOW)Пример: ZIGBEE_ADAPTER_PORT=/dev/ttyACM0$(NC)"

# Настройка прав доступа к адаптеру
permissions: ## Настроить права доступа к Zigbee адаптеру
	@echo "$(BLUE)🔐 Настройка прав доступа к Zigbee адаптеру...$(NC)"
	@echo "$(YELLOW)Добавление пользователя в группу dialout...$(NC)"
	@if ! groups $$USER | grep -q dialout; then \
		echo "$(YELLOW)Добавление пользователя $$USER в группу dialout...$(NC)"; \
		sudo usermod -a -G dialout $$USER; \
		echo "$(GREEN)✅ Пользователь $$USER добавлен в группу dialout$(NC)"; \
		echo "$(YELLOW)⚠️  Перезайдите в систему или выполните 'newgrp dialout' для применения изменений$(NC)"; \
	else \
		echo "$(GREEN)✅ Пользователь $$USER уже в группе dialout$(NC)"; \
	fi
	@echo "$(YELLOW)Проверка прав доступа к портам...$(NC)"
	@for port in /dev/ttyACM* /dev/ttyUSB*; do \
		if [ -e "$$port" ]; then \
			echo "$(BLUE)Порт $$port:$(NC) $$(ls -la $$port | awk '{print $$1, $$3, $$4}')"; \
			if [ -r "$$port" ] && [ -w "$$port" ]; then \
				echo "$(GREEN)✅ Права доступа к $$port настроены$(NC)"; \
			else \
				echo "$(RED)❌ Нет прав доступа к $$port$(NC)"; \
				echo "$(YELLOW)💡 Перезайдите в систему или выполните 'newgrp dialout'$(NC)"; \
			fi; \
		fi; \
	done

# Применение группы без перезагрузки
apply-group: ## Применить группу dialout без перезагрузки
	@echo "$(BLUE)🔄 Применение группы dialout...$(NC)"
	@if groups $$USER | grep -q dialout; then \
		echo "$(YELLOW)Применение группы dialout для текущей сессии...$(NC)"; \
		newgrp dialout; \
		echo "$(GREEN)✅ Группа dialout применена$(NC)"; \
	else \
		echo "$(RED)❌ Пользователь $$USER не в группе dialout$(NC)"; \
		echo "$(YELLOW)💡 Сначала выполните: make permissions$(NC)"; \
	fi

# Генерация безопасной конфигурации
generate-config: ## Сгенерировать безопасные параметры Zigbee сети
	@echo "$(BLUE)🔐 Генерация безопасных параметров Zigbee сети...$(NC)"
	@if [ ! -f zigbee2mqtt/data/configuration.yaml ]; then \
		echo "$(RED)❌ Файл конфигурации не найден$(NC)"; \
		echo "$(YELLOW)💡 Сначала выполните: make setup$(NC)"; \
		exit 1; \
	fi
	@cd scripts && ./generate-config.sh

# Генерация конфигураций из шаблонов
generate-configs: ## Сгенерировать конфигурации из шаблонов с envsubst
	@echo "$(BLUE)🔧 Генерация конфигураций из шаблонов...$(NC)"
	@if [ ! -f /usr/bin/envsubst ]; then \
		echo "$(RED)❌ envsubst не найден. Установите gettext-base:$(NC)"; \
		echo "$(YELLOW)   sudo apt-get install gettext-base$(NC)"; \
		exit 1; \
	fi
	@cd scripts && ./generate-configs.sh

# Полная безопасная настройка
secure-setup: setup generate-configs ## Полная безопасная настройка системы с шаблонами
	@echo "$(GREEN)✅ Система настроена с безопасными параметрами!$(NC)"
	@echo "$(BLUE)📋 Следующие шаги:$(NC)"
	@echo "   1. Настройте права доступа: make permissions"
	@echo "   2. Запустите систему: make start"
	@echo "   3. Проверьте статус: make status"

# Запуск системы
start: setup ## Запустить все сервисы
	@echo "$(BLUE)🚀 Запуск Zigbee2MQTT с MQTT Broker...$(NC)"
	@echo "$(YELLOW)Проверка прав доступа...$(NC)"
	@if ! groups $$USER | grep -q dialout; then \
		echo "$(YELLOW)⚠️  Пользователь $$USER не в группе dialout$(NC)"; \
		echo "$(YELLOW)💡 Для настройки прав выполните: make permissions$(NC)"; \
		echo "$(YELLOW)   Затем перезайдите в систему или выполните: make apply-group$(NC)"; \
	else \
		echo "$(GREEN)✅ Пользователь $$USER в группе dialout$(NC)"; \
	fi
	@echo "$(YELLOW)Используется: $(DOCKER_COMPOSE_CMD)$(NC)"
	@$(DOCKER_COMPOSE_CMD) up -d
	@echo "$(GREEN)✅ Сервисы запущены!$(NC)"
	@echo "$(BLUE)📋 Доступные сервисы:$(NC)"
	@echo "   • MQTT Broker: mqtt://localhost:$${MQTT_PORT:-1883}"
	@echo "   • MQTT WebSocket: ws://localhost:$${MQTT_WS_PORT:-9001}"
	@echo "   • Zigbee2MQTT Web UI: http://localhost:$${ZIGBEE2MQTT_PORT:-8081}"

# Остановка системы
stop: ## Остановить все сервисы
	@echo "$(BLUE)🛑 Остановка Zigbee2MQTT с MQTT Broker...$(NC)"
	@$(DOCKER_COMPOSE_CMD) down
	@echo "$(GREEN)✅ Все сервисы остановлены!$(NC)"

# Перезапуск системы
restart: stop start ## Перезапустить все сервисы

# Статус системы
status: ## Показать статус всех сервисов
	@echo "$(BLUE)📊 Статус Zigbee2MQTT с MQTT Broker...$(NC)"
	@echo ""
	@echo "$(YELLOW)🐳 Статус Docker контейнеров:$(NC)"
	@$(DOCKER_COMPOSE_CMD) ps
	@echo ""
	@echo "$(BLUE)📋 Информация о сервисах:$(NC)"
	@echo "   • MQTT Broker: mqtt://localhost:$${MQTT_PORT:-1883}"
	@echo "   • MQTT WebSocket: ws://localhost:$${MQTT_WS_PORT:-9001}"
	@echo "   • Zigbee2MQTT Web UI: http://localhost:$${ZIGBEE2MQTT_PORT:-8081}"

# Просмотр логов
logs: ## Показать логи всех сервисов
	@echo "$(BLUE)📋 Логи сервисов:$(NC)"
	@$(DOCKER_COMPOSE_CMD) logs -f

# Логи MQTT
logs-mqtt: ## Показать логи MQTT сервера
	@echo "$(BLUE)📋 Логи MQTT сервера:$(NC)"
	@$(DOCKER_COMPOSE_CMD) logs -f mqtt

# Логи Zigbee2MQTT
logs-zigbee: ## Показать логи Zigbee2MQTT
	@echo "$(BLUE)📋 Логи Zigbee2MQTT:$(NC)"
	@$(DOCKER_COMPOSE_CMD) logs -f zigbee2mqtt

# Обновление образов
pull: ## Обновить Docker образы
	@echo "$(BLUE)📥 Обновление Docker образов...$(NC)"
	@$(DOCKER_COMPOSE_CMD) pull
	@echo "$(GREEN)✅ Образы обновлены!$(NC)"

# Перезапуск конкретного сервиса
restart-mqtt: ## Перезапустить MQTT сервер
	@echo "$(BLUE)🔄 Перезапуск MQTT сервера...$(NC)"
	@$(DOCKER_COMPOSE_CMD) restart mqtt
	@echo "$(GREEN)✅ MQTT сервер перезапущен!$(NC)"

restart-zigbee: ## Перезапустить Zigbee2MQTT
	@echo "$(BLUE)🔄 Перезапуск Zigbee2MQTT...$(NC)"
	@$(DOCKER_COMPOSE_CMD) restart zigbee2mqtt
	@echo "$(GREEN)✅ Zigbee2MQTT перезапущен!$(NC)"

# Очистка данных
clean: ## Очистить все данные (ОСТОРОЖНО!)
	@echo "$(RED)⚠️  ВНИМАНИЕ: Это удалит ВСЕ данные!$(NC)"
	@echo "$(YELLOW)Вы уверены? (y/N):$(NC)"
	@read -p "" confirm && [ "$$confirm" = "y" ] || exit 1
	@echo "$(BLUE)🧹 Очистка данных...$(NC)"
	@$(DOCKER_COMPOSE_CMD) down -v
	@sudo rm -rf mqtt/data/* zigbee2mqtt/data/*
	@echo "$(GREEN)✅ Данные очищены!$(NC)"

# Проверка конфигурации
config-check: ## Проверить конфигурацию
	@echo "$(BLUE)🔍 Проверка конфигурации...$(NC)"
	@echo "$(YELLOW)Проверка docker-compose.yml:$(NC)"
	@$(DOCKER_COMPOSE_CMD) config
	@echo ""
	@echo "$(YELLOW)Проверка переменных окружения:$(NC)"
	@if [ -f $(ENV_FILE) ]; then \
		echo "$(GREEN)✅ Файл .env найден$(NC)"; \
		echo "$(BLUE)Содержимое .env:$(NC)"; \
		cat $(ENV_FILE); \
	else \
		echo "$(RED)❌ Файл .env не найден$(NC)"; \
	fi

# Тестирование подключения
test-mqtt: ## Протестировать подключение к MQTT
	@echo "$(BLUE)🧪 Тестирование MQTT подключения...$(NC)"
	@if command -v mosquitto_pub >/dev/null 2>&1; then \
		echo "$(YELLOW)Отправка тестового сообщения...$(NC)"; \
		mosquitto_pub -h localhost -p $${MQTT_PORT:-1883} -t "test/connection" -m "Hello from Makefile" || echo "$(RED)❌ Ошибка подключения к MQTT$(NC)"; \
		echo "$(GREEN)✅ Тестовое сообщение отправлено!$(NC)"; \
	else \
		echo "$(YELLOW)⚠️  mosquitto-clients не установлен. Установите для тестирования.$(NC)"; \
	fi

# Информация о системе
info: ## Показать информацию о системе
	@echo "$(BLUE)ℹ️  Информация о системе:$(NC)"
	@echo "$(YELLOW)Docker версия:$(NC)"
	@docker --version
	@echo "$(YELLOW)Docker Compose команда:$(NC) $(DOCKER_COMPOSE_CMD)"
	@echo "$(YELLOW)Проект:$(NC) $(PROJECT_NAME)"
	@echo "$(YELLOW)Рабочая директория:$(NC) $(PWD)"
	@echo "$(YELLOW)Переменные окружения:$(NC)"
	@if [ -f $(ENV_FILE) ]; then \
		echo "$(GREEN)✅ Файл .env загружен$(NC)"; \
	else \
		echo "$(RED)❌ Файл .env не найден$(NC)"; \
	fi
	@echo "$(YELLOW)Версии образов:$(NC)"
	@echo "   • MQTT Broker: eclipse-mosquitto:2.0.18"
	@echo "   • Zigbee2MQTT: koenkk/zigbee2mqtt:1.42.0 (стабильная версия до 2.0)" 