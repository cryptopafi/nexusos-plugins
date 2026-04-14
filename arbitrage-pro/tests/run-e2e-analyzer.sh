#!/usr/bin/env bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════
# Arbitrage Pro — E2E Analyzer Test with Real Data
# Simulates the full analyzer pipeline on 3 real lots
# ═══════════════════════════════════════════════════════════════

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Arbitrage Pro — E2E Analyzer (Real Data)${NC}"
echo -e "${BLUE}  $(date)${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo ""

# ─── LOT 1: SOTOS VOJUS TURNTEC 63 CNC Lathe (CZ → RO) ─────
echo -e "${BOLD}📦 LOT 1: SOTOS VOJUS TURNTEC 63 — CNC Lathe${NC}"
echo "   Platform: Surplex | Location: CZ | Category: industrial"
BUY=2500
PREMIUM=$(echo "scale=2; $BUY * 0.15" | bc)  # 375
TRANSPORT=1540  # CZ→RO truck-24t
VAT=0  # B2B reverse charge
HANDLING=50  # industrial
TOTAL=$(echo "scale=2; $BUY + $PREMIUM + $TRANSPORT + $VAT + $HANDLING" | bc)
# Comparables: €8824 (sim=0.6) and €10784 (sim=0.5)
# Weighted median: (8824*0.6 + 10784*0.5) / (0.6+0.5) = (5294.4 + 5392) / 1.1 = 9714.9
SELL=$(echo "scale=2; (8824*0.6 + 10784*0.5) / (0.6+0.5)" | bc)
PROFIT=$(echo "scale=2; $SELL - $TOTAL" | bc)
ROI=$(echo "scale=1; $PROFIT / $TOTAL * 100" | bc)
# Risk: base=4(industrial), mods: time(>7d)=0.5, condition(used-good)=0, capital(<5K)=0, transport(robust)=0 → 4.5
RISK="4.5"
CONF="0.5"  # only 2 comparables = 0.7, static table = 0.7 → min = 0.5 (sim_score avg < 0.7)
DEAL=$(echo "scale=2; $ROI * (1 - $RISK/20) * $CONF" | bc)
echo "   Buy: €$BUY | Premium: €$PREMIUM | Transport: €$TRANSPORT | Handling: €$HANDLING"
echo "   Total Landed: €$TOTAL"
echo "   Sell Price (weighted): €$SELL"
echo -e "   ${GREEN}Net Profit: €$PROFIT | ROI: ${ROI}%${NC}"
echo "   Risk: $RISK/10 | Confidence: $CONF | Deal Score: $DEAL"
if (( $(echo "$DEAL > 40" | bc) )); then
  echo -e "   ${GREEN}Verdict: 🟢 BUY${NC}"
elif (( $(echo "$DEAL > 15" | bc) )); then
  echo -e "   ${YELLOW}Verdict: 🟡 WATCH${NC}"
else
  echo -e "   ${RED}Verdict: 🔴 SKIP${NC}"
fi
echo ""

# ─── LOT 2: DMG GILDEMEISTER CTX ALPHA 300 CNC Lathe (DE → RO) ─
echo -e "${BOLD}📦 LOT 2: DMG GILDEMEISTER CTX ALPHA 300 — CNC Lathe${NC}"
echo "   Platform: Surplex | Location: DE | Category: industrial"
BUY=5000
PREMIUM=$(echo "scale=2; $BUY * 0.15" | bc)  # 750
TRANSPORT=2240  # DE→RO truck-24t
HANDLING=50
TOTAL=$(echo "scale=2; $BUY + $PREMIUM + $TRANSPORT + $VAT + $HANDLING" | bc)
# Comparables: €14706 (sim=0.8) and €16667 (sim=0.9)
SELL=$(echo "scale=2; (14706*0.8 + 16667*0.9) / (0.8+0.9)" | bc)
PROFIT=$(echo "scale=2; $SELL - $TOTAL" | bc)
ROI=$(echo "scale=1; $PROFIT / $TOTAL * 100" | bc)
# Risk: base=4, mods: time(>7d)=0.5, condition(used-good)=0, capital(5K-20K)=+0.5, robust=0 → 5.0
RISK="5.0"
CONF="0.7"  # 2 comparables = 0.7, static = 0.7 → min = 0.7
DEAL=$(echo "scale=2; $ROI * (1 - $RISK/20) * $CONF" | bc)
echo "   Buy: €$BUY | Premium: €$PREMIUM | Transport: €$TRANSPORT | Handling: €$HANDLING"
echo "   Total Landed: €$TOTAL"
echo "   Sell Price (weighted): €$SELL"
echo -e "   ${GREEN}Net Profit: €$PROFIT | ROI: ${ROI}%${NC}"
echo "   Risk: $RISK/10 | Confidence: $CONF | Deal Score: $DEAL"
if (( $(echo "$DEAL > 40" | bc) )); then
  echo -e "   ${GREEN}Verdict: 🟢 BUY${NC}"
