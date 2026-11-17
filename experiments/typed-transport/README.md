# Native typed endpoint and per-key notification experiment

Validated on 2026-11-17 with two independent mods and the installed
NoIntrosAndAutoResume 2.0.0-5 only. This is an experiment, not a production
GIMP implementation. No changes to HMI, its profiles or gameplay resources.

## Representation

The provider creates two unpossessed native AAIController actors solely to use
UseBlackboard(), the exposed native initializer for UBlackboardComponent.
Neither actor controls a character. This carrier needs review before production.

The endpoint actor has the fixed actor tag `GIMP`. Its native Blackboard has:

| Key | Native key type |
|---|---|
| protocol | String, GIMP |
| protocolversion | Int, 2 |
| moddataversion | Int, 1 |
| modid | String, gimp.test.random |
| generation | String, new endpoint GUID |
| values | Object reference to a second UBlackboardComponent |

The value Blackboard has `random` (Float) and `state` (String). These values are
native typed storage, not JSON text. The float key stores 32-bit floating-point
numbers; it is not an arbitrary-precision or float64 JSON-number replacement.
The fields are named Blackboard entries, not new C++ properties on UObject.
A shared custom script class, DLL, companion or inter-mod dependency is not used.

## Subscription

For each key the provider can expose a named native USceneComponent on the value
owner actor. The component's native OnComponentActivated delegate is used as an
explicit signal: the provider stores a value, then calls Broadcast(component,
false). This does not call Activate() or change the component activation state.
It is a reuse of an exposed native delegate, not automatic Blackboard observation.

The consumer discovers the value store, locates the `random` signal component,
binds its own UFUNCTION, reads the initial value once, then reads subsequent
values only from the callback. It never imports or casts to the provider's script
classes. The white-text/black-background readout shows the random value and event
count. The random key is changed once per second. The provider also signals the
unsubscribed `state` key every 0.4 seconds; it has a different signal component.

Discovery happens shortly after ReadyForPlay and once more after 10 seconds.
A separate 0.5-second timer maintains the view and checks object validity; it
never polls a value. These timings are test choices, not finalized lifecycle rules.

## Observed result

- Fresh native startup: 7270 compiler file reports, zero errors/warnings.
- Consumer validated all envelope fields and read the referenced typed value store.
- Runtime evidence recorded notifications greater than zero and fromEvent=true.
- User confirmed the black panel and changing white-text value work.
- No JSON serialization/parsing occurs in the provider-to-consumer transport.
  The consumer writes a JSON diagnostic only to Saved/gimp-typed-evidence.json;
  neither side reads it as a source of provider data.

Raw compiler/evidence snapshots remain in ignored investigation/typed-transport/.
Both mod descriptors have empty dependency arrays. The isolated development
Mods folder links only these two mods and the installed NoIntrosAndAutoResume.

## Limits

This establishes the carrier and explicit per-key notification mechanism in a
loaded gameplay world. It does not validate production overhead, duplicate
providers, adversarial schemas, missing-provider startup, save/load persistence,
world teardown/unsubscription or callback reentrancy. Runtime extension teardown
was not exposed as BlueprintOverride on UGothicModExt_WorldSubsystem, so the test
does not claim a complete cleanup policy. Do not save test actors into a release
save or ship this experiment as a finished protocol.

Official API references:
- https://alkimiainteractive.github.io/G1R-Modkit/script-reference/class_u_blackboard_component.html
- https://alkimiainteractive.github.io/G1R-Modkit/script-reference/class_u_blackboard_data.html
- https://alkimiainteractive.github.io/G1R-Modkit/script-reference/class_a_a_i_controller.html
- https://alkimiainteractive.github.io/G1R-Modkit/script-reference/class_f_actor_component_activated_signature.html

## Current source: protocol version 2

The native envelope and consumer version checks now use protocolversion2,
modid, moddataversion1 and values. Original observations above were captured on
the earlier revision; the independent push example provides current v2 validation.
