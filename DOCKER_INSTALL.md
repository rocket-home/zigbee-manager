# 🐳 Установка Docker и Docker Compose

## Ubuntu (рекомендуемый способ)

### ⚡ Быстрая установка через Snap:

```bash
# Установить Docker через snap (самый простой способ)
sudo snap install docker

# Проверить установку
docker --version
docker compose version

# Добавить пользователя в группу docker
sudo usermod -aG docker $USER

# Перезайти в пользователя (или перезагрузить систему)
newgrp docker
```

### ✅ Проверка установки:

```bash
# Проверить версии
docker --version
docker compose version

# Проверить работу Docker
docker run hello-world

# Проверить права пользователя
groups $USER
```

### 🔄 Альтернативная установка через репозиторий:

```bash
# Обновить пакеты
sudo apt update

# Установить необходимые пакеты
sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release

# Добавить GPG ключ Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Добавить репозиторий Docker
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Установить Docker
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Добавить пользователя в группу docker
sudo usermod -aG docker $USER

# Запустить Docker
sudo systemctl start docker
sudo systemctl enable docker
```

---

## 🆘 Решение проблем

### Docker не запускается:
```bash
# Проверить статус Docker
sudo systemctl status docker

# Перезапустить Docker
sudo systemctl restart docker

# Проверить права пользователя
groups $USER

# Добавить пользователя в группу docker (если не добавлен)
sudo usermod -aG docker $USER
newgrp docker

# Проверить работу Docker
docker run hello-world
```

### Проблемы с snap:
```bash
# Переустановить Docker через snap
sudo snap remove docker
sudo snap install docker

# Или использовать альтернативную установку через репозиторий
```

### Проблемы с правами:
```bash
# Проверить группы пользователя
groups $USER

# Добавить в группу docker
sudo usermod -aG docker $USER

# Перезайти в пользователя
newgrp docker

# Или перезагрузить систему
sudo reboot
```

---

## ✅ Готово!

После успешной установки Docker вы можете:

1. **Вернуться к QUICK_START.md** для установки Zigbee2MQTT
2. **Проверить установку**: `docker run hello-world`
3. **Начать работу**: перейти к основному руководству

---

## 📚 Дополнительная информация

- **[Официальная документация Docker](https://docs.docker.com/engine/install/ubuntu/)**
- **[QUICK_START.md](QUICK_START.md)** - Быстрый старт Zigbee2MQTT 