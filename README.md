# CMS Shield — защита данных в CMS
**Дата проекта:** 16.11.2026  
**Практическая работа:** «Защита данных в CMS»

Учебный комплект для усиления WordPress: аудит файловых разрешений, защита конфигурации и uploads, минимальные привилегии БД, FIM, зашифрованные резервные копии, WAF и ограничение частоты запросов.

## Состав
- `site/` — демонстрационная адаптивная панель (все показатели на ней демонстрационные).
- `scripts/audit_permissions.sh` — аудит разрешений; `--fix` изменяет права.
- `scripts/fim.py` — FIM с SHA-256 baseline и сверкой официальных MD5 checksum WordPress.
- `scripts/backup.sh` — дамп MySQL + файлы сайта, AES-256-CBC/PBKDF2, проверка расшифровки.
- `config/` — примеры Apache, Nginx, ModSecurity и WordPress.
- `sql/least-privilege.sql` — пример минимальных прав БД.
- `tests/` — автоматические тесты; GitHub Actions запускает их при push/PR.

## Запуск сайта
`python3 -m http.server 8080 --directory site` → http://127.0.0.1:8080

## Локальные проверки
```bash
python3 -m unittest discover -s tests -v
bash -n scripts/audit_permissions.sh scripts/backup.sh
python3 -m py_compile scripts/fim.py
```

## FIM
Локальный baseline JSON: `{"index.php":"<64-character-sha256>"}`. Храните baseline вне web-root и защищайте от записи веб-процессом. Официальный WordPress Core Checksum API отдаёт MD5, поэтому скрипт использует MD5 для API и SHA-256 для локального baseline.

```bash
python3 scripts/fim.py --root /var/www/html --version 6.7.2 --locale en_US
python3 scripts/fim.py --root ./fixture --version local --baseline ./baseline.json
```

## Аудит разрешений
```bash
sudo bash scripts/audit_permissions.sh /var/www/html --audit
# Только после проверки владельца/группы и резервной копии:
sudo bash scripts/audit_permissions.sh /var/www/html --fix
```
Режим fix устанавливает 755 для каталогов и 644 для файлов; wp-config.php получает 400. Проверьте, что PHP-процесс имеет право читать файл. При необходимости настройте владельца/группу и 440 вручную.

## WordPress hardening
1. Сделайте резервную копию и вручную перенесите настройки из `config/wordpress-hardening.php` в существующий wp-config.php.
2. Получите уникальные salts через https://api.wordpress.org/secret-key/1.1/salt/; не коммитьте секреты.
3. `sec26_` — пример префикса. Переименование таблиц требует отдельной миграции до изменения `$table_prefix`.
4. Создайте отдельного пользователя БД по SQL-шаблону; замените пароль и ограничьте доступ по хосту.
5. Включите HTTPS и Secure/HttpOnly/SameSite cookies; HSTS включайте после проверки всех поддоменов.

## Web server / WAF
- Apache: подключите `config/apache/security.conf` в VirtualHost; `uploads.htaccess` поместите в uploads.
- Nginx: директива `limit_req_zone` должна быть в контексте `http {}`; остальные правила — в `server {}`. Проверьте путь PHP-FPM.
- ModSecurity: используйте OWASP CRS; локальное правило — дополнительное, не замена CRS. Тестируйте false positives.

## Резервное копирование
Требуются mysqldump, tar, openssl. Перед запуском задайте DB_NAME, DB_USER, DB_PASSWORD, WP_ROOT, BACKUP_DIR, BACKUP_PASSPHRASE через защищённое окружение/secret manager. Не храните пароль в репозитории, shell history или аргументах процесса. Резервная копия должна находиться вне web-root. Проверьте восстановление на отдельном стенде.

## Статус проверки и ограничения
Автоматически проверяются unit-тесты FIM, синтаксис Bash и компиляция Python. Реальные HTTP 403, DB grants, HTTPS/HSTS, PHP execution blocking, WAF load test и production backup требуют отдельного тестового WordPress-сервера с MySQL и настроенным веб-сервером. Скриншот в docs — визуальный макет, а не доказательство production-развёртывания.

## Отчёт
Технический отчёт DOCX и локальный архив проекта предоставлены отдельно в материалах задания. В репозитории находятся исходники и инструкции.

**GitHub:** https://github.com/ffhg20197-maker/16.11.2026-2p
