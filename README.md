# MandaGram SDK for Zig

Standalone Zig bindings and a plain-text native plugin example for MandaGram plugin authors. The reusable SDK is in `include/mandagram_plugin.zig`; the example removes the `.plain ` prefix from outgoing text.

Pinned to MandaGram engine `259fc5a38b64a12c85121838278f78ee72541dfb` and its 53-slot C ABI for Windows/Linux x64. Requires Zig 0.14.1. No client checkout or other SDK repository is needed to build.

See [building and consuming the SDK](docs/building.md) for commands, artifact paths, and compatibility and safety limitations. Source provenance is recorded in `sdk-source.json`.
