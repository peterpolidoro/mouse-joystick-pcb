# Mouse Joystick PCB Plan

Use this file for work that is multi-step, risky, or likely to span multiple
sessions.

## 2026-10-20: GPIO facts for future-board readiness

- [x] Current root netlist exported via KiCad MCP; U601 pad nets inspected via
  MCP. `kicad/observation/` retains the 28-signal/two-spare checked facts,
  contract, pad records and reproduction README. Shared checker is owned by
  kicad-libs, firmware's consumer by mouse-joystick-firm.
- [ ] Compare manufactured connectivity at
  `646b8f47d9d09726598ad332c43e1b4714c95272` with current source
  `3edd5d0913f2028529597f80ccd57609dc61e66b`. No local v1.0 tag; native file
  blobs differ, so current-source agreement is not an equivalence assessment.
- [ ] Extend to complete observation taps, domain/off-state and mux facts.

No native KiCad file, fabrication package or bench log changed. Firmware's
28 constants/spares compile against this export; deliberate mismatch tests
are retained in the owning tools. See kicad-libs/PLANS readiness checkpoint.

## Documentation — complete for v1.0 (2026-10-15)

The documentation program run from kicad-libs (its PLANS, 2026-10-12 to
2026-10-15) is finished for this board: the fifteen placed block sheets
regenerated from the library with the copper kept, a page per placed block
(schematic, parts with sourcing, ports, the place on the board, the recorded
netlist check), the four subsystem pages and the MCU pin allocation from
`kicad/board.yaml` and its recipes, the dimensioned outline and mounting
hole drawing, the BOM page with its LCSC and datasheet links, the board view
with the model and numbered blocks, and the Pages site. `make docs` is a
no-op until a KiCad source changes; `make docs-check` is the gate before a
tag; `make site` builds the site strictly. The hand-written pages were
reviewed the same day: `docs/design-block-map.md` is a pointer page, the
routing pages of September 2026 are grouped as the routing record in the
site's navigation. What a new revision changes in the board is the bring-up
items below.

## Active Task — v1.0 unit A findings from the A4/A5 bring-up (2026-10-06)

Measured on unit A (`E4654C159F274534`) with `mouse-joystick-firm`'s new
`examples/BrakeAndTorque`; numbers in `docs/bringup-log.md` → "v1.0 unit A —
Stages A4 and A5". Three board-level items came out of it, none of which the
firmware can settle:

- [ ] **A full-scale brake step overshoots to 62 mA (127 % of 48.78 mA) for
      ~5 ms and `~{BRAKE_FAULT}` never asserts**, although 62 mA is above the
      56.4 mA ceiling (`V_LIMIT` 0.564 V / 10 Ω). Overshoot begins above ~60 %
      of full scale (90 %: +26 %, 75 %: +15 %, 60 %: +1 %); the first
      millisecond slews 8–14 mA/ms at every amplitude, so it is the coil's
      `L di/dt` against the drain headroom (coil ≈ 1–1.5 H) and the loop
      integrator winding up while the current cannot follow the ~2 ms
      command filter. Decide with a scope on `V_SENSE` (top of `R1816`) and
      `LIMIT_OUT` during a full-scale step: (a) the ceiling amplifier is
      slower than the excursion, (b) it limits but `LIMIT_OUT` never falls
      below `U1803`'s threshold, or (c) the monitor overshoots and the coil
      does not. If (b), the fault indication is blind to exactly the event it
      was added for (the 2026-09-08 reasoning above). Firmware ramps `BRAKE`
      setpoints meanwhile, so the next spin may also choose to slow the
      command filter or add anti-windup instead.
- [ ] **The torque shunt-calibration switch is inert on the as-built board**:
      `TQ_CAL_EN` low / high / low moved the ADS8689 reading by 0.0 codes
      against a design step of 0.744 V (9522 codes). The 2026-10-04 review in
      `kicad-libs/docs/torque-sensor-interface-design.md` predicted it: the
      N-channel enhancement MOSFET's source sits at `SIG_N` ≈ 5 V against a
      3.3 V gate. Fix in the block (a P-channel or a level shift) for the next
      spin; until then calibration is weights on the lever arm (rig plan C3).
      **Done another way 2026-10-16:** a Mark-10 force gauge on a string
      loop, with the gear out, read the right desk station's sensor at 0.965
      of the torque through the brake against 0.961 from the certificates
      (bring-up log, 2026-10-16). The chain is on its certificate; the switch
      fix stays for the next spin as the in-situ check it was meant to be.
- [ ] **Torque rest reading 69–71 mV below the ideal 1.6667 V zero** at
      `AMP_VOUT` (−0.255 N·cm on the nominal scale), 7× the sensor's zero
      balance. Mechanism preload (the joystick against its stop through the
      coupling) or front-end offset (`VEXC`, `VMID`, INA821): free the
      joystick by hand and read again, or meter `VEXC` (10.000 V) and `VMID`
      (5.000 V). Not a defect until separated; tare handles it either way.
      **Mechanical, 2026-10-16:** the rest is −1.8 N·cm raw on unit D and
      +0.2 then +0.6 on unit C, moves 0.3 when the pinion comes off and after
      a hard pull. Preload through the brake's coupling, not the front end.
      The per-trial tare stays necessary; `docs/bnc-conversion.md` tells the
      researcher to zero from the trace.
- [ ] **Friction in the lever axis and a non-linear brake, measured
      2026-10-16** (bring-up log): moving the free lever costs 0.42–0.50 N·cm
      on the right desk station and 0.23–0.38 on the left, the same with the
      gear out, so it is the lever bearings or the brake's coupling, not the
      gear train; the left brake drags 0.1–0.3 with its coil off. The brakes
      deliver 0.4–0.7 N·cm at the commanded 1.0 and 3.0 / 4.0 at full. Open:
      where in the axis the friction is (parts loosened one at a time with the
      gauge on the lever), whether `BRAKE` should map through a per-station
      curve, and the same measurements on Rig 1's stations
      (`mouse-joystick-firm/docs/torque-calibration.md`).
      Decided 2026-10-16: the researcher wants the load the mouse feels, so
      every station gets the alternating pull-push run and its row in
      `docs/station-torque-table.csv`; `docs/bnc-conversion.md` says how the
      trace and the row combine. **Rig 1 measured 2026-10-16** (bring-up
      log, "Rig 1 — reflash to `v1.0.1` and torque calibration"): friction
      0.27/0.12 N·cm pull/push on the right station and 0.18/0.15 on the
      left, smaller than the desk's; the brakes deliver 0.36 and 0.43 at
      the commanded 1.0, 3.03 and 3.58 at full; both rows filled. Still
      open: where in the axis the friction is, the per-station `BRAKE`
      curve, and a gear-out scale check at Rig 1 (the hand-held geometry
      there scattered sensor-over-gauge 0.85–1.07).
- [x] Confirmed on the wire, for the record: I2C 0x48 and 0x49 both ACK;
      brake DAC `GAIN` 0x0101 reads back, `DEVID` 0x115; ADS8689 `RANGE_SEL`
      0x0B reads back, SDO loopback patterns clean, noise 95–112 µV rms at
      1 kHz; brake 0–48.80 mA linear (full scale 1.0065 V against 1.006 V
      design, the 12 V gate drive is sufficient); no brake-to-torque coupling
      at 0.1 mV; `ALARM` 0x0041 at power-up (tripped high-AVDD flag from the
      `+5V_FILT` ramp) clears on read; `DEVICE_ID[15:0]` reads 0x0010 where
      the datasheet says 0 (harmless, noted).

## Open Item — Two of four v1.0 units ignore the USB 1200 baud touch (opened 2026-10-13)

Unit B (board 7, `E4654C159F404534`, 2026-10-07) and unit D (board 9,
`E4654C159F234234`, 2026-10-12) enter BOOTSEL on the 1200 baud touch at most
once and then never again under the delivery build (`mouse_joystick_qp_rev2`):
PlatformIO's upload fails `The RP2040 device returned an error: <unknown>` or
leaves the board running, a pyserial open at 1200 baud returns a broken pipe
on the DTR ioctl, and `picotool reboot -f` finds no reset interface. Units A
and C take the touch every time with the same build. Manual BOOTSEL (RJ-45
and USB out, button, USB in) then `picotool load -x --bus B --address N`
works first time. Record: `docs/bringup-log.md`, "Two things that bit" under
the desk rig, and the unit B session of 2026-10-07.

- [ ] Decide whether this is the board's USB path or the firmware's CDC
      handling. Board side: compare the four units' USB-C block (`J201`,
      the series resistors, the ESD part) and the `+5V_MCU` rail under USB
      enumeration; a unit that enumerates but drops the control transfer
      that carries the line-coding change points at signal quality. Firmware
      side: `mouse-joystick-firm/.agents/PLANS.md` holds the mirror item
      (the touch is honoured by the Arduino core's CDC, and the two failing
      units took it once from the self-test build).
- [ ] Until then the firmware README documents the button procedure; a
      reflash of Rig 1's left board needs hands at the rig. (From Peter's
      laptop every unit has taken the touch at every attempt: desk
      2026-10-14, Rig 1 2026-10-15 and 2026-10-16, both boards each time.)

## Completed Task — Session handoff and routing timing (2026-09-21)

- [x] Save a tracked [handoff](../docs/routing-session-handoff-2026-09-21.md)
      linking the completed PCB, mechanical report and current order package.
- [x] Preserve original run H timing lines: 21 min 43.702 s through optimization,
      excluding import/refill, local repairs and validation. That historical
      run used 31 configured threads and the older exporter; a fresh corrected
      export at one thread is not benchmarked.
- [x] Correct obsolete startup layout status and mark old routing checklists
      as historical. The complete board is committed in `d5ae4b0`.
- [x] Recheck the shunts: board R1203/R1204 are 0.15 ohm, but reusable block
      R4003/R4004 remain 0.12 ohm. Correct the old checked library item below;
      preserve the correct board shunts on any future block replacement.

The handoff update changes documentation only. No new routing run or board
change is needed to start the next session.

## Completed Task — Connector access and BNC spacing (2026-09-21)

- [x] Preserve the previously routed board and fabrication package under
      `tmp/connector-access/baseline/` and `baseline-fab/`.
- [x] Move angle BNC J1101 left by 10 mm: 24 mm pitch with J901, common Y,
      board-relative centres (42, 55) and (66, 55) mm. A 16 mm plug allowance
      leaves an 8 mm gap; the approximate STEP proxy is not fit evidence.
- [x] Move motor J1102 left by 5 mm and encoder J1103 left by 2 mm. The top
      terminal row stays aligned, with drawn body gaps of about 4.1/2.6 mm.
      All connector origins remain on board-relative whole-mm coordinates.
- [x] Reserve a 7 mm outer-copper hardware area around each M3 mounting hole.
      Hole positions remain on the 90 by 70 mm rectangle. Review USB/RJ45/FFC
      access; document enclosure-specific cable, latch and lid allowances.
- [x] Repair routing, retain 0.8 mm motor tracks, refill and verify: zero DRC
      errors/opens, zero ERC errors/warnings, clearance regression passes.
      The existing warning counts remain 499 clearances and 20 dangling vias.
- [x] Match all 1,204 schematic pad identities; only the three intended
      footprints moved. All values, rotations and library IDs are unchanged.
- [x] Regenerate `fab/routing-rescue-4layer/`, including the fabrication ZIP,
      81 resolved BOM groups, 360 placements, mechanical drawing and coordinates.

See [connector access report](../docs/connector-access-2026-09-21.md).
The current ZIP supersedes the earlier 14 mm BNC package. The initial routing
rescue below retained all placements; this later mechanical correction changes
three. No order has been placed. Actual mating cable/plug and enclosure fit
remain separate from electrical DRC; the FH12 requires its specified FFC.

## Completed Task — Routing rescue (2026-09-21)

- [x] Preserve the original six-layer board under `tmp/routing-rescue/baseline/`.
- [x] Correct DSN plane/window nesting, unfracture filled polygons, constrain
      duplicate-pad bridges to existing copper, and convert both `route`/`fix`
      with `--protect-prerouted`. Five regression tests pass.
- [x] Import the existing run H and refill: its 100 Freerouting residuals were
      five real missing connections. Controlled new runs were stopped after
      this discovery; no completed new exporter benchmark is claimed.
- [x] Repair the five opens, exporter-created BNC shorts, HV clearances and
      QSPI width. Four layers, zero DRC errors and zero unconnected items.
- [x] Verify all 1,204 schematic numbered-pad identities against the PCB and
      preserve all 364 footprint positions, rotations, values and library IDs.
      User permits movement, preferring whole-mm and symmetric connectors;
      movement proved unnecessary. Project rules and netclasses are unchanged.
- [x] Promote the verified candidate to `kicad/mouse-joystick-pcb.kicad_pcb`.
- [x] Complete `make fab` with KiCad 10.0.6: ERC 0 errors/0 warnings, DRC
      0 errors/0 unconnected pads. All 81 BOM groups resolve, 360 placements
      match. ZIP integrity and four-layer order verified. The remaining DRC
      warnings are 499 advisory clearances and 20 dangling vias. Clearance
      regression passes with no voltage-bearing findings.

See [completion report](../docs/routing-rescue-2026-09-21.md). Experiments and
native reports are under `tmp/routing-rescue/`; manufacturing outputs go to
`fab/routing-rescue-4layer/`. The historical routing blockers below are
superseded by these results. Optional circuit/bring-up work is not implied
complete by routing or DRC.

## Completed Board Task — InstrumentPort Tap Resistors (opened 2026-09-19)

**Completed before routing; library shunt follow-up remains below.** Split every InstrumentPort observation branch
off its functional net with a series resistor, so the long runs to `J1501`
become separate, deprioritisable, separately-classed nets. Twenty-four taps
across seven design blocks and the `/mcu/` sheet.

**The full specification — values, nets, owning blocks, as-built source pin
names, part numbers, naming rules and traps — is
[`docs/instrument-port-tap-resistors.md`](../docs/instrument-port-tap-resistors.md).**
That document is written to be executed from a fresh session; this is the
checklist.

Headline decisions, so they are not re-litigated:

- **100 Ω (`OW-PASS-0402WGF1000TCE`) on the fourteen clocked taps, 1 kΩ
  (`OW-PASS-RC0402FR-071KL`) on the ten slow control and status taps.** Never mix
  values inside one bus — a chip select takes its clock's value.
- **The resistors go inside the owning design block**, not on a wrapper sheet.
  The pull-resistor doubling rule does not apply to series elements. The one
  exception is `DAC_SDA`/`DAC_SCL`, shared by two DAC blocks, which go on
  `/mcu/`.
- **Board nets take `_INST`; block pins take `_TAP`.** Active-low names close the
  overbar first — `~{TMC_CS}_INST`, never `~{TMC_CS_INST}`, or the netclass
  pattern misses five nets. `_MON` and `_ISO` are both already taken.
- **Four nets get nothing** — `FW_TRIG0`, `FW_TRIG1`, `PG_5V`, `PG_12V` have the
  port as their only consumer.

**Done 2026-09-20.** All twenty-four taps are placed and netlist-verified; the
`INSTRUMENT` netclass is in place. Routing completed on 2026-09-21, tracked above.

- [ ] Correct `../kicad-libs`'s `tmc5130` shunts to **0.15 Ω** before future
      replacement of this board's driver block. Rechecked 2026-09-21: the library
      R4003/R4004 still read 0.12 Ω; the old checked item was inaccurate.
      Board R1203/R1204 correctly read 0.15 Ω and the current order is unaffected.
