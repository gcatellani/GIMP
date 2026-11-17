# Value-carrying notification experiment

Two independent mods test native typed snapshots in event callbacks. Neither
references the other's custom classes or declares a dependency on it. The only
additional mod in the isolated development run is NoIntrosAndAutoResume2.0.0-5.
The existing typed/discovery experiments and root README are preserved.

## Event representation

The discoverable GIMP actor retains the native typed Blackboard envelope and
current value store from the earlier experiment. There are per-key native
USceneComponent signals for random (number) and state (string).

On each publication the provider:
1. Writes the new current value to its normal Blackboard.
2. Creates a separate native Blackboard snapshot containing key, type, a typed
   value entry, provider, generation and sequence.
3. Calls Signal.OnComponentActivated.Broadcast(Snapshot, false).
4. Destroys the temporary snapshot's owner after synchronous callbacks return.

The component parameter is the snapshot Blackboard rather than the signal
component. A Blackboard is a native UActorComponent subclass, so no new common
script-defined event type is required. No JSON or provider-state lookup is used
for notification transport.

## Consumer behavior

The consumer binds UFUNCTION callbacks with the native signature
(UActorComponent Component, bool Reset). It casts Component to the native
UBlackboardComponent, validates identity/type, and copies all fields into a
consumer-local record before returning. It does not cache or read the provider's
current value store after discovery. Numeric and string publications are tested.

The on-screen black panel uses white text and shows key, type, value and sequence
for the latest received event, and for a consumer-owned copy processed at least
three real-time seconds later. A timer drains the local queue; it does not poll
the provider. The queue allows at most the few seconds of outstanding events in
this controlled-rate test, but a production consumer would require a hard cap.

The notification payload is borrowed for the callback: consumers MUST copy it
if they need to retain or queue the update. Retaining the native snapshot reference
is not supported by this test's lifetime policy. Provider callbacks remain
synchronous on the game thread; this is not asynchronous transport.

## Limits

The native delegate is repurposed explicitly; this is not automatic property
observation. Temporary AAIController actors exist only to access the exposed
UseBlackboard initializer. Allocation cost, production storage/event selection,
reentrancy, exception behavior, teardown and save-load persistence remain open.
Numbers use native float32. This is not a zero-copy direct scalar delegate.
Do not package this experiment as a production protocol implementation.

Diagnostics are consumer-written result files only:
Saved/gimp-push-evidence.json and ignored investigation/value-push/compiler*.json.
They are not read as provider data by either mod.

## Observed result (2026-11-17)

- Compiler listener received14540 reports across initial/recompile passes (7270
  source files); final current diagnostics contain zero errors/warnings. Initial
  conditional subclass-type mismatch was fixed before the successful run.
- Numeric and string snapshots delivered without provider script-type references.
- Numeric sequence50/value934.751465 was processed after3.003 seconds while latest
  received sequence55/value744.315918 was already available.
- String sequence49/state idle was processed after3.001 seconds while the latest
  received event was numeric sequence54. Zero invalid events in both captures.
- Diagnostic captures are evidence-number.json and evidence-string.json in ignored
  investigation/value-push/. Display rendering still awaits the user's visual check.
- Development PID26880 was launched visibly outside the sandbox with only these
  two test mods and NoIntrosAndAutoResume. It remains running for inspection.
