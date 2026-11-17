# ModKit discovery validation

Checked against the official Gothic 1 Remake ModKit native API reference on 2026-11-17.

This is an API/documentation validation, not an executed GIMP integration test.
No game scripts, mod installations or save data were changed.

## Confirmed exposed APIs

| Requirement | Documented API | Result |
|---|---|---|
| Enumerate enabled plugins | `Plugin::GetEnabledPluginNames()` returning `TArray<FString>` | Available |
| Resolve a package directory | `Plugin::GetPluginBaseDir(FString PluginName, FString& OutBaseDir)` | Available; returns success/failure |
| Query mount state | `Plugin::IsPluginMounted(FString PluginName)` | Available; useful additional information, not proof of a live provider report |
| Resolve a plugin descriptor | `Plugin::GetPluginDescriptorFilePath(FString PluginName, FString& OutFilePath)` | Available, but do not assume its result is the original `GothicMod.json` without a runtime check |
| Read a JSON source file | `FFileHelper::LoadFileToString(FString& Result, FString Filename, ...)` | Available |
| Parse a JSON document | `Json::ParseString(FString JsonStr)` returning `FJsonObject` | Available |
| Represent Gothic descriptor metadata | `FGothicModDesc.Metadata`, type `TMap<FString, FString>` | Available; values are strings |

The official package documentation states that mod packages are injected into
Unreal's plugin system during engine initialization. This supports using the
enabled-plugin APIs as the discovery mechanism. Their enumeration includes engine
plugins, so a consumer must filter for mod packages and valid protocol declarations.

## Custom metadata: correction to the original draft

The original nested declaration placed an object under `metadata.gimp`.
That does not match the documented string-to-string metadata type. Consumers
being able to parse raw JSON does not establish that the game's descriptor loader
accepts an object in a string-valued metadata field.

Use namespaced string entries instead:

```json
{
  "metadata": {
    "gimp.protocol": "GIMP",
    "gimp.protocolversion": "1",
    "gimp.provider": "exampleauthor.modname",
    "gimp.datafile": "exampleauthor.modname.json"
  }
}
```

The runtime data file is independent of the native descriptor schema. Its
`protocolversion` remains a JSON number, and its `value` object can contain the
types defined by each data contract.

## Proposed discovery procedure

1. Enumerate `Plugin::GetEnabledPluginNames()` after mod initialization.
2. Resolve each candidate's directory with `Plugin::GetPluginBaseDir()`.
3. Read the directory's `GothicMod.json`; skip packages without that file.
4. Parse it and validate the namespaced GIMP metadata fields.
5. Resolve the advertised data filename strictly inside the shared writable data directory.
6. Read the provider report and validate its identity, protocol version, freshness and session.

Each failed lookup, missing file or invalid document is an unavailable provider,
not a fatal dependency. Discovery alone does not prove a provider is publishing.

This procedure does not need a direct generic metadata getter, a mutable shared
registry, or references to another mod's script classes. A separate package-local
`GIMP.json` declaration remains an alternative design, rather than a requirement
imposed by unavailable discovery APIs.

## Runtime checks still outstanding

- Confirm enabled Gothic mods appear in the plugin enumeration and disabled mods
  are excluded, including command-line session overrides.
- Confirm resolution and raw descriptor reads for local installations, Steam
  Workshop packages and development directory overrides.
- Confirm the proposed string-valued metadata fields are accepted and preserved
  by the native loader and relevant mod-management operations.
- Exercise absent, malformed and unsupported declarations without stopping the consumer.

A read-only connection to the existing development metadata endpoint was attempted,
but no server was listening on port 27099. No game was launched or restarted for
this investigation. Native compilation and end-to-end behavior are therefore not
claimed as tested.

## Primary sources

- [Official mod package documentation](https://alkimiainteractive.github.io/G1R-Modkit/getting-started/mod-package/)
- [Plugin namespace reference](https://alkimiainteractive.github.io/G1R-Modkit/script-reference/namespace_plugin.html)
- [FGothicModDesc reference](https://alkimiainteractive.github.io/G1R-Modkit/script-reference/struct_f_gothic_mod_desc.html)
- [FFileHelper reference](https://alkimiainteractive.github.io/G1R-Modkit/script-reference/namespace_f_file_helper.html)
- [Json namespace reference](https://alkimiainteractive.github.io/G1R-Modkit/script-reference/namespace_json.html)
