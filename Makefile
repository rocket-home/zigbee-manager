MAKEFLAGS += --no-print-directory
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

.PHONY: help start stop restart status logs logs-mqtt logs-zigbee clean detect configure setup env permissions apply-group generate-configs secure-setup generate-security pull restart-mqtt restart-zigbee config-check test-mqtt backup restore backup-system restore-system permit-join-enable permit-join-disable permit-join-temp permit-join-status monitor-devices monitor-devices-all monitor-devices-filter info cloud-mqtt-setup cloud-mqtt-enable cloud-mqtt-disable cloud-mqtt-status cloud-mqtt-test cloud-mqtt-credentials mqtt-subscribe mqtt-publish

# Основная команда помощи
help: ## Показать справку по командам
	@echo "$(BLUE)Zigbee2MQTT с MQTT Broker - Команды управления$(NC)"
	@echo ""
	@echo "$(GREEN)Основные команды:$(NC)"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(YELLOW)%-15s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
	@echo "$(GREEN)Используемая команда Docker Compose:$(NC) $(DOCKER_COMPOSE_CMD)"

# Настройка и инициализация (без параметров безопасности)
setup: ## Первоначальная настройка системы (без параметров безопасности)
	@echo "$(BLUE)🔧 Настройка Zigbee2MQTT с MQTT Broker...$(NC)"
	@# Проверка наличия .env файла
	@if [ ! -f $(ENV_FILE) ]; then \
		echo "$(RED)❌ Файл .env не найден!$(NC)"; \
		echo "$(YELLOW)💡 Сначала выполните: make env$(NC)"; \
		echo "$(BLUE)📝 Это создаст .env из env.example и откроет его в редакторе$(NC)"; \
		echo "$(BLUE)📝 После настройки .env выполните: make setup$(NC)"; \
		exit 1; \
	fi
	@echo "$(GREEN)✅ Файл .env найден$(NC)"
	@# Выполнение команд в правильном порядке
	@echo "$(BLUE)📋 Выполнение команд настройки...$(NC)"
	@echo "$(YELLOW)1️⃣ Настройка прав доступа...$(NC)"
	@$(MAKE) permissions
	@echo "$(YELLOW)2️⃣ Применение группы dialout...$(NC)"
	@$(MAKE) apply-group
	@echo "$(YELLOW)3️⃣ Обнаружение Zigbee адаптеров...$(NC)"
	@$(MAKE) detect
	@echo "$(YELLOW)4️⃣ Генерация конфигураций...$(NC)"
	@AUTO=true $(MAKE) generate-configs
	@echo "$(GREEN)✅ Настройка завершена!$(NC)"
	@echo "$(BLUE)📋 Следующие шаги:$(NC)"
	@echo "   1. Запустите систему: make start"
	@echo "   2. Проверьте статус: make status"

# Управление файлом .env
env: ## Создать .env из примера
	@echo "$(BLUE)📝 Управление файлом .env...$(NC)"
	@if [ -f $(ENV_FILE) ]; then \
		echo "$(YELLOW)⚠️  Файл .env уже существует!$(NC)"; \
		echo -n "$(YELLOW)Перезаписать из env.example? [y/N] $(NC)"; \
		read -r ans; \
		if [ "$$ans" = "y" ] || [ "$$ans" = "Y" ]; then \
			echo "$(BLUE)📝 Копирование env.example в .env...$(NC)"; \
			cp env.example $(ENV_FILE); \
			echo "$(GREEN)✅ Файл .env перезаписан из env.example$(NC)"; \
		else \
			echo "$(BLUE)ℹ️  Используется существующий файл .env$(NC)"; \
		fi; \
	else \
		echo "$(BLUE)📝 Создание .env из env.example...$(NC)"; \
		cp env.example $(ENV_FILE); \
		echo "$(GREEN)✅ Файл .env создан из env.example$(NC)"; \
	fi
	@echo "$(BLUE)📝 Файл .env готов для редактирования: $(ENV_FILE)$(NC)"
	@echo "$(YELLOW)💡 Отредактируйте файл вручную или используйте команду: make cloud-mqtt-credentials$(NC)"

