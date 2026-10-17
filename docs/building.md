# Building and consuming the Zig SDK

## Requirements

Use **Zig 0.14.1**, available as `zig` on PATH. The supported ABI targets are Windows x86-64 and Linux x86-64. Run commands from this repository root. The SDK is bundled: neither a MandaGram checkout, another SDK repository, package download, nor a C compiler is needed for this example.

## Build the example

On Linux x64 (shell):

```sh
zig build -Doptimize=ReleaseSafe
```

Output: `zig-out/lib/libplain_text.so`.

On Windows x64 (PowerShell):

```powershell
zig build -Doptimize=ReleaseSafe
```

Output: `zig-out/bin/plain_text.dll`. Any generated import library or debug symbols are not the plugin binary.

To select either supported target explicitly, including cross-compilation:

```sh
zig build -Doptimize=ReleaseSafe -Dtarget=x86_64-linux-gnu
zig build -Doptimize=ReleaseSafe -Dtarget=x86_64-windows-gnu
```

The target determines the same output paths above. The default install prefix is `zig-out`; `--prefix <directory>` changes it. This is a local build, not installation into or publication of the client.

`build.zig` publishes the reusable named module `mandagram_plugin` and builds `examples/plain_text.zig` as a dynamic library using that module. The example exports `mandagram_plugin_metadata` and `mandagram_plugin_init`, registers a before-send hook, and removes the `.plain ` prefix without allocating a replacement string. Its returned substring relies on the pinned host copying it before releasing the input buffer.

## Consume the bindings in another project

No package-manager setup is required. Copy the unchanged `include/mandagram_plugin.zig` into your project as `vendor/mandagram_plugin.zig`, retaining the source revision/provenance with your vendored copy. The bindings are self-contained and do not import the plugin example or require the C header at build time.

In your Zig 0.14.1 `build.zig`, after creating the root module for your plugin (called `root` here), add:

```zig
const sdk = b.createModule(.{
    .root_source_file = b.path("vendor/mandagram_plugin.zig"),
});
root.addImport("mandagram_plugin", sdk);
```

In your plugin source:

```zig
const sdk = @import("mandagram_plugin");
```

Use `sdk.PluginMetadata`, `sdk.PluginApi`, and the callback types for the C-compatible entrypoints illustrated by `examples/plain_text.zig`. Build your root module as a dynamic library, as shown by this repository's `build.zig`. Do not compile the example into your own plugin: its exported entrypoints belong to the example. The root build registers the same SDK as a named module with `b.addModule`; direct vendoring above avoids introducing a package manifest solely to consume this single-file SDK.

## Compatibility and safety

- The canonical bindings are preserved unchanged from the landing SDK, pinned to engine `259fc5a38b64a12c85121838278f78ee72541dfb`. The contract is the 53-slot C ABI for Windows/Linux x64, not a promise of compatibility with other engine revisions or architectures.
- There is no ABI-version negotiation, plugin deinitialization entrypoint, or hook-unregister API in this contract. Do not unload a library while the host can call its registered callbacks. A nullable function slot is not version negotiation and does not make reading a mismatched API table safe.
- Native plugins execute in the client's process without sandbox isolation. Incorrect pointers, lifetimes, calling conventions, or callback behavior can crash or compromise the client.
- Building or checking exports is not runtime certification. This SDK/example is not certified by a live-client run; no real account sessions, credentials, databases, or personal logs are included or required for building. Test runtime behavior only in a controlled environment with a matching client revision.
- `sdk-source.json` records source provenance. No additional license grant is inferred from copying these sources.

## Verification performed

2026-10-17: ReleaseSafe builds passed with Zig 0.14.1 for Windows x64 and the explicit x86_64-linux-gnu cross target. The DLL ran in an isolated Windows C++ host and the SO in a Linux x86_64 WSL host: exports, metadata, nine text boundary cases, borrowed pointer identity, rejected registration and missing registration function passed. A separate Windows ABI probe verified all 53 field offsets and the sizes of PluginApi, HookParam and PluginMetadata. Canonical headers and SHA256 matched the pinned engine Git blobs; publishable sources were scanned for binary files and credential patterns. Loading in MandaGram was not exercised. No client data or sessions were used.
