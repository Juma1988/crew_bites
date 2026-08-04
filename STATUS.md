# crew-bites-tracker — All-Status (v1.0)

**Last updated:** 2026-07-23  
**Rule engine / rules/*.md:** read details there, main tracker stays compact at root  

---

## ✅ CONFIRMED DONE — listed as single list of tasks

| Task | Summary | When confirmed done |
|------|---------|---------------------|
| D1 Display name → Crew Bites (Android/iOS labels + AppTheme.brandName) package kept app_101 | 2026-07-22 |
| D3 Home flow (skip dialog: new order archives directly, continues to pick crew without confirmation) | 2026-07-21 |
| D4 Colors/Themes polished in Settings (Coral/Ocean/Grape/Mint/Sunset/Mango swatch selection) | 2026-07-22 |
| D5 Continue → Back returns to People (stack: Home → Add User → Add Orders; fixed homepage.dart) | 2026-07-18 + 2026-07-21 |
| D11 AppDebug suite expanded now shipped & hidden | 2026-07-19 |

## ❌ OPEN — still open / needs work

| Task ID | Priority | Brief issue | Notes |
|---------|----------|-------------|-------|
| E41 L9 | Medium/Low | Privacy markdown rendering (SelectableText shows raw syntax on phones) | Add flutter_markdown dep + MarkdownBody replace; verify EN/AR |
| E22 M15 | Medium/Low | Docs drift — plan.md/log.md still reference AppDebug shipped / English-only as if still set | Sync docs to reality per AGENTS rules 3+4: AR default + dual lang now, update RULEs accordingly |
| E23 L3 | Low | Seed names EN-only on AR-default app (Alex/Sam/Jordan — region-neutral or use Translate.foodTitle) | Needs product-level decision before coding |

## 🟡 INCOMPLETE / PARTIAL (still ongoing)

| Task ID | Priority | Current state |
|---------|----------|---------------|
| E27 C3/S1 | Critical/P0 | Play Console needs privacy policy hosted HTTPS for upload; offline-only today fine — resolve before production ship if public release planned |
| E56 M12 | Medium/M2 – fixed 2026-07-22 now | Privacy page locale-sticky until reopen/app close: reactive via AppSettings + FutureBuilder (fixed) |

## ✅ NEXT PRIORITY (after current open tasks — listed as next steps to work on)

1. **C2** Preserve foodPrices when OrderSession rebuilds on People → Next  
   Issue: prices drop; unassigned foods vanish — copy `foodPrices` into rebuilt session before commit
2. **H1/H3** Unknown-price sentinel flag + clear- roster reset not fully updated in memory  
   Unknown ≠ 0 missing; H3 clears prefs but CrewStore UI stays stale until restart (done only when user next opens app)
3. **RB-04 Review Board mandatory no-skip-rule** — every new feature starts with 3-bullet spec as template: problem → solution → accept-criteria, PR template required before coding begins  
   ```json
   {
     "template": {"problem":"...","solution":"...","accept_criteria":["Problem solved","Acceptance confirmed"]},
     "skip_condition": null,
     "skip_message": null  -- must be set for any skipped feature (no skip allowed unless user explicitly says so)
   }
   ```

## 📜 Rules engine — active guardrails summary (detailed docs at rules/01-definition-of-done.md through rules/06-review-board.md)

- **R-O1 Definition of Done:** task is only truly done after tests pass + CI runs; no just-emulator, prevents issues that took months to surface  
- **FRZ-27 Dependency freeze with weekly allowed upgrades:** lock pubspec so commits can't break UI accidentally; weekly allowed-upgrade list approved by team keeps pipeline from becoming completely frozen forever  
- **DOC-03 Document before shipping + STATUS.md rule (CI fail):** update STATUS.md alongside code for every release — if you add features without updating doc status it's rejected at merge time via hard CI check fails
- **PRIV-29 Privacy-first default:** personal data stored offline until review consent approved and feature design confirmed; no accidental sharing without explicit user permission flow  
- **RB-06 Review Board mandatory no-skip-rule (hard fail):** every new feature must submit 3-bullet spec (problem/solution/accept-criteria) before code starts; PR template blocked unless filled with skip_condition=null — no skipping allowed by default