- [x] Add the tap resistors and tap pins to the **eight** blocks in
      `../kicad-libs`; add the two I2C taps on `/mcu/`. Eight, not seven: the
      spec's own table lists eight blocks plus the `/mcu/` sheet.
      **Pins were named `_INST`, not `_TAP`** — see
      [As Built](../docs/instrument-port-tap-resistors.md#as-built-2026-09-20).
- [x] Re-place the blocks here by hand; re-check `R1203`/`R1204`.
- [x] Wire the 24 `_INST` nets to the port block's `DIGn` pins. Every tap lands
      on the channel the spec assigns it, verified input-pin to output-pin on all
      four buffers.
- [x] Add the `INSTRUMENT` netclass — 24 explicit assignments plus the `/*_INST`
      pattern, 0.15 mm track and clearance, **`Default`'s via geometry
      unchanged**. Proven live: three findings on `_INST` nets at 0.1978 mm
      stopped being violations, including an overbar name.
- [x] Verify by netlist export, not ERC. Each `_INST` net has exactly two nodes;
      each functional net kept its bias and no longer reaches a buffer.
- [x] Re-check designator citations across the docs. The `J` band was
      reassigned — `interface-map.md`'s connector table is rewritten as built,
      and the pyControl RX pull-up is `R401` in `validation-plan.md`,
      `rev0-plan.md` and `power.md`. `bringup-log.md` is deliberately untouched.

Historical pre-routing findings (see completed routing above for disposition;
remaining one-layer vias are recorded warnings, not opens):

- [ ] Two pairs of exactly stacked vias at (129.175, 84.5) on `GND` and
      (127.425, 84.5) on `+36V_SW` — `holes_co_located`, delete one of each pair.
- [ ] Fifteen one-layer vias inside `rp2040_with_gpio_isolation_sn74cb3q3245`
      (`GPIO2`-`GPIO8`, `10`-`13`, `15`, `18`, `20`, `22`). Redundant stubs, not
      breaks — those nets report no unconnected items.
- [ ] Fifteen voltage-bearing clearance **errors**; see the severity split
      recorded in `kicad/mouse-joystick-pcb.kicad_dru`.

## Historical Task — v1.0 Layout And Routing (opened 2026-09-18)

**Superseded by the completed four-layer routing above on 2026-09-21.**
The following is the prior planning record, not the current board status.

**Autorouting state, 2026-09-20: not routed. Best result 95 of 246 connections
left unrouted, across five runs.** Before attempting another run, read
[`docs/autoroute-log.md`](../docs/autoroute-log.md) — it records what each
configuration produced so runs are not repeated — and the reusable reference
[`../kicad-libs/docs/freerouting-autorouting.md`](../../kicad-libs/docs/freerouting-autorouting.md),
which documents freerouting v2.4.1's settings surface, its verified defaults and
the four that matter for design-block boards.

Do not re-litigate these; all measured:

- **Locking tracks is harmful.** `(type fix)` cost 157 already-connected pins.
- **A track keepout over a GND plane kills fanout** — zero vias placed.
- **Without a keepout the plane gets cut** — 48 non-GND segments on In1.Cu.
- **Enlarging the board and moving blocks did not help** — same ~60% rate, more
  work to do because inter-block copper was destroyed.
- **The router used one layer out of four** (+415 segments on F.Cu, +7 on a
  96%-empty B.Cu). Default via cost 50 against trace cost 1.0–1.8. **Tuning this
  has not been tried and is the largest untried lever.**
- **Never export with `zones=0`.** 51 of 323 GND terminals are exposed-pad
  thermal-via duplicates that only a pour can tie together.

**Gated on the tap-resistor task above as of 2026-09-19.** Splitting 24 nets
changes the ratsnest and orphans copper already routed to the port, so finishing
the route first would be work done twice. Pouring GND and fixing the four
voltage-bearing clearances are independent and can proceed either way.

**The schematic is done and ERC-clean; the board is placed with 2200 tracks in
and 149 connections left.** State, numbers and reasoning are in
`.agents/handoff.local.md`. This is the checklist.

Blocking, in order:

- [ ] **Pour GND.** There are no copper zones at all. 40 of the 149 unrouted
      connections are `GND`; 71 of 149 are power/ground distribution. Decide at
      the same time whether an inner layer becomes a power plane.
- [ ] **Re-run `make clearance-baseline` after pouring.** The current baseline
      was taken with zero zones, so a post-route diff against it would be
      meaningless.
- [ ] **Fix four voltage-bearing clearances** — `+36V_SW`↔`+5V_SW` 0.25 mm,
      `+36V_SW`↔`PG_5V` 0.2919 mm ×2, `+36V_SW`↔`PG_12V` 0.35 mm, and
      `+36V_SW`↔`VCP` 0.353 mm ×2 (that last is ~10 V real differential, low
      priority). All routed copper, all movable.
- [ ] **Delete the duplicate via** — `holes_co_located`, two `+36V_SW` vias at
      the same point.
- [ ] **Hand-route HV entry, motor phases, bootstrap/`VCP`, USB** before the
      autorouter. Freerouting sees netclasses but none of the `.kicad_dru`
      rules.
- [ ] **Autoroute the rest** with `make freeroute`, threads at 1, then
      `make clearance-check` and read the diff.

Not blocking, but cheapest now:

- [ ] Add the two PPTC test points at `R303` — a fitted-versus-jumpered polyfuse
      is otherwise undiagnosable, and pads are free before routing.
- [ ] Decide `J1103` pin 2 / encoder index: `ENCN` stays inside the `tmc5130`
      block and that pin is unconnected.
- [ ] Regenerate `docs/interface-map.md` → `#### mcu Sheet Pins` from the
      schematic instead of maintaining it by hand.

Upstream dependency, unchanged: the `DIG0`/`DIG1` marker pair is still not
frozen in `../board-interfaces`, so hold `FW_TRIG0`/`FW_TRIG1`.

Library dependency: **`../kicad-libs`'s `tmc5130` still ships 0.12 Ω shunts**
against this board's 0.15 Ω. Do not re-place that block until it is fixed
upstream.

## Completed Task — Digital InstrumentPort documentation (2026-09-12)

**Session continuation, 2026-09-13:** Start from the
[InstrumentPort handoff](../../kicad-libs/docs/instrument-port-session-handoff.md).
The subdivision observations are now saved in the canonical draft. DIG0/1 is
the latest beacon-placement recommendation, not a decision; DIG14/15 was the
earlier unfrozen proposal. The v1.0 adoption/fallback gate remains open.

The new design direction is a 50-pin, 32-channel read-only digital port with
integrated SN74LV541ARKSR buffers, enabled by hardware default on
`+3.3V_MCU`. See `docs/digital-instrument-port-migration.md` and the canonical
`board-interfaces/docs/instrument-port-digital.md` draft.

- [x] Document the migration and the v1.0 adoption/fallback release gate.
- [x] Replace the default-disabled recommendation for the new port, retaining
      the old pull-up/OE description as legacy hardware evidence.
- [x] Cross-link the old allocation and validation docs and check consistency.

Verification: `make test` documentation/scaffold checks and `git diff --check`
pass; new local links/anchors resolve. Only Markdown files changed. Board
migration, new overlay allocation, and qualification remain pending.

This reopens the 2026-09-11 decision to keep 40 pins for v1.0; it does not claim
the board is migrated or authorize an indefinite release delay. Prefer the new
port if the reviewed block, adapter design, and board checks fit the order
schedule; otherwise explicitly record a legacy-40 release fallback. Debug,
analog, vertical FFC, and 25-pin implementations do not gate v1.0.
Earlier "leave the InstrumentPort blocks alone" / "no new blocks" scope notes
apply to the legacy fallback, not to an adopted 50-pin migration.

## Active Task — v0.2 JLCPCB Fabrication Release (2026-08-21)

- [x] Confirm the schematic, PCB title block, and front silkscreen identify v0.2.
- [x] Confirm `J1901` uses the corrected
  `orb_weaver_connectors:RJ45_Molex_43860-0001_Horizontal` footprint.
- [x] Generate the managed JLCPCB fabrication package with ERC and DRC enabled.
- [x] Verify the four copper layers, drill outputs, BOM/placement coverage, and
  Gerber-only upload archive.

## v0.3 Bring-Up — What To Test When The Boards Arrive (opened 2026-09-08)

**v0.3 boards are inbound. The repo is already at `(rev "1.0")` as of `2de2847`,
so v0.3 is a measurement vehicle, not a shipping revision.** Everything below is
either a v1.0 decision that hardware can settle, or a measurement that has been
owed since August.

**v0.3 is electrically identical to v0.2 on the 36 V path** — verified by diffing
`kicad/` at `v0.2` against `cab25b3`. Every 36 V problem from v0.2 will
reproduce, and the firmware staircase in `PowerSequence` is still required.

### Stages 1-3 passed on the first v0.3 unit, 2026-09-09 — board 4, `E4654C159F171E34`

Stage 1 on USB alone (24 checks, 0 failed), then stages 2 and 3 with the motor,
encoder, limit switch, 36 V, pyControl RJ-45, LA5032 and the angle BNC all
connected. Rail up in 132 ms, TMC5130A `VERSION` = 0x11, `vsense` reads back 1,
encoder follow ratio **1.0000**, switch witnessed (engages 28.8°, 1.8° throw,
active high), **homing repeatable to 2.0 encoder counts** at 0.200 rev/s
approach / 0.010 rev/s creep. Full results in `docs/bringup-log.md` → *Board 4*.

**Resolved on the way: the `IOIN` disagreement between boards.** Five of those
bits depend on what is plugged in, so the firmware's fixed expected value is
wrong by construction. Empty limit-switch connector reads `REFL_STEP` = 1
(the MAX6816 drives its own pull-up high and v0.3 has no `LIMIT_SW` pull-down);
fitted and at rest it reads 0, because the switch is normally closed. No
assembly defect on any board. Fail-safe in the right direction: a broken switch
cable reads as a permanent limit.

**Still untested, and it is the headline item:** the angle output. There is no
`DAC80501` driver in the firmware at all, so the BNC only shows the DAC's reset
state. Nothing about the analog characterisation below can start until that
driver exists.

Three things from stage 1 that change how the rest of this list is run:

- **Build `env:mouse_joystick_rev1` for a v0.3 board, not `env:mouse_joystick`.**
  v0.3's `U501` pads 13/14/16 route `GP10`/`GP11`/`GP13` to the angle-output DAC,
  so v0.3 *is* `MJ_BOARD_REV=1`. `platformio.ini` calls that env "the rev 1 board
  (pcb HEAD)", which reads as if no fabricated board matches it. **Both
  `platformio.ini` and `src/BoardPins.hpp` in `../mouse-joystick-firm` still say
  rev 0 covers "v0.1 and v0.2" and rev 1 is "HEAD"; neither mentions v0.3.**
  Worth one comment edit before someone flashes the wrong env at a live SPI bus.
- **Designators rotated again, and the self test prints v0.1 names.** The mapping
  for every part stage 1 touches is tabulated in the bring-up log. The one that
  matters most: **the `LATCH` strap is `R1903` on v0.3**, not `R203`.
- **Nothing in the angle-output list below is reachable on USB alone.** The
  `DAC80501` and `OPA197` sit on `+5V_SW`, so the whole headline characterisation
  needs 36 V connected. Stage 1 is the entire USB-only surface.

Still owed on this unit and cheap: a cold power-on reset reason (needs a replug,
so it reads `power-on` rather than `software`), and boot latency, which needs the
LA5032 on `FW_TRIG0`/`FW_TRIG1`.

### The two measurements that gate v1.0 design decisions

- [x] **1. CLOSED 2026-09-10 WITHOUT THE OneBox RECORDING — the ÷2 dividers are
      GO on all three blocks.** The user cannot take an OneBox recording now, so
      the decision was made on data in hand: both channels are limited by
      something other than the converter, and both arguments are
      **radius-independent**. **Angle is encoder-limited by 14.9×** — one
      encoder count (0.0900°) is 2.279 mV post-divider, ≈15 OneBox codes.
      **Torque is sensor-limited by 1.63×** — the RTS-5's 0.05%
      nonrepeatability is 3.3 codes pre-divider and still 1.63 post. So no
      recording can change the answer, and the alternative (a 3.3 V precision
      RRIO buffer) is a new part plus vendor mapping plus lead time against a
      v1.0 the whole scope narrowing exists to get ordered. **The ÷1 fallback
      needs no extra land:** both divider positions are populated 3.2 kΩ, so
      reverting after rig testing is 0 Ω on top and omit the bottom — a BOM value
      change, not a respin, at the cost of the 3.3 V single-fault bound.
      **Researcher input the same day, which confirmed rather than changed it:**
      peak pull force **~20 mN to ~140 mN**, reward threshold a **5 mm** pull,
      lever arm **75-76 mm** rig-measured (old-rig CAD says 72-73 mm). So 5 mm is
      **3.77°-3.82° ≈ 42 encoder counts, 5.9%-6.0% of the 64.174° swing**, and
      the mouse's whole force range sits at **4.3%-30%** of the torque span.
      **CLOSED 2026-09-11 — the peak-pull distribution arrived and the angle
      mapping stays full-swing.** 1,319 successful trials: min 6.23 mm, median
      12.15 mm, p95 14.41, p99 16.12, **max 21.21 mm**, SD 1.50 mm (CV 12%), i.e.
      4.73°-16.10° or **7.4%-25.1% of the 64.174° swing**. Narrowing buys nothing
      because **the encoder is the quantizer, not the OneBox**: one count is
      0.1186 mm of pull and the full-swing mapping already gives the OneBox 14.7
      codes per count, so a 20 mm map's 2.08 extra bits sit below the encoder
      floor. The trial-to-trial SD is **12.6 encoder counts** wide. And the
      researcher's own max (21.21 mm) exceeds the 20 mm they proposed, so a
      narrowed map clips real pull peaks. Full derivation and the arithmetic:
      `docs/encoder-analog-output.md` → *CLOSED 2026-09-11*. **Nothing further is
      owed from outside on this board.** Original status follows.
      ~~HALF-SETTLED 2026-09-10. The span half is closed; the noise half
      needs the OneBox.~~ The gain/offset fit came out **unity to within 0.03%**,
      so **there is no span error to preserve** and the ÷2 divider costs exactly
      the predicted one bit and nothing more. What remains is strictly: is the
      recorded trace already OneBox-quantisation-limited with margin? That is a
      noise measurement at the **19 µV RMS** level, which no scope on this bench
      can see — it needs the OneBox itself or another 16-bit capture. **The op-amp
      purchase decision is still open, and still gated on the researcher question
      below rather than on anything measurable here.** Original text:
      ~~Does the analog output span matter? — decides an op-amp purchase.~~
      v1.0 halves every board-exiting analog output with a ÷2 divider so nothing
      can exceed 3.3 V on a pyControl pin
      (`docs/onebox-analog-interface.md`). That costs exactly one
      bit. **The criterion is whether the recorded trace is already
      OneBox-quantization-limited with margin to spare.** Record a static,
      homed, motor-idle angle trace at full span and look at the width of the
      value histogram. Predicted from the documented figures: board noise 19 µV
      RMS against the `AD7616-P`'s ~44 µV RMS quantization, so the converter
      should dominate by about 2.3×. If it does, halving the span is undetectable
      and the divider wins. If the trace is much wider than a couple of codes,
      span is precious and a 3.3 V RRIO op amp is worth buying.
      - Angle is expected to be **encoder**-limited by a wide margin regardless:
        713 counts over the 64.174° swing is 2.3 mV per count on a 1.650 V span
        against a 152.6 µV OneBox step, so the OneBox already resolves 15× finer
        than the encoder can distinguish.
- [~] **1b — the -0.19% figure is LOAD-DEPENDENT, noted 2026-09-10.** That
      number assumes a **1 MΩ** load, which the OneBox has. A 10 MΩ meter sees
      only **-0.02%**, about 0.34 mV on 1.650 V, which is at the Fluke's
      resolution and lost in drift — so measuring it with a meter alone tests
      the wrong thing. Either load the BNC with 1 MΩ to emulate the OneBox and
      then insert the 1.8 kΩ, or accept it as arithmetic: a -0.2% fixed gain
      error is fully absorbed by per-board calibration, and the Johnson noise of
      1.85 kΩ is ~5.5 nV/√Hz. **Leaning toward the arithmetic.** Original text:
      ~~Validate the divider's source impedance without touching the board.~~
      Put 1.8 kΩ in series in the BNC cable and confirm the DC reading moves only
      by the predicted **−0.19%** and the noise does not change. That is the only
      thing about the final ÷2 topology (1.85 kΩ source versus today's 249 Ω) the
      OneBox can tell apart.
- [~] **1c — NO gross motor coupling, measured 2026-09-10.** Static setpoint at
      1.650 V, scope AC-coupled at 10 mV/div on the BNC: **3.54 mV pk-pk with the
      driver off, 3.55 mV with the chopper running, no increase under jogs or
      under 6 fast approaches, and the same value with the BNC disconnected** —
      so that 3.5 mV is the scope's own floor. Bounds board noise plus coupling
      at roughly **< 200 µV RMS**, about 4x the `AD7616-P`'s quantisation.
      **A scope cannot reach the 19 µV prediction** — its LSB is 312 µV at
      10 mV/div and 31 µV even at 1 mV/div — so measurement 1's noise half needs
      the OneBox and nothing else will do.
      **The chopper frequency was NOT swept**; this is the default operating
      point only. Original text:
      ~~Check nothing else dominates first. Sweep the motor chopper~~
      frequency while recording the angle channel. The `AD7616-P`'s antialias
      filter is first-order at ~39 kHz against fixed 30.3 kHz sampling, so
      out-of-band content folds in nearly unattenuated. **A chopper-correlated
      artifact would be far larger than one bit and makes the span question
      academic until fixed.**
- [x] **2. DONE 2026-09-10 — `+36V_SW` never exceeded 37 V, so NO TVS is needed
      for the motor-driven case.** Single-shot armed at 37 V, 1 V above nominal,
      through 7 hard-stop decelerations at 0.200 rev/s plus 6 reversals at
      `IRUN` 17 = 0.421 A RMS, and two staircase turn-ons. Never triggered. That
      is **12 V of margin** to the TMC5130A's 49 V inductive-load maximum, and
      it also bounds `+36V_SW` ripple under 1 V. Matches the energy prediction
      (200 µF holds 130 mJ against ~2.2 mJ of coil energy, so ~0.4 V worst case).
      Data in `docs/bringup-log.md` -> *MEASUREMENT 2 CLOSED*.
      **Does not cover supply-side events** — the probe was downstream of the
      high-side switch, and hot-plug plus cable-inductance ringing at the input
      is what the TMC5130A datasheet's ringing warning is actually about. The
      entry TVS position and the driver's RC snubber footprint both exist, so
      that remains a populate decision. `SMBJ40A` if ever wanted; stocked
      `SMF48A` covers first boards.

### The rest of the angle-output characterisation

This is the headline reason v0.3 was ordered.

- [ ] **`GAIN` CANNOT BE READ BACK. Rewritten 2026-09-09 — the original text
      asked for something the hardware cannot do.** The `DAC80501` has **no SDO
      pin**: the VSSOP-10 pinout is VDD, VOUT, NC, AGND, SPI2C, SCLK, SYNC,
      SDIN, NC, VREFIO, `SDIN` is typed *Input* in SPI mode, and "SDO" appears
      nowhere in the datasheet. Over SPI the part is strictly **write-only**.
      (The `GP12`/`SDO` note further down this file is the torque bridge's ADC,
      a different chip.) So:
      - `VREFIO` = **2.500 V** is a **DMM measurement at the pin**, not a
        firmware check. Still worth taking.
      - `GAIN` = `0x0101` can only be verified **by measuring the output**:
        write a known code, measure the BNC, compare against the expected full
        scale. That is a DMM task at bring-up, not a register read.
      - The safety point stands and gets sharper. `GAIN` **resets to `0x0001`**
        — REF-DIV 0, BUFF-GAIN 1, which is a **5.0 V full scale** on a 5 V VDD.
        The board needs 2.5 V full scale (×1.32 → 3.3 V at the BNC). Since the
        `Z` variant resets the DAC register to zero scale, the output is safe
        until data is written — so **writing `GAIN` before any DAC data is
        mandatory, and the driver must enforce that ordering itself** rather
        than trust the caller. Note `0x0000` (REF-DIV 0, BUFF-GAIN 0) also gives
        2.5 V full scale with less gain-up noise; `0x0101` is what this plan
        specified and there may be a v1.0 3.3 V headroom reason for it.
- [x] **DECIDED 2026-09-10: v1.0 straps the DAC to I2C.** Firmware is ready —
      `env:mouse_joystick_rev1_i2c` in `../mouse-joystick-firm` builds the I2C
      path today, and both examples select the transport with `-DMJ_DAC_I2C=1`.
      **It cannot be tested on any board that exists**: on v0.3 `SPI2C` (`U2001`
      pad 5) is tied **directly to GND in copper**, no strap resistor, so v0.3 is
      SPI-only without cutting a trace.
      Three reasons, and the bandwidth objection is now measured away:
      - **`STATUS.REF-ALARM` is unreadable over SPI.** A reference alarm drives
        the output to 0 V while leaving the DAC codes intact, so it is
        indistinguishable from a legitimate zero. `docs/encoder-analog-output.md`
        requires `STATUS` to report the output invalid in that case, and SPI
        cannot.
      - **The 4.5 mV floor measured 2026-09-10 makes the analog level a weak
        backup.** It was supposed to be ~25 mV. The gap between a firmware fault
        and a dead output section is now 4.5 mV, halving to 2.25 mV at v1.0.
      - **Bandwidth does not bind.** I2C at 1 MHz adds ~33 µs to a **measured**
        527 µs worst-case angle loop — about 6%. See the 1 kHz loop result in
        `docs/bringup-log.md`.
      **Two DACs, ONE bus, no second peripheral needed.** `A0` selects four
      addresses by what it is tied to: **AGND 0x48, VDD 0x49, SDA 0x4A,
      SCL 0x4B**. The angle output takes 0x48 and the brake takes 0x49, leaving
      two spare. It also saves **2 GPIOs** — I2C needs SDA + SCL where SPI needs
      SCLK + SDIN + *two* separate chip selects — which matters on a revision
      also adding the torque bridge's `SDO`, `TQ_CONVST_CS`, `TQ_CAL_EN` and
      `~{BRAKE_FAULT}`.
- [~] **DESIGN BLOCK SPEC for the I2C strap — BRAKE BLOCK DONE 2026-09-10,
      analog block still owed.** `brake_current_sink_0_49ma_dac80501`'s schematic
      is complete and netlist-verified: `SPI2C` and `A0` each strapped with a
      1 kΩ to `+3.3V_FILT` (I2C mode, **address 0x49**), the `~{CS}` port
      deleted, `SCL`/`SDA` exposed with **no termination**, and `SDA`'s port
      shape changed to `bidirectional`. **The three 10 kΩ SPI-idle resistors were
      deleted** — that was missing from the original spec and is the part that
      would have broken the bus. **No DNP parts**, by the user's preference.
      Full as-built detail in `../kicad-libs/docs/brake-current-sink-design.md`
      → *Strapped To I2C*. `analog_output_0_3v3_dac80501` is unchanged so far and
      takes **0x48**, matching the firmware's existing
      `kI2cAddrA0Agnd` selection. Original spec follows.
      Both `analog_output_0_3v3_dac80501` and
      `brake_current_sink_0_49ma_dac80501` need it, and those two are the
      complete set — no other block contains a DAC80501.
      **MODIFY IN PLACE. Do not fork SPI and I2C variants.** Decided 2026-09-10.
      Neither block has an installed base to protect: the analog one is already
      on the re-place list above for the DAC-to-3.3 V change, and the brake one
      has never been placed. v0.3's SPI configuration is preserved in git at the
      `v0.3` tag and in the fabricated boards, so a live SPI block is not needed
      to reproduce it. Forking would double maintenance across ~57 and ~24
      components over a four-pin difference, name the blocks on the wrong axis
      (this repo names by function + range + part, not interface), and invite
      placing the wrong variant. A dual-mode block was considered and rejected:
      pin 7's net changes from a hierarchical port to a static tie, which cannot
      cleanly be a populate option, and keeping the port either way makes the
      block ambiguous about what it is.
      **BUNDLE the I2C change with the already-planned DAC-to-3.3 V change on
      the analog block, so it is re-placed ONCE.** Two re-placements means two
      rounds of designator churn and two LCSC/Vendor-SKU scrubs — `rp2040` took
      50 field issues from a two-part change.
      **The brake block's DAC is already on `+3.3V_FILT`** (checked at `U36001`
      pad 1), so it needs only the transport change, no rail move, and its bus
      is level-compatible with the RP2040 immediately.
      Five changes, both blocks:
      1. **`SPI2C` (pin 5): GND -> the local VDD rail.** Currently a hard copper
         tie to GND.
      2. **`SYNC/A0` (pin 7) stops being a chip select and becomes a static
         address strap.** Drop the `~{DAC_CS}` hierarchical port. **Expose the
         address as a selectable strap inside the block** — two 0402 positions,
         `A0`->AGND and `A0`->VDD, populate exactly one — so the same block can
         be placed twice at different addresses. Do NOT hard-wire one address.
      3. **`SCLK`/`SDIN` (pins 6, 8) become `SCL`/`SDA`**; rename the block's
         hierarchical ports to match.
      4. **PULL-UPS MUST BE BOARD-LEVEL, NOT IN THE BLOCK.** Two instances each
         carrying pull-ups would put them in parallel and halve the resistance.
         Same class of trap as two `PWR_FLAG`s on one net. The block exposes
         `SCL`/`SDA` with no pull-ups; the board fits one pair.
      5. **Pull-ups reference the ALWAYS-ON 3.3 V rail, on the MCU side of the
         bus switch** — not the switched side, or they are dead whenever the
         rail is off. Convenient that v1.0 already moves the DAC to 3.3 V, which
         makes the bus level-compatible with the RP2040 with no translation.
      **Open question worth thinking about:** open-drain I2C through the
      `SN74CB3Q3245` bus switch. The CB3Q is a bidirectional FET switch and
      passes I2C fine, but the pull-up placement above is what makes the
      switch-open state sane. Verify on v1.0 hardware rather than assuming.
      This is new, it is a hardware change, and it is small. `docs/encoder-analog-output.md`
      states that **"`STATUS` must report the output as invalid"** when the
      output is 0 V for either of two reasons — an unpowered output section, or
      a **reference alarm** from a misconfigured `REF-DIV`. Both look exactly
      like a legitimate end of travel in a researcher's recorded dataset.
      **Over SPI, firmware cannot detect the reference alarm at all**, so that
      stated requirement is unimplementable as built. The unpowered case is
      inferable from `SW_RAIL_SENSE_DIV_2`; the alarm is not.
      The `DACx0501` **does** support register readback — including `DEVID`,
      `GAIN` and `STATUS.REF-ALARM` — but **only in I2C mode**, selected by the
      `SPI2C` strap pin at power-up. The cost is bandwidth, and it does not
      bind: this design's update rate is already capped near **1 kHz** by the
      987 Hz filter's 266 µs group delay and the encoder-read loop, while I2C
      fast mode puts a 24-bit frame at roughly 30 µs. So I2C buys the alarm
      visibility the design doc asks for and costs nothing that matters.
      Change is a strap plus two pull-ups plus a different peripheral.
- [x] **DONE 2026-09-10 on board 4, and the fit is essentially unity.** Fluke 87
      on DC volts at the BNC, four codes: 0 -> **4.5 mV**, 993 -> **50.2 mV**,
      32768 -> **1.650 V**, 65535 -> **3.300 V**. One model fits all four —
      **unity gain to within 0.03%, +0.2 mV offset, hard clamp at 4.5 mV** — and
      every residual is inside the meter's resolution. Span is 1.650 V against
      1.650 expected, so **there is no per-board gain to calibrate out**. The
      warning that the fit "must be redone rather than rescaled" at v1.0 still
      holds but costs almost nothing, because the only per-board number is the
      clamp. Data in `docs/bringup-log.md` -> *ANGLE OUTPUT CHARACTERISED*.
      **This also half-settles measurement 1 below:** there is no span error to
      preserve, so the ÷2 divider costs exactly the predicted one bit and
      nothing more. The remaining half is a noise question and needs a
      recording, not a meter.
- [x] **The output floor is 4.5 mV, NOT ~25 mV — and that breaks the
      three-level out-of-band scheme.** Measured 2026-09-10. The valid-range gap
      improves (45.5 mV instead of 25), but the gap between a **firmware fault**
      and a **dead output section** collapses from 25 mV to **4.5 mV**, halving
      again to 2.25 mV at v1.0. Both hardware failures read as a legitimate end
      of travel, and the doc's mitigation is `STATUS` reporting the output
      invalid — which over SPI cannot see a reference alarm. **So this
      strengthens the I2C strap case below.**
      - [ ] **Decide: drive code 497 = 25 mV as the fault level instead of code
            0.** Firmware-only, free, restores the 25 mV separations
            deliberately, and survives the v1.0 halving at 12.5 mV (82 OneBox
            codes). Not applied — it changes what recorded data means.
      - [ ] **Correct `docs/encoder-analog-output.md`**, which asserts a ~25 mV
            floor and builds the out-of-band scheme on it. The 25 mV figure is
            measured wrong by 5.6x.
- [~] **Partly answered 2026-09-10 without a dedicated capture.** The live
      1 kHz loop showed the filter needs **~2 ms to settle a step** while
      updates arrive every 1 ms, which is why the staircase is visible at all —
      so the settling figure is corroborated even though the 266 µs group delay
      itself was not timed against a trigger reference. A proper measurement
      still wants `FW_TRIG1` on a second scope channel, and the InstrumentPort
      FFC is occupied by the LA5032. Original text:
      ~~Verify the **266 µs filter group delay** of the 2-pole 987 Hz Sallen-Key.
      Any latency measured through `AIN0` includes it and it is not firmware
      latency.
- [x] **DONE 2026-09-10 — `ANGLE_OUT_MON` reads 1.650 V, the same as the BNC.**
      Fluke 87 on `J1501` pin 32 against pin 31/33 GND, with the output parked at
      midscale. Topology traced in copper too: `R2008` 1 kΩ taps `AMP_VOUT`, the
      **op-amp side** of the 249 Ω `R2007`, so the monitor reads the true output
      regardless of what loads the BNC — which would have caught the 50 Ω
      termination error immediately. Original text:
      ~~Confirm `ANGLE_OUT_MON` on `J1501` pin 32 tracks `ANGLE_OUT`. At v1.0 the
      monitor tap moves to the divider midpoint and the two read the *same*
      voltage, which removes a scale factor from the capture.

### Carried-forward measurements this board can finally take

- [ ] **`~{HV_FAULT}` and `HV_SNS` need `GP14` raised first.** Firmware must
      assert `HV_DIAG_EN` before either reads anything at all. Without it
      neither works, and that has bitten before.
- [ ] **`+3.3V_MCU` back-power check.** Measure it with 36 V applied and **both**
      USB and pyControl unplugged. The `SN74LVC125A` has no `Ioff` and TI does not
      specify its leakage at `VCC` = 0, so this is unspecified rather than
      guaranteed.
- [x] **Encoder filter value — closed on paper 2026-09-08, no scope needed.**
      The fitted part is an **E4T-1000**: 1000 CPR, so `f_ch = 1000 × RPM/60`, and
      the 470 pF `C802`/`C803` corner of 44.9 kHz is reached only at **2694 RPM at
      the motor shaft**. Bring-up ran `VMAX` = 0.100 rev/s = **6 RPM** (100 Hz),
      so the margin is ~450× and even a ten-fold faster axis stays clear. The
      encoder's own ceiling binds first anyway — max A/B frequency **100 kHz**,
      and module max RPM = 6×10⁶/CPR = **6000 RPM** at 1000 CPR. **470 pF is
      correct; do not re-derive.** Scoping `ENC_A_FILT` is now optional
      confirmation, not a gate.
- [x] **DONE 2026-09-09 — `IRUN` 17 wins, on case temperature alone.** Taken on
      board `E4654C159F4D1334` with a thermal camera, 66 min of continuous
      energisation at `IRUN` 17 driven by repeated `g` cycles: motor can plateaus
      at **43.3 °C** in a ~25 °C room (+18 °C rise), TMC5130A at **45.5 °C**,
      `ot`/`otpw` clear on every poll, no follow failures in ~1300 cycles.
      `IRUN` 24 scales the rise by (0.600/0.421)² = 2.03 to **~62 °C in the same
      room**, over the 60 °C case maximum, so it is rejected without a rebuild.
      Electrical duty was ~100%, not the 72% of motion time: `cs_actual` polled 15
      with `stst` = 1, because firmware never writes `TPOWERDOWN`. Real use is
      **low duty** (command, depower, wait, rehome), so this bounds rather than
      represents — the exception being a hold-against-force mode, still open with
      the researcher. **Coil current was not measured** (no clamp on the bench);
      the thermal half is decisive on its own. Data, method and three caveats in
      `docs/bringup-log.md` → *Thermal Survey*. Original text below.
      ~~**Coil current and motor case temperature — settles IRUN 17 versus 24-25,
      and does NOT need v0.3.**~~ The motor and driver path are unchanged from v0.2
      and two v0.2 boards are in hand, so this can be taken today. Measure coil
      current at IRUN 17 and read case temperature after a representative duty
      cycle. Copper loss is **2.31 W** at 0.421 A and **4.68 W** at 0.600 A (both
      phases, 6.5 Ω/phase) in an **82 g** NEMA 8 whose datasheet case maximum is
      **60 °C (140 °F)** against a 50 °C ambient maximum — so this is a real
      constraint, not a formality. **That 60 °C figure is inconsistent with the
      Class B (130 °C) winding insulation quoted on the same datasheet page**;
      worth a question to Lin Engineering as well as a thermocouple. This
      measurement is also what decides whether the shunt can move to
      a larger shunt at a later revision — see the *Required* item for which one,
      and note it is **not** the 0.33 Ω an earlier draft named.
- [x] **LATCH baseline — DONE 2026-09-09 on board 4, FAIL as expected.** Cold,
      the rail holds only 52-73 ms of 250 ms and `~{HV_FAULT}` latches low.
      `R1903` is fitted, so v0.3 behaves exactly like v0.2 and **the firmware
      staircase stays required**. Stage 2 also passed in full on that board the
      same day: rail up in 132 ms, bus closed, TMC5130A `VERSION` = 0x11.
      **Caution — the probe could report a false PASS**, and did once: run while
      `+36V_SW`'s 208 µF was still charged it presents the switch with no inrush.
      `+36V_SW` needs **691 ms** to bleed. Fixed in firmware; details in
      `docs/bringup-log.md` → *LATCH baseline*.
- [ ] **Travel: set both hard stops deliberately and record them, rather than
      measuring whichever position they were left in.** Reframed 2026-09-09: the
      stops on both joysticks are **movable**, both mechanisms have roughly
      **60°** of range, and the gearing is **1:1 on both**, so joystick degrees
      and motor degrees are the same number. The 28° figure carried through this
      repo and through firmware's `kMeasuredTravelMicrosteps` = 4000 is a stop
      setting, not a mechanism property — see `docs/bringup-log.md` → *The 28 deg
      travel figure is a hard-stop setting, not a mechanism property*. The left's
      64.174° full swing is consistent with ~60°.
- [x] **Hand-check both mechanisms — done 2026-09-09, neither is jammed.** Both
      joysticks were reconnected and sit mid-travel; ~1300 motion cycles ran on
      the right with no follow failures.
- [ ] **Hand-check the left mechanism's swing before commanding any motion** —
      it may have been left jammed on 2026-09-03. See `docs/bringup-log.md`,
      "OPEN: the mechanism may have been left jammed".
- [ ] **Record which measurements were impractical for lack of a test point.**
      There are none anywhere on the board, and the 36 V diagnosis had to be done
      by energy accounting because reading `+36V_SW` means clipping onto
      `C1213`'s can pads. **That list is the v1.0 test-point requirement.**

### The question hardware cannot answer

- [ ] **Ask the researcher which box is the primary analog record.** The OneBox is
      16-bit over ±5 V, 152.6 µV per code, so a 1.650 V span is 13.4 bits and the
      ÷2 divider is free. pyControl's own ADC is 12-bit on a 3.3 V reference,
      806 µV per code, so the same span is **11 bits** and the divider hurts. This
      is the single input that decides whether to buy a 3.3 V RRIO op amp, and no
      measurement on v0.3 substitutes for it.

## v1.0 Board Changes (opened 2026-09-08, supersedes the v0.4 list below)

**Status 2026-09-16: under way. The ordered task list is now
`.agents/handoff.local.md` → *Finish the schematic* and *Still to place*, which
is current; this section is the scope definition behind it.** Blocks are no
longer a prerequisite — all of them pass in `../kicad-libs` and two are placed.
What changed since this section was written:

- `rp2040` + `rp2040_gpio_isolation_sn74cb3q3245` are replaced by the single
  `rp2040_with_gpio_isolation_sn74cb3q3245`, built 2026-09-16, **placed**.
- The 40-pin DUT boundary and all four `SN74LVC125A` buffers are replaced by
  `instrument_port_digital_50_dut_ffc_boundary_vertical` — **32 channels**, not
  18, allocated in `docs/interface-map.md`. `GP24` was freed and immediately
  re-spent on `HV_LATCH`, which the bench had owed a pin since 2026-09-02.
- Both DAC blocks are **I2C** (0x48 analog, 0x49 brake), not SPI, which freed
  `GP13` and moved the torque ADC onto `SPI1`.
- `hv_to_12v_tpsm365r6` joins the placement list — new to this board, and both
  the brake and torque blocks need `+12V`.
- The PPTC is chosen: `1206L035/16YR`, LCSC `C126817`, **to be purchased**.
- Nine new board-level biases are owed, listed in `docs/interface-map.md` →
  *Board-Level Input Biases*. The I2C pull-ups are **4.7 kΩ**, not 2.2 kΩ.

Re-placing `tmc5130` still damages a clean board: `../kicad-libs` is 0.12 Ω
against this board's 0.15 Ω, re-verified 2026-09-16.

## SCOPE NARROWED 2026-09-08 — v1.0 only, no nice-to-haves

**Decided by the user: only changes that directly affect v1.0. Everything else
waits until v1.0 has been tested.** The goal is to order v1.0 as soon as v0.3
testing allows. The lists below are kept for their reasoning; **treat anything
not named here as deferred.**

**Zero regression traps remain on this board.** By not re-placing `tmc5130` and
not re-placing `rp2040_gpio_isolation_sn74cb3q3245`, two of the three evaporate
without any work — the shunt can never revert, and the isolation block's 6
unconnected-copper errors never reach the board. The third (the torque block's
missing `.kicad_pcb`) is library work, listed in `../kicad-libs`'s plan.

**CORRECTED 2026-09-10 — the list below was wrong about two blocks.** Commit
`aa68b17` ("Remove some design blocks for modifications", 2026-09-08) removed
**three** sheets from this board, not one: the 36 V input block, **`rp2040`**,
and **`quadrature_encoder_input_5v_sn74lvc2g17`**. So `rp2040` is *not* "leave
alone entirely" — it is out of the schematic and must be re-placed, and it has
since been edited in `../kicad-libs` (the `RUN` switch, done and clean). Same for
the encoder block, which needs no design change but does need re-placing after
the library scrub. **The board schematic on disk therefore has no MCU and 126
components; that is deliberate teardown, not damage.**

**Blocks to re-place:** `hv_input_36V_terminal_2pos_5p08_protected_vertical`
(this *is* the `LATCH` fix — the block already exposes the port, no edit),
`analog_output_0_3v3_dac80501` (DAC to 3.3 V **+ I2C strap + ÷2 divider**),
**`rp2040`** (`RUN` switch), and **`quadrature_encoder_input_5v_sn74lvc2g17`**
(no design change; re-place after the library scrub).
**Blocks to place new:** `torque_bridge_0_3v3_ina821`,
`brake_current_sink_0_49ma_dac80501`, `hv_to_12v_tpsm365r6`.
**Blocks to leave alone entirely:** `tmc5130`,
`rp2040_gpio_isolation_sn74cb3q3245`, `usb2`, both `5v_to_3v3_tps73733`,
`hv_to_5v_tpsm365r6`, `limit_switch_debounced_input`,
`pycontrol_behavior_port_rj45_boundary`,
`instrumentation_signal_buffer_sn74lvc125a`, the InstrumentPort boundary.

**Verified 2026-09-08 and it removes a dependency:** the isolation block already
exposes **all 30 channels** as `GPIO0`-`GPIO29` / `ISO0`-`ISO29` port pairs, so
`~{BRAKE_FAULT}` routes through a spare channel with **board-level wiring only** —
no block edit, no re-place.

### Cut from v1.0 — revisit after v1.0 is tested

- **The debug connector and SWD pads.** No probe on hand; buys nothing today.
- **Dropping `U603`/`U604`** — area/cost optimisation, not a defect.
- **The 1206 PPTC for `R303`** — the fitted jumper works; sizing unresolved.
- **`PYC_FAULT` / `EXT_FAULT_IN` / `~{RIG_FAULT}`** — already deferred below.

### Kept despite the narrowing, and why

- **Test points.** They are **pads: no BOM lines, no parts, no cost**, and they
  are what makes v1.0 testable — the whole point of ordering it. v0.2's 36 V
  diagnosis had to be done by energy accounting because reading `+36V_SW` means
  clipping onto `C1213`'s can pads. Decide schematic-symbol versus layout-only
  before layout, as below.
- **`~{BRAKE_FAULT}`** — the one genuine judgement call, ~2 parts
  (`SN74LVC2G17`, 990 in stock, plus a 100 nF). **It is not a feature for the
  experiment, it is instrumentation for the v1.0 test:** without it a brake
  current-ceiling event is completely invisible to both the MCU and the capture,
  so if the limiter fires during v1.0 bring-up you would never know. Cutting it
  is defensible; cutting it means accepting that blind spot on first hardware.

**Two regression traps, not three — updated 2026-09-08.** The `tmc5130` shunt is
no longer a library fix: the block now ships **0.12 Ω deliberately, as a
placeholder**, and **sizing `R4003`/`R4004` is this board's responsibility after
placement**. See *Required* below. Also verified that day: v1.0 needs **no new
design blocks** — all 36 exist, including `hv_to_12v_tpsm365r6`.

### Required

- [ ] **Size `R1203`/`R1204` after placing `tmc5130` — the block default is
      wrong on purpose.** (They are `R4003`/`R4004` inside the library block.)
      **VALUE CLOSED 2026-09-09: 0.15 Ω with `vsense` = 1, and the 0.22 Ω 2512
      branch below is dead.** Taking 0.22 Ω needed `IRUN` settled at 17 **and** a
      reduction above ~1.7:1. `IRUN` 17 is settled (see the thermal result in the
      v0.3 section above), but **the gearing is 1:1 on both joysticks**, so the
      sweep would need motor overcurrent the thermal result rules out. No 2512
      land change in the block or this board. The action that remains is only the
      swap from the block's 0.12 Ω placeholder at placement time — which is
      exactly the silent failure this item exists to prevent.
      Decided 2026-09-08. The library ships **0.12 Ω**
      (`OW-PASS-KRL1632E-M-R120-F-T5`) as a placeholder because the correct value
      is a property of the motor. **This board fits 0.15 Ω
      (`OW-PASS-RLH12FTCR150`) with `vsense` = 1**, which is what both v0.2 units
      already carry and read back. Forgetting the swap is silent — no ERC, no DRC,
      no fault bit — and with firmware writing IRUN 17 a 0.12 Ω fit puts
      **0.511 A RMS, +21.4%** into the coils. Record the shunt value, the
      `vsense` bit and `IRUN` **in one place**; they are one decision.
      Why 0.15 Ω, against the whole stocked field (derivation in the `kicad-libs`
      plan → **`tmc5130` shunt policy**): it is the only value/`vsense` pair that
      keeps *both* candidate operating points inside the CS range — **0.421 A on
      CS 17** and **0.600 A on CS 24**, step 23.4 mA — and the choice between
      those two is still open. 0.22 Ω/`vsense` = 1 cannot reach 0.600 A at all;
      0.33 Ω/`vsense` = 1 cannot reach either. It is also Trinamic's own worked
      example for the low-current branch ("0R15: 1.1 A peak").
      **If you ever move off 0.15 Ω, the destination is 0.22 Ω 2512
      (`JER2512F3R220`, 500 in stock, 3 W, ±50 ppm) with `vsense` = 0** — and it
      is a mixed trade, not an upgrade. Gains: 131 mV of sense signal against
      89 mV (+47%), tempco ±50 ppm/°C against the 0.15 Ω's ±100 ppm, and 1.60×
      headroom, the most of any stocked option. Costs: step coarsens 23.4 →
      29.9 mA, the operating point drops from CS 17 to CS 13, and it is a **2512
      land change** in both the block and this board, where `BRA`/`BRB` are routed
      tight per the TMC pin table. Take it only if the thermal result settles
      IRUN at 17 **and** the gear count comes back above ~1.7:1 so the
      calibration sweep needs no motor overcurrent.
      **Corrected 2026-09-08: an earlier draft named 0.33 Ω here. It is at zero
      stock** (`OW-PASS-73WL4R330F`, `C2121350` — catalogued and orderable,
      `stock_total = 0`) and on re-derivation it is worse than the 0.22 Ω anyway
      on tempco (±200 ppm), power rating (750 mW) and headroom (1.09×). Do not
      queue it as a purchase. `0.36 Ω` 1206 is stocked but is a ±600 ppm/°C
      250 mW thick-film chip resistor whose rating is exceeded at full scale —
      it is the polyfuse-position part, not a shunt. Note `V_SRTL`/`V_SRTH` are **typ-only in rev 1.21**,
      so absolute current accuracy is unspecified whatever is fitted; this is a
      resolution-and-ceiling choice, not an accuracy one.
- [x] **Corrected 2026-09-08 — `docs/rev0-plan.md` is now clean.** Seven edits,
      more than the five `IRUN` sites, because the root cause was upstream of
      them: **the doc's stated "0.67 A per phase" motor rating was an assumption,
      and *Open Decisions* item 1 explicitly ruled out the `WO-208-13-01D` that
      turned out to be fitted.** Every derived figure was re-computed rather than
      rescaled — `IRUN` 28 → 17, peak sense voltage 163 → 101 mV (89 mV across the
      0.15 Ω itself), peak dissipation 135 → 53 mW, the `vsense` = 0 hazard
      1.23 A → 0.760 A, and the self-limiting claim "12% above the motor rating" →
      **25%**. Two findings recorded while fixing it: **0.760 A exceeds the
      `vsense` = 1 ceiling of 0.749 A**, so the wrong bit defeats the hardware
      limit outright; and the old "fix the library down to 0.15 Ω" instruction was
      reversed in place to "never re-place `tmc5130`". Original text below kept for
      the record.
      ~~**Correct the stale `IRUN = 28` — this is the more dangerous half of the
      shunt problem, and it is in the docs, not the hardware.**~~
      **Scope corrected 2026-09-08: only this repo's `docs/rev0-plan.md` is
      stale.** `../mouse-joystick-firm`'s AGENTS.md was already fixed on
      2026-09-02 — it now reads "`IRUN <= 17` (0.421 A RMS) until someone measures
      a coil current", names the WO-208-13-01D, and records that bring-up runs at
      `IRUN = 8`. Firmware is correct and already enforces the conservative
      reading. `docs/rev0-plan.md` still carries `IRUN = 28` in five places
      (lines ~249, 251, 276, 525, 605), which on 0.15 Ω is **0.679 A RMS —
      1.61× the conservative reading of the motor's 0.6 A/phase and 1.13× even
      the equal-heating reading**. Fix those five, noting 24-25 as the
      alternative pending the thermal measurement.
- [ ] **`LATCH` to a GPIO — the blocking defect.** `R1903` 1 kΩ still straps the
      `TPS1HTC100-Q1`'s `LATCH` to `+3.3V_MCU`, selecting latch-off, which
      prevents the 36 V rail from ever coming up. **The library block already
      exposes `LATCH` as a port**, so this is a re-place plus one wire to a spare
      GPIO. Full reasoning and the rejected alternatives are in the v0.4 section
      below, which stays for that reasoning.
- [ ] Re-placing that block also brings three fixes worth knowing about: `SNS`
      gains a 1 kΩ + 10 nF filter behind the 249 Ω `R_SNS` (**today the raw
      node goes straight into `GP28` unfiltered**), `~{FAULT}` gains a 10 kΩ
      RPROT, and the `DIAG_EN` RPROT goes 1 kΩ → 10 kΩ.
- [ ] **Move `~{HV_FAULT}` off `GP29`.** It is an open-drain *digital* input
      sitting on **ADC3**, and ADC pins are the board's scarce resource: `GP26` is
      rail sense, `GP28` is `HV_SNS`, and `GP27`/ADC1 is the only free one.
      Moving `~{HV_FAULT}` to a spare digital pin frees ADC3 for `BRAKE_ISENSE`
      and leaves `GP27` available. Costs nothing.
- [ ] **Add `hv_to_12v_tpsm365r6` on the switched domain.** Needed by the torque
      block, and now also by the brake's loop amplifier. Place its switching loop
      **physically remote from the torque bridge front end** — it exists to feed
      that block, which makes adjacency tempting.
- [ ] **Place `torque_bridge_0_3v3_ina821`.** Board-side obligations: the sensor
      BNC and the `TQ_AOUT` BNC are **not** in the block, and **the ESD clamp's
      ground via must land on the BNC's ground pin** or its clamping is dominated
      by connection inductance. Three GPIOs: `GP12` (`SPI1 RX`) for `SDO`, one for
      `TQ_CONVST_CS`, one for `TQ_CAL_EN` — the last is not optional in the sense
      that matters, since the in-block pull-down makes an unconnected port safe
      but leaves the shunt-cal circuit inert.
- [ ] **Place `brake_current_sink_0_49ma_dac80501`.** The coil terminal is
      in-block. `BRAKE_ISENSE` goes to the freed ADC and to `AIN1_P`. Give the
      pass device as close to **6 cm²** of drain copper as the zone allows, on
      the side **away** from the torque zone.
- [ ] **Wire `~{BRAKE_FAULT}` back to the RP2040.** Decided 2026-09-08, and the
      point is to **buy information**: monitor the brake's current-ceiling output
      on real hardware and let that decide whether the deferred inter-board
      `~{RIG_FAULT}` line is worth building. Without it there is no evidence
      either way. The brake block gains the `SN74LVC2G17` buffer and the port
      (see the `kicad-libs` plan); the board owes three things:
      - **One GPIO**, routed **through the isolation bus switch** (`sw`), because
        the far end is powered from the switched domain — that is the rule, not a
        convenience. It arrives already at 3.3 V logic, so it needs a route but
        **not** an `SN74LVC125A` channel.
      - **An MCU-side termination.** The buffer has `Ioff`, so with `+3.3V_FILT`
        down its output is high-Z and the isolated MCU-side pin floats. A **10 kΩ
        pull-down to GND** is the right choice: per the domain rule, a pull that
        may read LOW goes straight to GND rather than to `+3.3V_SW`. The
        consequence is that the line reads **asserted whenever the switched rail
        is off**, which is the fail-safe direction — but firmware must therefore
        only interpret it while `SW_RAIL_SENSE` says the rail is up. Record it
        with the other nine board-level terminations.
      - **`DIG12` on the InstrumentPort**, already allocated to `~{BRAKE_FAULT}`
        in `docs/interface-map.md`, so the capture sees the same edge the MCU
        does.
      Record the GPIO in `docs/interface-map.md`. **Budget still fits:** eight
      digital spares after `GP12` goes to the torque `SDO`, against six consumers
      — `HV_LATCH`, `TQ_CONVST_CS`, `TQ_CAL_EN`, `BRAKE_CS`, the relocated
      `~{HV_FAULT}`, and `~{BRAKE_FAULT}` — leaving two spares plus `GP27`/ADC1.
- [ ] **INVERTED 2026-09-10 by the I2C change — this now says the opposite.**
      The DAC blocks' three 10 kΩ SPI-idle resistors are **deleted**, so the
      board owns every bus termination. **Fit two 2.2 kΩ pull-up pairs, one per
      bus segment:** the DAC-side pair referenced to the **switched** 3.3 V rail,
      the MCU-side pair to **`+3.3V_MCU`**. Not one always-on pair — an
      always-on pull-up reaching a DAC whose `VDD` is at 0 V exceeds the
      `DAC80501`'s `VDD + 0.3 V` digital-input absolute maximum and back-feeds
      the block's `+3.3V_FILT` through the internal clamps. And the switch is
      **open by default** (`~{BUS_SW_EN}` = `GP9`, held isolated by `R601`
      7.87 kΩ), so a single MCU-side pair would leave the peripheral segment
      floating into two live DACs and three powered `SN74LVC125A` monitor
      inputs. Closed bus is then 1.1 kΩ, right for the 1 MHz FM+ the loop budget
      assumes; the DAC sinks 3 mA in FM+ so 1.5 mA/line is fine.
      ~~Do not add board-level pull-downs on `SCK` or `SDI`. Both DAC blocks
      already own one each, so a board carrying both already has 5 kΩ.~~
- [ ] **Move the InstrumentPort DAC-bus monitor taps to the B (MCU) side of
      `U602`.** Today `U2101`'s three `SN74LVC125A` monitor inputs sit on the
      A (peripheral) side — `U2101.2` on `~{DAC_CS}`, `.5` on `DAC_SPI_SCK`,
      `.9` on `DAC_SPI_COPI` — where the blocks' own 10 kΩ pulls used to hold
      them defined. With those gone and the bus switch open by default, powered
      LVC125 inputs would float. The B side is held by the always-on pull-up
      pair, and it is the waveform you actually want to decode.
- [ ] **Going to I2C frees one `U2101` channel** (3 of 4 used → 2 of 4) and two
      GPIOs. Record the two I2C pins and the freed channel in
      `docs/interface-map.md`, and drop the `~{DAC_CS_BUF}` row.
- [ ] **Add the `RUN` reset switch — restored to Required 2026-09-08, with
      evidence.** Lands via the `rp2040` block change. **Do it independently of
      the debug connector**, which stays cut.
      **The failure it fixes has already happened once**, 2026-09-03:
      `docs/bringup-log.md` → "`STATUS` hung the core". The board stopped
      answering the link **and** stopped honouring the 1200 baud reset touch, so
      it could not be reflashed. Recovery needed `SW501` held through a power
      cycle with **both USB and the RJ-45 unplugged** — pulling USB alone leaves
      the board alive on pyControl's 5 V through the ORing diodes. With a `RUN`
      switch that becomes: hold BOOTSEL, tap `RUN`, reflash. No cables touched,
      and no disturbing a rig where two interchangeable boards sit on ports 1
      and 4 and calibration belongs to a board serial.
      **Why once is enough to justify it:** the recovery cost is structural, not
      a bug — it follows from the ORing diodes and the deliberately unswitchable
      MCU domain, so every future hang costs the same four steps. v1.0 also
      roughly doubles the surface for that exact bug class: the `STATUS` hang was
      *reaching for SPI before the bus was up*, and v1.0 adds the `ADS8689` to
      shared `SPI1` with an ordering constraint (first write after power-up must
      use `SPI-00-S`) and a mode that must match the `DAC80501`'s falling-edge
      capture. And the log's own lesson is that this class is **untestable in the
      shared corpus by construction**, so it will always be found on hardware.
      **Cost is lower than "one part":** `SW501` is already `C7185056` as a
      single-designator BOM line, so a second instance **increments that line's
      quantity rather than adding a BOM line** — nothing new for JLCPCB to
      source or place, no new footprint (`orb_weaver_smd:SMT_1045822_WRE`), no new
      symbol, 115 in stock. RP2040 `RUN` has an internal 50-80 kΩ pull-up so no
      external pull-up is needed. **It is also the only cut item that cannot be
      added later without a respin.**
- [ ] **Firmware, paired with the above: enable the RP2040 hardware watchdog.**
      Recorded in `../mouse-joystick-firm/.agents/PLANS.md`. It covers the
      complementary case — a transient hang self-recovers unattended, in the rig,
      with no button — and the `STATUS` hang would have auto-recovered.
      **They are complementary, not substitutes, and this is the part to get
      right: a watchdog reset does NOT enter BOOTSEL.** Flash something reliably
      broken and the watchdog gives a reset loop that you still cannot reflash out
      of, so it makes that case *harder* to escape. `RUN` + BOOTSEL is the escape
      hatch for "I just flashed something broken"; the watchdog is for "it wedged
      mid-session". Ship both.
- [ ] **Debug connector: land the pads, and treat the probe as a separate
      purchase.** Established 2026-09-08: **there is no SWD probe on hand for
      either candidate footprint**, and no Tag-Connect or 1.27 mm 2×05
      Cortex-Debug pattern exists in official `kicad-footprints` 10.0.6 or the
      local libraries, so the footprint must be authored either way. The probe
      is **not a board problem** — `debugprobe` firmware turns any spare RP2040
      board into a CMSIS-DAP probe that OpenOCD and probe-rs speak, so SWD
      capability is a ~$4 purchase, not a respin. **Land the pads regardless**;
      they are close to free and they are the only route to a hard-fault
      post-mortem. Prefer Tag-Connect TC2030-style (pads plus three NPTH, **zero
      BOM lines**, so no per-board cost and nothing for JLCPCB to place) over the
      SMD header, which is a new part *and* an order.
- [x] **An on-board debug MCU is rejected — decided 2026-09-08.** Recorded so it
      is not re-proposed. See **Why an on-board debug MCU was rejected** below.
- [ ] **Test points.** Decide **before layout** whether they are schematic
      symbols (so the netlist carries them) or layout-only pads. The list:
      `+36V_SW`, `+5V_SW`, `+3.3V_SW`, `+3.3V_MCU`, `+5V_MCU`, both sides of
      `R303`, `TMC_DIAG0`, `TMC_DIAG1`, `~{TMC_DRV_EN}`, `HV_EN`, `HV_SNS`,
      `REFL`, `~{INSTR_BUF_OE}`, `ENC_A`, `ENC_B`, `LIMIT_SW`, plus in-block
      `VREFIO`, `AMP_VOUT` and `AOUT`, and `TQ_DRDY` once torque is in.
- [ ] **Netclasses for the new analog nets.** Torque: `SIG_P`, `SIG_N`, `IN_P`,
      `IN_N`, `VEXC`, `VMID`, `INA_OUT`, `ATT_TAP`, `FILT_IN`, `AMP_VOUT`,
      `TQ_AOUT`. Brake: `V_SET`, `V_SENSE`, `V_LIMIT`, `BRAKE_ISENSE`, the gate
      node and the coil nets. None of them may fall through to `Default`, and
      re-check that no net matches more than one pattern.
- [ ] **Fix the title block.** Every sheet still reads "Orb Weaver Design Block
      Mining" and carries the mining project's `comment 1`. `rev` is already
      `1.0`. This is the fabrication drawing.
- [ ] **Board outline.** 100 × 80 mm with 177 footprints today. The brake zone
      (36 passives, three SOT-23-5, a VSSOP-10, a DFN2020, two SOD-123FL, an
      X1SON, two ferrites, a 2-position vertical terminal, no electrolytic), the
      torque zone (57 parts) and the 12 V module are a large increase. Leave pads
      for an RC snubber from the brake pass-device drain to GND.

### Decide, then do

- [ ] **The pyControl event lines `GP20`/`GP22`/`GP23`.** The researcher will
      likely derive pull events from the analog or UART record instead, in which
      case all three come out along with the `J8`/`J9` BNCs planned for them —
      real board area next to the new zones. **Not forced by the pin budget:**
      moving `~{HV_FAULT}` off ADC3 already resolves the squeeze. Confirm with
      the researcher, then remove them for the right reason.
- [ ] **`U603` and `U604` are entirely unused and `U602` uses 1 of 8 channels.**
      Three QFN-20s and three bypass caps for seven signals. The cheapest moment
      to drop two of them is before placement, by moving `TMC_DIAG1` to one of
      `U601`'s free channels. Note the old counter-argument is dead: the unused
      channels have their MCU-side pins tied to GND, so nothing is pre-wired.
- [ ] **`R303` is a 0.36 Ω jumper in a 1206 polyfuse position** on the pyControl
      5 V branch. No PPTC exists in the parts DB. Size against v1.0's load, not
      rev 0's ~100 mA. Port 5 V is a shared 1.0 A that also feeds the controller's
      own logic regulator with no per-port fuse, so a fault here can reset the
      experiment controller. Add test points either side or a tripped fuse cannot
      be diagnosed in circuit.
- [ ] **TVS at the 36 V entry** — populate decision, from v0.3 measurement 2.
- [ ] **Encoder chain has no ESD device**, contrary to `docs/design-block-map.md`.
      The 4.7 kΩ series and 470 pF give some protection and the `SN74LVC2G17` has
      internal clamps. Decide and record.
- [ ] **Locking motor connector.** Screw terminals on a rig that gets handled;
      deferred once already. Decide before the harness is rebuilt, not after.
- [ ] **Silkscreen a unit identifier.** Two interchangeable boards in one rig is a
      failure mode, and calibration belongs to a board serial rather than a
      joystick position.
- [ ] **The bus switches run from `+3.3V_MCU`**, whereas the `SN74CB3Q3245` part
      note says to power them from the switched rail so `Ioff` provides isolation
      at `VCC` = 0. As built, isolation depends on the MCU holding
      `~{BUS_SW_EN}` high, which `R601` makes the reset default. Reconcile the
      note or the rail.
- [x] **`~{BRAKE_FAULT}` — decided 2026-09-08: it goes to a GPIO in v1.0.**
      Moved up to *Required* below.

### Why an on-board debug MCU was rejected

Decided 2026-09-08. Two variants were considered — a second MCU on the board for
programming and debug, and a second FFC port letting an external debug MCU reach
the target — and both are rejected. The reasoning, so it is not re-litigated:

- **The observe half already exists and is better than a debug MCU would be.**
  Eleven live InstrumentPort Strands, an LA5032 with 32 channels, and
  agent-drivable captures. The 2026-09-03 encoder confirmation — raw quadrature
  against the driver's `X_ENC` to 3-8 counts — is exactly the class of question a
  debug MCU would be bought for, and the port answered it.
- **The domain-state half already exists too.** The UART protocol's `status`,
  `limits` and `id` report the state that actually matters, *while the system
  runs*. A halted core cannot tell you why a follow check tripped.
- **Breakpoints are close to useless on this system.** Halting mid-move leaves
  the motor energised at a commanded position, the brake in an arbitrary state
  and 36 V up. Every firmware problem hit so far — stall detection, follow-check
  sensitivity, the `mechanical_stop_first` homing fault, the `ENC_CONST` sign —
  is *dynamic*, and none is visible at a halt.
- **The register state that matters is not in the RP2040.** `GSTAT`,
  `DRV_STATUS`, `IOIN` and `CHOPCONF` live in the TMC5130A and are read over SPI
  regardless; `IHOLD_IRUN` is **write-only**, so no debugger can read it back.
- **Reflashing is already solved.** The firmware self test has a `B` command that
  reboots into BOOTSEL, so the usual headline benefit of SWD is largely already
  covered; the `RUN` switch closes the hung-or-unprogrammed remainder.
- **A stimulus path conflicts with a documented safety constraint.**
  `docs/instrument-strategy.md` → *Safety With Animals Present* makes
  observe-only a deliberate property: the buffers are unidirectional, `AOUT0`/
  `AOUT1` are no-connect, and anything adding a drive path into the board "must be
  treated as a bench-only configuration and must not be the normal experiment
  arrangement". An on-board debug MCU is a permanently populated drive path, which
  is the arrangement that rule forbids.
- **What survives the rejection is worth keeping.** The one real capability gap is
  **hardware-in-the-loop stimulus** — faking encoder quadrature, asserting the
  limit switch, driving fault lines to test firmware response automatically. If
  that is ever wanted, build it the way this project already builds instrument
  interfaces: **a separate bench-only adapter board that plugs into an FFC port**,
  a sibling of `m2k_instrument_port_adapter` and `la5032_instrument_port_adapter`,
  physically absent during animal work. Not an on-board part. **Do not design it
  now** — the InstrumentPort's capture side has not yet failed to answer a
  question.

### Deferred to a later revision — do not design now

- [ ] **`PYC_FAULT` / `EXT_FAULT_IN` / any hard-wired fault signal.** Decided
      2026-09-08: **test v1.0 and the new blocks first**, and add this only if
      the rig shows it is needed. **`~{BRAKE_FAULT}` on a GPIO is the experiment
      that informs this** — if a monitored ceiling event turns out to be frequent
      or consequential, that is the evidence for building a rig-level line; if it
      never fires in normal use, the deferral becomes permanent. What was established while looking, so it does
      not have to be re-derived:
      - **No free RJ-45 pin can carry it on this breakout and these ports.** Rig 1
        is a **Breakout 1.2** (`b = Breakout_1_2()`), boards on **ports 1 and 4**.
        Read off `../kicad-libs/tmp/pyControl_breakout_1_2r1_schematic.pdf`: pins
        3 and 7 are `POW-xA`/`POW-xB`, `TBD62083APG` sink-driver **outputs** on
        every port; pin 5 is **`POW-1C`** on port 1 (another driver output) and
        **`DAC-2`** on port 4 (pyboard `X6`/`PA5`, an analog DAC output); pin 8 is
        **unconnected** on 1.2. Pins 1 and 4 are the UART, 2 is ground, 6 is 5 V.
        **The pin-5 table in `docs/pycontrol-port-pinout.md` is the H7 breakout's
        and does not apply to this rig.**
      - Breakout 1.2 has only **two** BNCs, and **`BNC-2` is the same net as port
        6's `DIO-6B`**, so using it forecloses port 6.
      - **The controller is not who needs the wire.** The safety rule wants one
        board's fault to stop the other, which is a board-to-board link: a single
        shared active-low open-drain `~{RIG_FAULT}` on a 2-position 3.5 mm
        terminal, pulled up to **`+3.3V_MCU`** (not `+3.3V_SW`), costs **one
        GPIO** because the same pin reads the wired-OR while high-Z, and replaces
        both `PYC_FAULT` and `EXT_FAULT_IN`. A wired-OR cannot detect a *dead*
        board, so hardware would handle fault propagation and the UART heartbeat
        liveness.
      - If the controller must see it instead, **port 2** is the least-bad donor:
        no UART, nothing assigned, and `DIO-2A`/`DIO-2B` are two independent MCU
        GPIOs, so one spare port can carry both boards' fault lines via a
        Y-harness.

### Purchases before layout, not after

**Modelled 2026-09-08 against the whole v1.0 BOM, not part by part. Nothing is
short: buy nothing for a 5-board build.** Method — v0.3's fab BOM (173
placements) plus `torque_bridge_0_3v3_ina821` (57), plus
`brake_current_sink_0_49ma_dac80501` (47), plus `hv_to_12v_tpsm365r6` (12), plus
the planned block deltas, plus the board-level `TQ_AOUT` BNC = **302 placements
over 81 BOM lines**. Every line mapped to a JLCPCB offer; none at zero stock.
Tightest coverage in the entire board:

