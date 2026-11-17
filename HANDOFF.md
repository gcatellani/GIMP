# GIMP protocol handoff

Updated 2026-11-17 (Europe/Berlin).

- Current direction: native discoverable endpoints with JSON payloads in memory.
  Independent provider and consumer lab mods have no type/dependency coupling.
  Live main-menu test passed typed-value reads, updates, removal and replacement;
  7265 native compiler reports, no diagnostics. Source is under experiments/.
- Save-load/world lifecycle, persistence, malformed data, production carrier cost
  and a consumer-only launch still require validation. Do not overclaim readiness.
- User requested removal of the companion runtime from disk and GitHub, preserving
  this protocol repository and its memory-only experiments. Removed runtime files,
  old packaging/counter/tests/example/docs, old linked test setups and release ZIP.
  Artwork and unrelated mods/user data retained. HMI's obsolete dependency and
  abandoned file-consumer experiment were removed; memory implementation
  remains paused. No new game launch for cleanup.
- Published the signed protocol-only root e365934, replaced remote main and
  deleted tag 0.9 locally/remotely. Old local history was pruned and remote refs
  verified. GitHub may retain unreachable cached objects outside ref control.
- User shortened README themselves; preserved those edits and expanded only the
  endpoint discovery/reading explanation, compatibility checks and lab source links.
  Documentation-only update; no runtime changes or new gameplay validation.
- Current dev21120 (last launched) uses memory labs and deployed NoIntros companion,
  no HMI or shared infrastructure. User requested timer0 and skip-continue=true;
  native settings were saved, no Vortex redeployment or regular game launch.
- GitHub origin:git@github.com:gcatellani/GIMP.git, branch main. Repository-local
  signing uses the user's passphrase-protected GPG key; never request its secret
  in chat. Generated assets remain local unless their publication is requested.
