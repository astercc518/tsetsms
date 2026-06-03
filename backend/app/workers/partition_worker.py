"""
sms_logs 按月分区维护（生产级源镜像）
- 首次：把 sms_logs 改造为按 submit_time 月度 RANGE 分区（要求空表）
- 每月：补建未来月份分区（REORGANIZE pmax），DROP 超过保留月数的旧分区（瞬间回收磁盘）
保留月数由 SMS_LOGS_RETAIN_MONTHS 控制（默认 3）。
DDL 直连 MySQL（绕过 ProxySQL），用配置中的库账号（已授予 sms_system 全部权限）。
"""
import os
import datetime as dt

import pymysql

from app.config import settings
from app.workers.celery_app import celery_app
from app.utils.logger import get_logger

logger = get_logger(__name__)

RETAIN_MONTHS = int(os.getenv("SMS_LOGS_RETAIN_MONTHS", "3"))
AHEAD_MONTHS = int(os.getenv("SMS_LOGS_PARTITION_AHEAD", "2"))
_DB_HOST = os.getenv("PARTITION_DB_HOST", "mysql")  # 直连后端，避免 ProxySQL 路由 DDL


def _conn():
    return pymysql.connect(
        host=_DB_HOST, port=3306,
        user=settings.DATABASE_USER, password=settings.DATABASE_PASSWORD,
        database=settings.DATABASE_NAME, autocommit=True, connect_timeout=10,
    )


def _ym_add(y: int, m: int, delta: int):
    idx = y * 12 + (m - 1) + delta
    return idx // 12, idx % 12 + 1


def _pname(y: int, m: int) -> str:
    return f"p{y:04d}{m:02d}"


def _next_month_first(y: int, m: int) -> str:
    ny, nm = _ym_add(y, m, 1)
    return f"{ny:04d}-{nm:02d}-01 00:00:00"


def maintain_sms_logs_partitions():
    now = dt.datetime.now()
    y, m = now.year, now.month
    db = settings.DATABASE_NAME
    conn = _conn()
    cur = conn.cursor()
    result = {"created": [], "dropped": [], "initialized": False}
    try:
        cur.execute(
            "SELECT COUNT(*) FROM information_schema.partitions "
            "WHERE table_schema=%s AND table_name='sms_logs' AND partition_name IS NOT NULL",
            (db,),
        )
        is_partitioned = cur.fetchone()[0] > 0

        if not is_partitioned:
            cur.execute("SELECT COUNT(*) FROM sms_logs")
            rows = cur.fetchone()[0]
            if rows > 0:
                logger.warning("sms_logs 非空(%s 行)，跳过自动初始分区，请人工迁移后再启用", rows)
                return {"skipped": "non-empty unpartitioned", "rows": rows}
            # 1) 让分区列 submit_time 进入所有唯一键（RANGE 分区前置要求）
            cur.execute(
                "ALTER TABLE sms_logs "
                "DROP PRIMARY KEY, ADD PRIMARY KEY (id, submit_time), "
                "DROP INDEX message_id, ADD UNIQUE KEY message_id (message_id, submit_time)"
            )
            # 2) 初始按月分区：上月 .. 本月+AHEAD，+ pmax 兜底
            defs = []
            for d in range(-1, AHEAD_MONTHS + 1):
                yy, mm = _ym_add(y, m, d)
                defs.append(
                    f"PARTITION {_pname(yy, mm)} VALUES LESS THAN "
                    f"(UNIX_TIMESTAMP('{_next_month_first(yy, mm)}'))"
                )
            defs.append("PARTITION pmax VALUES LESS THAN MAXVALUE")
            cur.execute(
                "ALTER TABLE sms_logs PARTITION BY RANGE (UNIX_TIMESTAMP(submit_time)) (\n  "
                + ",\n  ".join(defs) + "\n)"
            )
            result["initialized"] = True
            logger.info("sms_logs 已初始化为按月 RANGE 分区")

        # 现有分区
        cur.execute(
            "SELECT partition_name FROM information_schema.partitions "
            "WHERE table_schema=%s AND table_name='sms_logs' AND partition_name IS NOT NULL",
            (db,),
        )
        existing = {r[0] for r in cur.fetchall()}

        # 3) 补建本月 .. 本月+AHEAD（REORGANIZE pmax 拆出新月）
        for d in range(0, AHEAD_MONTHS + 1):
            yy, mm = _ym_add(y, m, d)
            pn = _pname(yy, mm)
            if pn in existing:
                continue
            cur.execute(
                f"ALTER TABLE sms_logs REORGANIZE PARTITION pmax INTO ("
                f"PARTITION {pn} VALUES LESS THAN (UNIX_TIMESTAMP('{_next_month_first(yy, mm)}')), "
                f"PARTITION pmax VALUES LESS THAN MAXVALUE)"
            )
            existing.add(pn)
            result["created"].append(pn)
            logger.info("sms_logs 新增分区 %s", pn)

        # 4) DROP 超过保留月数的旧分区（瞬间回收空间）
        cy, cm = _ym_add(y, m, -RETAIN_MONTHS)
        cutoff = cy * 100 + cm  # YYYYMM
        for pn in sorted(existing):
            if pn == "pmax" or not pn.startswith("p") or not pn[1:].isdigit():
                continue
            if int(pn[1:]) < cutoff:
                cur.execute(f"ALTER TABLE sms_logs DROP PARTITION {pn}")
                result["dropped"].append(pn)
                logger.info("sms_logs 删除过期分区 %s（热留 %s 个月）", pn, RETAIN_MONTHS)

        return result
    finally:
        cur.close()
        conn.close()


@celery_app.task(name="sms_logs_partition_maintenance_task", queue="integrations")
def sms_logs_partition_maintenance_task():
    """每月维护 sms_logs 分区：补建未来月 + DROP 超期月。"""
    try:
        stats = maintain_sms_logs_partitions()
        logger.info("sms_logs 分区维护完成: %s", stats)
        return stats
    except Exception as e:  # noqa: BLE001
        logger.exception("sms_logs 分区维护失败: %s", e)
        return {"error": str(e)}
