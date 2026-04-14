# OpenRouter Models Audit for DELPHI PRO
**Generated**: 2026-03-20 19:21
**Total models on OpenRouter**: 350
**Models with pricing > $0**: 321
**Free models**: 27

---

## TABLE 1: Search & Research Models

Models with built-in web search capability -- critical for DELPHI scouts.

| Model | Input $/1M | Output $/1M | Context | Max Output | Cache Read $/1M | Notes |
|-------|-----------|------------|---------|------------|-----------------|-------|
| `perplexity/sonar` | $1.00 | $1.00 | 127,072 | 0 | FREE | Basic search, cheapest Perplexity |
| `perplexity/sonar-pro` | $3.00 | $15.00 | 200,000 | 8,000 | FREE | Enhanced search, longer output |
| `perplexity/sonar-pro-search` | $3.00 | $15.00 | 200,000 | 8,000 | FREE | Same as sonar-pro (alias) |
| `perplexity/sonar-reasoning-pro` | $2.00 | $8.00 | 128,000 | 0 | FREE | Search + chain-of-thought reasoning |
| `perplexity/sonar-deep-research` | $2.00 | $8.00 | 128,000 | 0 | FREE | Multi-step deep research with citations |
| `openai/gpt-4o-mini-search-preview` | $0.150 | $0.600 | 128,000 | 16,384 | FREE | GPT-4o-mini with Bing search |
| `openai/gpt-4o-search-preview` | $2.50 | $10.00 | 128,000 | 16,384 | FREE | GPT-4o with Bing search |
| `openai/o4-mini-deep-research` | $2.00 | $8.00 | 200,000 | 100,000 | $0.500 | o4-mini with deep web research |
| `openai/o3-deep-research` | $10.00 | $40.00 | 200,000 | 100,000 | $2.50 | o3 with deep web research (premium) |
| `alibaba/tongyi-deepresearch-30b-a3b` | $0.090 | $0.450 | 131,072 | 131,072 | $0.090 | Alibaba deep research, very cheap |
| `relace/relace-search` | $1.00 | $3.00 | 256,000 | 128,000 | FREE | Code-focused search |

### Sonar Family Comparison

| Feature | sonar | sonar-pro | sonar-reasoning-pro | sonar-deep-research |
|---------|-------|-----------|--------------------|--------------------|
| Input $/1M | $1.00 | $3.00 | $2.00 | $2.00 |
| Output $/1M | $1.00 | $15.00 | $8.00 | $8.00 |
| Context | 127K | 200K | 128K | 128K |
| Web Search | Yes | Yes | Yes | Yes |
| Reasoning | No | No | Yes (CoT) | Yes (multi-step) |
| Citations | Basic | Enhanced | Enhanced | Comprehensive |
| Best For | Quick lookups | Detailed search | Analytical queries | Deep investigations |

**DELPHI Recommendation**: Use `sonar` for D1 quick scouts ($1/1M), `sonar-reasoning-pro` for D2-D3 ($2/$8), `sonar-deep-research` for D4 deep dives ($2/$8).

## TABLE 2: Deep Research Models

For `scout-deep` module -- models that can do multi-step, autonomous research.

| Model | Input $/1M | Output $/1M | Context | Max Output | Quality Tier |
|-------|-----------|------------|---------|------------|-------------|
| `perplexity/sonar-deep-research` | $2.00 | $8.00 | 128,000 | 0 | A-tier (web search built-in) |
| `openai/o4-mini-deep-research` | $2.00 | $8.00 | 200,000 | 100,000 | A-tier (cheaper deep research) |
| `openai/o3-deep-research` | $10.00 | $40.00 | 200,000 | 100,000 | S-tier (best quality, expensive) |
| `alibaba/tongyi-deepresearch-30b-a3b` | $0.090 | $0.450 | 131,072 | 131,072 | B-tier (extremely cheap) |
| `google/gemini-2.5-pro` | $1.25 | $10.00 | 1,048,576 | 65,536 | A-tier (1M ctx, thinking mode) |
| `google/gemini-2.5-flash` | $0.300 | $2.50 | 1,048,576 | 65,535 | B+tier (fast, cheap, 1M ctx) |
| `openai/o3` | $2.00 | $8.00 | 200,000 | 100,000 | A-tier (strong reasoning) |
| `openai/o3-pro` | $20.00 | $80.00 | 200,000 | 100,000 | S-tier (highest quality reasoning) |
| `openai/o4-mini` | $1.10 | $4.40 | 200,000 | 100,000 | B+tier (good reasoning, cheap) |
| `anthropic/claude-opus-4.6` | $5.00 | $25.00 | 1,000,000 | 128,000 | S-tier (1M ctx, best analysis) |