# Обнаружение Zigbee адаптера
detect: ## Обнаружить доступные Zigbee адаптеры
	@echo "$(BLUE)🔍 Поиск Zigbee адаптеров...$(NC)"
	@echo "$(YELLOW)Проверка USB устройств...$(NC)"
	@echo "$(BLUE)📋 Подробная информация об устройствах:$(NC)"
	@echo ""
	@found_zigbee=false; \
	for port in /dev/ttyACM* /dev/ttyUSB*; do \
		if [ -e "$$port" ]; then \
			echo "$(YELLOW)🔍 Анализ $$port:$(NC)"; \
			device_info=$$(udevadm info --name=$$port --query=property 2>/dev/null); \
			if [ -n "$$device_info" ]; then \
				vendor_id=$$(echo "$$device_info" | grep -i "ID_VENDOR_ID" | cut -d= -f2); \
				product_id=$$(echo "$$device_info" | grep -i "ID_MODEL_ID" | cut -d= -f2); \
				vendor_name=$$(echo "$$device_info" | grep -i "ID_VENDOR" | cut -d= -f2 | head -1); \
				product_name=$$(echo "$$device_info" | grep -i "ID_MODEL" | cut -d= -f2 | head -1); \
				serial=$$(echo "$$device_info" | grep -i "ID_SERIAL" | cut -d= -f2 | head -1); \
				echo "   📍 Порт: $$port"; \
				echo "   🏭 Производитель: $$vendor_name"; \
				echo "   📦 Модель: $$product_name"; \
				echo "   🆔 Vendor ID: $$vendor_id"; \
				echo "   🆔 Product ID: $$product_id"; \
				echo "   🔢 Серийный номер: $$serial"; \
				echo "   🔐 Права: $$(ls -la $$port | awk '{print $$1, $$3, $$4}')"; \
				\
				# Проверка на известные Zigbee адаптеры \
				is_zigbee=false; \
				case "$$vendor_id:$$product_id" in \
					"0451:bef3"|"0451:bef4"|"0451:bef5") \
						echo "   ✅ $(GREEN)Определен как Texas Instruments CC2531 Zigbee адаптер$(NC)"; \
						is_zigbee=true; \
						found_zigbee=true; \
						;; \
					"0451:16c8"|"0451:16c9") \
						echo "   ✅ $(GREEN)Определен как Texas Instruments CC2538 Zigbee адаптер$(NC)"; \
						is_zigbee=true; \
						found_zigbee=true; \
						;; \
					"10c4:ea60"|"10c4:ea61"|"10c4:ea70") \
						echo "   ❓ $(YELLOW)Silicon Labs CP210x - USB-to-Serial чип$(NC)"; \
						echo "   ℹ️  $(BLUE)Может использоваться в Zigbee адаптерах, но не является Zigbee устройством$(NC)"; \
						is_zigbee=false; \
						;; \
					"0403:6001"|"0403:6015") \
						echo "   ❓ $(YELLOW)FTDI FT232/FT245 - USB-to-Serial чип$(NC)"; \
						echo "   ℹ️  $(BLUE)Может использоваться в Zigbee адаптерах, но не является Zigbee устройством$(NC)"; \
						is_zigbee=false; \
						;; \
					"1a86:7523"|"1a86:5523") \
						echo "   ❓ $(YELLOW)QinHeng Electronics CH340/CH341 - USB-to-Serial чип$(NC)"; \
						echo "   ℹ️  $(BLUE)Может использоваться в Zigbee адаптерах, но не является Zigbee устройством$(NC)"; \
						is_zigbee=false; \
						;; \
					"067b:2303"|"067b:2302") \
						echo "   ❓ $(YELLOW)Prolific Technology PL2303 - USB-to-Serial чип$(NC)"; \
						echo "   ℹ️  $(BLUE)Может использоваться в Zigbee адаптерах, но не является Zigbee устройством$(NC)"; \
						is_zigbee=false; \
						;; \
					*) \
						if echo "$$product_name" | grep -qi "zigbee\|cc2531\|cc2538\|cc2652\|cc1352\|sniffer\|coordinator"; then \
							echo "   ✅ $(GREEN)Определен как Zigbee адаптер по названию$(NC)"; \
							is_zigbee=true; \
							found_zigbee=true; \
						else \
							echo "   ❓ $(YELLOW)Неизвестное устройство - возможно не Zigbee адаптер$(NC)"; \
						fi; \
						;; \
				esac; \
				\
				if [ "$$is_zigbee" = "true" ]; then \
					echo "   💡 $(BLUE)Рекомендуется для использования с Zigbee2MQTT$(NC)"; \
					# Определение типа адаптера \
					case "$$vendor_id:$$product_id" in \
						"0451:16c8"|"0451:16c9") \
							echo "   ⭐ $(GREEN)CC2538 - специализированный Zigbee микроконтроллер$(NC)"; \
							;; \
						"0451:bef3"|"0451:bef4"|"0451:bef5") \
							echo "   ⭐ $(GREEN)CC2531 - специализированный Zigbee микроконтроллер$(NC)"; \
							;; \
						*) \
							echo "   ℹ️  $(BLUE)Стандартный Zigbee адаптер$(NC)"; \
							;; \
					esac; \
				else \
					echo "   ⚠️  $(YELLOW)Возможно обычный USB-to-Serial адаптер$(NC)"; \
				fi; \
				echo ""; \
			else \
				echo "   ❌ $(RED)Не удалось получить информацию об устройстве$(NC)"; \
				echo "   🔐 Права: $$(ls -la $$port | awk '{print $$1, $$3, $$4}')"; \
				echo ""; \
			fi; \
		fi; \
	done; \
	\
	if [ "$$found_zigbee" = "false" ]; then \
		echo "$(RED)❌ Zigbee адаптеры не обнаружены$(NC)"; \
		echo "$(YELLOW)💡 Убедитесь, что Zigbee адаптер подключен и определяется системой$(NC)"; \
		echo "$(BLUE)💡 Обнаружены USB-to-Serial устройства, но они не являются Zigbee адаптерами$(NC)"; \
	else \
		echo "$(GREEN)✅ Zigbee адаптеры обнаружены!$(NC)"; \
	fi

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

