# DELPHI PRO Integral E2E Test: scout-web + scout-knowledge
**Date:** 2026-03-20
**Topic:** "AI research agents 2026"

---

## scout-web Results

| # | Channel | Status | Results | Time (est) | Notes |
|---|---------|--------|---------|------------|-------|
| 1 | **Brave Search** | FAIL | 0 | <1s | HTTP 429 - quota exceeded (Free plan: 2000/2000 used). Needs plan upgrade or key rotation. |
| 2 | **Tavily** | FAIL | 0 | <1s | Plan usage limit exceeded. Needs plan upgrade or new API key. |
| 3 | **Exa** | PASS | 3 | ~2s | Neural search returned 3 rich results with full text. Top hit: Zylos AI tool-use optimization article (2026-03-03). High-quality content extraction. |
| 4 | **GitHub Repos** | PASS | 5 (of 120 total) | ~1s | Returned 5 repos: `dzhng/deep-research`, `karpathy/autoresearch` (2026-03-06!), `assafelovic/gpt-researcher`, `HKUDS/Auto-Deep-Research`, `virattt/ai-financial-agent`. All actively pushed in 2025-2026. |
| 5 | **DuckDuckGo** | FAIL | 0 | <1s | Rate limited ("DDG detected an anomaly"). Known issue with DDG bot detection. |
| 6 | **Perplexity (via OpenRouter)** | PASS | 1 (868 chars) | 3.9s | Model `perplexity/sonar` responded successfully. Named LangGraph, CrewAI, AutoGen, LlamaIndex, LangChain as top frameworks. Key validated (73 chars). |

### scout-web Summary
- **PASS: 3/6** (Exa, GitHub, Perplexity)
- **FAIL: 3/6** (Brave quota, Tavily quota, DuckDuckGo rate-limit)
- **Action items:**
  - Brave: rotate API key or upgrade from Free plan
  - Tavily: upgrade plan or obtain new key
  - DuckDuckGo: unreliable for automated use; consider deprioritizing or adding retry/backoff

---

## scout-knowledge Results

| # | Channel | Status | Results | Time (est) | Notes |
|---|---------|--------|---------|------------|-------|
| 1 | **ArXiv** | PASS | 3 | ~2s | Returned 3 highly relevant papers: `AgentIR` (2603.04384), `Total Recall QA` (2603.18516), `SAGE` (2602.05975). All 2026 publications on deep research agents. Excellent relevance. |
| 2 | **OpenAlex** | PASS | 3 | ~2s | Returned 3 works. Top result has suspicious cite count (14128 for fringe paper). 2nd: chatbot review (147 cites). 3rd: "Towards AI Research Agents in Chemical Sciences" (2024, directly relevant). Mixed relevance - may need query refinement. |
| 3 | **Wikipedia** | PASS | 3 | ~1s | Returned: "Intelligent agent" (pageid 2711317), "AI agent" (pageid 78823217), "History of artificial intelligence" (pageid 2894560). Good foundational references. |
| 4 | **News CLI (Guardian)** | PASS | 3 | 1.5s | Returned 3 T1-tier Guardian articles. All March 2026. Topics: rogue AI agents (lab tests), NK agents using AI, Meta AI agent data leak. Clean JSON output. Exit code 0. |

### scout-knowledge Summary
- **PASS: 4/4** (ArXiv, OpenAlex, Wikipedia, News CLI)
- **Action items:**
  - OpenAlex: consider adding relevance filtering (first result was low-quality/high-cite-count anomaly)
  - ArXiv results were exceptionally relevant and current

---

## Overall Assessment

| Suite | Pass | Fail | Rate |
|-------|------|------|------|
| scout-web | 3 | 3 | 50% |
| scout-knowledge | 4 | 0 | 100% |
| **Total** | **7** | **3** | **70%** |

### Critical Path Status
- **Research viable:** YES - Exa + GitHub + Perplexity provide sufficient web coverage
- **Knowledge viable:** YES - all 4 channels operational
- **Blockers:** Brave and Tavily quota exhaustion degrades web breadth. Not blocking but reduces redundancy.

### Recommended Fixes (Priority Order)
1. **Brave API key** - rotate or upgrade plan (blocks primary web search)
2. **Tavily API key** - upgrade plan (blocks backup web search)
3. **DuckDuckGo** - add retry with backoff; consider making it fallback-only
4. **OpenAlex** - add result quality filter to avoid citation-count anomalies
