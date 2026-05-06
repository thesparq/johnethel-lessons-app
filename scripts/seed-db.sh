#!/usr/bin/env bash
# seed-db.sh — Seed the local SurrealDB with sample lesson data
# Usage: ./scripts/seed-db.sh

set -e

SURREAL_BIN="${SURREAL_BIN:-/home/thesparq/.surrealdb/surreal}"
SEED_FILE="${SEED_FILE:-./seed_lessons.surql}"
DB_URL="${SURREAL_URL:-http://127.0.0.1:8000}"
DB_USER="${SURREAL_USER:-root}"
DB_PASS="${SURREAL_PASS:-root}"
DB_NS="${SURREAL_NS:-johnethel}"
DB_DB="${SURREAL_DB:-lessons}"

echo "=== Johnethel LMS Database Seeder ==="
echo ""

# Check if surreal binary exists
if [ ! -f "$SURREAL_BIN" ]; then
  echo "❌ SurrealDB binary not found at: $SURREAL_BIN"
  echo "   Set SURREAL_BIN env var or install SurrealDB to ~/.surrealdb/"
  exit 1
fi

# Check if seed file exists
if [ ! -f "$SEED_FILE" ]; then
  echo "❌ Seed file not found: $SEED_FILE"
  exit 1
fi

echo "📦 SurrealDB binary: $SURREAL_BIN"
echo "📄 Seed file:       $SEED_FILE"
echo "🌐 Endpoint:        $DB_URL"
echo "🏢 Namespace:       $DB_NS"
echo "💾 Database:        $DB_DB"
echo ""

# Check if SurrealDB is running
echo "🔍 Checking if SurrealDB is running..."
if curl -s "$DB_URL/health" > /dev/null 2>&1; then
  echo "   ✅ SurrealDB is running at $DB_URL"
else
  echo "   ⚠️  SurrealDB is not running. Starting it now..."
  echo ""
  
  # Start SurrealDB in-memory mode
  nohup "$SURREAL_BIN" start \
    --user "$DB_USER" \
    --pass "$DB_PASS" \
    --bind 127.0.0.1:8000 \
    > /tmp/surrealdb.log 2>&1 &
  
  SURREAL_PID=$!
  echo "   🚀 Started SurrealDB (PID: $SURREAL_PID)"
  echo "   📝 Logs: /tmp/surrealdb.log"
  echo ""
  
  # Wait for it to be ready
  echo "   ⏳ Waiting for SurrealDB to be ready..."
  for i in {1..30}; do
    if curl -s "$DB_URL/health" > /dev/null 2>&1; then
      echo "   ✅ SurrealDB is ready!"
      echo ""
      break
    fi
    sleep 1
    if [ $i -eq 30 ]; then
      echo "   ❌ Timeout waiting for SurrealDB to start"
      echo "   Check logs: tail -f /tmp/surrealdb.log"
      exit 1
    fi
  done
fi

# Create namespace and database
echo "🏗️  Creating namespace '$DB_NS' and database '$DB_DB'..."
curl -s -X POST \
  -u "$DB_USER:$DB_PASS" \
  -H "Accept: application/json" \
  "$DB_URL/sql" \
  -d "USE NS $DB_NS DB $DB_DB;" > /dev/null

# Clear existing data (optional, safe for local dev)
echo "🧹 Clearing existing lesson_content data..."
curl -s -X POST \
  -u "$DB_USER:$DB_PASS" \
  -H "surreal-ns: $DB_NS" \
  -H "surreal-db: $DB_DB" \
  -H "Accept: application/json" \
  "$DB_URL/sql" \
  -d "DELETE lesson_content;" > /dev/null

# Import seed data
echo "🌱 Importing seed data from $SEED_FILE..."
"$SURREAL_BIN" import \
  --endpoint "$DB_URL" \
  --username "$DB_USER" \
  --password "$DB_PASS" \
  --namespace "$DB_NS" \
  --database "$DB_DB" \
  "$SEED_FILE"

# Verify
echo ""
echo "✅ Seed complete!"
echo ""
echo "📊 Verification:"
echo "   Subjects:"
SUBJECTS=$(curl -s -X POST \
  -u "$DB_USER:$DB_PASS" \
  -H "surreal-ns: $DB_NS" \
  -H "surreal-db: $DB_DB" \
  -H "Accept: application/json" \
  "$DB_URL/sql" \
  -d "SELECT subject FROM lesson_content GROUP BY subject;" | grep -o '"subject":"[^"]*"' | cut -d'"' -f4)

for subject in $SUBJECTS; do
  COUNT=$(curl -s -X POST \
    -u "$DB_USER:$DB_PASS" \
    -H "surreal-ns: $DB_NS" \
    -H "surreal-db: $DB_DB" \
    -H "Accept: application/json" \
    "$DB_URL/sql" \
    -d "SELECT count() FROM lesson_content WHERE subject = '$subject' GROUP BY count;" | grep -o '"count":[0-9]*' | cut -d':' -f2)
  echo "     • $subject: $COUNT lessons"
done

echo ""
echo "🚀 SurrealDB is ready at $DB_URL"
echo "   NS: $DB_NS | DB: $DB_DB"
