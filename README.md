# HomeLab DevOps Platform

## Infrastructure as Code • Configuration as Code • CI/CD • Monitoring • Secrets Management

Домашняя DevOps-платформа, демонстрирующая полный цикл работы с современной инфраструктурой: Infrastructure as Code, Configuration as Code, управление секретами, мониторинг и автоматизированный CI/CD-конвейер на базе виртуализации KVM.

Проект автоматически создает виртуальную машину с помощью Terraform, настраивает её через Ansible, разворачивает стек приложений и мониторинга с использованием Docker Compose и управляет всем процессом через Jenkins Multibranch Pipeline с интеграцией HashiCorp Vault.

---

## Project Overview

Цель проекта — не просто изучение отдельных инструментов, а построение максимально приближенного к реальной практике DevOps-процесса.

В рамках проекта реализован полностью воспроизводимый процесс, при котором весь жизненный цикл инфраструктуры — от создания виртуальной машины до развертывания приложений — описан в коде, хранится в Git и автоматически выполняется средствами CI/CD.

На текущий момент проект демонстрирует следующие подходы:

- Infrastructure as Code (Terraform)
- Configuration as Code (Ansible)
- Dashboard as Code (автоматическое развертывание Grafana Dashboard)
- Secrets Management (HashiCorp Vault)
- Continuous Integration & Continuous Deployment (Jenkins Multibranch Pipeline)
- Централизованный мониторинг и алертинг (Prometheus + Grafana + Loki)

---

## Architecture Overview

```text
                 Github Repository
                          |
                          ▼
             Pull Request - Merge в main
                          |
                          ▼
            Jenkins Multibranch Pipeline
                          |
          ┌───────────────┼────────────────┐
          |               |                |
          ▼               ▼                ▼
   HashiCorp Vault     Terraform        Ansible
      (Secrets)          (IaC)           (CaC)
          |               |                |
          └───────────────┼────────────────┘
                          ▼
              Ubuntu 24.04 Virtual Machine
                          |
                          ▼
                 Docker Compose Stack
                          |
     ┌────────────────────┼──────────────────────┐
 ordpress            Monitoring              Alerting
MySQL Redis    Prometheus Grafana Loki     Alertmanager
```

---

## Technology Stack

Infrastructure:
- Arch Linux
- QEMU / KVM
- libvirt

Automation:
- Jenkins
- Terraform
- Ansible

Monitoring:
- Prometheus
- Grafana
- Loki

Security:
- HashiCorp Vault
- Nftables

---

## Infrastructure as Code

- Terraform 1.15
- Провайдер dmacvicar/libvirt

Хранение состояния Terraform:

- MinIO (S3 Backend)

---

## Configuration as Code

- Ansible

Автоматизируется:

- Установка Docker;
- Настройка Docker Engine;
- Конфигурация Registry Mirrors;
- Настройка прокси;
- Развертывание Docker Compose;
- Автоматическая генерация Ansible Inventory на основе Terraform Outputs.

---

## CI/CD Workflow and Environment Strategy

Проект использует Jenkins Multibranch Pipeline совместно с GitHub и GitFlow workflow.

Каждая ветка разработки автоматически обнаруживается Jenkins и запускается в отдельном pipeline execution. Это позволяет проверять изменения до их попадания в основную ветку.

### Feature branch workflow

Разработка новых функций выполняется в отдельных ветках:

```text
feature/*
      |
      ▼
Jenkins Multibranch Pipeline
      |
      ├── Checkout Code
      ├── Terraform Init
      ├── Terraform Plan
      ├── Ansible Validate
      └── Automated Tests
```


После успешной проверки изменения отправляются в Pull Request.

После Code Review выполняется merge в main.

### Main branch deployment

После изменения ветки main Jenkins выполняет deployment pipeline:

