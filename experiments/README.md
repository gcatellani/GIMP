# GIMP implementation experiments

These are independent development tests, not production mod packages.

- [Typed storage and per-key change signals](typed-transport/README.md)
- [Discovery lifecycle timing](discovery-timing/README.md)
- [Value-carrying notifications and delayed consumer queues](value-push/README.md)
- [Earlier in-memory JSON transport](memory-transport/README.md)

The native typed, discovery and push examples now use protocolversion2 with
modid/values and moddataversion1. Push notification types are derived from the
supported key contract, not an explicit type field. The published reference0.0.1
ZIPs are refreshed to match. Earlier observations in test notes describe the
original revisions; new v2 validation is recorded separately. The JSON-only
memory-transport experiment remains a historical v1 investigation.

Each test includes its own limitations. Native compilation and runtime evidence do
not establish a complete production lifetime, allocation or persistence policy.
Local linked installations, raw traces and diagnostics remain ignored under
investigation/. No shared companion GIMP mod or HMI dependency is introduced.
