# Используем базовый образ PostgreSQL 16.2 на основе Alpine Linux
FROM postgres:16.2-alpine

# Устанавливаем необходимые переменные окружения
ENV POSTGRES_USER=postgres
ENV POSTGRES_PASSWORD=password
ENV POSTGRES_DB=library_db

# Копирование SQL-скрипта для инициализации базы данных
COPY init.sql /docker-entrypoint-initdb.d/