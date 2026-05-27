#!/bin/bash

# Выход при любой ошибке
set -e

# Перенаправляем ввод на терминал, чтобы read работал внутри curl | bash
exec < /dev/tty

echo "=========================================="
echo "   Настройка параметров сертификата       "
echo "=========================================="

# Запрос домена
while [ -z "$DOMAIN" ]; do
    read -p "Введите ваш домен (например, vpn.domain.com): " DOMAIN
done

# Запрос почты
while [ -z "$EMAIL" ]; do
    read -p "Введите ваш email для уведомлений: " EMAIL
done

echo "=========================================="
echo " Начинаем установку для $DOMAIN ($EMAIL)"
echo "=========================================="

# 1. Устанавливаем зависимости
echo "--- Установка dependencies ---"
sudo apt update
sudo apt install -y curl socat

# 2. Качаем и ставим acme.sh с ПРАВИЛЬНЫМ email
echo "--- Установка acme.sh ---"
curl https://get.acme.sh | sh -s email="$EMAIL"

# Настраиваем окружение
export LE_CONFIG_HOME="$HOME/.acme.sh"

# 3. Переключаем дефолтный CA на Let's Encrypt
echo "--- Переключение на Let's Encrypt ---"
"$HOME/.acme.sh/acme.sh" --set-default-ca --server letsencrypt

# 4. Выпускаем сертификат через standalone (80 порт)
echo "--- Выпуск сертификата для $DOMAIN ---"
"$HOME/.acme.sh/acme.sh" --issue -d "$DOMAIN" --standalone

echo "------------------------------------------------"
echo "Успешно! Сертификаты лежат в папке по умолчанию:"
echo "-> $HOME/.acme.sh/${DOMAIN}_ecc/"
echo "------------------------------------------------"
