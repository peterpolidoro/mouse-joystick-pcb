# Mouse Joystick PCB Agent Guidance

This file is the canonical project guidance for agent sessions in this
repository.

## Session Start

Read this file first.

If `AGENT_MEMORY_REPO` is set and points at a directory, read
`$AGENT_MEMORY_REPO/AGENTS.md` before planning or editing.

If sibling checkouts exist, read:

- `../mouse-joysticks-pcb/docs/` — the twin-axis board for the same rig, and the
  source of most of this repository's documentation
- `../orb-weaver-context/context/agent-index.md`
- `../orb-weaver-context/context/kicad-agent-context.md`
- `../orb-weaver-context/context/pcb-development-plan.md`
- `../board-interfaces/docs/instrument-port-40.md`
- `../kicad-libs/docs/design-blocks.md`

If `.agents/handoff.local.md` exists, read it before planning or editing.

If the session drives a board (a reflash, a measurement, a person at the
lever), read `../mouse-joystick-firm/.agents/AGENTS.md`, section "Hardware
Sessions", and for the Rig 1 reflash and torque calibration of October 2026
`../mouse-joystick-firm/.agents/handoff-rig1-torque-calibration-2026-10-16.md`.
Measured numbers still land in this repository's `docs/bringup-log.md`.

If the task is multi-step, risky, or likely to span more than one session, read
`.agents/PLANS.md` and keep it updated as work progresses.

## Current State — 2026-10-15

v1.0 is fabricated, tagged `v1.0` and in service: four boards built from
`fab/mouse-joystick-pcb/` (the v1.0 order, regenerated only for a new
revision), two in Rig 1 and two on the verification rig. The copper is the
fabricated copper; since the tag the block sheets were regenerated from the
library with the copper kept, and the PCB changed in footprint fields, paths
and group ids only. Its documentation is complete: the generated set under
`docs/generated/` (block pages, subsystem pages, the MCU pin allocation, the
dimensioned outline drawing, the BOM with its sourcing, the recorded netlist
checks), the README block and the Pages site
(https://peterpolidoro.github.io/mouse-joystick-pcb/, built by
`.github/workflows/pages.yml` from the committed pages; `make site` builds it
strictly here). Bring-up findings and open items are in `.agents/PLANS.md`
and `docs/bringup-log.md`.

The routing record of September 2026 ([the routing session handoff](../docs/routing-session-handoff-2026-09-21.md),
the autoroute log, the routing completion and the connector access
correction) is history, kept for how the board came to be; it is not an
instruction to route again. The next revision's changes are the PLANS
items (the brake overshoot, the inert torque calibration switch, the USB
1200 baud touch), each decided with measurements first.

## Repository Purpose

This repository owns the KiCad implementation and board-specific notes for
`mouse-joystick-pcb`: a **single-axis** mouse joystick controller integrated as a
native pyControl peripheral. Two of these boards serve the rig's two joysticks.

**There is a second, live design for the same rig.** `../mouse-joysticks-pcb` is
the twin-axis board. The form-factor question is deliberately open. See
`docs/relationship-to-twin-axis-board.md`.

The predecessor motor-control validation board is `../tmc51x0-driver-dev-pcb`.
The previous-generation joystick board is `~/Repositories/kicad/mouse-joystick-pcb`
— same name, different design, prior art to mine rather than a dependency.

## Board Rules

- **One PCB, one joystick axis, one pyControl UART.** There is no axis argument
  in the protocol and no axis suffix in net names. If you find yourself adding
  one, you are working on the wrong board.
- **Do not port twin-axis complexity here.** Axis symmetry rules, cross-axis
  fault policy, `XFAULT`, and the `B`-for-both protocol argument belong in
  `../mouse-joysticks-pcb`. Their absence is the point.
- **Rev 0 is deliberately scoped down; the pin map is not.** Rev 0 connects 18
  of 30 GPIOs and reserves more at fixed numbers so rev 1 adds them without
  moving anything. **Spares are now `GP15`, `GP16`, `GP18` and `GP27` — four, not
  five.** `GP14` was consumed on 2026-08-17 by `HV_DIAG_EN`; see the `DIAG_EN`
  rule below. If a change needs more pins than are free, say so rather than
  quietly cutting a reserved function. See `docs/interface-map.md` and
  `docs/rev0-plan.md`.
