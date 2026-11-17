# Memory-only transport lab

These are independent development-only G1R mods, not installable production
features or a standalone GIMP runtime package.

| Folder | Mod |
|---|---|
| `provider/GIMP-Memory-Provider-Lab` | Publishes an endpoint and mutates/removes/replaces it |
| `consumer/GIMP-Memory-Consumer-Lab` | Reads native endpoint/component data, never provider script types |

Both `GothicMod.json` files have empty dependency lists. Do not add HMI or a
shared provider/consumer script library for this test.

## Reproduce

1. Copy/link both mod folders into an isolated `Mods` directory.
2. Launch G1R in development mode with that directory:

```text
-as-development-mode -ModsDirectory="<lab Mods directory>" -Mods=GIMP-Memory-Provider-Lab,GIMP-Memory-Consumer-Lab
```

Use the normal ModKit script-root configuration for your installation if needed.
Keep the main menu visible and the game focused for at least ten seconds. The
extensions attach to the native main-menu widget; no save needs to be loaded.

The phase test publishes revision 1, updates to revision 2 after two seconds,
removes the endpoint after four seconds, and creates a new endpoint/generation
with revision 3 after six seconds. The reader writes a **diagnostic result only**:

```text
System::GetProjectSavedDirectory() + "GIMP-Lab/memory-transport-evidence.json"
```

That file is not part of the transport. The provider has no file IO and never
reads the consumer's result. The successful original run used a workspace-local
diagnostic destination; the published source changes only that destination to
this portable Saved-directory path.

Expected final flags: initial typed values, updated values, removal and replacement
are true; invalidPayload is false. Protocol/version checks here
are intentionally minimal and not production input validation.

## Important limits

- Do not enable immediate auto-resume for the main-menu phase test: it may leave
  the widget before the timed phases finish. A later lab launch used AutoResume,
  but it is separate from the successful phase-test evidence.
- Actor tags hold a fixed discovery marker only. Dynamic JSON lives in a hidden
  native text component, not in FNames.
- Consumer-only compilation/runtime, save reloads, world transitions and production
  data-carrier costs remain separate tests.
- Do not ship these lab mods to end users as a finalized GIMP implementation.

See [the observed results](../../docs/memory-transport-validation.md).