# Генерация конфигураций из шаблонов
generate-configs: ## Сгенерировать конфигурации из шаблонов с envsubst
	@echo "$(BLUE)🔧 Генерация конфигураций из шаблонов...$(NC)"
	@if [ -f zigbee2mqtt/data/configuration.yaml ] && [ -z "$$FORCE" ] && [ -z "$$AUTO" ]; then \
		echo "$(RED)⚠️  ВНИМАНИЕ: Файл конфигурации Zigbee2MQTT уже существует и будет перезаписан!$(NC)"; \
		echo -n "$(YELLOW)Продолжить и перезаписать конфигурацию? [y/N] $(NC)"; \
		read -r ans; \
		if [ "$$ans" != "y" ] && [ "$$ans" != "Y" ]; then \
			echo "$(YELLOW)Операция отменена.$(NC)"; \
			false; \
		fi; \
	fi
	@if [ ! -f /usr/bin/envsubst ]; then \
		echo "$(RED)❌ envsubst не найден. Установите gettext-base:$(NC)"; \
		echo "$(YELLOW)   sudo apt-get install gettext-base$(NC)"; \
		exit 1; \
	fi
	@cd scripts && ./generate-configs.sh

# Полная безопасная настройка (с параметрами безопасности)
secure-setup: setup generate-security ## Полная безопасная настройка системы с генерацией PAN ID, Extended PAN ID и Network Key
	@echo "$(GREEN)✅ Система настроена с безопасными параметрами!$(NC)"
	@echo "$(BLUE)📋 Следующие шаги:$(NC)"
	@echo "   1. Запустите систему: make start"
	@echo "   2. Проверьте статус: make status"

# Принудительная генерация новых параметров безопасности
generate-security: ## Принудительно сгенерировать новые параметры безопасности (ОСТОРОЖНО!)
	@if [ -z "$$FORCE" ]; then \
		echo "$(RED)⚠️  ВНИМАНИЕ: Эта операция сгенерирует НОВЫЕ параметры безопасности сети!$(NC)"; \
		echo "$(YELLOW)💡 Существующие параметры будут перезаписаны.$(NC)"; \
		echo "$(YELLOW)💡 Все подключенные устройства потеряют связь с сетью!$(NC)"; \
		echo -n "$(YELLOW)Продолжить и сгенерировать новые параметры? [y/N] $(NC)"; \
		read -r ans; \
		if [ "$$ans" != "y" ] && [ "$$ans" != "Y" ]; then \
			echo "$(YELLOW)Операция отменена.$(NC)"; \
			false; \
		fi; \
	fi
	@echo "$(BLUE)🔐 Принудительная генерация новых параметров безопасности...$(NC)"
	@if [ ! -f $(ENV_FILE) ]; then \
		echo "$(RED)❌ Файл .env не найден. Сначала выполните: make setup${NC}"; \
		exit 1; \
	fi
	@# Очищаем существующие параметры безопасности для принудительной генерации
	@sed -i '/^ZIGBEE_PAN_ID=/d' $(ENV_FILE) 2>/dev/null || true
	@sed -i '/^ZIGBEE_EXTENDED_PAN_ID=/d' $(ENV_FILE) 2>/dev/null || true
	@sed -i '/^ZIGBEE_NETWORK_KEY=/d' $(ENV_FILE) 2>/dev/null || true
	@cd scripts && ./generate-configs.sh
	@echo "$(GREEN)✅ Новые параметры безопасности сгенерированы!$(NC)"
	@echo "$(YELLOW)⚠️  ВНИМАНИЕ: Все устройства нужно будет переподключить к сети!${NC}"

# Запуск системы
start: ## Запустить все сервисы
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
	@echo "   • Zigbee2MQTT Web UI: http://localhost:$${ZIGBEE2MQTT_PORT:-8083}"

# Остановка системы
stop: ## Остановить все сервисы
	@echo "$(BLUE)🛑 Остановка Zigbee2MQTT с MQTT Broker...$(NC)"
	@$(DOCKER_COMPOSE_CMD) down
	@echo "$(GREEN)✅ Все сервисы остановлены!$(NC)"