- **`kicad/board-manifest.yaml` is the board's manifest** (kicad-libs decision
  D20, written 2026-10-01): every placed block with its anchor, each port mapped
  to the label it meets in its parent sheet or `open` with a reason, the four
  wrapper sheets, the netclass profiles and every net's class. After placing,
  wiring or moving a block: `make mechanical-datums`, `make board-manifest-derive`
  (keeps the written meanings and reasons), `make board-manifest-check`. The block
  between the `GENERATED BOARD MANIFEST` markers at the top of
  `docs/interface-map.md` is its rendering (`make board-manifest-render`), never
  edited by hand; the narrative below the block is.
  **`make compose` makes the project agree with the manifest** (kicad-libs D28,
  proven on a scratch copy of this board 2026-10-02): a placement the board
  lacks gets its child sheet from the library block, its sheet symbol with the
  recorded pins, a stub and label per mapped port, a no-connect per open port
  and its PCB group with the block's copper at the recorded anchor; a pin wired
  to nothing gets its stub. It never moves, renames or deletes, so a difference
  it reports is fixed in the drawing or the manifest. `make compose-check` is
  the dry run; after a real run, `make mechanical-datums` then
  `make board-manifest-check`. The scratch proof lives in `tmp/compose-proof/`
  (ignored) until the GUI gate is done.
- **`kicad/board.yaml` is the board's source** (kicad-libs D27, written
  2026-10-02): the `motor_encoder_switch` recipe from kicad-libs by reference
  (pinned by hash; the `driver` role overridden to the as-built retired
  `tmc5130` block, which the expansion reports as drift), the three
  board-local recipes in `kicad/subsystems/` (`mcu`, `brake_torque_sensor`,
  `instrument_port`), the five root blocks, and the net meanings;
  `kicad/sheet-pins.yaml` holds this board's own sheet-pin arrangements.
  `make expand` writes `kicad/board-manifest.yaml` from it and
  `make expand-check` compares (exact as of 2026-10-02). The manifest stays
  the checked file: edit the source, `make expand`, `make
  board-manifest-check`, then `make compose`.
