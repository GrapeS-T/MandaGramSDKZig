const std = @import("std");

pub const jobject = ?*anyopaque;

pub const HookParam = extern struct {
    this_ptr: ?*anyopaque,
    args: [*]?*anyopaque,
    args_count: u32,
    padding: u32 = 0,
    result: ?*anyopaque = null,
    return_early: u8 = 0,
    has_result: u8 = 0,
    reserved: u16 = 0,
    padding2: u32 = 0,

    pub inline fn cancel(self: *HookParam) void {
        self.return_early = 1;
    }

    pub inline fn setResult(self: *HookParam, res: ?*anyopaque) void {
        self.result = res;
        self.has_result = 1;
        self.return_early = 1;
    }

    pub inline fn getArg(self: *const HookParam, index: usize) ?*anyopaque {
        if (index < self.args_count) {
            return self.args[index];
        }
        return null;
    }

    pub fn replaceComposable(self: *HookParam, api: *const PluginApi, cb: ComposableFn, user_data: usize) void {
        if (api.replace_composable) |replace_fn| {
            replace_fn(self, cb, user_data);
        } else {
            self.cancel();
        }
    }
};

pub const ComposableFn = *const fn (composer: jobject, user_data: usize) callconv(.c) void;
pub const ScopedComposableFn = *const fn (scope: jobject, composer: jobject, user_data: usize) callconv(.c) void;

pub const HookBeforeFn = *const fn (param: *HookParam) callconv(.c) void;
pub const HookAfterFn = *const fn (param: *HookParam) callconv(.c) void;

pub const PluginMetadata = extern struct {
    name: [*:0]const u8,
    version: [*:0]const u8,
    author: [*:0]const u8,
    description: [*:0]const u8,
};

pub const UpdateHookFn = ?*const fn (update_json: [*:0]const u8, user_data: usize) callconv(.c) bool;
pub const MessageBeforeSendFn = ?*const fn (chat_id: i64, text: [*:0]const u8, user_data: usize) callconv(.c) ?[*:0]const u8;
pub const MessageAfterSendFn = ?*const fn (chat_id: i64, message_id: i64, user_data: usize) callconv(.c) void;
pub const MessageReceiveFn = ?*const fn (chat_id: i64, message_id: i64, text: [*:0]const u8, user_data: usize) callconv(.c) void;
pub const ChatActionClickFn = ?*const fn (chat_id: i64, user_data: usize) callconv(.c) void;