**DELPHI Recommendation**: `o4-mini-deep-research` is the best value for deep research ($2/$8, 200K ctx). `sonar-deep-research` adds web search. For premium: `o3-deep-research` ($10/$40).

## TABLE 3: Reasoning Models (Critic Council)

For synthesis, critic evaluation, and complex analytical tasks.

| Model | Input $/1M | Output $/1M | Context | Max Output | Notes |
|-------|-----------|------------|---------|------------|-------|
| `qwen/qwq-32b` | $0.150 | $0.580 | 131,072 | 131,072 | Strong reasoning, very cheap |
| `qwen/qwen3-30b-a3b-thinking-2507` | $0.080 | $0.400 | 131,072 | 131,072 | Latest Qwen thinking, cheap |
| `qwen/qwen3-235b-a22b-thinking-2507` | $0.150 | $1.50 | 131,072 | 0 | Large Qwen thinking model |
| `deepseek/deepseek-r1-0528` | $0.450 | $2.15 | 163,840 | 65,536 | Strong open reasoning |
| `deepseek/deepseek-r1` | $0.700 | $2.50 | 64,000 | 16,000 | Original DeepSeek R1 |
| `moonshotai/kimi-k2-thinking` | $0.470 | $2.00 | 131,072 | 0 | Kimi thinking model |
| `qwen/qwen3-max-thinking` | $0.780 | $3.90 | 262,144 | 32,768 | Qwen Max with thinking |
| `openai/o4-mini` | $1.10 | $4.40 | 200,000 | 100,000 | OpenAI reasoning, good value |
| `openai/o4-mini-high` | $1.10 | $4.40 | 200,000 | 100,000 | o4-mini with more compute |
| `openai/o3-mini` | $1.10 | $4.40 | 200,000 | 100,000 | Predecessor, similar pricing |
| `openai/o3` | $2.00 | $8.00 | 200,000 | 100,000 | Strong reasoning tier |
| `perplexity/sonar-reasoning-pro` | $2.00 | $8.00 | 128,000 | 0 | Reasoning + web search |
| `anthropic/claude-sonnet-4.6` | $3.00 | $15.00 | 1,000,000 | 128,000 | Claude latest, 1M ctx |
| `anthropic/claude-sonnet-4.5` | $3.00 | $15.00 | 1,000,000 | 64,000 | Claude 4.5 Sonnet, 1M ctx |
| `anthropic/claude-opus-4.6` | $5.00 | $25.00 | 1,000,000 | 128,000 | Best Claude, 1M ctx |
| `anthropic/claude-opus-4.5` | $5.00 | $25.00 | 200,000 | 64,000 | Claude 4.5 Opus |
| `google/gemini-2.5-pro` | $1.25 | $10.00 | 1,048,576 | 65,536 | Google best, 1M ctx, thinking |
| `openai/o1` | $15.00 | $60.00 | 200,000 | 100,000 | Original o1 |
| `openai/o3-pro` | $20.00 | $80.00 | 200,000 | 100,000 | Premium reasoning |
| `openai/o1-pro` | $150.00 | $600.00 | 200,000 | 100,000 | Ultra-premium |

**DELPHI Recommendation**: For Critic Council use `o4-mini` ($1.10/$4.40) or `qwq-32b` ($0.15/$0.58) for cost-sensitive runs. For synthesis: `gemini-2.5-pro` ($1.25/$10) offers excellent value with 1M context.

## TABLE 4: Fast/Cheap Scout Models (Haiku Alternatives)

Current baseline: `claude-haiku-4.5` at $1.00/$5.00 per 1M tokens.

