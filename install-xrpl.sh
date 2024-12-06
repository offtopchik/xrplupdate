#!/bin/bash

# Цвета для вывода
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # Без цвета

# Проверка прав root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Этот скрипт должен быть запущен с правами root!${NC}"
   exit 1
fi

echo -e "${GREEN}Запуск скрипта установки XRPL Node Configurator...${NC}"

# Установка необходимых пакетов
echo -e "${GREEN}Установка зависимостей...${NC}"
apt update && apt install -y git curl || {
    echo -e "${RED}Ошибка при установке зависимостей.${NC}"
    exit 1
}

# Установка Node.js (версия 16 или выше)
if ! command -v node &> /dev/null || [[ $(node -v | cut -d. -f1) < "v16" ]]; then
    echo -e "${GREEN}Установка Node.js...${NC}"
    curl -fsSL https://deb.nodesource.com/setup_16.x | bash - && apt install -y nodejs || {
        echo -e "${RED}Ошибка при установке Node.js.${NC}"
        exit 1
    }
else
    echo -e "${GREEN}Node.js уже установлен.${NC}"
fi

# Клонирование репозитория
echo -e "${GREEN}Клонирование репозитория XRPL Node Configurator...${NC}"
git clone https://github.com/XRPLF/xrpl-node-configurator.git || {
    echo -e "${RED}Ошибка при клонировании репозитория.${NC}"
    exit 1
}

cd xrpl-node-configurator || {
    echo -e "${RED}Ошибка: папка репозитория не найдена.${NC}"
    exit 1
}

# Установка npm-зависимостей
echo -e "${GREEN}Установка зависимостей npm...${NC}"
npm install || {
    echo -e "${RED}Ошибка при установке npm-зависимостей.${NC}"
    exit 1
}

# Запуск конфигуратора
echo -e "${GREEN}Запуск XRPL Node Configurator...${NC}"
npm start || {
    echo -e "${RED}Ошибка при запуске XRPL Node Configurator.${NC}"
    exit 1
}

echo -e "${GREEN}Установка завершена! Откройте интерфейс конфигуратора в браузере.${NC}"