```text
main
 |
 ▼
Jenkins Multibranch Pipeline
 |
 ├── Получение секретов из HashiCorp Vault
 ├── Terraform Init
 ├── Terraform Plan
 ├── Сохранение Terraform Plan как build artifact
 ├── Terraform Apply
 ├── Генерация Ansible Inventory
 ├── Проверка Ansible Playbook
 ├── Ansible Deployment
 └── Проверка доступности сервисов
```

Для защиты состояния инфраструктуры отключено параллельное выполнение Jenkins build.

Terraform State хранится в удаленном S3-совместимом backend на базе MinIO.

---

## Automated Test Environment

Для разработки новых возможностей используется автоматическое тестовое окружение.

Jenkins pipeline способен полностью воспроизвести окружение из кода:

- Terraform создает виртуальную машину Ubuntu через KVM/libvirt;
- Terraform получает состояние инфраструктуры из MinIO backend;
- Ansible выполняет первоначальную настройку системы;
- Docker Compose разворачивает сервисный стек;
- выполняются проверки работоспособности компонентов.

Окружение не требует ручной настройки и полностью описано через:

- Infrastructure as Code (Terraform);
- Configuration as Code (Ansible);
- Pipeline as Code (Jenkinsfile);
- Secrets Management (HashiCorp Vault).

---

## Secrets Management

Все чувствительные данные хранятся в HashiCorp Vault.

В Vault размещаются:

- Учетные данные MySQL;
- Telegram Bot Token;
- Учетные данные Grafana;
- Учетные данные MinIO;
- Параметры WordPress и тестового окружения.

Секреты никогда не попадают в Git-репозиторий.

---

## Monitoring and Observability

Развернут стек мониторинга:

- Prometheus
- Grafana
- Loki
- Promtail
- Node Exporter
- MySQL Exporter
- cAdvisor
- Alertmanager

Все дашборды Grafana автоматически создаются при развертывании инфраструктуры.

---

## Deployment

Terraform автоматически создает:

- Storage Pool;
- Базовый образ Ubuntu;
- Cloud-Init ISO;
- Виртуальные диски;
- Виртуальную машину.

Состояние Terraform хранится в удаленном S3-совместимом backend MinIO.

## Implemented Features

✅ Infrastructure as Code

- Создание и управление виртуальной инфраструктурой через Terraform.

✅ Configuration as Code

- Автоматическое конфигурирование сервера через Ansible.

✅ Remote Terraform State

- Хранение Terraform State в MinIO S3 backend.

✅ Secrets Management

- Централизованное управление секретами через HashiCorp Vault.

✅ Dynamic Inventory

- Автоматическая генерация Ansible Inventory из Terraform outputs.

✅ CI/CD

- Jenkins Multibranch Pipeline.
- Автоматический план и деплой инфраструктуры

✅ Monitoring Stack

- Prometheus
- Grafana
- Loki
- Promtail

✅ Alerting

- Alertmanager
- Telegram notifications.

---

## Roadmap

Планируется добавить:

- Trivy (анализ Docker-образов);
- OWASP Dependency-Check;
- Docker Bench Security;
- Тестирование Ansible через Molecule;
- Миграцию инфраструктуры в Kubernetes;
- Helm Charts;
- GitOps с использованием Argo CD;
- Отказоустойчивое развертывание;
- Автоматическое резервное копирование.

---

## Engineering Approach

В отличие от большинства учебных примеров, демонстрирующих отдельные инструменты из DevOps-стека, данный проект ориентирован на построение целостного инженерного процесса.

Основной целью было не только изучение отдельных технологий, а их интеграция в единую систему:

- инфраструктура создается автоматически через Infrastructure as Code;
- конфигурация серверов управляется через Configuration as Code;
- секреты хранятся централизованно и не попадают в Git;
- изменения проходят через контролируемый CI/CD процесс;
- состояние инфраструктуры и работоспособность сервисов контролируются средствами мониторинга и алертинга.

Проект является первым этапом развития собственного DevOps HomeLab, который в дальнейшем будет расширяться поддержкой Kubernetes, Helm, GitOps и облачно-ориентированных практик.
