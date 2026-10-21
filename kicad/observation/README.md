# GPIO and observation-port connectivity evidence

The [generated port map](port-map.md) covers all 32 Digital-50 paths;
`port-facts.json` is its machine-readable companion. `port-contract.json`
owns this board's expected sources, taps, domains and conditional bias
scenarios. These supplement the MCU-only export and manufacturing comparison
below.

`gpio-facts.json` checks the current source at
`3edd5d0913f2028529597f80ccd57609dc61e66b`, not a newly qualified assembly.
The MCP XML netlist export and `get_footprint_pads` for U601 agree on all
28 assigned GPIOs and two spares. `mcu-pads.json` retains the MCP pad result;
`contract.json` specifies revision, conditional switch traversal and spares.
The netlist input hash is retained in the output.

The fabrication reference is commit
`646b8f47d9d09726598ad332c43e1b4714c95272`; a `v1.0` tag is absent in this
checkout. Git object comparison on 2026-10-20 found different current versus
fabrication board/schematic blobs. That can include documentation changes,
but byte equality cannot establish equivalence.

`fabrication-connectivity.json` now supplies a separate logical-assignment
comparison, made 2026-10-20 from fresh MCP exports at
`6f1bd481ecc9188e03654acd9d5a0fd6e909e80c`. Its native schematic/PCB/project
Git blobs are unchanged from the GPIO facts' `3edd5d0` source. The frozen
fabrication ZIP at both current HEAD and the fabrication commit has Git blob
`5d264bebf578902e29e49534fc8d21fbcd76bb99`.

The frozen and current outer-copper X2 exports have identical pad groups on
every net: 1,204 numbered pads plus J1301's unnumbered, unassigned mechanical
pad. Seven net names changed; none split or merged. All 1,204 schematic pins
also agree exactly with current PCB pad net names. The report retains each
pad's old/current assignment, input hashes and the seven renames.

This checks intended logical connectivity carried in Gerber attributes,
not geometric copper connectivity, component values, assembly or electrical
behavior. It establishes the manufactured logical pin-assignment comparison
for these source revisions; it does not qualify current library blocks.
The original `gpio-facts.json` remains a current-source export, with this
comparison as its supplement.

To regenerate, export the root schematic as KiCad XML through KiCad MCP's
`export_netlist(format="kicadxml")`, then obtain U601 pads through
`get_footprint_pads`. Record the actual source revision and pad numbers/nets.
From a kicad-libs checkout, with explicit input paths:

```sh
python3 scripts/observation_facts.py \
  --netlist /path/exported-netlist.xml \
  --pads /path/mouse-joystick-pcb/kicad/observation/mcu-pads.json \
  --board /path/mouse-joystick-pcb/kicad/board.yaml \
  --contract /path/mouse-joystick-pcb/kicad/observation/contract.json \
  --output /path/mouse-joystick-pcb/kicad/observation/gpio-facts.json
```

The checker rejects wrong pad nets, GPIO assignments, missing switch pairs,
unexpected switch types and revision disagreement. Enable state is conditional;
peripheral mux, full tap-to-connector paths and reset/off-state electrical
behavior are not proved by this export.

The firmware consumes this file explicitly using
`mouse-joystick-firm/tools/check_board_pins.py`. It does not need this repository
to build or run its ordinary tests.

To repeat the manufacturing comparison, export current F.Cu/B.Cu Gerbers
with MCP `export_gerbers` into a scratch directory and the root XML netlist
with `export_netlist`. Run `kicad-libs/scripts/fabrication_connectivity.py`
with explicit `--fabrication-zip`, `--current-front`, `--current-back`,
`--netlist`, `--fabrication-revision`, `--current-revision` and `--output`.
The command and supported format are in `kicad-libs/docs/reuse-evidence.md`.
The checker does not infer commit provenance from filenames. Before recording
new evidence, verify the source tree is clean and compare the frozen ZIP's
Git blob to the specified fabrication commit:

```sh
git rev-parse HEAD:fab/mouse-joystick-pcb/mouse-joystick-pcb-jlcpcb.zip \
  646b8f47d9d09726598ad332c43e1b4714c95272:fab/mouse-joystick-pcb/mouse-joystick-pcb-jlcpcb.zip
git diff --name-only 3edd5d0913f2028529597f80ccd57609dc61e66b \
  6f1bd481ecc9188e03654acd9d5a0fd6e909e80c -- \
  '*.kicad_sch' '*.kicad_pcb' '*.kicad_pro'
```

## Complete Digital-50 paths, checked 2026-10-20

The port export uses a fresh MCP root XML netlist at
`bfd1399ff948e6fe9ef62bb6ead1295f3e2fb0ef`. Native schematic/PCB/project Git
objects are unchanged from the saved `6f1bd48` comparison above; all 1,204
numbered XML pins still match its current PCB pad assignments exactly.

Every signal contact is traced through its 100 Ω output resistor, paired
SN74LV541A input/output and optional functional-side tap. The 24 input taps
are fourteen 100 Ω and ten 1 kΩ resistors. FW_TRIG0/1 and PG_5V/PG_12V
connect directly to buffer inputs; DIG4–7 are grounded inputs. The 18 dedicated
connector grounds are checked separately. Four buffer banks use +3.3V_MCU,
with both enables held low by their own 10 kΩ pull-down.

Both `mouse-joystick-firm/instrument/mouse-joystick-v1.0.toml` and the frozen
`instrument-control/fixtures/mouse-joystick-pcb-v1.0/profile.toml` agree with
all 32 composed signal names. Their historical DAQ_SDA/DAQ_SCL names resolve
through the board recipe to DAC_SDA/DAC_SCL; the frozen profile is unchanged.
The contact profile belongs to
`board-interfaces/profiles/instrument-port-digital-50-v0.1.json`.

The contract distinguishes source domains and records all external resistor
paths to named rails. Required paths include R408/R409's switched-rail
discharge, R607's 7.87 kΩ bus-enable pull-up, PG_5V's 5 V pull-up and PG_12V's
12 V divider. Three scenarios cover MCU-on/switched-off, all-rails-on and
all-rails-off, assuming settled rails and high-impedance drivers. They are
conditional passive bias expectations, not measured reset or power-off logic.
PYC_UART_TX and HV_DIAG_EN have no external resistor path to a declared rail;
internal pulls and active driver behavior are not modeled. Unpowered buffers
provide no valid connector logic reading.

To reproduce, follow `kicad-libs/docs/observation-port-facts.md`: export XML
through MCP, then run `scripts/observation_port.py` in kicad-libs with this
directory's contract and fabrication baseline, the board/subsystem recipes,
the owner contact profile and both monitor profiles. Write the outputs here
as `port-facts.json` and `port-map.md`; never hand-edit generated reports.
The report retains all input hashes and the checked monitor hashes.

The source revisions are caller-verified provenance. Before reusing the saved
PCB baseline, check native Git objects; for this export the following produced
no differences:

```sh
git diff --name-only 6f1bd481ecc9188e03654acd9d5a0fd6e909e80c \
  bfd1399ff948e6fe9ef62bb6ead1295f3e2fb0ef -- \
  '*.kicad_sch' '*.kicad_pcb' '*.kicad_pro'
```

Current resistor values and DNP flags are schematic declarations, not a
comparison with fitted components. Peripheral mux, analog thresholds,
transition behavior, loading and geometric copper connectivity remain separate
checks. No native design, firmware, fabrication package or measured capture
was changed to produce these facts.
