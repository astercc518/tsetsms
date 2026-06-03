#!/usr/bin/env bash
# ==============================================================================
# 复刻实例首次部署引导（生产源镜像）
#   - 为本实例生成独立强密钥写入 .env（幂等：已是非占位值则跳过，绝不覆盖已配置实例）
#   - 由 proxysql.cnf.template 渲染出 proxysql.cnf（解耦硬编码密码）
# 用法（全新机器首次部署，先于 docker compose up 执行一次）：
#   ./scripts/bootstrap.sh && docker compose up -d
# 在已配置实例上重复执行是安全的：仅渲染 proxysql.cnf，不改动已有密钥。
# ==============================================================================
set -euo pipefail
cd "$(dirname "$0")/.."

ENV_FILE=".env"
TEMPLATE="proxysql.cnf.template"
# 仅把"显式占位符"或空值视为待生成；绝不把真实密码（即便看起来弱）当占位符，避免误覆盖已配置实例
PLACEHOLDER_RE='^请替换|^change-me$|^changeme$|__GEN__'

[ -f "$TEMPLATE" ] || { echo "缺少 $TEMPLATE"; exit 1; }
[ -f "$ENV_FILE" ] || { [ -f .env.example ] && cp .env.example "$ENV_FILE" || touch "$ENV_FILE"; }

genhex() { openssl rand -hex "${1:-32}"; }
genb64() { openssl rand -base64 "${1:-24}" | tr -d '\n/+=' | head -c "${2:-24}"; }  # 适合密码（无特殊字符）
genfernet() {
  python3 -c "from cryptography.fernet import Fernet;print(Fernet.generate_key().decode())" 2>/dev/null \
    || openssl rand -base64 32 | tr '+/' '-_'
}

cur() { grep -E "^$1=" "$ENV_FILE" 2>/dev/null | head -1 | cut -d= -f2- || true; }
upsert() {
  local k="$1" v="$2"
  if grep -qE "^${k}=" "$ENV_FILE"; then
    # 用 | 分隔，密钥不含 |
    sed -i "s|^${k}=.*|${k}=${v}|" "$ENV_FILE"
  else
    printf '%s=%s\n' "$k" "$v" >> "$ENV_FILE"
  fi
}
need_gen() {
  local v; v="$(cur "$1")"
  [ -z "$v" ] && return 0
  echo "$v" | grep -qE "$PLACEHOLDER_RE" && return 0
  return 1
}
set_if_needed() {
  local k="$1" gen="$2"
  if need_gen "$k"; then upsert "$k" "$gen"; echo "  生成 $k"; fi
}

echo "== 生成/补齐本实例独立密钥（幂等）=="
set_if_needed MYSQL_ROOT_PASSWORD       "$(genb64 24 24)"
set_if_needed MYSQL_PASSWORD            "$(genb64 24 24)"
set_if_needed REDIS_PASSWORD            "$(genb64 24 24)"
set_if_needed RABBITMQ_PASSWORD         "$(genb64 24 24)"
set_if_needed JWT_SECRET_KEY            "$(genhex 48)"
set_if_needed INTERNAL_TOKEN            "$(genhex 32)"
set_if_needed TELEGRAM_STAFF_API_SECRET "$(genhex 32)"
set_if_needed BOT_PERSISTENCE_KEY       "$(genfernet)"
set_if_needed PROXYSQL_ADMIN_PASSWORD   "$(genb64 16 16)"
set_if_needed PROXYSQL_RADMIN_PASSWORD  "$(genb64 16 16)"
set_if_needed PROXYSQL_MONITOR_PASSWORD "$(genb64 24 24)"

echo "== 渲染 proxysql.cnf（注入 MYSQL_PASSWORD / monitor / admin 密码）=="
# shellcheck disable=SC1090
set -a; . "$ENV_FILE"; set +a
export MYSQL_PASSWORD PROXYSQL_ADMIN_PASSWORD PROXYSQL_RADMIN_PASSWORD PROXYSQL_MONITOR_PASSWORD
envsubst '${MYSQL_PASSWORD} ${PROXYSQL_ADMIN_PASSWORD} ${PROXYSQL_RADMIN_PASSWORD} ${PROXYSQL_MONITOR_PASSWORD}' \
  < "$TEMPLATE" > proxysql.cnf
echo "  proxysql.cnf 已生成"

echo "完成。可执行： docker compose up -d"
