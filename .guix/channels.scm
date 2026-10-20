;; Repo-local channels.scm for an Orb Weaver KiCad project.
;;
;; Keep this file pinned to exact commits for normal development. Update these
;; pins deliberately when changing the KiCad toolchain, Guix packages, agent
;; launchers, context package, or packaged kicad-libs snapshot. See
;; ../orb-weaver-context/context/guix-channel-maintenance.md.
;;
;; The default shape below matches the current Orb Weaver workflow:
;; - Guix for KiCad, FreeCAD, and common tools
;; - orb-weaver-context for current ontology and agent context
;; - guix-agent-tools for Codex and Claude launchers
;; - orb-weaver-kicad-libs for KiCad libraries, templates, and helper scripts

(list
 (channel
  (name 'guix)
  (url "https://git.guix.gnu.org/guix.git")
  (branch "master")
  (commit "dd8c1c5173a0e2e7311cb805ed0344ad971bc6e7")
  (introduction
    (make-channel-introduction
      "9edb3f66fd807b096b48283debdcddccfea34bad"
      (openpgp-fingerprint
        "BBB0 2DDF 2CEA F6A8 0D1D  E643 A2A0 6DF2 A33A 54FA"))))
 (channel
  (name 'orb-weaver-context)
  (url "https://codeberg.org/orb-weaver/orb-weaver-context.git")
  (branch "main")
  (commit "4b6ffa16b0159e095a5cb92a717284aa7d904eb3"))
 (channel
  (name 'guix-agent-tools)
  (url "https://codeberg.org/orb-weaver/guix-agent-tools.git")
  (branch "main")
  (commit "2a798cf4fd802bad9caf561a78a58bb36b2902c6"))
 (channel
  (name 'orb-weaver-kicad-libs)
  (url "https://codeberg.org/orb-weaver/kicad-libs.git")
  (branch "main")
  (commit "f1910778e44efde6884fe31c8dae74df32774f31")))