# Перезапуск системы
restart: ## Перезапустить все сервисы
	@echo "$(BLUE)🔄 Перезапуск Zigbee2MQTT с MQTT Broker...$(NC)"
	@$(DOCKER_COMPOSE_CMD) down
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
	@echo "$(GREEN)✅ Сервисы перезапущены!$(NC)"
	@echo "$(BLUE)📋 Доступные сервисы:$(NC)"
	@echo "   • MQTT Broker: mqtt://localhost:$${MQTT_PORT:-1883}"
	@echo "   • MQTT WebSocket: ws://localhost:$${MQTT_WS_PORT:-9001}"
	@echo "   • Zigbee2MQTT Web UI: http://localhost:$${ZIGBEE2MQTT_PORT:-8083}"

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
	@echo "   • Zigbee2MQTT Web UI: http://localhost:$${ZIGBEE2MQTT_PORT:-8083}"

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
	@if [ -z "$$FORCE" ]; then \
		echo "$(RED)⚠️  ВНИМАНИЕ: Эта операция удалит ВСЕ данные системы!$(NC)"; \
		echo "$(YELLOW)💡 Конфигурации, данные MQTT и Zigbee2MQTT будут потеряны.$(NC)"; \
		echo -n "$(YELLOW)Продолжить и удалить все данные? [y/N] $(NC)"; \
		read -r ans; \
		if [ "$$ans" != "y" ] && [ "$$ans" != "Y" ]; then \
			echo "$(YELLOW)Операция отменена.$(NC)"; \
			false; \
		fi; \
	fi
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

# Резервное копирование безопасности
backup: ## Создать резервную копию параметров безопасности
	@echo "$(BLUE)🔐 Создание резервной копии параметров безопасности...$(NC)"
	@cd scripts && ./backup-security.sh

# Восстановление безопасности
restore: ## Восстановить параметры безопасности из резервной копии
	@echo "$(BLUE)🔄 Восстановление параметров безопасности...$(NC)"
	@if [ -z "$(BACKUP_PATH)" ]; then \
		echo "$(RED)❌ Не указан путь к резервной копии$(NC)"; \
		echo "$(YELLOW)💡 Использование: make restore BACKUP_PATH=backups/20250726_143022$(NC)"; \
		exit 1; \
	fi
	@if [ -z "$$FORCE" ]; then \
		echo "$(RED)⚠️  ВНИМАНИЕ: Эта операция перезапишет существующие параметры безопасности!$(NC)"; \
		echo "$(YELLOW)💡 Текущие параметры будут потеряны.$(NC)"; \
		echo -n "$(YELLOW)Продолжить и восстановить параметры? [y/N] $(NC)"; \
		read -r ans; \
		if [ "$$ans" != "y" ] && [ "$$ans" != "Y" ]; then \
			echo "$(YELLOW)Операция отменена.$(NC)"; \
			false; \
		fi; \
	fi
	@cd scripts && ./restore-security.sh ../$(BACKUP_PATH)

# Полное резервное копирование системы
backup-system: ## Создать полную резервную копию всей системы
	@echo "$(BLUE)🔐 Создание полной резервной копии системы...$(NC)"
	@if [ -z "$(NAME)" ]; then \
		echo "$(YELLOW)💡 Использование: make backup-system NAME=имя_резервной_копии$(NC)"; \
		echo "$(YELLOW)💡 Пример: make backup-system NAME=before-update$(NC)"; \
		echo "$(BLUE)📝 Создание резервной копии с автоматическим именем...$(NC)"; \
	fi
	@cd scripts && ./backup-system.sh "$(NAME)"

# Восстановление системы
restore-system: ## Восстановить всю систему из полной резервной копии
	@echo "$(BLUE)🔄 Восстановление системы из полной резервной копии...$(NC)"
	@if [ -z "$(BACKUP_FILE)" ]; then \
		echo "$(RED)❌ Не указан путь к архиву резервной копии$(NC)"; \
		echo "$(YELLOW)💡 Использование: make restore-system BACKUP_FILE=backups/zigbee-manager-backup-20250726_143022.tar.gz$(NC)"; \
		exit 1; \
	fi
	@if [ -z "$$FORCE" ]; then \
		echo "$(RED)⚠️  ВНИМАНИЕ: Эта операция перезапишет все существующие файлы системы!$(NC)"; \
		echo "$(YELLOW)💡 Текущие конфигурации и данные будут потеряны.$(NC)"; \
		echo -n "$(YELLOW)Продолжить и восстановить систему? [y/N] $(NC)"; \
		read -r ans; \
		if [ "$$ans" != "y" ] && [ "$$ans" != "Y" ]; then \
			echo "$(YELLOW)Операция отменена.$(NC)"; \
			false; \
		fi; \
	fi
	@cd scripts && ./restore-system.sh ../$(BACKUP_FILE)

