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

- User selected the shared discovery tag `GIMP` and requested no lab mentions in
  README. Updated README wording/code accordingly without restoring omitted text.
  Historical experiment sources/evidence retain their original test tag; no new
  runtime validation or game changes were performed for this documentation edit.

## Typed key/value and event experiment (2026-11-17)

- User requested typed envelope/value data, per-key subscriptions, random provider
  and visible white-text/black-background consumer. Sources are in uncommitted
  experiments/typed-transport/, independent mods with empty dependency lists.
- Native AAIController.UseBlackboard initializes endpoint/value Blackboards:
  string protocol/provider/generation, int protocolversion, object value reference,
  string state and float32 random. No JSON transport or cross-mod script types.
- Per-key native USceneComponent.OnComponentActivated is explicitly Broadcast
  after a write; consumer binds only random, reads initially then on callbacks.
  It is an adapted native signal, not automatic property-change observation.
- Initial naming warnings fixed. Unsupported Deinitialize BlueprintOverride
  methods removed. Normal shutdown of dev21360 verified, fresh dev11508 launched
  unsandboxed with only GIMP-Typed-Provider, GIMP-Typed-Consumer and installed
  NoIntrosAndAutoResume2.0.0-5. No HMI/Regen/Vortex deployment or save writes.
- Final compiler snapshot: 7270 actual file reports, zero errors/warnings.
  Evidence envelopeValid=true, fromEvent=true, random887.4477, notifications11,
  generationF0CFA46D41D2F77C86F6939FD9BB0E50. User confirmed updating panel works.
- Computer Use native helper unavailable (os error2); visible proof is user's
  observation, not inferred from process/window presence. Game left running.
- Existing root README/user edits/artwork preserved; no commit/push requested.
  See experiment README for carrier/precision/lifecycle limitations.

## Discovery timing test (2026-11-17)

- User requested verifying a suitable discovery moment. New independent test mods
  are in experiments/discovery-timing/; existing typed test/readme/user edits kept.
- Two clean dev launches with only GIMP-Discovery-Provider/Consumer and installed
  NoIntrosAndAutoResume. No game existed initially. Run1 PID23724 closed normally;
  run2 PID15776 remains running. No Vortex deployment, HMI or save/profile writes.
- Both fresh compiles7270 file reports/zero errors/warnings. Copied raw runtime
  traces into ignored investigation/discovery-timing/run1 and run2; assertions
  verify matching counts. Provider publishes compatible endpoints during Ready,
  then gameplay timers3s/12s. Consumer probes native and mod lifecycle hooks.
- Both runs: world/player BeginPlay and SaveGameLoaded see0; Ready sees1;
  deferred-next-tick sees1;4s sees2;10s sees2;13s sees3. Requested load-order
  reversal did not change actual observed callback ordering; do not overclaim.
- Recommendation: first deferred check after ReadyForPlay, with protocol convention
  that providers create endpoint synchronously during Ready (or earlier), then
  expose readiness via data rather than delaying endpoint creation. Optional10s
  retry catches delayed providers but cannot guarantee arbitrary lateness.
- SetTimer is gameplay time; first callbacks observed around real6s and10s timer
  around real15.6s due loading/first-tick scheduling. No wall-clock guarantee.
- Manual save reload/world travel and opposite callback ordering not yet tested.
  Pending user focus/ready question is no longer needed for traces: both completed.
  No commit/push requested; test sources/docs/handoff remain uncommitted.

## Lightweight README update

- User requested concise explanations of discovery timing, typed native storage,
  consumer subscriptions and provider pushes. Preserved their structure, intro,
  diagram and logical data example; replaced outdated discovery/subscription bullets.
- README now states early ReadyForPlay endpoint publication, deferred discovery,
  optional bounded10s retry, native Blackboard envelope/value layout, per-key named
  native signals, bind/read/store-before-broadcast/unbind sequence, float32 precision
  and remaining lifecycle/carrier validation. No JSON transport is claimed.
- Documentation-only edit; no game restart, runtime edits, commit or push requested.

## Value-carrying notification test (2026-11-17)

- User requested pushing key/type/value in notifications and showing received data
  on screen. New independent mods in experiments/value-push/, isolated links in
  investigation/value-push/Mods. Earlier experiments, README edits and artwork kept.
- No game existed at entry. Dev26880 launched unsandboxed with GIMP-Push-Provider,
  GIMP-Push-Consumer, deployed NoIntrosAndAutoResume only. No HMI, Vortex deployment,
  profile or save changes. Leave running. No commit/push requested.
- Native OnComponentActivated carries a separate snapshot UBlackboardComponent
  via its UActorComponent parameter. Contains key/type/typed value/provider/
  generation/sequence. Provider destroys temporary owner after synchronous broadcast;
  consumer copies fields in callback into its own queue, never retains the snapshot
  and never reads provider current values after discovery. No JSON transport.
- Consumer draws key/type/value/sequence in white-on-black for received events and
  copied events processed3s later. Numeric every1s and string every1.3s signals tested.
- Initial conditional TSubclassOf mismatch fixed. Compiler14540 reports across two
  passes, final current diagnostics0 errors/warnings. Live evidence: numeric seq50
  value934.751465 processed3.003s later after latestseq55; stringseq49 idle processed
  3.001s later after latestseq54. Invalid0, notifications54/processed49 at capture.
- Raw evidence-number/string.json and compiler.json under ignored test investigation.
  Test README documents borrowed-payload lifetime and temporary actor allocation cost.
  UI confirmation question pending; runtime event/queue evidence already verified.
- This is a synchronous native-object payload, not a native delegate with direct
  arbitrary scalar parameters. Production overhead/reentrancy/cleanup unvalidated.

## Publication of typed/push protocol direction

- User requested publishing latest work to GitHub. Preserved their latest schema
  names modid/values and moddataversion, fixed remaining old-name references,
  documented contract-based types without a required notification type field,
  and replaced outdated pull-only wording with borrowed snapshot/copy-before-queue.
- Publishing README/HANDOFF and three independent typed/discovery/push source
  experiments plus index; exclude raw investigation data and local Nexus artwork.
  Historical experiments keep actual tested field names/type for honest evidence;
  index/root README state the difference from the current protocol direction.
- Documentation/source publication only: no runtime changes, restart or deployment.

## Downloadable reference0.0.1

- User requested packaged provider/consumer, source alongside ZIPs, README links
  and GitHub publication. Exact tested value-push runtime source remains unchanged.
- Added tools/package_reference.py: separate installable AngelScript provider and
  consumer ZIPs, full source ZIP, SHA256 manifest, deterministic metadata, no overwrite.
  Normal outputs are workspace Distribution/GIMP/Reference/0.0.1. User explicitly
  requested downloadable reference ZIPs on GitHub, so narrowly except these small
  archives under reference/0.0.1 from ordinary no-release-ZIPs-in-Git policy.
- Reference guide covers install/uninstall, live compilation, optional AutoResume,
  borrowed payload copying, prototype limits and earlier schema/type differences.
  Root README links ZIPs, guide, browsable source and checksums. Other artwork kept.
- Verified CRC/byte identity/runtime descriptors/README links, extracted source-only
  bundle and rebuilt all three archives byte-identically. Provider3594 bytes,
  consumer4364 bytes, source11832 bytes. No game launch/restart/deployment or tag.
- Publication includes only docs/tool/reference downloads; excludes investigation
  fixtures/results and assets/nexus. Existing native compile/runtime evidence remains
  applicable because Provider.as/Consumer.as and descriptors have not changed.
