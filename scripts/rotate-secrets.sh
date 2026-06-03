#!/usr/bin/env bash
# ==============================================================================
# 密钥轮换（克隆已运行实例后让其拥有独立强密钥；或加固源实例）
#   用旧凭据改写在用存储 → 更新 .env → 重渲染并重载 proxysql.cnf → 重建容器
#   约 30-60s 应用层停机；MySQL/Redis/RabbitMQ 数据不丢。
# 关键点（来自实战教训）：
#   - ProxySQL 仅首次初始化读 .cnf，之后用持久卷里的配置 → 轮换时必须清 proxysql_data 卷
#   - 用 hex 生成密码（无特殊字符，SQL/env/cnf 均安全）
#   - 改完 MySQL 密码后立即校验，失败则中止
# 用法： ./scripts/rotate-secrets.sh
# ==============================================================================
set -uo pipefail
cd "$(dirname "$0")/.."
ENV_FILE=".env"
[ -f "$ENV_FILE" ] || { echo "缺少 .env"; exit 1; }

# shellcheck disable=SC1090
set -a; . "$ENV_FILE"; set +a
OLD_ROOT="${MYSQL_ROOT_PASSWORD}"; RMQ_USER="${RABBITMQ_USER:-smsc_mq}"

gen() { openssl rand -hex "${1:-16}"; }   # hex：无特殊字符，安全
upsert() { local k="$1" v="$2"; if grep -qE "^${k}=" "$ENV_FILE"; then sed -i "s|^${k}=.*|${k}=${v}|" "$ENV_FILE"; else printf '%s=%s\n' "$k" "$v" >> "$ENV_FILE"; fi; }

echo "== 生成新密钥 =="
N_ROOT=$(gen 16); N_SMS=$(gen 16); N_REDIS=$(gen 16); N_RMQ=$(gen 16); N_MON=$(gen 16)
N_PADMIN=$(gen 12); N_PRADMIN=$(gen 12)
N_JWT=$(gen 48); N_INT=$(gen 32); N_STAFF=$(gen 32)
N_BOTKEY=$(python3 -c "from cryptography.fernet import Fernet;print(Fernet.generate_key().decode())" 2>/dev/null || true)

echo "== 改 MySQL 用户密码（旧 root 连接）并立即校验 =="
docker exec -e NR="$N_ROOT" -e NS="$N_SMS" -e NM="$N_MON" -e OR="$OLD_ROOT" smsc-mysql sh -c '
mysql -uroot -p"$OR" 2>/dev/null <<SQL
ALTER USER "root"@"localhost" IDENTIFIED BY "'"$N_ROOT"'";
ALTER USER "smsuser"@"%" IDENTIFIED BY "'"$N_SMS"'";
ALTER USER "monitor"@"%" IDENTIFIED WITH mysql_native_password BY "'"$N_MON"'";
FLUSH PRIVILEGES;
SQL'
if ! docker exec smsc-mysql mysql -usmsuser -p"$N_SMS" -e "SELECT 1" >/dev/null 2>&1; then
  echo "!! MySQL 新密码校验失败，已中止（未改 .env，可重试）"; exit 1
fi
echo "  MySQL OK"

echo "== 改 RabbitMQ 用户密码 =="
docker exec smsc-rabbitmq rabbitmqctl change_password "$RMQ_USER" "$N_RMQ" >/dev/null 2>&1 && echo "  RabbitMQ OK"

echo "== 更新 .env =="
upsert MYSQL_ROOT_PASSWORD "$N_ROOT"; upsert MYSQL_PASSWORD "$N_SMS"
upsert REDIS_PASSWORD "$N_REDIS"; upsert RABBITMQ_PASSWORD "$N_RMQ"
upsert PROXYSQL_MONITOR_PASSWORD "$N_MON"; upsert PROXYSQL_ADMIN_PASSWORD "$N_PADMIN"; upsert PROXYSQL_RADMIN_PASSWORD "$N_PRADMIN"
upsert JWT_SECRET_KEY "$N_JWT"; upsert INTERNAL_TOKEN "$N_INT"; upsert TELEGRAM_STAFF_API_SECRET "$N_STAFF"
[ -n "$N_BOTKEY" ] && upsert BOT_PERSISTENCE_KEY "$N_BOTKEY"

echo "== 重渲染 proxysql.cnf =="
set -a; . "$ENV_FILE"; set +a
export MYSQL_PASSWORD PROXYSQL_ADMIN_PASSWORD PROXYSQL_RADMIN_PASSWORD PROXYSQL_MONITOR_PASSWORD
envsubst '${MYSQL_PASSWORD} ${PROXYSQL_ADMIN_PASSWORD} ${PROXYSQL_RADMIN_PASSWORD} ${PROXYSQL_MONITOR_PASSWORD}' < proxysql.cnf.template > proxysql.cnf

echo "== 重建 ProxySQL（清持久卷以加载新 cnf）+ 其它受影响容器 =="
PVOL=$(docker volume ls --format '{{.Name}}' | grep -E 'proxysql_data$' | head -1)
docker compose rm -sf proxysql >/dev/null 2>&1
[ -n "$PVOL" ] && docker volume rm "$PVOL" >/dev/null 2>&1
docker compose up -d --force-recreate redis api worker worker-dlr worker-result worker-sms worker-web beat bot smpp-gateway >/dev/null 2>&1
docker compose up -d proxysql >/dev/null 2>&1

echo "  等待 ProxySQL 健康..."
for i in $(seq 1 24); do [ "$(docker inspect -f '{{.State.Health.Status}}' smsc-proxysql 2>/dev/null)" = healthy ] && break; sleep 5; done
echo "  等待 API 就绪..."
docker compose up -d api >/dev/null 2>&1   # 确保 api 处于 Up（若依赖未就绪曾停在 Created）
for i in $(seq 1 30); do [ "$(curl -s -o /dev/null -w '%{http_code}' -m 3 http://127.0.0.1:8000/health 2>/dev/null)" = 200 ] && break; sleep 3; done
docker compose restart frontend >/dev/null 2>&1; sleep 3

if [ "$(curl -s -o /dev/null -w '%{http_code}' -m 5 http://127.0.0.1:8000/health 2>/dev/null)" = 200 ]; then
  echo "完成：密钥已轮换为本实例独立强密钥，服务已恢复。"
else
  echo "!! 轮换后 API 未就绪，请检查： docker compose ps / docker logs smsc-api"
fi