# Управление permit_join
permit-join-enable: ## Включить permit_join для подключения устройств
	@echo "$(BLUE)🔓 Включение permit_join...$(NC)"
	@if [ ! -f $(ENV_FILE) ]; then \
		echo "$(RED)❌ Файл .env не найден!$(NC)"; \
		echo "$(YELLOW)💡 Сначала выполните: make env$(NC)"; \
		exit 1; \
	fi
	@echo "$(YELLOW)📝 Обновление переменной PERMIT_JOIN в .env...$(NC)"
	@if grep -q "^PERMIT_JOIN=" $(ENV_FILE); then \
		sed -i 's/^PERMIT_JOIN=.*/PERMIT_JOIN=true/' $(ENV_FILE); \
	else \
		echo "PERMIT_JOIN=true" >> $(ENV_FILE); \
	fi
	@echo "$(GREEN)✅ PERMIT_JOIN установлен в true$(NC)"
	@echo "$(YELLOW)📝 Перегенерация конфигурации...$(NC)"
	@AUTO=true $(MAKE) generate-configs
	@echo "$(YELLOW)🔄 Перезапуск Zigbee2MQTT...$(NC)"
	@$(MAKE) restart-zigbee
	@echo "$(GREEN)✅ Permit join включен на постоянной основе$(NC)"
	@echo "$(YELLOW)💡 Устройства могут подключаться к сети$(NC)"

permit-join-disable: ## Выключить permit_join
	@echo "$(BLUE)🔒 Выключение permit_join...$(NC)"
	@if [ ! -f $(ENV_FILE) ]; then \
		echo "$(RED)❌ Файл .env не найден!$(NC)"; \
		echo "$(YELLOW)💡 Сначала выполните: make env$(NC)"; \
		exit 1; \
	fi
	@echo "$(YELLOW)📝 Обновление переменной PERMIT_JOIN в .env...$(NC)"
	@if grep -q "^PERMIT_JOIN=" $(ENV_FILE); then \
		sed -i 's/^PERMIT_JOIN=.*/PERMIT_JOIN=false/' $(ENV_FILE); \
	else \
		echo "PERMIT_JOIN=false" >> $(ENV_FILE); \
	fi
	@echo "$(GREEN)✅ PERMIT_JOIN установлен в false$(NC)"
	@echo "$(YELLOW)📝 Перегенерация конфигурации...$(NC)"
	@AUTO=true $(MAKE) generate-configs
	@echo "$(YELLOW)🔄 Перезапуск Zigbee2MQTT...$(NC)"
	@$(MAKE) restart-zigbee
	@echo "$(GREEN)✅ Permit join выключен$(NC)"
	@echo "$(YELLOW)💡 Устройства не могут подключаться к сети$(NC)"

permit-join-temp: ## Включить permit_join на указанное время (в минутах)
	@echo "$(BLUE)⏰ Включение permit_join на временной период...$(NC)"
	@if [ -z "$(MINUTES)" ]; then \
		echo "$(RED)❌ Не указано время в минутах$(NC)"; \
		echo "$(YELLOW)💡 Использование: make permit-join-temp MINUTES=5$(NC)"; \
		exit 1; \
	fi
	@cd scripts && ./permit-join.sh enable-temp $(MINUTES)

permit-join-status: ## Проверить статус permit_join
	@echo "$(BLUE)🔍 Проверка статуса permit_join...$(NC)"
	@cd scripts && ./permit-join.sh status

# Мониторинг устройств
monitor-devices: ## Мониторинг логов присоединения устройств
	@echo "$(BLUE)📡 Запуск мониторинга устройств...$(NC)"
	@cd scripts && ./monitor-devices.sh

monitor-devices-all: ## Мониторинг всех MQTT сообщений
	@echo "$(BLUE)📡 Запуск мониторинга всех сообщений...$(NC)"
	@cd scripts && ./monitor-devices.sh --all

monitor-devices-filter: ## Мониторинг с фильтром
	@echo "$(BLUE)📡 Запуск мониторинга с фильтром...$(NC)"
	@if [ -z "$(FILTER)" ]; then \
		echo "$(RED)❌ Не указан фильтр$(NC)"; \
		echo "$(YELLOW)💡 Использование: make monitor-devices-filter FILTER=join$(NC)"; \
		echo "$(BLUE)📋 Примеры фильтров:$(NC)"; \
		echo "   • FILTER=join,left          # Несколько слов"; \
		echo "   • FILTER=+join,-error       # Включить 'join', исключить 'error'"; \
		echo "   • FILTER=-permit            # Исключить все с 'permit'"; \
		exit 1; \
	fi
	@cd scripts && ./monitor-devices.sh --filter "$(FILTER)"



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

# Управление облачным MQTT брокером
cloud-mqtt-setup: ## Настроить подключение к облачному MQTT брокеру
	@echo "$(BLUE)☁️  Настройка облачного MQTT брокера...$(NC)"
	@cd scripts && ./cloud-mqtt-config.sh

cloud-mqtt-enable: ## Включить мост к облачному MQTT
	@echo "$(BLUE)☁️  Включение моста к облачному MQTT...$(NC)"
	@if [ ! -f $(ENV_FILE) ]; then \
		echo "$(RED)❌ Файл .env не найден. Сначала выполните: make setup${NC}"; \
		exit 1; \
	fi
	@if grep -q "^CLOUD_MQTT_ENABLED=" $(ENV_FILE); then \
		sed -i 's/^CLOUD_MQTT_ENABLED=.*/CLOUD_MQTT_ENABLED=true/' $(ENV_FILE); \
	else \
		echo "CLOUD_MQTT_ENABLED=true" >> $(ENV_FILE); \
	fi
	@echo "$(GREEN)✅ Мост к облачному MQTT включен${NC}"
	@echo "$(YELLOW)💡 Перезапустите сервисы: make restart${NC}"

