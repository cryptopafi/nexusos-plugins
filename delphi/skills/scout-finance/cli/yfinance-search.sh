#!/bin/bash
# yfinance-search.sh — Stock/crypto/ETF data via yfinance (FREE, unlimited)
# Replaces Alpha Vantage MCP (25 req/day limit)
#
# Usage:
#   yfinance-search.sh --symbol AAPL [--period 1mo] [--info]
#   yfinance-search.sh --symbol BTC-USD --period 5d

set -euo pipefail

SYMBOL=""
PERIOD="1mo"
INFO=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --symbol) SYMBOL="$2"; shift 2 ;;
    --period) PERIOD="$2"; shift 2 ;;
    --info) INFO=true; shift ;;
    --help)
      echo "Usage: yfinance-search.sh --symbol AAPL [--period 1mo] [--info]"
      echo "Periods: 1d, 5d, 1mo, 3mo, 6mo, 1y, 2y, 5y, 10y, ytd, max"
      exit 0 ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

if [[ -z "$SYMBOL" ]]; then
  echo '{"status": "error", "error": "Provide --symbol (e.g. AAPL, BTC-USD, SPY)", "agent": "scout-finance/yfinance"}' >&2
  exit 1
fi

export SYMBOL PERIOD INFO

python3 << 'PYEOF'
import json, sys, os
import yfinance as yf

symbol = os.environ.get('SYMBOL', '')
period = os.environ.get('PERIOD', '1mo')
show_info = os.environ.get('INFO', 'false') == 'true'

try:
    ticker = yf.Ticker(symbol)

    if show_info:
        info = ticker.info
        key_fields = ['shortName', 'sector', 'industry', 'marketCap', 'previousClose',
                     'open', 'dayHigh', 'dayLow', 'volume', 'fiftyTwoWeekHigh',
                     'fiftyTwoWeekLow', 'trailingPE', 'forwardPE', 'dividendYield',
                     'beta', 'currency', 'exchange']
        filtered = {k: info.get(k) for k in key_fields if info.get(k) is not None}
        result = {
            'status': 'complete',
            'agent': 'scout-finance/yfinance',
            'symbol': symbol,
            'info': filtered,
            'channel': 'yfinance',
            'source_tier': 'T1'
        }
    else:
        hist = ticker.history(period=period)
        if hist.empty:
            result = {'status': 'error', 'error': f'No data for {symbol}'}
        else:
            records = []
            for date, row in hist.tail(30).iterrows():
                records.append({
                    'date': date.strftime('%Y-%m-%d'),
                    'open': round(row['Open'], 2),
                    'high': round(row['High'], 2),
                    'low': round(row['Low'], 2),
                    'close': round(row['Close'], 2),
                    'volume': int(row['Volume'])
                })
            result = {
                'status': 'complete',
                'agent': 'scout-finance/yfinance',
                'symbol': symbol,
                'period': period,
                'data_points': len(records),
                'latest': records[-1] if records else None,
                'history': records,
                'channel': 'yfinance',
                'source_tier': 'T1',
                'note': 'Showing last 30 data points. Use --period for different ranges.'
            }

    print(json.dumps(result, indent=2, default=str))

except Exception as e:
    print(json.dumps({'status': 'error', 'error': str(e)}), file=sys.stderr)
    sys.exit(1)
PYEOF
