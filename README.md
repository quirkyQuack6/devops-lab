# HomeLab DevOps Node: IaC, Automated Monitoring & Jenkins CI/CD Pipeline

Учебный проект (лабораторная работа) по автоматизации развертывания изолированной DevOps-инфраструктуры в KVM на базе Arch Linux. Проект реализует концепции **Infrastructure as Code (IaC)**, **Configuration as Code (CaC)** и **Dashboard as Code** с построением сквозного локального конвейера непрерывной интеграции и доставки (CI/CD).

---

## Архитектура стека

* **Хост-система**: Arch Linux + `libvirt` (QEMU/KVM) + `nftables`
* **Инфраструктурный слой (IaC)**: Terraform v1.15 + провайдер `dmacvicar/libvirt` (v0.9.8)
* **CI/CD Оркестратор**: Jenkins LTS (запущен в Docker, режим `network_mode: host`)
* **Управление секретами**: HashiCorp Vault (запущен в Docker)
* **Управление конфигурацией**: Ansible
* **Виртуальная машина**: Ubuntu 24.04 LTS (Noble Numbat) Cloud Image
* **Приложения и Мониторинг**: Docker Compose стек из 10 контейнеров на ВМ:
  *   *Приложения*: WordPress, MySQL, Redis
  *   *Монитооринг (PLG)*: Prometheus, Grafana, Loki, Promtail, cAdvisor, Node Exporter, MySQL Exporter

---

## Сетевая топология и обход блокировок

Для успешного скачивания Docker-образов и скриптов в условиях ограничений Docker Hub для СНГ настроена гибридная прокси-маршрутизация:
1. **Прокси на хосте**: Приложение `v2rayN` / `Xray` слушает порт `10808` на интерфейсе `192.168.122.1` (KVM-мост хоста) с включенной опцией *Allow LAN*.
2. **Файрвол хоста (`nftables`)**: В цепочку `chain input` добавлено правило `tcp dport 10808 accept` для беспрепятственного прохождения трафика из подсети виртуалки.
3. **Зеркала**: Демон Docker внутри Ubuntu настроен на работу через зеркала, что гарантирует скачивание слоев образов.

---

## Схема работы CI/CD Pipeline (Jenkinsfile)

Проект использует GitFlow с защитой ветки `main`. Прямые коммиты запрещены — изменения вносятся только через Feature-ветки и Code Review в Pull Request.

```text
➔ Изменение кода на Arch Linux
➔ git push
➔ Открытие Pull Request
➔ Merge в main
➔ Автоматический триггер Jenkins (SCM Polling):
┌─────────────────────────────────────────────────────────────────────────┐
│ Контейнер Jenkins (Кастомный Dockerfile c Ansible & Host Network)       │
│                                                                         │
│ 1. Этап 'Checkout Code': Скачивает стабильный main-код из GitHub        │
│ 2. Этап 'Lint & Validate': Проверяет синтаксис плейбука Ansible         │
│ 3. Этап 'Vault Auth': Безопасная передача секретов из HashiCorp Vault   │
│ 4. Этап 'Deploy Stack': Запускает ansible-playbook по SSH-ключам        │
└─────────────────────────────────────────────────────────────────────────┘
➔ KVM Виртуальная машина полностью обновлена
```

---

## Пошаговое развертывание 

### Шаг 1: Подготовка инфраструктуры (Terraform)
Перейдите в директорию Terraform, инициализируйте провайдер и создайте ВМ:
```bash
cd terraform
terraform init -upgrade
terraform apply
```
*Terraform требуется до 150 секунд, чтобы поднять домен подключить ISO-образ Cloud-Init как CD-ROM устройство и дождаться выделения IP-адреса по DHCP.*

### Шаг 2: Запуск сервера автоматизации (Jenkins)
Соберите кастомный образ Jenkins со встроенным Ansible и запустите Jenkins и Vault:
```bash
cd ../jenkins
docker compose up -d --build
```
1. Откройте интерфейс: `http://localhost:8084`.
2. Заберите первичный пароль из логов хоста: `docker logs jenkins`.
3. Создайте элемент типа **Pipeline**, укажите ссылку на ваш Github-репозиторий, ветку `*/main` и режим опроса `Poll SCM` со значением например `H/5 * * * *`.

### Шаг 3: Настройка системы безопасности
1. Авторизуйте CLI-сессию внутри контейнера Vault с помощью мастер-токена:
   ```bash
   docker exec -it vault-server vault login <ваш-токен>
   ```
2. Запишите секреты бд и мониторинга в хранилище по пути `secret/homelab/db`:
   ```bash
   docker exec -it vault-server vault kv put secret/homelab/db \
     mysql_root_password="ваш_root_пароль" \
     mysql_user="wp_admin" \
     mysql_password="ваш_пароль_для_user" \
     mysql_exporter_user="exporter" \
     mysql_exporter_password="ваш_пароль_для_exporter" \
     mysql_database="wordpress"
   ```
3. Проверьте корректность записи данных в хранилище:
   ```bash
   docker exec -it vault-server vault kv get sescret/homelab/db
   ```     
4. Установите плагин `HashiCorp Vault Plugin` в Jenkins.
5. В разделе *Manage Jenkins ➔ Credentials* добавьте секрет с типом **Vault Token Credential**. Укажите ID `vault-root-token` и вставьте <ваш_токен>.


### Шаг 4. Автоматический запуск
Убедитесь, что актуальный IP-адрес вашей ВМ прописан в `ansible/hosts.ini`, сделайте коммит изменений и влейте Pull Request. Через 5 минут Jenkins автоматически выполнит деплой всего стека.

---

## Результат работы и концепция Dashboard as Code

После успешного завершения пайплайна в вашей системе будут развернуты:
*   **Веб-сайт**: `http://<IP_ВМ>:8080` (WordPress + MySQL + Redis-кэш)
*   **Система Мониторинга**: `http://<IP_ВМ>:3000` (Grafana)

Все 6 встроенных дашбордов оживают **мгновенно и автоматически**.
- Метрики: `uid: prometheus-production`
- Логи: `uid: loki-production`

Флаг `allowUiUpdates: true` в файле `dashboard_provider.yaml` позволяет редактировать и сохранять панели из веб-интерфейса Grafana