cloud-mqtt-disable: ## Отключить мост к облачному MQTT
	@echo "$(BLUE)☁️  Отключение моста к облачному MQTT...$(NC)"
	@if [ ! -f $(ENV_FILE) ]; then \
		echo "$(RED)❌ Файл .env не найден${NC}"; \
		exit 1; \
	fi
	@if grep -q "^CLOUD_MQTT_ENABLED=" $(ENV_FILE); then \
		sed -i 's/^CLOUD_MQTT_ENABLED=.*/CLOUD_MQTT_ENABLED=false/' $(ENV_FILE); \
	else \
		echo "CLOUD_MQTT_ENABLED=false" >> $(ENV_FILE); \
	fi
	@echo "$(GREEN)✅ Мост к облачному MQTT отключен${NC}"
	@echo "$(YELLOW)💡 Перезапустите сервисы: make restart${NC}"

cloud-mqtt-status: ## Проверить статус моста к облачному MQTT
	@echo "$(BLUE)☁️  Статус моста к облачному MQTT...$(NC)"
	@if [ ! -f $(ENV_FILE) ]; then \
		echo "$(RED)❌ Файл .env не найден${NC}"; \
		exit 1; \
	fi
	@if grep -q "^CLOUD_MQTT_ENABLED=true" $(ENV_FILE); then \
		echo "$(GREEN)✅ Мост к облачному MQTT включен${NC}"; \
		echo "$(BLUE)📋 Параметры:${NC}"; \
		grep "^CLOUD_MQTT_" $(ENV_FILE) | grep -v "PASSWORD" | sed 's/^/   • /'; \
		echo ""; \
		echo "$(BLUE)🔍 Проверка состояния соединения:${NC}"; \
		if $(DOCKER_COMPOSE_CMD) ps mqtt | grep -q "Up"; then \
			echo "$(GREEN)✅ MQTT контейнер запущен${NC}"; \
			echo "$(BLUE)📋 Статус мостового соединения:${NC}"; \
			# Проверяем последние записи о мосте \
			if $(DOCKER_COMPOSE_CMD) logs --tail=20 mqtt 2>/dev/null | grep -q "bridge"; then \
				echo "$(BLUE)   Последние записи о мосте:${NC}"; \
				$(DOCKER_COMPOSE_CMD) logs --tail=20 mqtt 2>/dev/null | grep "bridge" | tail -3 | sed 's/^/     • /'; \
				# Проверяем статус подключения \
				if $(DOCKER_COMPOSE_CMD) logs --tail=50 mqtt 2>/dev/null | grep -q "bridge.*connected\|bridge.*Connected"; then \
					echo "$(GREEN)   ✅ Мост подключен к облачному брокеру${NC}"; \
				elif $(DOCKER_COMPOSE_CMD) logs --tail=50 mqtt 2>/dev/null | grep -q "bridge.*failed\|bridge.*error\|bridge.*disconnected"; then \
					echo "$(RED)   ❌ Мост отключен или есть ошибки${NC}"; \
					echo "$(YELLOW)   Последние ошибки моста:${NC}"; \
					$(DOCKER_COMPOSE_CMD) logs --tail=50 mqtt 2>/dev/null | grep -i "bridge.*error\|bridge.*failed\|bridge.*disconnect" | tail -2 | sed 's/^/     • /'; \
				elif $(DOCKER_COMPOSE_CMD) logs --tail=20 mqtt 2>/dev/null | grep -q "PINGREQ\|PINGRESP\|PUBLISH.*bridge"; then \
					echo "$(GREEN)   ✅ Мост активен (есть обмен сообщениями)${NC}"; \
				else \
					echo "$(YELLOW)   ⚠️  Статус моста неопределён${NC}"; \
				fi; \
			else \
				echo "$(YELLOW)   • Записей о мосте не найдено${NC}"; \
				echo "$(YELLOW)   💡 Возможно, мост не настроен или не запущен${NC}"; \
			fi; \
		else \
			echo "$(RED)❌ MQTT контейнер не запущен${NC}"; \
			echo "$(YELLOW)💡 Запустите сервисы: make start${NC}"; \
		fi; \
	else \
		echo "$(YELLOW)ℹ️  Мост к облачному MQTT отключен${NC}"; \
		echo "$(BLUE)💡 Для включения выполните: make cloud-mqtt-enable${NC}"; \
	fi