| part | /board | stock | boards |
| --- | --- | --- | --- |
| `OPA197IDBVR` `C221351` | 7 | 298 | **42** |
| 2.2 µF `GRM21BD72A225KE01L` `C2981733` | 2 | 90 | 45 |
| `DAC80501ZDGSR` `C1852033` | 2 | 98 | 49 |
| `HL-BNC-KHDA` `C19712152` | 2 | 98 | 49 |
| `ADS8689IPWR` / `INA821IDR` / `REF5010AIDR` | 1 ea | 50 ea | 50 |

Everything else clears 60 boards. Re-run the model rather than re-deriving it:
the script pattern is one join of `db/source/vendor_map_jlcpcb.csv` and
`db/source/parts.csv` against this repo's `fab/*/jlcpcb-bom.csv` plus the block
component lists.

- [x] **`DAC80501ZDGSR` — closed, the concern was stale.** This bullet said "50 in
      stock… covers exactly 25 boards with no rework margin". **Stock is 98**, so
      it is 49 boards at 2 per board.
- [x] **`OPA197IDBVR` — closed, no purchase needed.** 7 per board confirmed by
      count (3 brake, 3 torque, 1 angle — the old "~2 torque" was low), against
      **298** in stock = 42 boards. The queued "100-150" is unnecessary.
