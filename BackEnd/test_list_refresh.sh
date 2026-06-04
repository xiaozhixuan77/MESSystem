#!/bin/bash
# 产线列表刷新 — 完整用户流程集成测试
set -e

BASE="http://localhost:8080"
PASS=0
FAIL=0

check() { if [ "$1" = "$2" ]; then PASS=$((PASS+1)); echo "  ✅ $3"; else FAIL=$((FAIL+1)); echo "  ❌ $3 (expected '$2', got '$1')"; fi; }
check_gt() { if [ "$1" -gt "$2" ] 2>/dev/null; then PASS=$((PASS+1)); echo "  ✅ $3"; else FAIL=$((FAIL+1)); echo "  ❌ $3 ($1 <= $2)"; fi; }
jsonval() { python -c "import sys,json; d=json.load(sys.stdin)['data']; [print(l['$2']) for l in d if l['id']==$1]" 2>/dev/null; }

echo "=== 1. 登录 ==="
LOGIN=$(curl -sf -X POST "$BASE/auth/login" -H "Content-Type: application/json" -d '{"username":"OP001","password":"123456"}')
TOKEN=$(echo "$LOGIN" | python -c "import sys,json; print(json.load(sys.stdin)['data']['token'])" 2>/dev/null)
check "$(echo "$LOGIN" | python -c "import sys,json; print(json.load(sys.stdin)['code'])" 2>/dev/null)" "200" "登录返回 200"

echo ""
echo "=== 2. 获取产线列表 ==="
LIST=$(curl -sf "$BASE/lines" -H "Authorization: Bearer $TOKEN")
LINE1_STATUS=$(echo "$LIST" | jsonval 1 "status")
LINE1_FINISHED=$(echo "$LIST" | jsonval 1 "finishedCount")
echo "  产线1 状态: $LINE1_STATUS, 产量: $LINE1_FINISHED"
check "$LINE1_STATUS" "暂停" "产线1 状态为暂停"

echo ""
echo "=== 3. 启动产线 ==="
START=$(curl -sf -X POST "$BASE/lines/1/start" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -d '{"workOrderId":13}')
check "$(echo "$START" | python -c "import sys,json; print(json.load(sys.stdin)['code'])" 2>/dev/null)" "200" "启动成功"

echo ""
echo "=== 4. 等待仿真 Tick (5s) ==="
sleep 5

echo ""
echo "=== 5. 返回列表 → HTTP 重新拉取 ==="
LIST2=$(curl -sf "$BASE/lines" -H "Authorization: Bearer $TOKEN")
LINE1_STATUS2=$(echo "$LIST2" | jsonval 1 "status")
LINE1_FINISHED2=$(echo "$LIST2" | jsonval 1 "finishedCount")
echo "  产线1 状态: $LINE1_STATUS2, 产量: $LINE1_FINISHED2"
check "$LINE1_STATUS2" "生产中" "刷新 → 状态「生产中」"
check_gt "$LINE1_FINISHED2" "$LINE1_FINISHED" "产量增长 ($LINE1_FINISHED → $LINE1_FINISHED2)"

echo ""
echo "=== 6. 停止产线 ==="
STOP=$(curl -sf -X POST "$BASE/lines/1/stop" -H "Authorization: Bearer $TOKEN")
check "$(echo "$STOP" | python -c "import sys,json; print(json.load(sys.stdin)['code'])" 2>/dev/null)" "200" "停止成功"

echo ""
echo "=== 7. 返回列表 → 验证 ==="
LIST3=$(curl -sf "$BASE/lines" -H "Authorization: Bearer $TOKEN")
LINE1_STATUS3=$(echo "$LIST3" | jsonval 1 "status")
echo "  产线1 状态: $LINE1_STATUS3"
check "$LINE1_STATUS3" "暂停" "刷新 → 状态「暂停」"

echo ""
echo "=== 8. 复位产线 ==="
RESET=$(curl -sf -X POST "$BASE/lines/1/reset" -H "Authorization: Bearer $TOKEN")
check "$(echo "$RESET" | python -c "import sys,json; print(json.load(sys.stdin)['code'])" 2>/dev/null)" "200" "复位成功"

LIST4=$(curl -sf "$BASE/lines" -H "Authorization: Bearer $TOKEN")
LINE1_STATUS4=$(echo "$LIST4" | jsonval 1 "status")
check "$LINE1_STATUS4" "空闲" "刷新 → 状态「空闲」"

echo ""
echo "========================================="
echo "  通过: $PASS  失败: $FAIL"
echo "========================================="
[ "$FAIL" -eq 0 ] && echo "全部通过 ✅" || echo "存在失败 ❌"
