# abapToC (ZAPTOC)

ABAP Transport of Copies — a one-click create / release / import workflow for Transports of
Copies, packaged as transaction **ZAPTOC**.

> **Lineage & credit:** this project is a maintained fork of
> [**Kaszub09/abapToC**](https://github.com/Kaszub09/abapToC) by **Marcin Kaszuba**, who wrote
> the original tool (MIT, 2023). All artifacts in this fork are renamed to the `ZAPTOC*`
> namespace (`ZTOC` → `ZAPTOC`, `ZCL_ZABAP_TOC*` → `ZCL_ZAPTOC*`, function group
> `ZABAP_TOC` → `ZAPTOC`, …) so both projects can be installed side by side without
> collisions. If you want the original, install Marcin's repo.

## Features

1. Transaction **ZAPTOC** for easy creation / release / import of Transports of Copies,
   with an ALV overview of your transports.
2. Create, release, and import a Transport of Copies to the target system with one click
   (import runs over RFC via `ZAPTOC_UNPACK`).

## Installation

1. Install with [abapGit](https://github.com/abapGit/abapGit).
2. For import to work:
   1. Import/transport the project to the target system.
   2. Create an SM59 connection for each possible transport target (e.g. `SYSTEM` or
      `SYSTEM.MANDANT`) with exactly that name — it is used to call the RFC that unpacks
      the transport. So `ZZZ.999` for system ZZZ client 999, or just `ZZZ` if transports
      don't specify a client.
   3. [Optional] Set the development system as trusted (transaction SMT1) on the target
      system, enable Trust Relationship on the connection, and use Current User — then
      imports won't prompt for a target-system login.

## Differences from the original

- All objects renamed to the `ZAPTOC*` namespace (installable alongside the original).
- abaplint CI gate (`npm run lint`, config in `abaplint.json`), lower-case keyword style.
- Small fixes: call transaction mode, transport display, restored E05 textpool entry.

## Notes

1. Written in ABAP 7.50.
2. License: MIT (original copyright Marcin Kaszuba — see [LICENSE](LICENSE)).
