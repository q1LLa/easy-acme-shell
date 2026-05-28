#!/bin/bash

# Выход при любой ошибке
set -e

# Перенаправляем ввод на терминал, чтобы read работал внутри curl | bash
exec < /dev/tty

echo "=================================================="
echo "   Настройка SSL через Cloudflare API (DNS-01)   "
echo "=================================================="

# 1. Запрос домена
while [ -z "$DOMAIN" ]; do
    read -p "Введите ваш домен (например, vpn.domain.com): " DOMAIN
done

# 2. Запрос почты
while [ -z "$EMAIL" ]; do
    read -p "Введите ваш email для уведомлений: " EMAIL
done

# 3. Запрос данных Cloudflare API
echo "--------------------------------------------------"
echo "Учетные данные Cloudflare (нужны для DNS-проверки):"
while [ -z "$CF_TOKEN" ]; do
    read -p "-> Введите ваш Cloudflare API Token: " CF_TOKEN
done

while [ -z "$CF_ACCOUNT" ]; do
    read -p "-> Введите ваш Cloudflare Account ID: " CF_ACCOUNT
done

# 4. Запрос команды после обновления (с дефолтным значением)
echo "--------------------------------------------------"
DEFAULT_CMD="cd /opt/remnanode && docker compose down && docker compose up -d && sudo systemctl reload nginx"
echo "Какую команду выполнять после успешного обновления сертификата?"
echo "Нажмите [ENTER], чтобы использовать команду по умолчанию:"
echo "-> $DEFAULT_CMD"
read -p "Или введите свою (оставьте пустой, если команда не нужна): " USER_CMD

# Определяем итоговую команду
if [ -z "$USER_CMD" ]; then
    RELOAD_CMD="$DEFAULT_CMD"
else
    RELOAD_CMD="$USER_CMD"
fi

echo "=================================================="
echo " Начинаем установку для $DOMAIN"
echo "=================================================="

# 5. Устанавливаем зависимости
echo "--- Установка dependencies ---"
sudo apt update
sudo apt install -y curl socat

# 6. Качаем и ставим acme.sh с ПРАВИЛЬНЫМ email
echo "--- Установка acme.sh ---"
curl https://get.acme.sh | sh -s email="$EMAIL"

# Настраиваем окружение для текущей сессии скрипта
export LE_CONFIG_HOME="$HOME/.acme.sh"
export CF_Token="$CF_TOKEN"
export CF_Account_ID="$CF_ACCOUNT"

# 7. Переключаем дефолтный CA на Let's Encrypt
echo "--- Переключение на Let's Encrypt ---"
"$HOME/.acme.sh/acme.sh" --set-default-ca --server letsencrypt

# 8. Выпускаем сертификат через DNS API Cloudflare
echo "--- Выпуск сертификата для $DOMAIN через DNS API ---"

if [ -n "$RELOAD_CMD" ] && [ "$RELOAD_CMD" != "none" ]; then
    echo "Команда перезапуска при обновлении: $RELOAD_CMD"
    "$HOME/.acme.sh/acme.sh" --issue --dns dns_cf -d "$DOMAIN" --reloadcmd "$RELOAD_CMD"
else
    echo "--- Выпуск без команды перезапуска ---"
    "$HOME/.acme.sh/acme.sh" --issue --dns dns_cf -d "$DOMAIN"
fi

echo "------------------------------------------------"
echo "Успешно! Сертификаты выпущены через DNS-проверку."
echo "Cloudflare API ключи и reloadcmd сохранены в конфиг."
echo "-> Путь: $HOME/.acme.sh/${DOMAIN}_ecc/"
echo "------------------------------------------------"
