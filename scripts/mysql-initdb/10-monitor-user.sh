#!/bin/bash
# 仅在全新实例 MySQL 首次初始化（数据卷为空）时由 docker-entrypoint-initdb.d 执行。
# 创建 ProxySQL 监控用户，密码取自容器环境 PROXYSQL_MONITOR_PASSWORD（由 bootstrap.sh 生成）。
set -e
: "${PROXYSQL_MONITOR_PASSWORD:?需要 PROXYSQL_MONITOR_PASSWORD 环境变量}"
mysql -uroot -p"${MYSQL_ROOT_PASSWORD}" <<SQL
CREATE USER IF NOT EXISTS 'monitor'@'%' IDENTIFIED WITH mysql_native_password BY '${PROXYSQL_MONITOR_PASSWORD}';
GRANT USAGE, REPLICATION CLIENT ON *.* TO 'monitor'@'%';
FLUSH PRIVILEGES;
SQL
echo "[init] ProxySQL monitor 用户已创建"
