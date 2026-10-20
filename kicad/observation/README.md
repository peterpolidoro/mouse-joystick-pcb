# GPIO connectivity evidence

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
but byte equality cannot establish equivalence. Manufactured connectivity
comparison remains open. Do not relabel this export as that comparison.

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
