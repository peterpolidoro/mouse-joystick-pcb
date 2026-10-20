# Development

Developer-facing notes for this repository: the toolchain the board was drawn
with, the repositories it was developed beside, the environment, and the
design and layout record. Nothing here is needed to open the KiCad project,
to order boards or to use the board in the rig; the README and the documents
it lists cover that.

## The Orb Weaver Toolchain

This board was drawn inside the Orb Weaver ecosystem
(https://codeberg.org/orb-weaver). Its KiCad library, `kicad-libs`, supplied
the symbols, footprints, parts database and the design blocks the board is
composed from, and its `orb-weaver-kicad-*` tools generate `docs/generated/`,
the fabrication package under `fab/`, the board manifest, the mechanical
datums and the clearance baseline.

The schematic and board carry their own copies of every symbol and footprint,
so KiCad 10 opens, edits, checks and plots the project without the library.
The project-local library tables resolve through `ORB_WEAVER_KICAD_LIBS`; when
that variable is unset KiCad reports the libraries as missing once and carries
on. Without the library the 3D viewer shows only KiCad's stock models, parts
cannot be updated from the library, and the design blocks cannot be
recomposed or refreshed. The assembled STEP model under `docs/generated/3d/`
covers the mechanical need.

The Makefile prefers a sibling checkout, `../kicad-libs`, through
`ORB_WEAVER_KICAD_LIBS`, and falls back to the packaged tools from the Guix
channel pinned in `.guix/channels.scm`.

Library identifiers such as `orb_weaver_private:tmc5130` or
`orb_weaver_smd:DRY6` appear throughout the KiCad files, the generated
documentation and the design record. They name symbols, footprints and design
blocks in `kicad-libs`; the copies embedded in this project are what the board
was built from.

## Sibling Repositories

Documentation in this repository cites files in other repositories as
`<repository>/<path>`; the Makefile and the agent guidance assume the Orb
Weaver ones as sibling checkouts (`../kicad-libs` and so on).

| Repository | Role | Where |
| --- | --- | --- |
| `mouse-joystick-firm` | The firmware this board runs, the pyControl device class, the board simulator and the protocol corpus | https://github.com/peterpolidoro/mouse-joystick-firm |
| `camera-gpio-interface-pcb` | The rig's camera interface board | https://github.com/peterpolidoro/camera-gpio-interface-pcb |
| `mouse-joysticks-mech` | STEP and glTF of the two-joystick mechanical assembly | https://github.com/peterpolidoro/mouse-joysticks-mech |
| `joystick-rig` | The rig's pyControl tasks, hardware definition and operating notes | https://github.com/sourishmukh/joystick-rig |
| `TMC51X0` | The TMC5130A driver library the firmware uses | https://github.com/janelia-arduino/TMC51X0 |
| `syringe-pump` | pyControl module reference design: the source of the behaviour-port pinout and the UART parameters | https://github.com/peterpolidoro/syringe-pump |
| `pycontrol-h7-breakout` | The pyControl H7 breakout; the host side of the behaviour port was traced from it | https://github.com/peterpolidoro/pycontrol-h7-breakout |
| `pycontrol-code` | A checkout of pyControl 2.1.1 | https://github.com/pyControl/code |
| `kicad-libs` | Symbols, footprints, parts, design blocks, documentation and fabrication generators | https://codeberg.org/orb-weaver/kicad-libs |
| `kicad-libs-nonfree` | Private store of vendor datasheets the design record cites | private, not published |
| `board-interfaces` | Interface contracts: the instrument port, the pyControl behaviour port, the identity beacon | https://codeberg.org/orb-weaver/board-interfaces |
| `orb-weaver-context` | Shared architecture and planning documents, including the PCB development plan and the rig system plan | https://codeberg.org/orb-weaver/orb-weaver-context |
| `mouse-joysticks-pcb` | The twin-axis board for the same rig, which most of this repository's documentation was derived from | https://codeberg.org/orb-weaver/mouse-joysticks-pcb |
| `tmc51x0-driver-dev-pcb` | The RP2040 plus TMC5130A validation board this board's driver section descends from | https://codeberg.org/orb-weaver/tmc51x0-driver-dev-pcb |
| `instrument-control` | Logic-analyzer observation of the rig's boards and board identification by beacon | https://codeberg.org/orb-weaver/instrument-control |
| `la5032-instrument-port-adapter` | The LA5032 adapter for the instrument port | https://codeberg.org/orb-weaver/la5032-instrument-port-adapter |
| `qp-arduino-example` | The QP/C++ port pilot; its `evidence/` directory holds the bring-up log's capture files | https://codeberg.org/orb-weaver/qp-arduino-example |
| `guix-agent-tools` | The Guix channel carrying the agent and KiCad tooling | https://codeberg.org/orb-weaver/guix-agent-tools |

The previous-generation boards and software for the same rig, cited in
`docs/prior-art.md` as `<organization>/<repository>`, are on GitHub under
`janelia-kicad`, `janelia-modular-devices` and `janelia-python`.

## Environment

Managed KiCad targets use `.guix/channels.scm` through `guix time-machine`.
Keep that file pinned to exact commits following
`orb-weaver-context/context/guix-channel-maintenance.md`.

    make help                 List the available targets
    make kicad-edits          Open the project in the managed KiCad
    make fab                  Generate the JLCPCB fabrication package under fab/
    make docs                 Regenerate docs/generated/ and the README's managed block
    make docs-check           Report whether that documentation is stale
    make test                 Check the project against the library and the manifest
    make clearance-check      Re-run DRC on a copy with clearance raised to error and diff the baseline
    make board-manifest-check Check kicad/board-manifest.yaml against the board
    make compose-check        Dry run of composing the project from the manifest
    make expand-check         Compare kicad/board.yaml with the manifest

`docs/generated/` and the block between the `BEGIN/END GENERATED BOARD
DOCUMENTATION` markers in `README.md` are written by `make docs`, and the
block between the `GENERATED BOARD MANIFEST` markers at the top of
`docs/interface-map.md` by `make board-manifest-render`. Never hand-edit any
of them.

For the interval between a KiCad release and its Guix package,
`.guix/manifest-kicad-local.scm` and `.guix/local-modules/orb-weaver/kicad-local.scm`
provide an opt-in overlay: `make kicad-edits-local`, `kicad-shell-local`,
`kicad-version-local`, `fab-local`. The module currently overrides KiCad
10.0.7 (set 2026-10-08, while the Guix update waits upstream; the same module
is in `kicad-libs`, `mouse-joysticks-pcb` and `tmc51x0-driver-dev-pcb`, bump
all four together). Reset it to plain aliases once the pin carries the
release.

## Design And Layout Record

The board is composed from fifteen design-block instances under four
board-authored sheets. `kicad/board-manifest.yaml` records every placement,
port mapping, netclass and net meaning as built; `kicad/board.yaml` with the
recipes in `kicad/subsystems/` is its source. The agent guidance in
`.agents/AGENTS.md` carries the rules for keeping them in step with the
drawing.

v1.0 was routed on four layers on 2026-09-21 with 24 mm BNC spacing; the
fabrication package in `fab/mouse-joystick-pcb/` was built from that board
and committed in `646b8f4`, and the board file has been unchanged since
`d5ae4b0`. Two assembled units were ordered from JLCPCB from that package.
The first article had a placement-rotation fault (37 of 360 parts) that the
package's per-footprint rotation correction now prevents; the bring-up log
records the diagnosis and the rework.

- [Rev 0 plan](rev0-plan.md): the design record and the Rev 0 scope decisions
- [Design block map](design-block-map.md): retired 2026-10-13; points at the generated block, subsystem and GPIO pages under `docs/generated/`
- [Relationship to the twin-axis board](relationship-to-twin-axis-board.md): why a single-axis board, and what carries over
- [Prior art](prior-art.md): the previous rig's boards, firmware and documentation
- [Validation plan](validation-plan.md): the Gates A to F sequence adapted to this board
- [Digital instrument port migration](digital-instrument-port-migration.md): the move to the 50-pin, 32-channel port
- [Instrument port tap resistors](instrument-port-tap-resistors.md): the 24 series taps and their own netclass
- [Instrument strategy](instrument-strategy.md): what the logic analyzers watch and why
- [Observability development plan](observability-plan.md): this board's slice of the cross-repository observability work
- [B5Z magnetic particle brake controller](b5z-magnetic-particle-brake-controller.md): brake requirements and prior art; its topology is superseded by the `kicad-libs` brake block
- [Brake and torque purchase plan](mouse-joystick-brake-torque-purchase-plan.md): the parts bought for the v1.0 front ends
- [Routing session handoff, 2026-09-21](routing-session-handoff-2026-09-21.md): where the routed board stood, and the measured autorouting time
- [Routing rescue, 2026-09-21](routing-rescue-2026-09-21.md) and [autoroute log](autoroute-log.md): the layout record, run by run
- [Connector access correction, 2026-09-21](connector-access-2026-09-21.md): the BNC spacing change and the regenerated package
- [HV input block schematic note](hv-input-block-schematic-note.txt): the text block that travels with the 36 V input block
- `captures/` and `evidence/`: logic-analyzer captures and timing records from the rev 0 boards; the v1.0 runs are in `mouse-joystick-firm/evidence/`

## Agent Guidance

[GPIO connectivity evidence](../kicad/observation/README.md) records the checked
current-source export consumed by firmware, its reproduction procedure and the
outstanding comparison with the fabrication revision.

`AGENTS.md` and `.agents/` carry the agent-facing guidance, plans and handoffs
for this repository. They assume the sibling checkouts above.
