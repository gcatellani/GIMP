# Gothic 1 Remake Inter-Mod Protocol (GIMP)

GIMP aims to let Gothic 1 Remake mods exchange structured information without
hardcoding other mods' script classes or requiring every provider to be installed.
For example, a regeneration mod could publish health/mana regeneration states
and rates for a HUD mod to display.

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
    "regeneration.health.state": "active",
    "regeneration.health.ratePerSecond": 0.2,
    "regeneration.mana.state": "idle",
    "regeneration.mana.ratePerSecond": 0.5
  }
}
```

- `provider` identifies the data source and stays stable across updates.
- `generation` distinguishes endpoint instances; it is **not a shared game-session
  UUID**. Providers generate a new one when replacing their endpoint.
- `revision` identifies a changed payload within an endpoint instance.
- `value` holds documented key/value pairs. Consumers recognize supported contracts
  and ignore unknown fields.


## How a consumer finds and reads compatible providers

A consumer is a mod that reads data; a provider is a mod that publishes it.
A mod can do both. **The consumer discovers live endpoints, rather than looking
for a particular mod name or importing another mod's script classes.** Each
provider creates an engine-managed actor in the current world, gives it a shared,
stable discovery tag, and attaches a native component containing its JSON report.

All providers use the actor tag **`GIMP`**. Multiple mods can use this same tag
on their own endpoint actors; discovery returns every matching actor. Each
provider is identified by the `provider` field inside its JSON report.

The current payload carrier is a hidden `UTextRenderComponent`. Consumers and
providers must agree on that carrier; its suitability for production still
requires validation. Provider identities and changing values belong in the JSON,
not in changing tags. Protocol versions are declared inside the report, not in
the discovery tag.

The reading sequence is:

1. **Discover endpoints.** Call `Gameplay::GetAllActorsWithTag()` with the `GIMP`
   tag. This returns native `AActor` references for matching actors in the current
   world. No matches means no data is currently available; the consuming mod
   continues to work without that optional feature. An installed or enabled mod
   does not necessarily have a live endpoint yet.
2. **Read each candidate's report.** Check `IsValid(actor)`, obtain its native
   component with `GetComponentByClass(UTextRenderComponent)`, check that component
   too, then read `GetText().ToString()`. This copies the JSON into the consumer's
   own string. The consumer never casts the actor to the provider's custom class
   and never writes to its component.
3. **Check compatibility before using values.** Bound the payload size, parse it
   with `FJsonObject.LoadFromString()`, and validate required fields and their
   types. Require `protocol == "GIMP"` and a supported `protocolversion`. Read the
   stable `provider` identity, `generation`, `revision` and `value` object.
   Skip malformed or unsupported reports independently so one bad endpoint does
   not prevent reading others.
4. **Check the data contract.** A compatible envelope alone does not mean the
   consumer understands every value. For example, a regeneration display looks
   for the documented health/mana state and rate keys, checks their types and
   allowed ranges, and ignores unrelated keys. A map-marker provider may speak
   GIMP correctly without offering anything that regeneration display can use.
   Contract identifiers and their versioning still need to be finalized.
5. **Use and refresh supported data.** Keep each provider's data separate. Poll
   the payload at an appropriate interval; `revision` identifies updates within
   the same `generation`. A changed generation means a new endpoint instance,
   so discard the previous instance's cached state. Recheck native validity and
   rediscover periodically; clear unavailable data when an endpoint disappears
   or the world changes. A production freshness/expiry policy is still to be
   specified, since an existing actor alone does not prove its data is current.

The example below illustrates lookup and parsing only; the compatibility and
lifecycle checks above are also required for a production reader:

```cpp
TArray<AActor> Endpoints;
Gameplay::GetAllActorsWithTag(n"GIMP", Endpoints);

for (AActor Endpoint : Endpoints)
{
    if (!IsValid(Endpoint)) continue;
    auto Payload = Cast<UTextRenderComponent>(
        Endpoint.GetComponentByClass(UTextRenderComponent));
    if (!IsValid(Payload)) continue;

    FString Text = Payload.GetText().ToString();
    FJsonObject Report;
    if (Text.Len() >= 16384 || !Report.LoadFromString(Text)) continue;

    // Validate the envelope and the supported value contract here.
    // Read only the fields this consumer understands.
}
```

The 16 KiB limit above is an example bound, not a settled protocol limit.
Consumers could poll every 250 ms, for example, rather than scan every frame.
Multi-provider handling and production scan costs remain to be validated.

`Plugin::GetEnabledPluginNames()` can separately list enabled plugins for
optional diagnostics. **It is not needed to read these endpoints and is not a
compatibility test:** the live report determines what a provider offers. No
central registry file, advertised memory address, companion GIMP mod or hard
provider/consumer dependency is needed for the demonstrated mechanism.

Safe gameplay/save-load lifecycle handling remains to be validated before
treating this as a production integration.

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

GIMP requires no shared runtime mod and no dependency between the
provider and consumer. Each publishes or discovers native endpoints independently.
The protocol does not require players to install a separate GIMP package.

Endpoint/session lifetime remains an open validation item. Sharing a process is
not, by itself, proof that all objects are invalidated correctly during save loads.

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
native detection and provider reports. These regeneration gameplay rules are an example contract, not functionality
implemented by GIMP itself.

## Still to validate

- Same-save reloads, new games, world transitions and loading/paused states.
- Whether world-scoped endpoints suffice to replace shared session identification.
- Persistence exclusion and invalidation of cached references.
- A consumer-only launch with the provider mod disabled.
- Malformed/oversized payloads, duplicate endpoints and unsupported versions.
- Multiple providers, rapid updates and discovery costs in large gameplay worlds.
- A production carrier, including allocation and render-state overhead.
- Compatibility/versioning rules and production integration examples.

## References

- [Official Gothic 1 Remake ModKit](https://github.com/AlkimiaInteractive/G1R-Modkit)
- [Native actor discovery](https://alkimiainteractive.github.io/G1R-Modkit/script-reference/namespace_gameplay.html)
- [Actor tags and component lookup](https://alkimiainteractive.github.io/G1R-Modkit/script-reference/class_a_actor.html)
- [Native text component](https://alkimiainteractive.github.io/G1R-Modkit/script-reference/class_u_text_render_component.html)
- [Native JSON object](https://alkimiainteractive.github.io/G1R-Modkit/script-reference/class_f_json_object.html)