| Model | Input $/1M | Output $/1M | Context | Max Output | Savings vs Haiku | Notes |
|-------|-----------|------------|---------|------------|-----------------|-------|
| `openai/gpt-5-nano` | $0.050 | $0.400 | 400,000 | 128,000 | +95% input | 95% cheaper input |
| `openai/gpt-4.1-nano` | $0.100 | $0.400 | 1,047,576 | 32,768 | +90% input | 90% cheaper input, 1M ctx |
| `openai/gpt-4o-mini` | $0.150 | $0.600 | 128,000 | 16,384 | +85% input | 85% cheaper input |
| `openai/gpt-5-mini` | $0.250 | $2.00 | 400,000 | 128,000 | +75% input | 75% cheaper input, 400K ctx |
| `openai/gpt-4.1-mini` | $0.400 | $1.60 | 1,047,576 | 32,768 | +60% input | 60% cheaper input, 1M ctx |
| `google/gemini-2.5-flash-lite` | $0.100 | $0.400 | 1,048,576 | 65,535 | +90% input | 90% cheaper, 1M ctx |
| `google/gemini-2.5-flash` | $0.300 | $2.50 | 1,048,576 | 65,535 | +70% input | 70% cheaper, 1M ctx, thinking |
| `qwen/qwen3-30b-a3b-instruct-2507` | $0.090 | $0.300 | 262,144 | 262,144 | +91% input | 91% cheaper input |
| `meta-llama/llama-4-scout` | $0.080 | $0.300 | 327,680 | 16,384 | +92% input | 92% cheaper, 327K ctx |
| `meta-llama/llama-4-maverick` | $0.150 | $0.600 | 1,048,576 | 16,384 | +85% input | 85% cheaper, 1M ctx |
| `mistralai/mistral-small-2603` | $0.150 | $0.600 | 262,144 | 0 | +85% input | 85% cheaper |
| `qwen/qwen-plus` | $0.260 | $0.780 | 1,000,000 | 32,768 | +74% input | 74% cheaper, 1M ctx |
| `anthropic/claude-3-haiku` | $0.250 | $1.25 | 200,000 | 4,096 | +75% input | 75% cheaper (legacy) |
| `anthropic/claude-3.5-haiku` | $0.800 | $4.00 | 200,000 | 8,192 | +20% input | 20% cheaper |

### Top Scout Replacements (Best Value)

1. **`google/gemini-2.5-flash-lite`** -- $0.10/$0.40, 1M context, 90% cheaper than Haiku
2. **`openai/gpt-5-nano`** -- $0.05/$0.40, 400K context, 95% cheaper than Haiku
3. **`openai/gpt-4.1-nano`** -- $0.10/$0.40, 1M context, 90% cheaper than Haiku
4. **`google/gemini-2.5-flash`** -- $0.30/$2.50, 1M context, thinking mode, 70% cheaper
5. **`meta-llama/llama-4-scout`** -- $0.08/$0.30, 327K context, 92% cheaper

## TABLE 5: Cost per Research Run

Assumptions: ~2K input tokens per search call, ~1K output tokens per search response,
~4K input for synthesis, ~2K output for synthesis, ~3K input for critic, ~1.5K output for critic,
~8K input for deep research, ~4K output for deep research, ~6K input for opus synthesis, ~3K output.

| Stack | D1 (1 search) | D2 (4 search + synth) | D3 (6 search + critic + synth) | D4 (10 search + 3 critics + deep + opus synth) |
|-------|--------------|----------------------|-------------------------------|-----------------------------------------------|
| **Current (Claude-only)** | $7.000 | $70.000 | $115.500 | $409.500 |
| **Optimal OpenRouter** | $3.000 | $37.000 | $52.900 | $212.700 |
| **Budget OpenRouter** | $3.000 | $18.200 | $25.520 | $73.980 |
| **Ultra-Budget** | $0.900 | $4.800 | $7.920 | $24.780 |
| **Premium Quality** | $12.000 | $118.000 | $160.000 | $519.000 |

*Costs shown in thousandths of a dollar (mills). Multiply by 1000 for per-1000-runs cost.*

### Cost per 100 Research Runs

| Stack | 100x D1 | 100x D2 | 100x D3 | 100x D4 |
|-------|---------|---------|---------|---------|
| **Current (Claude-only)** | $0.70 | $7.00 | $11.55 | $40.95 |
| **Optimal OpenRouter** | $0.30 | $3.70 | $5.29 | $21.27 |
| **Budget OpenRouter** | $0.30 | $1.82 | $2.55 | $7.40 |
| **Ultra-Budget** | $0.09 | $0.48 | $0.79 | $2.48 |
| **Premium Quality** | $1.20 | $11.80 | $16.00 | $51.90 |

### Savings Summary

- **D1**: Optimal saves 57% vs Claude-only, Budget saves 57%
- **D2**: Optimal saves 47% vs Claude-only, Budget saves 74%
- **D3**: Optimal saves 54% vs Claude-only, Budget saves 78%
- **D4**: Optimal saves 48% vs Claude-only, Budget saves 82%

## TABLE 6: Special Capabilities

### Models with Built-in Web Search

