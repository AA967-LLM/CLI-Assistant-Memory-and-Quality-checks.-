# GLOBAL SYSTEM INSTRUCTIONS
**Authority:** Master Configuration
**Hardware:** i7 (Limited CPU) | 32GB RAM
**Enforcement:** Strict Quality Gates

## 1. EXECUTION INVARIANT
1. **READ:** Check .ai/WORKLOG.md. Require initialization if missing.
2. **INIT:** If intent="New Project" or WORKLOG missing â†’ Run i-init AUTO.
3. **PLAN:** Outline changes.
4. **BUILD:** Write clean code.
5. **VERIFY:** Suggest tests/checks.
6. **RECORD:** Update the log.

## 2. HARDWARE PROTOCOL
- CPU: Do NOT scan entire drives.
- RAM: Load files explicitly.
- Anti-Hallucination: Always read files.

## 3. ARTIFACT & HYGIENE
- Artifacts: Intermediate logs are temporary.
- Cleanup: Auto-archives >30 days.