- **`make refresh-block INSTANCE=<name> [BLOCK=] [RENAME=OLD=NEW]`** brings one
  placed block up to its library block (kicad-libs D22, proven on a scratch
  copy of this board 2026-10-02: the 5 V regulator to
  `orb_weaver_tpsm365r6_fixed:tpsm365r6_fixed_5v`, whose output port is `VOUT`
  where the board says `+5V`; the digital-50 boundary's copper). It keeps
  designators, restores pins by name, replaces the group's copper by identity
  and leaves everything else byte for byte; it prints what to change in
  `kicad/board.yaml`. The three retired blocks (`tmc5130` →
  `orb_weaver_tmc5130:tmc5130_spi_r150`, `hv_to_5v_tpsm365r6`,
  `hv_to_12v_tpsm365r6` → `orb_weaver_tpsm365r6_adjustable:tpsm365r6_adjustable_12v`)
  are its targets on the real board, when you decide to; the regulators'
  new port copper lands on your own routing (DRC names it).
- **`make generate-glue`** draws this board's own parts, the glue a recipe or
  `kicad/board.yaml` names (the pulls and series resistors, the connectors,
  the mounting holes, the PWR_FLAGs), into the sheets `make compose` created:
  a symbol with a stub and a local label per pin carrying the recipe's net
  name, two-pin parts upright in a row with reference and value at the right
  (kicad-libs step 8b, D28; proven 2026-10-02 by regenerating this whole
  schematic into `tmp/generate-proof/` to the hand-built netlist). It creates
  and never moves: a part already drawn under the recipe's reference, or
  placed by an earlier run, is skipped, so on the drawn board it has nothing
  to draw. Designators of parts it draws follow the sheet's page band; the
  recipe-to-board mapping is in `kicad/board-manifest.compose.json`.
  `GENERATE_GLUE_OPTIONS=--dry-run` reports first. The order for a new
  board: edit the source, `make expand`, `make compose`, `make generate-glue`,
  `make board-manifest-check`.
- **Current sense is 0.15 Ω with `vsense = 1` and `IRUN = 28`** for the 0.67 A/
  phase motor, on both shunt positions. **The `tmc5130` block ships 0.12 Ω as its
  default — change it.** As of 2026-08-17 this is the *only* electrical difference
  between the board and its `kicad-libs` sources, and it runs in the board's
  favour: `kicad-libs` moved to 0.12 Ω in commit `a8dca31`. **Re-placing the
  `tmc5130` block silently reverts the shunts** and puts roughly 25% over the
  intended current. Fix the library down to 0.15 Ω, or never re-place that block.
  `vsense` is CHOPCONF bit 17 and its reset default is 0;
  leaving it at 0 with 0.15 Ω installed drives roughly 1.8× the motor's rated
  current. Firmware must set and read back `vsense = 1` before raising
  `DRV_ENN`. The shunt value and the `vsense` setting are one decision — never
  change either independently.
- **The supply is 36 V, and that has consequences.** The TMC5130A operates to
  46 V, so 36 V leaves 10 V of transient headroom, and the 36 V input block
  populates no TVS. The TMC's internal 5 V regulator must be offloaded by
  supplying `VCC` externally. See `docs/power.md` before touching the power
  section.
- **The high-side switch is a reset button, and the board has two power
  domains.** Feed `hv_to_5v_tpsm365r6` from the **switched** `+36V_SW` — that is
  what makes `HV_EN` power-cycle every resettable chip. It is only safe because
  the MCU is on a separate always-on domain fed from USB `VBUS` or pyControl
  pin 6 through two ORing diodes, never from the 36 V chain. **Reversed
  2026-08-13**; earlier guidance said feed pre-switch. Putting the *MCU* on the
  switched chain is still the way to make an unbootable board. See
  `docs/power.md`.
- **`DIAG_EN` must stay on a GPIO. Never tie it high.** Added 2026-08-17, and it
  is not obvious: holding the TPS1HTC100's `DIAG_EN` high keeps its OFF-state
  open-load detection enabled, which switches in an internal 150 kΩ pull-up from
  `VS` to `VOUT`. At 36 V that trickles ~240 µA into `+36V_SW`'s ~208 µF, the
  rail creeps past the buck's 3.6 V minimum `VIN` in about three seconds, and the
  switched domain hiccups instead of staying off — which silently destroys the
  power-cycle-as-reset property above. `DIAG_EN` has an internal pull-down, so
  `GP14` high-Z at reset means diagnostics off and `+36V_SW` at true zero.
  Protection still works with diagnostics off; only reporting is gated, so
  firmware must raise `GP14` before reading current sense or faults.
- **Anything that must read HIGH while the driver is powered pulls up to
  `+3.3V_SW`, never `+3.3V_MCU`.** Pulling a cross-domain net up to the always-on
  rail back-powers `+3.3V_SW` to roughly 1.3 V through the TMC's protection
  diodes, defeats the `HV_EN` power-cycle, and corrupts `SW_RAIL_SENSE` — the very
  reading firmware uses to decide the switched rail is down. This was built the
  wrong way once. Pulls that may read LOW go straight to GND. The nine board-level
  termination resistors and the reasoning for each are in `.agents/PLANS.md`.
- **`R408`/`R409` provide the passive discharge path for `+3.3V_SW`**, through
  the `SW_RAIL_SENSE` divider. Pull-ups to that rail approach LOW once it settles
  off, provided other drivers do not inject current. Removing the divider changes
  that expectation. `kicad/observation/port-map.md` separates checked resistor
  paths from unqualified reset/off-state electrical behavior.
- pyControl owns experiment sequencing. This board owns local motion timing and
  safety. Never move experiment-level decisions into this firmware, and never
  expose unbounded trajectories or raw motor power as the normal API.
- `RJ-45` names a connector family, not an interface. Do not treat the pyControl
  behavior port as Ethernet and do not place Ethernet magnetics. The pinout and
  serial parameters in `docs/pycontrol-port-pinout.md` are **cited, not
  bench-verified**.
- The assigned pyControl port must be UART-capable: ports 1, 3, or 4 on Breakout
  board 1.2; ports 1, 2, 3, 4, 5, 9, or 10 on the H7 breakout — **but the H7's
  UARTs are routed, not yet declared**, because `pycontrol/code` v2.1.1 has no
  `breakout_h7.py`. The D-series Breakout Board 1.6 list (8, 10, 11, 12) is
  carried forward unverified; that board is in no local checkout. The full
  controller-side map is `../board-interfaces/docs/pycontrol-behavior-port.md`.
- Both DIO lines on the assigned port are consumed by the UART. The three TTL
  lines land on BNCs **in rev 1** — Rev 0 carries the serial link only.
- **`DIO-A` is this board's RX; `DIO-B` is this board's TX.** The alphabetical
  order reverses, so `PYC_DIO_A` → `PYC_UART_RX` → `GP1` and `PYC_DIO_B` →
  `PYC_UART_TX` → `GP0`. Block pins are named by connector position, board nets
  by MCU function; the crossover happens once, at the `mcu` sheet boundary.
  Diagram and the full sheet-pin direction table in `docs/interface-map.md`.
- **pyControl pin 6's 5 V is load-bearing**, not optional: it is one of only two
  sources that power the board. Confirmed 5 V from the syringe-pump netlist; its
  current budget is unmeasured.
- Do not carry motor power through the pyControl behavior port. The board runs a
  36 V rail the port does not supply.
- **InstrumentPort-40 is in Rev 0** as of 2026-08-16, with 11 of 18 digital
  Strands live and 4 reserved for the rev 2 brake and torque sensor — three of
  which `ENC_A`, `ENC_B`, and `LIMIT_SW` borrow until then. `DIG0`, `DIG1`, and
  `DIG11` are **swap slots**; do not treat those tenants as permanent, and do not
  reassign the slots early. The full allocation is in `docs/interface-map.md`. It is intended
  for use **during scientific experiments**, not only on the bench, so
  observation must be passive, unidirectional, and unable to affect rig
  behavior. No divided motor rail reaches any `AIN*`.
- **The encoder and the limit switch never reach a GPIO**, in any revision —
  decided 2026-08-16. The TMC5130A owns them; firmware reads position and homing
  from the driver over SPI. `GP14`/`GP15`/`GP16`/`GP18` are spare and the PIO
  cross-check and `ENCODER_MISMATCH` are deleted, not deferred. The InstrumentPort
  taps are the board's only independent witnesses to those signals.
- **Tap points are decisions, not details.** The TMC5130A bus is observed on the
  *A* side of the GPIO isolation switch, and the encoder and limit switch on the
  *driver* side of their conditioning, because in those cases the series element
  has two distinguishable states. The pyControl serial is taken from the port block's
  existing `PYC_DIO_A`/`PYC_DIO_B` pins — **do not re-propose a connector-side tap
  with extra boundary pins**; it was considered and rejected, because a digital
  channel cannot resolve 33 mV across 100 Ω and the tap would sit on the
  unprotected side of the ESD clamp. All reasoned in `docs/interface-map.md`.
  A 100 kΩ pull-down goes wherever a tapped net can float, and no `SN74LVC125A`
  input may be left undriven.
- Do not redefine InstrumentPort-40 here; document only this board's overlay. If
  the profile is genuinely too narrow, raise it in `board-interfaces`.
- Do not define the reusable pyControl connector profile here. That belongs in
  `board-interfaces` once it has sufficient evidence.
- **Two interchangeable boards in one rig is a new failure mode.** Calibration
  belongs to a board serial, not to a joystick position. `ID` reports the serial.
  Silkscreen a unit identifier.
- **Rev 0 has no SWD header and no reset connection**, decided 2026-08-17. `RUN`,
  `SWCLK` and `SWD` are no-connect flagged. RP2040 `RUN` has an internal 50–80 kΩ
  pull-up so this is an access limitation, not an electrical defect — but it means
  no debugger during bring-up, and BOOTSEL recovery needs both USB *and* pyControl
  unplugged, because the MCU domain is ORed from two sources. Revisit in a future
  revision rather than treating it as an oversight.
- Distinguish cited claims from bench-verified claims. Unknowns stay explicit
  unknowns with an owner.
- Use `kicad-libs` for shared symbols, footprints, internal parts, vendor
  mappings, and design blocks. Promote a circuit into `kicad-libs` only after
  this board verifies it.
- Record real board results in `docs/bringup-log.md`, per board serial.

## Keeping Two Repositories In Sync

Shared facts live in both this repository and `../mouse-joysticks-pcb`:

- the pyControl port pinout and UART parameters
- the motor part, its rating, and the current-sense decision
- the encoder part and the limit switch part
- the DAC part and the logic-level answer
- the UART protocol's framing, verbs, events, and fault model

**When one of these changes, change it in both.** A silent divergence in a shared
fact is the failure mode of running two repositories.

## Safety Rules

The board must reach a safe state without pyControl's cooperation:

- On boot: motor rail off, stepper outputs disabled, wait for an explicit `ARM`.
- During operation: require a host heartbeat; enforce current, velocity,
  acceleration, and travel limits; latch faults; assert the `FAULT` line; drop
  `HV_EN`.
- On host loss, heartbeat timeout, reset, or fault: stop motion, report the
  cause.
- With two boards in a rig, one board's fault leaves the other running. Decide
  explicitly whether that is acceptable, and prefer a hard-wired `EXT_FAULT_IN`
  over relying on the host to notice. See `docs/pycontrol-interface.md`.

## Development Environment

Prefer Makefile targets:

- `make test` — documentation and scaffold presence check
- `make codex` / `make claude` — agent sessions with sibling checkouts added
- `make agent-reflection`
- `make kicad-shell` / `make kicad-edits`
- `make validate-db` — Orb Weaver KiCad database library wiring
- `make fab` — fabrication outputs
- `make docs` — regenerate `docs/generated/` and the README's managed block
- `make docs-check` — report whether that documentation is stale
- `make check-kicad-libs`

`docs/generated/` and the block between the
`<!-- BEGIN/END GENERATED BOARD DOCUMENTATION -->` markers in `README.md` are
written by `make docs`. Never hand-edit either. `make docs` is a no-op unless a
`.kicad_sch`, `.kicad_pcb`, `.kicad_pro` or `.kicad_dru` hash changed, so run it
freely; `make docs-check` is the pre-tag gate and names what moved. Mechanical
coordinates there are centre-of-board origin, X right and Y up, which is not
KiCad's frame — see `kicad-libs/docs/board-documentation.md`.

### Local KiCad Overlay

The pinned Guix channel (`dd8c1c5`) carries KiCad 10.0.6, verified with
`guix time-machine -C .guix/channels.scm -- show kicad`, so plain
`make kicad-edits` gives 10.0.6. The opt-in overlay in
`.guix/manifest-kicad-local.scm` and
`.guix/local-modules/orb-weaver/kicad-local.scm` (`make kicad-version-local`,
`kicad-shell-local`, `kicad-edits-local`, `fab-local`) stays as the hook for
the interval between a KiCad release and its Guix package; the user uses it
whenever KiCad is ahead of Guix. Since 2026-10-08 it overrides KiCad 10.0.7
(released that day; the Guix update is submitted upstream), so the `-local`
targets give 10.0.7 and the default ones 10.0.6. The module is byte-identical
in `kicad-libs`, `mouse-joysticks-pcb` and `tmc51x0-driver-dev-pcb`; bump all
four together (the procedure is in `kicad-libs/docs/guix-packaging.md`), and
reset it to plain aliases once the pin catches up.

### Routing Helpers

`make export-dsn`, `make freeroute`, `make import-ses`, `make clearance-baseline`
and `make clearance-check` call the shared kicad-libs commands
(`orb-weaver-kicad-export-dsn`, `-import-ses`, `-clearance-check`); the scripts
moved out of this repository's `scripts/` on 2026-09-25 and the channel pin
`768a00b` ships them. `kicad/clearance-baseline.json` is still this board's
baseline. Workflow: kicad-libs `docs/freerouting-autorouting.md`.

### KiCad Project State

**Layout and routing are complete as of 2026-09-21.** The four-layer PCB has
364 footprints, with all 1,204 numbered pad identities matching the schematic.
The configured fabrication build reports ERC 0 errors/0 warnings and DRC
0 errors/0 unconnected pads. Its remaining warnings are 499 advisory clearances
and 20 dangling vias; clearance regression passes with no voltage-bearing
findings. These checks do not establish firmware or bench behavior.

ERC alone did not catch the earlier electrical findings. After schematic or
layout edits, compare the exported schematic netlist to the PCB as well as
running ERC/DRC. Use `.agents/PLANS.md` and the tracked handoff above for current
status; older dated planning entries are history where completion supersedes
them. The project now has 24 netclasses and 166 netclass patterns, the four-layer
stackup, plot/fabrication setup and JLCPCB design rules.

**The netclasses were doing nothing until 2026-09-17.** The `.kicad_dru` carried
an unconditional `(constraint clearance (min 0.10mm))` rule, and **an
unconditional custom clearance constraint replaces the netclass value rather
than flooring it** — so the effective clearance was 0.10 mm board-wide and all 21
classes' 0.15–0.5 mm settings were dead letters. Fixed in `ff081ff`: the fab
floors moved to Board Setup → Constraints (`min_clearance` and `min_track_width`,
0.0 → 0.1 mm) and both unconditional rules were deleted. **Never re-add a fab
floor as an unconditional rule** — the file carries a comment saying so. All
conditional rules were kept.

`rule_severities.clearance` is `error` here and must stay that way. The
existing scoped `Legacy low-voltage block clearance is advisory` rule demotes
non-voltage-bearing pairs to warnings; HV, motor and other voltage-bearing
classes remain errors. Preserve that distinction and run `make clearance-check`
after routing. Never suppress the clearance category globally to hide failures.

The inherited patterns were generic names (`+24V`, `VM`, `PGND`, `+3V3`,
`USB_HS`) that matched almost nothing here — 146 of 156 nets fell to `Default` at
0.2 mm, including the 36 V rail and all four motor phases, and `*/HV_IN` was
silently matching `PWR_HV_LOCAL` at 0.25 mm. **Fixed 2026-08-17.** Two things to
know before touching them again: this board's rails are spelled `+3.3V_*`, not
`+3V3_*`; and `BRA`/`BRB` are **not** Kelvin sense nets on a TMC5130A — they carry
full coil current into the sense resistor, so they are sized with the motor
phases. `SENSE_KELVIN` exists for the TMC5160's `SRA`/`SRB`. If you add patterns,
re-check that no net matches more than one netclass.

## Validation

For documentation-only changes, review against `docs/validation-plan.md` gates.

For schematic/layout work, use KiCad ERC/DRC once the design is mature enough for
those checks to be meaningful.

`ORB_WEAVER_KICAD_LIBS` must resolve for KiCad to find the database and footprint
libraries.

When editing `kicad-libs` design blocks, run `scrub-private-vendor-fields`
**then** `validate`. Validate inspects `.kicad_sch` only, so a passing validate
does not prove the `.kicad_pcb` side is clean.

## Publication Layers

This repository is mirrored to GitHub for the rig's researchers, so it has two
layers (decided 2026-10-12):

- **Citable layer**: `README.md`, `CITATION.cff`, `LICENSE`, `LICENSES/`,
  `kicad/`, `fab/`, `docs/generated/` and every document the README lists.
  It must open and read without any Orb Weaver checkout and must not refer to
  codeberg.org or to `orb-weaver-*` repositories. KiCad library identifiers
  (`orb_weaver_private:…`, `orb_weaver_smd:…`) and the generated-block
  comments are allowed; they are library references, not links. Files in
  other repositories are cited as `<repository>/<path>` with no `../` and no
  URL; `docs/development.md` maps each repository name to its URL.
- **Development layer**: `docs/development.md`, the documents it lists,
  `AGENTS.md`, `.agents/`, `.codex/`, `Makefile` and `.guix/`. These may name
  the sibling checkouts and the Orb Weaver repositories.

A new document goes into exactly one of the two lists. `LICENSES/NOTICE.md`
keeps its `kicad-libs` URL: it is the CC-BY-SA attribution for the embedded
symbols, footprints and blocks.