| Model | Input $/1M | Output $/1M | Search Type |
|-------|-----------|------------|------------|
| `perplexity/sonar` | $1.00 | $1.00 | Real-time web search + citations |
| `perplexity/sonar-pro` | $3.00 | $15.00 | Enhanced web search + citations |
| `perplexity/sonar-reasoning-pro` | $2.00 | $8.00 | Web search + reasoning |
| `perplexity/sonar-deep-research` | $2.00 | $8.00 | Multi-step autonomous research |
| `openai/gpt-4o-mini-search-preview` | $0.150 | $0.600 | Bing search integration |
| `openai/gpt-4o-search-preview` | $2.50 | $10.00 | Bing search integration |
| `openai/o4-mini-deep-research` | $2.00 | $8.00 | Deep web research + reasoning |
| `openai/o3-deep-research` | $10.00 | $40.00 | Premium deep web research |
| `alibaba/tongyi-deepresearch-30b-a3b` | $0.090 | $0.450 | Alibaba deep research |

### Models with Very Long Context (>500K)

| Model | Context | Input $/1M | Output $/1M |
|-------|---------|-----------|------------|
| `x-ai/grok-4.20-multi-agent-beta` | 2,000,000 | $2.00 | $6.00 |
| `x-ai/grok-4.20-beta` | 2,000,000 | $2.00 | $6.00 |
| `x-ai/grok-4.1-fast` | 2,000,000 | $0.200 | $0.500 |
| `x-ai/grok-4-fast` | 2,000,000 | $0.200 | $0.500 |
| `openai/gpt-5.4-pro` | 1,050,000 | $30.00 | $180.00 |
| `openai/gpt-5.4` | 1,050,000 | $2.50 | $15.00 |
| `xiaomi/mimo-v2-pro` | 1,048,576 | $1.00 | $3.00 |
| `google/gemini-3.1-flash-lite-preview` | 1,048,576 | $0.250 | $1.50 |
| `google/gemini-3.1-pro-preview-customtools` | 1,048,576 | $2.00 | $12.00 |
| `google/gemini-3.1-pro-preview` | 1,048,576 | $2.00 | $12.00 |
| `google/gemini-3-flash-preview` | 1,048,576 | $0.500 | $3.00 |
| `google/gemini-3-pro-preview` | 1,048,576 | $2.00 | $12.00 |
| `google/gemini-2.5-flash-lite-preview-09-2025` | 1,048,576 | $0.100 | $0.400 |
| `google/gemini-2.5-flash-lite` | 1,048,576 | $0.100 | $0.400 |
| `google/gemini-2.5-flash` | 1,048,576 | $0.300 | $2.50 |
| `google/gemini-2.5-pro` | 1,048,576 | $1.25 | $10.00 |
| `google/gemini-2.5-pro-preview` | 1,048,576 | $1.25 | $10.00 |
| `google/gemini-2.5-pro-preview-05-06` | 1,048,576 | $1.25 | $10.00 |
| `meta-llama/llama-4-maverick` | 1,048,576 | $0.150 | $0.600 |
| `google/gemini-2.0-flash-lite-001` | 1,048,576 | $0.075 | $0.300 |
| `google/gemini-2.0-flash-001` | 1,048,576 | $0.100 | $0.400 |
| `openai/gpt-4.1` | 1,047,576 | $2.00 | $8.00 |
| `openai/gpt-4.1-mini` | 1,047,576 | $0.400 | $1.60 |
| `openai/gpt-4.1-nano` | 1,047,576 | $0.100 | $0.400 |
| `writer/palmyra-x5` | 1,040,000 | $0.600 | $6.00 |
| `minimax/minimax-01` | 1,000,192 | $0.200 | $1.10 |
| `qwen/qwen3.5-flash-02-23` | 1,000,000 | $0.065 | $0.260 |
| `anthropic/claude-sonnet-4.6` | 1,000,000 | $3.00 | $15.00 |
| `qwen/qwen3.5-plus-02-15` | 1,000,000 | $0.260 | $1.56 |
| `anthropic/claude-opus-4.6` | 1,000,000 | $5.00 | $25.00 |
| `amazon/nova-2-lite-v1` | 1,000,000 | $0.300 | $2.50 |
| `amazon/nova-premier-v1` | 1,000,000 | $2.50 | $12.50 |
| `anthropic/claude-sonnet-4.5` | 1,000,000 | $3.00 | $15.00 |
| `qwen/qwen3-coder-plus` | 1,000,000 | $0.650 | $3.25 |
| `qwen/qwen3-coder-flash` | 1,000,000 | $0.195 | $0.975 |
| `qwen/qwen-plus-2025-07-28:thinking` | 1,000,000 | $0.260 | $0.780 |
| `qwen/qwen-plus-2025-07-28` | 1,000,000 | $0.260 | $0.780 |
| `minimax/minimax-m1` | 1,000,000 | $0.400 | $2.20 |
| `qwen/qwen-plus` | 1,000,000 | $0.260 | $0.780 |

