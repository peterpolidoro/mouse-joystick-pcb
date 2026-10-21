# InstrumentPort Tap Resistors

**Status: implemented 2026-09-20 and verified against the exported netlist.**
This document is the build order for splitting every InstrumentPort observation
branch off its functional net with a series resistor. It is written to be
executed in a fresh session: everything needed — values, nets, owning blocks, pin
names, part numbers and the traps — is here. See
[As Built](#as-built-2026-09-20) for what actually landed and the two places the
build deviated from this specification. The generated
[observation-port map](../kicad/observation/port-map.md) now checks all 24 input
taps, 32 output resistors and connector paths against current exported
connectivity and the saved fabrication pad assignments (2026-10-20).

**Read first:** [`docs/interface-map.md`](interface-map.md) →
[InstrumentPort-Digital-50 Pinout](interface-map.md#instrumentport-digital-50-pinout),
[Where Each Signal Is Tapped](interface-map.md#where-each-signal-is-tapped) and
[Board-Level Input Biases](interface-map.md#board-level-input-biases); then
[`docs/design-block-map.md`](design-block-map.md) for the re-place rules.

## What This Changes

Today a monitored signal is one net with three or more terminals: the driver,
the peripheral, and a long run to an `SN74LV541A` input in the port block. After
this change it is two nets joined by a series resistor — a T-tap, with the
resistor in the **branch**, never in the functional path:

```
  driver ───┬──────────────── peripheral        net: TMC_SPI_SCK      (short, direct)
            │
            └──[ R ]───────── SN74LV541A input  net: TMC_SPI_SCK_INST (long, deferrable)
```

Three things this buys, in order of how much they matter here:

1. **Routing.** One three-terminal net the router must solve as a single tree
   becomes two two-terminal nets it can solve separately, prioritise
   differently, and give their own netclass. The instrument branch can be routed
   last, routed thin, or left for a later pass.
2. **Signal integrity.** 100 Ω is roughly the tap stub's characteristic
   impedance, so the branch is source-terminated and stops reflecting back into
   the functional net. It does **not** hide the stub's ~12 pF from the driver —
   that would take kΩ, which costs edge fidelity. The routing win is
   topological; the SI win is damping.
3. **Fault coupling.** The resistor limits current into a failed buffer input;
   it does not guarantee the functional net remains valid. The 100 Ω case below
   can still pull the functional signal down substantially.

## Values

**100 Ω on anything clocked, 1 kΩ on slow control and status lines.**

| Value | Internal part | JLCPCB | Symbol/footprint |
|---|---|---|---|
| 100 Ω | `OW-PASS-0402WGF1000TCE` | C25076 | `orb_weaver_passives:R_100_0402` / `Resistor_SMD:R_0402_1005Metric` |
| 1 kΩ | `OW-PASS-RC0402FR-071KL` | C106235 | `orb_weaver_passives:R_1k_0402` / `Resistor_SMD:R_0402_1005Metric` |

Both are already stocked and already on this board — the 100 Ω is the same part
the port block uses 32 times as `R1305`-`R1336` on the buffer **outputs**, so
this adds no BOM line.

### Why those numbers

**DC does not constrain the value at all.** The only current in a tap resistor
is the 541's input leakage, ±1 µA — 1 mV across 1 kΩ. This holds *only* because
every existing DC-defining pull stays on the **functional** side of the new
resistor. Move one to the tap side and you build a divider and un-define the
functional net.

**The buffer does not constrain it either.** `SN74LV541A` recommended
`Δt/Δv` is **100 ns/V at V_CC = 3 V to 3.6 V** (200 ns/V at 2.3–2.7 V, 20 ns/V at
4.5–5.5 V — the 3.3 V rail is the forgiving case). An RC edge crosses the
0.3–0.7·V_CC band at about 0.64·τ ns/V, so τ up to ~156 ns is in spec. Against
~12 pF of stub — 2 pF of 541 input plus ~10 pF of trace, from the capacitance
arithmetic in `interface-map.md` — even 10 kΩ passes. The datasheet's own
Input Considerations section recommends 10 kΩ for input networks of this kind.

**Measurement fidelity is what binds.** `TMC_SPI_SCK` is ≤4 MHz
(`docs/encoder-analog-output.md`), and the ADS8689 will take SCLK far faster if
the torque bus is ever pushed. At 100 Ω / 12 pF, τ = 1.2 ns and the 10–90% edge
is 2.6 ns — faster than the ~5 ns the 541 itself produces, so the capture is not
degraded at any rate this board will run.

**The one argument for going bigger is a failed buffer.** If a 541 input fails
shorted to ground, 100 Ω lets it drag the functional net to roughly 2.2–2.6 V
depending on RP2040 drive strength, straddling the TMC5130A's 2.31 V `V_IH`. At
1 kΩ the net holds above 3.1 V and the rig keeps running. The port is meant to
be live during experiments and `.agents/AGENTS.md` requires observation to be
"unable to affect rig behavior," so buy that decade wherever it is free — and it
is free on everything that is not clocked.

### The rule that keeps this from becoming a mess

**Never mix values inside one bus.** Any signal compared against a clock in the
capture — chip selects included — takes its clock's value, so the RC delay is
common-mode rather than skew. `TQ_CONVST_CS` at 1 kΩ beside `TQ_SPI_SCK` at
100 Ω would inject ~7 ns of manufactured skew into the one measurement worth
taking. This is why `~{TMC_CS}` and `TQ_CONVST_CS` are 100 Ω while `TQ_CAL_EN`,
which is never read against a clock, is 1 kΩ.

## The Twenty-Four Taps

Source pin names below are the **as-built** hierarchical sheet pins, read from
the schematic on 2026-09-19. `Strand` is the port channel from
[InstrumentPort-Digital-50 Pinout](interface-map.md#instrumentport-digital-50-pinout).

| Board net | Strand | Owning block or sheet | Source pin | New tap pin | Value |
|---|---|---|---|---|---|
| `TMC_SPI_SCK` | `DIG8` | `tmc5130` | `SCK` | `SCK_TAP` | 100 Ω |
| `~{TMC_CS}` | `DIG9` | `tmc5130` | `~{CS}` | `~{CS}_TAP` | 100 Ω |
| `TMC_SPI_COPI` | `DIG10` | `tmc5130` | `SDI` | `SDI_TAP` | 100 Ω |
| `TMC_SPI_CIPO` | `DIG11` | `tmc5130` | `SDO` | `SDO_TAP` | 100 Ω |
| `TMC_DIAG0` | `DIG12` | `tmc5130` | `SWN_DIAG0` | `SWN_DIAG0_TAP` | 1 kΩ |
| `TMC_DIAG1` | `DIG13` | `tmc5130` | `SWP_DIAG1` | `SWP_DIAG1_TAP` | 1 kΩ |
| `~{TMC_DRV_EN}` | `DIG14` | `tmc5130` | `~{DRV_EN}` | `~{DRV_EN}_TAP` | 1 kΩ |
| `LIMIT_SW` | `DIG15` | `limit_switch_debounced_input_vertical` | `LIMIT_SW` | `LIMIT_SW_TAP` | 1 kΩ |
| `TQ_SPI_SCK` | `DIG16` | `torque_bridge_0_3v3_ina821` | `SCK` | `SCK_TAP` | 100 Ω |
| `TQ_CONVST_CS` | `DIG17` | `torque_bridge_0_3v3_ina821` | `TQ_CONVST_CS` | `TQ_CONVST_CS_TAP` | 100 Ω |
| `TQ_SPI_COPI` | `DIG18` | `torque_bridge_0_3v3_ina821` | `SDI` | `SDI_TAP` | 100 Ω |
| `TQ_SPI_CIPO` | `DIG19` | `torque_bridge_0_3v3_ina821` | `SDO` | `SDO_TAP` | 100 Ω |
| `TQ_CAL_EN` | `DIG20` | `torque_bridge_0_3v3_ina821` | `TQ_CAL_EN` | `TQ_CAL_EN_TAP` | 1 kΩ |
| `~{BRAKE_FAULT}` | `DIG21` | `brake_current_sink_0_49ma_dac80501` | `~{BRAKE_FAULT}` | `~{BRAKE_FAULT}_TAP` | 1 kΩ |
| `DAC_SDA` | `DIG22` | **`/mcu/` board sheet** | — | — | 100 Ω |
| `DAC_SCL` | `DIG23` | **`/mcu/` board sheet** | — | — | 100 Ω |
| `HV_EN` | `DIG24` | `hv_input_36V_terminal_2pos_5p08_protected_vertical` | `ENABLE` | `ENABLE_TAP` | 1 kΩ |
| `HV_DIAG_EN` | `DIG25` | `hv_input_36V_terminal_2pos_5p08_protected_vertical` | `DIAG_ENABLE` | `DIAG_ENABLE_TAP` | 1 kΩ |
| `~{HV_FAULT}` | `DIG26` | `hv_input_36V_terminal_2pos_5p08_protected_vertical` | `~{FAULT}` | `~{FAULT}_TAP` | 1 kΩ |
| `~{BUS_SW_EN}` | `DIG27` | `rp2040_with_gpio_isolation_sn74cb3q3245` | `~{BUS_SW_EN}` | `~{BUS_SW_EN}_TAP` | 1 kΩ |
| `ENCA` | `DIG28` | `quadrature_encoder_input_5v_sn74lvc2g17` | `ENCA` | `ENCA_TAP` | 100 Ω |
| `ENCB` | `DIG29` | `quadrature_encoder_input_5v_sn74lvc2g17` | `ENCB` | `ENCB_TAP` | 100 Ω |
| `PYC_UART_TX` | `DIG2` | `pycontrol_behavior_port_rj45_boundary_vertical` | `PYC_DIO_B_HOSTRX_SDA_MISO` | `PYC_DIO_B_TAP` | 100 Ω |
| `PYC_UART_RX` | `DIG3` | `pycontrol_behavior_port_rj45_boundary_vertical` | `PYC_DIO_A_HOSTTX_SCL_MOSI` | `PYC_DIO_A_TAP` | 100 Ω |

**Fourteen at 100 Ω, ten at 1 kΩ, across seven design blocks and one board
sheet.** The pyControl tap pins are deliberately shortened rather than extended
to `PYC_DIO_A_HOSTTX_SCL_MOSI_TAP`; note the deviation in the block.

**The alphabetical crossover still applies.** `DIO-A` is this board's RX, so
`PYC_DIO_A_TAP` carries `PYC_UART_RX_INST` and `PYC_DIO_B_TAP` carries
`PYC_UART_TX_INST`. The block's own pin names (`HOSTTX`, `HOSTRX`) confirm the
direction — do not "fix" the apparent mismatch.

### Four nets get no resistor

`FW_TRIG0` (`DIG0`), `FW_TRIG1` (`DIG1`), `PG_5V` (`DIG30`) and `PG_12V`
(`DIG31`) have the port as their **only** consumer. There is no second branch to
split off, so a series resistor adds two pads and a fitting hazard and isolates
nothing. Leave them direct. `DIG4`-`DIG7` are tied to GND and have no signal.

`~{BUS_SW_EN}` looks like it belongs in that group and does not: the node it
exports is also the bus switch's own `~OE` inside the block, so the board-level
run to the port really is a stub off a live node.

## Where The Resistor Goes, And Why It May Live In The Block

**Inside the owning block, and the project's existing pull-resistor rule does
not forbid it.** The rule in
[Which sheet a pull belongs on](interface-map.md#which-sheet-a-pull-belongs-on)
— a pull goes inside a block only if the block owns the net, because two
placements parallel the pulls and halve them — is specific to **shunt**
elements. A series tap resistor cannot be halved by duplication: two placements
give two independent taps to two different port channels, which is exactly what
the twin-axis board would want. The physical argument agrees — the resistor must
sit at the tapped pin to keep the stub short and to serve as the launch point
for the long run, and only the block's own `.kicad_pcb` knows where that pin is.

**The exception is a shared net: tap inside a block only where that block is the
unique tap source.** `DAC_SDA`/`DAC_SCL` fail that test — both
`analog_output_0_3v3_dac80501` and `brake_current_sink_0_49ma_dac80501` sit on
the pair, so an in-block tap would put two resistors onto one port channel.
Those two go on `/mcu/`, beside `R406`/`R407`, which already hold the
switched-side node being tapped.

### Two traps

**Do not put the switched-domain taps in the RP2040 block.** All fourteen of
those signals pass through `rp2040_with_gpio_isolation_sn74cb3q3245`, which makes
it the convenient place to add pins — and doing so would move every tap from the
`A` side of the bus switch to the `B` side, silently reversing the 2026-08-17
decision recorded in
[Where Each Signal Is Tapped](interface-map.md#where-each-signal-is-tapped). The
taps belong at the peripheral end. `~{BUS_SW_EN}` is the single legitimate tap in
that block, because the RP2040 drives it there.

**Keep every existing bias on the functional side.** `R1101`-`R1107` in
`motor_encoder_switch`, `R901`-`R905` in `brake_torque_sensor`, `R2012` in the
torque block, `R402`/`R403`/`R406`/`R407` in `mcu`, `R1601` in the limit-switch
block. None of them moves. Each tap then inherits its functional net's defined
level through the resistor, so **no tap needs a pull-down of its own** — which
keeps the "every net reaching an `SN74LV541A` input has a DC-defining resistor"
property intact. Re-run that sweep across the split nets when the work is done.

## Naming

**Board nets take `_INST`. Block pins take `_TAP`.** A reusable block should not
name someone else's connector, and the board already has precedent for a
block-pin/board-net divergence in the `DIO_A` → `PYC_UART_RX` crossover.

**Close the overbar before the suffix: `~{TMC_CS}_INST`, never
`~{TMC_CS_INST}`.** KiCad stores the overbar markup literally in the net name, so
the braced form is a string ending in `}`.

**Corrected 2026-09-21: a `/*_INST` netclass pattern DOES match those names.**
Verified by exporting the DSN and reading the resolved class membership — all
24 nets land in `INSTRUMENT`, including all five overbar ones. The warning below
that the pattern "will not match" was wrong. The naming rule still stands on its
own merits: the bar belongs over the signal name and `_INST` is a topology tag.

Related, and the reason this matters less than it looks: **KiCad nulls
`netclass_assignments` on a pcbnew round-trip.** The 24 explicit assignments made
on 2026-09-20 were gone by the next export, leaving only the pattern. Patterns
are the durable mechanism here; explicit per-net assignment is not. Five taps are affected — `~{TMC_CS}`, `~{TMC_DRV_EN}`,
`~{HV_FAULT}`, `~{BUS_SW_EN}`, `~{BRAKE_FAULT}` — and if the pattern misses them
they fall silently to `Default`, which is the same failure that put 146 of 156
nets on 0.2 mm before the 2026-08-17 netclass fix. It also reads correctly: the
bar belongs over the signal name, and `_INST` is a topology tag, not part of what
is asserted low. Same rule for the pins: `~{CS}_TAP`, not `~{CS_TAP}`.

**`_MON` and `_ISO` are both already taken — do not use either.** `_MON` collides
with `/ANGLE_OUT_MON` and the torque block's `TQ_AOUT_MON`, two **analog**
monitor nets that a `*_MON` netclass pattern would sweep in. `_ISO` is worse: the
port block already uses `DIGn_ISO` internally for its connector-side node, and
the `Tap` column in `interface-map.md` uses `ISO` to mean the A/switched side of
the bus switch. `_INST` matches nothing on the board today — verified against all
309 nets on 2026-09-19.

**Pin electrical type: make every `_TAP` pin an `output`.** The port block's
`DIGn` pins are all `input`, and output→input is the combination all 28 channels
already run on. `passive` is the semantically purer choice for taps of signals
the block *receives* (`SCK_TAP`, `~{CS}_TAP`, `ENABLE_TAP`, …) and should also
pass ERC; if you prefer it, check ERC for "input not driven" before committing.
A board that does not use a tap places a no-connect flag on it.

## Netclass

Add one netclass — suggested name `INSTRUMENT` — with pattern `/*_INST`, and
re-check that no net matches more than one netclass, per the standing rule in
`.agents/AGENTS.md`. These nets carry microamps:

- **track width 0.15 mm** (the board's `min_track_width` floor is 0.1 mm)
- **clearance 0.15 mm** (floor is 0.1 mm)
- **via geometry identical to `Default`** — deliberately not smaller. A netclass
  that drills differently from the via actually placed triggers the KiCad defect
  documented in `scripts/import_ses.py`: a Specctra session round-trip drops the
  explicit drill and the hole grows to the netclass value, which already pushed
  seven vias under the JLCPCB 0.125 mm annular-ring floor once.

This netclass is also what makes the extra-layers question cheap later: if all
24 taps are one class, moving them to a dedicated layer pair is a layer
restriction, not a re-route.

## Execution Notes

The blocks are edited in `kicad-libs` and re-placed here by hand. Known costs,
all documented elsewhere and repeated here so they are not rediscovered:

- **`tmc5130` re-place reverts the current sense resistors.** `R1203`/`R1204` are
  **0.15 Ω** (`OW-PASS-RLH12FTCR150`) on this board and 0.12 Ω in the library.
  Fix the library to 0.15 Ω in the same editing pass, or re-set both by hand
  after every re-place. 0.12 Ω runs ~25% over the motor's 0.679 A RMS rating and
  nothing catches it — ERC and DRC both pass and the first symptom is a hot
  motor. See [`docs/design-block-map.md`](design-block-map.md).
- **Designators cascade.** Twenty-four new resistors across seven blocks will
  shift the bands again; the last two-resistor change moved the whole `20xx` band
  plus `R901`-`R903` and required reconciling 114 citations across six doc files.
  Re-check designator references in docs afterwards. `interface-map.md` line 1148
  already calls the pyControl RX pull-up `R401` while `validation-plan.md:373` and
  `rev0-plan.md:410` still say `R403`; `R401` is what is fitted. Leave
  `docs/bringup-log.md` alone — its `R403` entries are measurements from boards
  where that designator was real.
- **Never tick "Re-link footprints to schematic symbols based on their reference
  designators."** Library blocks use 5-digit bands and this board is 4-digit.
- **Some placement intent lives only in the library block's `.kicad_pcb`** and
  does not arrive through Update PCB from Schematic — copy it by hand.
- **The rip-up already happened.** Splitting a net orphans copper already on
  it, which would normally have to be measured and weighed first. As of
  2026-09-19 the board carries **0 traces and 0 vias** — the 2054 tracks and 146
  vias were deleted deliberately before this work started, so that cost is
  already paid and there is nothing to preserve.

**The 10 kΩ `PYC_UART_RX` pull-up (`R401`) does not move into the block.** The
block's boundary has no 3.3 V pin and *which* 3.3 V domain is a board decision;
it is a shunt, so the doubling rule does apply to it; and the original 2026-08-14
decision put it in the board-authored `mcu` sheet specifically "so a design-block
re-place cannot lose it" — which is the property being exercised here. See
[`GP1` Gets A Hardware Pull-Up](interface-map.md#gp1-gets-a-hardware-pull-up).

## As Built (2026-09-20)

All twenty-four taps are placed and verified from the exported netlist: each
`_INST` net carries exactly two nodes, each functional net kept its DC-defining
bias and no longer reaches a buffer directly, and every tap lands on the channel
this document assigns it. `R1203`/`R1204` still read 0.15 Ω after the `tmc5130`
re-place.

**Two deviations from the specification above, both deliberate — the text above
is kept as written so the reasoning survives:**

1. **Block pins are named `_INST`, not `_TAP`.** The rule in
   [Naming](#naming) said board nets take `_INST` and block pins take `_TAP`.
   Every block was built with `_INST` on both sides — `SCK_INST`, `ENABLE_INST`,
   `PYC_DIO_A_INST` and so on. One suffix is easier to hold than two and the
   overbar rule was followed correctly either way. **`_TAP` appears nowhere in
   the library or on the board; do not reintroduce it.**
2. **The `INSTRUMENT` netclass assigns all 24 nets explicitly** in
   `netclass_assignments`, and *also* carries the specified `/*_INST` pattern.
   The explicit assignments are what the five overbar names rely on; the pattern
   is future-proofing for taps added later. Class is priority 20, track 0.15 mm,
   clearance 0.15 mm, `Default`'s 0.6 / 0.3 via geometry unchanged, and it is
   coloured `rgb(255, 167, 38)` so the taps are visible while routing.

### As-built designators

Board designators for the tap resistors, read from the netlist. The `R` bands
shifted when the blocks were re-placed, so name these by net, not by number.

| Board net | Tap resistor | Value | Buffer input |
|---|---|---|---|
| `TMC_SPI_SCK` | `R1206` | 100 Ω | `U1302` pin 9 |
| `~{TMC_CS}` | `R1205` | 100 Ω | `U1302` pin 8 |
| `TMC_SPI_COPI` | `R1207` | 100 Ω | `U1302` pin 7 |
| `TMC_SPI_CIPO` | `R1208` | 100 Ω | `U1302` pin 6 |
| `TMC_DIAG0` | `R1209` | 1 kΩ | `U1302` pin 5 |
| `TMC_DIAG1` | `R1210` | 1 kΩ | `U1302` pin 4 |
| `~{TMC_DRV_EN}` | `R1211` | 1 kΩ | `U1302` pin 3 |
| `LIMIT_SW` | `R1602` | 1 kΩ | `U1302` pin 2 |
| `TQ_SPI_SCK` | `R2024` | 100 Ω | `U1303` pin 9 |
| `TQ_CONVST_CS` | `R2027` | 100 Ω | `U1303` pin 8 |
| `TQ_SPI_COPI` | `R2026` | 100 Ω | `U1303` pin 7 |
| `TQ_SPI_CIPO` | `R2025` | 100 Ω | `U1303` pin 6 |
| `TQ_CAL_EN` | `R2028` | 1 kΩ | `U1303` pin 5 |
| `~{BRAKE_FAULT}` | `R1820` | 1 kΩ | `U1303` pin 4 |
| `DAC_SDA` | `R411` | 100 Ω | `U1303` pin 3 |
| `DAC_SCL` | `R410` | 100 Ω | `U1303` pin 2 |
| `HV_EN` | `R510` | 1 kΩ | `U1304` pin 9 |
| `HV_DIAG_EN` | `R511` | 1 kΩ | `U1304` pin 8 |
| `~{HV_FAULT}` | `R512` | 1 kΩ | `U1304` pin 7 |
| `~{BUS_SW_EN}` | `R604` | 1 kΩ | `U1304` pin 6 |
| `ENCA` | `R1507` | 100 Ω | `U1304` pin 5 |
| `ENCB` | `R1508` | 100 Ω | `U1304` pin 4 |
| `PYC_UART_TX` | `R305` | 100 Ω | `U1301` pin 7 |
| `PYC_UART_RX` | `R304` | 100 Ω | `U1301` pin 6 |

**The connector is `J1301`, not `J1501`.** The whole `J` band was reassigned in
the same rebuild; see
[`docs/interface-map.md`](interface-map.md) for the full as-built connector map.

## Verification

1. **Netlist, not ERC.** Export the flattened netlist and confirm each of the 24
   functional nets has exactly its original terminals minus the port, and each
   `_INST` net has exactly two: the tap resistor and one `SN74LV541A` input.
2. Confirm all five active-low `_INST` names use the `~{NAME}_INST` form and that
   the `INSTRUMENT` netclass pattern matches all 24 and nothing else.
3. Re-run the "every net reaching an `SN74LV541A` input has a DC-defining
   resistor" sweep across the split nets.
4. Confirm `R1203`/`R1204` still read 0.15 Ω after any `tmc5130` re-place.
5. `make clearance-baseline` afterwards — the existing baseline predates both the
   GND pour and these parts.
