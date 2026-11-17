# GIMP test reference 0.0.1

Two small, independent Gothic 1 Remake script mods demonstrate typed native data,
per-key pushed snapshots, and consumer-owned delayed queues. They are learning
examples, not a production-ready interoperability library.

## Downloads

- GIMP-Push-Provider-0.0.1.zip: publishes a random number every second and a string
  state every 1.3 seconds.
- GIMP-Push-Consumer-0.0.1.zip: subscribes to both keys and displays their key, type
  and value in white text on black. A second line processes copied updates after
  three seconds, demonstrating that queued values survive later provider changes.
- GIMP-Reference-Sources-0.0.1.zip: both mods' complete source, experiment notes,
  this guide and the repeatable packaging script.
- SHA256SUMS.txt: SHA-256 checksums of these three archives.

## Install and try

1. Close the game. Extract both mod ZIPs into your game's G1R/Mods directory.
   The resulting files include G1R/Mods/GIMP-Push-Provider/GothicMod.json and
   G1R/Mods/GIMP-Push-Consumer/GothicMod.json.
2. Enable both example mods using the game's normal mod selection and load a save.
3. Leave gameplay resumed. The consumer panel shows incoming and delayed values.
4. To remove the examples, close the game and remove their two mod folders.

No GIMP companion, HMI, DLL or consumer/provider dependency is required. The game
compiles the included AngelScript source on startup: there is no separate binary
build to install. NoIntrosAndAutoResume was used only to automate our test launch;
it is optional and is not included. The examples do not write gameplay saves or
profile settings; the consumer writes only Saved/gimp-push-evidence.json diagnostics.
Use a disposable test save and do not save these temporary test actors into it.

For development, point -ModsDirectory at a directory containing these two mod
folders and select -Mods=GIMP-Push-Provider,GIMP-Push-Consumer together with
-as-development-mode and your normal ModKit -ScriptDirectory argument.

## Read and rebuild

The source ZIP preserves the folders experiments/value-push/provider and consumer.
Open Provider.as to follow publication; open Consumer.as to follow discovery,
subscription, snapshot copying, queue processing and drawing. Extract the source
ZIP into an empty folder, then run python tools/package_reference.py to rebuild
all three ZIPs under Distribution/GIMP/Reference/0.0.1. Python is only needed for
packaging, not for running either mod. Existing versioned ZIPs are never overwritten.

## What was tested

Native compilation completed without errors/warnings. Independent mods exchanged
numeric and string snapshots; consumer copies were processed after three seconds
while newer events had already arrived. No JSON serialization or filesystem reads
are used to exchange provider data.

This version preserves the exact tested implementation: it uses provider/value,
does not yet expose moddataversion, and includes type in notifications. The current
protocol README instead describes modid/values, moddataversion and contract-based
types. This is a transport reference, not a claim to implement every current rule.

The provider passes a native Blackboard snapshot through an existing delegate's
component parameter. The snapshot is borrowed only for the synchronous callback;
consumers copy fields before returning. Temporary actor allocation, reentrancy,
world teardown and save/load behavior need production review. Native numbers are
float32. Keep callbacks short and use bounded queues in production integrations.