### Vision/Multimodal Models (Cheap, >32K context)

| Model | Input $/1M | Context | Input Modalities |
|-------|-----------|---------|-----------------|
| `openrouter/free` | FREE | 200,000 | text, image |
| `nvidia/nemotron-nano-12b-v2-vl:free` | FREE | 128,000 | image, text, video |
| `mistralai/mistral-small-3.1-24b-instruct:free` | FREE | 128,000 | text, image |
| `google/gemma-3-4b-it:free` | FREE | 32,768 | text, image |
| `google/gemma-3-12b-it:free` | FREE | 32,768 | text, image |
| `google/gemma-3-27b-it:free` | FREE | 131,072 | text, image |
| `google/gemma-3-4b-it` | $0.040 | 131,072 | text, image |
| `google/gemma-3-12b-it` | $0.040 | 131,072 | text, image |
| `meta-llama/llama-3.2-11b-vision-instruct` | $0.049 | 131,072 | text, image |
| `qwen/qwen3.5-9b` | $0.050 | 256,000 | text, image, video |
| `openai/gpt-5-nano` | $0.050 | 400,000 | text, image, file |
| `amazon/nova-lite-v1` | $0.060 | 300,000 | text, image |
| `qwen/qwen3.5-flash-02-23` | $0.065 | 1,000,000 | text, image, video |
| `bytedance-seed/seed-1.6-flash` | $0.075 | 262,144 | image, text, video |
| `mistralai/mistral-small-3.2-24b-instruct` | $0.075 | 128,000 | image, text |

## DELPHI PRO Optimization Recommendations

### Recommended Model Stack by Depth

| Role | Current | Recommended | Savings |
|------|---------|-------------|---------|
| D1 Scout | claude-haiku-4.5 ($1/$5) | perplexity/sonar ($1/$1) | ~67% on output |
| D2 Scout | claude-haiku-4.5 ($1/$5) | perplexity/sonar ($1/$1) | ~67% on output + built-in search |
| D2 Synthesis | claude-sonnet-4.6 ($3/$15) | gemini-2.5-pro ($1.25/$10) | ~42% |
| D3 Scout | claude-haiku-4.5 ($1/$5) | sonar-reasoning-pro ($2/$8) | Better quality, +search |
| D3 Critic | claude-sonnet-4.6 ($3/$15) | o4-mini ($1.10/$4.40) | ~67% |
| D3 Synthesis | claude-sonnet-4.6 ($3/$15) | gemini-2.5-pro ($1.25/$10) | ~42% |
| D4 Deep Research | claude-opus-4.6 ($5/$25) | o4-mini-deep-research ($2/$8) | ~60% + built-in search |
| D4 Critic | claude-sonnet-4.6 ($3/$15) | o4-mini ($1.10/$4.40) | ~67% |
| D4 Final Synthesis | claude-opus-4.6 ($5/$25) | claude-opus-4.6 ($5/$25) | Keep for quality |

### Key Insights

1. **Perplexity Sonar models have built-in web search** -- eliminates need for separate search API calls, reducing complexity and latency
2. **Google Gemini 2.5 Flash/Pro offer exceptional value** -- 1M context at $0.30/$0.10 input, with thinking mode
3. **OpenAI o4-mini is the best reasoning value** -- $1.10/$4.40, strong CoT, 200K context
4. **Alibaba Tongyi DeepResearch is absurdly cheap** -- $0.09/$0.45 for deep research capability
5. **GPT-5-nano at $0.05/$0.40** is the cheapest viable scout if search isn't built-in
6. **Claude Opus 4.6 now has 1M context** -- worth keeping for final synthesis where quality is paramount
7. **27 free models available** including qwen3-coder, nemotron-super-120b -- useful for low-priority tasks

### Migration Priority

1. **Immediate**: Switch D1-D2 scouts to `perplexity/sonar` (saves ~67% + adds search)
2. **High**: Add `o4-mini` as critic model (saves ~67% vs Sonnet)
3. **Medium**: Add `gemini-2.5-pro` as synthesis model (saves ~42% vs Sonnet, 1M ctx)
4. **Medium**: Add `o4-mini-deep-research` for D4 deep (saves ~60% + built-in search)
5. **Low**: Evaluate `alibaba/tongyi-deepresearch` for budget deep research
6. **Low**: Test `gpt-5-nano`/`gemini-2.5-flash-lite` as ultra-cheap scouts