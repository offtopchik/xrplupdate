#!/bin/bash

# Цвета для вывода
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # Без цвета

# Проверка прав root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Запустите скрипт с правами root! (sudo)${NC}"
   exit 1
fi

# Функция обновления системы
function update_system() {
    echo -e "${GREEN}Обновление системы...${NC}"
    apt update && apt upgrade -y || {
        echo -e "${RED}Ошибка при обновлении системы.${NC}"
        return 1
    }
    echo -e "${GREEN}Система успешно обновлена.${NC}"
}

# Функция установки всех зависимостей и пакетов
function install_all() {
    echo -e "${GREEN}Установка базовых инструментов (curl, git, wget, build-essential)...${NC}"
    apt install -y curl git wget build-essential || {
        echo -e "${RED}Ошибка при установке базовых инструментов.${NC}"
        return 1
    }

    echo -e "${GREEN}Установка Node.js...${NC}"
    curl -fsSL https://deb.nodesource.com/setup_16.x | bash - && apt install -y nodejs || {
        echo -e "${RED}Ошибка при установке Node.js.${NC}"
        return 1
    }

    echo -e "${GREEN}Установка компилятора C++ и CMake...${NC}"
    apt install -y gcc g++ cmake || {
        echo -e "${RED}Ошибка при установке компилятора и CMake.${NC}"
        return 1
    }

    echo -e "${GREEN}Установка Boost и OpenSSL...${NC}"
    apt install -y libboost-all-dev libssl-dev || {
        echo -e "${RED}Ошибка при установке Boost и OpenSSL.${NC}"
        return 1
    }

    echo -e "${GREEN}Установка rippled...${NC}"
    if ! command -v rippled &> /dev/null; then
        echo -e "${GREEN}Добавление репозитория Ripple...${NC}"
        wget -q -O - "https://repos.ripple.com/repos/api/gpg/key/public" | apt-key add -
        echo "deb https://repos.ripple.com/repos/rippled-deb focal stable" > /etc/apt/sources.list.d/ripple.list
        apt update && apt install -y rippled || {
            echo -e "${RED}Ошибка при установке rippled.${NC}"
            return 1
        }
        echo -e "${GREEN}rippled успешно установлен!${NC}"
    else
        echo -e "${GREEN}rippled уже установлен.${NC}"
    fi

    echo -e "${GREEN}Настройка rippled...${NC}"
    if [ -f /etc/opt/ripple/rippled.cfg ]; then
        cp /etc/opt/ripple/rippled.cfg /etc/opt/ripple/rippled.cfg.backup
        sed -i 's/#start = yes/start = yes/' /etc/opt/ripple/rippled.cfg
        systemctl enable rippled
        systemctl start rippled
        echo -e "${GREEN}rippled настроен и запущен.${NC}"
    else
        echo -e "${RED}Файл конфигурации rippled не найден! Проверьте установку.${NC}"
        return 1
    fi

    echo -e "${GREEN}Клонирование XRPL Node Configurator...${NC}"
    if [[ ! -d "xrpl-node-configurator" ]]; then
        git clone https://github.com/XRPLF/xrpl-node-configurator.git || {
            echo -e "${RED}Ошибка при клонировании XRPL Node Configurator.${NC}"
            return 1
        }
    else
        echo -e "${GREEN}Репозиторий xrpl-node-configurator уже существует.${NC}"
    fi

    cd xrpl-node-configurator || {
        echo -e "${RED}Не удалось перейти в директорию xrpl-node-configurator.${NC}"
        return 1
    }

    echo -e "${GREEN}Установка npm-зависимостей XRPL Node Configurator...${NC}"
    npm install || {
        echo -e "${RED}Ошибка при установке npm-зависимостей.${NC}"
        return 1
    }

    cd ..
    echo -e "${GREEN}Все зависимости успешно установлены!${NC}"
}

# Функция запуска XRPL Node Configurator
function start_configurator() {
    if [[ -d "xrpl-node-configurator" ]]; then
        cd xrpl-node-configurator || {
            echo -e "${RED}Не удалось перейти в директорию xrpl-node-configurator.${NC}"
            return 1
        }
        echo -e "${GREEN}Запуск XRPL Node Configurator...${NC}"
        npm start
    else
        echo -e "${RED}Директория xrpl-node-configurator не найдена. Установите зависимости.${NC}"
    fi
}

# Функция проверки логов rippled
function check_logs() {
    echo -e "${GREEN}Последние 50 строк логов rippled:${NC}"
    journalctl -u rippled -n 50 --no-pager || {
        echo -e "${RED}Не удалось получить логи rippled.${NC}"
        return 1
    }
}

# Функция остановки ноды rippled
function stop_node() {
    echo -e "${GREEN}Остановка rippled...${NC}"
    systemctl stop rippled && echo -e "${GREEN}rippled остановлен.${NC}" || echo -e "${RED}Не удалось остановить rippled.${NC}"
}

# Функция удаления установленных компонентов
function uninstall_all() {
    echo -e "${GREEN}Удаление xrpl-node-configurator и rippled...${NC}"
    systemctl stop rippled
    apt remove -y rippled
    apt autoremove -y

    if [[ -d "xrpl-node-configurator" ]]; then
        rm -rf xrpl-node-configurator
        echo -e "${GREEN}xrpl-node-configurator удалён.${NC}"
    else
        echo -e "${GREEN}xrpl-node-configurator не найден.${NC}"
    fi

    echo -e "${GREEN}Удаление завершено.${NC}"
}

# Меню
while true; do
    echo ""
    echo -e "${GREEN}STARNODE${NC}"
    echo -e "${GREEN}Выберите действие:${NC}"
    echo "1) Обновить систему"
    echo "2) Установить все зависимости и пакеты"
    echo "3) Запустить XRPL Node Configurator"
    echo "4) Проверить логи rippled"
    echo "5) Остановить ноду (rippled)"
    echo "6) Удалить все (rippled и xrpl-node-configurator)"
    echo "7) Выход"
    echo -n "Ваш выбор: "
    read choice

    case $choice in
        1)
            update_system
            ;;
        2)
            install_all
            ;;
        3)
            start_configurator
            ;;
        4)
            check_logs
            ;;
        5)
            stop_node
            ;;
        6)
            uninstall_all
            ;;
        7)
            echo -e "${GREEN}Выход из скрипта.${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Неверный выбор, попробуйте снова.${NC}"
            ;;
    esac
done