cloud-mqtt-test: ## Протестировать двусторонний обмен сообщениями через облачный MQTT мост
	@echo "$(BLUE)☁️  Тестирование двустороннего обмена сообщениями через облачный MQTT мост...$(NC)"
	@if [ ! -f $(ENV_FILE) ]; then \
		echo "$(RED)❌ Файл .env не найден${NC}"; \
		exit 1; \
	fi
	@if ! grep -q "^CLOUD_MQTT_ENABLED=true" $(ENV_FILE); then \
		echo "$(YELLOW)ℹ️  Мост к облачному MQTT отключен${NC}"; \
		echo "$(BLUE)💡 Для включения выполните: make cloud-mqtt-enable${NC}"; \
		exit 1; \
	fi
	@if ! command -v mosquitto_pub >/dev/null 2>&1 || ! command -v mosquitto_sub >/dev/null 2>&1; then \
		echo "$(YELLOW)⚠️  mosquitto-clients не установлен. Установите для тестирования.${NC}"; \
		echo "$(BLUE)💡 Ubuntu/Debian: sudo apt install mosquitto-clients${NC}"; \
		echo "$(BLUE)💡 CentOS/RHEL: sudo yum install mosquitto-clients${NC}"; \
		exit 1; \
	fi
	@echo "$(YELLOW)🔍 Проверка статуса MQTT контейнера...$(NC)"
	@if ! $(DOCKER_COMPOSE_CMD) ps mqtt | grep -q "Up"; then \
		echo "$(RED)❌ MQTT контейнер не запущен${NC}"; \
		echo "$(BLUE)💡 Запустите сервисы: make start${NC}"; \
		exit 1; \
	fi
	@echo "$(GREEN)✅ MQTT контейнер запущен${NC}"
	@echo "$(YELLOW)🧪 Запуск теста двустороннего обмена сообщениями...$(NC)"
	@echo ""
	@./scripts/test-cloud-bridge-bidirectional.sh

# Настройка учетных данных облачного MQTT
cloud-mqtt-credentials: ## Настроить учетные данные для облачного MQTT брокера
	@echo "$(BLUE)🔐 Настройка учетных данных облачного MQTT...$(NC)"
	@if [ ! -f $(ENV_FILE) ]; then \
		echo "$(RED)❌ Файл .env не найден!$(NC)"; \
		echo "$(YELLOW)💡 Сначала выполните: make env$(NC)"; \
		exit 1; \
	fi
	@echo "$(BLUE)📝 Введите учетные данные для облачного MQTT брокера:$(NC)"
	@echo -n "$(YELLOW)Логин: $(NC)"; \
	read -r username; \
	if [ -z "$$username" ]; then \
		echo "$(RED)❌ Логин не может быть пустым$(NC)"; \
		exit 1; \
	fi; \
	echo -n "$(YELLOW)Пароль: $(NC)"; \
	read password; \
	echo ""; \
	if [ -z "$$password" ]; then \
		echo "$(RED)❌ Пароль не может быть пустым$(NC)"; \
		exit 1; \
	fi; \
	echo "$(BLUE)📝 Сохранение учетных данных в .env...$(NC)"; \
	if grep -q "^CLOUD_MQTT_USERNAME=" $(ENV_FILE); then \
		sed -i "s/^CLOUD_MQTT_USERNAME=.*/CLOUD_MQTT_USERNAME=$$username/" $(ENV_FILE); \
	else \
		echo "CLOUD_MQTT_USERNAME=$$username" >> $(ENV_FILE); \
	fi; \
	if grep -q "^CLOUD_MQTT_PASSWORD=" $(ENV_FILE); then \
		sed -i "s/^CLOUD_MQTT_PASSWORD=.*/CLOUD_MQTT_PASSWORD=$$password/" $(ENV_FILE); \
	else \
		echo "CLOUD_MQTT_PASSWORD=$$password" >> $(ENV_FILE); \
	fi; \
	echo "$(GREEN)✅ Учетные данные сохранены!$(NC)"; \
	echo "$(BLUE)📝 Включение облачного MQTT...$(NC)"; \
	if grep -q "^CLOUD_MQTT_ENABLED=" $(ENV_FILE); then \
		sed -i 's/^CLOUD_MQTT_ENABLED=.*/CLOUD_MQTT_ENABLED=true/' $(ENV_FILE); \
	else \
		echo "CLOUD_MQTT_ENABLED=true" >> $(ENV_FILE); \
	fi; \
	echo "$(GREEN)✅ Облачный MQTT включен!$(NC)"; \
	echo "$(BLUE)📋 Следующие шаги:$(NC)"; \
	echo "   1. Перегенерируйте конфигурации: make generate-configs"; \
	echo "   2. Перезапустите сервисы: make restart"; \
	echo "   3. Проверьте статус моста: make cloud-mqtt-status"

