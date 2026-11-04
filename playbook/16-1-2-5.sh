#!/usr/bin/env bash

set -e

echo "=== [1/4] Запуск Docker-контейнеров ==="

start_container() {
    local name=$1
    local image=$2
    echo "Запуск контейнера: $name из образа $image..."
    docker rm -f "$name" 2>/dev/null || true
    docker run -d --name "$name" "$image" sleep infinity
}

start_container "ubuntu" "ubuntu:latest"
start_container "centos" "quay.io/centos/centos:stream9"
start_container "fedora" "pycontribs/fedora"

echo "=== [2/4] Подготовка окружения внутри контейнеров ==="
echo "Установка Python в чистые ОС..."
docker exec ubuntu apt-get update && docker exec ubuntu apt-get install -y python3

echo "=== [3/4] Запуск Ansible Playbook ==="
if [ -f playbook.yml ]; then
    ansible-playbook -i inventory/prod.yml site.yml --vault-password-file .vault_pass
else
    echo "Файл playbook.yml не найден! Запускаем тестовую ad-hoc проверку фактов..."
    ansible all -i inventory/prod.yml -m ansible.builtin.debug -a "var=some_fact" --vault-password-file .vault_pass
fi

echo "=== [4/4] Очистка окружения ==="
echo "Остановка и удаление тестовых контейнеров..."
docker rm -f ubuntu centos fedora

echo "=== Получение фактов успешно завершено! ==="