- [x] **`RT0402BRD073K2L` 3.2 kΩ 0.1% / 25 ppm — closed.** 1980 in stock against
      6 per board for the three ÷2 dividers.
- [x] **`USBLC6-2P6` — closed.** The 2026-08-14 handoff warned "stock is 20…
      two per board caps the build at ten boards". **Stock is now 1002.**
- [ ] **A 1206 PPTC for `R303`/`R1903` — the only genuinely pending purchase, and
      it is blocked on a spec rather than on money.** Confirmed 2026-09-08: there
      is **no fuse, polyfuse or PPTC anywhere in the catalog** — zero hits on all
      three terms. Size the hold current against v1.0's load, **not** rev 0's
      ~100 mA, *then* create the internal part, vendor mapping, symbol and
      footprint. Buying before sizing is how the wrong hold current gets ordered.
- [ ] **Do not buy the TVS yet.** `SMBJ40A` is **not in the catalog**; the stocked
      `SMF48A` (120) covers first boards. The populate decision comes from **v0.3
      measurement 2**, so ordering now is buying ahead of the data that decides
      whether it is needed.
- [ ] **Do not buy the 3.3 V RRIO op amp yet** — gated on v0.3 measurement 1 plus
      the researcher's answer. Nothing stocked qualifies.
- [ ] **If the build is 25 boards rather than 5, top up four parts first.**
      `ADS8689IPWR` ($4.19), `INA821IDR` ($2.49) and `REF5010AIDR` ($1.21) all sit
      at exactly **50**, and `DAC80501ZDGSR` ($5.02) at 98 — a 25-board run
      consumes half of each with no rework margin, and these are the lines with
      real lead-time exposure. At 5 boards, order nothing.
- [x] **Both parts are identified — closed 2026-09-08, resolved 2026-09-02.**
      This bullet was stale. `docs/bringup-log.md` identifies the motor as a Lin
      Engineering **WO-208-13-01D** (NEMA 08, 1.8°/step, 4-lead bipolar,
      0.6 A/phase, 6.5 Ω/phase, 3 oz-in, no gearbox, rear shaft) and the encoder
      as a US Digital **E4T-1000** single-ended (1000 CPR, 4000 quadrature
      counts/rev, 5 V push-pull), CPR bench-confirmed against 51200 usteps/rev.
      Datasheets in `docs/datasheets/` and `../kicad-libs/tmp/`. What the motor
      number did **not** settle is whether 0.6 A is RMS or peak — Lin does not
      say — so that sub-question survives as the IRUN 17 versus 24-25 choice, and
      only a thermal measurement closes it.

## Next Revision — v0.4 Required Changes (opened 2026-09-02)

> **Superseded 2026-09-08 by the two sections above.** The repo is at
> `(rev "1.0")` and there is no v0.4. **This section is kept for its reasoning,
> not its task list** — the rejected alternatives for the `LATCH` fix, the energy
> accounting behind the 108 µF ceiling, and the `swap_lr` and harness notes are
> all still correct and should not be re-derived. Work the v1.0 list.

**Carry these forward. v0.2 and v0.3 are electrically identical on the 36 V
path, so v0.3 boards will reproduce every problem below.** Verified by diffing
`kicad/` at `v0.2` against `cab25b3` ("Generated v0.3 fab files"): `R206`/`R1906`
= 40 kΩ, `LATCH` strapped through 1 kΩ, `C1213`+`C1214` = 2 × 100 µF, unchanged.

### 1. `LATCH` to a GPIO — blocking, and the reason this section exists

`R203` (0402, 1 kΩ) straps the TPS1HTC100-Q1's `LATCH` to `+3.3V_MCU`, selecting
latch-off. **That prevents the 36 V rail from ever coming up.** The switch trips
its relative thermal shutdown 1-2 ms into charging `+36V_SW`'s 208 µF, at only
~10-12 V, and with latch-off it never retries — so the rail lives on stored
charge for 17-68 ms and collapses. Measured on **both** rig boards.

**Change: move `R203`'s far end from `+3.3V_MCU` to a spare GPIO.** Keep the
1 kΩ `RPROT`. Firmware drives it low for the power-up ramp and high once the
rail is up, which gets retry-based soft-start *and* latch-off for real faults.
It also defaults to auto-retry when the MCU is unpowered or at reset, which is
the safe default — that is exactly when the rail must be able to charge.

Spare GPIOs proven good by stage 1: `GP15`, `GP16`, `GP17`, `GP18`, `GP20`,
`GP22`, `GP23`, `GP27`. (`GP10`/`GP11`/`GP13` are the rev-1 DAC bus — do not
use those.)

Rejected alternatives, with the reasoning so it is not re-derived:

- **Tie `LATCH` low permanently.** Works — proved it by depopulating `R203` —
  but the part then auto-retries every 2 ms *forever* into a genuine fault,
  cycling the motor rail at ~500 Hz. `docs/power.md` is right that a joystick
  twitching in an animal's paw is unacceptable. Fine as a bench configuration,
  wrong as a shipped one.
- **Halve the bulk instead.** The switch delivers ~70 mJ before tripping, so
  ½CV² = 70 mJ at 36 V puts the one-burst ceiling at **~108 µF** — depopulating
  `C1214` lands on break-even, not under it. Real margin needs ≤ 50-60 µF, and
  that bulk is what absorbs motor inductive turn-off on a rail with 49 V of
  driver headroom and **no TVS**. Do not trade a protection for a convenience.
- **Raise `I_CL`.** FET energy is ½CV² regardless of the limit; the time is
  ∝ 1/I, so peak junction rise goes as roughly ½VI·Zθ(t) ∝ √I. **A higher limit
  is hotter.** Separately, check `R206` still leaves motion headroom once the
  motor is known — 0.679 A RMS/phase draws an estimated 0.2-0.7 A from 36 V
  depending on winding resistance, against a 1.15 A limit.

### 2. Test points — the binding constraint all session

`+36V_SW`, `+5V_SW`, `+3.3V_SW`, `+3.3V_MCU`, `+5V_MCU`, and both sides of
`R1903`. The entire 36 V diagnosis rested on energy accounting because reading
`+36V_SW` means clipping onto `C1213`'s can pads, and that measurement still has
not been taken.

### 3. Not a required change, but know it before the next layout

**The limit switch is at the positive end of travel and wired to `REFL`.**
Measured 2026-09-02 on board `E4654C159F4D1334` during stage 3. `REFL` is the
TMC5130A's *left* switch and stops *negative* motion, so `SW_MODE.swap_lr` has
to be set or the hardware stop guards the direction that moves away from the
switch. Firmware sets it, so **nothing has to change on the board** — but it is
a mismatch between the wiring and the chip's natural sense, and a future
revision or `../mouse-joysticks-pcb` could avoid it by putting the switch at the
negative end of travel or wiring it to `REFR`. Full note in
`docs/bringup-log.md`.

**The left and right joysticks use different harnesses so the boards and the
firmware are identical.** Decided 2026-09-02. The left mechanism is mirrored, so
its harness swaps one motor coil's leads and the encoder's A/B channels; nothing
else differs and the boards carry no left/right state. Tables, the reasoning,
and the verification procedure are in `docs/harness-pinouts.md`.

**Travel is only ~4000 microsteps, 28 deg at the motor shaft**, bounded by the
limit switch at the positive end and a mechanical stop at the negative end. Any
future firmware or motion envelope has to fit inside it.