elif (( $(echo "$DEAL > 15" | bc) )); then
  echo -e "   ${YELLOW}Verdict: 🟡 WATCH${NC}"
else
  echo -e "   ${RED}Verdict: 🔴 SKIP${NC}"
fi
echo ""

# ─── LOT 3: Professional Espresso Machine (NL → RO) ─────────
echo -e "${BOLD}📦 LOT 3: Professional Espresso Machine 2 Group${NC}"
echo "   Platform: Troostwijk | Location: NL | Category: restaurant-equipment"
BUY=350
PREMIUM=$(echo "scale=2; $BUY * 0.15" | bc)  # 52.50
TRANSPORT=2310  # NL→RO van-3.5t
HANDLING=30
TOTAL=$(echo "scale=2; $BUY + $PREMIUM + $TRANSPORT + $VAT + $HANDLING" | bc)
# Comparables (5 items): weighted by similarity
# €765(0.7) + €1078(0.8) + €1373(0.75) + €1600(0.6) + €882(0.85)
# Weighted = (765*0.7+1078*0.8+1373*0.75+1600*0.6+882*0.85)/(0.7+0.8+0.75+0.6+0.85)
SELL=$(echo "scale=2; (765*0.7+1078*0.8+1373*0.75+1600*0.6+882*0.85)/(0.7+0.8+0.75+0.6+0.85)" | bc)
PROFIT=$(echo "scale=2; $SELL - $TOTAL" | bc)
ROI=$(echo "scale=1; $PROFIT / $TOTAL * 100" | bc)
# Risk: base=3(restaurant), mods: time(>7d)=0.5, condition(used-good)=0, capital(<5K)=0, transport(standard)=+0.5 → 4.0
RISK="4.0"
CONF="0.7"  # 5 comparables = 1.0, static = 0.7 → min = 0.7
DEAL=$(echo "scale=2; $ROI * (1 - $RISK/20) * $CONF" | bc)
echo "   Buy: €$BUY | Premium: €$PREMIUM | Transport: €$TRANSPORT | Handling: €$HANDLING"
echo "   Total Landed: €$TOTAL"
echo "   Sell Price (weighted): €$SELL"
echo -e "   Profit: €$PROFIT | ROI: ${ROI}%"
echo "   Risk: $RISK/10 | Confidence: $CONF | Deal Score: $DEAL"
if (( $(echo "$DEAL > 40" | bc) )); then
  echo -e "   ${GREEN}Verdict: 🟢 BUY${NC}"
elif (( $(echo "$DEAL > 15" | bc) )); then
  echo -e "   ${YELLOW}Verdict: 🟡 WATCH${NC}"
else
  echo -e "   ${RED}Verdict: 🔴 SKIP${NC}"
fi

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo -e "${BOLD}  KEY INSIGHTS FROM REAL DATA${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo ""
echo "  1. 🏭 HIGH-VALUE INDUSTRIAL (CNC) → Transport cost is small vs. item value"
echo "     → CNC lathes at €2500-5000 sell for €9700-15800 on OLX = viable arbitrage"
echo ""
echo "  2. ☕ SINGLE ESPRESSO MACHINES → Transport kills the deal"
echo "     → €350 machine + €2310 transport = €2742 landed vs €1050 sell = LOSS"
echo "     → ONLY viable if: bulk shipment (10+ units) OR local pickup"
echo ""
echo "  3. 📊 DMG/Gildemeister brand premium is REAL"
echo "     → Brand name CNC (DMG) sells 50-70% higher than generic CNC on OLX"
echo "     → Target premium brands at auction for highest margins"
echo ""
echo "  4. 🚛 Transport thresholds:"
echo "     → Items must be worth >€3000 for NL/DE→RO to make sense"
echo "     → Items <€1000: only viable within 500km or via courier"
echo ""
