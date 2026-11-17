# Endpoint discovery lifecycle timing experiment

Independent development provider/consumer, derived from the typed-value test.
Only these two mods and the deployed NoIntrosAndAutoResume are loaded.
No HMI, shared GIMP runtime, Vortex deployment or save writes are involved.

Provider behavior:
- Publish a complete GIMP-tagged typed endpoint during HandleReadyForPlay.
- Publish another compatible endpoint on a 3-second gameplay timer.
- Publish another on a 12-second gameplay timer.

Consumer observations:
- Native world Initialize, PostInitialize and OnWorldBeginPlay.
- Mod HandlePlayerCharacterBeginPlay, HandleSaveGameLoaded, HandleReadyForPlay.
- Timed deferred checks at 0.001, 0.05, 0.2, 1, 4, 10 and 13 seconds.

Each compatible endpoint must have a native Blackboard containing protocol GIMP,
protocolversion1 and a valid value-store object. Counts do not merely count tags.
The consumer's separate UScriptWorldSubsystem observer counts tags at early world
hooks. The random display/event subscription from the typed test is preserved.
Extra scans in this experiment measure timing; they are not a recommended
production polling policy.

Diagnostics are overwritten by each new world at Saved/gimp-discovery-provider.txt,
Saved/gimp-discovery-consumer.txt and Saved/gimp-discovery-world.txt. Captures for
separate runs belong in ignored investigation/discovery-timing/runN/ before restart.
The log uses GetRealTimeSeconds, while SetTimer schedules gameplay time: loading,
pausing or background throttling can shift timer callbacks relative to real time.
Do not interpret a timer's name as a wall-clock guarantee.

Run1 used default load priorities and provider-first command-line enumeration.
Run2 requests consumer-first/provider-last load priorities and reversed enumeration.
The actual callback traces, not the requested order alone, determine whether the
ordering changed. Restart between runs so all class declarations are freshly loaded.
Production world teardown, same-world save reload and unbounded late publishers
remain separate concerns.

## Results: two fresh save-loading startups, 2026-11-17

Both native compiler snapshots contain7270 file reports and zero errors/warnings.
The second run requested different load priorities and reversed CLI enumeration,
but did not change the observed callback order. It is not proof of both orders.

| Consumer observation | Compatible endpoints in each run |
|---|---:|
| World Initialize/PostInitialize/BeginPlay | 0 tagged actors |
| Player BeginPlay | 0 |
| SaveGameLoaded | 0 |
| ReadyForPlay | 1 |
| First deferred timer callback | 1 |
| 4-second timer | 2 |
| 10-second timer | 2 |
| 13-second timer | 3 |

The early endpoint was published by the provider during ReadyForPlay before the
consumer's matching callback. Discovery at world/player BeginPlay was too early
in these save-loading runs. The first deferred callback after ReadyForPlay is a
sensible initial discovery point if providers are required to publish complete
endpoints synchronously during ReadyForPlay. It avoids relying on the relative
order of individual mods' ReadyForPlay callbacks; that ordering is not an API
all-providers-ready guarantee.

A 10-second second scan caught the intentionally 3-second-delayed endpoint but
missed the 12-second-delayed endpoint, which the 13-second diagnostic scan found.
No finite pair of scans guarantees discovering arbitrarily delayed publication.
Recommended convention: publish an endpoint early, keep it for the world's
lifetime, and represent unavailable data/readiness in the endpoint instead of
creating it only when a gameplay effect first activates. A bounded late retry is
optional resilience, not a replacement for that convention.

Timing caveat observed in both runs: callbacks scheduled at0.001/0.05/0.2 seconds
all occurred in the first observed timer update around real-time6 seconds, while
10-second gameplay timers fired around real-time15.6 seconds. Loading/first-tick
scheduling makes a wall-clock promise inappropriate.

These results cover two startup loads of the existing save, not manual same-world
reload, travel, all load orders or all third-party initialization behavior. Game
was left running after run2. No save or profile file was modified by the test.

## Current source: protocol version 2

The native envelope and consumer version checks now use protocolversion2,
modid, moddataversion1 and values. Original observations above were captured on
the earlier revision; the independent push example provides current v2 validation.
