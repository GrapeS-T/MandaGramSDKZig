const std = @import("std");
const sdk = @import("mandagram_plugin");

const metadata = sdk.PluginMetadata{
    .name = "Plain Text Zig",
    .version = "1.0.0",
    .author = "MandaGram Community",
    .description = "Removes the .plain prefix from outgoing text",
};

pub export fn mandagram_plugin_metadata() callconv(.c) *const sdk.PluginMetadata {
    return &metadata;
}

fn beforeSend(_: i64, text: [*:0]const u8, _: usize) callconv(.c) ?[*:0]const u8 {
    // The host copies this substring before releasing the input buffer.
    if (std.mem.startsWith(u8, std.mem.span(text), ".plain ")) return text + 7;
    return text;
}

pub export fn mandagram_plugin_init(api: *const sdk.PluginApi) callconv(.c) bool {
    const register = api.register_message_send_hook orelse return false;
    api.log_info("PlainZig", "Registering text hook");
    return register(beforeSend, null, 0) == 0;
}
