#!/bin/bash

# ==========================================
# НАСТРОЙКИ
# ==========================================
DOMAIN="yourdomain.com"
EMAIL="your-email@example.com"
# ==========================================

set -e

# 1. Устанавливаем зависимости (curl и socat нужны для работы standalone режима)
echo "--- Установка зависимостей ---"
sudo apt update
sudo apt install -y curl socat

# 2. Качаем и ставим acme.sh (установится в ~/.acme.sh/)
echo "--- Установка acme.sh ---"
curl https://get.acme.sh | sh -s email="$EMAIL"

# Перезагружаем окружение, чтобы команда acme.sh стала доступна в терминале
export LE_CONFIG_HOME="$HOME/.acme.sh"
alias acme.sh="$HOME/.acme.sh/acme.sh"

# 3. Переключаем дефолтный CA на Let's Encrypt (по умолчанию acme.sh сейчас использует ZeroSSL)
echo "--- Переключение на Let's Encrypt ---"
"$HOME/.acme.sh/acme.sh" --set-default-ca --server letsencrypt

# 4. Выпускаем сертификат через встроенный веб-сервер (80 порт)
echo "--- Выпуск сертификата для $DOMAIN ---"
"$HOME/.acme.sh/acme.sh" --issue -d "$DOMAIN" --standalone

echo "------------------------------------------------"
echo "Успешно! Сертификаты лежат в папке по умолчанию:"
echo "-> $HOME/.acme.sh/${DOMAIN}_ecc/"
echo "------------------------------------------------"