/// Чистый FFI API плагинной системы MandaGram (53 указателя на функции)
pub const PluginApi = extern struct {
    // 0..8: Ядро и инфраструктура
    register_hook: *const fn (
        class_name: [*:0]const u8,
        method_name: [*:0]const u8,
        method_descriptor: ?[*:0]const u8,
        before_callback: ?HookBeforeFn,
        after_callback: ?HookAfterFn,
    ) callconv(.c) i32,
    log_info: *const fn (tag: [*:0]const u8, msg: [*:0]const u8) callconv(.c) void,
    log_error: *const fn (tag: [*:0]const u8, msg: [*:0]const u8) callconv(.c) void,
    get_storage_dir: ?*const fn (plugin_name: [*:0]const u8, out_buf: [*]u8, max_len: u32) callconv(.c) i32 = null,
    get_cache_dir: ?*const fn (plugin_name: [*:0]const u8, out_buf: [*]u8, max_len: u32) callconv(.c) i32 = null,
    resolve_asset: ?*const fn (plugin_name: [*:0]const u8, asset_name: [*:0]const u8, out_buf: [*]u8, max_len: u32) callconv(.c) i32 = null,
    get_current_user_id: ?*const fn () callconv(.c) i64 = null,
    get_active_chat_id: ?*const fn () callconv(.c) i64 = null,
    execute_tdlib_query: ?*const fn (json_query: [*:0]const u8, out_buf: [*]u8, max_len: u32) callconv(.c) i32 = null,

    // 9..16: Низкоуровневые примитивы Compose рантайма
    create_composable_lambda: ?*const fn (cb: ComposableFn, user_data: usize) callconv(.c) jobject = null,
    create_scoped_lambda: ?*const fn (cb: ScopedComposableFn, user_data: usize) callconv(.c) jobject = null,
    replace_composable: ?*const fn (param: *HookParam, cb: ComposableFn, user_data: usize) callconv(.c) void = null,
    composer_start_group: ?*const fn (composer: jobject, key: i32) callconv(.c) void = null,
    composer_end_group: ?*const fn (composer: jobject) callconv(.c) void = null,
    composer_get_remembered: ?*const fn (composer: jobject) callconv(.c) jobject = null,
    composer_set_remembered: ?*const fn (composer: jobject, val: jobject) callconv(.c) void = null,
    composer_is_skipping: ?*const fn (composer: jobject) callconv(.c) bool = null,

    // 17..20: Высокоуровневые хуки событий MandaGram (HookRegistry)
    register_update_hook: ?*const fn (cb: UpdateHookFn, user_data: usize) callconv(.c) i32 = null,
    register_message_send_hook: ?*const fn (before_cb: MessageBeforeSendFn, after_cb: MessageAfterSendFn, user_data: usize) callconv(.c) i32 = null,
    register_message_receive_hook: ?*const fn (cb: MessageReceiveFn, user_data: usize) callconv(.c) i32 = null,
    register_chat_action: ?*const fn (id: [*:0]const u8, label: [*:0]const u8, click_cb: ChatActionClickFn, user_data: usize) callconv(.c) i32 = null,

    // 21..34: Чистая FFI рефлексия объектов и полей
    get_object_field: ?*const fn (obj: jobject, field_name: [*:0]const u8) callconv(.c) jobject = null,
    set_object_field: ?*const fn (obj: jobject, field_name: [*:0]const u8, val: jobject) callconv(.c) void = null,
    get_int_field: ?*const fn (obj: jobject, field_name: [*:0]const u8) callconv(.c) i32 = null,
    set_int_field: ?*const fn (obj: jobject, field_name: [*:0]const u8, val: i32) callconv(.c) void = null,
    get_long_field: ?*const fn (obj: jobject, field_name: [*:0]const u8) callconv(.c) i64 = null,
    set_long_field: ?*const fn (obj: jobject, field_name: [*:0]const u8, val: i64) callconv(.c) void = null,
    get_bool_field: ?*const fn (obj: jobject, field_name: [*:0]const u8) callconv(.c) bool = null,
    set_bool_field: ?*const fn (obj: jobject, field_name: [*:0]const u8, val: bool) callconv(.c) void = null,
    get_string_utf: ?*const fn (jstr: jobject, out_buf: [*]u8, max_len: u32) callconv(.c) i32 = null,
    create_string_utf: ?*const fn (str: [*:0]const u8) callconv(.c) jobject = null,
    get_attached_field: ?*const fn (obj: jobject, key: [*:0]const u8) callconv(.c) jobject = null,
    set_attached_field: ?*const fn (obj: jobject, key: [*:0]const u8, val: jobject) callconv(.c) void = null,
    get_state_value: ?*const fn (state_obj: jobject) callconv(.c) jobject = null,
    set_state_value: ?*const fn (state_obj: jobject, val: jobject) callconv(.c) void = null,

    // 35..45: Модификаторы Compose через чистый FFI
    modifier_empty: ?*const fn () callconv(.c) jobject = null,
    modifier_size: ?*const fn (mod: jobject, width_dp: f32, height_dp: f32) callconv(.c) jobject = null,
    modifier_width: ?*const fn (mod: jobject, width_dp: f32) callconv(.c) jobject = null,
    modifier_height: ?*const fn (mod: jobject, height_dp: f32) callconv(.c) jobject = null,
    modifier_fill_max_width: ?*const fn (mod: jobject) callconv(.c) jobject = null,
    modifier_fill_max_height: ?*const fn (mod: jobject) callconv(.c) jobject = null,
    modifier_padding: ?*const fn (mod: jobject, start_dp: f32, top_dp: f32, end_dp: f32, bottom_dp: f32) callconv(.c) jobject = null,
    modifier_background: ?*const fn (mod: jobject, argb: u32, corner_radius_dp: f32) callconv(.c) jobject = null,
    modifier_border: ?*const fn (mod: jobject, width_dp: f32, argb: u32, corner_radius_dp: f32) callconv(.c) jobject = null,
    modifier_clickable: ?*const fn (mod: jobject, on_click_lambda: jobject) callconv(.c) jobject = null,
    modifier_weight: ?*const fn (scope: jobject, mod: jobject, weight: f32) callconv(.c) jobject = null,

    // 46..52: Компоненты Compose через чистый FFI
    compose_row: ?*const fn (composer: jobject, mod: jobject, content_lambda: jobject) callconv(.c) void = null,
    compose_column: ?*const fn (composer: jobject, mod: jobject, content_lambda: jobject) callconv(.c) void = null,
    compose_box: ?*const fn (composer: jobject, mod: jobject, content_lambda: jobject) callconv(.c) void = null,
    compose_spacer: ?*const fn (composer: jobject, mod: jobject) callconv(.c) void = null,
    compose_text: ?*const fn (composer: jobject, text: [*:0]const u8, mod: jobject, argb: u32, font_size_sp: f32, is_bold: bool, max_lines: i32) callconv(.c) void = null,
    compose_image: ?*const fn (composer: jobject, bitmap: jobject, mod: jobject) callconv(.c) void = null,
    get_avatar_bitmap: ?*const fn (path: [*:0]const u8) callconv(.c) jobject = null,
};

