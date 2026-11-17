# GIMP protocol development

This repository contains the GIMP protocol proposal and memory-transport experiments.
Read README.md and HANDOFF.md. Preserve the user's existing edits.

- GIMP is a protocol, not a separately installable runtime mod.
- Do not add a companion UUID module, shared writable registry or hard dependency
  between providers and consumers. Use native discoverable endpoints.
- Dynamic telemetry must not be stored as changing FName tags.
- Keep experiments under experiments/ and local fixtures/diagnostics under ignored
  investigation/. Do not distribute the experiments as production mods.
- Distinguish the validated in-memory JSON mechanism from direct custom struct
  sharing, and main-menu tests from gameplay/save-load lifecycle validation.
- HMI integration remains paused until the user requests it. Do not modify its
  gameplay functionality, saves or profiles as part of protocol documentation work.
- Do not launch/restart/deploy games, commit, push or tag unless requested.
- Never commit credentials, private keys, raw crash dumps or release ZIPs.
- Generated artwork is separate; preserve assets unless explicitly requested otherwise.

Checkout location is the user-requested workspace GIMP/ path. Do not move it.
