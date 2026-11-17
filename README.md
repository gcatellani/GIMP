# Gothic 1 Remake Inter-Mod Protocol (GIMP)

**Status: experimental protocol. Memory-only cross-mod exchange validated in-game;
production transport and save-load lifecycle rules are not yet finalized.**

GIMP aims to let Gothic 1 Remake mods exchange structured information without
hardcoding other mods' script classes or requiring every provider to be installed.
For example, a regeneration mod could publish health/mana regeneration states
and rates for a HUD mod to display.

## Current direction: exchange data in game memory

Two independent test mods successfully exchanged a structured JSON payload held
entirely in game memory. The provider published a discoverable, engine-managed
endpoint. The consumer located it through native ModKit APIs and read its live
payload without referencing the provider's script classes.

**Both independent lab mods have empty dependency lists.** No shared registry,
provider data file or additional infrastructure mod was involved.

This establishes that a separate session-authority mod is not required merely to
exchange data. It does **not** yet establish that session/lifecycle protection
can safely be removed when loading saves or changing worlds.

## What was actually tested

The proof uses an invisible, noncolliding actor with a stable discovery tag. A
hidden native `UTextRenderComponent` holds the JSON as nonlocalized `FText`.
The consumer uses only native actor, component and JSON APIs.

This component is an experimental carrier, **not a finalized production storage
recommendation**. The payload is serialized JSON in memory, not a raw pointer
or an arbitrary custom script struct shared between mods.

| Live check | Result |
|---|---|
| Read string, number and boolean values | Passed |
| Read updated values from the same endpoint | Passed |
| Handle endpoint removal | Passed |
| Discover/read a replacement endpoint | Passed |
| Run with only the two independent lab mods | Passed |
| Reference another mod's custom script classes | Not required |

The isolated run produced **7,265 native compiler file reports, with no errors
or warnings**. It completed in the main-menu world without loading or changing a
savegame. A later dev run including NoIntrosAndAutoResume compiled with 7,270
reports and no diagnostics; it is not additional proof of gameplay lifecycle behavior.

See the [detailed validation record](docs/memory-transport-validation.md) and
[reproducible lab source](experiments/memory-transport/README.md).

## Proposed endpoint data

This illustrates the logical structure. Production field names and versioning
rules are still proposals:

```json
{
  "protocol": "GIMP",
  "protocolversion": 1,
  "provider": "exampleauthor.regeneration",
  "generation": "a-new-guid-for-this-endpoint-instance",
  "revision": 2,
  "value": {
    "regeneration.v1.health.state": "active",
    "regeneration.v1.health.ratePerSecond": 0.2,
    "regeneration.v1.mana.state": "idle",
    "regeneration.v1.mana.ratePerSecond": 0.5
  }
}
```

- `provider` identifies the data source and stays stable across updates.
- `generation` distinguishes endpoint instances; it is **not a shared game-session
  UUID**. The experiment generated a new one when replacing the endpoint.
- `revision` identifies a changed payload within an endpoint instance.
- `value` holds documented key/value pairs. Consumers recognize supported contracts
  and ignore unknown fields.

The lab's small test payload is not a completed regeneration integration or a
frozen wire format.

## Discovery and ownership

- Providers own and update only their own endpoints; consumers treat them as read-only.
- No raw memory addresses are advertised or dereferenced.
- Missing, destroyed, invalid or unsupported endpoints mean unavailable data,
  not a fatal dependency or permission to retain stale values.
- Use stable tags for discovery only. Unreal interns FNames; continuously changing
  JSON/rates must not be published as new tag names.
- Production consumers should cache world-scoped native references and invalidate
  them appropriately, rather than scan every actor each frame.
- A discovery tag is a cooperative convention, not a security boundary.

## Dependencies

The memory-only lab requires no shared runtime mod and no dependency between the
provider and consumer. Each publishes or discovers native endpoints independently.
The protocol does not require players to install a separate GIMP package.

Endpoint/session lifetime remains an open validation item. Sharing a process is
not, by itself, proof that all objects are invalidated correctly during save loads.

## Native ModKit APIs

The experiment uses documented native capabilities:

- `Gameplay::GetAllActorsWithTag()` for discovery.
- `AActor.GetComponentByClass()` for a known native component type.
- `UTextRenderComponent.SetText()` / `GetText()` for the experimental memory payload.
- `FJsonObject.LoadFromString()` and field access for structured values.

Enabled-plugin enumeration, package-directory lookup and descriptor reading were
also checked against the official API reference. Descriptor metadata is a
string-to-string map, so declarations must use flat string entries rather than
nested objects. See [ModKit discovery validation](docs/modkit-discovery-validation.md).

An in-memory endpoint may make a separate datafile declaration unnecessary;
production discovery metadata has not yet been standardized.

## Example use case: regeneration

Health and mana would be independent channels:

| State | Meaning |
|---|---|
| `inactive` | Inactive or suspended, for example at the resource cap |
| `idle` | Enabled but waiting to engage, for example during cooldown |
| `active` | Regeneration is taking place |

Rates are finite, nonnegative resource points per second. Restoring 1 HP every
5 seconds corresponds to `0.2 HP/sec`. Only active sources contribute to an
active-rate total. Consumers must avoid double-counting effects through both
native detection and provider reports. The memory test does not implement these
regeneration gameplay rules.

## Still to validate

- Same-save reloads, new games, world transitions and loading/paused states.
- Whether world-scoped endpoints suffice to replace shared session identification.
- Persistence exclusion and invalidation of cached references.
- A consumer-only launch with the provider mod disabled.
- Malformed/oversized payloads, duplicate endpoints and unsupported versions.
- Multiple providers, rapid updates and discovery costs in large gameplay worlds.
- A production carrier, including allocation and render-state overhead.
- Compatibility/versioning rules and production integration examples.

No production HMI integration has been changed to use this memory transport.
HMI memory-transport integration remains paused. The isolated proof does not
establish production gameplay lifecycle behavior.

## Repository layout

| Path | Purpose |
|---|---|
| `experiments/memory-transport/` | Independent provider/consumer proof source |
| `docs/` | Validation evidence, limitations and historical proposals |

The repository contains protocol documentation and development experiments, not a
standalone installable GIMP mod. Do not distribute the lab mods as production releases.

## References

- [Official Gothic 1 Remake ModKit](https://github.com/AlkimiaInteractive/G1R-Modkit)
- [Native actor discovery](https://alkimiainteractive.github.io/G1R-Modkit/script-reference/namespace_gameplay.html)
- [Actor tags and component lookup](https://alkimiainteractive.github.io/G1R-Modkit/script-reference/class_a_actor.html)
- [Native text component](https://alkimiainteractive.github.io/G1R-Modkit/script-reference/class_u_text_render_component.html)
- [Native JSON object](https://alkimiainteractive.github.io/G1R-Modkit/script-reference/class_f_json_object.html)