mqtt-subscribe: ## Подписаться на топик локального MQTT (использование: make mqtt-subscribe TOPIC="zigbee2mqtt/#")
	@echo "$(BLUE)📡 Подписка на топик локального MQTT...$(NC)"
	@if [ ! -f $(ENV_FILE) ]; then \
		echo "$(RED)❌ Файл .env не найден${NC}"; \
		exit 1; \
	fi
	@if ! command -v mosquitto_sub >/dev/null 2>&1; then \
		echo "$(YELLOW)⚠️  mosquitto-clients не установлен. Установите для подписки.${NC}"; \
		echo "$(BLUE)💡 Ubuntu/Debian: sudo apt install mosquitto-clients${NC}"; \
		echo "$(BLUE)💡 CentOS/RHEL: sudo yum install mosquitto-clients${NC}"; \
		exit 1; \
	fi
	@if [ -z "$(TOPIC)" ]; then \
		echo "$(YELLOW)ℹ️  Топик не указан. Используйте: make mqtt-subscribe TOPIC=\"zigbee2mqtt/#\"${NC}"; \
		echo "$(BLUE)📋 Примеры топиков:${NC}"; \
		echo "   • zigbee2mqtt/# (все сообщения Zigbee2MQTT)"; \
		echo "   • zigbee2mqtt/bridge/state (статус моста)"; \
		echo "   • zigbee2mqtt/bridge/devices (устройства)"; \
		echo "   • zigbee2mqtt/+/state (статус всех устройств)"; \
		echo "   • # (все сообщения)"; \
		exit 1; \
	fi
	@echo "$(YELLOW)🔍 Проверка статуса MQTT контейнера...$(NC)"
	@if ! $(DOCKER_COMPOSE_CMD) ps mqtt | grep -q "Up"; then \
		echo "$(RED)❌ MQTT контейнер не запущен${NC}"; \
		echo "$(BLUE)💡 Запустите сервисы: make start${NC}"; \
		exit 1; \
	fi
	@echo "$(GREEN)✅ MQTT контейнер запущен${NC}"
	@echo "$(BLUE)📡 Подписка на топик: $(TOPIC)${NC}"
	@echo "$(YELLOW)💡 Для остановки нажмите Ctrl+C${NC}"
	@echo ""
	@mosquitto_sub -h localhost -p 1883 -u admin -P admin -t "$(TOPIC)" -v 

mqtt-publish: ## Опубликовать сообщение в локальный MQTT (использование: make mqtt-publish TOPIC="test/topic" MESSAGE="Hello World")
	@echo "$(BLUE)📤 Публикация сообщения в локальный MQTT...$(NC)"
	@if [ ! -f $(ENV_FILE) ]; then \
		echo "$(RED)❌ Файл .env не найден${NC}"; \
		exit 1; \
	fi
	@if ! command -v mosquitto_pub >/dev/null 2>&1; then \
		echo "$(YELLOW)⚠️  mosquitto-clients не установлен. Установите для публикации.${NC}"; \
		echo "$(BLUE)💡 Ubuntu/Debian: sudo apt install mosquitto-clients${NC}"; \
		echo "$(BLUE)💡 CentOS/RHEL: sudo yum install mosquitto-clients${NC}"; \
		exit 1; \
	fi
	@if [ -z "$(TOPIC)" ]; then \
		echo "$(YELLOW)ℹ️  Топик не указан. Используйте: make mqtt-publish TOPIC=\"test/topic\" MESSAGE=\"Hello World\"${NC}"; \
		echo "$(BLUE)📋 Примеры использования:${NC}"; \
		echo "   • make mqtt-publish TOPIC=\"test/topic\" MESSAGE=\"Hello World\"${NC}"; \
		echo "   • make mqtt-publish TOPIC=\"zigbee2mqtt/bridge/request/restart\" MESSAGE=\"\"${NC}"; \
		echo "   • make mqtt-publish TOPIC=\"zigbee2mqtt/bridge/request/backup\" MESSAGE=\"\"${NC}"; \
		exit 1; \
	fi
	@if [ -z "$(MESSAGE)" ] && [ "$(MESSAGE)" != "" ]; then \
		echo "$(YELLOW)ℹ️  Сообщение не указано. Используйте: make mqtt-publish TOPIC=\"test/topic\" MESSAGE=\"Hello World\"${NC}"; \
		exit 1; \
	fi
	@echo "$(YELLOW)🔍 Проверка статуса MQTT контейнера...$(NC)"
	@if ! $(DOCKER_COMPOSE_CMD) ps mqtt | grep -q "Up"; then \
		echo "$(RED)❌ MQTT контейнер не запущен${NC}"; \
		echo "$(BLUE)💡 Запустите сервисы: make start${NC}"; \
		exit 1; \
	fi
	@echo "$(GREEN)✅ MQTT контейнер запущен${NC}"
	@echo "$(BLUE)📤 Публикация в топик: $(TOPIC)${NC}"
	@echo "$(BLUE)📝 Сообщение: $(MESSAGE)${NC}"
	@echo ""
	@if mosquitto_pub -h localhost -p 1883 -u admin -P admin -t "$(TOPIC)" -m "$(MESSAGE)"; then \
		echo "$(GREEN)✅ Сообщение успешно опубликовано!${NC}"; \
	else \
		echo "$(RED)❌ Ошибка публикации сообщения${NC}"; \
		exit 1; \
	fi

 