### 4. Carried forward unchanged

- TVS footprint on `HV_IN` — still a populate decision, still no evidence either
  way. `docs/power.md` → Transient Headroom.
- 1206 PPTC on the pyControl 5 V branch (`R1903` is a jumper today), plus test
  points either side so a tripped fuse is diagnosable.

## How To Check A New Revision For The Fix

**One command.** Flash `mouse-joystick-firm` `examples/TMC5130Communication` and
send **`l`**:

- `[FAIL] this board still needs the workaround` → `LATCH` is still strapped.
  Nothing to do; `PowerSequence::powerUp()` uses the firmware staircase
  automatically.
- `[PASS] LATCH fix is present` → a plain `HV_EN` assertion works. Then build
  with `-DMJ_HAS_LATCH_GPIO=1 -DMJ_LATCH_GPIO=<n>`, reading `<n>` off that
  revision's netlist — **do not guess it**, `src/BoardPins.hpp` has an `#error`
  that enforces this — and `powerUp()` switches to the direct path and arms
  latch-off after the ramp.
- `[!!] NO 36 V INPUT` → the rail never moved *and* the switch never reported.
  Below `V_S,UVLOR` (5.0-5.75 V) the part does not operate, so this is an absent
  supply, not a tripped switch. Check `J201` is seated and the supply is on;
  `J201` pin 1 is `GND`, pin 2 is positive, and reversed leads are blocked by
  `D201` and look identical to this.

`s` then runs the whole stage 2 sequence and prints which power-up method it
used, so a bring-up log records the mechanism rather than leaving it to be
re-derived.

## Current Goal

**Rev 0, rescoped 2026-08-13: get the interfaces on a board and send it to
fabrication.** RP2040 with GPIO isolation, one TMC5130A on a 4-pin motor
terminal, one single-ended encoder on a 5-pin terminal read by the driver only,
one debounced limit switch on a 2-pin terminal, a pyControl UART on RJ-45, and a
36 V switched supply input that doubles as a chip-reset button.

Rev 0 also carries **InstrumentPort-40**, moved back in on 2026-08-16 for
firmware development — see Resolved below.

Deferred to rev 1: the 0-5 V analog angle output, the pyControl TTL event lines,
and the PIO encoder cross-check. Their pins are reserved and no Rev 0 pin moves
when they arrive. **The PIO cross-check was since deleted outright** — see
2026-08-16 below.

**Session-level detail lives in `.agents/handoff.local.md`.** Read it first.

The rig's two-joystick form factor question stays open. This board is the fast
path to a testable system, not a commitment against `../mouse-joysticks-pcb`.

## Context

Source-of-truth sibling repositories:

- `../mouse-joysticks-pcb` — the twin-axis board for the same rig; most of this
  repository's documentation derives from it
- `../orb-weaver-context` — cross-project context and the PCB development plan
- `../board-interfaces` — InstrumentPort-40 and, later, the pyControl connector
  profile
- `../kicad-libs` — symbols, footprints, database libraries, design blocks,
  vendor mappings, KiCad helper tooling
- `../tmc51x0-driver-dev-pcb` — the validated RP2040 + TMC5130A predecessor
- `../mouse-joysticks-mech` — the new-rig mechanical assembly, two joysticks
- `~/Repositories/github/syringe-pump` — pyControl module reference design
- `~/Repositories/kicad/mouse-joystick-pcb` — previous-generation prior art

## Direction History

- **2026-08-10:** `mouse-joystick-pcb` created as one PCB per joystick, RP2040.
- **2026-08-11:** renamed to `mouse-joysticks-pcb` and rescoped to one board for
  both joysticks; Rev 0 descoped back to RP2040 to be buildable now.
- **2026-08-12:** this repository created to carry the single-axis design in
  parallel, because it can be finished sooner. 36 V input instead of 24 V, and
  nothing descoped for pin budget. Both repositories are live.

## Resolved

- **Rev 0 scope, 2026-08-13, amended 2026-08-16.** Interfaces plus the means to
  observe them; DAC and event lines deferred to rev 1, PIO encoder tap deleted.
  `docs/rev0-plan.md`.
- **RP2040 GPIO allocation.** Rev 0 connects **18 of 30** and reserves 8 more at
  fixed numbers; full scope is **26 of 30**. **Spares are now four — `GP15`,
  `GP16`, `GP18`, `GP27`**; `GP14` was consumed by `HV_DIAG_EN` on 2026-08-17.
  **No pin moves between Rev 0 and rev 1.** `TMC_REF_STIM` was deleted permanently and its
  pin pays for the bus-switch enable on `GP9`. `docs/interface-map.md`.
- **Two power domains, 2026-08-13.** The high-side switch is a reset button:
  everything resettable is on `+36V_SW` → `+5V_SW` → `+3.3V_SW`, and the MCU is on
  `+5V_MCU` → `+3.3V_MCU` fed from USB `VBUS` or pyControl pin 6 through two ORing
  diodes. The board does not boot on 36 V alone, accepted. Exactly two
  `5v_to_3v3_tps73733` instances, one per domain. `docs/power.md`.
- **GPIO isolation rule.** A GPIO goes through the bus switch if and only if its
  far end is on the switched domain — 7 channels in Rev 0, 12 at full scope. The
  pyControl UART bypasses, so the board stays reachable with the motor rail off.
  The oversized 4-package block is accepted as-is for schedule.
- **pyControl pin 6 is 5 V**, confirmed from the syringe-pump module netlist. Its
  current budget is still unmeasured and is a Gate A item.
- **InstrumentPort-40 is in Rev 0, re-allocated 2026-08-16.** Moved back in for
  firmware development: the port carries both directions of the pyControl serial
  link *tapped at the RJ-45*, the TMC5130A SPI bus, the two firmware triggers, and
  `ENC_A`/`ENC_B`/`LIMIT_SW` — 11 of 18 digital Strands live. The other 7 are
  allocated and unrouted, **4 reserved for the rev 2 brake and torque sensor** so
  those circuits inherit a pinout instead of renegotiating one. The overlay now
  follows the profile's own Preferred Digital Overlays table: TMC bus on the SPI
  slots, pyControl serial on the first UART pair, brake PWM and fault on the
  PWM/fault slots, torque front end on the I2C slots.
  - **REVISED 2026-09-11 — the eviction is now a choice, not a forced move, and
    the strand budget needs settling before v1.0 layout.** The I2C transport
    change cut both ways: it freed `DIG6` (`~DAC_CS`) and dissolved `DIG11`'s
    `BRAKE_CS` allocation, since I2C has no chip selects — **but it also took the
    torque ADC's `SCK`/`SDI` off strands they used to share with the DAC bus**,
    because `SPI1` now serves the `ADS8689` alone. v1.0 tallies to **17 or 19 of
    18 strands** depending on whether those two get port visibility. Decide it
    explicitly here rather than discovering it at routing.
    **User's decision, 2026-09-11: the TMC5130 has proven itself on encoder
    handling, so `ENC_A`/`ENC_B` are reconfirming a verified circuit and the
    strands are better spent verifying new ones.** Recommended split: **keep
    `LIMIT_SW`** — homing is the field failure mode and the switch is a wearing
    mechanical part whose failure the driver's own registers cannot contradict —
    and give `ENC_A`/`ENC_B` test pads instead of strands. If more are needed,
    `TQ_CAL_EN` is a static enable rather than an edge worth a channel, and the
    ADC's `SDI` carries only bring-up configuration writes.
    **Reopened 2026-09-12:** retaining InstrumentPort-40 v0.3 for v1.0 is now
    the explicit schedule fallback, not the only planned outcome. The new
    direction is 50 pins / 32 digital channels / 18 grounds with integrated,
    hardware-default-enabled buffers; it supersedes the earlier 30-signal /
    10-return digital-40 proposal. See `docs/digital-instrument-port-migration.md`
    for the adoption gate. Neither the new board overlay nor hardware is done.
    **Beacon correction:** retain the current 64-bit serial payload; adding a
    profile-version field is not firmware-only compatibility. Record the profile
    with captures until a separately versioned frame/decoder extension exists.
    Legacy `FW_TRIG0` = `GP25`, `FW_TRIG1` = `GP21` reach `TRIG0`/`TRIG1`
    through `U1801` and bypass the bus switch. Keep both marker channels in
    the new first 16-channel bank and retain the planned `FW_TRIG` test pads.
    Original legacy allocation rationale follows.
  - **`DIG0`, `DIG1`, and `DIG11` are swap slots.** `ENC_A`, `ENC_B`, and
    `LIMIT_SW` hold three of the rev 2 brake/torque slots through Rev 0 and rev 1
    and hand them over at rev 2. They earn the space because none of those signals
    reaches a GPIO in any revision, so the TMC5130A's own registers are firmware's
    entire account of position and homing and nothing can contradict them —
    capturing the raw signals beside the SPI traffic is the only check. These
    slots were chosen because they sit in the rev 2 buffer package, making the
    eviction as late as possible. `ENC_N` stays on a test pad.
  - **No new boundary pins on `pycontrol_behavior_port_rj45_boundary`.** An
    earlier draft called for two, so the port could tap the connector side of
    `R29001`/`R29002`. Rejected 2026-08-16: 330 µA through 100 Ω is 33 mV, so a
    digital channel cannot tell the two sides apart, and the connector-side tap
    would put the buffer input on the unprotected side of the ESD clamp. The port
    uses the existing `PYC_DIO_A`/`PYC_DIO_B` pins at five boundary pins.
  - **But change those two pins from `passive` to `bidirectional`.** It is the
    only connector boundary block in the library with no driving pin — `usb2` and
    `instrument_port_40_dut_ffc_boundary` both use bidirectional for logic — and
    left passive, `PYC_UART_RX` reaches the board with no driver on the net.
  - **Signal directions are now in the allocation table**, as a `Dir` column, and
    every `mcu` sheet pin is listed with its KiCad shape and what it mates with.
    The `DIO-A` → RX / `DIO-B` → TX crossover is drawn explicitly; it is the one
    place on this board where the naming reverses. `~{BUS_SW_EN}` is the only Rev
    0 connected GPIO needing no `mcu` sheet pin — the bus switch is inside that
    sheet.
  - `GP24` `~{INSTR_BUF_OE}` is now live. No pin moved.
  - ~~**Four 100 kΩ pull-downs plus the `SW_RAIL_SENSE` divider are the only new
    passives.**~~ **Superseded 2026-08-17.** As built there are **nine** 10 kΩ
    termination resistors plus the divider, and the 100 kΩ value would have been
    wrong on the TMC SPI lines — see **Open Schematic Findings**. Buffer packages
    are **three** (`U1601`, `U1701`, `U1801`); `U_C` and `U_D` were never placed and
    do not exist. The spare twelfth channel has its input tied to GND, but its
    output stops at `R1805` and does not reach `DIG12`.
  - **It costs layout schedule** — a 40-pin FFC, three buffer footprints, and 18
    more routed nets on the board whose layout was already the long pole.
  - `docs/interface-map.md`, `docs/instrument-strategy.md`.
- **Event-line routing.** Three lines on BNC, two dual jacks plus one. Rev 1.
- **The pyControl port pinout**, from the syringe pump. Cited, not bench-verified.
- **Current sense**, inherited: 0.15 Ω, `vsense = 1`, ~~`IRUN = 28`~~ **`IRUN = 17`
  (0.421 A RMS), corrected 2026-09-08.** 28 predates the motor being identified
  and is above its rating on either reading of 0.6 A/phase; 24-25 is the
  alternative if the thermal measurement supports the equal-heating reading.
- **Supply voltage:** 36 V, using the existing
  `hv_input_36V_terminal_2pos_5p08_protected` block.
- **TVS on `HV_IN`, for the switch and the buck — not for the driver.** A standard
  TVS cannot clamp under the TMC5130A's 49 V on a 36 V rail, but the switch (70 V)
  and the buck (65 V) are the parts exposed at hot-plug, and they are clampable.
  `SMBJ40A` preferred, stocked `SMF48A` usable now. The driver is protected by
  construction — bulk downstream of the soft-start switch, capped at tens of µF,
  tight `VS` loop — and verified at Gate B. **As built, no TVS is populated**
  (confirmed by netlist, 2026-08-17); it stays a Gate B measurement rather than a
  fabrication blocker.
- **The 36 V input block is clean.** The six edits were verified by netlist review
  on 2026-08-12 — `EN` divider, `DIAG_EN`, `LATCH`, `ILIM` = 40 kΩ, `SNS` = 249 Ω,
  and the `~FAULT` route. **The three defects below were fixed and verified in the
  block on 2026-08-16**: `R27005` now pulls `~{FAULT}` up to `+3.3V_MCU`, and
  `HV_IN` and `SNS` are hierarchical. Kept for the record only — historically,
  `~FAULT` was pulled down
  to `GND` instead of up to `+3V3_MCU`, and `HV_IN` and `SNS` are local labels
  rather than hierarchical, so the board can reach neither. Plus two cheap
  concerns — `C27002`'s 50 V rating on a 36 V rail, and the misleading `VAA` net
  name. The `+3V3_MCU` naming concern was **withdrawn**; naming the rail by its
  domain is correct. All in `docs/power.md`; fix before the block's PCB layout is
  finished.
- **Multi-source logic power, superseded 2026-08-13.** Now two sources only —
  USB `VBUS` and pyControl pin 6 — ORed at `+5V_MCU`, upstream of the MCU
  domain's own LDO. The onboard buck is **not** one of them; it lives on the
  switched domain. The two 5 V rails are separate nets, which is what keeps
  `+5V_SW` in spec for the TMC's `VCC`.

## Blocking Items

**Two remain, and only the second can actually invalidate the board.** Ranked.

1. **Joystick motor part number.** **Identified 2026-09-02: Lin Engineering
   WO-208-13-01D** — NEMA 08, 1.8°/step, 4-lead bipolar, 0.6 A/phase,
   6.5 Ω/phase, 3 oz-in, no gearbox, rear shaft. See `docs/bringup-log.md`. The
   "0.67 A" in the sentence below was an assumption and is superseded; **Lin does
   not state whether 0.6 A is RMS or peak**, which is exactly the open IRUN 17
   (0.421 A) versus 24-25 (0.600 A) choice, and only the thermal measurement
   closes it. **The bulk-capacitance question below can now be decided.**
   Sets the motor connector, supply envelope,
   `ILIM`, and confirms whether 0.67 A is RMS or peak. Owner: Peter. Also settles
   the `tmc5130` block's bulk-capacitance question, restated here so it survives a
   clone: the block ships **200 µF on `VM`** (`C1213`+`C1214`, 2× 100 µF 50 V,
   `OW-PASS-EEEHAH101UAP`, D8×10.2 mm) sitting on switched `+36V_SW`, where
   `docs/power.md` bounds bulk at "tens of µF, not hundreds". 200 µF at 36 V is
   **130 mJ** per `HV_EN` turn-on into an HTSSOP-14. **Unresolved.** Options:
   depopulate `C1214` (65 mJ), keep both and verify a clean turn-on cold and hot
   at Gate B, or decide once the motor is identified. 50 V on 36 V is 1.39×, and
   110 mA ripple each is thin for motor bulk.

   **Added 2026-08-17:** this bulk is also what sets the off-state creep rate in the
   `DIAG_EN` finding below. At ~208 µF the rail creeps at ~1.2 V/s; depopulating
   `C1214` would double that to ~2.4 V/s. Moving `DIAG_EN` to `GP14` removes the
   creep entirely, so the two decisions are now independent — but do not
   reintroduce a fixed `DIAG_EN` pull-up while reasoning about bulk.
