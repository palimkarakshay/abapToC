# abapToC

ABAP Transport of Copies (ToC) utility. Ships a custom SAP transaction **ZAPTOC** for one-click
create / release / import of Transport of Copies. Standalone **public MIT** kit (not in the
`lumivara-abap` monorepo — intentionally separate per LUMIVARA.md).


**FORK LINEAGE (2026-06-11):** maintained fork of Kaszub09/abapToC (Marcin Kaszuba, MIT 2023) —
shared git history. All artifacts renamed ZTOC→ZAPTOC / *zabap_toc*→*zaptoc* at larshp's request
(dotabap/dotabap-list#270) so both install side-by-side; README credits the original up top.
NEVER present this repo as original work on marketing surfaces — always "maintained fork".
Product line: **Lumivara SAP** (Clean Core & ABAP modernization).

## Stack & layout
- ABAP **7.50** source, packaged as an **abapGit** repo (`.abapgit.xml`, folder logic = PREFIX, master lang E).
- `src/` — all ABAP objects (abapGit naming `<obj>.<type>.abap` + matching `.xml` metadata):
  - `zaptoc.prog.abap` / `zaptoc.tran.xml` — ZAPTOC report + transaction.
  - `zcl_zaptoc.clas.abap` — core ToC packing/release logic.
  - `zcl_zaptoc_report.clas.abap` — report/UI (selection screen + ALV).
  - `zcx_zaptoc_exception.clas.abap` — exception class.
  - `zaptoc.fugr.*` — function group incl. `zaptoc_unpack` (RFC called on target system).
- `node_modules/` is only the abaplint CLI (devDependency); there is no JS app.

## Develop / Verify (build gate)
Package manager: **npm** (`package-lock.json`). The only gate is abaplint:
- Install: `npm ci`
- Lint (Verify gate): `npm run lint`  (= `abaplint`, config in `abaplint.json`)
- Autofix: `npm run lint:fix`

CI: `.github/workflows/abaplint.yml` runs `npm ci` + `npm run lint` on every push/PR (Node 24).
There are no unit tests and no bundler/build step — abaplint passing IS the build.

## abaplint config notes (abaplint.json)
- Syntax version pinned **v750**; `errorNamespace` = `^(Z|Y|LCL_|TY_|LIF_)`.
- `check_syntax` and `unknown_types` are OFF (no system DDIC available in CI) — don't expect
  type/syntax resolution, only style/parser rules.
- Enforced style: keyword_case **lower**, line length **120**, no tabs, ASCII-only.

## Deploy
No web/Vercel deploy. Distribution = install into an SAP system via abapGit (see README:
SM59 RFC connections named per target `SYS` / `SYS.MANDANT`, optional SMT1 trust).

## Gotchas
- Edit ABAP in `src/` directly; keep abapGit `.xml` metadata in sync with each `.abap` object.
- After any change, run `npm run lint` — it is the same check CI enforces.
- Public OSS kit: keep it self-contained; do NOT fold into `lumivara-abap`.
