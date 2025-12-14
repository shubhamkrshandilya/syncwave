#!/bin/bash

# Performance Testing Script for SyncWave

echo "🔬 SyncWave Performance Tests"
echo "=============================="
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check if server is running
echo -n "Checking server status... "
if curl -s http://localhost:3456/api/health > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Running${NC}"
else
    echo -e "${RED}✗ Not running${NC}"
    echo "Please start the server first: cd server && npm start"
    exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Latency Tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Test 1: Health check latency
echo -n "1. Health Check Latency: "
START=$(date +%s%N)
curl -s http://localhost:3456/api/health > /dev/null
END=$(date +%s%N)
LATENCY=$(((END - START) / 1000000))
if [ $LATENCY -lt 50 ]; then
    echo -e "${GREEN}${LATENCY}ms ✓${NC} (Target: <50ms)"
elif [ $LATENCY -lt 100 ]; then
    echo -e "${YELLOW}${LATENCY}ms ⚠${NC} (Target: <50ms)"
else
    echo -e "${RED}${LATENCY}ms ✗${NC} (Target: <50ms)"
fi

# Test 2: Library load latency
echo -n "2. Library Load Latency: "
START=$(date +%s%N)
RESPONSE=$(curl -s http://localhost:3456/api/songs)
END=$(date +%s%N)
LATENCY=$(((END - START) / 1000000))
SONG_COUNT=$(echo "$RESPONSE" | grep -o '"total":[0-9]*' | grep -o '[0-9]*')
if [ $LATENCY -lt 100 ]; then
    echo -e "${GREEN}${LATENCY}ms ✓${NC} (${SONG_COUNT} songs, Target: <100ms)"
elif [ $LATENCY -lt 500 ]; then
    echo -e "${YELLOW}${LATENCY}ms ⚠${NC} (${SONG_COUNT} songs, Target: <100ms)"
else
    echo -e "${RED}${LATENCY}ms ✗${NC} (${SONG_COUNT} songs, Target: <100ms)"
fi

# Test 3: Search latency
echo -n "3. Search Latency: "
START=$(date +%s%N)
curl -s "http://localhost:3456/api/songs/search?q=test" > /dev/null
END=$(date +%s%N)
LATENCY=$(((END - START) / 1000000))
if [ $LATENCY -lt 50 ]; then
    echo -e "${GREEN}${LATENCY}ms ✓${NC} (Target: <50ms)"
elif [ $LATENCY -lt 150 ]; then
    echo -e "${YELLOW}${LATENCY}ms ⚠${NC} (Target: <50ms)"
else
    echo -e "${RED}${LATENCY}ms ✗${NC} (Target: <50ms)"
fi

# Test 4: Stream start latency (first bytes)
echo -n "4. Stream Start Latency: "
if [ "$SONG_COUNT" -gt 0 ]; then
    FIRST_SONG_ID=$(echo "$RESPONSE" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
    START=$(date +%s%N)
    curl -s -r 0-1024 "http://localhost:3456/api/stream/$FIRST_SONG_ID" > /dev/null 2>&1
    END=$(date +%s%N)
    LATENCY=$(((END - START) / 1000000))
    if [ $LATENCY -lt 200 ]; then
        echo -e "${GREEN}${LATENCY}ms ✓${NC} (Target: <200ms)"
    elif [ $LATENCY -lt 500 ]; then
        echo -e "${YELLOW}${LATENCY}ms ⚠${NC} (Target: <200ms)"
    else
        echo -e "${RED}${LATENCY}ms ✗${NC} (Target: <200ms)"
    fi
else
    echo -e "${YELLOW}Skipped (no songs)${NC}"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "💾 Memory & Storage Tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Test 5: Server memory usage
echo -n "5. Server Memory Usage: "
if command -v ps &> /dev/null; then
    MEM=$(ps aux | grep "node server.js" | grep -v grep | awk '{print $6}')
    if [ ! -z "$MEM" ]; then
        MEM_MB=$((MEM / 1024))
        if [ $MEM_MB -lt 100 ]; then
            echo -e "${GREEN}${MEM_MB}MB ✓${NC} (Target: <100MB idle)"
        elif [ $MEM_MB -lt 200 ]; then
            echo -e "${YELLOW}${MEM_MB}MB ⚠${NC} (Target: <100MB idle)"
        else
            echo -e "${RED}${MEM_MB}MB ✗${NC} (Target: <100MB idle)"
        fi
    else
        echo -e "${YELLOW}Not measurable${NC}"
    fi
else
    echo -e "${YELLOW}ps command not available${NC}"
fi

# Test 6: Library size
echo -n "6. Library Index Size: "
if [ "$SONG_COUNT" -gt 0 ]; then
    RESPONSE_SIZE=$(echo "$RESPONSE" | wc -c)
    RESPONSE_KB=$((RESPONSE_SIZE / 1024))
    BYTES_PER_SONG=$((RESPONSE_SIZE / SONG_COUNT))
    echo -e "${BLUE}${RESPONSE_KB}KB${NC} (${BYTES_PER_SONG} bytes/song)"
else
    echo -e "${YELLOW}No songs in library${NC}"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔄 Concurrent Request Test"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo -n "7. Handling 10 Concurrent Requests: "
START=$(date +%s%N)
for i in {1..10}; do
    curl -s http://localhost:3456/api/health > /dev/null &
done
wait
END=$(date +%s%N)
TOTAL_TIME=$(((END - START) / 1000000))
AVG_TIME=$((TOTAL_TIME / 10))
if [ $AVG_TIME -lt 100 ]; then
    echo -e "${GREEN}${AVG_TIME}ms avg ✓${NC} (Total: ${TOTAL_TIME}ms)"
elif [ $AVG_TIME -lt 200 ]; then
    echo -e "${YELLOW}${AVG_TIME}ms avg ⚠${NC} (Total: ${TOTAL_TIME}ms)"
else
    echo -e "${RED}${AVG_TIME}ms avg ✗${NC} (Total: ${TOTAL_TIME}ms)"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📈 Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Library: ${SONG_COUNT} songs"
echo ""
echo "Recommendations:"
echo "  • If latency >100ms: Check disk I/O (use SSD if possible)"
echo "  • If memory >200MB: Restart server or reduce library size"
echo "  • If concurrent test fails: Server may be CPU-bound"
echo ""
echo "To test Flutter web app performance:"
echo "  1. Open Chrome DevTools (F12)"
echo "  2. Go to Performance tab"
echo "  3. Record while loading library"
echo "  4. Check for long tasks (>50ms)"
echo ""
