# Memory-only interoperability proof

Validated live on 2026-11-17. This isolated experiment informs the current protocol direction. It does not
change the paused HMI integration. The protocol
remains experimental; the root README separates the approaches.

## Question

Can a provider publish structured values in game memory and a separately compiled
consumer discover/read them using native ModKit types, without referencing the
provider's script classes, exchanging a data file or loading the GIMP UUID mod?

**Yes, for the in-memory JSON mechanism tested here.**

## Experiment

Two independent lab mods have empty dependency lists:

- The provider spawns its own invisible, noncolliding, nonticking actor. Its one
  stable discovery tag is `GIMP.MemoryEndpoint.lab.v1`.
- A native `UTextRenderComponent` attached to that actor holds the JSON envelope
  as nonlocalized `FText`. It is hidden and does not tick or render visibly.
- The consumer queries native `AActor` references by the discovery tag, obtains
  the native component through `GetComponentByClass(UTextRenderComponent)`, reads
  its text and parses it with `FJsonObject.LoadFromString`.
- The consumer contains no reference to the provider's script actor/extension
  classes. Only the two independent lab mods were loaded in the successful run.

The payload includes provider identity, protocol version, endpoint generation,
revision and a value object with string, number and boolean fields. It never
passes through a provider data file. The consumer writes only a local diagnostic
result under ignored `investigation/`; that output is not the exchange mechanism.

Changing payload values are not stored in actor/component tags. Those are FNames
and should not be used as a continuously changing telemetry store. The stable
tag locates the endpoint; the dynamically replaceable text holds its payload.

## Observed results

Native compiler: **7,265 actual file reports; no errors or warnings**.

| Check | Observed result |
|---|---|
| Initial typed payload | String `active`, numeric rate approximately `0.2`, boolean `true` read successfully |
| Update in place | Rate changed to approximately `0.7`; consumer read revision 2 with the same generation |
| Endpoint removed | Consumer observed no endpoint without crashing |
| Endpoint replaced | Consumer read revision 3 and a different generation |
| Invalid parsed payloads | None observed in this valid-payload test |
| Additional infrastructure mod required | No |

The final test evidence recorded:

```json
{
  "revision": 3,
  "readInitialTypedValues": true,
  "readUpdatedValues": true,
  "observedRemoval": true,
  "readReplacement": true,
  "invalidPayload": false,
  "providerModEnabled": true
}
```

Raw evidence and local fixtures are in ignored `investigation/memory-transport/`.
The [published lab source](../experiments/memory-transport/README.md) is available
for reproduction, outside the release package. Its consumer diagnostic output
path was made portable; the transport logic is unchanged. The successful test ran against the main-menu world,
without loading or changing a savegame. The user subsequently closed that game.

## What this establishes

- A native discoverable object can carry a live payload across independent mods.
- The consumer does not need the provider's script class or a shared base class.
- JSON serialization can be kept entirely in memory; filesystem transport is not
  required for this mechanism.
- An absent/destroyed endpoint can be handled through normal native validity and
  discovery checks.
- A separate session-authority mod is not necessary merely to exchange data.

## What remains unvalidated

- This transports serialized JSON in a native component. It does not establish
  direct access to arbitrary custom typed script structs across mods.
- The text-render component is a proof carrier, not an approved production storage
  choice. Its allocation/render-state costs and better native alternatives need review.
- Same-save reloads, world transitions, persistence exclusion and paused/loading
  states still require gameplay lifecycle tests before dropping session scoping.
- The consumer was not yet launched alone with the provider mod disabled. Its
  dependency list/type references were checked, and live endpoint removal was tested.
- Malformed, oversized, duplicated and rapidly changing endpoints, cached-reference
  invalidation, concurrent providers and larger-world discovery costs need tests.

No raw memory addresses are advertised. The experiment uses engine-managed object
references and native validity checks. Matching a discovery tag is a cooperative
protocol convention, not a security boundary.

## Primary API references

- [Native actor discovery](https://alkimiainteractive.github.io/G1R-Modkit/script-reference/namespace_gameplay.html)
- [Actor tags and component lookup](https://alkimiainteractive.github.io/G1R-Modkit/script-reference/class_a_actor.html)
- [Native text component](https://alkimiainteractive.github.io/G1R-Modkit/script-reference/class_u_text_render_component.html)
- [Native JSON object](https://alkimiainteractive.github.io/G1R-Modkit/script-reference/class_f_json_object.html)