2. **Encoder part.** **Largely resolved 2026-08-17 — no longer gates the
   schematic, and no longer gates fabrication.** The receive path is decided and
   built: single-ended 5 V push-pull, conditioned by the new
   `quadrature_encoder_input_5v_sn74lvc2g17` block. Confirmed against the
   encoder's own spec (4.5-5.5 V supply, 25-42 mA, `VOH` ≥ 2.4 V at −8/−5 mA,
   `VOL` ≤ 0.4 V, tr 100 ns / tf 50 ns), which closes against the SN74LVC2G17's
   `VT+` ≤ 2.0 V and `VT−` ≥ 0.8 V with 400 mV of margin on both rails.

   **Closed 2026-09-08.** The part is a US Digital **E4T-1000**, 1000 CPR
   bench-confirmed against 51200 usteps/rev, so the `C802`/`C803` filter value is
   confirmed correct with ~450× margin — see the closed item in the v0.3 section
   above, and do not re-derive it. **One consequence to propagate:** the E4T's
   `CPR > 500` branch draws **34 mA typ / 42 mA max** (against 25/30 for
   CPR ≤ 500) and drops output drive to `IOL`/`IOH` = 5 mA, so
   `docs/power.md`'s 5 V-budget row still reading *"Unknown — the encoder part is
   not identified"* is stale and should be filled in with 42 mA worst case.

   Superseded text, kept for the derivation: what still needs the part number,
   and **only** this: **CPR and maximum shaft
   RPM**, to confirm the `C802`/`C803` filter value. They are fitted at 470 pF,
   which covers a channel frequency up to 44.9 kHz — `f_ch = CPR × RPM / 60`.
   Note the number to size against is the fastest **motor-commanded** move
   (homing, recentering), not how fast the mouse pulls; the animal is the slow
   case. A low-pass has no lower limit, so slower motion never requires a
   different value — only a faster axis would. Sizing table with `R = 4.7 kΩ`:

   | Cap | f_c | max `f_ch` | atten @10 MHz |
   | --- | --- | --- | --- |
   | 27 pF | 1.09 MHz | 685 kHz | −19 dB |
   | **470 pF (fitted)** | 71.4 kHz | **44.9 kHz** | −43 dB |
   | 1 nF | 33.7 kHz | 21.2 kHz | −49 dB |
   | 2.2 nF | 15.3 kHz | 9.7 kHz | −56 dB |

   Verify at bring-up by scoping `ENC_A_FILT` during the fastest commanded move.
   Both channels must keep the same value so A/B propagation delay stays matched.
   Still open from the part choice: whether the encoder has an index channel —
   `J1102` pin 2 is reserved for it, and `ENCN` is currently tied to GND through
   `R1201`. Also confirm the 25-42 mA draw lands in `docs/power.md` (it is ~7% of
   the TPSM365R6's 600 mA).
3. Board outline and mounting. `../mouse-joysticks-mech` is a two-joystick
   assembly, so how a per-axis board mounts is a decision — but pick a rectangle
   and move on rather than blocking the fab order on it.

**Both of the 2026-08-17 non-blocking carry-overs are now closed.** Netclass
patterns were extended from 108 to 124 so every rail, both motor phases and the
sense returns route at their intended widths; and the missing `RUN`/`SWD` was
resolved as a **decision** rather than a fix — deferred to a future board revision,
since RP2040 `RUN` has an internal 50–80 kΩ pull-up and needs no external part. Both
are recorded in **Open Schematic Findings** below, which is the tracked record.
(`.agents/handoff.local.md` is gitignored and will not be present on a fresh clone —
do not rely on it.)

**Resolved 2026-08-13, no longer blocking:**

- DAC8563 `VIH` — deferred with the DAC to rev 1.
- Where `+3.3V_MCU` comes from — USB or pyControl only, two diodes, no always-on
  converter on `HV_IN`.
- The TMC's switched `VCC_IO` — it is on `+3.3V_SW` from the second LDO, so all
  three TMC supplies fall together and the pin-34 ordering holds by construction.
- `D3`, the pyControl 5 V branch — populated. It is one of only two sources that
  power the board, so it is no longer conditional.
- `EXT_FAULT_IN` on `GP27` — rev 1, since Rev 0 has no `FAULT` output to
  cross-wire.
- The regulator feed point — post-switch, deliberately.

Items 1-2 are shared with `../mouse-joysticks-pcb`. Answer them once and record
the answer in both.

**Reopened and narrowed, 2026-08-12: the 36 V TVS.** It belongs on `HV_IN` to
protect the switch and the buck at hot-plug, not on the motor rail to protect the
driver — nothing can do the latter at 36 V. `SMBJ40A` is the part to order, and
the stocked `SMF48A` works for first boards, so it is **not a fabrication
blocker**. See `docs/power.md`.

**Settled 2026-08-17: no TVS is populated in Rev 0.** Confirmed against the
netlist. It stays a bench-measurement item, not a fabrication blocker — and it is
what bounds the margin on `C1213`/`C1214`, which are 50 V parts on a 36 V rail
(72% of rating). Measure the transient at the TMC5130A `VS` pins at Gate B.

## Open Schematic Findings — re-verified 2026-08-17 (cleared for layout)

Third and final pre-layout review, run after the nine board-level termination
resistors, the `DIAG_EN` rework, and the netclass patterns. This section is
**self-contained on purpose** — it is the tracked record, and
`.agents/handoff.local.md` is gitignored and will not survive a clone onto another
machine. Everything needed to act is here.

### Current verification state

**ERC is clean: 0 violations at every severity.** 142 components, no duplicate
refdes, every part has a footprint. **Zero undefined cross-domain nets.** Netclass
patterns extended from 108 to 124, so no current-carrying net routes at the 0.2 mm
`Default` width. Every capacitor sits at or below 80% of its rated voltage.

Reproduce:

```sh
export ORB_WEAVER_KICAD_LIBS=$HOME/Repositories/orb-weaver/kicad-libs
kicad-cli sch erc -o /tmp/mj-all.rpt --severity-all kicad/mouse-joystick-pcb.kicad_sch
kicad-cli sch export netlist --format kicadxml -o /tmp/mj.xml \
  kicad/mouse-joystick-pcb.kicad_sch
```

**ERC could not see most of what mattered here.** Every finding below was found by
walking the flattened netlist against manufacturer datasheets, and all of them kept
passing ERC before and after the fix. Re-check by netlist, not by ERC.

**No blockers remain. The schematic is cleared for layout.**

### Closed this session — keep the reasoning, do not re-derive

- **`TMC_DIAG1` crossed the isolation barrier onto a hard ground.** The
  `rp2040_gpio_isolation_sn74cb3q3245` block cross-mapped its A and B labels on the
  two middle switches. Fixed in `kicad-libs` and re-placed. All 32 channels were
  then audited: the pairing on the RGY-20 package is `A_n` = pin (n+1),
  `B_n` = pin (19−n), every used pair matches, unused A pins are open and unused B
  pins are tied to GND.

- **Netclass patterns matched none of this board's rails.** 146 of 156 nets fell to
  `Default` (0.2 mm / 0.2 mm), including `/+36V_SW`, both 5 V rails, both 3.3 V
  rails, all four motor phases and the `BRA`/`BRB` sense returns. The inherited
  patterns target `+24V`, `VM` and `/tmc5130_spi/OA*`, none of which exist here, and
  `*/HV_IN` was silently matching `PWR_HV_LOCAL` at 0.25 mm — worse than falling
  through. Added:

  | Pattern | Netclass | Width |
  | --- | --- | --- |
  | `*/HV_RAW`, `*/HV_IN` (retargeted) | `PWR_HV_ENTRY` | 1.5 mm |
  | `/+36V_SW` | `PWR_HV_BUS` | 1.2 mm |
  | `/motor_encoder_limit/OA*`, `/motor_encoder_limit/OB*` | `MOTOR_2A` | 0.8 mm |
  | `*/tmc5130/BRA`, `*/tmc5130/BRB` | `MOTOR_2A` | 0.8 mm |
  | `/+5V_*`, `*/VBUS`, `*/PYC_CONN_5V`, `*/PYC_5V_FUSED` | `PWR_5V` | 0.5 mm |
  | `/+3.3V_*` | `PWR_3V3` | 0.3 mm |
  | `*/5VOUT`, `*/tpsm365r6/VCC` | `PWR_5V_LOCAL` | 0.2 mm |
  | `*/tmc5130/VCP`, `*/tmc5130/CPO`, `*/tmc5130/CPI` | `BOOTSTRAP` | 0.3 mm |

  Verified that no net matches more than one netclass, so there is no precedence
  ambiguity. **`BRA`/`BRB` are not Kelvin sense nets** — on the TMC5130A they carry
  full coil current into the sense resistor, so they are sized with the motor
  phases. `SENSE_KELVIN` exists for the TMC5160's `SRA`/`SRB`, not for this part.
  `MOTOR_2A` (0.8 mm) was chosen over `MOTOR_LOW` (0.3 mm) because the motor part is
  still open; downgrade it once the motor is fixed.

- **`DIAG_EN` moved from a fixed `+3.3V_MCU` pull-up to `GP14`.** This is the
  subtlest defect found in the whole review and `docs/power.md` had analysed
  `DIAG_EN` at length without catching it. Holding `DIAG_EN` high keeps the
  TPS1HTC100's OFF-state open-load detection permanently enabled, which switches in
  an internal **150 kΩ pull-up from `VS` to `VOUT`** (`ROL_OFF` 110–166 kΩ,
  datasheet §7.3.4.2). At 36 V that injects ~240 µA into `+36V_SW`, which carries
  ~208 µF, so the rail creeps at ~1.2 V/s and crosses the TPSM365R6's 3.6 V minimum
  `VIN` in about 3 s. The buck then starts, collapses, and hiccups — so the switched
  domain never cleanly powers off, the "`HV_EN` power-cycles every resettable chip"
  property is broken, and `SW_RAIL_SENSE` reads a fluctuating value. `DIAG_EN` has an
  internal pull-down, so with `GP14` high-Z at reset diagnostics are off and
  `+36V_SW` sits at true zero. Current limit and thermal shutdown are unaffected
  (Table 7-1); only reporting is gated, so **firmware must raise `GP14` before it
  can read current sense or faults**. A 10–15 kΩ bleeder on `+36V_SW` was the
  considered alternative. Note this interacts with Blocking Item 1: halving the bulk
  by depopulating `C1214` would double the creep rate, not remove it.

- **Nine board-level termination resistors added.** All in board-authored sheets
  (`mcu`, `motor_encoder_limit`, `instrument_port`), so a design-block re-place
  cannot lose them.

  | Ref | Value | Net | To | Why |
  | --- | --- | --- | --- | --- |
  | `R403` | 10 kΩ | `PYC_UART_RX` | `+3.3V_MCU` | UART RX must idle **high**; the RP2040's default pull-down looks like a permanent break |
  | `R1401` | 10 kΩ | `TMC_SPI_SCK` | GND | define the `U1701` buffer input when the switched domain is off |
  | `R1402` | 10 kΩ | `TMC_SPI_COPI` | GND | as above |
  | `R1403` | 10 kΩ | `TMC_SPI_CIPO` | GND | as above; also gives the instrument tap a clean idle-low |
  | `R1404` | 10 kΩ | `~{TMC_CS}` | `+3.3V_SW` | CSN must idle **deasserted**; a pull-down would assert chip select |
  | `R1405` | 10 kΩ | `LIMIT_SW` | GND | define the `U1801` buffer input |
  | `R1101` | 10 kΩ | `TMC_DIAG0` | `+3.3V_SW` | DIAG is open-drain at reset; datasheet requires ≤47 kΩ |
  | `R1102` | 10 kΩ | `TMC_DIAG1` | `+3.3V_SW` | as above |
  | `R1103` | 10 kΩ | `~{TMC_DRV_EN}` | `+3.3V_SW` | guarantees the power stage is **disabled** in hardware |

  Four decisions inside that table are load-bearing and easy to get wrong later:

  1. **Pulls that must read HIGH reference `+3.3V_SW`, never `+3.3V_MCU`.**
     Referencing the always-on rail back-powers `+3.3V_SW` to roughly 1.3 V through
     the TMC's protection diodes — defeating the `HV_EN` power-cycle and corrupting
     `SW_RAIL_SENSE`, and parking the buffer inputs at ~2.0 V, exactly the
     `SN74LVC125A`'s `VIH`. This was built the wrong way once and corrected.
  2. **`+3.3V_SW` is held at 0 V when off by `R401`/`R402` (2 kΩ to GND)**, which is
     what makes a pull-up to that rail a valid LOW in the off state. If the
     `SW_RAIL_SENSE` divider is ever removed, four of these resistors stop defining
     their nets.
  3. **Do not use 100 kΩ pull-downs on the TMC SPI lines**, which is what
     `docs/interface-map.md` used to prescribe. The TMC's `CSN`/`SCK`/`SDI`/`SDO`
     are `(tpu)` with `RPU` = 132/166/200 kΩ; 100 kΩ against that parks the node at
     ~1.9 V, straddling the buffer's 2.0 V `VIH` and leaving chip select ambiguous.
     10 kΩ gives 0.28 V, a clean LOW.
  4. **`~{TMC_DRV_EN}` needed `R1103` even though `DRV_ENN` has an internal
     pull-up.** Once firmware enables the bus switch, the RP2040's reset-state
     internal pull-down (`RPD` 50–80 kΩ) passes straight through the FET switch and
     fights the TMC's 132–200 kΩ `tpu`, giving 1.00–1.89 V — never a guaranteed
     HIGH, and at the worst corner a LOW, which **enables the power stage** with
     36 V on `VS`. `R1103` makes the worst case 2.75 V against a 2.31 V `V_INHI`, so
     "drivers disabled at boot" is a hardware guarantee rather than a firmware
     ordering requirement.

  Resulting levels, verified:

  | Net | Domain OFF | Domain ON, bus isolated |
  | --- | --- | --- |
  | `TMC_SPI_SCK`/`COPI`/`CIPO` | 0 V | 0.28 V (LOW) |
  | `~{TMC_CS}` | ≤0.24 V | ≈3.4 V (HIGH, deasserted) |
  | `LIMIT_SW` | 0 V | driven by `U1301` |
  | `TMC_DIAG0`/`1` | 0 V | 3.3 V (open-drain idle) |
  | `~{TMC_DRV_EN}` | 0 V | ≥2.75 V (power stage off) |

- **`AGND` was a floating four-pin island** — `J1501` pins 31/34/37/40 connected to
  nothing, and the `instrument_port` sheet had no `AGND` pin so it never left the
  sub-block. Now tied to `GND`.

- **`PMC_UART_RX_BUF` / `PMC_UART_TX_BUF` typo** fixed to `PYC_`.

- **`GP1` pull-up fitted** (`R403`). Note the reason is *idle level*, not floating:
  every RP2040 GPIO resets with its internal pull-**down** enabled, which on a UART
  RX line reads as a permanent break, and the net leaves the board through the RJ-45
  where nothing drives it when unplugged. That is also why the bus-switch B side
  needs no termination at all — the MCU's own pull-downs define it.

### Verified correct — do not re-derive

- **Power architecture.** `+5V_MCU` is ORed from USB (`D301`) and pyControl
  (`D1901`) only; `hv_to_5v_tpsm365r6` takes `+36V_SW`; four distinct rails, one
  source each, and the two 5 V rails never meet. All three diodes verified oriented
  correctly (symbol pin 1 is the **cathode**): `HV_RAW`→`HV_IN`, `VBUS`→`+5V_MCU`,
  `PYC_5V_FUSED`→`+5V_MCU`.
- **The pyControl crossover.** `PYC_DIO_A` → `PYC_UART_RX` → `GP1`, `PYC_DIO_B` →
  `PYC_UART_TX` → `GP0`, with `TX` an `Output` and `RX` an `Input` on the `mcu`
  sheet. `PYC_DIO_A`/`_B` are `bidirectional` in both the library block and the
  placed copy.
- **InstrumentPort mapping** — all eleven Rev 0 Strands land where
  `docs/interface-map.md` says.
- **TMC5130A strapping**, every pin checked against the datasheet: `TST_MODE`,
  `SD_MODE` and `SWSEL` to GND; `SPI_MODE` left open on its internal pull-up;
  `ENCN` tied to GND through `R1201` 10 kΩ exactly as the datasheet requires when
  unused; `N.C.` pins 6/31/36 to GND as required; `DNC` pins open; `VCP`, `CPI`/`CPO`,
  `BRA`/`BRB` and `5VOUT` capacitors all per the pin table. `R1203`/`R1204` are
  **0.15 Ω**.
- **`R207` = 249 Ω on `HV_SNS` is correct and needs no series resistor.** `ISNSFLT`
  is a 5.2–6.4 mA *current source*, so a fault reads 1.3–1.6 V — safely under the
  RP2040's `VPIN` absolute maximum of `IOVDD` + 0.5 = 3.8 V, and clearly distinct
  from the ≤0.37 V maximum normal-current reading. `VSNSFH` is 3.3/3.95/4.4 V at
  `VDIAG_EN` = 3.3 V, so the 1 kΩ that `docs/power.md` originally specified **would
  have driven `GP28` past its absolute maximum**. Safe upper bound is about 594 Ω.
- **Capacitor voltage ratings**, all ≤80%. Two notes: `OW-CAP-100N-0402-X5R-16V`
  declares only `ReqMinVoltage = 16V` but resolves to LCSC C162178, a **100 V** X5R
  0402, so the TMC's `VS` bypass caps `C1209`/`C1210` are rated by vendor mapping
  rather than by requirement — worth switching to a part whose requirement states
  the rail voltage. `C1213`/`C1214` are 100 µF **50 V** on 36 V (72%), which with no
  TVS fitted is a bench-measurement item.
- **`R601` 7.87 kΩ** pulls `~{BUS_SW_EN}` high to `+3.3V_MCU`, so the bus switches
  default to isolated at reset. **`R1601`/`R1701`/`R1801` 10 kΩ** pull
  `~{INSTR_BUF_OE}` high, implementing exactly what the `SN74LVC125A` datasheet
  requires: "to ensure the high-impedance state during power up or power down, OE
  should be tied to VCC through a pull-up resistor".
- **13 of the 14 placed design-block copies are byte-identical to their library
  sources.** The exception is `tmc5130`, and the board is the correct one — see
  "Carry into layout" below.

### Checked and explicitly **not** defects — do not chase these

- **`X1201` pin 1 (`Tri-State`) left open.** The ECS-2520S pad table states
  "High or NC → Active". Datasheet-sanctioned. An earlier review called this a
  defect; it was wrong.
- **`RUN`, `SWCLK` and `SWD` unconnected.** RP2040 `RUN` has an internal 50–80 kΩ
  pull-up and the datasheet permits leaving it open or tying it to `IOVDD`, so this
  is an access limitation, not an electrical defect. **Deferred to a future board
  revision by explicit decision, 2026-08-17.** The cost is no debugger during
  bring-up and BOOTSEL recovery requiring both USB and pyControl unplugged.
- **`~{TMC_DRV_EN}` relies on `DRV_ENN`'s internal pull-up for its fail-safe
  direction** — "the power stage becomes switched off when this pin becomes driven
  to a high level". `R1103` now backs that up in hardware.
- **`U901` `BOOT`/`SW` unconnected** (bootstrap capacitor is internal);
  **`U1201` `SPI_MODE` floating** (internal pull-up = SPI, matching `SD_MODE`=0 and
  `SWSEL`=0); **`U1201` `AIN_IREF` floating** (`GCONF.I_scale_analog` resets to 0);
  **`R1805.2` dangling** (spare 12th buffer channel, input grounded); **`J1102`
  pin 2** (reserved index, NC-flagged); **`J301` SBU1/SBU2**; **`J1901` pins
  3/5/7/8**; the TMC `DNC` pins; spare RP2040 GPIOs; the LDO `NR` pins.
- **No MCU-side termination on the bus switch.** Every RP2040 GPIO resets with its
  internal pull-down enabled, and the switch's A/B ports are FET pass gates with no
  logic input, so nothing floats there.
- **`~OE` is not a substitute for terminating a buffer input.** `ΔICC` is 500 µA
  typ / 5 mA max per partially biased input, independent of `OE`, against 40 µA max
  for the whole device with valid levels. This was proposed and rejected.

### Carry into layout — decisions, not blockers

- [ ] **`U603` and `U604` are entirely unused; `U602` uses 1 of 8 channels.** Three
  QFN-20 packages plus three decoupling capacitors of board area for seven signals.
  The cheapest moment to drop them is before placement, by moving `TMC_DIAG1` onto
  one of `U601`'s two free channels. Note the counter-argument no longer holds: the
  unused channels have their **MCU-side pins tied to GND**, so the reserved rev-1
  DAC channels are not pre-wired and rev 1 must edit the block regardless.
- [ ] **Re-placing `tmc5130` reverts the shunt — reset them by hand afterwards.**
  **Rewritten 2026-09-08; the previous instruction ("fix the library down to
  0.15 Ω") is reversed and must not be reinstated.** The board has
  `R1203`/`R1204` = **0.15 Ω** and `kicad-libs` now ships **0.12 Ω deliberately,
  as a per-motor placeholder** — see that repo's plan → **`tmc5130` shunt
  policy**. So a re-place *will* silently revert them, and the fix is on this
  side: set them back to 0.15 Ω (`OW-PASS-RLH12FTCR150`) and confirm `vsense` = 1.
  The old "25% over the intended 0.679 A RMS" figure is wrong twice over: the
  overshoot is **+21.4%** and 0.679 A is a superseded driver setting, not the
  motor's rating. Correct reference point is **0.421 A RMS at IRUN 17**.
- [ ] **Placement intent lives in the library blocks' `.kicad_pcb`, not in ours.**
  `C1201` is `X1201`'s bypass (1.64 mm pad-to-pad) and `C1204` is the TMC's
  `VCC_IO` bypass (3.04 mm). "Update PCB from Schematic" will not bring that across.
  Also keep `BRA`/`BRB` short to their sense resistors, and `VCP`/`CPI`/`CPO` tight,
  per the TMC pin table.
- [ ] **`R1903` is a polyfuse position fitted with a jumper.** The block's own note:
  "R29003 IS A POLYFUSE POSITION, NOT PROTECTION... Populate a 1206 PPTC,
  250-500 mA hold." Port 5 V is a shared 1.0 A that also feeds the pyControl
  controller's own logic regulator with no per-port fuse, so a fault here can reset
  the experiment controller. Either source the PPTC or accept the jumper and record
  it. There are no test points either side, so a tripped PPTC could not be diagnosed
  in circuit.
- [ ] **No test points exist anywhere on the board**, against roughly a dozen that
  `docs/interface-map.md` calls for. Decide whether they are schematic symbols (add
  before layout so the netlist carries them) or layout-only pads. The `SWSEL` pad it
  asks for is moot — `SWSEL` is tied directly to GND with no net.
- [ ] **The bus switches run from `+3.3V_MCU`,** whereas the `SN74CB3Q3245` part
  note in `kicad-libs` says to "power from the switched target-domain 3.3-V rail so
  Ioff provides isolation at VCC=0". As built, isolation depends on the MCU holding
  `~BUS_SW_EN` high, which `R601` makes the reset default. Deliberate divergence;
  reconcile the note or the rail.
- [ ] **Two unrecorded TMC deviations to sign off.** `R1202` = 10 Ω sits between
  `+5V_SW` and `5VOUT`, where the datasheet describes 2.2–3.3 Ω between `5VOUT` and
  `VCC`; and `VSA` is on `+5V_SW` where the datasheet says "normally tied to VS".
  Both are benign — `VCC` is supplied externally so the internal regulator idles,
  and the sequencing rule "VCC comes up before or in parallel to 5VOUT or VCC_IO" is
  satisfied — but neither is recorded as a decision.
- [ ] **The `SN74LVC125A` has no `Ioff`** and TI does not specify its leakage at
  `VCC` = 0. `VI` absolute maximum is −0.5 to 6.5 V *absolute*, not VCC-referenced,
  and `IIK` is specified only for `VI` < 0, so there is no input clamp to VCC and
  gross back-power is unlikely — but it is unspecified rather than guaranteed.
  Measure `+3.3V_MCU` with 36 V applied and both USB and pyControl unplugged at
  Gate B.
- [ ] **The encoder chain has no ESD device**, contrary to the "filtering and ESD"
  description in `docs/design-block-map.md`. The 4.7 kΩ series and 470 pF give some
  protection and the `SN74LVC2G17` has internal clamps. Decide and record.

## Milestones

1. ~~Scaffold the repository and write the design record.~~ **Done 2026-08-12.**
2. Answer blocking items 1-5.
3. Prove `hv_input_36V_terminal_2pos_5p08_protected` in a scratch project with
   ERC. It has never been placed on any board.
4. Compose the schematic from existing `kicad-libs` blocks, in the order in
   `docs/rev0-plan.md`.
5. ~~Design the two sections Rev 0 needs that do not exist as blocks: the
   pyControl port boundary and the debounced limit input.~~ **Done 2026-08-15
   and 2026-08-16**, both with saved PCB layouts, both still project-local
   pending bench verification. The event BNC group and the DAC output section
   move to rev 1 with the functions they serve.
6. Freeze the GPIO allocation and the instrument overlay against the schematic.
7. Run ERC/DRC, generate fabrication outputs, order.
8. Bench bring-up against Gates B through D. The 36 V transient measurement at
   the TMC5130A `VS` pins is the one that justifies or condemns the supply
   choice.
9. Native pyControl integration against Gate E, adapting
   `pump_controller.py` as the device-class template.
10. Record results in `docs/bringup-log.md`, against the board serial.

## Verification

Ready for active PCB work when:

- ~~the schematic is electrically sound~~ **done 2026-08-17** — ERC clean at every
  severity, zero undefined cross-domain nets, netclass patterns cover every
  current-carrying net;
- the motor part is identified, and the encoder's CPR and maximum shaft RPM are
  known well enough to confirm the `C802`/`C803` filter value;
- ~~the DAC logic-level question is settled~~ **deferred to rev 1**;
- the bulk-capacitance placement and snubber footprint are decided;
- ~~the `+3.3V_MCU` source and the switched `VCC_IO` rail are decided~~
  **done 2026-08-13**;
- ~~the Guix pin, Makefile, and KiCad scaffold exist~~ **done**; `make validate-db`
  still to be run once in the managed shell;
- Gate A items in `docs/validation-plan.md` have explicit status.

## Progress Log

- 2026-09-17 (latest): **schematic complete and ERC-clean; all fourteen v1.0
  design blocks error-free; layout still not started.**
  - **7 root sheets, 241 nets, ERC zero errors.** PCB at 57 footprints, 0 traces,
    0 vias, 4 zones — Update PCB From Schematic has not been run since any of this
    landed. Run ERC from `make kicad-edits`: through the MCP server it reports
    ~240 violations that are all `lib_symbol_issues`/`footprint_link_issues`
    because `ORB_WEAVER_KICAD_LIBS` does not resolve in that process.
  - **The four schematic defects from 2026-09-16 are all closed.** The rails now
    cross the `mcu` boundary (`+3.3V_MCU` one net of 44 nodes where it was 34
    trapped plus a 1-node orphan; `+3.3V_SW` one net of 18) and the stale
    `SW_RAIL_SENSE` pin is gone; `R1107`'s pull-up is connected so `~{TMC_CS}` has
    its termination; `HV_LATCH` is wired `GP24` to the HV block's `LATCH`; and 31
    no-connect flags cover the unused `ISO` and raw `GPIO` pins, with ERC
    severities untouched.
  - **The digital-50 DUT block is placed** — `J1301` plus `U1301`-`U1304`. All 26
    assigned channels verified at pad level by cross-referencing the block's
    internal `DIGn`→buffer-pin map against the board netlist. **Note that
    `get_sheet_info` reports `component_count: 0` for `instrument_port`** because
    the block is a sub-sheet; that reads like "not placed" and is not.
  - **The three phantom pyControl signals are retired**, taking footnote 8's
    offered choice: `DIG4` and `DIG5` join the four spares as explicit ground
    ties, so six of 32 strands are tied and no `LV541A` input floats.
  - **`~{BUS_SW_EN}` has a read-only monitor port** on the combined MCU block and
    reaches `DIG27`. The net still has exactly its six nodes, so the port is a
    declaration not a second driver, and because it is `output` on both sides of
    the sheet boundary ERC catches any board that tries to drive it.
  - **`docs/interface-map.md` instrument-port section rewritten to one table.**
    The 40-pin overlay and its dependent subsections are deleted rather than kept
    alongside the new map; the remaining pinout is 32 `DIGn` rows with no ground
    rows, columns `Strand | Pin | Bank | Board net | Tap | State`, one row per
    sheet pin. `J1501` is now the Hirose `FH12-50S-0.5SVA(54)`. Net effect 140
    insertions, 480 deletions. **The `#### mcu Sheet Pins` table is still stale**
    and should be regenerated from the schematic.
  - **Design rules fixed here too, committed as `ff081ff`.** Same root cause as
    `../kicad-libs`: an unconditional `(constraint clearance (min 0.10mm))` DRU
    rule was replacing every netclass clearance, so the effective value was
    0.10 mm project-wide. Fab floors moved to Board Setup (`min_clearance` and
    `min_track_width` 0.0 → 0.1 mm), both unconditional rules deleted, and
    netclass patterns 124 → 130 to cover `*/+36V`, `*/+12V_FILT` and the
    `*/BMA1`-style bridge names. **`rule_severities.clearance` stays `error`
    here** — the advisory treatment applies only to the authoring project. Since
    the PCB has no traces, none of this has been exercised on this board yet.
  - **Landmine: `../kicad-libs`'s `tmc5130` still carries 0.12 Ω shunts** against
    this board's 0.15 Ω with `vsense = 1`. That block now passes its own checks,
    which gives no protection — the shunt is a value, not a rule. Fix upstream
    before placing, and then the "never re-place `tmc5130`" rule can be retired.
  - **Two improvements proposed and not applied**, both cheapest before layout:
    regrouping four instrument-port pairs so no SPI clock sits beside its own data
    and I2C is not split across a ground (hygiene, not a fix for an observed
    problem — coupled amplitude is tens of millivolts); and landing `PG_5V` and
    `PG_12V` on two of the six ground-tied strands now that all four `hv_to_*`
    blocks expose `PGOOD`. The bank assignment is already correct and should not
    change.
  - **Smaller items found and left open:** `instrument_port` names two sheet pins
    `DAQ_SCL`/`DAQ_SDA` where the nets are `DAC_*`; `ANGLE_OUT_MON` is a one-node
    net with no destination; `/motor_encoder_switch/tmc5130/SWSEL` is a one-node
    net where the docs claim a hard GND tie.

- 2026-09-08, final: **scope narrowed to v1.0-only, then the `RUN` switch put
  back on evidence.**
  - **Narrowing removed both remaining regression traps for free.** Not
    re-placing `tmc5130` means the shunt can never revert; not re-placing
    `rp2040_gpio_isolation_sn74cb3q3245` means its 6 unconnected-copper errors
    never reach the board. Verified the isolation block already exposes **all 30
    channels** as `GPIO0`-`GPIO29` / `ISO0`-`ISO29` port pairs, so
    `~{BRAKE_FAULT}` needs board wiring only — no block edit, no re-place. **Zero
    traps left on this board.**
  - **`~{BRAKE_FAULT}` kept** (user agreed): ~2 parts, and without it a brake
    current-ceiling event is invisible to both the MCU and the capture on first
    hardware.
  - **`RUN` switch restored to Required**, and the deciding fact was already in
    this repo: the `STATUS` hang of 2026-09-03 left the board unable to honour
    the 1200 baud reset touch, so recovery took BOOTSEL held through a power cycle
    with **both** cables out. It costs no new BOM line (`SW501`'s `C7185056` line
    just goes to quantity 2), no new footprint, no new symbol — and it is the only
    cut item that cannot be added later without a respin. The debug connector and
    SWD pads stay cut.
  - **Paired firmware task opened** in `../mouse-joystick-firm/.agents/PLANS.md`:
    enable the RP2040 hardware watchdog. **They are not substitutes** — a watchdog
    reset does not enter BOOTSEL, so it makes the just-flashed-something-broken
    case harder to escape, which is exactly the case `RUN` + BOOTSEL covers.
  - **Correction to an earlier item this session:** the claim that
    `../mouse-joystick-firm`'s AGENTS.md still carries `IRUN = 28` was wrong. It
    was fixed 2026-09-02 and already reads `IRUN <= 17`. **Only this repo's
    `docs/rev0-plan.md` is stale**, in five places.

- 2026-09-08, latest: **v1.0 costed against stock — buy nothing — and the
  on-board debug MCU rejected.**
  - **Nothing is short.** Whole-BOM model, not part by part: **302 placements over
    81 lines**, every line mapped, none at zero stock, tightest coverage **42
    boards**. Table and method in *Purchases before layout, not after*, which was
    rewritten; **four of its entries were stale in the safe direction**, including
    `DAC80501ZDGSR` at 98 in stock rather than 50 and `USBLC6-2P6` at 1002 against
    an August warning that it capped the build at ten boards.
  - **One real purchase remains — the 1206 PPTC — and it is blocked on sizing, not
    on money.** No fuse, polyfuse or PPTC exists in the catalog at all. Size the
    hold current against v1.0's load first. `SMBJ40A` and the 3.3 V RRIO op amp are
    both gated on v0.3 measurements; ordering either now is buying ahead of the
    data.
  - **If the build becomes 25 boards rather than 5**, top up `ADS8689IPWR`,
    `INA821IDR`, `REF5010AIDR` (all at exactly 50) and `DAC80501ZDGSR` (98) before
    layout — half-consumed with no rework margin, and the expensive lines.
  - **No SWD probe on hand for either candidate footprint.** Land the pads anyway
    (Tag-Connect TC2030-style, zero BOM lines) and buy a probe separately — any
    spare RP2040 running `debugprobe` is a CMSIS-DAP probe, so this is ~$4 rather
    than a board decision. The `RUN` switch is now split from the connector so it
    is not held up.
  - **An on-board debug MCU, and a debug FFC port, are both rejected** — new
    section *Why an on-board debug MCU was rejected*. Decisive point beyond the
    duplication with the InstrumentPort: `docs/instrument-strategy.md` makes
    observe-only a deliberate safety property, and a permanently populated debug
    MCU is exactly the drive path that section forbids as a normal experiment
    arrangement. The surviving gap is **HIL stimulus**, which belongs in a separate
    bench-only FFC adapter board if it is ever wanted.

- 2026-09-08, later: **the `tmc5130` shunt moved from a library fix to a
  board responsibility, and four stale items closed against measurements this
  repo already had.** Plans only; no KiCad files and no docs touched. The
  companion entry in `../kicad-libs/.agents/PLANS.md` carries the shunt
  derivation.
  - **`R1203`/`R1204` stay 0.15 Ω with `vsense` = 1, and that is now this repo's
    job.** `kicad-libs` keeps 0.12 Ω as a deliberate per-motor placeholder. Two
    places in this file said "fix the library down to 0.15 Ω"; both are rewritten,
    and the instruction is reversed rather than softened.
  - **The old "25% over the intended 0.679 A RMS" was wrong twice.** The overshoot
    is **+21.4%**, and 0.679 A is a superseded driver setting rather than a motor
    rating. The correct reference is **0.421 A RMS at IRUN 17**.
  - **The dangerous stale number is in the docs, not the hardware.** `IRUN = 28`
    still sits in `docs/rev0-plan.md` (the firmware's AGENTS.md was already
    corrected 2026-09-02) —
    0.679 A RMS on the fitted 0.15 Ω, which is 1.61× the conservative reading of
    the motor's 0.6 A/phase and 1.13× even the equal-heating reading.
    `docs/bringup-log.md` flagged it on 2026-09-02 and the two docs were never
    updated. Now a Required task.
  - **Both Blocking Items are answerable and were left open by bookkeeping.** The
    motor has been identified since 2026-09-02 (Lin Engineering
    **WO-208-13-01D**) and the encoder is an **E4T-1000** with 1000 CPR
    bench-confirmed. The purchase list still called both "still open and still
    blocking"; the milestone list still gated on them. What the motor number did
    *not* settle is whether 0.6 A is RMS or peak — Lin does not say — so that
    survives as the IRUN 17 versus 24-25 choice.
  - **The `C802`/`C803` encoder filter is closed on paper, no scope needed.** At
    1000 CPR the 470 pF corner of 44.9 kHz is reached only at **2694 RPM** at the
    motor shaft; bring-up ran at **6 RPM**. The encoder's own 100 kHz / 6000 RPM
    ceiling binds first. 470 pF is correct.
  - **`docs/power.md`'s 5 V budget still reads "Unknown — the encoder part is not
    identified".** Fill in **42 mA worst case** (the E4T's `CPR > 500` branch:
    34 mA typ / 42 mA max, output drive down to 5 mA).
  - **A measurement was sitting behind the wrong gate.** The coil-current and
    case-temperature reading that settles IRUN needs **v0.2**, not v0.3 — the
    motor and driver path are unchanged and two boards are in hand. Added to the
    bring-up list with the numbers that make it matter: 2.31 W of copper loss at
    0.421 A, 4.68 W at 0.600 A, in an 82 g NEMA 8 with a **60 °C datasheet case
    maximum** against a 50 °C ambient maximum. That 60 °C figure contradicts the
    Class B (130 °C) winding insulation on the same page.
  - **v1.0 needs no new design blocks.** All 36 exist, `hv_to_12v_tpsm365r6`
    included. Two regression traps remain, not three.

- 2026-09-08: **v0.3 test plan and v1.0 change list opened** (the two
  sections at the top). No KiCad files touched. Four `../kicad-libs` design docs
  were updated; that repo's `.agents/PLANS.md` has the matching block-work list.
  What changed in the picture:
  - **The brake's pass device is a 3 V-class part.** `V_GS(th)` = 2.4 / 3 / 4.0 V
    from `../kicad-libs/tmp/BUK7D36-60E.pdf`, so worst-corner gate margin on a
    5 V rail was 90 mV with a −7.5 mV/°C tempco. **Resolved by moving the brake's
    loop amplifier to 12 V**, which the board is already adding a
    `hv_to_12v_tpsm365r6` for. The part stays; the margin did not.
  - **Decided: no board-exiting analog signal may exceed 3.3 V**, so a pyControl
    MCU pin cannot be damaged by a direct connection. Implemented as a ÷2 divider
    per output, in-block. **The torque channel was believed exempt and is not** —
    verified from the block netlists, its ceiling is set by `U37005`'s 5 V rail,
    not by the ÷3 attenuator, so a buffer fault puts ~4.95 V on the BNC. Same for
    the angle buffer, `BRAKE_ISENSE`, and both monitor taps. The `TPD1E05U06` on
    each output is a 5.5 V-working ESD part and does not bound a DC fault.
  - **The pin budget is not the constraint it looked like.** Nine GPIOs are free;
    v1.0 needs six. The real squeeze was the ADC, and `~{HV_FAULT}` is a digital
    input sitting on `GP29`/ADC3 — moving it frees an ADC for `BRAKE_ISENSE` at
    no cost. So the pyControl event lines can be dropped because the researcher
    does not want them, not under pin pressure.
  - **A `RUN` reset switch is in for v1.0**, in the `rp2040` block along with
    exposing `SWCLK`/`SWD`. Verified from the netlist that a warm reset is safe:
    `HV_EN` releases into `R1904`'s 10 kΩ pull-down so `+36V_SW` drops, and
    `~{TMC_DRV_EN}` pulls up to `+3.3V_SW` through `R1103` so the driver disables.
  - **Hard-wired fault signalling is deferred**, at Peter's call — test v1.0 and
    the new blocks first. The RJ-45 investigation that closed the "can it go on a
    spare pin" question is written up in the v1.0 section's *Deferred* subsection
    so it does not have to be repeated.
  - **`torque_bridge_0_3v3_ina821` is not as finished as it looked**: the block
    has no `.kicad_pcb` and 114 unscrubbed vendor fields. Placing it today would
    bring the netlist and none of the layout.

- 2026-08-31 (latest): **Rev-2 brake block schematic drawn and netlist-verified in
  `kicad-libs`** — 47 parts, 26 named nets, no floating pins. Not laid out, not
  bench validated. Two consequences for this board:
  - **The pass device is final at 60 V (`BUK7D36-60EX`) with no alternate**, so the
    brake zone needs **one** land pattern, not two. The 80 V `BSC072N08NS5ATMA1`
    was rejected on gate-drive headroom.
  - **The `+36V_SW` ringing measurement no longer chooses the brake FET.** This
    board's own TMC5130A limit is the binding one: 49 V absolute maximum with an
    inductive load is 80% of the brake FET's 60 V rating. What the measurement
    decides is whether to populate a **TVS at the 36 V entry**, which would protect
    the driver and the brake stage together. Recorded in `docs/power.md`.
  Brake-zone area is now known from the drawn sheet: 36 small passives, three
  SOT-23-5 amplifiers, a VSSOP-10 DAC, a DFN2020 pass device, two SOD-123FL
  diodes, an X1SON clamp, two 0603 ferrites, one 2-position 3.5 mm **vertical**
  terminal, and **no electrolytic**. Leave pads for an RC snubber from the
  pass-device drain to GND. Updated `docs/design-block-map.md` and `docs/power.md`.
- 2026-08-31: **Rev-2 brake driver design settled in `kicad-libs`, and
  the InstrumentPort allocation changed as a result.** The block is
  `brake_current_sink_0_49ma_dac80501` — renamed from
  `b5z_brake_current_driver` — a DAC-programmed linear current sink. Full
  specification, values, BOM, and open items:
  `../kicad-libs/docs/brake-current-sink-design.md`. **The schematic is not
  drawn and nothing is bench validated.** What this board needs to know:
  - **`DIG11` becomes `BRAKE_CS`, not `BRAKE_DIM`.** There is no PWM in the
    design, so a `BRAKE_DIM` net does not exist in any revision. The DAC chip
    select is the truthful equivalent of a brake-command edge, and with
    `DIG9`/`DIG10` already carrying the shared DAC `SCK`/`COPI`, one capture can
    now recover both the commanded angle *and* the commanded brake current.
  - **`AIN1_P/N` resolved to `BRAKE_ISENSE`**, 0-2.01 V through 249 Ω, needs a
    >=100 kΩ load, floor about 25 mV. `AUX_ANALOG_OUT` loses the slot; it was
    already unpopulated. The "must be low-side or ground-referenced" constraint
    is satisfied by construction — the sink is low-side, so no high-side node
    exists to put on the connector.
  - **`~{BRAKE_FAULT}` on `DIG12` is a continuous limiter output, not a latch**,
    and it arrives already at 3.3 V logic from the block's own optional
    `SN74LVC2G17`, so it needs a route but not an `SN74LVC125A` channel.
  - **Rev-2 GPIO cost dropped from about 6 to about 4.** The brake side is 1 GPIO
    plus 1 ADC, because both DACs share one write-only 3-wire bus.
  - **The 36 V decision is vindicated and now quantified.** The sink needs at
    least about 31 V for 49 mA through a 605 Ω hot winding; 36 V −5% leaves 4.2 V
    of compliance and 36 V +5% costs 0.71 W in the pass device. A 24 V rail could
    not drive the brake at all. Propagated to `docs/relationship-to-twin-axis-board.md`.
  - **New load-budget rows:** 48.8 mA DC on `+36V_SW`, about 3 mA on `+5V_SW`,
    about 2 mA on `+3.3V_SW`. **No electrolytic** in the brake zone — the 150 µF
    63 V can was sized for the dropped `LM3404HV` fallback.
  - **One measurement this board owes rev 2:** `+36V_SW` maximum and ringing at
    the future brake-stage location with the TMC5130A driving. The pass device
    sees the full rail whenever the brake is off, so this is what decides between
    a 60 V `BUK7D36-60EX` and the 80 V `BSC072N08NS5ATMA1` DNP alternate.
  Updated `docs/design-block-map.md`, `docs/interface-map.md`, `docs/power.md`,
  `docs/rev0-plan.md`, `docs/prior-art.md`, `docs/instrument-strategy.md`, and
  `docs/relationship-to-twin-axis-board.md`.
- 2026-08-31: Bumped the opt-in local KiCad overlay
  (`.guix/local-modules/orb-weaver/kicad-local.scm`) from 10.0.5 to **10.0.6**,
  matching the same bump in `kicad-libs`; the two overlay modules stay
  byte-identical. KiCad, `kicad-doc`, and the symbol, footprint, 3D model, and
  template libraries all move to the `10.0.6` tag, with `kicad-templates`
  keeping its hash because that tag points at the same commit as `10.0.5`. The
  pinned Guix channel carries 10.0.5 (README and AGENTS still claimed 10.0.4),
  so the plain targets stay on 10.0.5 and only the `*-local` targets see
  10.0.6. Channel pins were deliberately left alone. Committed fab outputs
  under `fab/` were generated by 10.0.5 and are unchanged; a future
  `make fab-local` will stamp 10.0.6 into the Gerber headers.
- 2026-08-21: Generated the v0.2 JLCPCB fabrication release after the
  corrected Molex 43860-0001 RJ45 footprint was propagated through
  `kicad-libs`, the pyControl design block, and this board. ERC and DRC both
  report zero violations and DRC reports zero unconnected pads. The release has
  all four copper layers (`F.Cu`, `In1.Cu`, `In2.Cu`, `B.Cu`); the drill report
  reflects the corrected RJ45 geometry with eight 0.89 mm plated signal holes
  and two 3.25 mm unplated locating holes. The strict JLCPCB BOM resolves all 52
  grouped rows / 142 unique physical designators, exactly matching 142 unique
  placement rows with no missing or duplicate references. The Gerber-only
  upload archive contains 14 files and has SHA-256
  `fc628d4e5b39820e8a8128eaa3fcecd050a2dda82fce49c02ae428a683cf1976`.
  The channel-pinned `orb-weaver-kicad-fab` was not used for the final package
  because it emitted only the outer copper layers; the final release used the
  current helper from the sibling `kicad-libs` checkout, which derives all
  enabled copper layers from the board.

- 2026-08-17: **Third pre-layout review. The schematic is cleared for
  layout.** ERC clean at every severity, 142 components, and — the check that
  actually mattered — **zero undefined cross-domain nets**, verified by walking the
  flattened netlist against the TMC5130A, RP2040, SN74LVC125A, SN74CB3Q3245,
  TPS1HTC100-Q1 and ECS-2520S datasheets. Both prior blockers are closed:
  `TMC_DIAG1` now crosses on a matched `U602` channel pair (all 32 audited), and
  netclass patterns went 108 → 124 so the 36 V rail, both 5 V rails, both 3.3 V
  rails, the four motor phases and `BRA`/`BRB` no longer route at 0.2 mm.
  Nine board-level termination resistors were added, and the reasoning behind which
  rail each references is the most transferable thing in this review — see the
  four numbered notes under "Closed this session". Three earlier findings were
  **retired as wrong** after reading the datasheets: `X1201`'s open `Tri-State` pin
  is explicitly permitted, `RUN` floating is safe on its internal pull-up, and
  `HV_SNS` needs no series resistor because `SNS` is a current source. One genuinely
  new defect was found and fixed — `DIAG_EN` held high keeps the TPS1HTC100's
  off-state open-load pull-up enabled, which stops the switched domain ever cleanly
  powering off; it now runs from `GP14`. `AGND` was tied to `GND`, the `PMC`/`PYC`
  typo fixed, and the `GP1` pull-up fitted. Decided, not fixed: no SWD header or
  `RUN` connection in Rev 0. Remaining items are layout decisions, not schematic
  defects, and are listed under "Carry into layout".

- 2026-08-17 (later): **Re-reviewed the schematic after integrating the new
  encoder block. ERC is now clean at every severity — 0 violations, down from 9
  errors and 129 warnings.** 133 components, no duplicate refdes, every part
  footprinted. Ten of the twelve original findings are closed, including the
  encoder input, which is now conditioned by
  `quadrature_encoder_input_5v_sn74lvc2g17` (SN74LVC2G17 dual Schmitt on
  `+3.3V_SW`, 4.7 kΩ series, 470 pF filters, 100 kΩ pull-downs on both the harness
  and output sides) with `ENCN` tied to GND through `R1201`. The rail-sense divider,
  sense resistors, `SWSEL`, shadow labels, off-grid endpoints, `PWR_FLAG`, and all
  125 symbol mismatches are resolved.
  **Two blockers remain and neither is visible to ERC** — both were found by
  walking the flattened netlist and both will keep passing ERC after any edit.
  First, `TMC_DIAG1` never crosses the isolation barrier and is shorted to GND:
  its two halves land on different bus-switch channels because the
  `rp2040_gpio_isolation_sn74cb3q3245` block in `kicad-libs` cross-maps its A and
  B labels on the two middle switches. Second, netclass patterns still match none
  of this board's rails, so the 36 V motor rail would route at Default width.
  Then seven pre-layout items: the `GP1` pull-up, five floating buffer inputs on
  the switched domain, `X1201`'s floating enable, the `PMC`/`PYC` typo, no
  reset/SWD, bus-switch direction versus the docs, and buffer grouping. Full
  detail with refdes, pin numbers, and repro commands in **Open Schematic
  Findings** above — written self-contained because `handoff.local.md` does not
  travel between machines. Sharpened Blocking Item 2: the encoder part no longer
  gates the schematic, only the `C802`/`C803` filter value.

- 2026-08-17: **Reviewed the completed Rev 0 schematic.** Ran `kicad-cli sch erc`
  plus a flattened-netlist check against `docs/interface-map.md`. **The
  InstrumentPort mapping is exactly right** — all 11 Rev 0 Strands where the
  allocation says — and the power architecture verifies clean: `+5V_MCU` fed only
  by `+5V_USB` and `+5V_PYC`, `hv_to_5v_tpsm365r6` on `+36V_SW`, the MCU LDO on
  `+5V_MCU`, the two 5 V rails never meeting, and the `DIO-A`→RX / `DIO-B`→TX
  crossover the right way round. Annotation is per-instance distinct across the
  twice-placed LDO sheet, and there are no global power symbols, so no
  cross-domain name collision is possible.
  **Twelve findings, five of them blockers**, all recorded in
  `.agents/handoff.local.md` with reproduction steps: sense resistors still
  0.12 Ω; TMC `SWSEL` floating; two `pin_not_connected` errors caused by
  off-grid wire endpoints; no `PWR_FLAG` on `+5V_MCU`; and the encoder input bare
  with `ENC_N` unwired and a 5 V-supplied encoder feeding 3.3 V TMC inputs.
  Then: `SW_RAIL_SENSE` tied bare to `GP26`, the bus switch wired A/B inverted so
  the instrument taps sit on the switched side, no pull resistors anywhere yet,
  `+3.3V`/`+5V` local labels shadowing the hierarchical names, a `PMC`/`PYC`
  typo, a buffer grouping that differs from the documented one, and 127
  `lib_symbol_mismatch` warnings.
  Corrected two design-record items that the review found the board disagreeing
  with, rather than leaving the docs lying — see Resolved.

- 2026-08-16 (later): **Cut the encoder and limit switch off the MCU, and
  retargeted the rail sense.** `ENC_A`/`ENC_B`/`ENC_N` and `LIMIT_SW` now reach
  the TMC5130A and nothing else, in every revision — the driver owns them and
  firmware reads position and homing from its registers over SPI. That frees
  `GP14`, `GP15`, `GP16`, and `GP18`, taking Rev 0 to **17 of 30** and full scope
  to **25 of 30 with five spares**. It **deletes rather than defers** the PIO
  encoder cross-check, `ENCODER_MISMATCH`, and the `GP14`-`GP16` contiguity
  constraint; the fault code is retired and its bit left permanently reserved.
  Isolated channels dropped from 8/16 to **7/12**, which makes the four-package
  bus-switch block twice the size it needs rather than a bit over — still
  accepted on schedule grounds, now recorded as a larger waste.
  **`LIMIT_SW` joined the InstrumentPort** on `DIG11`, a third swap slot
  alongside `ENC_A`/`ENC_B`, taking Rev 0 to **11 of 18 Strands** and three fitted
  buffer packages. With no GPIO copies, those taps are the board's only
  independent witnesses to what the driver is being fed; they are also the last
  ones, since nothing replaces them at rev 2. Fourth 100 kΩ pull-down added for
  `LIMIT_SW`.
  **`GP26` went from `V5_SENSE` on divided `+5V_SW` to `SW_RAIL_SENSE` on a ÷2
  divider off `+3V3_SW`** — same two resistors, end of the chain, so one reading
  confirms 36 V, 5 V, and 3.3 V. It is *not* redundant with the TMC answering
  SPI, which was the tempting argument: SPI reaches the driver through the bus
  switch the sense exists to gate, so that check is circular. `~{HV_FAULT}` does
  not cover it either — with no 36 V the switch is unpowered and its open-drain
  output reads as no fault. `HV_SNS` does cover most of it, and that is recorded
  as the fallback if the pin is ever wanted elsewhere.
  **Rev 2 may now fit on RP2040** — five spares against roughly six needed for
  brake and torque on one axis, five if `TQ_DRDY` is dropped. Recorded as an
  observation to check, not a commitment. *(Narrowed 2026-08-17: `GP14` went to
  `HV_DIAG_EN`, so it is now **four** spares against those same six. Rev 2 no
  longer fits without dropping something — recheck before relying on it.)*
  Updated `interface-map`, `rev0-plan`, `power`, `uart-protocol`,
  `instrument-strategy`, `design-block-map`, `validation-plan`, `bringup-log`,
  `README`, `.agents/AGENTS.md`, the handoff, and this file.

- 2026-08-16: **Moved InstrumentPort-40 into Rev 0 and re-allocated all 18 digital
  Strands.** The port is now justified by firmware development rather than by
  experiments — both directions of the pyControl serial link, tapped at the
  RJ-45, plus the TMC5130A SPI bus in one capture. **10 Strands live at
  fabrication, 8 allocated and unrouted, 4 reserved for the rev 2 brake and torque
  sensor** so those circuits inherit a pinout. `ENC_A`/`ENC_B` borrow two of the
  reserved slots — `DIG0`/`DIG1`, in the rev 2 buffer package so the eviction is
  as late as possible — because the driver's `X_ENC` register is the only encoder
  count Rev 0 has and the raw edges are the only way to check it decodes
  correctly. `ENC_N` went to a test pad. The new allocation also follows the v0.3
  profile's own Preferred Digital Overlays table much more closely than the
  superseded one did. Decided the three tap points — the existing
  `PYC_DIO_A`/`PYC_DIO_B` pins for the pyControl serial, A side of the bus switch
  for the TMC, driver side of the filter for the encoder — and the three 100 kΩ
  pull-downs they need, on `TMC_SPI_CIPO`, `ENC_A`, and `ENC_B`. **Proposed and
  then rejected** a connector-side pyControl tap needing two new boundary pins: a
  digital channel cannot resolve 33 mV across the block's 100 Ω, and the tap would
  have sat on the unprotected side of the ESD clamp. Regrouped the five buffer packages so each
  revision populates whole packages and no CMOS input floats: `U_A`/`U_B`/`U_E`
  fitted, `U_C`/`U_D` DNP, `U_E`'s two brake inputs GND-tied until rev 2. `GP24`
  went live with no pin moved. Corrected the
  old claim that six slots carried signals Rev 0 does not have — only the three
  DAC wires were genuinely absent. Updated `interface-map`, `design-block-map`,
  `instrument-strategy`, `rev0-plan`, `validation-plan`, `bringup-log`, `README`,
  `.agents/AGENTS.md`, the handoff, and this file. Then added a `Dir` column to
  the GPIO table and a "Signal Direction And Sheet Pin Types" section giving every
  `mcu` sheet pin its KiCad shape, what it mates with, and the far side's declared
  shape — surveyed from the blocks rather than assumed. **`kicad-libs` needs one
  small change:** `PYC_DIO_A`/`PYC_DIO_B` from `passive` to `bidirectional`. Not
  yet done: that, and every bit of the schematic and layout work itself.
- 2026-08-14: **Built three `kicad-libs` blocks and closed the pin 6 budget
  question.** Added the ORing diode to `usb2` exposing both `VBUS` and
  `+5V_USB`; created `limit_switch_debounced_input` and
  `pycontrol_behavior_port_rj45_boundary`. Traced the pyControl 5 V supply from
  the **host** side in `~/Repositories/github/pycontrol-h7-breakout`: a shared
  **1.0 A** RECOM `R-78E5.0-1.0` feeding all ten ports, the terminal block, and
  the controller's own `AMS1117-3.3`, with no per-port fuse — so blocking item 3
  is answered, and its real consequence is a **new polyfuse requirement** on this
  board's pin 6 branch. Also corrected the pinout: pin 5 is `DIO-C` on eight of
  ten ports and a `POW-C` sink driver on two, not "`SPECIAL`", and pins 3/7 are
  driver outputs, which kills the "use `POW-A`/`POW-B` for event lines"
  fallback. Decided a **hardware 10 kΩ pull-up on `GP1`** rather than relying on
  firmware. Mirrored the pinout findings into `../mouse-joysticks-pcb`.
  **Rev 0 was not finished and not ordered.** A netlist audit found the schematic
  much less connected than `README.md` claims — the `mcu` sheet has no sheet pins
  at root, so there are three separate GND nets, the isolation block is entirely
  unwired, and all 30 GPIOs are unwired. Full state and a ranked action list are
  in `.agents/handoff.local.md`, which did not exist before today despite being
  referenced here and in `.agents/AGENTS.md`.
- 2026-08-13: **Rescoped Rev 0 to the interfaces only** and rewrote the design
  record around it — `interface-map`, `rev0-plan`, `design-block-map`, `README`,
  plus scope banners on the eight docs describing deferred subsystems. Rev 0
  connects 17 of 30 GPIOs and reserves the rest at fixed numbers, so rev 1 adds
  the DAC, the PIO encoder tap, the event lines, and the InstrumentPort without
  *(counts superseded 2026-08-16)*
  moving a pin. Dropped `TMC_REF_STIM` permanently to pay for the bus-switch
  enable on `GP9`. Confirmed the whole Rev 0 connector complement is stocked in
  one 3.5 mm terminal family, and flagged that it is screw, not locking.
- 2026-08-13: **Adopted the two-domain power architecture.** The high-side switch
  is a researcher-facing reset button, so the regulator chain is fed
  *post*-switch and the MCU is fed from USB `VBUS` or pyControl pin 6 through two
  ORing diodes, never from the 36 V chain. Exactly two `5v_to_3v3_tps73733`, one
  per domain. This **reversed the pre-switch guidance** in `power.md` and
  `.agents/AGENTS.md`, and dissolved three open items at once: the `+3V3_MCU`
  source, the switched `VCC_IO`, and whether the TMC tolerates `VCC_IO` without
  `VCC`/`VS`. Confirmed pyControl pin 6 is 5 V from the syringe-pump netlist; its
  current budget stays unmeasured.
- 2026-08-13: **Rewrote the GPIO isolation rule** to follow the far end's power
  domain rather than an ad-hoc list. The pyControl UART now bypasses the bus
  switch, so the board stays reachable with the motor rail off — the earlier
  write-up had it isolated, which defeated the purpose. 8 isolated channels in
  Rev 0, 16 at full scope. Accepted the oversized 4-package block for schedule.
- 2026-08-12: Created the repository. Seeded `.guix/`, `Makefile`, agent shims,
  and an empty KiCad 10 project from `../mouse-joysticks-pcb`, renamed
  throughout. Wrote the design record: `rev0-plan`, `interface-map`, `power`,
  `design-block-map`, `relationship-to-twin-axis-board`, `pycontrol-port-pinout`,
  `pycontrol-interface`, `uart-protocol`, `encoder-analog-output`,
  `instrument-strategy`, `validation-plan`, `bringup-log`, `prior-art`.
- 2026-08-12: Derived the RP2040 allocation — 27 of 30, 3 ADC-capable spares,
  nothing descoped — and the InstrumentPort-40 overlay, which fills all 18
  digital slots. Gave the DAC SPI bus two slots so the analog angle output can be
  verified against the encoder from a single capture.
- 2026-08-12: Added `orb_weaver_smd:Texas_HTSSOP-14-1EP_..._ThermalVias_JLCPCB` to
  `kicad-libs`. The stock footprint's thermal *pad* was already correct; the via
  array was missing, and KiCad's official `_ThermalVias` variant fails this
  project's DRU with 15 `drill_out_of_range` errors (0.2 mm drills vs a 0.3 mm
  `min_through_hole_diameter`). Enlarging only the drill would breach the 0.18 mm
  PTH annular rule, so the local variant uses 0.7 mm pads / 0.3 mm drills
  (0.20 mm annular) with the y-pitch tightened to 1.0 mm to keep the outer pads
  inside the 5 mm pad. DRC-verified clean, and **assigned at source** on
  Peter's instruction: three `db/source/` CSVs plus the symbol default, then
  `make build-db`. Placed instances are copies and still carry the old footprint —
  Update Symbols from Library is needed in the two hv_input blocks, the mining
  example project, and **`tmc51x0-driver-dev-pcb`**, which places the 24 V
  barrel-jack block and will gain thermal vias on its next update. Its
  `fp-lib-table` already carries `orb_weaver_smd`.