/// Удобные обертки Zig для работы с Modifier
pub const Modifier = struct {
    pub inline fn empty(api: *const PluginApi) jobject {
        return if (api.modifier_empty) |f| f() else null;
    }

    pub inline fn size(api: *const PluginApi, mod: jobject, w_dp: f32, h_dp: f32) jobject {
        return if (api.modifier_size) |f| f(mod, w_dp, h_dp) else mod;
    }

    pub inline fn width(api: *const PluginApi, mod: jobject, w_dp: f32) jobject {
        return if (api.modifier_width) |f| f(mod, w_dp) else mod;
    }

    pub inline fn height(api: *const PluginApi, mod: jobject, h_dp: f32) jobject {
        return if (api.modifier_height) |f| f(mod, h_dp) else mod;
    }

    pub inline fn fillMaxWidth(api: *const PluginApi, mod: jobject) jobject {
        return if (api.modifier_fill_max_width) |f| f(mod) else mod;
    }

    pub inline fn fillMaxHeight(api: *const PluginApi, mod: jobject) jobject {
        return if (api.modifier_fill_max_height) |f| f(mod) else mod;
    }

    pub inline fn padding(api: *const PluginApi, mod: jobject, start_dp: f32, top_dp: f32, end_dp: f32, bottom_dp: f32) jobject {
        return if (api.modifier_padding) |f| f(mod, start_dp, top_dp, end_dp, bottom_dp) else mod;
    }

    pub inline fn background(api: *const PluginApi, mod: jobject, argb: u32, corner_radius_dp: f32) jobject {
        return if (api.modifier_background) |f| f(mod, argb, corner_radius_dp) else mod;
    }

    pub inline fn border(api: *const PluginApi, mod: jobject, width_dp: f32, argb: u32, corner_radius_dp: f32) jobject {
        return if (api.modifier_border) |f| f(mod, width_dp, argb, corner_radius_dp) else mod;
    }

    pub inline fn clickable(api: *const PluginApi, mod: jobject, on_click_lambda: jobject) jobject {
        return if (api.modifier_clickable) |f| f(mod, on_click_lambda) else mod;
    }

    pub inline fn weight(api: *const PluginApi, scope: jobject, mod: jobject, w: f32) jobject {
        return if (api.modifier_weight) |f| f(scope, mod, w) else mod;
    }
};

/// Удобные обертки Zig для компонентов Compose
pub const Compose = struct {
    pub inline fn row(api: *const PluginApi, composer: jobject, mod: jobject, content_lambda: jobject) void {
        if (api.compose_row) |f| f(composer, mod, content_lambda);
    }

    pub inline fn column(api: *const PluginApi, composer: jobject, mod: jobject, content_lambda: jobject) void {
        if (api.compose_column) |f| f(composer, mod, content_lambda);
    }

    pub inline fn box(api: *const PluginApi, composer: jobject, mod: jobject, content_lambda: jobject) void {
        if (api.compose_box) |f| f(composer, mod, content_lambda);
    }

    pub inline fn spacer(api: *const PluginApi, composer: jobject, mod: jobject) void {
        if (api.compose_spacer) |f| f(composer, mod);
    }

    pub inline fn text(
        api: *const PluginApi,
        composer: jobject,
        str: [*:0]const u8,
        mod: jobject,
        argb: u32,
        font_size_sp: f32,
        is_bold: bool,
        max_lines: i32,
    ) void {
        if (api.compose_text) |f| f(composer, str, mod, argb, font_size_sp, is_bold, max_lines);
    }

    pub inline fn image(api: *const PluginApi, composer: jobject, bitmap: jobject, mod: jobject) void {
        if (api.compose_image) |f| f(composer, bitmap, mod);
    }

    pub inline fn getAvatarBitmap(api: *const PluginApi, path: [*:0]const u8) jobject {
        return if (api.get_avatar_bitmap) |f| f(path) else null;
    }
};
