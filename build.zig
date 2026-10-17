const std = @import("std");

// Zig 0.14.1. The reusable module is independent of the plugin example.
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const sdk = b.addModule("mandagram_plugin", .{
        .root_source_file = b.path("include/mandagram_plugin.zig"),
    });
    const root = b.createModule(.{
        .root_source_file = b.path("examples/plain_text.zig"),
        .target = target,
        .optimize = optimize,
    });
    root.addImport("mandagram_plugin", sdk);
    const lib = b.addLibrary(.{
        .name = "plain_text",
        .linkage = .dynamic,
        .root_module = root,
    });
    b.installArtifact(lib);
}
