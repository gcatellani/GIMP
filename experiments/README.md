# GIMP implementation experiments

These are independent development tests, not production mod packages.

- [Typed storage and per-key change signals](typed-transport/README.md)
- [Discovery lifecycle timing](discovery-timing/README.md)
- [Value-carrying notifications and delayed consumer queues](value-push/README.md)
- [Earlier in-memory JSON transport](memory-transport/README.md)

The root README describes the current protocol direction. The experiments preserve
what was actually tested: earlier provider/value field names, no moddataversion
field yet, and an explicit type field in push snapshots. The current design uses
modid/values, adds moddataversion, and derives notification value types from the
supported data contract rather than requiring a separate type field.

Each test includes its own limitations. Native compilation and runtime evidence do
not establish a complete production lifetime, allocation or persistence policy.
Local linked installations, raw traces and diagnostics remain ignored under
investigation/. No shared companion GIMP mod or HMI dependency is introduced.