- 2026-08-12: **Reversed the `VSA` → `VM` recommendation.** The external 5 V on
  `VSA` exists to bypass the internal linear regulator, which the datasheet
  explicitly sanctions ("a different (lower) supply voltage can be used for VSA")
  and which matters thermally: the regulator can contribute up to 1 W at 46 V, and
  even with `VCC` external it would add a few hundred mW to a package already
  dissipating ~0.45 W of bridge `I²R`. So `VSA` stays on `+5V` and **`+5V` is
  switched with `+36V`**. Cheapest way to get every ordering right: feed
  `hv_to_5v_tpsm365r6` from the **switched `+36V`**, which reverses the earlier
  pre-switch recommendation for that buck. **Consequence to plan for:** the TMC's
  `VCC_IO` cannot sit on the always-on MCU rail, because an always-on `VCC_IO` with
  a switched `VCC` is the order pin 34 forbids — so there are two 3.3 V domains,
  `+3V3_MCU` always on and a switched 3.3 V for `VCC_IO` alone. That makes the
  `+3V3_MCU` name load-bearing rather than merely descriptive. **New open item:**
  where `+3V3_MCU` comes from when only the 36 V supply is connected.
- 2026-08-12: Settled the "do not power the TMC5130A without VM" question against
  rev 1.21, and it lands on a different pin than expected. **`VCC` must come up
  EARLY**, not late — pin 34: "make sure, that VCC comes up before or in parallel to
  5VOUT or VCC_IO, whichever comes up later". So `VCC` alive with `VS` = 0 is the
  permitted direction, and the buck→LDO cascade guarantees `VCC` before `VCC_IO` by
  construction. **The real violation is `VSA`:** the `tmc5130` block ties `VSA`
  (pin 39) to `+5V` while `VS` goes to `VM`, and the absolute maximum is
  `V_VSA` ≤ `V_VS` + 0.5 V. With the buck fed pre-switch, `VSA` sits 4.5 V over that
  limit every time the motor rail is off — the boot state and the safe state. Fix is
  to tie `VSA` to `VM`, the datasheet's "normally tied to VS"; costs ~0.15 W in the
  internal regulator because `VCC` is fed externally. **Rejected switching the 3.3 V
  rail**: the MCU runs on it and drives `ENABLE`, so that is a deadlock. Also noted
  `R4002` is 10 Ω where the datasheet recommends 2.2-3.3 Ω between `VCC` and
  `5VOUT`. This is a shared change to the `tmc5130` block.
