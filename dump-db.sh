#!/usr/bin/env bash
#
# misskey-db-dump.sh
#
# misskey の PostgreSQL データベースを kubectl port-forward 経由で論理ダンプする。
# envfile から接続情報を読み込む。
#
# 前提:
#   - 母艦から kubectl が実行可能
#   - misskey namespace の db Pod が稼働中
#   - envfile に POSTGRES_USER / POSTGRES_PASSWORD / POSTGRES_DB が定義されている

set -euo pipefail

# ===== 設定 =====
ENVFILE="${ENVFILE:-./envfile}"
NAMESPACE="${NAMESPACE:-misskey}"
POD="${POD:-db}"
LOCAL_PORT="${LOCAL_PORT:-5432}"
REMOTE_PORT="${REMOTE_PORT:-5432}"
OUTPUT_DIR="${OUTPUT_DIR:-$HOME/pi41-backup}"

# ===== envfile 読み込み =====
if [[ ! -f "$ENVFILE" ]]; then
    echo "ERROR: envfile not found: $ENVFILE" >&2
    exit 1
fi

# envfile の中の POSTGRES_* だけ読み込む(他の変数で汚染しないように grep で絞る)
# shellcheck disable=SC1090
source <(grep -E '^POSTGRES_(USER|PASSWORD|DB)=' "$ENVFILE")

: "${POSTGRES_USER:?POSTGRES_USER not set in $ENVFILE}"
: "${POSTGRES_PASSWORD:?POSTGRES_PASSWORD not set in $ENVFILE}"
: "${POSTGRES_DB:?POSTGRES_DB not set in $ENVFILE}"

echo "[info] envfile loaded: user=$POSTGRES_USER db=$POSTGRES_DB"

# ===== 出力先準備 =====
mkdir -p "$OUTPUT_DIR"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
DUMP_FILE="$OUTPUT_DIR/misskey_db_${TIMESTAMP}.dump"

# ===== port-forward 起動(バックグラウンド) =====
echo "[info] starting port-forward: $NAMESPACE/$POD ${LOCAL_PORT}:${REMOTE_PORT}"
kubectl port-forward -n "$NAMESPACE" "$POD" "${LOCAL_PORT}:${REMOTE_PORT}" >/dev/null 2>&1 &
PF_PID=$!

# 終了時に必ず port-forward を止める
cleanup() {
    if kill -0 "$PF_PID" 2>/dev/null; then
        echo "[info] stopping port-forward (PID $PF_PID)"
        kill "$PF_PID" 2>/dev/null || true
        wait "$PF_PID" 2>/dev/null || true
    fi
}
trap cleanup EXIT

# port-forward が listen するまで待つ(最大 10 秒)
echo "[info] waiting for port-forward to be ready..."
for i in {1..20}; do
    if (echo > "/dev/tcp/127.0.0.1/${LOCAL_PORT}") 2>/dev/null; then
        echo "[info] port-forward is ready"
        break
    fi
    if [[ $i -eq 20 ]]; then
        echo "ERROR: port-forward did not become ready within 10 seconds" >&2
        exit 1
    fi
    sleep 0.5
done

# ===== 接続テスト =====
echo "[info] testing connection..."
if ! PGPASSWORD="$POSTGRES_PASSWORD" psql \
    -h 127.0.0.1 -p "$LOCAL_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" \
    -c '\conninfo' >/dev/null 2>&1; then
    echo "ERROR: failed to connect to PostgreSQL" >&2
    exit 1
fi
echo "[info] connection OK"

# ===== ダンプ実行 =====
echo "[info] running pg_dump -> $DUMP_FILE"
PGPASSWORD="$POSTGRES_PASSWORD" pg_dump \
    -h 127.0.0.1 -p "$LOCAL_PORT" \
    -U "$POSTGRES_USER" -d "$POSTGRES_DB" \
    --format=custom \
    --file="$DUMP_FILE"

# ===== 結果確認 =====
SIZE=$(du -h "$DUMP_FILE" | cut -f1)
echo "[info] dump completed: $DUMP_FILE ($SIZE)"

# 簡易検証: pg_restore --list でリスト出せるか
if pg_restore --list "$DUMP_FILE" >/dev/null 2>&1; then
    echo "[info] dump verification: OK (pg_restore --list succeeded)"
else
    echo "[warn] dump verification: pg_restore --list failed" >&2
    exit 1
fi

echo "[done] backup successful"

