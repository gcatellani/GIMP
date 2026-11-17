# Gothic 1 Remake Inter-Mod Protocol (GIMP)

GIMP aims to let Gothic 1 Remake mods exchange structured information without
hardcoding other mods' script classes or requiring every provider to be installed. The idea is to achieve lower coupling.

## How it works

### Basics

We distinguish:
- Providers: they offer data via a standard interface and format (GIMP)
- Consumers: they consume data provided by other mods using GIMP

A mod can be both at the same time, a provider and consumer.
A mod exposes data over __one__ interface.
A mod can consume from __multiple__ sources / providers.

![GIMP provider and consumer overview](assets/pics/GIMP.jpg)

### Provider

To produce GIMP comfirming data, a mod:
1. Offers data in a `GIMP`-tagged payload.
2. The payload follows the following schema. The actual data is stored as key/value pairs.
```json
{
  "protocol": "GIMP",
  "protocolversion": 1,
  "provider": "exampleauthor.regeneration",
  "generation": "endpoint-guid",
  "value": {
    "regeneration.health.state": "active",
    "regeneration.health.ratePerSecond": 0.2,
    "regeneration.mana.state": "idle",
    "regeneration.mana.ratePerSecond": 0.5
  }
}
```

- `provider` identifies the data source and stays stable across updates.
- `generation` distinguishes endpoint instances; it is **not a shared game-session UUID**. Providers generate a new one when replacing their endpoint.
- `value` holds documented key/value pairs. Consumers recognize supported contracts and ignore unknown fields.

### Consumer

To consume GIMP-compatible mod data from other mods, a consumer:
1. When starting scans for mods with the GIMP tag.
2. Subscribes to the producers and values inside them it recognizes and wants to use.

## Technical details

Providers:
- Each provider creates an engine-managed actor in the current world, gives it a shared,
stable discovery **`GIMP`** tag and.
- Providers own and update only their own endpoints; consumers treat them as read-only.
- No raw memory addresses are advertised or dereferenced.


Consumers:
- Call `Gameplay::GetAllActorsWithTag()` with the `GIMP` tag. This returns native `AActor` references for matching actors in the current world. No matches means no data is currently available; the consuming mod continues to work without that optional feature.
- Chek compatibility using `provider` and `protocolversion` information.
- Subscribe to data in the value-store.
- Missing, destroyed, invalid or unsupported endpoints mean unavailable data,
  not a fatal dependency or permission to retain stale values.
- Production consumers should cache world-scoped native references and invalidate
  them appropriately, rather than scan every actor each frame.

## References
GIMP is compatible with the [Official Gothic 1 Remake ModKit](https://github.com/AlkimiaInteractive/G1R-Modkit)