- 2026-08-12: **Withdrew the `+3V3_MCU` rename recommendation.** The pull-ups on
  `DIAG_EN`, `LATCH` and `~FAULT` must reference the rail the MCU itself uses, so
  naming the rail by its domain is correct and more precise than `+3.3V`. Only
  consequence: `5v_to_3v3_tps73733` emits `+3.3V`, so the two names need reconciling
  at board level and a netclass pattern added.
- 2026-08-12: Reviewed `hv_input_36V_terminal_2pos_5p08_protected` after the first
  round of edits (refdes renumbered; a `.kicad_pcb` now exists). **Correct:** the
  `EN` divider is now 1 kΩ series + 10 kΩ pulldown giving 3.0 V; `DIAG_EN` and
  `LATCH` are pulled to `+3V3_MCU` through 1 kΩ `RPROT`; `ILIM` = 40 kΩ;
  `SNS` = 249 Ω; diode orientation, both capacitor placements, thermal pad to
  `GND`, `NC` left open, `PWR_FLAG` on `HV_IN`, and the HTSSOP-14 PowerPAD
  footprint all check out. **Three defects:** `R27005` pulls `~FAULT` to `GND`
  instead of `+3V3_MCU`, so the open-drain output idles low and never presents a
  valid high; `HV_IN` is a local label, so the board cannot tap the unswitched node
  for the buck feed or the TVS; and `SNS` is a local label, so the current sense
  cannot reach `GP28`. **Three concerns:** `C27002` is 50 V on a 36 V rail where
  `C27001` is 100 V, and `VOUT` is specified to −60 V during inductive turn-off;
  `+3V3_MCU` will not connect to the board's `+3.3V`; and `VAA` names a pin the
  part does not have. ERC is clean — 32 violations, all library-path or
  isolated-fragment artifacts.
- 2026-08-12: Checked the six input-block edits against actual stock and the parts
  database. **Neither 470 Ω nor 24.9 kΩ is stocked**, so the values changed again:
  `R27004` → **249 Ω** (`OW-PASS-CRCW0402249RFKED`, fault level 1.29-1.59 V, even
  safer than 470 Ω would have been) and `R27003` → **40 kΩ**
  (`OW-PASS-SCR0603F40K`, `I_CL` ~1.2 A), with 2 × 49.9 kΩ in parallel as the
  25 kΩ / 1.96 A fallback. Every value now in use is stocked and already promoted,
  so the block edits carry no lead time. Confirmed the SNS amplitude loss is
  irrelevant because `I_SNS` accuracy is ±25-30% below 60 mA anyway.
- 2026-08-12: Netlist export of the `usb2` block shows it has **no ESD
  protection** — only the receptacle and two 5.1 kΩ `CC` pulldowns, with `SHIELD`
  unconnected. The 27 Ω `D+`/`D-` series resistors RP2040 needs are not missing;
  they are `R10001`/`R10002` inside the `rp2040` block. Decided to add the
  **stocked `USBLC6-2P6`** (already in the parts database as
  `Power_Protection:USBLC6-2P6` / `Package_TO_SOT_SMD:SOT-666`, 20 on hand) on the
  connector side of those resistors, rather than purchasing `USBLC6-2SC6`, which is
  the same die in SOT-23-6 and would also need a new internal part. Buy the SC6
  only if boards are hand-assembled. This matters more than usual because `VBUS`
  now feeds the logic rail and the USBLC6 clamps `VBUS` as well as the data lines.
- 2026-08-12: Resolved the four follow-up questions on the 36 V input block against
  `tps1htc100-q1.pdf`. `DIAG_EN` and `LATCH` at 3.3 V with `VS` unpowered is within
  Recommended Operating Conditions, because those pins are specified −1 to 5.5 V
  **with respect to GND** and independently of `VS`; this is unlike the `DAC8563`
  case, whose inputs are specified relative to its own `VDD`. `ILIM` and `SNS` are
  each a single resistor to ground, so the earlier "2:1 divider" advice is
  withdrawn: change `R27003` 10 kΩ → 24.9 kΩ (limit 5.3 A typ → ~2 A) and
  `R27004` 1 kΩ → 470 Ω (fault level 3.3-4.4 V → 2.44-3.01 V, under the ADC
  limit). **Both values were superseded later the same day** by the stock check
  recorded in the entry above — 24.9 kΩ and 470 Ω are not stocked; the values in
  use are 40 kΩ and 249 Ω. Corrected the current-limit figure from 4.6 A to **5.3 A typ (4-6.3 A)**;
  the earlier number used the wrong `K_CL` row instead of the datasheet's tabulated
  `I_CL` values. `LATCH` floating gives **auto-retry every 2 ms**, so tie it high
  for latch-off; clearing is by toggling `EN`, which firmware already owns on
  `GP19`. `R27001` → 1 kΩ done.
- 2026-08-12: Audited `hv_input_36V_terminal_2pos_5p08_protected` by exporting its
  netlist and checking it against `tps1htc100-q1.pdf`. Confirmed the 220 nF is the
  `VS` bypass on `HV_IN` and the 22 nF is the output bypass on `+36V`, both
  correctly placed. Found six things to change when the block is placed: the
  `EN` divider (10 k/10 k) gives only 1.65 V against a 1.5 V `VIH`; `DIAG_EN` is
  left unconnected with an internal pulldown, which disables the `SNS` current
  sense that `GP28` was allocated to read; `~FAULT` and `LATCH` are unconnected;
  `ILIM` is set to ~4.6 A; and the `SNS` fault level of 3.3-4.4 V would
  overvoltage the RP2040 ADC. Allocated `GP29` to `~{HV_FAULT}` and specified a
  2:1 divider on `SNS`. Also bounded output bulk capacitance at tens of µF, since
  the switch dissipates ½CV² charging it and the datasheet requires the design not
  reach thermal shutdown while doing so.
- 2026-08-12: **Corrected the previous "no TVS" conclusion.** It was right that no
  standard TVS protects the TMC5130A at 36 V and wrong to conclude none was
  needed: because the regulator chain taps pre-switch, `HV_IN` carries the buck's
  input capacitance, so hot-plug rings against it while the switch is off and the
  driver is disconnected. The exposed parts at that moment are the 70 V switch and
  the 65 V buck, both clampable by a 40 V-standoff part. TVS goes on `HV_IN`.
- 2026-08-12: Ran the TVS arithmetic against the actual stocked parts and
  **reversed the earlier "add a board-level TVS" recommendation.** Standard SMBJ
  parts clamp at ~1.6× standoff, so a 36 V rail needs 40 V standoff and clamps
  near 64 V, against the TMC5130A's 49 V absolute maximum; the `SMBJ40A`
  breakdown spread of 44.4-49.1 V straddles that limit. The `TPS1HTC100-Q1`
  (70 V / 81 V transient) and `TPSM365R6V5` (65 V / 70 V) need no clamp. Recorded
  that the stocked `SMBJ28A` works only on a 24 V rail, which is why the 24 V
  input block is passive-with-TVS while the 36 V block is active-with-soft-start —
  two coherent designs, not one with a missing part. Also recorded that the 36 V
  block runs happily from 24 V or 30 V as an escape hatch.
- 2026-08-12: Added the multi-source logic rail — onboard buck, USB `VBUS`, and
  optional pyControl 5 V, diode-ORed at the `TPS73733` input rather than at
  `+5V`, because ORing onto `+5V` violates the TMC5130A's 4.6 V `VCC` minimum and
  truncates the DAC's full-scale output. Allocated `GP26`/`ADC0` to a switched-rail
  sense *(retargeted from `+5V_SW` to `+3V3_SW` on 2026-08-16)* so
  firmware can detect the MCU-alive/`+5V`-dead state that USB-only power creates,
  and recorded the input-clamp back-powering hazard it introduces.
- 2026-08-12: Worked the 36 V consequences from `TMC5130A_datasheet_rev1.21.pdf`
  chapter 29: 46 V operating, 49 V absolute with inductive load, and the
  datasheet's own warning about supply ringing from stray inductance. Recorded
  that the internal 5 V regulator's 1 W limit is reached at 32 mA when
  `VM = 36 V`, so `VCC` must be supplied externally, and that the 36 V input
  block populates no TVS. Also flagged the pre-/post-switch feed point as the one
  way to make an unbootable board out of correct blocks.

## Planned Task — OBS-HW-JOYSTICK: current-board qualification and future debug/trace planning (2026-09-29)

**MCU comparison update, 2026-09-30:** the local observability plan now links the
stocked STM32G0B1CEU6 versus RP2040/RP2354B assessment and PIO UART tradeoffs.
Future pin/peripheral budget studies can proceed independently; three STM32
UART pairs coexist statically with USB/SWD, but this is not a complete joystick
allocation or qualification. PIO does not create spare physical pins. No current
board design or active QP target changes; central Context plan owns check results.

**Later 2026-09-30 update:** the Debug-Trace-20 logical pinout is accepted for
planning; see the local observability plan and owning interface contract.
Physical connector/cable, driver inhibit and new board allocation remain open.
RP2354B is now a candidate to assess against the nearly allocated RP2040 pin map;
this does not select an MCU migration or change the active RP2040 QP target.

**Direction update, 2026-09-30:** the separate optional connector and reusable
external RP2040 probe are future-revision evaluation work. This reopens only
that planning scope from the dated 2026-09-08 rejection of a second FFC port;
retain its historical rationale, the current manufactured-board restrictions
and the absence of SWD on the existing board. `OBS-PROBE` owns external-probe
qualification in `instrument-control`; a second UART bridge is not assumed.
`OBS-QP` now prioritizes RP2040/Earle Philhower Arduino, QP 7.3.4/QV only.
Previous Teensy build evidence remains valid within its recorded scope, with
Teensy hardware deferred/nonblocking; STM32G0B1CEU6 is later. No RP2040 QP
support or new hardware result is established by this target change.

The new [board observability plan](../docs/observability-plan.md) owns this
workstream's detailed queue. The [central roadmap](../../orb-weaver-context/context/experimental-system-observability-plan.md)
owns cross-repository gates and parallel workstreams. Existing dated board
decisions and measured bring-up records remain authoritative; this entry
records intent and no new hardware validation.

- [ ] Claim `.1` and prepare the actual v1.0 overlay, expected states, test
      criteria and evidence manifest with `OBS-IF`/`OBS-FW` (G0).
- [ ] On actual unit arrival/readiness, perform `.2` through the qualified
      `OBS-HW-ADAPTER` path and record measured limits per serial (G1).
- [ ] Coordinate `.3` with `OBS-FW`/`OBS-HOST` for one bounded command, bus,
      encoder/limit and physical-response capture with uncertainty (G4).
- [ ] Prepare `.4` as a separate future-revision debug/trace-connector proposal
      with `OBS-IF`, `OBS-FW` and `OBS-PROBE`; review pin mux, actual probe UART
      capability, voltage, cable and power behavior before schematic work.
      Preserve current routing and read-only 32-signal Digital-50. Defer
      combined-60 and a permanently on-board debug MCU until demonstrated need.
- [ ] Record direct researcher-to-DUT USB and separate external-probe USB,
      preventing VBUS tying and signal-pin back-powering. Two connectors are
      not evidence of isolation. Scope any future attached-monitoring session
      separately; no halt/reset/program/write authority follows from attachment.

Claim file ownership before parallel edits and reserve shared bench resources
through the central session record before measurements. Offline fixture and
documentation work can proceed in parallel. Keep current manufactured-board
qualification separate from future revision design; do not edit `kicad-libs`
for this documentation task. Report evidence-linked results and limits to the
central roadmap owner before marking a gate complete.

## Pure agent shell update (2026-10-08)

- Pinned guix-agent-tools to published commit
  `788874ea3af208c30d66bd4e415b18e35ec14c2b`; other channel pins are unchanged.
- Task manifests provide Make; the agent manifest also declares Guix so
  nested managed Make targets work without host PATH.
- Verified the final pure agent environment, basic Make entrypoints, and
  both published agent launchers using offline probes and temporary state.
- 5 task manifests passed pure runtime smoke checks.
- Validation logs: `/tmp/pure-rollout`; cross-repository summary in
  guix-agent-tools/.agents/PLANS.md. Changes left uncommitted.
