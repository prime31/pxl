const __root = @This();
pub const __builtin = @import("c_builtins");
pub const __helpers = @import("helpers");

pub const int_least8_t = i8;
pub const int_least16_t = i16;
pub const int_least32_t = i32;
pub const int_least64_t = i64;
pub const uint_least8_t = u8;
pub const uint_least16_t = u16;
pub const uint_least32_t = u32;
pub const uint_least64_t = u64;
pub const int_fast8_t = i8;
pub const int_fast16_t = i16;
pub const int_fast32_t = i32;
pub const int_fast64_t = i64;
pub const uint_fast8_t = u8;
pub const uint_fast16_t = u16;
pub const uint_fast32_t = u32;
pub const uint_fast64_t = u64;
pub const __int8_t = i8;
pub const __uint8_t = u8;
pub const __int16_t = c_short;
pub const __uint16_t = c_ushort;
pub const __int32_t = c_int;
pub const __uint32_t = c_uint;
pub const __int64_t = c_longlong;
pub const __uint64_t = c_ulonglong;
pub const __darwin_intptr_t = c_long;
pub const __darwin_natural_t = c_uint;
pub const __darwin_ct_rune_t = c_int;
pub const __mbstate_t = extern union {
    __mbstate8: [128]u8,
    _mbstateL: c_longlong,
};
pub const __darwin_mbstate_t = __mbstate_t;
pub const __darwin_ptrdiff_t = c_long;
pub const __darwin_size_t = c_ulong;
pub const __builtin_va_list = [*c]u8;
pub const __darwin_va_list = __builtin_va_list;
pub const __darwin_wchar_t = c_int;
pub const __darwin_rune_t = __darwin_wchar_t;
pub const __darwin_wint_t = c_int;
pub const __darwin_clock_t = c_ulong;
pub const __darwin_socklen_t = __uint32_t;
pub const __darwin_ssize_t = c_long;
pub const __darwin_time_t = c_long;
pub const __darwin_blkcnt_t = __int64_t;
pub const __darwin_blksize_t = __int32_t;
pub const __darwin_dev_t = __int32_t;
pub const __darwin_fsblkcnt_t = c_uint;
pub const __darwin_fsfilcnt_t = c_uint;
pub const __darwin_gid_t = __uint32_t;
pub const __darwin_id_t = __uint32_t;
pub const __darwin_ino64_t = __uint64_t;
pub const __darwin_ino_t = __darwin_ino64_t;
pub const __darwin_mach_port_name_t = __darwin_natural_t;
pub const __darwin_mach_port_t = __darwin_mach_port_name_t;
pub const __darwin_mode_t = __uint16_t;
pub const __darwin_off_t = __int64_t;
pub const __darwin_pid_t = __int32_t;
pub const __darwin_sigset_t = __uint32_t;
pub const __darwin_suseconds_t = __int32_t;
pub const __darwin_uid_t = __uint32_t;
pub const __darwin_useconds_t = __uint32_t;
pub const __darwin_uuid_t = [16]u8;
pub const __darwin_uuid_string_t = [37]u8;
pub const struct___darwin_pthread_handler_rec = extern struct {
    __routine: ?*const fn (?*anyopaque) callconv(.c) void,
    __arg: ?*anyopaque,
    __next: [*c]struct___darwin_pthread_handler_rec,
};
pub const struct__opaque_pthread_attr_t = extern struct {
    __sig: c_long,
    __opaque: [56]u8,
};
pub const struct__opaque_pthread_cond_t = extern struct {
    __sig: c_long,
    __opaque: [40]u8,
};
pub const struct__opaque_pthread_condattr_t = extern struct {
    __sig: c_long,
    __opaque: [8]u8,
};
pub const struct__opaque_pthread_mutex_t = extern struct {
    __sig: c_long,
    __opaque: [56]u8,
};
pub const struct__opaque_pthread_mutexattr_t = extern struct {
    __sig: c_long,
    __opaque: [8]u8,
};
pub const struct__opaque_pthread_once_t = extern struct {
    __sig: c_long,
    __opaque: [8]u8,
};
pub const struct__opaque_pthread_rwlock_t = extern struct {
    __sig: c_long,
    __opaque: [192]u8,
};
pub const struct__opaque_pthread_rwlockattr_t = extern struct {
    __sig: c_long,
    __opaque: [16]u8,
};
pub const struct__opaque_pthread_t = extern struct {
    __sig: c_long,
    __cleanup_stack: [*c]struct___darwin_pthread_handler_rec,
    __opaque: [8176]u8,
};
pub const __darwin_pthread_attr_t = struct__opaque_pthread_attr_t;
pub const __darwin_pthread_cond_t = struct__opaque_pthread_cond_t;
pub const __darwin_pthread_condattr_t = struct__opaque_pthread_condattr_t;
pub const __darwin_pthread_key_t = c_ulong;
pub const __darwin_pthread_mutex_t = struct__opaque_pthread_mutex_t;
pub const __darwin_pthread_mutexattr_t = struct__opaque_pthread_mutexattr_t;
pub const __darwin_pthread_once_t = struct__opaque_pthread_once_t;
pub const __darwin_pthread_rwlock_t = struct__opaque_pthread_rwlock_t;
pub const __darwin_pthread_rwlockattr_t = struct__opaque_pthread_rwlockattr_t;
pub const __darwin_pthread_t = [*c]struct__opaque_pthread_t;
pub const intmax_t = c_long;
pub const uintmax_t = c_ulong;
pub const va_list = __builtin_va_list;
pub const __gnuc_va_list = __builtin_va_list;
pub const __darwin_nl_item = c_int;
pub const __darwin_wctrans_t = c_int;
pub const __darwin_wctype_t = __uint32_t;
pub const u_int8_t = u8;
pub const u_int16_t = c_ushort;
pub const u_int32_t = c_uint;
pub const u_int64_t = c_ulonglong;
pub const register_t = i64;
pub const user_addr_t = u_int64_t;
pub const user_size_t = u_int64_t;
pub const user_ssize_t = i64;
pub const user_long_t = i64;
pub const user_ulong_t = u_int64_t;
pub const user_time_t = i64;
pub const user_off_t = i64;
pub const syscall_arg_t = u_int64_t;
pub const ptrdiff_t = __darwin_ptrdiff_t;
pub const rsize_t = __darwin_size_t;
pub const wchar_t = __darwin_wchar_t;
pub const wint_t = __darwin_wint_t;
pub const max_align_t = c_longdouble;
pub const struct_ImVec2_t = extern struct {
    x: f32,
    y: f32,
    pub const igSetNextWindowPos = __root.igSetNextWindowPos;
    pub const igSetNextWindowPosEx = __root.igSetNextWindowPosEx;
    pub const igSetNextWindowSize = __root.igSetNextWindowSize;
    pub const igSetNextWindowSizeConstraints = __root.igSetNextWindowSizeConstraints;
    pub const igSetNextWindowContentSize = __root.igSetNextWindowContentSize;
    pub const igSetNextWindowScroll = __root.igSetNextWindowScroll;
    pub const igSetWindowPos = __root.igSetWindowPos;
    pub const igSetWindowSize = __root.igSetWindowSize;
    pub const igSetCursorScreenPos = __root.igSetCursorScreenPos;
    pub const igSetCursorPos = __root.igSetCursorPos;
    pub const igDummy = __root.igDummy;
    pub const igPushClipRect = __root.igPushClipRect;
    pub const igIsRectVisibleBySize = __root.igIsRectVisibleBySize;
    pub const igIsRectVisible = __root.igIsRectVisible;
    pub const igIsMouseHoveringRect = __root.igIsMouseHoveringRect;
    pub const igIsMouseHoveringRectEx = __root.igIsMouseHoveringRectEx;
    pub const igIsMousePosValid = __root.igIsMousePosValid;
};
pub const ImVec2 = struct_ImVec2_t;
pub const struct_ImVec4_t = extern struct {
    x: f32,
    y: f32,
    z: f32,
    w: f32,
    pub const igGetColorU32ImVec4 = __root.igGetColorU32ImVec4;
    pub const igTextColored = __root.igTextColored;
    pub const igTextColoredV = __root.igTextColoredV;
    pub const igColorConvertFloat4ToU32 = __root.igColorConvertFloat4ToU32;
};
pub const ImVec4 = struct_ImVec4_t;
pub const ImU64 = c_ulonglong;
pub const ImTextureID = ImU64;
pub const struct_ImTextureRect_t = extern struct {
    x: c_ushort,
    y: c_ushort,
    w: c_ushort,
    h: c_ushort,
};
pub const ImTextureRect = struct_ImTextureRect_t;
pub const struct_ImVector_ImTextureRect_t = extern struct {
    Size: c_int,
    Capacity: c_int,
    Data: [*c]ImTextureRect,
};
pub const ImVector_ImTextureRect = struct_ImVector_ImTextureRect_t;
pub const struct_ImTextureData_t = extern struct {
    UniqueID: c_int,
    Status: ImTextureStatus,
    BackendUserData: ?*anyopaque,
    QueueUserData: ?*anyopaque,
    TexID: ImTextureID,
    Format: ImTextureFormat,
    Width: c_int,
    Height: c_int,
    BytesPerPixel: c_int,
    Pixels: [*c]u8,
    UsedRect: ImTextureRect,
    UpdateRect: ImTextureRect,
    Updates: ImVector_ImTextureRect,
    UnusedFrames: c_int,
    RefCount: c_ushort,
    UseColors: bool,
    WantDestroyNextFrame: bool,
    pub const ImTextureData_Create = __root.ImTextureData_Create;
    pub const ImTextureData_DestroyPixels = __root.ImTextureData_DestroyPixels;
    pub const ImTextureData_GetPixels = __root.ImTextureData_GetPixels;
    pub const ImTextureData_GetPixelsAt = __root.ImTextureData_GetPixelsAt;
    pub const ImTextureData_GetSizeInBytes = __root.ImTextureData_GetSizeInBytes;
    pub const ImTextureData_GetPitch = __root.ImTextureData_GetPitch;
    pub const ImTextureData_GetTexRef = __root.ImTextureData_GetTexRef;
    pub const ImTextureData_GetTexID = __root.ImTextureData_GetTexID;
    pub const ImTextureData_SetTexID = __root.ImTextureData_SetTexID;
    pub const ImTextureData_SetStatus = __root.ImTextureData_SetStatus;
    pub const Create = __root.ImTextureData_Create;
    pub const DestroyPixels = __root.ImTextureData_DestroyPixels;
    pub const GetPixels = __root.ImTextureData_GetPixels;
    pub const GetPixelsAt = __root.ImTextureData_GetPixelsAt;
    pub const GetSizeInBytes = __root.ImTextureData_GetSizeInBytes;
    pub const GetPitch = __root.ImTextureData_GetPitch;
    pub const GetTexRef = __root.ImTextureData_GetTexRef;
    pub const GetTexID = __root.ImTextureData_GetTexID;
    pub const SetTexID = __root.ImTextureData_SetTexID;
    pub const SetStatus = __root.ImTextureData_SetStatus;
};
pub const ImTextureData = struct_ImTextureData_t;
pub const struct_ImTextureRef_t = extern struct {
    _TexData: [*c]ImTextureData,
    _TexID: ImTextureID,
    pub const ImTextureRef_GetTexID = __root.ImTextureRef_GetTexID;
    pub const igImage = __root.igImage;
    pub const igImageEx = __root.igImageEx;
    pub const igImageWithBg = __root.igImageWithBg;
    pub const igImageWithBgEx = __root.igImageWithBgEx;
    pub const igImageImVec4 = __root.igImageImVec4;
    pub const GetTexID = __root.ImTextureRef_GetTexID;
};
pub const ImTextureRef = struct_ImTextureRef_t;
pub const struct_ImGuiTextFilter_ImGuiTextRange_t = extern struct {
    b: [*c]const u8,
    e: [*c]const u8,
    pub const ImGuiTextFilter_ImGuiTextRange_empty = __root.ImGuiTextFilter_ImGuiTextRange_empty;
    pub const ImGuiTextFilter_ImGuiTextRange_split = __root.ImGuiTextFilter_ImGuiTextRange_split;
    pub const empty = __root.ImGuiTextFilter_ImGuiTextRange_empty;
    pub const split = __root.ImGuiTextFilter_ImGuiTextRange_split;
};
pub const ImGuiTextFilter_ImGuiTextRange = struct_ImGuiTextFilter_ImGuiTextRange_t;
pub const struct_ImVector_ImGuiTextRange_t = extern struct {
    Size: c_int,
    Capacity: c_int,
    Data: [*c]ImGuiTextFilter_ImGuiTextRange,
};
pub const ImVector_ImGuiTextRange = struct_ImVector_ImGuiTextRange_t;
pub const struct_ImVector_char_t = extern struct {
    Size: c_int,
    Capacity: c_int,
    Data: [*c]u8,
};
pub const ImVector_char = struct_ImVector_char_t;
pub const ImGuiID = c_uint;
const union_unnamed_1 = extern union {
    val_i: c_int,
    val_f: f32,
    val_p: ?*anyopaque,
};
pub const struct_ImGuiStoragePair_t = extern struct {
    key: ImGuiID,
    unnamed_0: union_unnamed_1,
};
pub const ImGuiStoragePair = struct_ImGuiStoragePair_t;
pub const struct_ImVector_ImGuiStoragePair_t = extern struct {
    Size: c_int,
    Capacity: c_int,
    Data: [*c]ImGuiStoragePair,
};
pub const ImVector_ImGuiStoragePair = struct_ImVector_ImGuiStoragePair_t;
pub const ImS8 = i8;
pub const ImS64 = c_longlong;
pub const ImGuiSelectionUserData = ImS64;
pub const struct_ImGuiSelectionRequest_t = extern struct {
    Type: ImGuiSelectionRequestType,
    Selected: bool,
    RangeDirection: ImS8,
    RangeFirstItem: ImGuiSelectionUserData,
    RangeLastItem: ImGuiSelectionUserData,
};
pub const ImGuiSelectionRequest = struct_ImGuiSelectionRequest_t;
pub const struct_ImVector_ImGuiSelectionRequest_t = extern struct {
    Size: c_int,
    Capacity: c_int,
    Data: [*c]ImGuiSelectionRequest,
};
pub const ImVector_ImGuiSelectionRequest = struct_ImVector_ImGuiSelectionRequest_t;
pub const ImDrawIdx = c_ushort;
pub const struct_ImVector_ImDrawIdx_t = extern struct {
    Size: c_int,
    Capacity: c_int,
    Data: [*c]ImDrawIdx,
};
pub const ImVector_ImDrawIdx = struct_ImVector_ImDrawIdx_t;
pub const ImU32 = c_uint;
pub const struct_ImDrawVert_t = extern struct {
    pos: ImVec2,
    uv: ImVec2,
    col: ImU32,
};
pub const ImDrawVert = struct_ImDrawVert_t;
pub const struct_ImVector_ImDrawVert_t = extern struct {
    Size: c_int,
    Capacity: c_int,
    Data: [*c]ImDrawVert,
};
pub const ImVector_ImDrawVert = struct_ImVector_ImDrawVert_t;
pub const ImDrawListFlags = c_int;
pub const struct_ImDrawListSharedData_t = opaque {};
pub const ImDrawListSharedData = struct_ImDrawListSharedData_t;
pub const struct_ImVector_ImVec2_t = extern struct {
    Size: c_int,
    Capacity: c_int,
    Data: [*c]ImVec2,
};
pub const ImVector_ImVec2 = struct_ImVector_ImVec2_t;
pub const struct_ImDrawCmdHeader_t = extern struct {
    ClipRect: ImVec4,
    TexRef: ImTextureRef,
    VtxOffset: c_uint,
};
pub const ImDrawCmdHeader = struct_ImDrawCmdHeader_t;
pub const ImVector_ImDrawChannel = struct_ImVector_ImDrawChannel_t;
pub const struct_ImDrawListSplitter_t = extern struct {
    _Current: c_int,
    _Count: c_int,
    _Channels: ImVector_ImDrawChannel,
    pub const ImDrawListSplitter_Clear = __root.ImDrawListSplitter_Clear;
    pub const ImDrawListSplitter_ClearFreeMemory = __root.ImDrawListSplitter_ClearFreeMemory;
    pub const ImDrawListSplitter_Split = __root.ImDrawListSplitter_Split;
    pub const ImDrawListSplitter_Merge = __root.ImDrawListSplitter_Merge;
    pub const ImDrawListSplitter_SetCurrentChannel = __root.ImDrawListSplitter_SetCurrentChannel;
    pub const Clear = __root.ImDrawListSplitter_Clear;
    pub const ClearFreeMemory = __root.ImDrawListSplitter_ClearFreeMemory;
    pub const Split = __root.ImDrawListSplitter_Split;
    pub const Merge = __root.ImDrawListSplitter_Merge;
    pub const SetCurrentChannel = __root.ImDrawListSplitter_SetCurrentChannel;
};
pub const ImDrawListSplitter = struct_ImDrawListSplitter_t;
pub const struct_ImVector_ImVec4_t = extern struct {
    Size: c_int,
    Capacity: c_int,
    Data: [*c]ImVec4,
};
pub const ImVector_ImVec4 = struct_ImVector_ImVec4_t;
pub const struct_ImVector_ImTextureRef_t = extern struct {
    Size: c_int,
    Capacity: c_int,
    Data: [*c]ImTextureRef,
};
pub const ImVector_ImTextureRef = struct_ImVector_ImTextureRef_t;
pub const ImU8 = u8;
pub const struct_ImVector_ImU8_t = extern struct {
    Size: c_int,
    Capacity: c_int,
    Data: [*c]ImU8,
};
pub const ImVector_ImU8 = struct_ImVector_ImU8_t;
pub const struct_ImDrawList_t = extern struct {
    CmdBuffer: ImVector_ImDrawCmd,
    IdxBuffer: ImVector_ImDrawIdx,
    VtxBuffer: ImVector_ImDrawVert,
    Flags: ImDrawListFlags,
    _VtxCurrentIdx: c_uint,
    _Data: ?*ImDrawListSharedData,
    _VtxWritePtr: [*c]ImDrawVert,
    _IdxWritePtr: [*c]ImDrawIdx,
    _Path: ImVector_ImVec2,
    _CmdHeader: ImDrawCmdHeader,
    _Splitter: ImDrawListSplitter,
    _ClipRectStack: ImVector_ImVec4,
    _TextureStack: ImVector_ImTextureRef,
    _CallbacksDataBuf: ImVector_ImU8,
    _FringeScale: f32,
    _OwnerName: [*c]const u8,
    pub const ImDrawList_PushClipRect = __root.ImDrawList_PushClipRect;
    pub const ImDrawList_PushClipRectFullScreen = __root.ImDrawList_PushClipRectFullScreen;
    pub const ImDrawList_PopClipRect = __root.ImDrawList_PopClipRect;
    pub const ImDrawList_PushTexture = __root.ImDrawList_PushTexture;
    pub const ImDrawList_PopTexture = __root.ImDrawList_PopTexture;
    pub const ImDrawList_GetClipRectMin = __root.ImDrawList_GetClipRectMin;
    pub const ImDrawList_GetClipRectMax = __root.ImDrawList_GetClipRectMax;
    pub const ImDrawList_AddLine = __root.ImDrawList_AddLine;
    pub const ImDrawList_AddLineEx = __root.ImDrawList_AddLineEx;
    pub const ImDrawList_AddLineH = __root.ImDrawList_AddLineH;
    pub const ImDrawList_AddLineHEx = __root.ImDrawList_AddLineHEx;
    pub const ImDrawList_AddLineV = __root.ImDrawList_AddLineV;
    pub const ImDrawList_AddLineVEx = __root.ImDrawList_AddLineVEx;
    pub const ImDrawList_AddRect = __root.ImDrawList_AddRect;
    pub const ImDrawList_AddRectEx = __root.ImDrawList_AddRectEx;
    pub const ImDrawList_AddRectFilled = __root.ImDrawList_AddRectFilled;
    pub const ImDrawList_AddRectFilledEx = __root.ImDrawList_AddRectFilledEx;
    pub const ImDrawList_AddRectFilledMultiColor = __root.ImDrawList_AddRectFilledMultiColor;
    pub const ImDrawList_AddQuad = __root.ImDrawList_AddQuad;
    pub const ImDrawList_AddQuadEx = __root.ImDrawList_AddQuadEx;
    pub const ImDrawList_AddQuadFilled = __root.ImDrawList_AddQuadFilled;
    pub const ImDrawList_AddTriangle = __root.ImDrawList_AddTriangle;
    pub const ImDrawList_AddTriangleEx = __root.ImDrawList_AddTriangleEx;
    pub const ImDrawList_AddTriangleFilled = __root.ImDrawList_AddTriangleFilled;
    pub const ImDrawList_AddCircle = __root.ImDrawList_AddCircle;
    pub const ImDrawList_AddCircleEx = __root.ImDrawList_AddCircleEx;
    pub const ImDrawList_AddCircleFilled = __root.ImDrawList_AddCircleFilled;
    pub const ImDrawList_AddNgon = __root.ImDrawList_AddNgon;
    pub const ImDrawList_AddNgonEx = __root.ImDrawList_AddNgonEx;
    pub const ImDrawList_AddNgonFilled = __root.ImDrawList_AddNgonFilled;
    pub const ImDrawList_AddEllipse = __root.ImDrawList_AddEllipse;
    pub const ImDrawList_AddEllipseEx = __root.ImDrawList_AddEllipseEx;
    pub const ImDrawList_AddEllipseFilled = __root.ImDrawList_AddEllipseFilled;
    pub const ImDrawList_AddEllipseFilledEx = __root.ImDrawList_AddEllipseFilledEx;
    pub const ImDrawList_AddText = __root.ImDrawList_AddText;
    pub const ImDrawList_AddTextEx = __root.ImDrawList_AddTextEx;
    pub const ImDrawList_AddTextImFontPtr = __root.ImDrawList_AddTextImFontPtr;
    pub const ImDrawList_AddTextImFontPtrEx = __root.ImDrawList_AddTextImFontPtrEx;
    pub const ImDrawList_AddBezierCubic = __root.ImDrawList_AddBezierCubic;
    pub const ImDrawList_AddBezierQuadratic = __root.ImDrawList_AddBezierQuadratic;
    pub const ImDrawList_AddPolyline = __root.ImDrawList_AddPolyline;
    pub const ImDrawList_AddConvexPolyFilled = __root.ImDrawList_AddConvexPolyFilled;
    pub const ImDrawList_AddConcavePolyFilled = __root.ImDrawList_AddConcavePolyFilled;
    pub const ImDrawList_AddImage = __root.ImDrawList_AddImage;
    pub const ImDrawList_AddImageEx = __root.ImDrawList_AddImageEx;
    pub const ImDrawList_AddImageQuad = __root.ImDrawList_AddImageQuad;
    pub const ImDrawList_AddImageQuadEx = __root.ImDrawList_AddImageQuadEx;
    pub const ImDrawList_AddImageRounded = __root.ImDrawList_AddImageRounded;
    pub const ImDrawList_PathClear = __root.ImDrawList_PathClear;
    pub const ImDrawList_PathLineTo = __root.ImDrawList_PathLineTo;
    pub const ImDrawList_PathLineToMergeDuplicate = __root.ImDrawList_PathLineToMergeDuplicate;
    pub const ImDrawList_PathFillConvex = __root.ImDrawList_PathFillConvex;
    pub const ImDrawList_PathFillConcave = __root.ImDrawList_PathFillConcave;
    pub const ImDrawList_PathStroke = __root.ImDrawList_PathStroke;
    pub const ImDrawList_PathArcTo = __root.ImDrawList_PathArcTo;
    pub const ImDrawList_PathArcToFast = __root.ImDrawList_PathArcToFast;
    pub const ImDrawList_PathEllipticalArcTo = __root.ImDrawList_PathEllipticalArcTo;
    pub const ImDrawList_PathEllipticalArcToEx = __root.ImDrawList_PathEllipticalArcToEx;
    pub const ImDrawList_PathBezierCubicCurveTo = __root.ImDrawList_PathBezierCubicCurveTo;
    pub const ImDrawList_PathBezierQuadraticCurveTo = __root.ImDrawList_PathBezierQuadraticCurveTo;
    pub const ImDrawList_PathRect = __root.ImDrawList_PathRect;
    pub const ImDrawList_AddCallback = __root.ImDrawList_AddCallback;
    pub const ImDrawList_AddCallbackEx = __root.ImDrawList_AddCallbackEx;
    pub const ImDrawList_AddDrawCmd = __root.ImDrawList_AddDrawCmd;
    pub const ImDrawList_CloneOutput = __root.ImDrawList_CloneOutput;
    pub const ImDrawList_ChannelsSplit = __root.ImDrawList_ChannelsSplit;
    pub const ImDrawList_ChannelsMerge = __root.ImDrawList_ChannelsMerge;
    pub const ImDrawList_ChannelsSetCurrent = __root.ImDrawList_ChannelsSetCurrent;
    pub const ImDrawList_PrimReserve = __root.ImDrawList_PrimReserve;
    pub const ImDrawList_PrimUnreserve = __root.ImDrawList_PrimUnreserve;
    pub const ImDrawList_PrimRect = __root.ImDrawList_PrimRect;
    pub const ImDrawList_PrimRectUV = __root.ImDrawList_PrimRectUV;
    pub const ImDrawList_PrimQuadUV = __root.ImDrawList_PrimQuadUV;
    pub const ImDrawList_PrimWriteVtx = __root.ImDrawList_PrimWriteVtx;
    pub const ImDrawList_PrimWriteIdx = __root.ImDrawList_PrimWriteIdx;
    pub const ImDrawList_PrimVtx = __root.ImDrawList_PrimVtx;
    pub const ImDrawList_AddRectImDrawFlags = __root.ImDrawList_AddRectImDrawFlags;
    pub const ImDrawList_AddPolylineImDrawFlags = __root.ImDrawList_AddPolylineImDrawFlags;
    pub const ImDrawList_PathStrokeImDrawFlags = __root.ImDrawList_PathStrokeImDrawFlags;
    pub const ImDrawList_PushTextureID = __root.ImDrawList_PushTextureID;
    pub const ImDrawList_PopTextureID = __root.ImDrawList_PopTextureID;
    pub const ImDrawList__SetDrawListSharedData = __root.ImDrawList__SetDrawListSharedData;
    pub const ImDrawList__ResetForNewFrame = __root.ImDrawList__ResetForNewFrame;
    pub const ImDrawList__ClearFreeMemory = __root.ImDrawList__ClearFreeMemory;
    pub const ImDrawList__PopUnusedDrawCmd = __root.ImDrawList__PopUnusedDrawCmd;
    pub const ImDrawList__TryMergeDrawCmds = __root.ImDrawList__TryMergeDrawCmds;
    pub const ImDrawList__OnChangedClipRect = __root.ImDrawList__OnChangedClipRect;
    pub const ImDrawList__OnChangedTexture = __root.ImDrawList__OnChangedTexture;
    pub const ImDrawList__OnChangedVtxOffset = __root.ImDrawList__OnChangedVtxOffset;
    pub const ImDrawList__SetTexture = __root.ImDrawList__SetTexture;
    pub const ImDrawList__CalcCircleAutoSegmentCount = __root.ImDrawList__CalcCircleAutoSegmentCount;
    pub const ImDrawList__PathArcToFastEx = __root.ImDrawList__PathArcToFastEx;
    pub const ImDrawList__PathArcToN = __root.ImDrawList__PathArcToN;
    pub const PushClipRect = __root.ImDrawList_PushClipRect;
    pub const PushClipRectFullScreen = __root.ImDrawList_PushClipRectFullScreen;
    pub const PopClipRect = __root.ImDrawList_PopClipRect;
    pub const PushTexture = __root.ImDrawList_PushTexture;
    pub const PopTexture = __root.ImDrawList_PopTexture;
    pub const GetClipRectMin = __root.ImDrawList_GetClipRectMin;
    pub const GetClipRectMax = __root.ImDrawList_GetClipRectMax;
    pub const AddLine = __root.ImDrawList_AddLine;
    pub const AddLineEx = __root.ImDrawList_AddLineEx;
    pub const AddLineH = __root.ImDrawList_AddLineH;
    pub const AddLineHEx = __root.ImDrawList_AddLineHEx;
    pub const AddLineV = __root.ImDrawList_AddLineV;
    pub const AddLineVEx = __root.ImDrawList_AddLineVEx;
    pub const AddRect = __root.ImDrawList_AddRect;
    pub const AddRectEx = __root.ImDrawList_AddRectEx;
    pub const AddRectFilled = __root.ImDrawList_AddRectFilled;
    pub const AddRectFilledEx = __root.ImDrawList_AddRectFilledEx;
    pub const AddRectFilledMultiColor = __root.ImDrawList_AddRectFilledMultiColor;
    pub const AddQuad = __root.ImDrawList_AddQuad;
    pub const AddQuadEx = __root.ImDrawList_AddQuadEx;
    pub const AddQuadFilled = __root.ImDrawList_AddQuadFilled;
    pub const AddTriangle = __root.ImDrawList_AddTriangle;
    pub const AddTriangleEx = __root.ImDrawList_AddTriangleEx;
    pub const AddTriangleFilled = __root.ImDrawList_AddTriangleFilled;
    pub const AddCircle = __root.ImDrawList_AddCircle;
    pub const AddCircleEx = __root.ImDrawList_AddCircleEx;
    pub const AddCircleFilled = __root.ImDrawList_AddCircleFilled;
    pub const AddNgon = __root.ImDrawList_AddNgon;
    pub const AddNgonEx = __root.ImDrawList_AddNgonEx;
    pub const AddNgonFilled = __root.ImDrawList_AddNgonFilled;
    pub const AddEllipse = __root.ImDrawList_AddEllipse;
    pub const AddEllipseEx = __root.ImDrawList_AddEllipseEx;
    pub const AddEllipseFilled = __root.ImDrawList_AddEllipseFilled;
    pub const AddEllipseFilledEx = __root.ImDrawList_AddEllipseFilledEx;
    pub const AddText = __root.ImDrawList_AddText;
    pub const AddTextEx = __root.ImDrawList_AddTextEx;
    pub const AddTextImFontPtr = __root.ImDrawList_AddTextImFontPtr;
    pub const AddTextImFontPtrEx = __root.ImDrawList_AddTextImFontPtrEx;
    pub const AddBezierCubic = __root.ImDrawList_AddBezierCubic;
    pub const AddBezierQuadratic = __root.ImDrawList_AddBezierQuadratic;
    pub const AddPolyline = __root.ImDrawList_AddPolyline;
    pub const AddConvexPolyFilled = __root.ImDrawList_AddConvexPolyFilled;
    pub const AddConcavePolyFilled = __root.ImDrawList_AddConcavePolyFilled;
    pub const AddImage = __root.ImDrawList_AddImage;
    pub const AddImageEx = __root.ImDrawList_AddImageEx;
    pub const AddImageQuad = __root.ImDrawList_AddImageQuad;
    pub const AddImageQuadEx = __root.ImDrawList_AddImageQuadEx;
    pub const AddImageRounded = __root.ImDrawList_AddImageRounded;
    pub const PathClear = __root.ImDrawList_PathClear;
    pub const PathLineTo = __root.ImDrawList_PathLineTo;
    pub const PathLineToMergeDuplicate = __root.ImDrawList_PathLineToMergeDuplicate;
    pub const PathFillConvex = __root.ImDrawList_PathFillConvex;
    pub const PathFillConcave = __root.ImDrawList_PathFillConcave;
    pub const PathStroke = __root.ImDrawList_PathStroke;
    pub const PathArcTo = __root.ImDrawList_PathArcTo;
    pub const PathArcToFast = __root.ImDrawList_PathArcToFast;
    pub const PathEllipticalArcTo = __root.ImDrawList_PathEllipticalArcTo;
    pub const PathEllipticalArcToEx = __root.ImDrawList_PathEllipticalArcToEx;
    pub const PathBezierCubicCurveTo = __root.ImDrawList_PathBezierCubicCurveTo;
    pub const PathBezierQuadraticCurveTo = __root.ImDrawList_PathBezierQuadraticCurveTo;
    pub const PathRect = __root.ImDrawList_PathRect;
    pub const AddCallback = __root.ImDrawList_AddCallback;
    pub const AddCallbackEx = __root.ImDrawList_AddCallbackEx;
    pub const AddDrawCmd = __root.ImDrawList_AddDrawCmd;
    pub const CloneOutput = __root.ImDrawList_CloneOutput;
    pub const ChannelsSplit = __root.ImDrawList_ChannelsSplit;
    pub const ChannelsMerge = __root.ImDrawList_ChannelsMerge;
    pub const ChannelsSetCurrent = __root.ImDrawList_ChannelsSetCurrent;
    pub const PrimReserve = __root.ImDrawList_PrimReserve;
    pub const PrimUnreserve = __root.ImDrawList_PrimUnreserve;
    pub const PrimRect = __root.ImDrawList_PrimRect;
    pub const PrimRectUV = __root.ImDrawList_PrimRectUV;
    pub const PrimQuadUV = __root.ImDrawList_PrimQuadUV;
    pub const PrimWriteVtx = __root.ImDrawList_PrimWriteVtx;
    pub const PrimWriteIdx = __root.ImDrawList_PrimWriteIdx;
    pub const PrimVtx = __root.ImDrawList_PrimVtx;
    pub const AddRectImDrawFlags = __root.ImDrawList_AddRectImDrawFlags;
    pub const AddPolylineImDrawFlags = __root.ImDrawList_AddPolylineImDrawFlags;
    pub const PathStrokeImDrawFlags = __root.ImDrawList_PathStrokeImDrawFlags;
    pub const PushTextureID = __root.ImDrawList_PushTextureID;
    pub const PopTextureID = __root.ImDrawList_PopTextureID;
    pub const SetDrawListSharedData = __root.ImDrawList__SetDrawListSharedData;
    pub const ResetForNewFrame = __root.ImDrawList__ResetForNewFrame;
    pub const ClearFreeMemory = __root.ImDrawList__ClearFreeMemory;
    pub const PopUnusedDrawCmd = __root.ImDrawList__PopUnusedDrawCmd;
    pub const TryMergeDrawCmds = __root.ImDrawList__TryMergeDrawCmds;
    pub const OnChangedClipRect = __root.ImDrawList__OnChangedClipRect;
    pub const OnChangedTexture = __root.ImDrawList__OnChangedTexture;
    pub const OnChangedVtxOffset = __root.ImDrawList__OnChangedVtxOffset;
    pub const SetTexture = __root.ImDrawList__SetTexture;
    pub const CalcCircleAutoSegmentCount = __root.ImDrawList__CalcCircleAutoSegmentCount;
    pub const PathArcToFastEx = __root.ImDrawList__PathArcToFastEx;
    pub const PathArcToN = __root.ImDrawList__PathArcToN;
};
pub const ImDrawList = struct_ImDrawList_t;
pub const ImDrawCallback = ?*const fn (parent_list: [*c]const ImDrawList, cmd: [*c]const ImDrawCmd) callconv(.c) void;
pub const struct_ImDrawCmd_t = extern struct {
    ClipRect: ImVec4,
    TexRef: ImTextureRef,
    VtxOffset: c_uint,
    IdxOffset: c_uint,
    ElemCount: c_uint,
    UserCallback: ImDrawCallback,
    UserCallbackData: ?*anyopaque,
    UserCallbackDataSize: c_int,
    UserCallbackDataOffset: c_int,
    pub const ImDrawCmd_GetTexID = __root.ImDrawCmd_GetTexID;
    pub const GetTexID = __root.ImDrawCmd_GetTexID;
};
pub const ImDrawCmd = struct_ImDrawCmd_t;
pub const struct_ImVector_ImDrawCmd_t = extern struct {
    Size: c_int,
    Capacity: c_int,
    Data: [*c]ImDrawCmd,
};
pub const ImVector_ImDrawCmd = struct_ImVector_ImDrawCmd_t;
pub const struct_ImDrawChannel_t = extern struct {
    _CmdBuffer: ImVector_ImDrawCmd,
    _IdxBuffer: ImVector_ImDrawIdx,
};
pub const ImDrawChannel = struct_ImDrawChannel_t;
pub const struct_ImVector_ImDrawChannel_t = extern struct {
    Size: c_int,
    Capacity: c_int,
    Data: [*c]ImDrawChannel,
};
pub const struct_ImVector_ImDrawListPtr_t = extern struct {
    Size: c_int,
    Capacity: c_int,
    Data: [*c][*c]ImDrawList,
};
pub const ImVector_ImDrawListPtr = struct_ImVector_ImDrawListPtr_t;
pub const struct_ImVector_ImU32_t = extern struct {
    Size: c_int,
    Capacity: c_int,
    Data: [*c]ImU32,
};
pub const ImVector_ImU32 = struct_ImVector_ImU32_t;
pub const ImWchar16 = c_ushort;
pub const ImWchar = ImWchar16;
pub const struct_ImVector_ImWchar_t = extern struct {
    Size: c_int,
    Capacity: c_int,
    Data: [*c]ImWchar,
};
pub const ImVector_ImWchar = struct_ImVector_ImWchar_t;
pub const struct_ImVector_float_t = extern struct {
    Size: c_int,
    Capacity: c_int,
    Data: [*c]f32,
};
pub const ImVector_float = struct_ImVector_float_t;
pub const ImU16 = c_ushort;
pub const struct_ImVector_ImU16_t = extern struct {
    Size: c_int,
    Capacity: c_int,
    Data: [*c]ImU16,
};
pub const ImVector_ImU16 = struct_ImVector_ImU16_t; // ./src-docking/cimgui.h:3787:18: warning: struct demoted to opaque type - has bitfield
pub const struct_ImFontGlyph_t = opaque {};
pub const ImFontGlyph = struct_ImFontGlyph_t;
pub const struct_ImVector_ImFontGlyph_t = extern struct {
    Size: c_int,
    Capacity: c_int,
    Data: ?*ImFontGlyph,
};
pub const ImVector_ImFontGlyph = struct_ImVector_ImFontGlyph_t; // ./src-docking/cimgui.h:4022:26: warning: struct demoted to opaque type - has bitfield
pub const struct_ImFontBaked_t = opaque {
    pub const ImFontBaked_ClearOutputData = __root.ImFontBaked_ClearOutputData;
    pub const ImFontBaked_FindGlyph = __root.ImFontBaked_FindGlyph;
    pub const ImFontBaked_FindGlyphNoFallback = __root.ImFontBaked_FindGlyphNoFallback;
    pub const ImFontBaked_GetCharAdvance = __root.ImFontBaked_GetCharAdvance;
    pub const ImFontBaked_IsGlyphLoaded = __root.ImFontBaked_IsGlyphLoaded;
    pub const ClearOutputData = __root.ImFontBaked_ClearOutputData;
    pub const FindGlyph = __root.ImFontBaked_FindGlyph;
    pub const FindGlyphNoFallback = __root.ImFontBaked_FindGlyphNoFallback;
    pub const GetCharAdvance = __root.ImFontBaked_GetCharAdvance;
    pub const IsGlyphLoaded = __root.ImFontBaked_IsGlyphLoaded;
};
pub const ImFontBaked = struct_ImFontBaked_t;
pub const ImFontAtlasFlags = c_int;
const union_unnamed_2 = extern union {
    TexRef: ImTextureRef,
    TexID: ImTextureRef,
};
pub const struct_ImVector_ImTextureDataPtr_t = extern struct {
    Size: c_int,
    Capacity: c_int,
    Data: [*c][*c]ImTextureData,
};
pub const ImVector_ImTextureDataPtr = struct_ImVector_ImTextureDataPtr_t;
pub const ImVector_ImFontPtr = struct_ImVector_ImFontPtr_t;
pub const ImFontFlags = c_int;
pub const struct_ImFontLoader_t = opaque {};
pub const ImFontLoader = struct_ImFontLoader_t;
pub const struct_ImFontConfig_t = extern struct {
    Name: [40]u8,
    FontData: ?*anyopaque,
    FontDataSize: c_int,
    FontDataOwnedByAtlas: bool,
    MergeMode: bool,
    PixelSnapH: bool,
    OversampleH: ImS8,
    OversampleV: ImS8,
    EllipsisChar: ImWchar,
    SizePixels: f32,
    GlyphRanges: [*c]const ImWchar,
    GlyphExcludeRanges: [*c]const ImWchar,
    GlyphOffset: ImVec2,
    GlyphMinAdvanceX: f32,
    GlyphMaxAdvanceX: f32,
    GlyphExtraAdvanceX: f32,
    FontNo: ImU32,
    FontLoaderFlags: c_uint,
    RasterizerMultiply: f32,
    RasterizerDensity: f32,
    ExtraSizeScale: f32,
    Flags: ImFontFlags,
    DstFont: [*c]ImFont,
    FontLoader: ?*const ImFontLoader,
    FontLoaderData: ?*anyopaque,
    PixelSnapV: bool,
};
pub const ImFontConfig = struct_ImFontConfig_t;
pub const struct_ImVector_ImFontConfig_t = extern struct {
    Size: c_int,
    Capacity: c_int,
    Data: [*c]ImFontConfig,
};
pub const ImVector_ImFontConfig = struct_ImVector_ImFontConfig_t;
pub const struct_ImVector_ImDrawListSharedDataPtr_t = extern struct {
    Size: c_int,
    Capacity: c_int,
    Data: [*c]?*ImDrawListSharedData,
};
pub const ImVector_ImDrawListSharedDataPtr = struct_ImVector_ImDrawListSharedDataPtr_t;
pub const struct_ImFontAtlasBuilder_t = opaque {};
pub const ImFontAtlasBuilder = struct_ImFontAtlasBuilder_t;
pub const struct_ImGuiContext_t = opaque {
    pub const igDestroyContext = __root.igDestroyContext;
    pub const igSetCurrentContext = __root.igSetCurrentContext;
};
pub const ImGuiContext = struct_ImGuiContext_t;
pub const struct_ImFontAtlasRect_t = extern struct {
    x: c_ushort,
    y: c_ushort,
    w: c_ushort,
    h: c_ushort,
    uv0: ImVec2,
    uv1: ImVec2,
};
pub const ImFontAtlasRect = struct_ImFontAtlasRect_t;
pub const struct_ImFontAtlas_t = extern struct {
    Flags: ImFontAtlasFlags,
    TexDesiredFormat: ImTextureFormat,
    TexGlyphPadding: c_int,
    TexMinWidth: c_int,
    TexMinHeight: c_int,
    TexMaxWidth: c_int,
    TexMaxHeight: c_int,
    UserData: ?*anyopaque,
    unnamed_0: union_unnamed_2,
    TexData: [*c]ImTextureData,
    TexList: ImVector_ImTextureDataPtr,
    Locked: bool,
    RendererHasTextures: bool,
    TexIsBuilt: bool,
    TexPixelsUseColors: bool,
    TexUvScale: ImVec2,
    TexUvWhitePixel: ImVec2,
    Fonts: ImVector_ImFontPtr,
    Sources: ImVector_ImFontConfig,
    TexUvLines: [33]ImVec4,
    TexNextUniqueID: c_int,
    FontNextUniqueID: c_int,
    DrawListSharedDatas: ImVector_ImDrawListSharedDataPtr,
    Builder: ?*ImFontAtlasBuilder,
    FontLoader: ?*const ImFontLoader,
    FontLoaderName: [*c]const u8,
    FontLoaderData: ?*anyopaque,
    FontLoaderFlags: c_uint,
    RefCount: c_int,
    OwnerContext: ?*ImGuiContext,
    TempRect: ImFontAtlasRect,
    pub const igCreateContext = __root.igCreateContext;
    pub const ImFontAtlas_AddFont = __root.ImFontAtlas_AddFont;
    pub const ImFontAtlas_AddFontDefault = __root.ImFontAtlas_AddFontDefault;
    pub const ImFontAtlas_AddFontDefaultVector = __root.ImFontAtlas_AddFontDefaultVector;
    pub const ImFontAtlas_AddFontDefaultBitmap = __root.ImFontAtlas_AddFontDefaultBitmap;
    pub const ImFontAtlas_AddFontFromFileTTF = __root.ImFontAtlas_AddFontFromFileTTF;
    pub const ImFontAtlas_AddFontFromMemoryTTF = __root.ImFontAtlas_AddFontFromMemoryTTF;
    pub const ImFontAtlas_AddFontFromMemoryCompressedTTF = __root.ImFontAtlas_AddFontFromMemoryCompressedTTF;
    pub const ImFontAtlas_AddFontFromMemoryCompressedBase85TTF = __root.ImFontAtlas_AddFontFromMemoryCompressedBase85TTF;
    pub const ImFontAtlas_RemoveFont = __root.ImFontAtlas_RemoveFont;
    pub const ImFontAtlas_CompactCache = __root.ImFontAtlas_CompactCache;
    pub const ImFontAtlas_SetFontLoader = __root.ImFontAtlas_SetFontLoader;
    pub const ImFontAtlas_Clear = __root.ImFontAtlas_Clear;
    pub const ImFontAtlas_ClearFonts = __root.ImFontAtlas_ClearFonts;
    pub const ImFontAtlas_ClearInputData = __root.ImFontAtlas_ClearInputData;
    pub const ImFontAtlas_ClearTexData = __root.ImFontAtlas_ClearTexData;
    pub const ImFontAtlas_Build = __root.ImFontAtlas_Build;
    pub const ImFontAtlas_GetTexDataAsAlpha8 = __root.ImFontAtlas_GetTexDataAsAlpha8;
    pub const ImFontAtlas_GetTexDataAsRGBA32 = __root.ImFontAtlas_GetTexDataAsRGBA32;
    pub const ImFontAtlas_SetTexID = __root.ImFontAtlas_SetTexID;
    pub const ImFontAtlas_SetTexIDImTextureRef = __root.ImFontAtlas_SetTexIDImTextureRef;
    pub const ImFontAtlas_IsBuilt = __root.ImFontAtlas_IsBuilt;
    pub const ImFontAtlas_GetGlyphRangesDefault = __root.ImFontAtlas_GetGlyphRangesDefault;
    pub const ImFontAtlas_GetGlyphRangesGreek = __root.ImFontAtlas_GetGlyphRangesGreek;
    pub const ImFontAtlas_GetGlyphRangesKorean = __root.ImFontAtlas_GetGlyphRangesKorean;
    pub const ImFontAtlas_GetGlyphRangesJapanese = __root.ImFontAtlas_GetGlyphRangesJapanese;
    pub const ImFontAtlas_GetGlyphRangesChineseFull = __root.ImFontAtlas_GetGlyphRangesChineseFull;
    pub const ImFontAtlas_GetGlyphRangesChineseSimplifiedCommon = __root.ImFontAtlas_GetGlyphRangesChineseSimplifiedCommon;
    pub const ImFontAtlas_GetGlyphRangesCyrillic = __root.ImFontAtlas_GetGlyphRangesCyrillic;
    pub const ImFontAtlas_GetGlyphRangesThai = __root.ImFontAtlas_GetGlyphRangesThai;
    pub const ImFontAtlas_GetGlyphRangesVietnamese = __root.ImFontAtlas_GetGlyphRangesVietnamese;
    pub const ImFontAtlas_AddCustomRect = __root.ImFontAtlas_AddCustomRect;
    pub const ImFontAtlas_RemoveCustomRect = __root.ImFontAtlas_RemoveCustomRect;
    pub const ImFontAtlas_GetCustomRect = __root.ImFontAtlas_GetCustomRect;
    pub const ImFontAtlas_AddCustomRectRegular = __root.ImFontAtlas_AddCustomRectRegular;
    pub const ImFontAtlas_GetCustomRectByIndex = __root.ImFontAtlas_GetCustomRectByIndex;
    pub const ImFontAtlas_CalcCustomRectUV = __root.ImFontAtlas_CalcCustomRectUV;
    pub const ImFontAtlas_AddCustomRectFontGlyph = __root.ImFontAtlas_AddCustomRectFontGlyph;
    pub const ImFontAtlas_AddCustomRectFontGlyphForSize = __root.ImFontAtlas_AddCustomRectFontGlyphForSize;
    pub const AddFont = __root.ImFontAtlas_AddFont;
    pub const AddFontDefault = __root.ImFontAtlas_AddFontDefault;
    pub const AddFontDefaultVector = __root.ImFontAtlas_AddFontDefaultVector;
    pub const AddFontDefaultBitmap = __root.ImFontAtlas_AddFontDefaultBitmap;
    pub const AddFontFromFileTTF = __root.ImFontAtlas_AddFontFromFileTTF;
    pub const AddFontFromMemoryTTF = __root.ImFontAtlas_AddFontFromMemoryTTF;
    pub const AddFontFromMemoryCompressedTTF = __root.ImFontAtlas_AddFontFromMemoryCompressedTTF;
    pub const AddFontFromMemoryCompressedBase85TTF = __root.ImFontAtlas_AddFontFromMemoryCompressedBase85TTF;
    pub const RemoveFont = __root.ImFontAtlas_RemoveFont;
    pub const CompactCache = __root.ImFontAtlas_CompactCache;
    pub const SetFontLoader = __root.ImFontAtlas_SetFontLoader;
    pub const Clear = __root.ImFontAtlas_Clear;
    pub const ClearFonts = __root.ImFontAtlas_ClearFonts;
    pub const ClearInputData = __root.ImFontAtlas_ClearInputData;
    pub const ClearTexData = __root.ImFontAtlas_ClearTexData;
    pub const Build = __root.ImFontAtlas_Build;
    pub const GetTexDataAsAlpha8 = __root.ImFontAtlas_GetTexDataAsAlpha8;
    pub const GetTexDataAsRGBA32 = __root.ImFontAtlas_GetTexDataAsRGBA32;
    pub const SetTexID = __root.ImFontAtlas_SetTexID;
    pub const SetTexIDImTextureRef = __root.ImFontAtlas_SetTexIDImTextureRef;
    pub const IsBuilt = __root.ImFontAtlas_IsBuilt;
    pub const GetGlyphRangesDefault = __root.ImFontAtlas_GetGlyphRangesDefault;
    pub const GetGlyphRangesGreek = __root.ImFontAtlas_GetGlyphRangesGreek;
    pub const GetGlyphRangesKorean = __root.ImFontAtlas_GetGlyphRangesKorean;
    pub const GetGlyphRangesJapanese = __root.ImFontAtlas_GetGlyphRangesJapanese;
    pub const GetGlyphRangesChineseFull = __root.ImFontAtlas_GetGlyphRangesChineseFull;
    pub const GetGlyphRangesChineseSimplifiedCommon = __root.ImFontAtlas_GetGlyphRangesChineseSimplifiedCommon;
    pub const GetGlyphRangesCyrillic = __root.ImFontAtlas_GetGlyphRangesCyrillic;
    pub const GetGlyphRangesThai = __root.ImFontAtlas_GetGlyphRangesThai;
    pub const GetGlyphRangesVietnamese = __root.ImFontAtlas_GetGlyphRangesVietnamese;
    pub const AddCustomRect = __root.ImFontAtlas_AddCustomRect;
    pub const RemoveCustomRect = __root.ImFontAtlas_RemoveCustomRect;
    pub const GetCustomRect = __root.ImFontAtlas_GetCustomRect;
    pub const AddCustomRectRegular = __root.ImFontAtlas_AddCustomRectRegular;
    pub const GetCustomRectByIndex = __root.ImFontAtlas_GetCustomRectByIndex;
    pub const CalcCustomRectUV = __root.ImFontAtlas_CalcCustomRectUV;
    pub const AddCustomRectFontGlyph = __root.ImFontAtlas_AddCustomRectFontGlyph;
    pub const AddCustomRectFontGlyphForSize = __root.ImFontAtlas_AddCustomRectFontGlyphForSize;
};
pub const ImFontAtlas = struct_ImFontAtlas_t;
pub const struct_ImVector_ImFontConfigPtr_t = extern struct {
    Size: c_int,
    Capacity: c_int,
    Data: [*c][*c]ImFontConfig,
};
pub const ImVector_ImFontConfigPtr = struct_ImVector_ImFontConfigPtr_t;
pub const struct_ImGuiStorage_t = extern struct {
    Data: ImVector_ImGuiStoragePair,
    pub const igSetStateStorage = __root.igSetStateStorage;
    pub const ImGuiStorage_Clear = __root.ImGuiStorage_Clear;
    pub const ImGuiStorage_GetInt = __root.ImGuiStorage_GetInt;
    pub const ImGuiStorage_SetInt = __root.ImGuiStorage_SetInt;
    pub const ImGuiStorage_GetBool = __root.ImGuiStorage_GetBool;
    pub const ImGuiStorage_SetBool = __root.ImGuiStorage_SetBool;
    pub const ImGuiStorage_GetFloat = __root.ImGuiStorage_GetFloat;
    pub const ImGuiStorage_SetFloat = __root.ImGuiStorage_SetFloat;
    pub const ImGuiStorage_GetVoidPtr = __root.ImGuiStorage_GetVoidPtr;
    pub const ImGuiStorage_SetVoidPtr = __root.ImGuiStorage_SetVoidPtr;
    pub const ImGuiStorage_GetIntRef = __root.ImGuiStorage_GetIntRef;
    pub const ImGuiStorage_GetBoolRef = __root.ImGuiStorage_GetBoolRef;
    pub const ImGuiStorage_GetFloatRef = __root.ImGuiStorage_GetFloatRef;
    pub const ImGuiStorage_GetVoidPtrRef = __root.ImGuiStorage_GetVoidPtrRef;
    pub const ImGuiStorage_BuildSortByKey = __root.ImGuiStorage_BuildSortByKey;
    pub const ImGuiStorage_SetAllInt = __root.ImGuiStorage_SetAllInt;
    pub const Clear = __root.ImGuiStorage_Clear;
    pub const GetInt = __root.ImGuiStorage_GetInt;
    pub const SetInt = __root.ImGuiStorage_SetInt;
    pub const GetBool = __root.ImGuiStorage_GetBool;
    pub const SetBool = __root.ImGuiStorage_SetBool;
    pub const GetFloat = __root.ImGuiStorage_GetFloat;
    pub const SetFloat = __root.ImGuiStorage_SetFloat;
    pub const GetVoidPtr = __root.ImGuiStorage_GetVoidPtr;
    pub const SetVoidPtr = __root.ImGuiStorage_SetVoidPtr;
    pub const GetIntRef = __root.ImGuiStorage_GetIntRef;
    pub const GetBoolRef = __root.ImGuiStorage_GetBoolRef;
    pub const GetFloatRef = __root.ImGuiStorage_GetFloatRef;
    pub const GetVoidPtrRef = __root.ImGuiStorage_GetVoidPtrRef;
    pub const BuildSortByKey = __root.ImGuiStorage_BuildSortByKey;
    pub const SetAllInt = __root.ImGuiStorage_SetAllInt;
};
pub const ImGuiStorage = struct_ImGuiStorage_t;
pub const struct_ImFont_t = extern struct {
    LastBaked: ?*ImFontBaked,
    OwnerAtlas: [*c]ImFontAtlas,
    Flags: ImFontFlags,
    CurrentRasterizerDensity: f32,
    FontId: ImGuiID,
    LegacySize: f32,
    Sources: ImVector_ImFontConfigPtr,
    EllipsisChar: ImWchar,
    FallbackChar: ImWchar,
    Used8kPagesMap: [1]ImU8,
    EllipsisAutoBake: bool,
    RemapPairs: ImGuiStorage,
    Scale: f32,
    pub const igPushFontFloat = __root.igPushFontFloat;
    pub const ImFont_IsGlyphInFont = __root.ImFont_IsGlyphInFont;
    pub const ImFont_IsLoaded = __root.ImFont_IsLoaded;
    pub const ImFont_GetDebugName = __root.ImFont_GetDebugName;
    pub const ImFont_GetFontBaked = __root.ImFont_GetFontBaked;
    pub const ImFont_GetFontBakedEx = __root.ImFont_GetFontBakedEx;
    pub const ImFont_CalcTextSizeA = __root.ImFont_CalcTextSizeA;
    pub const ImFont_CalcTextSizeAEx = __root.ImFont_CalcTextSizeAEx;
    pub const ImFont_CalcWordWrapPosition = __root.ImFont_CalcWordWrapPosition;
    pub const ImFont_RenderChar = __root.ImFont_RenderChar;
    pub const ImFont_RenderCharEx = __root.ImFont_RenderCharEx;
    pub const ImFont_RenderText = __root.ImFont_RenderText;
    pub const ImFont_CalcWordWrapPositionA = __root.ImFont_CalcWordWrapPositionA;
    pub const ImFont_ClearOutputData = __root.ImFont_ClearOutputData;
    pub const ImFont_AddRemapChar = __root.ImFont_AddRemapChar;
    pub const ImFont_IsGlyphRangeUnused = __root.ImFont_IsGlyphRangeUnused;
    pub const igPushFont = __root.igPushFont;
    pub const IsGlyphInFont = __root.ImFont_IsGlyphInFont;
    pub const IsLoaded = __root.ImFont_IsLoaded;
    pub const GetDebugName = __root.ImFont_GetDebugName;
    pub const GetFontBaked = __root.ImFont_GetFontBaked;
    pub const GetFontBakedEx = __root.ImFont_GetFontBakedEx;
    pub const CalcTextSizeA = __root.ImFont_CalcTextSizeA;
    pub const CalcTextSizeAEx = __root.ImFont_CalcTextSizeAEx;
    pub const CalcWordWrapPosition = __root.ImFont_CalcWordWrapPosition;
    pub const RenderChar = __root.ImFont_RenderChar;
    pub const RenderCharEx = __root.ImFont_RenderCharEx;
    pub const RenderText = __root.ImFont_RenderText;
    pub const CalcWordWrapPositionA = __root.ImFont_CalcWordWrapPositionA;
    pub const ClearOutputData = __root.ImFont_ClearOutputData;
    pub const AddRemapChar = __root.ImFont_AddRemapChar;
    pub const IsGlyphRangeUnused = __root.ImFont_IsGlyphRangeUnused;
};
pub const ImFont = struct_ImFont_t;
pub const struct_ImVector_ImFontPtr_t = extern struct {
    Size: c_int,
    Capacity: c_int,
    Data: [*c][*c]ImFont,
};
pub const struct_ImGuiPlatformMonitor_t = extern struct {
    MainPos: ImVec2,
    MainSize: ImVec2,
    WorkPos: ImVec2,
    WorkSize: ImVec2,
    DpiScale: f32,
    PlatformHandle: ?*anyopaque,
};
pub const ImGuiPlatformMonitor = struct_ImGuiPlatformMonitor_t;
pub const struct_ImVector_ImGuiPlatformMonitor_t = extern struct {
    Size: c_int,
    Capacity: c_int,
    Data: [*c]ImGuiPlatformMonitor,
};
pub const ImVector_ImGuiPlatformMonitor = struct_ImVector_ImGuiPlatformMonitor_t;
pub const ImGuiViewportFlags = c_int;
pub const struct_ImDrawData_t = extern struct {
    Valid: bool,
    FrameCount: c_int,
    TotalIdxCount: c_int,
    TotalVtxCount: c_int,
    CmdLists: ImVector_ImDrawListPtr,
    DisplayPos: ImVec2,
    DisplaySize: ImVec2,
    FramebufferScale: ImVec2,
    OwnerViewport: [*c]ImGuiViewport,
    Textures: [*c]ImVector_ImTextureDataPtr,
    CmdListsCount: c_int,
    pub const ImDrawData_Clear = __root.ImDrawData_Clear;
    pub const ImDrawData_AddDrawList = __root.ImDrawData_AddDrawList;
    pub const ImDrawData_DeIndexAllBuffers = __root.ImDrawData_DeIndexAllBuffers;
    pub const ImDrawData_ScaleClipRects = __root.ImDrawData_ScaleClipRects;
    pub const Clear = __root.ImDrawData_Clear;
    pub const AddDrawList = __root.ImDrawData_AddDrawList;
    pub const DeIndexAllBuffers = __root.ImDrawData_DeIndexAllBuffers;
    pub const ScaleClipRects = __root.ImDrawData_ScaleClipRects;
};
pub const ImDrawData = struct_ImDrawData_t;
pub const struct_ImGuiViewport_t = extern struct {
    ID: ImGuiID,
    Flags: ImGuiViewportFlags,
    Pos: ImVec2,
    Size: ImVec2,
    FramebufferScale: ImVec2,
    WorkPos: ImVec2,
    WorkSize: ImVec2,
    DpiScale: f32,
    ParentViewportId: ImGuiID,
    ParentViewport: [*c]ImGuiViewport,
    DrawData: [*c]ImDrawData,
    RendererUserData: ?*anyopaque,
    PlatformUserData: ?*anyopaque,
    PlatformIconData: ?*anyopaque,
    PlatformHandle: ?*anyopaque,
    PlatformHandleRaw: ?*anyopaque,
    PlatformWindowCreated: bool,
    PlatformRequestMove: bool,
    PlatformRequestResize: bool,
    PlatformRequestClose: bool,
    pub const igGetBackgroundDrawListEx = __root.igGetBackgroundDrawListEx;
    pub const igGetForegroundDrawListEx = __root.igGetForegroundDrawListEx;
    pub const ImGuiViewport_GetCenter = __root.ImGuiViewport_GetCenter;
    pub const ImGuiViewport_GetWorkCenter = __root.ImGuiViewport_GetWorkCenter;
    pub const ImGuiViewport_GetDebugName = __root.ImGuiViewport_GetDebugName;
    pub const GetCenter = __root.ImGuiViewport_GetCenter;
    pub const GetWorkCenter = __root.ImGuiViewport_GetWorkCenter;
    pub const GetDebugName = __root.ImGuiViewport_GetDebugName;
};
pub const ImGuiViewport = struct_ImGuiViewport_t;
pub const struct_ImVector_ImGuiViewportPtr_t = extern struct {
    Size: c_int,
    Capacity: c_int,
    Data: [*c][*c]ImGuiViewport,
};
pub const ImVector_ImGuiViewportPtr = struct_ImVector_ImGuiViewportPtr_t;
pub const ImS16 = c_short;
pub const ImS32 = c_int;
pub const struct_ImFontGlyphRangesBuilder_t = extern struct {
    UsedChars: ImVector_ImU32,
    pub const ImFontGlyphRangesBuilder_Clear = __root.ImFontGlyphRangesBuilder_Clear;
    pub const ImFontGlyphRangesBuilder_GetBit = __root.ImFontGlyphRangesBuilder_GetBit;
    pub const ImFontGlyphRangesBuilder_SetBit = __root.ImFontGlyphRangesBuilder_SetBit;
    pub const ImFontGlyphRangesBuilder_AddChar = __root.ImFontGlyphRangesBuilder_AddChar;
    pub const ImFontGlyphRangesBuilder_AddText = __root.ImFontGlyphRangesBuilder_AddText;
    pub const ImFontGlyphRangesBuilder_AddRanges = __root.ImFontGlyphRangesBuilder_AddRanges;
    pub const ImFontGlyphRangesBuilder_BuildRanges = __root.ImFontGlyphRangesBuilder_BuildRanges;
    pub const Clear = __root.ImFontGlyphRangesBuilder_Clear;
    pub const GetBit = __root.ImFontGlyphRangesBuilder_GetBit;
    pub const SetBit = __root.ImFontGlyphRangesBuilder_SetBit;
    pub const AddChar = __root.ImFontGlyphRangesBuilder_AddChar;
    pub const AddText = __root.ImFontGlyphRangesBuilder_AddText;
    pub const AddRanges = __root.ImFontGlyphRangesBuilder_AddRanges;
    pub const BuildRanges = __root.ImFontGlyphRangesBuilder_BuildRanges;
};
pub const ImFontGlyphRangesBuilder = struct_ImFontGlyphRangesBuilder_t;
pub const struct_ImColor_t = extern struct {
    Value: ImVec4,
    pub const ImColor_SetHSV = __root.ImColor_SetHSV;
    pub const SetHSV = __root.ImColor_SetHSV;
};
pub const ImColor = struct_ImColor_t;
pub const ImGuiConfigFlags = c_int;
pub const ImGuiBackendFlags = c_int;
pub const ImGuiColorEditFlags = c_int;
pub const ImGuiMouseSource = c_int;
pub const ImGuiKeyChord = c_int;
pub const struct_ImGuiKeyData_t = extern struct {
    Down: bool,
    DownDuration: f32,
    DownDurationPrev: f32,
    AnalogValue: f32,
};
pub const ImGuiKeyData = struct_ImGuiKeyData_t;
pub const struct_ImGuiIO_t = extern struct {
    ConfigFlags: ImGuiConfigFlags,
    BackendFlags: ImGuiBackendFlags,
    DisplaySize: ImVec2,
    DisplayFramebufferScale: ImVec2,
    DeltaTime: f32,
    IniSavingRate: f32,
    IniFilename: [*c]const u8,
    LogFilename: [*c]const u8,
    UserData: ?*anyopaque,
    Fonts: [*c]ImFontAtlas,
    FontDefault: [*c]ImFont,
    FontAllowUserScaling: bool,
    ConfigNavSwapGamepadButtons: bool,
    ConfigNavMoveSetMousePos: bool,
    ConfigNavCaptureKeyboard: bool,
    ConfigNavEscapeClearFocusItem: bool,
    ConfigNavEscapeClearFocusWindow: bool,
    ConfigNavCursorVisibleAuto: bool,
    ConfigNavCursorVisibleAlways: bool,
    ConfigDockingNoSplit: bool,
    ConfigDockingNoDockingOver: bool,
    ConfigDockingWithShift: bool,
    ConfigDockingAlwaysTabBar: bool,
    ConfigDockingTransparentPayload: bool,
    ConfigViewportsNoAutoMerge: bool,
    ConfigViewportsNoTaskBarIcon: bool,
    ConfigViewportsNoDecoration: bool,
    ConfigViewportsNoDefaultParent: bool,
    ConfigViewportsPlatformFocusSetsImGuiFocus: bool,
    ConfigDpiScaleFonts: bool,
    ConfigDpiScaleViewports: bool,
    ConfigMacOSXBehaviors: bool,
    ConfigInputTrickleEventQueue: bool,
    ConfigInputTextCursorBlink: bool,
    ConfigInputTextEnterKeepActive: bool,
    ConfigColorEditFlags: ImGuiColorEditFlags,
    ConfigDragClickToInputText: bool,
    ConfigWindowsResizeFromEdges: bool,
    ConfigWindowsMoveFromTitleBarOnly: bool,
    ConfigWindowsCopyContentsWithCtrlC: bool,
    ConfigScrollbarScrollByPage: bool,
    ConfigIniSettingsSaveLastUsedDate: bool,
    ConfigIniSettingsAutoDiscardMonths: c_int,
    ConfigDebugIniSettings: bool,
    MouseDrawCursor: bool,
    ConfigMemoryCompactTimer: f32,
    MouseDoubleClickTime: f32,
    MouseDoubleClickMaxDist: f32,
    MouseSingleClickDelay: f32,
    MouseDragThreshold: f32,
    KeyRepeatDelay: f32,
    KeyRepeatRate: f32,
    ConfigErrorRecovery: bool,
    ConfigErrorRecoveryEnableAssert: bool,
    ConfigErrorRecoveryEnableDebugLog: bool,
    ConfigErrorRecoveryEnableTooltip: bool,
    ConfigDebugIsDebuggerPresent: bool,
    ConfigDebugHighlightIdConflicts: bool,
    ConfigDebugHighlightIdConflictsShowItemPicker: bool,
    ConfigDebugBeginReturnValueOnce: bool,
    ConfigDebugBeginReturnValueLoop: bool,
    ConfigDebugIgnoreFocusLoss: bool,
    BackendPlatformName: [*c]const u8,
    BackendRendererName: [*c]const u8,
    BackendPlatformUserData: ?*anyopaque,
    BackendRendererUserData: ?*anyopaque,
    BackendLanguageUserData: ?*anyopaque,
    WantCaptureMouse: bool,
    WantCaptureKeyboard: bool,
    WantTextInput: bool,
    WantSetMousePos: bool,
    WantSaveIniSettings: bool,
    NavActive: bool,
    NavVisible: bool,
    Framerate: f32,
    MetricsRenderVertices: c_int,
    MetricsRenderIndices: c_int,
    MetricsRenderWindows: c_int,
    MetricsActiveWindows: c_int,
    MouseDelta: ImVec2,
    Ctx: ?*ImGuiContext,
    MousePos: ImVec2,
    MouseDown: [5]bool,
    MouseWheel: f32,
    MouseWheelH: f32,
    MouseSource: ImGuiMouseSource,
    MouseHoveredViewport: ImGuiID,
    KeyCtrl: bool,
    KeyShift: bool,
    KeyAlt: bool,
    KeySuper: bool,
    KeyMods: ImGuiKeyChord,
    KeysData: [155]ImGuiKeyData,
    WantCaptureMouseUnlessPopupClose: bool,
    MousePosPrev: ImVec2,
    MouseClickedPos: [5]ImVec2,
    MouseClickedTime: [5]f64,
    MouseClicked: [5]bool,
    MouseDoubleClicked: [5]bool,
    MouseClickedCount: [5]ImU16,
    MouseClickedLastCount: [5]ImU16,
    MouseReleased: [5]bool,
    MouseReleasedTime: [5]f64,
    MouseDownOwned: [5]bool,
    MouseDownOwnedUnlessPopupClose: [5]bool,
    MouseWheelRequestAxisSwap: bool,
    MouseCtrlLeftAsRightClick: bool,
    MouseDownDuration: [5]f32,
    MouseDownDurationPrev: [5]f32,
    MouseDragMaxDistanceAbs: [5]ImVec2,
    MouseDragMaxDistanceSqr: [5]f32,
    PenPressure: f32,
    AppFocusLost: bool,
    AppAcceptingEvents: bool,
    InputQueueSurrogate: ImWchar16,
    InputQueueCharacters: ImVector_ImWchar,
    FontGlobalScale: f32,
    GetClipboardTextFn: ?*const fn (user_data: ?*anyopaque) callconv(.c) [*c]const u8,
    SetClipboardTextFn: ?*const fn (user_data: ?*anyopaque, text: [*c]const u8) callconv(.c) void,
    ClipboardUserData: ?*anyopaque,
    pub const ImGuiIO_AddKeyEvent = __root.ImGuiIO_AddKeyEvent;
    pub const ImGuiIO_AddKeyAnalogEvent = __root.ImGuiIO_AddKeyAnalogEvent;
    pub const ImGuiIO_AddMousePosEvent = __root.ImGuiIO_AddMousePosEvent;
    pub const ImGuiIO_AddMouseButtonEvent = __root.ImGuiIO_AddMouseButtonEvent;
    pub const ImGuiIO_AddMouseWheelEvent = __root.ImGuiIO_AddMouseWheelEvent;
    pub const ImGuiIO_AddMouseSourceEvent = __root.ImGuiIO_AddMouseSourceEvent;
    pub const ImGuiIO_AddMouseViewportEvent = __root.ImGuiIO_AddMouseViewportEvent;
    pub const ImGuiIO_AddFocusEvent = __root.ImGuiIO_AddFocusEvent;
    pub const ImGuiIO_AddInputCharacter = __root.ImGuiIO_AddInputCharacter;
    pub const ImGuiIO_AddInputCharacterUTF16 = __root.ImGuiIO_AddInputCharacterUTF16;
    pub const ImGuiIO_AddInputCharactersUTF8 = __root.ImGuiIO_AddInputCharactersUTF8;
    pub const ImGuiIO_SetKeyEventNativeData = __root.ImGuiIO_SetKeyEventNativeData;
    pub const ImGuiIO_SetKeyEventNativeDataEx = __root.ImGuiIO_SetKeyEventNativeDataEx;
    pub const ImGuiIO_SetAppAcceptingEvents = __root.ImGuiIO_SetAppAcceptingEvents;
    pub const ImGuiIO_ClearEventsQueue = __root.ImGuiIO_ClearEventsQueue;
    pub const ImGuiIO_ClearInputKeys = __root.ImGuiIO_ClearInputKeys;
    pub const ImGuiIO_ClearInputMouse = __root.ImGuiIO_ClearInputMouse;
    pub const AddKeyEvent = __root.ImGuiIO_AddKeyEvent;
    pub const AddKeyAnalogEvent = __root.ImGuiIO_AddKeyAnalogEvent;
    pub const AddMousePosEvent = __root.ImGuiIO_AddMousePosEvent;
    pub const AddMouseButtonEvent = __root.ImGuiIO_AddMouseButtonEvent;
    pub const AddMouseWheelEvent = __root.ImGuiIO_AddMouseWheelEvent;
    pub const AddMouseSourceEvent = __root.ImGuiIO_AddMouseSourceEvent;
    pub const AddMouseViewportEvent = __root.ImGuiIO_AddMouseViewportEvent;
    pub const AddFocusEvent = __root.ImGuiIO_AddFocusEvent;
    pub const AddInputCharacter = __root.ImGuiIO_AddInputCharacter;
    pub const AddInputCharacterUTF16 = __root.ImGuiIO_AddInputCharacterUTF16;
    pub const AddInputCharactersUTF8 = __root.ImGuiIO_AddInputCharactersUTF8;
    pub const SetKeyEventNativeData = __root.ImGuiIO_SetKeyEventNativeData;
    pub const SetKeyEventNativeDataEx = __root.ImGuiIO_SetKeyEventNativeDataEx;
    pub const SetAppAcceptingEvents = __root.ImGuiIO_SetAppAcceptingEvents;
    pub const ClearEventsQueue = __root.ImGuiIO_ClearEventsQueue;
    pub const ClearInputKeys = __root.ImGuiIO_ClearInputKeys;
    pub const ClearInputMouse = __root.ImGuiIO_ClearInputMouse;
};
pub const ImGuiIO = struct_ImGuiIO_t;
pub const ImGuiInputTextFlags = c_int;
pub const ImGuiKey = c_int;
pub const struct_ImGuiInputTextCallbackData_t = extern struct {
    Ctx: ?*ImGuiContext,
    EventFlag: ImGuiInputTextFlags,
    Flags: ImGuiInputTextFlags,
    UserData: ?*anyopaque,
    ID: ImGuiID,
    EventKey: ImGuiKey,
    EventChar: ImWchar,
    EventActivated: bool,
    BufDirty: bool,
    Buf: [*c]u8,
    BufTextLen: c_int,
    BufSize: c_int,
    CursorPos: c_int,
    SelectionStart: c_int,
    SelectionEnd: c_int,
    pub const ImGuiInputTextCallbackData_DeleteChars = __root.ImGuiInputTextCallbackData_DeleteChars;
    pub const ImGuiInputTextCallbackData_InsertChars = __root.ImGuiInputTextCallbackData_InsertChars;
    pub const ImGuiInputTextCallbackData_SelectAll = __root.ImGuiInputTextCallbackData_SelectAll;
    pub const ImGuiInputTextCallbackData_SetSelection = __root.ImGuiInputTextCallbackData_SetSelection;
    pub const ImGuiInputTextCallbackData_ClearSelection = __root.ImGuiInputTextCallbackData_ClearSelection;
    pub const ImGuiInputTextCallbackData_HasSelection = __root.ImGuiInputTextCallbackData_HasSelection;
    pub const DeleteChars = __root.ImGuiInputTextCallbackData_DeleteChars;
    pub const InsertChars = __root.ImGuiInputTextCallbackData_InsertChars;
    pub const SelectAll = __root.ImGuiInputTextCallbackData_SelectAll;
    pub const SetSelection = __root.ImGuiInputTextCallbackData_SetSelection;
    pub const ClearSelection = __root.ImGuiInputTextCallbackData_ClearSelection;
    pub const HasSelection = __root.ImGuiInputTextCallbackData_HasSelection;
};
pub const ImGuiInputTextCallbackData = struct_ImGuiInputTextCallbackData_t;
pub const ImGuiListClipperFlags = c_int;
pub const struct_ImGuiListClipper_t = extern struct {
    DisplayStart: c_int,
    DisplayEnd: c_int,
    UserIndex: c_int,
    ItemsCount: c_int,
    ItemsHeight: f32,
    Flags: ImGuiListClipperFlags,
    StartPosY: f64,
    StartSeekOffsetY: f64,
    Ctx: ?*ImGuiContext,
    TempData: ?*anyopaque,
    pub const ImGuiListClipper_Begin = __root.ImGuiListClipper_Begin;
    pub const ImGuiListClipper_End = __root.ImGuiListClipper_End;
    pub const ImGuiListClipper_Step = __root.ImGuiListClipper_Step;
    pub const ImGuiListClipper_IncludeItemByIndex = __root.ImGuiListClipper_IncludeItemByIndex;
    pub const ImGuiListClipper_IncludeItemsByIndex = __root.ImGuiListClipper_IncludeItemsByIndex;
    pub const ImGuiListClipper_SeekCursorForItem = __root.ImGuiListClipper_SeekCursorForItem;
    pub const Begin = __root.ImGuiListClipper_Begin;
    pub const End = __root.ImGuiListClipper_End;
    pub const Step = __root.ImGuiListClipper_Step;
    pub const IncludeItemByIndex = __root.ImGuiListClipper_IncludeItemByIndex;
    pub const IncludeItemsByIndex = __root.ImGuiListClipper_IncludeItemsByIndex;
    pub const SeekCursorForItem = __root.ImGuiListClipper_SeekCursorForItem;
};
pub const ImGuiListClipper = struct_ImGuiListClipper_t;
pub const struct_ImGuiMultiSelectIO_t = extern struct {
    Requests: ImVector_ImGuiSelectionRequest,
    RangeSrcItem: ImGuiSelectionUserData,
    NavIdItem: ImGuiSelectionUserData,
    NavIdSelected: bool,
    RangeSrcReset: bool,
    ItemsCount: c_int,
};
pub const ImGuiMultiSelectIO = struct_ImGuiMultiSelectIO_t;
pub const struct_ImGuiPayload_t = extern struct {
    Data: ?*anyopaque,
    DataSize: c_int,
    SourceId: ImGuiID,
    SourceParentId: ImGuiID,
    DataFrameCount: c_int,
    DataType: [33]u8,
    Preview: bool,
    Delivery: bool,
    pub const ImGuiPayload_Clear = __root.ImGuiPayload_Clear;
    pub const ImGuiPayload_IsDataType = __root.ImGuiPayload_IsDataType;
    pub const ImGuiPayload_IsPreview = __root.ImGuiPayload_IsPreview;
    pub const ImGuiPayload_IsDelivery = __root.ImGuiPayload_IsDelivery;
    pub const Clear = __root.ImGuiPayload_Clear;
    pub const IsDataType = __root.ImGuiPayload_IsDataType;
    pub const IsPreview = __root.ImGuiPayload_IsPreview;
    pub const IsDelivery = __root.ImGuiPayload_IsDelivery;
};
pub const ImGuiPayload = struct_ImGuiPayload_t;
pub const struct_ImGuiPlatformImeData_t = extern struct {
    WantVisible: bool,
    WantTextInput: bool,
    InputPos: ImVec2,
    InputLineHeight: f32,
    ViewportId: ImGuiID,
};
pub const ImGuiPlatformImeData = struct_ImGuiPlatformImeData_t;
pub const struct_ImGuiPlatformIO_t = extern struct {
    Platform_GetClipboardTextFn: ?*const fn (ctx: ?*ImGuiContext) callconv(.c) [*c]const u8,
    Platform_SetClipboardTextFn: ?*const fn (ctx: ?*ImGuiContext, text: [*c]const u8) callconv(.c) void,
    Platform_ClipboardUserData: ?*anyopaque,
    Platform_OpenInShellFn: ?*const fn (ctx: ?*ImGuiContext, path: [*c]const u8) callconv(.c) bool,
    Platform_OpenInShellUserData: ?*anyopaque,
    Platform_SetImeDataFn: ?*const fn (ctx: ?*ImGuiContext, viewport: [*c]ImGuiViewport, data: [*c]ImGuiPlatformImeData) callconv(.c) void,
    Platform_ImeUserData: ?*anyopaque,
    Platform_LocaleDecimalPoint: ImWchar,
    Platform_SessionDate: c_int,
    Renderer_TextureMaxWidth: c_int,
    Renderer_TextureMaxHeight: c_int,
    Renderer_RenderState: ?*anyopaque,
    DrawCallback_ResetRenderState: ImDrawCallback,
    DrawCallback_SetSamplerLinear: ImDrawCallback,
    DrawCallback_SetSamplerNearest: ImDrawCallback,
    Platform_CreateWindow: ?*const fn (vp: [*c]ImGuiViewport) callconv(.c) void,
    Platform_DestroyWindow: ?*const fn (vp: [*c]ImGuiViewport) callconv(.c) void,
    Platform_ShowWindow: ?*const fn (vp: [*c]ImGuiViewport) callconv(.c) void,
    Platform_SetWindowPos: ?*const fn (vp: [*c]ImGuiViewport, pos: ImVec2) callconv(.c) void,
    Platform_GetWindowPos: ?*const fn (vp: [*c]ImGuiViewport) callconv(.c) ImVec2,
    Platform_SetWindowSize: ?*const fn (vp: [*c]ImGuiViewport, size: ImVec2) callconv(.c) void,
    Platform_GetWindowSize: ?*const fn (vp: [*c]ImGuiViewport) callconv(.c) ImVec2,
    Platform_GetWindowFramebufferScale: ?*const fn (vp: [*c]ImGuiViewport) callconv(.c) ImVec2,
    Platform_SetWindowFocus: ?*const fn (vp: [*c]ImGuiViewport) callconv(.c) void,
    Platform_GetWindowFocus: ?*const fn (vp: [*c]ImGuiViewport) callconv(.c) bool,
    Platform_GetWindowMinimized: ?*const fn (vp: [*c]ImGuiViewport) callconv(.c) bool,
    Platform_SetWindowTitle: ?*const fn (vp: [*c]ImGuiViewport, str: [*c]const u8) callconv(.c) void,
    Platform_SetWindowAlpha: ?*const fn (vp: [*c]ImGuiViewport, alpha: f32) callconv(.c) void,
    Platform_UpdateWindow: ?*const fn (vp: [*c]ImGuiViewport) callconv(.c) void,
    Platform_RenderWindow: ?*const fn (vp: [*c]ImGuiViewport, render_arg: ?*anyopaque) callconv(.c) void,
    Platform_SwapBuffers: ?*const fn (vp: [*c]ImGuiViewport, render_arg: ?*anyopaque) callconv(.c) void,
    Platform_GetWindowDpiScale: ?*const fn (vp: [*c]ImGuiViewport) callconv(.c) f32,
    Platform_OnChangedViewport: ?*const fn (vp: [*c]ImGuiViewport) callconv(.c) void,
    Platform_GetWindowWorkAreaInsets: ?*const fn (vp: [*c]ImGuiViewport) callconv(.c) ImVec4,
    Platform_CreateVkSurface: ?*const fn (vp: [*c]ImGuiViewport, vk_inst: ImU64, vk_allocators: ?*const anyopaque, out_vk_surface: [*c]ImU64) callconv(.c) c_int,
    Renderer_CreateWindow: ?*const fn (vp: [*c]ImGuiViewport) callconv(.c) void,
    Renderer_DestroyWindow: ?*const fn (vp: [*c]ImGuiViewport) callconv(.c) void,
    Renderer_SetWindowSize: ?*const fn (vp: [*c]ImGuiViewport, size: ImVec2) callconv(.c) void,
    Renderer_RenderWindow: ?*const fn (vp: [*c]ImGuiViewport, render_arg: ?*anyopaque) callconv(.c) void,
    Renderer_SwapBuffers: ?*const fn (vp: [*c]ImGuiViewport, render_arg: ?*anyopaque) callconv(.c) void,
    Monitors: ImVector_ImGuiPlatformMonitor,
    Textures: ImVector_ImTextureDataPtr,
    Viewports: ImVector_ImGuiViewportPtr,
    pub const ImGuiPlatformIO_ClearPlatformHandlers = __root.ImGuiPlatformIO_ClearPlatformHandlers;
    pub const ImGuiPlatformIO_ClearRendererHandlers = __root.ImGuiPlatformIO_ClearRendererHandlers;
    pub const ClearPlatformHandlers = __root.ImGuiPlatformIO_ClearPlatformHandlers;
    pub const ClearRendererHandlers = __root.ImGuiPlatformIO_ClearRendererHandlers;
};
pub const ImGuiPlatformIO = struct_ImGuiPlatformIO_t;
pub const ImGuiSelectionBasicStorage = struct_ImGuiSelectionBasicStorage_t;
pub const struct_ImGuiSelectionBasicStorage_t = extern struct {
    Size: c_int,
    PreserveOrder: bool,
    UserData: ?*anyopaque,
    AdapterIndexToStorageId: ?*const fn (self: [*c]ImGuiSelectionBasicStorage, idx: c_int) callconv(.c) ImGuiID,
    _SelectionOrder: c_int,
    _Storage: ImGuiStorage,
    pub const ImGuiSelectionBasicStorage_ApplyRequests = __root.ImGuiSelectionBasicStorage_ApplyRequests;
    pub const ImGuiSelectionBasicStorage_Contains = __root.ImGuiSelectionBasicStorage_Contains;
    pub const ImGuiSelectionBasicStorage_Clear = __root.ImGuiSelectionBasicStorage_Clear;
    pub const ImGuiSelectionBasicStorage_Swap = __root.ImGuiSelectionBasicStorage_Swap;
    pub const ImGuiSelectionBasicStorage_SetItemSelected = __root.ImGuiSelectionBasicStorage_SetItemSelected;
    pub const ImGuiSelectionBasicStorage_GetNextSelectedItem = __root.ImGuiSelectionBasicStorage_GetNextSelectedItem;
    pub const ImGuiSelectionBasicStorage_GetStorageIdFromIndex = __root.ImGuiSelectionBasicStorage_GetStorageIdFromIndex;
    pub const ApplyRequests = __root.ImGuiSelectionBasicStorage_ApplyRequests;
    pub const Contains = __root.ImGuiSelectionBasicStorage_Contains;
    pub const Clear = __root.ImGuiSelectionBasicStorage_Clear;
    pub const Swap = __root.ImGuiSelectionBasicStorage_Swap;
    pub const SetItemSelected = __root.ImGuiSelectionBasicStorage_SetItemSelected;
    pub const GetNextSelectedItem = __root.ImGuiSelectionBasicStorage_GetNextSelectedItem;
    pub const GetStorageIdFromIndex = __root.ImGuiSelectionBasicStorage_GetStorageIdFromIndex;
};
pub const ImGuiSelectionExternalStorage = struct_ImGuiSelectionExternalStorage_t;
pub const struct_ImGuiSelectionExternalStorage_t = extern struct {
    UserData: ?*anyopaque,
    AdapterSetItemSelected: ?*const fn (self: [*c]ImGuiSelectionExternalStorage, idx: c_int, selected: bool) callconv(.c) void,
    pub const ImGuiSelectionExternalStorage_ApplyRequests = __root.ImGuiSelectionExternalStorage_ApplyRequests;
    pub const ApplyRequests = __root.ImGuiSelectionExternalStorage_ApplyRequests;
};
pub const struct_ImGuiSizeCallbackData_t = extern struct {
    UserData: ?*anyopaque,
    Pos: ImVec2,
    CurrentSize: ImVec2,
    DesiredSize: ImVec2,
};
pub const ImGuiSizeCallbackData = struct_ImGuiSizeCallbackData_t;
pub const ImGuiDir = c_int;
pub const ImGuiTreeNodeFlags = c_int;
pub const ImGuiHoveredFlags = c_int;
pub const struct_ImGuiStyle_t = extern struct {
    FontSizeBase: f32,
    FontScaleMain: f32,
    FontScaleDpi: f32,
    Alpha: f32,
    DisabledAlpha: f32,
    WindowPadding: ImVec2,
    WindowRounding: f32,
    WindowBorderSize: f32,
    WindowBorderHoverPadding: f32,
    WindowMinSize: ImVec2,
    WindowTitleAlign: ImVec2,
    WindowMenuButtonPosition: ImGuiDir,
    ChildRounding: f32,
    ChildBorderSize: f32,
    PopupRounding: f32,
    PopupBorderSize: f32,
    FramePadding: ImVec2,
    FrameRounding: f32,
    FrameBorderSize: f32,
    ItemSpacing: ImVec2,
    ItemInnerSpacing: ImVec2,
    CellPadding: ImVec2,
    TouchExtraPadding: ImVec2,
    IndentSpacing: f32,
    ColumnsMinSpacing: f32,
    ScrollbarSize: f32,
    ScrollbarRounding: f32,
    ScrollbarPadding: f32,
    GrabMinSize: f32,
    GrabRounding: f32,
    LogSliderDeadzone: f32,
    ImageRounding: f32,
    ImageBorderSize: f32,
    TabRounding: f32,
    TabBorderSize: f32,
    TabMinWidthBase: f32,
    TabMinWidthShrink: f32,
    TabCloseButtonMinWidthSelected: f32,
    TabCloseButtonMinWidthUnselected: f32,
    TabBarBorderSize: f32,
    TabBarOverlineSize: f32,
    TableAngledHeadersAngle: f32,
    TableAngledHeadersTextAlign: ImVec2,
    TreeLinesFlags: ImGuiTreeNodeFlags,
    TreeLinesSize: f32,
    TreeLinesRounding: f32,
    MenuItemRounding: f32,
    SelectableRounding: f32,
    DragDropTargetRounding: f32,
    DragDropTargetBorderSize: f32,
    DragDropTargetPadding: f32,
    ColorMarkerSize: f32,
    ColorButtonPosition: ImGuiDir,
    ButtonTextAlign: ImVec2,
    SelectableTextAlign: ImVec2,
    InputTextCursorSize: f32,
    SeparatorSize: f32,
    SeparatorTextBorderSize: f32,
    SeparatorTextAlign: ImVec2,
    SeparatorTextPadding: ImVec2,
    DisplayWindowPadding: ImVec2,
    DisplaySafeAreaPadding: ImVec2,
    DockingNodeHasCloseButton: bool,
    DockingSeparatorSize: f32,
    MouseCursorScale: f32,
    AntiAliasedLines: bool,
    AntiAliasedLinesUseTex: bool,
    AntiAliasedFill: bool,
    CurveTessellationTol: f32,
    CircleTessellationMaxError: f32,
    Colors: [63]ImVec4,
    HoverStationaryDelay: f32,
    HoverDelayShort: f32,
    HoverDelayNormal: f32,
    HoverFlagsForTooltipMouse: ImGuiHoveredFlags,
    HoverFlagsForTooltipNav: ImGuiHoveredFlags,
    _MainScale: f32,
    _NextFrameFontSizeBase: f32,
    pub const igShowStyleEditor = __root.igShowStyleEditor;
    pub const igStyleColorsDark = __root.igStyleColorsDark;
    pub const igStyleColorsLight = __root.igStyleColorsLight;
    pub const igStyleColorsClassic = __root.igStyleColorsClassic;
    pub const ImGuiStyle_ScaleAllSizes = __root.ImGuiStyle_ScaleAllSizes;
    pub const ScaleAllSizes = __root.ImGuiStyle_ScaleAllSizes;
};
pub const ImGuiStyle = struct_ImGuiStyle_t;
pub const ImGuiSortDirection = ImU8;
pub const struct_ImGuiTableColumnSortSpecs_t = extern struct {
    ColumnUserID: ImGuiID,
    ColumnIndex: ImS16,
    SortOrder: ImS16,
    SortDirection: ImGuiSortDirection,
};
pub const ImGuiTableColumnSortSpecs = struct_ImGuiTableColumnSortSpecs_t;
pub const struct_ImGuiTableSortSpecs_t = extern struct {
    Specs: [*c]const ImGuiTableColumnSortSpecs,
    SpecsCount: c_int,
    SpecsDirty: bool,
};
pub const ImGuiTableSortSpecs = struct_ImGuiTableSortSpecs_t;
pub const struct_ImGuiTextBuffer_t = extern struct {
    Buf: ImVector_char,
    pub const ImGuiTextBuffer_begin = __root.ImGuiTextBuffer_begin;
    pub const ImGuiTextBuffer_end = __root.ImGuiTextBuffer_end;
    pub const ImGuiTextBuffer_size = __root.ImGuiTextBuffer_size;
    pub const ImGuiTextBuffer_empty = __root.ImGuiTextBuffer_empty;
    pub const ImGuiTextBuffer_clear = __root.ImGuiTextBuffer_clear;
    pub const ImGuiTextBuffer_resize = __root.ImGuiTextBuffer_resize;
    pub const ImGuiTextBuffer_reserve = __root.ImGuiTextBuffer_reserve;
    pub const ImGuiTextBuffer_c_str = __root.ImGuiTextBuffer_c_str;
    pub const ImGuiTextBuffer_append = __root.ImGuiTextBuffer_append;
    pub const ImGuiTextBuffer_appendf = __root.ImGuiTextBuffer_appendf;
    pub const ImGuiTextBuffer_appendfv = __root.ImGuiTextBuffer_appendfv;
    pub const begin = __root.ImGuiTextBuffer_begin;
    pub const end = __root.ImGuiTextBuffer_end;
    pub const size = __root.ImGuiTextBuffer_size;
    pub const empty = __root.ImGuiTextBuffer_empty;
    pub const clear = __root.ImGuiTextBuffer_clear;
    pub const resize = __root.ImGuiTextBuffer_resize;
    pub const reserve = __root.ImGuiTextBuffer_reserve;
    pub const str = __root.ImGuiTextBuffer_c_str;
    pub const append = __root.ImGuiTextBuffer_append;
    pub const appendf = __root.ImGuiTextBuffer_appendf;
    pub const appendfv = __root.ImGuiTextBuffer_appendfv;
};
pub const ImGuiTextBuffer = struct_ImGuiTextBuffer_t;
pub const struct_ImGuiTextFilter_t = extern struct {
    InputBuf: [256]u8,
    Filters: ImVector_ImGuiTextRange,
    CountGrep: c_int,
    pub const ImGuiTextFilter_Draw = __root.ImGuiTextFilter_Draw;
    pub const ImGuiTextFilter_PassFilter = __root.ImGuiTextFilter_PassFilter;
    pub const ImGuiTextFilter_Build = __root.ImGuiTextFilter_Build;
    pub const ImGuiTextFilter_Clear = __root.ImGuiTextFilter_Clear;
    pub const ImGuiTextFilter_IsActive = __root.ImGuiTextFilter_IsActive;
    pub const Draw = __root.ImGuiTextFilter_Draw;
    pub const PassFilter = __root.ImGuiTextFilter_PassFilter;
    pub const Build = __root.ImGuiTextFilter_Build;
    pub const Clear = __root.ImGuiTextFilter_Clear;
    pub const IsActive = __root.ImGuiTextFilter_IsActive;
};
pub const ImGuiTextFilter = struct_ImGuiTextFilter_t;
pub const ImGuiTabItemFlags = c_int;
pub const ImGuiDockNodeFlags = c_int;
pub const struct_ImGuiWindowClass_t = extern struct {
    ClassId: ImGuiID,
    ParentViewportId: ImGuiID,
    FocusRouteParentWindowId: ImGuiID,
    ViewportFlagsOverrideSet: ImGuiViewportFlags,
    ViewportFlagsOverrideClear: ImGuiViewportFlags,
    TabItemFlagsOverrideSet: ImGuiTabItemFlags,
    DockNodeFlagsOverrideSet: ImGuiDockNodeFlags,
    DockingAlwaysTabBar: bool,
    DockingAllowUnclassed: bool,
    PlatformIconData: ?*anyopaque,
    pub const igSetNextWindowClass = __root.igSetNextWindowClass;
};
pub const ImGuiWindowClass = struct_ImGuiWindowClass_t;
pub const ImGuiCol = c_int;
pub const ImGuiCond = c_int;
pub const ImGuiDataType = c_int;
pub const ImGuiMouseButton = c_int;
pub const ImGuiMouseCursor = c_int;
pub const ImGuiStyleVar = c_int;
pub const ImGuiTableBgTarget = c_int;
pub const ImDrawFlags = c_int;
pub const ImDrawTextFlags = c_int;
pub const ImGuiButtonFlags = c_int;
pub const ImGuiChildFlags = c_int;
pub const ImGuiComboFlags = c_int;
pub const ImGuiDragDropFlags = c_int;
pub const ImGuiFocusedFlags = c_int;
pub const ImGuiInputFlags = c_int;
pub const ImGuiItemFlags = c_int;
pub const ImGuiPopupFlags = c_int;
pub const ImGuiMultiSelectFlags = c_int;
pub const ImGuiSelectableFlags = c_int;
pub const ImGuiSliderFlags = c_int;
pub const ImGuiTabBarFlags = c_int;
pub const ImGuiTableFlags = c_int;
pub const ImGuiTableColumnFlags = c_int;
pub const ImGuiTableRowFlags = c_int;
pub const ImGuiWindowFlags = c_int;
pub const ImWchar32 = c_uint;
pub const ImGuiInputTextCallback = ?*const fn (data: [*c]ImGuiInputTextCallbackData) callconv(.c) c_int;
pub const ImGuiSizeCallback = ?*const fn (data: [*c]ImGuiSizeCallbackData) callconv(.c) void;
pub const ImGuiMemAllocFunc = ?*const fn (sz: usize, user_data: ?*anyopaque) callconv(.c) ?*anyopaque;
pub const ImGuiMemFreeFunc = ?*const fn (ptr: ?*anyopaque, user_data: ?*anyopaque) callconv(.c) void;
pub extern fn ImTextureRef_GetTexID(self: [*c]const ImTextureRef) ImTextureID;
pub extern fn igCreateContext(shared_font_atlas: [*c]ImFontAtlas) ?*ImGuiContext;
pub extern fn igDestroyContext(ctx: ?*ImGuiContext) void;
pub extern fn igGetCurrentContext() ?*ImGuiContext;
pub extern fn igSetCurrentContext(ctx: ?*ImGuiContext) void;
pub extern fn igGetIO() [*c]ImGuiIO;
pub extern fn igGetPlatformIO() [*c]ImGuiPlatformIO;
pub extern fn igGetStyle() [*c]ImGuiStyle;
pub extern fn igNewFrame() void;
pub extern fn igEndFrame() void;
pub extern fn igRender() void;
pub extern fn igGetDrawData() [*c]ImDrawData;
pub extern fn igShowDemoWindow(p_open: [*c]bool) void;
pub extern fn igShowMetricsWindow(p_open: [*c]bool) void;
pub extern fn igShowDebugLogWindow(p_open: [*c]bool) void;
pub extern fn igShowIDStackToolWindow() void;
pub extern fn igShowIDStackToolWindowEx(p_open: [*c]bool) void;
pub extern fn igShowAboutWindow(p_open: [*c]bool) void;
pub extern fn igShowStyleEditor(ref: [*c]ImGuiStyle) void;
pub extern fn igShowStyleSelector(label: [*c]const u8) bool;
pub extern fn igShowFontSelector(label: [*c]const u8) void;
pub extern fn igShowUserGuide() void;
pub extern fn igGetVersion() [*c]const u8;
pub extern fn igStyleColorsDark(dst: [*c]ImGuiStyle) void;
pub extern fn igStyleColorsLight(dst: [*c]ImGuiStyle) void;
pub extern fn igStyleColorsClassic(dst: [*c]ImGuiStyle) void;
pub extern fn igBegin(name: [*c]const u8, p_open: [*c]bool, flags: ImGuiWindowFlags) bool;
pub extern fn igEnd() void;
pub extern fn igBeginChild(str_id: [*c]const u8, size: ImVec2, child_flags: ImGuiChildFlags, window_flags: ImGuiWindowFlags) bool;
pub extern fn igBeginChildID(id: ImGuiID, size: ImVec2, child_flags: ImGuiChildFlags, window_flags: ImGuiWindowFlags) bool;
pub extern fn igEndChild() void;
pub extern fn igIsWindowAppearing() bool;
pub extern fn igIsWindowCollapsed() bool;
pub extern fn igIsWindowFocused(flags: ImGuiFocusedFlags) bool;
pub extern fn igIsWindowHovered(flags: ImGuiHoveredFlags) bool;
pub extern fn igGetWindowDrawList() [*c]ImDrawList;
pub extern fn igGetWindowDpiScale() f32;
pub extern fn igGetWindowPos() ImVec2;
pub extern fn igGetWindowSize() ImVec2;
pub extern fn igGetWindowWidth() f32;
pub extern fn igGetWindowHeight() f32;
pub extern fn igGetWindowViewport() [*c]ImGuiViewport;
pub extern fn igSetNextWindowPos(pos: ImVec2, cond: ImGuiCond) void;
pub extern fn igSetNextWindowPosEx(pos: ImVec2, cond: ImGuiCond, pivot: ImVec2) void;
pub extern fn igSetNextWindowSize(size: ImVec2, cond: ImGuiCond) void;
pub extern fn igSetNextWindowSizeConstraints(size_min: ImVec2, size_max: ImVec2, custom_callback: ImGuiSizeCallback, custom_callback_data: ?*anyopaque) void;
pub extern fn igSetNextWindowContentSize(size: ImVec2) void;
pub extern fn igSetNextWindowCollapsed(collapsed: bool, cond: ImGuiCond) void;
pub extern fn igSetNextWindowFocus() void;
pub extern fn igSetNextWindowScroll(scroll: ImVec2) void;
pub extern fn igSetNextWindowBgAlpha(alpha: f32) void;
pub extern fn igSetNextWindowViewport(viewport_id: ImGuiID) void;
pub extern fn igSetWindowPos(pos: ImVec2, cond: ImGuiCond) void;
pub extern fn igSetWindowSize(size: ImVec2, cond: ImGuiCond) void;
pub extern fn igSetWindowCollapsed(collapsed: bool, cond: ImGuiCond) void;
pub extern fn igSetWindowFocus() void;
pub extern fn igSetWindowPosStr(name: [*c]const u8, pos: ImVec2, cond: ImGuiCond) void;
pub extern fn igSetWindowSizeStr(name: [*c]const u8, size: ImVec2, cond: ImGuiCond) void;
pub extern fn igSetWindowCollapsedStr(name: [*c]const u8, collapsed: bool, cond: ImGuiCond) void;
pub extern fn igSetWindowFocusStr(name: [*c]const u8) void;
pub extern fn igGetScrollX() f32;
pub extern fn igGetScrollY() f32;
pub extern fn igSetScrollX(scroll_x: f32) void;
pub extern fn igSetScrollY(scroll_y: f32) void;
pub extern fn igGetScrollMaxX() f32;
pub extern fn igGetScrollMaxY() f32;
pub extern fn igSetScrollHereX(center_x_ratio: f32) void;
pub extern fn igSetScrollHereY(center_y_ratio: f32) void;
pub extern fn igSetScrollFromPosX(local_x: f32, center_x_ratio: f32) void;
pub extern fn igSetScrollFromPosY(local_y: f32, center_y_ratio: f32) void;
pub extern fn igPushFontFloat(font: [*c]ImFont, font_size_base_unscaled: f32) void;
pub extern fn igPopFont() void;
pub extern fn igGetFont() [*c]ImFont;
pub extern fn igGetFontSize() f32;
pub extern fn igGetFontBaked() ?*ImFontBaked;
pub extern fn igPushStyleColor(idx: ImGuiCol, col: ImU32) void;
pub extern fn igPushStyleColorImVec4(idx: ImGuiCol, col: ImVec4) void;
pub extern fn igPopStyleColor() void;
pub extern fn igPopStyleColorEx(count: c_int) void;
pub extern fn igPushStyleVar(idx: ImGuiStyleVar, val: f32) void;
pub extern fn igPushStyleVarImVec2(idx: ImGuiStyleVar, val: ImVec2) void;
pub extern fn igPushStyleVarX(idx: ImGuiStyleVar, val_x: f32) void;
pub extern fn igPushStyleVarY(idx: ImGuiStyleVar, val_y: f32) void;
pub extern fn igPopStyleVar() void;
pub extern fn igPopStyleVarEx(count: c_int) void;
pub extern fn igPushItemFlag(option: ImGuiItemFlags, enabled: bool) void;
pub extern fn igPopItemFlag() void;
pub extern fn igPushItemWidth(item_width: f32) void;
pub extern fn igPopItemWidth() void;
pub extern fn igSetNextItemWidth(item_width: f32) void;
pub extern fn igCalcItemWidth() f32;
pub extern fn igPushTextWrapPos(wrap_local_pos_x: f32) void;
pub extern fn igPopTextWrapPos() void;
pub extern fn igGetFontTexUvWhitePixel() ImVec2;
pub extern fn igGetColorU32(idx: ImGuiCol) ImU32;
pub extern fn igGetColorU32Ex(idx: ImGuiCol, alpha_mul: f32) ImU32;
pub extern fn igGetColorU32ImVec4(col: ImVec4) ImU32;
pub extern fn igGetColorU32ImU32(col: ImU32) ImU32;
pub extern fn igGetColorU32ImU32Ex(col: ImU32, alpha_mul: f32) ImU32;
pub extern fn igGetStyleColorVec4(idx: ImGuiCol) [*c]const ImVec4;
pub extern fn igGetCursorScreenPos() ImVec2;
pub extern fn igSetCursorScreenPos(pos: ImVec2) void;
pub extern fn igGetContentRegionAvail() ImVec2;
pub extern fn igGetCursorPos() ImVec2;
pub extern fn igGetCursorPosX() f32;
pub extern fn igGetCursorPosY() f32;
pub extern fn igSetCursorPos(local_pos: ImVec2) void;
pub extern fn igSetCursorPosX(local_x: f32) void;
pub extern fn igSetCursorPosY(local_y: f32) void;
pub extern fn igGetCursorStartPos() ImVec2;
pub extern fn igSeparator() void;
pub extern fn igSameLine() void;
pub extern fn igSameLineEx(offset_from_start_x: f32, spacing: f32) void;
pub extern fn igNewLine() void;
pub extern fn igSpacing() void;
pub extern fn igDummy(size: ImVec2) void;
pub extern fn igIndent() void;
pub extern fn igIndentEx(indent_w: f32) void;
pub extern fn igUnindent() void;
pub extern fn igUnindentEx(indent_w: f32) void;
pub extern fn igBeginGroup() void;
pub extern fn igEndGroup() void;
pub extern fn igAlignTextToFramePadding() void;
pub extern fn igGetTextLineHeight() f32;
pub extern fn igGetTextLineHeightWithSpacing() f32;
pub extern fn igGetFrameHeight() f32;
pub extern fn igGetFrameHeightWithSpacing() f32;
pub extern fn igPushID(str_id: [*c]const u8) void;
pub extern fn igPushIDStr(str_id_begin: [*c]const u8, str_id_end: [*c]const u8) void;
pub extern fn igPushIDPtr(ptr_id: ?*const anyopaque) void;
pub extern fn igPushIDInt(int_id: c_int) void;
pub extern fn igPopID() void;
pub extern fn igGetID(str_id: [*c]const u8) ImGuiID;
pub extern fn igGetIDStr(str_id_begin: [*c]const u8, str_id_end: [*c]const u8) ImGuiID;
pub extern fn igGetIDPtr(ptr_id: ?*const anyopaque) ImGuiID;
pub extern fn igGetIDInt(int_id: c_int) ImGuiID;
pub extern fn igTextUnformatted(text: [*c]const u8) void;
pub extern fn igTextUnformattedEx(text: [*c]const u8, text_end: [*c]const u8) void;
pub extern fn igText(fmt: [*c]const u8, ...) void;
pub extern fn igTextV(fmt: [*c]const u8, args: va_list) void;
pub extern fn igTextColored(col: ImVec4, fmt: [*c]const u8, ...) void;
pub extern fn igTextColoredV(col: ImVec4, fmt: [*c]const u8, args: va_list) void;
pub extern fn igTextDisabled(fmt: [*c]const u8, ...) void;
pub extern fn igTextDisabledV(fmt: [*c]const u8, args: va_list) void;
pub extern fn igTextWrapped(fmt: [*c]const u8, ...) void;
pub extern fn igTextWrappedV(fmt: [*c]const u8, args: va_list) void;
pub extern fn igLabelText(label: [*c]const u8, fmt: [*c]const u8, ...) void;
pub extern fn igLabelTextV(label: [*c]const u8, fmt: [*c]const u8, args: va_list) void;
pub extern fn igBulletText(fmt: [*c]const u8, ...) void;
pub extern fn igBulletTextV(fmt: [*c]const u8, args: va_list) void;
pub extern fn igSeparatorText(label: [*c]const u8) void;
pub extern fn igButton(label: [*c]const u8) bool;
pub extern fn igButtonEx(label: [*c]const u8, size: ImVec2) bool;
pub extern fn igSmallButton(label: [*c]const u8) bool;
pub extern fn igInvisibleButton(str_id: [*c]const u8, size: ImVec2, flags: ImGuiButtonFlags) bool;
pub extern fn igArrowButton(str_id: [*c]const u8, dir: ImGuiDir) bool;
pub extern fn igCheckbox(label: [*c]const u8, v: [*c]bool) bool;
pub extern fn igCheckboxFlagsIntPtr(label: [*c]const u8, flags: [*c]c_int, flags_value: c_int) bool;
pub extern fn igCheckboxFlagsUintPtr(label: [*c]const u8, flags: [*c]c_uint, flags_value: c_uint) bool;
pub extern fn igRadioButton(label: [*c]const u8, active: bool) bool;
pub extern fn igRadioButtonIntPtr(label: [*c]const u8, v: [*c]c_int, v_button: c_int) bool;
pub extern fn igProgressBar(fraction: f32, size_arg: ImVec2, overlay: [*c]const u8) void;
pub extern fn igBullet() void;
pub extern fn igTextLink(label: [*c]const u8) bool;
pub extern fn igTextLinkOpenURL(label: [*c]const u8) bool;
pub extern fn igTextLinkOpenURLEx(label: [*c]const u8, url: [*c]const u8) bool;
pub extern fn igImage(tex_ref: ImTextureRef, image_size: ImVec2) void;
pub extern fn igImageEx(tex_ref: ImTextureRef, image_size: ImVec2, uv0: ImVec2, uv1: ImVec2) void;
pub extern fn igImageWithBg(tex_ref: ImTextureRef, image_size: ImVec2) void;
pub extern fn igImageWithBgEx(tex_ref: ImTextureRef, image_size: ImVec2, uv0: ImVec2, uv1: ImVec2, bg_col: ImVec4, tint_col: ImVec4) void;
pub extern fn igImageButton(str_id: [*c]const u8, tex_ref: ImTextureRef, image_size: ImVec2) bool;
pub extern fn igImageButtonEx(str_id: [*c]const u8, tex_ref: ImTextureRef, image_size: ImVec2, uv0: ImVec2, uv1: ImVec2, bg_col: ImVec4, tint_col: ImVec4) bool;
pub extern fn igBeginCombo(label: [*c]const u8, preview_value: [*c]const u8, flags: ImGuiComboFlags) bool;
pub extern fn igEndCombo() void;
pub extern fn igComboChar(label: [*c]const u8, current_item: [*c]c_int, items: [*c]const [*c]const u8, items_count: c_int) bool;
pub extern fn igComboCharEx(label: [*c]const u8, current_item: [*c]c_int, items: [*c]const [*c]const u8, items_count: c_int, popup_max_height_in_items: c_int) bool;
pub extern fn igCombo(label: [*c]const u8, current_item: [*c]c_int, items_separated_by_zeros: [*c]const u8) bool;
pub extern fn igComboEx(label: [*c]const u8, current_item: [*c]c_int, items_separated_by_zeros: [*c]const u8, popup_max_height_in_items: c_int) bool;
pub extern fn igComboCallback(label: [*c]const u8, current_item: [*c]c_int, getter: ?*const fn (user_data: ?*anyopaque, idx: c_int) callconv(.c) [*c]const u8, user_data: ?*anyopaque, items_count: c_int) bool;
pub extern fn igComboCallbackEx(label: [*c]const u8, current_item: [*c]c_int, getter: ?*const fn (user_data: ?*anyopaque, idx: c_int) callconv(.c) [*c]const u8, user_data: ?*anyopaque, items_count: c_int, popup_max_height_in_items: c_int) bool;
pub extern fn igDragFloat(label: [*c]const u8, v: [*c]f32) bool;
pub extern fn igDragFloatEx(label: [*c]const u8, v: [*c]f32, v_speed: f32, v_min: f32, v_max: f32, format: [*c]const u8, flags: ImGuiSliderFlags) bool;
pub extern fn igDragFloat2(label: [*c]const u8, v: [*c]f32) bool;
pub extern fn igDragFloat2Ex(label: [*c]const u8, v: [*c]f32, v_speed: f32, v_min: f32, v_max: f32, format: [*c]const u8, flags: ImGuiSliderFlags) bool;
pub extern fn igDragFloat3(label: [*c]const u8, v: [*c]f32) bool;
pub extern fn igDragFloat3Ex(label: [*c]const u8, v: [*c]f32, v_speed: f32, v_min: f32, v_max: f32, format: [*c]const u8, flags: ImGuiSliderFlags) bool;
pub extern fn igDragFloat4(label: [*c]const u8, v: [*c]f32) bool;
pub extern fn igDragFloat4Ex(label: [*c]const u8, v: [*c]f32, v_speed: f32, v_min: f32, v_max: f32, format: [*c]const u8, flags: ImGuiSliderFlags) bool;
pub extern fn igDragFloatRange2(label: [*c]const u8, v_current_min: [*c]f32, v_current_max: [*c]f32) bool;
pub extern fn igDragFloatRange2Ex(label: [*c]const u8, v_current_min: [*c]f32, v_current_max: [*c]f32, v_speed: f32, v_min: f32, v_max: f32, format: [*c]const u8, format_max: [*c]const u8, flags: ImGuiSliderFlags) bool;
pub extern fn igDragInt(label: [*c]const u8, v: [*c]c_int) bool;
pub extern fn igDragIntEx(label: [*c]const u8, v: [*c]c_int, v_speed: f32, v_min: c_int, v_max: c_int, format: [*c]const u8, flags: ImGuiSliderFlags) bool;
pub extern fn igDragInt2(label: [*c]const u8, v: [*c]c_int) bool;
pub extern fn igDragInt2Ex(label: [*c]const u8, v: [*c]c_int, v_speed: f32, v_min: c_int, v_max: c_int, format: [*c]const u8, flags: ImGuiSliderFlags) bool;
pub extern fn igDragInt3(label: [*c]const u8, v: [*c]c_int) bool;
pub extern fn igDragInt3Ex(label: [*c]const u8, v: [*c]c_int, v_speed: f32, v_min: c_int, v_max: c_int, format: [*c]const u8, flags: ImGuiSliderFlags) bool;
pub extern fn igDragInt4(label: [*c]const u8, v: [*c]c_int) bool;
pub extern fn igDragInt4Ex(label: [*c]const u8, v: [*c]c_int, v_speed: f32, v_min: c_int, v_max: c_int, format: [*c]const u8, flags: ImGuiSliderFlags) bool;
pub extern fn igDragIntRange2(label: [*c]const u8, v_current_min: [*c]c_int, v_current_max: [*c]c_int) bool;
pub extern fn igDragIntRange2Ex(label: [*c]const u8, v_current_min: [*c]c_int, v_current_max: [*c]c_int, v_speed: f32, v_min: c_int, v_max: c_int, format: [*c]const u8, format_max: [*c]const u8, flags: ImGuiSliderFlags) bool;
pub extern fn igDragScalar(label: [*c]const u8, data_type: ImGuiDataType, p_data: ?*anyopaque) bool;
pub extern fn igDragScalarEx(label: [*c]const u8, data_type: ImGuiDataType, p_data: ?*anyopaque, v_speed: f32, p_min: ?*const anyopaque, p_max: ?*const anyopaque, format: [*c]const u8, flags: ImGuiSliderFlags) bool;
pub extern fn igDragScalarN(label: [*c]const u8, data_type: ImGuiDataType, p_data: ?*anyopaque, components: c_int) bool;
pub extern fn igDragScalarNEx(label: [*c]const u8, data_type: ImGuiDataType, p_data: ?*anyopaque, components: c_int, v_speed: f32, p_min: ?*const anyopaque, p_max: ?*const anyopaque, format: [*c]const u8, flags: ImGuiSliderFlags) bool;
pub extern fn igSliderFloat(label: [*c]const u8, v: [*c]f32, v_min: f32, v_max: f32) bool;
pub extern fn igSliderFloatEx(label: [*c]const u8, v: [*c]f32, v_min: f32, v_max: f32, format: [*c]const u8, flags: ImGuiSliderFlags) bool;
pub extern fn igSliderFloat2(label: [*c]const u8, v: [*c]f32, v_min: f32, v_max: f32) bool;
pub extern fn igSliderFloat2Ex(label: [*c]const u8, v: [*c]f32, v_min: f32, v_max: f32, format: [*c]const u8, flags: ImGuiSliderFlags) bool;
pub extern fn igSliderFloat3(label: [*c]const u8, v: [*c]f32, v_min: f32, v_max: f32) bool;
pub extern fn igSliderFloat3Ex(label: [*c]const u8, v: [*c]f32, v_min: f32, v_max: f32, format: [*c]const u8, flags: ImGuiSliderFlags) bool;
pub extern fn igSliderFloat4(label: [*c]const u8, v: [*c]f32, v_min: f32, v_max: f32) bool;
pub extern fn igSliderFloat4Ex(label: [*c]const u8, v: [*c]f32, v_min: f32, v_max: f32, format: [*c]const u8, flags: ImGuiSliderFlags) bool;
pub extern fn igSliderAngle(label: [*c]const u8, v_rad: [*c]f32) bool;
pub extern fn igSliderAngleEx(label: [*c]const u8, v_rad: [*c]f32, v_degrees_min: f32, v_degrees_max: f32, format: [*c]const u8, flags: ImGuiSliderFlags) bool;
pub extern fn igSliderInt(label: [*c]const u8, v: [*c]c_int, v_min: c_int, v_max: c_int) bool;
pub extern fn igSliderIntEx(label: [*c]const u8, v: [*c]c_int, v_min: c_int, v_max: c_int, format: [*c]const u8, flags: ImGuiSliderFlags) bool;
pub extern fn igSliderInt2(label: [*c]const u8, v: [*c]c_int, v_min: c_int, v_max: c_int) bool;
pub extern fn igSliderInt2Ex(label: [*c]const u8, v: [*c]c_int, v_min: c_int, v_max: c_int, format: [*c]const u8, flags: ImGuiSliderFlags) bool;
pub extern fn igSliderInt3(label: [*c]const u8, v: [*c]c_int, v_min: c_int, v_max: c_int) bool;
pub extern fn igSliderInt3Ex(label: [*c]const u8, v: [*c]c_int, v_min: c_int, v_max: c_int, format: [*c]const u8, flags: ImGuiSliderFlags) bool;
pub extern fn igSliderInt4(label: [*c]const u8, v: [*c]c_int, v_min: c_int, v_max: c_int) bool;
pub extern fn igSliderInt4Ex(label: [*c]const u8, v: [*c]c_int, v_min: c_int, v_max: c_int, format: [*c]const u8, flags: ImGuiSliderFlags) bool;
pub extern fn igSliderScalar(label: [*c]const u8, data_type: ImGuiDataType, p_data: ?*anyopaque, p_min: ?*const anyopaque, p_max: ?*const anyopaque) bool;
pub extern fn igSliderScalarEx(label: [*c]const u8, data_type: ImGuiDataType, p_data: ?*anyopaque, p_min: ?*const anyopaque, p_max: ?*const anyopaque, format: [*c]const u8, flags: ImGuiSliderFlags) bool;
pub extern fn igSliderScalarN(label: [*c]const u8, data_type: ImGuiDataType, p_data: ?*anyopaque, components: c_int, p_min: ?*const anyopaque, p_max: ?*const anyopaque) bool;
pub extern fn igSliderScalarNEx(label: [*c]const u8, data_type: ImGuiDataType, p_data: ?*anyopaque, components: c_int, p_min: ?*const anyopaque, p_max: ?*const anyopaque, format: [*c]const u8, flags: ImGuiSliderFlags) bool;
pub extern fn igVSliderFloat(label: [*c]const u8, size: ImVec2, v: [*c]f32, v_min: f32, v_max: f32) bool;
pub extern fn igVSliderFloatEx(label: [*c]const u8, size: ImVec2, v: [*c]f32, v_min: f32, v_max: f32, format: [*c]const u8, flags: ImGuiSliderFlags) bool;
pub extern fn igVSliderInt(label: [*c]const u8, size: ImVec2, v: [*c]c_int, v_min: c_int, v_max: c_int) bool;
pub extern fn igVSliderIntEx(label: [*c]const u8, size: ImVec2, v: [*c]c_int, v_min: c_int, v_max: c_int, format: [*c]const u8, flags: ImGuiSliderFlags) bool;
pub extern fn igVSliderScalar(label: [*c]const u8, size: ImVec2, data_type: ImGuiDataType, p_data: ?*anyopaque, p_min: ?*const anyopaque, p_max: ?*const anyopaque) bool;
pub extern fn igVSliderScalarEx(label: [*c]const u8, size: ImVec2, data_type: ImGuiDataType, p_data: ?*anyopaque, p_min: ?*const anyopaque, p_max: ?*const anyopaque, format: [*c]const u8, flags: ImGuiSliderFlags) bool;
pub extern fn igInputText(label: [*c]const u8, buf: [*c]u8, buf_size: usize, flags: ImGuiInputTextFlags) bool;
pub extern fn igInputTextEx(label: [*c]const u8, buf: [*c]u8, buf_size: usize, flags: ImGuiInputTextFlags, callback: ImGuiInputTextCallback, user_data: ?*anyopaque) bool;
pub extern fn igInputTextMultiline(label: [*c]const u8, buf: [*c]u8, buf_size: usize) bool;
pub extern fn igInputTextMultilineEx(label: [*c]const u8, buf: [*c]u8, buf_size: usize, size: ImVec2, flags: ImGuiInputTextFlags, callback: ImGuiInputTextCallback, user_data: ?*anyopaque) bool;
pub extern fn igInputTextWithHint(label: [*c]const u8, hint: [*c]const u8, buf: [*c]u8, buf_size: usize, flags: ImGuiInputTextFlags) bool;
pub extern fn igInputTextWithHintEx(label: [*c]const u8, hint: [*c]const u8, buf: [*c]u8, buf_size: usize, flags: ImGuiInputTextFlags, callback: ImGuiInputTextCallback, user_data: ?*anyopaque) bool;
pub extern fn igInputFloat(label: [*c]const u8, v: [*c]f32) bool;
pub extern fn igInputFloatEx(label: [*c]const u8, v: [*c]f32, step: f32, step_fast: f32, format: [*c]const u8, flags: ImGuiInputTextFlags) bool;
pub extern fn igInputFloat2(label: [*c]const u8, v: [*c]f32) bool;
pub extern fn igInputFloat2Ex(label: [*c]const u8, v: [*c]f32, format: [*c]const u8, flags: ImGuiInputTextFlags) bool;
pub extern fn igInputFloat3(label: [*c]const u8, v: [*c]f32) bool;
pub extern fn igInputFloat3Ex(label: [*c]const u8, v: [*c]f32, format: [*c]const u8, flags: ImGuiInputTextFlags) bool;
pub extern fn igInputFloat4(label: [*c]const u8, v: [*c]f32) bool;
pub extern fn igInputFloat4Ex(label: [*c]const u8, v: [*c]f32, format: [*c]const u8, flags: ImGuiInputTextFlags) bool;
pub extern fn igInputInt(label: [*c]const u8, v: [*c]c_int) bool;
pub extern fn igInputIntEx(label: [*c]const u8, v: [*c]c_int, step: c_int, step_fast: c_int, flags: ImGuiInputTextFlags) bool;
pub extern fn igInputInt2(label: [*c]const u8, v: [*c]c_int, flags: ImGuiInputTextFlags) bool;
pub extern fn igInputInt3(label: [*c]const u8, v: [*c]c_int, flags: ImGuiInputTextFlags) bool;
pub extern fn igInputInt4(label: [*c]const u8, v: [*c]c_int, flags: ImGuiInputTextFlags) bool;
pub extern fn igInputDouble(label: [*c]const u8, v: [*c]f64) bool;
pub extern fn igInputDoubleEx(label: [*c]const u8, v: [*c]f64, step: f64, step_fast: f64, format: [*c]const u8, flags: ImGuiInputTextFlags) bool;
pub extern fn igInputScalar(label: [*c]const u8, data_type: ImGuiDataType, p_data: ?*anyopaque) bool;
pub extern fn igInputScalarEx(label: [*c]const u8, data_type: ImGuiDataType, p_data: ?*anyopaque, p_step: ?*const anyopaque, p_step_fast: ?*const anyopaque, format: [*c]const u8, flags: ImGuiInputTextFlags) bool;
pub extern fn igInputScalarN(label: [*c]const u8, data_type: ImGuiDataType, p_data: ?*anyopaque, components: c_int) bool;
pub extern fn igInputScalarNEx(label: [*c]const u8, data_type: ImGuiDataType, p_data: ?*anyopaque, components: c_int, p_step: ?*const anyopaque, p_step_fast: ?*const anyopaque, format: [*c]const u8, flags: ImGuiInputTextFlags) bool;
pub extern fn igColorEdit3(label: [*c]const u8, col: [*c]f32, flags: ImGuiColorEditFlags) bool;
pub extern fn igColorEdit4(label: [*c]const u8, col: [*c]f32, flags: ImGuiColorEditFlags) bool;
pub extern fn igColorPicker3(label: [*c]const u8, col: [*c]f32, flags: ImGuiColorEditFlags) bool;
pub extern fn igColorPicker4(label: [*c]const u8, col: [*c]f32, flags: ImGuiColorEditFlags, ref_col: [*c]const f32) bool;
pub extern fn igColorButton(desc_id: [*c]const u8, col: ImVec4, flags: ImGuiColorEditFlags) bool;
pub extern fn igColorButtonEx(desc_id: [*c]const u8, col: ImVec4, flags: ImGuiColorEditFlags, size: ImVec2) bool;
pub extern fn igTreeNode(label: [*c]const u8) bool;
pub extern fn igTreeNodeStr(str_id: [*c]const u8, fmt: [*c]const u8, ...) bool;
pub extern fn igTreeNodePtr(ptr_id: ?*const anyopaque, fmt: [*c]const u8, ...) bool;
pub extern fn igTreeNodeV(str_id: [*c]const u8, fmt: [*c]const u8, args: va_list) bool;
pub extern fn igTreeNodeVPtr(ptr_id: ?*const anyopaque, fmt: [*c]const u8, args: va_list) bool;
pub extern fn igTreeNodeEx(label: [*c]const u8, flags: ImGuiTreeNodeFlags) bool;
pub extern fn igTreeNodeExStr(str_id: [*c]const u8, flags: ImGuiTreeNodeFlags, fmt: [*c]const u8, ...) bool;
pub extern fn igTreeNodeExPtr(ptr_id: ?*const anyopaque, flags: ImGuiTreeNodeFlags, fmt: [*c]const u8, ...) bool;
pub extern fn igTreeNodeExV(str_id: [*c]const u8, flags: ImGuiTreeNodeFlags, fmt: [*c]const u8, args: va_list) bool;
pub extern fn igTreeNodeExVPtr(ptr_id: ?*const anyopaque, flags: ImGuiTreeNodeFlags, fmt: [*c]const u8, args: va_list) bool;
pub extern fn igTreePush(str_id: [*c]const u8) void;
pub extern fn igTreePushPtr(ptr_id: ?*const anyopaque) void;
pub extern fn igTreePop() void;
pub extern fn igGetTreeNodeToLabelSpacing() f32;
pub extern fn igCollapsingHeader(label: [*c]const u8, flags: ImGuiTreeNodeFlags) bool;
pub extern fn igCollapsingHeaderBoolPtr(label: [*c]const u8, p_visible: [*c]bool, flags: ImGuiTreeNodeFlags) bool;
pub extern fn igSetNextItemOpen(is_open: bool, cond: ImGuiCond) void;
pub extern fn igSetNextItemStorageID(storage_id: ImGuiID) void;
pub extern fn igTreeNodeGetOpen(storage_id: ImGuiID) bool;
pub extern fn igSelectable(label: [*c]const u8) bool;
pub extern fn igSelectableEx(label: [*c]const u8, selected: bool, flags: ImGuiSelectableFlags, size: ImVec2) bool;
pub extern fn igSelectableBoolPtr(label: [*c]const u8, p_selected: [*c]bool, flags: ImGuiSelectableFlags) bool;
pub extern fn igSelectableBoolPtrEx(label: [*c]const u8, p_selected: [*c]bool, flags: ImGuiSelectableFlags, size: ImVec2) bool;
pub extern fn igBeginMultiSelect(flags: ImGuiMultiSelectFlags) [*c]ImGuiMultiSelectIO;
pub extern fn igBeginMultiSelectEx(flags: ImGuiMultiSelectFlags, selection_size: c_int, items_count: c_int) [*c]ImGuiMultiSelectIO;
pub extern fn igEndMultiSelect() [*c]ImGuiMultiSelectIO;
pub extern fn igSetNextItemSelectionUserData(selection_user_data: ImGuiSelectionUserData) void;
pub extern fn igIsItemToggledSelection() bool;
pub extern fn igBeginListBox(label: [*c]const u8, size: ImVec2) bool;
pub extern fn igEndListBox() void;
pub extern fn igListBox(label: [*c]const u8, current_item: [*c]c_int, items: [*c]const [*c]const u8, items_count: c_int, height_in_items: c_int) bool;
pub extern fn igListBoxCallback(label: [*c]const u8, current_item: [*c]c_int, getter: ?*const fn (user_data: ?*anyopaque, idx: c_int) callconv(.c) [*c]const u8, user_data: ?*anyopaque, items_count: c_int) bool;
pub extern fn igListBoxCallbackEx(label: [*c]const u8, current_item: [*c]c_int, getter: ?*const fn (user_data: ?*anyopaque, idx: c_int) callconv(.c) [*c]const u8, user_data: ?*anyopaque, items_count: c_int, height_in_items: c_int) bool;
pub extern fn igPlotLines(label: [*c]const u8, values: [*c]const f32, values_count: c_int) void;
pub extern fn igPlotLinesEx(label: [*c]const u8, values: [*c]const f32, values_count: c_int, values_offset: c_int, overlay_text: [*c]const u8, scale_min: f32, scale_max: f32, graph_size: ImVec2, stride: c_int) void;
pub extern fn igPlotLinesCallback(label: [*c]const u8, values_getter: ?*const fn (data: ?*anyopaque, idx: c_int) callconv(.c) f32, data: ?*anyopaque, values_count: c_int) void;
pub extern fn igPlotLinesCallbackEx(label: [*c]const u8, values_getter: ?*const fn (data: ?*anyopaque, idx: c_int) callconv(.c) f32, data: ?*anyopaque, values_count: c_int, values_offset: c_int, overlay_text: [*c]const u8, scale_min: f32, scale_max: f32, graph_size: ImVec2) void;
pub extern fn igPlotHistogram(label: [*c]const u8, values: [*c]const f32, values_count: c_int) void;
pub extern fn igPlotHistogramEx(label: [*c]const u8, values: [*c]const f32, values_count: c_int, values_offset: c_int, overlay_text: [*c]const u8, scale_min: f32, scale_max: f32, graph_size: ImVec2, stride: c_int) void;
pub extern fn igPlotHistogramCallback(label: [*c]const u8, values_getter: ?*const fn (data: ?*anyopaque, idx: c_int) callconv(.c) f32, data: ?*anyopaque, values_count: c_int) void;
pub extern fn igPlotHistogramCallbackEx(label: [*c]const u8, values_getter: ?*const fn (data: ?*anyopaque, idx: c_int) callconv(.c) f32, data: ?*anyopaque, values_count: c_int, values_offset: c_int, overlay_text: [*c]const u8, scale_min: f32, scale_max: f32, graph_size: ImVec2) void;
pub extern fn igBeginMenuBar() bool;
pub extern fn igEndMenuBar() void;
pub extern fn igBeginMainMenuBar() bool;
pub extern fn igEndMainMenuBar() void;
pub extern fn igBeginMenu(label: [*c]const u8) bool;
pub extern fn igBeginMenuEx(label: [*c]const u8, enabled: bool) bool;
pub extern fn igEndMenu() void;
pub extern fn igMenuItem(label: [*c]const u8) bool;
pub extern fn igMenuItemEx(label: [*c]const u8, shortcut: [*c]const u8, selected: bool, enabled: bool) bool;
pub extern fn igMenuItemBoolPtr(label: [*c]const u8, shortcut: [*c]const u8, p_selected: [*c]bool, enabled: bool) bool;
pub extern fn igBeginTooltip() bool;
pub extern fn igEndTooltip() void;
pub extern fn igSetTooltip(fmt: [*c]const u8, ...) void;
pub extern fn igSetTooltipV(fmt: [*c]const u8, args: va_list) void;
pub extern fn igBeginItemTooltip() bool;
pub extern fn igSetItemTooltip(fmt: [*c]const u8, ...) void;
pub extern fn igSetItemTooltipV(fmt: [*c]const u8, args: va_list) void;
pub extern fn igBeginPopup(str_id: [*c]const u8, flags: ImGuiWindowFlags) bool;
pub extern fn igBeginPopupModal(name: [*c]const u8, p_open: [*c]bool, flags: ImGuiWindowFlags) bool;
pub extern fn igEndPopup() void;
pub extern fn igOpenPopup(str_id: [*c]const u8, popup_flags: ImGuiPopupFlags) bool;
pub extern fn igOpenPopupID(id: ImGuiID, popup_flags: ImGuiPopupFlags) bool;
pub extern fn igOpenPopupOnItemClick(str_id: [*c]const u8, popup_flags: ImGuiPopupFlags) bool;
pub extern fn igCloseCurrentPopup() void;
pub extern fn igBeginPopupContextItem() bool;
pub extern fn igBeginPopupContextItemEx(str_id: [*c]const u8, popup_flags: ImGuiPopupFlags) bool;
pub extern fn igBeginPopupContextWindow() bool;
pub extern fn igBeginPopupContextWindowEx(str_id: [*c]const u8, popup_flags: ImGuiPopupFlags) bool;
pub extern fn igBeginPopupContextVoid() bool;
pub extern fn igBeginPopupContextVoidEx(str_id: [*c]const u8, popup_flags: ImGuiPopupFlags) bool;
pub extern fn igIsPopupOpen(str_id: [*c]const u8, flags: ImGuiPopupFlags) bool;
pub extern fn igBeginTable(str_id: [*c]const u8, columns: c_int, flags: ImGuiTableFlags) bool;
pub extern fn igBeginTableEx(str_id: [*c]const u8, columns: c_int, flags: ImGuiTableFlags, outer_size: ImVec2, inner_width: f32) bool;
pub extern fn igEndTable() void;
pub extern fn igTableNextRow() void;
pub extern fn igTableNextRowEx(row_flags: ImGuiTableRowFlags, min_row_height: f32) void;
pub extern fn igTableNextColumn() bool;
pub extern fn igTableSetColumnIndex(column_n: c_int) bool;
pub extern fn igTableSetupColumn(label: [*c]const u8, flags: ImGuiTableColumnFlags) void;
pub extern fn igTableSetupColumnEx(label: [*c]const u8, flags: ImGuiTableColumnFlags, init_width_or_weight: f32, user_data: ImGuiID) void;
pub extern fn igTableSetupScrollFreeze(cols: c_int, rows: c_int) void;
pub extern fn igTableHeader(label: [*c]const u8) void;
pub extern fn igTableHeadersRow() void;
pub extern fn igTableAngledHeadersRow() void;
pub extern fn igTableGetSortSpecs() [*c]ImGuiTableSortSpecs;
pub extern fn igTableGetColumnCount() c_int;
pub extern fn igTableGetColumnIndex() c_int;
pub extern fn igTableGetRowIndex() c_int;
pub extern fn igTableGetColumnName(column_n: c_int) [*c]const u8;
pub extern fn igTableGetColumnFlags(column_n: c_int) ImGuiTableColumnFlags;
pub extern fn igTableSetColumnEnabled(column_n: c_int, v: bool) void;
pub extern fn igTableGetHoveredColumn() c_int;
pub extern fn igTableSetBgColor(target: ImGuiTableBgTarget, color: ImU32, column_n: c_int) void;
pub extern fn igColumns() void;
pub extern fn igColumnsEx(count: c_int, id: [*c]const u8, borders: bool) void;
pub extern fn igNextColumn() void;
pub extern fn igGetColumnIndex() c_int;
pub extern fn igGetColumnWidth(column_index: c_int) f32;
pub extern fn igSetColumnWidth(column_index: c_int, width: f32) void;
pub extern fn igGetColumnOffset(column_index: c_int) f32;
pub extern fn igSetColumnOffset(column_index: c_int, offset_x: f32) void;
pub extern fn igGetColumnsCount() c_int;
pub extern fn igBeginTabBar(str_id: [*c]const u8, flags: ImGuiTabBarFlags) bool;
pub extern fn igEndTabBar() void;
pub extern fn igBeginTabItem(label: [*c]const u8, p_open: [*c]bool, flags: ImGuiTabItemFlags) bool;
pub extern fn igEndTabItem() void;
pub extern fn igTabItemButton(label: [*c]const u8, flags: ImGuiTabItemFlags) bool;
pub extern fn igSetTabItemClosed(tab_or_docked_window_label: [*c]const u8) void;
pub extern fn igDockSpace(dockspace_id: ImGuiID) ImGuiID;
pub extern fn igDockSpaceEx(dockspace_id: ImGuiID, size: ImVec2, flags: ImGuiDockNodeFlags, window_class: [*c]const ImGuiWindowClass) ImGuiID;
pub extern fn igDockSpaceOverViewport() ImGuiID;
pub extern fn igDockSpaceOverViewportEx(dockspace_id: ImGuiID, viewport: [*c]const ImGuiViewport, flags: ImGuiDockNodeFlags, window_class: [*c]const ImGuiWindowClass) ImGuiID;
pub extern fn igSetNextWindowDockID(dock_id: ImGuiID, cond: ImGuiCond) void;
pub extern fn igSetNextWindowClass(window_class: [*c]const ImGuiWindowClass) void;
pub extern fn igGetWindowDockID() ImGuiID;
pub extern fn igIsWindowDocked() bool;
pub extern fn igLogToTTY(auto_open_depth: c_int) void;
pub extern fn igLogToFile(auto_open_depth: c_int, filename: [*c]const u8) void;
pub extern fn igLogToClipboard(auto_open_depth: c_int) void;
pub extern fn igLogFinish() void;
pub extern fn igLogButtons() void;
pub extern fn igLogText(fmt: [*c]const u8, ...) void;
pub extern fn igLogTextV(fmt: [*c]const u8, args: va_list) void;
pub extern fn igBeginDragDropSource(flags: ImGuiDragDropFlags) bool;
pub extern fn igSetDragDropPayload(@"type": [*c]const u8, data: ?*const anyopaque, sz: usize, cond: ImGuiCond) bool;
pub extern fn igEndDragDropSource() void;
pub extern fn igBeginDragDropTarget() bool;
pub extern fn igAcceptDragDropPayload(@"type": [*c]const u8, flags: ImGuiDragDropFlags) [*c]const ImGuiPayload;
pub extern fn igEndDragDropTarget() void;
pub extern fn igGetDragDropPayload() [*c]const ImGuiPayload;
pub extern fn igBeginDisabled(disabled: bool) void;
pub extern fn igEndDisabled() void;
pub extern fn igPushClipRect(clip_rect_min: ImVec2, clip_rect_max: ImVec2, intersect_with_current_clip_rect: bool) void;
pub extern fn igPopClipRect() void;
pub extern fn igSetItemDefaultFocus() void;
pub extern fn igSetKeyboardFocusHere() void;
pub extern fn igSetKeyboardFocusHereEx(offset: c_int) void;
pub extern fn igSetNavCursorVisible(visible: bool) void;
pub extern fn igSetNextItemAllowOverlap() void;
pub extern fn igIsItemHovered(flags: ImGuiHoveredFlags) bool;
pub extern fn igIsItemActive() bool;
pub extern fn igIsItemFocused() bool;
pub extern fn igIsItemClicked() bool;
pub extern fn igIsItemClickedEx(mouse_button: ImGuiMouseButton) bool;
pub extern fn igIsItemVisible() bool;
pub extern fn igIsItemEdited() bool;
pub extern fn igIsItemActivated() bool;
pub extern fn igIsItemDeactivated() bool;
pub extern fn igIsItemDeactivatedAfterEdit() bool;
pub extern fn igIsItemToggledOpen() bool;
pub extern fn igIsAnyItemHovered() bool;
pub extern fn igIsAnyItemActive() bool;
pub extern fn igIsAnyItemFocused() bool;
pub extern fn igGetItemID() ImGuiID;
pub extern fn igGetItemRectMin() ImVec2;
pub extern fn igGetItemRectMax() ImVec2;
pub extern fn igGetItemRectSize() ImVec2;
pub extern fn igGetItemFlags() ImGuiItemFlags;
pub extern fn igGetItemClickedCountWithSingleClickDelay() c_int;
pub extern fn igGetItemClickedCountWithSingleClickDelayEx(mouse_button: ImGuiMouseButton, delay: f32) c_int;
pub extern fn igGetMainViewport() [*c]ImGuiViewport;
pub extern fn igGetBackgroundDrawList() [*c]ImDrawList;
pub extern fn igGetBackgroundDrawListEx(viewport: [*c]ImGuiViewport) [*c]ImDrawList;
pub extern fn igGetForegroundDrawList() [*c]ImDrawList;
pub extern fn igGetForegroundDrawListEx(viewport: [*c]ImGuiViewport) [*c]ImDrawList;
pub extern fn igIsRectVisibleBySize(size: ImVec2) bool;
pub extern fn igIsRectVisible(rect_min: ImVec2, rect_max: ImVec2) bool;
pub extern fn igGetTime() f64;
pub extern fn igGetFrameCount() c_int;
pub extern fn igGetDrawListSharedData() ?*ImDrawListSharedData;
pub extern fn igGetStyleColorName(idx: ImGuiCol) [*c]const u8;
pub extern fn igSetStateStorage(storage: [*c]ImGuiStorage) void;
pub extern fn igGetStateStorage() [*c]ImGuiStorage;
pub extern fn igCalcTextSize(text: [*c]const u8) ImVec2;
pub extern fn igCalcTextSizeEx(text: [*c]const u8, text_end: [*c]const u8, hide_text_after_double_hash: bool, wrap_width: f32) ImVec2;
pub extern fn igColorConvertU32ToFloat4(in: ImU32) ImVec4;
pub extern fn igColorConvertFloat4ToU32(in: ImVec4) ImU32;
pub extern fn igColorConvertRGBtoHSV(r: f32, g: f32, b: f32, out_h: [*c]f32, out_s: [*c]f32, out_v: [*c]f32) void;
pub extern fn igColorConvertHSVtoRGB(h: f32, s: f32, v: f32, out_r: [*c]f32, out_g: [*c]f32, out_b: [*c]f32) void;
pub extern fn igIsKeyDown(key: ImGuiKey) bool;
pub extern fn igIsKeyPressed(key: ImGuiKey) bool;
pub extern fn igIsKeyPressedEx(key: ImGuiKey, repeat: bool) bool;
pub extern fn igIsKeyReleased(key: ImGuiKey) bool;
pub extern fn igIsKeyChordPressed(key_chord: ImGuiKeyChord) bool;
pub extern fn igGetKeyPressedAmount(key: ImGuiKey, repeat_delay: f32, rate: f32) c_int;
pub extern fn igGetKeyName(key: ImGuiKey) [*c]const u8;
pub extern fn igSetNextFrameWantCaptureKeyboard(want_capture_keyboard: bool) void;
pub extern fn igShortcut(key_chord: ImGuiKeyChord, flags: ImGuiInputFlags) bool;
pub extern fn igSetNextItemShortcut(key_chord: ImGuiKeyChord, flags: ImGuiInputFlags) void;
pub extern fn igSetItemKeyOwner(key: ImGuiKey) bool;
pub extern fn igIsMouseDown(button: ImGuiMouseButton) bool;
pub extern fn igIsMouseClicked(button: ImGuiMouseButton) bool;
pub extern fn igIsMouseClickedEx(button: ImGuiMouseButton, repeat: bool) bool;
pub extern fn igIsMouseReleased(button: ImGuiMouseButton) bool;
pub extern fn igIsMouseDoubleClicked(button: ImGuiMouseButton) bool;
pub extern fn igIsMouseReleasedWithDelay(button: ImGuiMouseButton) bool;
pub extern fn igIsMouseReleasedWithDelayEx(button: ImGuiMouseButton, delay: f32) bool;
pub extern fn igGetMouseClickedCount(button: ImGuiMouseButton) c_int;
pub extern fn igIsMouseHoveringRect(r_min: ImVec2, r_max: ImVec2) bool;
pub extern fn igIsMouseHoveringRectEx(r_min: ImVec2, r_max: ImVec2, clip: bool) bool;
pub extern fn igIsMousePosValid(mouse_pos: [*c]const ImVec2) bool;
pub extern fn igIsAnyMouseDown() bool;
pub extern fn igGetMousePos() ImVec2;
pub extern fn igGetMousePosOnOpeningCurrentPopup() ImVec2;
pub extern fn igIsMouseDragging(button: ImGuiMouseButton, lock_threshold: f32) bool;
pub extern fn igGetMouseDragDelta(button: ImGuiMouseButton, lock_threshold: f32) ImVec2;
pub extern fn igResetMouseDragDelta() void;
pub extern fn igResetMouseDragDeltaEx(button: ImGuiMouseButton) void;
pub extern fn igGetMouseCursor() ImGuiMouseCursor;
pub extern fn igSetMouseCursor(cursor_type: ImGuiMouseCursor) void;
pub extern fn igSetNextFrameWantCaptureMouse(want_capture_mouse: bool) void;
pub extern fn igGetClipboardText() [*c]const u8;
pub extern fn igSetClipboardText(text: [*c]const u8) void;
pub extern fn igLoadIniSettingsFromDisk(ini_filename: [*c]const u8) void;
pub extern fn igLoadIniSettingsFromMemory(ini_data: [*c]const u8, ini_size: usize) void;
pub extern fn igSaveIniSettingsToDisk(ini_filename: [*c]const u8) void;
pub extern fn igSaveIniSettingsToMemory(out_ini_size: [*c]usize) [*c]const u8;
pub extern fn igDebugTextEncoding(text: [*c]const u8) void;
pub extern fn igDebugFlashStyleColor(idx: ImGuiCol) void;
pub extern fn igDebugStartItemPicker() void;
pub extern fn igDebugCheckVersionAndDataLayout(version_str: [*c]const u8, sz_io: usize, sz_style: usize, sz_vec2: usize, sz_vec4: usize, sz_drawvert: usize, sz_drawidx: usize) bool;
pub extern fn igDebugLog(fmt: [*c]const u8, ...) void;
pub extern fn igDebugLogV(fmt: [*c]const u8, args: va_list) void;
pub extern fn igSetAllocatorFunctions(alloc_func: ImGuiMemAllocFunc, free_func: ImGuiMemFreeFunc, user_data: ?*anyopaque) void;
pub extern fn igGetAllocatorFunctions(p_alloc_func: [*c]ImGuiMemAllocFunc, p_free_func: [*c]ImGuiMemFreeFunc, p_user_data: [*c]?*anyopaque) void;
pub extern fn igMemAlloc(size: usize) ?*anyopaque;
pub extern fn igMemFree(ptr: ?*anyopaque) void;
pub extern fn igUpdatePlatformWindows() void;
pub extern fn igRenderPlatformWindowsDefault() void;
pub extern fn igRenderPlatformWindowsDefaultEx(platform_render_arg: ?*anyopaque, renderer_render_arg: ?*anyopaque) void;
pub extern fn igDestroyPlatformWindows() void;
pub extern fn igFindViewportByID(viewport_id: ImGuiID) [*c]ImGuiViewport;
pub extern fn igFindViewportByPlatformHandle(platform_handle: ?*anyopaque) [*c]ImGuiViewport;
pub const ImGuiWindowFlags_None: c_int = 0;
pub const ImGuiWindowFlags_NoTitleBar: c_int = 1;
pub const ImGuiWindowFlags_NoResize: c_int = 2;
pub const ImGuiWindowFlags_NoMove: c_int = 4;
pub const ImGuiWindowFlags_NoScrollbar: c_int = 8;
pub const ImGuiWindowFlags_NoScrollWithMouse: c_int = 16;
pub const ImGuiWindowFlags_NoCollapse: c_int = 32;
pub const ImGuiWindowFlags_AlwaysAutoResize: c_int = 64;
pub const ImGuiWindowFlags_NoBackground: c_int = 128;
pub const ImGuiWindowFlags_NoSavedSettings: c_int = 256;
pub const ImGuiWindowFlags_NoMouseInputs: c_int = 512;
pub const ImGuiWindowFlags_MenuBar: c_int = 1024;
pub const ImGuiWindowFlags_HorizontalScrollbar: c_int = 2048;
pub const ImGuiWindowFlags_NoFocusOnAppearing: c_int = 4096;
pub const ImGuiWindowFlags_NoBringToFrontOnFocus: c_int = 8192;
pub const ImGuiWindowFlags_AlwaysVerticalScrollbar: c_int = 16384;
pub const ImGuiWindowFlags_AlwaysHorizontalScrollbar: c_int = 32768;
pub const ImGuiWindowFlags_NoNavInputs: c_int = 65536;
pub const ImGuiWindowFlags_NoNavFocus: c_int = 131072;
pub const ImGuiWindowFlags_UnsavedDocument: c_int = 262144;
pub const ImGuiWindowFlags_NoDocking: c_int = 524288;
pub const ImGuiWindowFlags_NoNav: c_int = 196608;
pub const ImGuiWindowFlags_NoDecoration: c_int = 43;
pub const ImGuiWindowFlags_NoInputs: c_int = 197120;
pub const ImGuiWindowFlags_DockNodeHost: c_int = 8388608;
pub const ImGuiWindowFlags_ChildWindow: c_int = 16777216;
pub const ImGuiWindowFlags_Tooltip: c_int = 33554432;
pub const ImGuiWindowFlags_Popup: c_int = 67108864;
pub const ImGuiWindowFlags_Modal: c_int = 134217728;
pub const ImGuiWindowFlags_ChildMenu: c_int = 268435456;
pub const ImGuiWindowFlags_ = c_uint;
pub const ImGuiChildFlags_None: c_int = 0;
pub const ImGuiChildFlags_Borders: c_int = 1;
pub const ImGuiChildFlags_AlwaysUseWindowPadding: c_int = 2;
pub const ImGuiChildFlags_ResizeX: c_int = 4;
pub const ImGuiChildFlags_ResizeY: c_int = 8;
pub const ImGuiChildFlags_AutoResizeX: c_int = 16;
pub const ImGuiChildFlags_AutoResizeY: c_int = 32;
pub const ImGuiChildFlags_AlwaysAutoResize: c_int = 64;
pub const ImGuiChildFlags_FrameStyle: c_int = 128;
pub const ImGuiChildFlags_NavFlattened: c_int = 256;
pub const ImGuiChildFlags_ = c_uint;
pub const ImGuiItemFlags_None: c_int = 0;
pub const ImGuiItemFlags_NoTabStop: c_int = 1;
pub const ImGuiItemFlags_NoNav: c_int = 2;
pub const ImGuiItemFlags_NoNavDefaultFocus: c_int = 4;
pub const ImGuiItemFlags_ButtonRepeat: c_int = 8;
pub const ImGuiItemFlags_AutoClosePopups: c_int = 16;
pub const ImGuiItemFlags_AllowDuplicateId: c_int = 32;
pub const ImGuiItemFlags_Disabled: c_int = 64;
pub const ImGuiItemFlags_LiveEditOnInputText: c_int = 128;
pub const ImGuiItemFlags_LiveEditOnInputScalar: c_int = 256;
pub const ImGuiItemFlags_LiveEditOnInput: c_int = 384;
pub const ImGuiItemFlags_ = c_uint;
pub const ImGuiInputTextFlags_None: c_int = 0;
pub const ImGuiInputTextFlags_CharsDecimal: c_int = 1;
pub const ImGuiInputTextFlags_CharsHexadecimal: c_int = 2;
pub const ImGuiInputTextFlags_CharsScientific: c_int = 4;
pub const ImGuiInputTextFlags_CharsUppercase: c_int = 8;
pub const ImGuiInputTextFlags_CharsNoBlank: c_int = 16;
pub const ImGuiInputTextFlags_AllowTabInput: c_int = 32;
pub const ImGuiInputTextFlags_EnterReturnsTrue: c_int = 64;
pub const ImGuiInputTextFlags_EscapeClearsAll: c_int = 128;
pub const ImGuiInputTextFlags_CtrlEnterForNewLine: c_int = 256;
pub const ImGuiInputTextFlags_ReadOnly: c_int = 512;
pub const ImGuiInputTextFlags_Password: c_int = 1024;
pub const ImGuiInputTextFlags_AlwaysOverwrite: c_int = 2048;
pub const ImGuiInputTextFlags_AutoSelectAll: c_int = 4096;
pub const ImGuiInputTextFlags_ParseEmptyRefVal: c_int = 8192;
pub const ImGuiInputTextFlags_DisplayEmptyRefVal: c_int = 16384;
pub const ImGuiInputTextFlags_NoHorizontalScroll: c_int = 32768;
pub const ImGuiInputTextFlags_NoUndoRedo: c_int = 65536;
pub const ImGuiInputTextFlags_ElideLeft: c_int = 131072;
pub const ImGuiInputTextFlags_CallbackCompletion: c_int = 262144;
pub const ImGuiInputTextFlags_CallbackHistory: c_int = 524288;
pub const ImGuiInputTextFlags_CallbackAlways: c_int = 1048576;
pub const ImGuiInputTextFlags_CallbackCharFilter: c_int = 2097152;
pub const ImGuiInputTextFlags_CallbackResize: c_int = 4194304;
pub const ImGuiInputTextFlags_CallbackEdit: c_int = 8388608;
pub const ImGuiInputTextFlags_WordWrap: c_int = 16777216;
pub const ImGuiInputTextFlags_ = c_uint;
pub const ImGuiTreeNodeFlags_None: c_int = 0;
pub const ImGuiTreeNodeFlags_Selected: c_int = 1;
pub const ImGuiTreeNodeFlags_Framed: c_int = 2;
pub const ImGuiTreeNodeFlags_AllowOverlap: c_int = 4;
pub const ImGuiTreeNodeFlags_NoTreePushOnOpen: c_int = 8;
pub const ImGuiTreeNodeFlags_NoAutoOpenOnLog: c_int = 16;
pub const ImGuiTreeNodeFlags_DefaultOpen: c_int = 32;
pub const ImGuiTreeNodeFlags_OpenOnDoubleClick: c_int = 64;
pub const ImGuiTreeNodeFlags_OpenOnArrow: c_int = 128;
pub const ImGuiTreeNodeFlags_Leaf: c_int = 256;
pub const ImGuiTreeNodeFlags_Bullet: c_int = 512;
pub const ImGuiTreeNodeFlags_FramePadding: c_int = 1024;
pub const ImGuiTreeNodeFlags_SpanAvailWidth: c_int = 2048;
pub const ImGuiTreeNodeFlags_SpanFullWidth: c_int = 4096;
pub const ImGuiTreeNodeFlags_SpanLabelWidth: c_int = 8192;
pub const ImGuiTreeNodeFlags_SpanAllColumns: c_int = 16384;
pub const ImGuiTreeNodeFlags_LabelSpanAllColumns: c_int = 32768;
pub const ImGuiTreeNodeFlags_NavLeftJumpsToParent: c_int = 131072;
pub const ImGuiTreeNodeFlags_CollapsingHeader: c_int = 26;
pub const ImGuiTreeNodeFlags_DrawLinesNone: c_int = 262144;
pub const ImGuiTreeNodeFlags_DrawLinesFull: c_int = 524288;
pub const ImGuiTreeNodeFlags_DrawLinesToNodes: c_int = 1048576;
pub const ImGuiTreeNodeFlags_NavLeftJumpsBackHere: c_int = 131072;
pub const ImGuiTreeNodeFlags_ = c_uint;
pub const ImGuiPopupFlags_None: c_int = 0;
pub const ImGuiPopupFlags_MouseButtonLeft: c_int = 4;
pub const ImGuiPopupFlags_MouseButtonRight: c_int = 8;
pub const ImGuiPopupFlags_MouseButtonMiddle: c_int = 12;
pub const ImGuiPopupFlags_NoReopen: c_int = 32;
pub const ImGuiPopupFlags_NoOpenOverExistingPopup: c_int = 128;
pub const ImGuiPopupFlags_NoOpenOverItems: c_int = 256;
pub const ImGuiPopupFlags_AnyPopupId: c_int = 1024;
pub const ImGuiPopupFlags_AnyPopupLevel: c_int = 2048;
pub const ImGuiPopupFlags_AnyPopup: c_int = 3072;
pub const ImGuiPopupFlags_MouseButtonShift_: c_int = 2;
pub const ImGuiPopupFlags_MouseButtonMask_: c_int = 12;
pub const ImGuiPopupFlags_InvalidMask_: c_int = 3;
pub const ImGuiPopupFlags_ = c_uint;
pub const ImGuiSelectableFlags_None: c_int = 0;
pub const ImGuiSelectableFlags_NoAutoClosePopups: c_int = 1;
pub const ImGuiSelectableFlags_SpanAllColumns: c_int = 2;
pub const ImGuiSelectableFlags_AllowDoubleClick: c_int = 4;
pub const ImGuiSelectableFlags_Disabled: c_int = 8;
pub const ImGuiSelectableFlags_AllowOverlap: c_int = 16;
pub const ImGuiSelectableFlags_Highlight: c_int = 32;
pub const ImGuiSelectableFlags_SelectOnNav: c_int = 64;
pub const ImGuiSelectableFlags_DontClosePopups: c_int = 1;
pub const ImGuiSelectableFlags_ = c_uint;
pub const ImGuiComboFlags_None: c_int = 0;
pub const ImGuiComboFlags_PopupAlignLeft: c_int = 1;
pub const ImGuiComboFlags_HeightSmall: c_int = 2;
pub const ImGuiComboFlags_HeightRegular: c_int = 4;
pub const ImGuiComboFlags_HeightLarge: c_int = 8;
pub const ImGuiComboFlags_HeightLargest: c_int = 16;
pub const ImGuiComboFlags_NoArrowButton: c_int = 32;
pub const ImGuiComboFlags_NoPreview: c_int = 64;
pub const ImGuiComboFlags_WidthFitPreview: c_int = 128;
pub const ImGuiComboFlags_HeightMask_: c_int = 30;
pub const ImGuiComboFlags_ = c_uint;
pub const ImGuiTabBarFlags_None: c_int = 0;
pub const ImGuiTabBarFlags_Reorderable: c_int = 1;
pub const ImGuiTabBarFlags_AutoSelectNewTabs: c_int = 2;
pub const ImGuiTabBarFlags_TabListPopupButton: c_int = 4;
pub const ImGuiTabBarFlags_NoCloseWithMiddleMouseButton: c_int = 8;
pub const ImGuiTabBarFlags_NoTabListScrollingButtons: c_int = 16;
pub const ImGuiTabBarFlags_NoTooltip: c_int = 32;
pub const ImGuiTabBarFlags_DrawSelectedOverline: c_int = 64;
pub const ImGuiTabBarFlags_FittingPolicyMixed: c_int = 128;
pub const ImGuiTabBarFlags_FittingPolicyShrink: c_int = 256;
pub const ImGuiTabBarFlags_FittingPolicyScroll: c_int = 512;
pub const ImGuiTabBarFlags_FittingPolicyMask_: c_int = 896;
pub const ImGuiTabBarFlags_FittingPolicyDefault_: c_int = 128;
pub const ImGuiTabBarFlags_FittingPolicyResizeDown: c_int = 256;
pub const ImGuiTabBarFlags_ = c_uint;
pub const ImGuiTabItemFlags_None: c_int = 0;
pub const ImGuiTabItemFlags_UnsavedDocument: c_int = 1;
pub const ImGuiTabItemFlags_SetSelected: c_int = 2;
pub const ImGuiTabItemFlags_NoCloseWithMiddleMouseButton: c_int = 4;
pub const ImGuiTabItemFlags_NoPushId: c_int = 8;
pub const ImGuiTabItemFlags_NoTooltip: c_int = 16;
pub const ImGuiTabItemFlags_NoReorder: c_int = 32;
pub const ImGuiTabItemFlags_Leading: c_int = 64;
pub const ImGuiTabItemFlags_Trailing: c_int = 128;
pub const ImGuiTabItemFlags_NoAssumedClosure: c_int = 256;
pub const ImGuiTabItemFlags_ = c_uint;
pub const ImGuiFocusedFlags_None: c_int = 0;
pub const ImGuiFocusedFlags_ChildWindows: c_int = 1;
pub const ImGuiFocusedFlags_RootWindow: c_int = 2;
pub const ImGuiFocusedFlags_AnyWindow: c_int = 4;
pub const ImGuiFocusedFlags_NoPopupHierarchy: c_int = 8;
pub const ImGuiFocusedFlags_DockHierarchy: c_int = 16;
pub const ImGuiFocusedFlags_RootAndChildWindows: c_int = 3;
pub const ImGuiFocusedFlags_ = c_uint;
pub const ImGuiHoveredFlags_None: c_int = 0;
pub const ImGuiHoveredFlags_ChildWindows: c_int = 1;
pub const ImGuiHoveredFlags_RootWindow: c_int = 2;
pub const ImGuiHoveredFlags_AnyWindow: c_int = 4;
pub const ImGuiHoveredFlags_NoPopupHierarchy: c_int = 8;
pub const ImGuiHoveredFlags_DockHierarchy: c_int = 16;
pub const ImGuiHoveredFlags_AllowWhenBlockedByPopup: c_int = 32;
pub const ImGuiHoveredFlags_AllowWhenBlockedByActiveItem: c_int = 128;
pub const ImGuiHoveredFlags_AllowWhenOverlappedByItem: c_int = 256;
pub const ImGuiHoveredFlags_AllowWhenOverlappedByWindow: c_int = 512;
pub const ImGuiHoveredFlags_AllowWhenDisabled: c_int = 1024;
pub const ImGuiHoveredFlags_NoNavOverride: c_int = 2048;
pub const ImGuiHoveredFlags_AllowWhenOverlapped: c_int = 768;
pub const ImGuiHoveredFlags_RectOnly: c_int = 928;
pub const ImGuiHoveredFlags_RootAndChildWindows: c_int = 3;
pub const ImGuiHoveredFlags_ForTooltip: c_int = 4096;
pub const ImGuiHoveredFlags_Stationary: c_int = 8192;
pub const ImGuiHoveredFlags_DelayNone: c_int = 16384;
pub const ImGuiHoveredFlags_DelayShort: c_int = 32768;
pub const ImGuiHoveredFlags_DelayNormal: c_int = 65536;
pub const ImGuiHoveredFlags_NoSharedDelay: c_int = 131072;
pub const ImGuiHoveredFlags_ = c_uint;
pub const ImGuiDockNodeFlags_None: c_int = 0;
pub const ImGuiDockNodeFlags_KeepAliveOnly: c_int = 1;
pub const ImGuiDockNodeFlags_NoDockingOverCentralNode: c_int = 4;
pub const ImGuiDockNodeFlags_PassthruCentralNode: c_int = 8;
pub const ImGuiDockNodeFlags_NoDockingSplit: c_int = 16;
pub const ImGuiDockNodeFlags_NoResize: c_int = 32;
pub const ImGuiDockNodeFlags_AutoHideTabBar: c_int = 64;
pub const ImGuiDockNodeFlags_NoUndocking: c_int = 128;
pub const ImGuiDockNodeFlags_NoSplit: c_int = 16;
pub const ImGuiDockNodeFlags_NoDockingInCentralNode: c_int = 4;
pub const ImGuiDockNodeFlags_ = c_uint;
pub const ImGuiDragDropFlags_None: c_int = 0;
pub const ImGuiDragDropFlags_SourceNoPreviewTooltip: c_int = 1;
pub const ImGuiDragDropFlags_SourceNoDisableHover: c_int = 2;
pub const ImGuiDragDropFlags_SourceNoHoldToOpenOthers: c_int = 4;
pub const ImGuiDragDropFlags_SourceAllowNullID: c_int = 8;
pub const ImGuiDragDropFlags_SourceExtern: c_int = 16;
pub const ImGuiDragDropFlags_PayloadAutoExpire: c_int = 32;
pub const ImGuiDragDropFlags_PayloadNoCrossContext: c_int = 64;
pub const ImGuiDragDropFlags_PayloadNoCrossProcess: c_int = 128;
pub const ImGuiDragDropFlags_AcceptBeforeDelivery: c_int = 1024;
pub const ImGuiDragDropFlags_AcceptNoDrawDefaultRect: c_int = 2048;
pub const ImGuiDragDropFlags_AcceptNoPreviewTooltip: c_int = 4096;
pub const ImGuiDragDropFlags_AcceptDrawAsHovered: c_int = 8192;
pub const ImGuiDragDropFlags_AcceptPeekOnly: c_int = 3072;
pub const ImGuiDragDropFlags_ = c_uint;
pub const ImGuiDataType_S8: c_int = 0;
pub const ImGuiDataType_U8: c_int = 1;
pub const ImGuiDataType_S16: c_int = 2;
pub const ImGuiDataType_U16: c_int = 3;
pub const ImGuiDataType_S32: c_int = 4;
pub const ImGuiDataType_U32: c_int = 5;
pub const ImGuiDataType_S64: c_int = 6;
pub const ImGuiDataType_U64: c_int = 7;
pub const ImGuiDataType_Float: c_int = 8;
pub const ImGuiDataType_Double: c_int = 9;
pub const ImGuiDataType_Bool: c_int = 10;
pub const ImGuiDataType_String: c_int = 11;
pub const ImGuiDataType_COUNT: c_int = 12;
pub const ImGuiDataType_ = c_uint;
pub const ImGuiDir_None: c_int = -1;
pub const ImGuiDir_Left: c_int = 0;
pub const ImGuiDir_Right: c_int = 1;
pub const ImGuiDir_Up: c_int = 2;
pub const ImGuiDir_Down: c_int = 3;
pub const ImGuiDir_COUNT: c_int = 4;
const enum_unnamed_3 = c_int;
pub const ImGuiSortDirection_None: c_int = 0;
pub const ImGuiSortDirection_Ascending: c_int = 1;
pub const ImGuiSortDirection_Descending: c_int = 2;
const enum_unnamed_4 = c_uint;
pub const ImGuiKey_None: c_int = 0;
pub const ImGuiKey_NamedKey_BEGIN: c_int = 512;
pub const ImGuiKey_Tab: c_int = 512;
pub const ImGuiKey_LeftArrow: c_int = 513;
pub const ImGuiKey_RightArrow: c_int = 514;
pub const ImGuiKey_UpArrow: c_int = 515;
pub const ImGuiKey_DownArrow: c_int = 516;
pub const ImGuiKey_PageUp: c_int = 517;
pub const ImGuiKey_PageDown: c_int = 518;
pub const ImGuiKey_Home: c_int = 519;
pub const ImGuiKey_End: c_int = 520;
pub const ImGuiKey_Insert: c_int = 521;
pub const ImGuiKey_Delete: c_int = 522;
pub const ImGuiKey_Backspace: c_int = 523;
pub const ImGuiKey_Space: c_int = 524;
pub const ImGuiKey_Enter: c_int = 525;
pub const ImGuiKey_Escape: c_int = 526;
pub const ImGuiKey_LeftCtrl: c_int = 527;
pub const ImGuiKey_LeftShift: c_int = 528;
pub const ImGuiKey_LeftAlt: c_int = 529;
pub const ImGuiKey_LeftSuper: c_int = 530;
pub const ImGuiKey_RightCtrl: c_int = 531;
pub const ImGuiKey_RightShift: c_int = 532;
pub const ImGuiKey_RightAlt: c_int = 533;
pub const ImGuiKey_RightSuper: c_int = 534;
pub const ImGuiKey_Menu: c_int = 535;
pub const ImGuiKey_0: c_int = 536;
pub const ImGuiKey_1: c_int = 537;
pub const ImGuiKey_2: c_int = 538;
pub const ImGuiKey_3: c_int = 539;
pub const ImGuiKey_4: c_int = 540;
pub const ImGuiKey_5: c_int = 541;
pub const ImGuiKey_6: c_int = 542;
pub const ImGuiKey_7: c_int = 543;
pub const ImGuiKey_8: c_int = 544;
pub const ImGuiKey_9: c_int = 545;
pub const ImGuiKey_A: c_int = 546;
pub const ImGuiKey_B: c_int = 547;
pub const ImGuiKey_C: c_int = 548;
pub const ImGuiKey_D: c_int = 549;
pub const ImGuiKey_E: c_int = 550;
pub const ImGuiKey_F: c_int = 551;
pub const ImGuiKey_G: c_int = 552;
pub const ImGuiKey_H: c_int = 553;
pub const ImGuiKey_I: c_int = 554;
pub const ImGuiKey_J: c_int = 555;
pub const ImGuiKey_K: c_int = 556;
pub const ImGuiKey_L: c_int = 557;
pub const ImGuiKey_M: c_int = 558;
pub const ImGuiKey_N: c_int = 559;
pub const ImGuiKey_O: c_int = 560;
pub const ImGuiKey_P: c_int = 561;
pub const ImGuiKey_Q: c_int = 562;
pub const ImGuiKey_R: c_int = 563;
pub const ImGuiKey_S: c_int = 564;
pub const ImGuiKey_T: c_int = 565;
pub const ImGuiKey_U: c_int = 566;
pub const ImGuiKey_V: c_int = 567;
pub const ImGuiKey_W: c_int = 568;
pub const ImGuiKey_X: c_int = 569;
pub const ImGuiKey_Y: c_int = 570;
pub const ImGuiKey_Z: c_int = 571;
pub const ImGuiKey_F1: c_int = 572;
pub const ImGuiKey_F2: c_int = 573;
pub const ImGuiKey_F3: c_int = 574;
pub const ImGuiKey_F4: c_int = 575;
pub const ImGuiKey_F5: c_int = 576;
pub const ImGuiKey_F6: c_int = 577;
pub const ImGuiKey_F7: c_int = 578;
pub const ImGuiKey_F8: c_int = 579;
pub const ImGuiKey_F9: c_int = 580;
pub const ImGuiKey_F10: c_int = 581;
pub const ImGuiKey_F11: c_int = 582;
pub const ImGuiKey_F12: c_int = 583;
pub const ImGuiKey_F13: c_int = 584;
pub const ImGuiKey_F14: c_int = 585;
pub const ImGuiKey_F15: c_int = 586;
pub const ImGuiKey_F16: c_int = 587;
pub const ImGuiKey_F17: c_int = 588;
pub const ImGuiKey_F18: c_int = 589;
pub const ImGuiKey_F19: c_int = 590;
pub const ImGuiKey_F20: c_int = 591;
pub const ImGuiKey_F21: c_int = 592;
pub const ImGuiKey_F22: c_int = 593;
pub const ImGuiKey_F23: c_int = 594;
pub const ImGuiKey_F24: c_int = 595;
pub const ImGuiKey_Apostrophe: c_int = 596;
pub const ImGuiKey_Comma: c_int = 597;
pub const ImGuiKey_Minus: c_int = 598;
pub const ImGuiKey_Period: c_int = 599;
pub const ImGuiKey_Slash: c_int = 600;
pub const ImGuiKey_Semicolon: c_int = 601;
pub const ImGuiKey_Equal: c_int = 602;
pub const ImGuiKey_LeftBracket: c_int = 603;
pub const ImGuiKey_Backslash: c_int = 604;
pub const ImGuiKey_RightBracket: c_int = 605;
pub const ImGuiKey_GraveAccent: c_int = 606;
pub const ImGuiKey_CapsLock: c_int = 607;
pub const ImGuiKey_ScrollLock: c_int = 608;
pub const ImGuiKey_NumLock: c_int = 609;
pub const ImGuiKey_PrintScreen: c_int = 610;
pub const ImGuiKey_Pause: c_int = 611;
pub const ImGuiKey_Keypad0: c_int = 612;
pub const ImGuiKey_Keypad1: c_int = 613;
pub const ImGuiKey_Keypad2: c_int = 614;
pub const ImGuiKey_Keypad3: c_int = 615;
pub const ImGuiKey_Keypad4: c_int = 616;
pub const ImGuiKey_Keypad5: c_int = 617;
pub const ImGuiKey_Keypad6: c_int = 618;
pub const ImGuiKey_Keypad7: c_int = 619;
pub const ImGuiKey_Keypad8: c_int = 620;
pub const ImGuiKey_Keypad9: c_int = 621;
pub const ImGuiKey_KeypadDecimal: c_int = 622;
pub const ImGuiKey_KeypadDivide: c_int = 623;
pub const ImGuiKey_KeypadMultiply: c_int = 624;
pub const ImGuiKey_KeypadSubtract: c_int = 625;
pub const ImGuiKey_KeypadAdd: c_int = 626;
pub const ImGuiKey_KeypadEnter: c_int = 627;
pub const ImGuiKey_KeypadEqual: c_int = 628;
pub const ImGuiKey_AppBack: c_int = 629;
pub const ImGuiKey_AppForward: c_int = 630;
pub const ImGuiKey_Oem102: c_int = 631;
pub const ImGuiKey_GamepadStart: c_int = 632;
pub const ImGuiKey_GamepadBack: c_int = 633;
pub const ImGuiKey_GamepadFaceLeft: c_int = 634;
pub const ImGuiKey_GamepadFaceRight: c_int = 635;
pub const ImGuiKey_GamepadFaceUp: c_int = 636;
pub const ImGuiKey_GamepadFaceDown: c_int = 637;
pub const ImGuiKey_GamepadDpadLeft: c_int = 638;
pub const ImGuiKey_GamepadDpadRight: c_int = 639;
pub const ImGuiKey_GamepadDpadUp: c_int = 640;
pub const ImGuiKey_GamepadDpadDown: c_int = 641;
pub const ImGuiKey_GamepadL1: c_int = 642;
pub const ImGuiKey_GamepadR1: c_int = 643;
pub const ImGuiKey_GamepadL2: c_int = 644;
pub const ImGuiKey_GamepadR2: c_int = 645;
pub const ImGuiKey_GamepadL3: c_int = 646;
pub const ImGuiKey_GamepadR3: c_int = 647;
pub const ImGuiKey_GamepadLStickLeft: c_int = 648;
pub const ImGuiKey_GamepadLStickRight: c_int = 649;
pub const ImGuiKey_GamepadLStickUp: c_int = 650;
pub const ImGuiKey_GamepadLStickDown: c_int = 651;
pub const ImGuiKey_GamepadRStickLeft: c_int = 652;
pub const ImGuiKey_GamepadRStickRight: c_int = 653;
pub const ImGuiKey_GamepadRStickUp: c_int = 654;
pub const ImGuiKey_GamepadRStickDown: c_int = 655;
pub const ImGuiKey_MouseLeft: c_int = 656;
pub const ImGuiKey_MouseRight: c_int = 657;
pub const ImGuiKey_MouseMiddle: c_int = 658;
pub const ImGuiKey_MouseX1: c_int = 659;
pub const ImGuiKey_MouseX2: c_int = 660;
pub const ImGuiKey_MouseWheelX: c_int = 661;
pub const ImGuiKey_MouseWheelY: c_int = 662;
pub const ImGuiKey_ReservedForModCtrl: c_int = 663;
pub const ImGuiKey_ReservedForModShift: c_int = 664;
pub const ImGuiKey_ReservedForModAlt: c_int = 665;
pub const ImGuiKey_ReservedForModSuper: c_int = 666;
pub const ImGuiKey_NamedKey_END: c_int = 667;
pub const ImGuiKey_NamedKey_COUNT: c_int = 155;
pub const ImGuiMod_None: c_int = 0;
pub const ImGuiMod_Ctrl: c_int = 4096;
pub const ImGuiMod_Shift: c_int = 8192;
pub const ImGuiMod_Alt: c_int = 16384;
pub const ImGuiMod_Super: c_int = 32768;
pub const ImGuiMod_Mask_: c_int = 61440;
pub const ImGuiKey_COUNT: c_int = 667;
pub const ImGuiMod_Shortcut: c_int = 4096;
const enum_unnamed_5 = c_uint;
pub const ImGuiInputFlags_None: c_int = 0;
pub const ImGuiInputFlags_Repeat: c_int = 1;
pub const ImGuiInputFlags_RouteActive: c_int = 1024;
pub const ImGuiInputFlags_RouteFocused: c_int = 2048;
pub const ImGuiInputFlags_RouteGlobal: c_int = 4096;
pub const ImGuiInputFlags_RouteAlways: c_int = 8192;
pub const ImGuiInputFlags_RouteOverFocused: c_int = 16384;
pub const ImGuiInputFlags_RouteOverActive: c_int = 32768;
pub const ImGuiInputFlags_RouteUnlessBgFocused: c_int = 65536;
pub const ImGuiInputFlags_RouteFromRootWindow: c_int = 131072;
pub const ImGuiInputFlags_Tooltip: c_int = 262144;
pub const ImGuiInputFlags_ = c_uint;
pub const ImGuiConfigFlags_None: c_int = 0;
pub const ImGuiConfigFlags_NavEnableKeyboard: c_int = 1;
pub const ImGuiConfigFlags_NavEnableGamepad: c_int = 2;
pub const ImGuiConfigFlags_NoMouse: c_int = 16;
pub const ImGuiConfigFlags_NoMouseCursorChange: c_int = 32;
pub const ImGuiConfigFlags_NoKeyboard: c_int = 64;
pub const ImGuiConfigFlags_DockingEnable: c_int = 128;
pub const ImGuiConfigFlags_ViewportsEnable: c_int = 1024;
pub const ImGuiConfigFlags_IsSRGB: c_int = 1048576;
pub const ImGuiConfigFlags_IsTouchScreen: c_int = 2097152;
pub const ImGuiConfigFlags_NavEnableSetMousePos: c_int = 4;
pub const ImGuiConfigFlags_NavNoCaptureKeyboard: c_int = 8;
pub const ImGuiConfigFlags_DpiEnableScaleFonts: c_int = 16384;
pub const ImGuiConfigFlags_DpiEnableScaleViewports: c_int = 32768;
pub const ImGuiConfigFlags_ = c_uint;
pub const ImGuiBackendFlags_None: c_int = 0;
pub const ImGuiBackendFlags_HasGamepad: c_int = 1;
pub const ImGuiBackendFlags_HasMouseCursors: c_int = 2;
pub const ImGuiBackendFlags_HasSetMousePos: c_int = 4;
pub const ImGuiBackendFlags_RendererHasVtxOffset: c_int = 8;
pub const ImGuiBackendFlags_RendererHasTextures: c_int = 16;
pub const ImGuiBackendFlags_RendererHasViewports: c_int = 1024;
pub const ImGuiBackendFlags_PlatformHasViewports: c_int = 2048;
pub const ImGuiBackendFlags_HasMouseHoveredViewport: c_int = 4096;
pub const ImGuiBackendFlags_HasParentViewport: c_int = 8192;
pub const ImGuiBackendFlags_ = c_uint;
pub const ImGuiCol_Text: c_int = 0;
pub const ImGuiCol_TextDisabled: c_int = 1;
pub const ImGuiCol_WindowBg: c_int = 2;
pub const ImGuiCol_ChildBg: c_int = 3;
pub const ImGuiCol_PopupBg: c_int = 4;
pub const ImGuiCol_Border: c_int = 5;
pub const ImGuiCol_BorderShadow: c_int = 6;
pub const ImGuiCol_FrameBg: c_int = 7;
pub const ImGuiCol_FrameBgHovered: c_int = 8;
pub const ImGuiCol_FrameBgActive: c_int = 9;
pub const ImGuiCol_TitleBg: c_int = 10;
pub const ImGuiCol_TitleBgActive: c_int = 11;
pub const ImGuiCol_TitleBgCollapsed: c_int = 12;
pub const ImGuiCol_MenuBarBg: c_int = 13;
pub const ImGuiCol_ScrollbarBg: c_int = 14;
pub const ImGuiCol_ScrollbarGrab: c_int = 15;
pub const ImGuiCol_ScrollbarGrabHovered: c_int = 16;
pub const ImGuiCol_ScrollbarGrabActive: c_int = 17;
pub const ImGuiCol_CheckMark: c_int = 18;
pub const ImGuiCol_CheckboxSelectedBg: c_int = 19;
pub const ImGuiCol_SliderGrab: c_int = 20;
pub const ImGuiCol_SliderGrabActive: c_int = 21;
pub const ImGuiCol_Button: c_int = 22;
pub const ImGuiCol_ButtonHovered: c_int = 23;
pub const ImGuiCol_ButtonActive: c_int = 24;
pub const ImGuiCol_Header: c_int = 25;
pub const ImGuiCol_HeaderHovered: c_int = 26;
pub const ImGuiCol_HeaderActive: c_int = 27;
pub const ImGuiCol_Separator: c_int = 28;
pub const ImGuiCol_SeparatorHovered: c_int = 29;
pub const ImGuiCol_SeparatorActive: c_int = 30;
pub const ImGuiCol_ResizeGrip: c_int = 31;
pub const ImGuiCol_ResizeGripHovered: c_int = 32;
pub const ImGuiCol_ResizeGripActive: c_int = 33;
pub const ImGuiCol_InputTextCursor: c_int = 34;
pub const ImGuiCol_TabHovered: c_int = 35;
pub const ImGuiCol_Tab: c_int = 36;
pub const ImGuiCol_TabSelected: c_int = 37;
pub const ImGuiCol_TabSelectedOverline: c_int = 38;
pub const ImGuiCol_TabDimmed: c_int = 39;
pub const ImGuiCol_TabDimmedSelected: c_int = 40;
pub const ImGuiCol_TabDimmedSelectedOverline: c_int = 41;
pub const ImGuiCol_DockingPreview: c_int = 42;
pub const ImGuiCol_DockingEmptyBg: c_int = 43;
pub const ImGuiCol_PlotLines: c_int = 44;
pub const ImGuiCol_PlotLinesHovered: c_int = 45;
pub const ImGuiCol_PlotHistogram: c_int = 46;
pub const ImGuiCol_PlotHistogramHovered: c_int = 47;
pub const ImGuiCol_TableHeaderBg: c_int = 48;
pub const ImGuiCol_TableBorderStrong: c_int = 49;
pub const ImGuiCol_TableBorderLight: c_int = 50;
pub const ImGuiCol_TableRowBg: c_int = 51;
pub const ImGuiCol_TableRowBgAlt: c_int = 52;
pub const ImGuiCol_TextLink: c_int = 53;
pub const ImGuiCol_TextSelectedBg: c_int = 54;
pub const ImGuiCol_TreeLines: c_int = 55;
pub const ImGuiCol_DragDropTarget: c_int = 56;
pub const ImGuiCol_DragDropTargetBg: c_int = 57;
pub const ImGuiCol_UnsavedMarker: c_int = 58;
pub const ImGuiCol_NavCursor: c_int = 59;
pub const ImGuiCol_NavWindowingHighlight: c_int = 60;
pub const ImGuiCol_NavWindowingDimBg: c_int = 61;
pub const ImGuiCol_ModalWindowDimBg: c_int = 62;
pub const ImGuiCol_COUNT: c_int = 63;
pub const ImGuiCol_TabActive: c_int = 37;
pub const ImGuiCol_TabUnfocused: c_int = 39;
pub const ImGuiCol_TabUnfocusedActive: c_int = 40;
pub const ImGuiCol_NavHighlight: c_int = 59;
pub const ImGuiCol_ = c_uint;
pub const ImGuiStyleVar_Alpha: c_int = 0;
pub const ImGuiStyleVar_DisabledAlpha: c_int = 1;
pub const ImGuiStyleVar_WindowPadding: c_int = 2;
pub const ImGuiStyleVar_WindowRounding: c_int = 3;
pub const ImGuiStyleVar_WindowBorderSize: c_int = 4;
pub const ImGuiStyleVar_WindowMinSize: c_int = 5;
pub const ImGuiStyleVar_WindowTitleAlign: c_int = 6;
pub const ImGuiStyleVar_ChildRounding: c_int = 7;
pub const ImGuiStyleVar_ChildBorderSize: c_int = 8;
pub const ImGuiStyleVar_PopupRounding: c_int = 9;
pub const ImGuiStyleVar_PopupBorderSize: c_int = 10;
pub const ImGuiStyleVar_FramePadding: c_int = 11;
pub const ImGuiStyleVar_FrameRounding: c_int = 12;
pub const ImGuiStyleVar_FrameBorderSize: c_int = 13;
pub const ImGuiStyleVar_ItemSpacing: c_int = 14;
pub const ImGuiStyleVar_ItemInnerSpacing: c_int = 15;
pub const ImGuiStyleVar_IndentSpacing: c_int = 16;
pub const ImGuiStyleVar_CellPadding: c_int = 17;
pub const ImGuiStyleVar_ScrollbarSize: c_int = 18;
pub const ImGuiStyleVar_ScrollbarRounding: c_int = 19;
pub const ImGuiStyleVar_ScrollbarPadding: c_int = 20;
pub const ImGuiStyleVar_GrabMinSize: c_int = 21;
pub const ImGuiStyleVar_GrabRounding: c_int = 22;
pub const ImGuiStyleVar_ImageRounding: c_int = 23;
pub const ImGuiStyleVar_ImageBorderSize: c_int = 24;
pub const ImGuiStyleVar_TabRounding: c_int = 25;
pub const ImGuiStyleVar_TabBorderSize: c_int = 26;
pub const ImGuiStyleVar_TabMinWidthBase: c_int = 27;
pub const ImGuiStyleVar_TabMinWidthShrink: c_int = 28;
pub const ImGuiStyleVar_TabBarBorderSize: c_int = 29;
pub const ImGuiStyleVar_TabBarOverlineSize: c_int = 30;
pub const ImGuiStyleVar_TableAngledHeadersAngle: c_int = 31;
pub const ImGuiStyleVar_TableAngledHeadersTextAlign: c_int = 32;
pub const ImGuiStyleVar_TreeLinesSize: c_int = 33;
pub const ImGuiStyleVar_TreeLinesRounding: c_int = 34;
pub const ImGuiStyleVar_MenuItemRounding: c_int = 35;
pub const ImGuiStyleVar_SelectableRounding: c_int = 36;
pub const ImGuiStyleVar_DragDropTargetRounding: c_int = 37;
pub const ImGuiStyleVar_ButtonTextAlign: c_int = 38;
pub const ImGuiStyleVar_SelectableTextAlign: c_int = 39;
pub const ImGuiStyleVar_SeparatorSize: c_int = 40;
pub const ImGuiStyleVar_SeparatorTextBorderSize: c_int = 41;
pub const ImGuiStyleVar_SeparatorTextAlign: c_int = 42;
pub const ImGuiStyleVar_SeparatorTextPadding: c_int = 43;
pub const ImGuiStyleVar_DockingSeparatorSize: c_int = 44;
pub const ImGuiStyleVar_COUNT: c_int = 45;
pub const ImGuiStyleVar_ = c_uint;
pub const ImGuiButtonFlags_None: c_int = 0;
pub const ImGuiButtonFlags_MouseButtonLeft: c_int = 1;
pub const ImGuiButtonFlags_MouseButtonRight: c_int = 2;
pub const ImGuiButtonFlags_MouseButtonMiddle: c_int = 4;
pub const ImGuiButtonFlags_MouseButtonMask_: c_int = 7;
pub const ImGuiButtonFlags_EnableNav: c_int = 8;
pub const ImGuiButtonFlags_AllowOverlap: c_int = 4096;
pub const ImGuiButtonFlags_ = c_uint;
pub const ImGuiColorEditFlags_None: c_int = 0;
pub const ImGuiColorEditFlags_NoAlpha: c_int = 2;
pub const ImGuiColorEditFlags_NoPicker: c_int = 4;
pub const ImGuiColorEditFlags_NoOptions: c_int = 8;
pub const ImGuiColorEditFlags_NoSmallPreview: c_int = 16;
pub const ImGuiColorEditFlags_NoInputs: c_int = 32;
pub const ImGuiColorEditFlags_NoTooltip: c_int = 64;
pub const ImGuiColorEditFlags_NoLabel: c_int = 128;
pub const ImGuiColorEditFlags_NoSidePreview: c_int = 256;
pub const ImGuiColorEditFlags_NoDragDrop: c_int = 512;
pub const ImGuiColorEditFlags_NoBorder: c_int = 1024;
pub const ImGuiColorEditFlags_NoColorMarkers: c_int = 2048;
pub const ImGuiColorEditFlags_AlphaOpaque: c_int = 4096;
pub const ImGuiColorEditFlags_AlphaNoBg: c_int = 8192;
pub const ImGuiColorEditFlags_AlphaPreviewHalf: c_int = 16384;
pub const ImGuiColorEditFlags_AlphaBar: c_int = 262144;
pub const ImGuiColorEditFlags_HDR: c_int = 524288;
pub const ImGuiColorEditFlags_DisplayRGB: c_int = 1048576;
pub const ImGuiColorEditFlags_DisplayHSV: c_int = 2097152;
pub const ImGuiColorEditFlags_DisplayHex: c_int = 4194304;
pub const ImGuiColorEditFlags_Uint8: c_int = 8388608;
pub const ImGuiColorEditFlags_Float: c_int = 16777216;
pub const ImGuiColorEditFlags_PickerHueBar: c_int = 33554432;
pub const ImGuiColorEditFlags_PickerHueWheel: c_int = 67108864;
pub const ImGuiColorEditFlags_PickerNoRotate: c_int = 134217728;
pub const ImGuiColorEditFlags_InputRGB: c_int = 268435456;
pub const ImGuiColorEditFlags_InputHSV: c_int = 536870912;
pub const ImGuiColorEditFlags_DefaultOptions_: c_int = 311427072;
pub const ImGuiColorEditFlags_AlphaMask_: c_int = 28674;
pub const ImGuiColorEditFlags_DisplayMask_: c_int = 7340032;
pub const ImGuiColorEditFlags_DataTypeMask_: c_int = 25165824;
pub const ImGuiColorEditFlags_PickerMask_: c_int = 100663296;
pub const ImGuiColorEditFlags_InputMask_: c_int = 805306368;
pub const ImGuiColorEditFlags_AlphaPreview: c_int = 0;
pub const ImGuiColorEditFlags_ = c_uint;
pub const ImGuiSliderFlags_None: c_int = 0;
pub const ImGuiSliderFlags_Logarithmic: c_int = 32;
pub const ImGuiSliderFlags_NoRoundToFormat: c_int = 64;
pub const ImGuiSliderFlags_NoInput: c_int = 128;
pub const ImGuiSliderFlags_WrapAround: c_int = 256;
pub const ImGuiSliderFlags_ClampOnInput: c_int = 512;
pub const ImGuiSliderFlags_ClampZeroRange: c_int = 1024;
pub const ImGuiSliderFlags_NoSpeedTweaks: c_int = 2048;
pub const ImGuiSliderFlags_ColorMarkers: c_int = 4096;
pub const ImGuiSliderFlags_AlwaysClamp: c_int = 1536;
pub const ImGuiSliderFlags_InvalidMask_: c_int = 1879048207;
pub const ImGuiSliderFlags_ = c_uint;
pub const ImGuiMouseButton_Left: c_int = 0;
pub const ImGuiMouseButton_Right: c_int = 1;
pub const ImGuiMouseButton_Middle: c_int = 2;
pub const ImGuiMouseButton_COUNT: c_int = 5;
pub const ImGuiMouseButton_ = c_uint;
pub const ImGuiMouseCursor_None: c_int = -1;
pub const ImGuiMouseCursor_Arrow: c_int = 0;
pub const ImGuiMouseCursor_TextInput: c_int = 1;
pub const ImGuiMouseCursor_ResizeAll: c_int = 2;
pub const ImGuiMouseCursor_ResizeNS: c_int = 3;
pub const ImGuiMouseCursor_ResizeEW: c_int = 4;
pub const ImGuiMouseCursor_ResizeNESW: c_int = 5;
pub const ImGuiMouseCursor_ResizeNWSE: c_int = 6;
pub const ImGuiMouseCursor_Hand: c_int = 7;
pub const ImGuiMouseCursor_Wait: c_int = 8;
pub const ImGuiMouseCursor_Progress: c_int = 9;
pub const ImGuiMouseCursor_NotAllowed: c_int = 10;
pub const ImGuiMouseCursor_COUNT: c_int = 11;
pub const ImGuiMouseCursor_ = c_int;
pub const ImGuiMouseSource_Mouse: c_int = 0;
pub const ImGuiMouseSource_TouchScreen: c_int = 1;
pub const ImGuiMouseSource_Pen: c_int = 2;
pub const ImGuiMouseSource_COUNT: c_int = 3;
const enum_unnamed_6 = c_uint;
pub const ImGuiCond_None: c_int = 0;
pub const ImGuiCond_Always: c_int = 1;
pub const ImGuiCond_Once: c_int = 2;
pub const ImGuiCond_FirstUseEver: c_int = 4;
pub const ImGuiCond_Appearing: c_int = 8;
pub const ImGuiCond_ = c_uint;
pub const ImGuiTableFlags_None: c_int = 0;
pub const ImGuiTableFlags_Resizable: c_int = 1;
pub const ImGuiTableFlags_Reorderable: c_int = 2;
pub const ImGuiTableFlags_Hideable: c_int = 4;
pub const ImGuiTableFlags_Sortable: c_int = 8;
pub const ImGuiTableFlags_NoSavedSettings: c_int = 16;
pub const ImGuiTableFlags_ContextMenuInBody: c_int = 32;
pub const ImGuiTableFlags_RowBg: c_int = 64;
pub const ImGuiTableFlags_BordersInnerH: c_int = 128;
pub const ImGuiTableFlags_BordersOuterH: c_int = 256;
pub const ImGuiTableFlags_BordersInnerV: c_int = 512;
pub const ImGuiTableFlags_BordersOuterV: c_int = 1024;
pub const ImGuiTableFlags_BordersH: c_int = 384;
pub const ImGuiTableFlags_BordersV: c_int = 1536;
pub const ImGuiTableFlags_BordersInner: c_int = 640;
pub const ImGuiTableFlags_BordersOuter: c_int = 1280;
pub const ImGuiTableFlags_Borders: c_int = 1920;
pub const ImGuiTableFlags_NoBordersInBody: c_int = 2048;
pub const ImGuiTableFlags_NoBordersInBodyUntilResize: c_int = 4096;
pub const ImGuiTableFlags_SizingFixedFit: c_int = 8192;
pub const ImGuiTableFlags_SizingFixedSame: c_int = 16384;
pub const ImGuiTableFlags_SizingStretchProp: c_int = 24576;
pub const ImGuiTableFlags_SizingStretchSame: c_int = 32768;
pub const ImGuiTableFlags_NoHostExtendX: c_int = 65536;
pub const ImGuiTableFlags_NoHostExtendY: c_int = 131072;
pub const ImGuiTableFlags_NoKeepColumnsVisible: c_int = 262144;
pub const ImGuiTableFlags_PreciseWidths: c_int = 524288;
pub const ImGuiTableFlags_NoClip: c_int = 1048576;
pub const ImGuiTableFlags_PadOuterX: c_int = 2097152;
pub const ImGuiTableFlags_NoPadOuterX: c_int = 4194304;
pub const ImGuiTableFlags_NoPadInnerX: c_int = 8388608;
pub const ImGuiTableFlags_ScrollX: c_int = 16777216;
pub const ImGuiTableFlags_ScrollY: c_int = 33554432;
pub const ImGuiTableFlags_SortMulti: c_int = 67108864;
pub const ImGuiTableFlags_SortTristate: c_int = 134217728;
pub const ImGuiTableFlags_HighlightHoveredColumn: c_int = 268435456;
pub const ImGuiTableFlags_SizingMask_: c_int = 57344;
pub const ImGuiTableFlags_ = c_uint;
pub const ImGuiTableColumnFlags_None: c_int = 0;
pub const ImGuiTableColumnFlags_Disabled: c_int = 1;
pub const ImGuiTableColumnFlags_DefaultHide: c_int = 2;
pub const ImGuiTableColumnFlags_DefaultSort: c_int = 4;
pub const ImGuiTableColumnFlags_WidthStretch: c_int = 8;
pub const ImGuiTableColumnFlags_WidthFixed: c_int = 16;
pub const ImGuiTableColumnFlags_NoResize: c_int = 32;
pub const ImGuiTableColumnFlags_NoReorder: c_int = 64;
pub const ImGuiTableColumnFlags_NoHide: c_int = 128;
pub const ImGuiTableColumnFlags_NoClip: c_int = 256;
pub const ImGuiTableColumnFlags_NoSort: c_int = 512;
pub const ImGuiTableColumnFlags_NoSortAscending: c_int = 1024;
pub const ImGuiTableColumnFlags_NoSortDescending: c_int = 2048;
pub const ImGuiTableColumnFlags_NoHeaderLabel: c_int = 4096;
pub const ImGuiTableColumnFlags_NoHeaderWidth: c_int = 8192;
pub const ImGuiTableColumnFlags_PreferSortAscending: c_int = 16384;
pub const ImGuiTableColumnFlags_PreferSortDescending: c_int = 32768;
pub const ImGuiTableColumnFlags_IndentEnable: c_int = 65536;
pub const ImGuiTableColumnFlags_IndentDisable: c_int = 131072;
pub const ImGuiTableColumnFlags_AngledHeader: c_int = 262144;
pub const ImGuiTableColumnFlags_IsEnabled: c_int = 16777216;
pub const ImGuiTableColumnFlags_IsVisible: c_int = 33554432;
pub const ImGuiTableColumnFlags_IsSorted: c_int = 67108864;
pub const ImGuiTableColumnFlags_IsHovered: c_int = 134217728;
pub const ImGuiTableColumnFlags_WidthMask_: c_int = 24;
pub const ImGuiTableColumnFlags_IndentMask_: c_int = 196608;
pub const ImGuiTableColumnFlags_StatusMask_: c_int = 251658240;
pub const ImGuiTableColumnFlags_NoDirectResize_: c_int = 1073741824;
pub const ImGuiTableColumnFlags_ = c_uint;
pub const ImGuiTableRowFlags_None: c_int = 0;
pub const ImGuiTableRowFlags_Headers: c_int = 1;
pub const ImGuiTableRowFlags_ = c_uint;
pub const ImGuiTableBgTarget_None: c_int = 0;
pub const ImGuiTableBgTarget_RowBg0: c_int = 1;
pub const ImGuiTableBgTarget_RowBg1: c_int = 2;
pub const ImGuiTableBgTarget_CellBg: c_int = 3;
pub const ImGuiTableBgTarget_ = c_uint;
pub extern fn ImVector_Construct(vector: ?*anyopaque) void;
pub extern fn ImVector_Destruct(vector: ?*anyopaque) void;
pub extern fn ImGuiPlatformIO_SetPlatform_GetWindowWorkAreaInsets(getWindowWorkAreaInsetsFunc: ?*const fn (vp: [*c]ImGuiViewport, result: [*c]ImVec4) callconv(.c) void) void;
pub extern fn ImGuiPlatformIO_SetPlatform_GetWindowFramebufferScale(getWindowFramebufferScaleFunc: ?*const fn (vp: [*c]ImGuiViewport, result: [*c]ImVec2) callconv(.c) void) void;
pub extern fn ImGuiPlatformIO_SetPlatform_GetWindowPos(getWindowPosFunc: ?*const fn (vp: [*c]ImGuiViewport, result: [*c]ImVec2) callconv(.c) void) void;
pub extern fn ImGuiPlatformIO_SetPlatform_GetWindowSize(getWindowSizeFunc: ?*const fn (vp: [*c]ImGuiViewport, result: [*c]ImVec2) callconv(.c) void) void;
pub extern fn ImGuiStyle_ScaleAllSizes(self: [*c]ImGuiStyle, scale_factor: f32) void;
pub extern fn ImGuiIO_AddKeyEvent(self: [*c]ImGuiIO, key: ImGuiKey, down: bool) void;
pub extern fn ImGuiIO_AddKeyAnalogEvent(self: [*c]ImGuiIO, key: ImGuiKey, down: bool, v: f32) void;
pub extern fn ImGuiIO_AddMousePosEvent(self: [*c]ImGuiIO, x: f32, y: f32) void;
pub extern fn ImGuiIO_AddMouseButtonEvent(self: [*c]ImGuiIO, button: c_int, down: bool) void;
pub extern fn ImGuiIO_AddMouseWheelEvent(self: [*c]ImGuiIO, wheel_x: f32, wheel_y: f32) void;
pub extern fn ImGuiIO_AddMouseSourceEvent(self: [*c]ImGuiIO, source: ImGuiMouseSource) void;
pub extern fn ImGuiIO_AddMouseViewportEvent(self: [*c]ImGuiIO, id: ImGuiID) void;
pub extern fn ImGuiIO_AddFocusEvent(self: [*c]ImGuiIO, focused: bool) void;
pub extern fn ImGuiIO_AddInputCharacter(self: [*c]ImGuiIO, c: c_uint) void;
pub extern fn ImGuiIO_AddInputCharacterUTF16(self: [*c]ImGuiIO, c: ImWchar16) void;
pub extern fn ImGuiIO_AddInputCharactersUTF8(self: [*c]ImGuiIO, str: [*c]const u8) void;
pub extern fn ImGuiIO_SetKeyEventNativeData(self: [*c]ImGuiIO, key: ImGuiKey, native_keycode: c_int, native_scancode: c_int) void;
pub extern fn ImGuiIO_SetKeyEventNativeDataEx(self: [*c]ImGuiIO, key: ImGuiKey, native_keycode: c_int, native_scancode: c_int, native_legacy_index: c_int) void;
pub extern fn ImGuiIO_SetAppAcceptingEvents(self: [*c]ImGuiIO, accepting_events: bool) void;
pub extern fn ImGuiIO_ClearEventsQueue(self: [*c]ImGuiIO) void;
pub extern fn ImGuiIO_ClearInputKeys(self: [*c]ImGuiIO) void;
pub extern fn ImGuiIO_ClearInputMouse(self: [*c]ImGuiIO) void;
pub extern fn ImGuiInputTextCallbackData_DeleteChars(self: [*c]ImGuiInputTextCallbackData, pos: c_int, bytes_count: c_int) void;
pub extern fn ImGuiInputTextCallbackData_InsertChars(self: [*c]ImGuiInputTextCallbackData, pos: c_int, text: [*c]const u8, text_end: [*c]const u8) void;
pub extern fn ImGuiInputTextCallbackData_SelectAll(self: [*c]ImGuiInputTextCallbackData) void;
pub extern fn ImGuiInputTextCallbackData_SetSelection(self: [*c]ImGuiInputTextCallbackData, s: c_int, e: c_int) void;
pub extern fn ImGuiInputTextCallbackData_ClearSelection(self: [*c]ImGuiInputTextCallbackData) void;
pub extern fn ImGuiInputTextCallbackData_HasSelection(self: [*c]const ImGuiInputTextCallbackData) bool;
pub extern fn ImGuiPayload_Clear(self: [*c]ImGuiPayload) void;
pub extern fn ImGuiPayload_IsDataType(self: [*c]const ImGuiPayload, @"type": [*c]const u8) bool;
pub extern fn ImGuiPayload_IsPreview(self: [*c]const ImGuiPayload) bool;
pub extern fn ImGuiPayload_IsDelivery(self: [*c]const ImGuiPayload) bool;
pub extern fn ImGuiTextFilter_ImGuiTextRange_empty(self: [*c]const ImGuiTextFilter_ImGuiTextRange) bool;
pub extern fn ImGuiTextFilter_ImGuiTextRange_split(self: [*c]const ImGuiTextFilter_ImGuiTextRange, separator: u8, out: [*c]ImVector_ImGuiTextRange) void;
pub extern fn ImGuiTextFilter_Draw(self: [*c]ImGuiTextFilter, label: [*c]const u8, width: f32) bool;
pub extern fn ImGuiTextFilter_PassFilter(self: [*c]const ImGuiTextFilter, text: [*c]const u8, text_end: [*c]const u8) bool;
pub extern fn ImGuiTextFilter_Build(self: [*c]ImGuiTextFilter) void;
pub extern fn ImGuiTextFilter_Clear(self: [*c]ImGuiTextFilter) void;
pub extern fn ImGuiTextFilter_IsActive(self: [*c]const ImGuiTextFilter) bool;
pub extern fn ImGuiTextBuffer_begin(self: [*c]const ImGuiTextBuffer) [*c]const u8;
pub extern fn ImGuiTextBuffer_end(self: [*c]const ImGuiTextBuffer) [*c]const u8;
pub extern fn ImGuiTextBuffer_size(self: [*c]const ImGuiTextBuffer) c_int;
pub extern fn ImGuiTextBuffer_empty(self: [*c]const ImGuiTextBuffer) bool;
pub extern fn ImGuiTextBuffer_clear(self: [*c]ImGuiTextBuffer) void;
pub extern fn ImGuiTextBuffer_resize(self: [*c]ImGuiTextBuffer, size: c_int) void;
pub extern fn ImGuiTextBuffer_reserve(self: [*c]ImGuiTextBuffer, capacity: c_int) void;
pub extern fn ImGuiTextBuffer_c_str(self: [*c]const ImGuiTextBuffer) [*c]const u8;
pub extern fn ImGuiTextBuffer_append(self: [*c]ImGuiTextBuffer, str: [*c]const u8, str_end: [*c]const u8) void;
pub extern fn ImGuiTextBuffer_appendf(self: [*c]ImGuiTextBuffer, fmt: [*c]const u8, ...) void;
pub extern fn ImGuiTextBuffer_appendfv(self: [*c]ImGuiTextBuffer, fmt: [*c]const u8, args: va_list) void;
pub extern fn ImGuiStorage_Clear(self: [*c]ImGuiStorage) void;
pub extern fn ImGuiStorage_GetInt(self: [*c]const ImGuiStorage, key: ImGuiID, default_val: c_int) c_int;
pub extern fn ImGuiStorage_SetInt(self: [*c]ImGuiStorage, key: ImGuiID, val: c_int) void;
pub extern fn ImGuiStorage_GetBool(self: [*c]const ImGuiStorage, key: ImGuiID, default_val: bool) bool;
pub extern fn ImGuiStorage_SetBool(self: [*c]ImGuiStorage, key: ImGuiID, val: bool) void;
pub extern fn ImGuiStorage_GetFloat(self: [*c]const ImGuiStorage, key: ImGuiID, default_val: f32) f32;
pub extern fn ImGuiStorage_SetFloat(self: [*c]ImGuiStorage, key: ImGuiID, val: f32) void;
pub extern fn ImGuiStorage_GetVoidPtr(self: [*c]const ImGuiStorage, key: ImGuiID) ?*anyopaque;
pub extern fn ImGuiStorage_SetVoidPtr(self: [*c]ImGuiStorage, key: ImGuiID, val: ?*anyopaque) void;
pub extern fn ImGuiStorage_GetIntRef(self: [*c]ImGuiStorage, key: ImGuiID, default_val: c_int) [*c]c_int;
pub extern fn ImGuiStorage_GetBoolRef(self: [*c]ImGuiStorage, key: ImGuiID, default_val: bool) [*c]bool;
pub extern fn ImGuiStorage_GetFloatRef(self: [*c]ImGuiStorage, key: ImGuiID, default_val: f32) [*c]f32;
pub extern fn ImGuiStorage_GetVoidPtrRef(self: [*c]ImGuiStorage, key: ImGuiID, default_val: ?*anyopaque) [*c]?*anyopaque;
pub extern fn ImGuiStorage_BuildSortByKey(self: [*c]ImGuiStorage) void;
pub extern fn ImGuiStorage_SetAllInt(self: [*c]ImGuiStorage, val: c_int) void;
pub const ImGuiListClipperFlags_None: c_int = 0;
pub const ImGuiListClipperFlags_NoSetTableRowCounters: c_int = 1;
pub const ImGuiListClipperFlags_ = c_uint;
pub extern fn ImGuiListClipper_Begin(self: [*c]ImGuiListClipper, items_count: c_int, items_height: f32) void;
pub extern fn ImGuiListClipper_End(self: [*c]ImGuiListClipper) void;
pub extern fn ImGuiListClipper_Step(self: [*c]ImGuiListClipper) bool;
pub extern fn ImGuiListClipper_IncludeItemByIndex(self: [*c]ImGuiListClipper, item_index: c_int) void;
pub extern fn ImGuiListClipper_IncludeItemsByIndex(self: [*c]ImGuiListClipper, item_begin: c_int, item_end: c_int) void;
pub extern fn ImGuiListClipper_SeekCursorForItem(self: [*c]ImGuiListClipper, item_index: c_int) void;
pub extern fn ImColor_SetHSV(self: [*c]ImColor, h: f32, s: f32, v: f32, a: f32) void;
pub extern fn ImColor_HSV(h: f32, s: f32, v: f32, a: f32) ImColor;
pub const ImGuiMultiSelectFlags_None: c_int = 0;
pub const ImGuiMultiSelectFlags_SingleSelect: c_int = 1;
pub const ImGuiMultiSelectFlags_NoSelectAll: c_int = 2;
pub const ImGuiMultiSelectFlags_NoRangeSelect: c_int = 4;
pub const ImGuiMultiSelectFlags_NoAutoSelect: c_int = 8;
pub const ImGuiMultiSelectFlags_NoAutoClear: c_int = 16;
pub const ImGuiMultiSelectFlags_NoAutoClearOnReselect: c_int = 32;
pub const ImGuiMultiSelectFlags_BoxSelect1d: c_int = 64;
pub const ImGuiMultiSelectFlags_BoxSelect2d: c_int = 128;
pub const ImGuiMultiSelectFlags_BoxSelectNoScroll: c_int = 256;
pub const ImGuiMultiSelectFlags_ClearOnEscape: c_int = 512;
pub const ImGuiMultiSelectFlags_ClearOnClickVoid: c_int = 1024;
pub const ImGuiMultiSelectFlags_ScopeWindow: c_int = 2048;
pub const ImGuiMultiSelectFlags_ScopeRect: c_int = 4096;
pub const ImGuiMultiSelectFlags_SelectOnAuto: c_int = 8192;
pub const ImGuiMultiSelectFlags_SelectOnClickAlways: c_int = 16384;
pub const ImGuiMultiSelectFlags_SelectOnClickRelease: c_int = 32768;
pub const ImGuiMultiSelectFlags_NavWrapX: c_int = 65536;
pub const ImGuiMultiSelectFlags_NoSelectOnRightClick: c_int = 131072;
pub const ImGuiMultiSelectFlags_SelectOnMask_: c_int = 57344;
pub const ImGuiMultiSelectFlags_CheckboxMode_: c_int = 1048576;
pub const ImGuiMultiSelectFlags_SelectOnClick: c_int = 8192;
pub const ImGuiMultiSelectFlags_ = c_uint;
pub const ImGuiSelectionRequestType_None: c_int = 0;
pub const ImGuiSelectionRequestType_SetAll: c_int = 1;
pub const ImGuiSelectionRequestType_SetRange: c_int = 2;
pub const ImGuiSelectionRequestType = c_uint;
pub extern fn ImGuiSelectionBasicStorage_ApplyRequests(self: [*c]ImGuiSelectionBasicStorage, ms_io: [*c]ImGuiMultiSelectIO) void;
pub extern fn ImGuiSelectionBasicStorage_Contains(self: [*c]const ImGuiSelectionBasicStorage, id: ImGuiID) bool;
pub extern fn ImGuiSelectionBasicStorage_Clear(self: [*c]ImGuiSelectionBasicStorage) void;
pub extern fn ImGuiSelectionBasicStorage_Swap(self: [*c]ImGuiSelectionBasicStorage, r: [*c]ImGuiSelectionBasicStorage) void;
pub extern fn ImGuiSelectionBasicStorage_SetItemSelected(self: [*c]ImGuiSelectionBasicStorage, id: ImGuiID, selected: bool) void;
pub extern fn ImGuiSelectionBasicStorage_GetNextSelectedItem(self: [*c]ImGuiSelectionBasicStorage, opaque_it: [*c]?*anyopaque, out_id: [*c]ImGuiID) bool;
pub extern fn ImGuiSelectionBasicStorage_GetStorageIdFromIndex(self: [*c]ImGuiSelectionBasicStorage, idx: c_int) ImGuiID;
pub extern fn ImGuiSelectionExternalStorage_ApplyRequests(self: [*c]ImGuiSelectionExternalStorage, ms_io: [*c]ImGuiMultiSelectIO) void;
pub extern fn ImDrawCmd_GetTexID(self: [*c]const ImDrawCmd) ImTextureID;
pub extern fn ImDrawListSplitter_Clear(self: [*c]ImDrawListSplitter) void;
pub extern fn ImDrawListSplitter_ClearFreeMemory(self: [*c]ImDrawListSplitter) void;
pub extern fn ImDrawListSplitter_Split(self: [*c]ImDrawListSplitter, draw_list: [*c]ImDrawList, count: c_int) void;
pub extern fn ImDrawListSplitter_Merge(self: [*c]ImDrawListSplitter, draw_list: [*c]ImDrawList) void;
pub extern fn ImDrawListSplitter_SetCurrentChannel(self: [*c]ImDrawListSplitter, draw_list: [*c]ImDrawList, channel_idx: c_int) void;
pub const ImDrawFlags_None: c_int = 0;
pub const ImDrawFlags_RoundCornersTopLeft: c_int = 16;
pub const ImDrawFlags_RoundCornersTopRight: c_int = 32;
pub const ImDrawFlags_RoundCornersBottomLeft: c_int = 64;
pub const ImDrawFlags_RoundCornersBottomRight: c_int = 128;
pub const ImDrawFlags_RoundCornersNone: c_int = 256;
pub const ImDrawFlags_RoundCornersAll: c_int = 240;
pub const ImDrawFlags_RoundCornersDefault_: c_int = 240;
pub const ImDrawFlags_RoundCornersTop: c_int = 48;
pub const ImDrawFlags_RoundCornersBottom: c_int = 192;
pub const ImDrawFlags_RoundCornersLeft: c_int = 80;
pub const ImDrawFlags_RoundCornersRight: c_int = 160;
pub const ImDrawFlags_RoundCornersMask_: c_int = 496;
pub const ImDrawFlags_Closed: c_int = 512;
pub const ImDrawFlags_InvalidMask_: c_int = -2147483633;
pub const ImDrawFlags_ = c_int;
pub const ImDrawListFlags_None: c_int = 0;
pub const ImDrawListFlags_AntiAliasedLines: c_int = 1;
pub const ImDrawListFlags_AntiAliasedLinesUseTex: c_int = 2;
pub const ImDrawListFlags_AntiAliasedFill: c_int = 4;
pub const ImDrawListFlags_AllowVtxOffset: c_int = 8;
pub const ImDrawListFlags_TextNoPixelSnap: c_int = 16;
pub const ImDrawListFlags_ = c_uint;
pub extern fn ImDrawList_PushClipRect(self: [*c]ImDrawList, clip_rect_min: ImVec2, clip_rect_max: ImVec2, intersect_with_current_clip_rect: bool) void;
pub extern fn ImDrawList_PushClipRectFullScreen(self: [*c]ImDrawList) void;
pub extern fn ImDrawList_PopClipRect(self: [*c]ImDrawList) void;
pub extern fn ImDrawList_PushTexture(self: [*c]ImDrawList, tex_ref: ImTextureRef) void;
pub extern fn ImDrawList_PopTexture(self: [*c]ImDrawList) void;
pub extern fn ImDrawList_GetClipRectMin(self: [*c]const ImDrawList) ImVec2;
pub extern fn ImDrawList_GetClipRectMax(self: [*c]const ImDrawList) ImVec2;
pub extern fn ImDrawList_AddLine(self: [*c]ImDrawList, p1: ImVec2, p2: ImVec2, col: ImU32) void;
pub extern fn ImDrawList_AddLineEx(self: [*c]ImDrawList, p1: ImVec2, p2: ImVec2, col: ImU32, thickness: f32) void;
pub extern fn ImDrawList_AddLineH(self: [*c]ImDrawList, min_x: f32, max_x: f32, y: f32, col: ImU32) void;
pub extern fn ImDrawList_AddLineHEx(self: [*c]ImDrawList, min_x: f32, max_x: f32, y: f32, col: ImU32, thickness: f32) void;
pub extern fn ImDrawList_AddLineV(self: [*c]ImDrawList, x: f32, min_y: f32, max_y: f32, col: ImU32) void;
pub extern fn ImDrawList_AddLineVEx(self: [*c]ImDrawList, x: f32, min_y: f32, max_y: f32, col: ImU32, thickness: f32) void;
pub extern fn ImDrawList_AddRect(self: [*c]ImDrawList, p_min: ImVec2, p_max: ImVec2, col: ImU32) void;
pub extern fn ImDrawList_AddRectEx(self: [*c]ImDrawList, p_min: ImVec2, p_max: ImVec2, col: ImU32, rounding: f32, thickness: f32, flags: ImDrawFlags) void;
pub extern fn ImDrawList_AddRectFilled(self: [*c]ImDrawList, p_min: ImVec2, p_max: ImVec2, col: ImU32) void;
pub extern fn ImDrawList_AddRectFilledEx(self: [*c]ImDrawList, p_min: ImVec2, p_max: ImVec2, col: ImU32, rounding: f32, flags: ImDrawFlags) void;
pub extern fn ImDrawList_AddRectFilledMultiColor(self: [*c]ImDrawList, p_min: ImVec2, p_max: ImVec2, col_upr_left: ImU32, col_upr_right: ImU32, col_bot_right: ImU32, col_bot_left: ImU32) void;
pub extern fn ImDrawList_AddQuad(self: [*c]ImDrawList, p1: ImVec2, p2: ImVec2, p3: ImVec2, p4: ImVec2, col: ImU32) void;
pub extern fn ImDrawList_AddQuadEx(self: [*c]ImDrawList, p1: ImVec2, p2: ImVec2, p3: ImVec2, p4: ImVec2, col: ImU32, thickness: f32) void;
pub extern fn ImDrawList_AddQuadFilled(self: [*c]ImDrawList, p1: ImVec2, p2: ImVec2, p3: ImVec2, p4: ImVec2, col: ImU32) void;
pub extern fn ImDrawList_AddTriangle(self: [*c]ImDrawList, p1: ImVec2, p2: ImVec2, p3: ImVec2, col: ImU32) void;
pub extern fn ImDrawList_AddTriangleEx(self: [*c]ImDrawList, p1: ImVec2, p2: ImVec2, p3: ImVec2, col: ImU32, thickness: f32) void;
pub extern fn ImDrawList_AddTriangleFilled(self: [*c]ImDrawList, p1: ImVec2, p2: ImVec2, p3: ImVec2, col: ImU32) void;
pub extern fn ImDrawList_AddCircle(self: [*c]ImDrawList, center: ImVec2, radius: f32, col: ImU32) void;
pub extern fn ImDrawList_AddCircleEx(self: [*c]ImDrawList, center: ImVec2, radius: f32, col: ImU32, num_segments: c_int, thickness: f32) void;
pub extern fn ImDrawList_AddCircleFilled(self: [*c]ImDrawList, center: ImVec2, radius: f32, col: ImU32, num_segments: c_int) void;
pub extern fn ImDrawList_AddNgon(self: [*c]ImDrawList, center: ImVec2, radius: f32, col: ImU32, num_segments: c_int) void;
pub extern fn ImDrawList_AddNgonEx(self: [*c]ImDrawList, center: ImVec2, radius: f32, col: ImU32, num_segments: c_int, thickness: f32) void;
pub extern fn ImDrawList_AddNgonFilled(self: [*c]ImDrawList, center: ImVec2, radius: f32, col: ImU32, num_segments: c_int) void;
pub extern fn ImDrawList_AddEllipse(self: [*c]ImDrawList, center: ImVec2, radius: ImVec2, col: ImU32) void;
pub extern fn ImDrawList_AddEllipseEx(self: [*c]ImDrawList, center: ImVec2, radius: ImVec2, col: ImU32, rot: f32, num_segments: c_int, thickness: f32) void;
pub extern fn ImDrawList_AddEllipseFilled(self: [*c]ImDrawList, center: ImVec2, radius: ImVec2, col: ImU32) void;
pub extern fn ImDrawList_AddEllipseFilledEx(self: [*c]ImDrawList, center: ImVec2, radius: ImVec2, col: ImU32, rot: f32, num_segments: c_int) void;
pub extern fn ImDrawList_AddText(self: [*c]ImDrawList, pos: ImVec2, col: ImU32, text_begin: [*c]const u8) void;
pub extern fn ImDrawList_AddTextEx(self: [*c]ImDrawList, pos: ImVec2, col: ImU32, text_begin: [*c]const u8, text_end: [*c]const u8) void;
pub extern fn ImDrawList_AddTextImFontPtr(self: [*c]ImDrawList, font: [*c]ImFont, font_size: f32, pos: ImVec2, col: ImU32, text_begin: [*c]const u8) void;
pub extern fn ImDrawList_AddTextImFontPtrEx(self: [*c]ImDrawList, font: [*c]ImFont, font_size: f32, pos: ImVec2, col: ImU32, text_begin: [*c]const u8, text_end: [*c]const u8, wrap_width: f32, cpu_fine_clip_rect: [*c]const ImVec4) void;
pub extern fn ImDrawList_AddBezierCubic(self: [*c]ImDrawList, p1: ImVec2, p2: ImVec2, p3: ImVec2, p4: ImVec2, col: ImU32, thickness: f32, num_segments: c_int) void;
pub extern fn ImDrawList_AddBezierQuadratic(self: [*c]ImDrawList, p1: ImVec2, p2: ImVec2, p3: ImVec2, col: ImU32, thickness: f32, num_segments: c_int) void;
pub extern fn ImDrawList_AddPolyline(self: [*c]ImDrawList, points: [*c]const ImVec2, num_points: c_int, col: ImU32, thickness: f32, flags: ImDrawFlags) void;
pub extern fn ImDrawList_AddConvexPolyFilled(self: [*c]ImDrawList, points: [*c]const ImVec2, num_points: c_int, col: ImU32) void;
pub extern fn ImDrawList_AddConcavePolyFilled(self: [*c]ImDrawList, points: [*c]const ImVec2, num_points: c_int, col: ImU32) void;
pub extern fn ImDrawList_AddImage(self: [*c]ImDrawList, tex_ref: ImTextureRef, p_min: ImVec2, p_max: ImVec2) void;
pub extern fn ImDrawList_AddImageEx(self: [*c]ImDrawList, tex_ref: ImTextureRef, p_min: ImVec2, p_max: ImVec2, uv_min: ImVec2, uv_max: ImVec2, col: ImU32) void;
pub extern fn ImDrawList_AddImageQuad(self: [*c]ImDrawList, tex_ref: ImTextureRef, p1: ImVec2, p2: ImVec2, p3: ImVec2, p4: ImVec2) void;
pub extern fn ImDrawList_AddImageQuadEx(self: [*c]ImDrawList, tex_ref: ImTextureRef, p1: ImVec2, p2: ImVec2, p3: ImVec2, p4: ImVec2, uv1: ImVec2, uv2: ImVec2, uv3: ImVec2, uv4: ImVec2, col: ImU32) void;
pub extern fn ImDrawList_AddImageRounded(self: [*c]ImDrawList, tex_ref: ImTextureRef, p_min: ImVec2, p_max: ImVec2, uv_min: ImVec2, uv_max: ImVec2, col: ImU32, rounding: f32, flags: ImDrawFlags) void;
pub extern fn ImDrawList_PathClear(self: [*c]ImDrawList) void;
pub extern fn ImDrawList_PathLineTo(self: [*c]ImDrawList, pos: ImVec2) void;
pub extern fn ImDrawList_PathLineToMergeDuplicate(self: [*c]ImDrawList, pos: ImVec2) void;
pub extern fn ImDrawList_PathFillConvex(self: [*c]ImDrawList, col: ImU32) void;
pub extern fn ImDrawList_PathFillConcave(self: [*c]ImDrawList, col: ImU32) void;
pub extern fn ImDrawList_PathStroke(self: [*c]ImDrawList, col: ImU32, thickness: f32, flags: ImDrawFlags) void;
pub extern fn ImDrawList_PathArcTo(self: [*c]ImDrawList, center: ImVec2, radius: f32, a_min: f32, a_max: f32, num_segments: c_int) void;
pub extern fn ImDrawList_PathArcToFast(self: [*c]ImDrawList, center: ImVec2, radius: f32, a_min_of_12: c_int, a_max_of_12: c_int) void;
pub extern fn ImDrawList_PathEllipticalArcTo(self: [*c]ImDrawList, center: ImVec2, radius: ImVec2, rot: f32, a_min: f32, a_max: f32) void;
pub extern fn ImDrawList_PathEllipticalArcToEx(self: [*c]ImDrawList, center: ImVec2, radius: ImVec2, rot: f32, a_min: f32, a_max: f32, num_segments: c_int) void;
pub extern fn ImDrawList_PathBezierCubicCurveTo(self: [*c]ImDrawList, p2: ImVec2, p3: ImVec2, p4: ImVec2, num_segments: c_int) void;
pub extern fn ImDrawList_PathBezierQuadraticCurveTo(self: [*c]ImDrawList, p2: ImVec2, p3: ImVec2, num_segments: c_int) void;
pub extern fn ImDrawList_PathRect(self: [*c]ImDrawList, rect_min: ImVec2, rect_max: ImVec2, rounding: f32, flags: ImDrawFlags) void;
pub extern fn ImDrawList_AddCallback(self: [*c]ImDrawList, callback: ImDrawCallback) void;
pub extern fn ImDrawList_AddCallbackEx(self: [*c]ImDrawList, callback: ImDrawCallback, userdata: ?*anyopaque, userdata_size: usize) void;
pub extern fn ImDrawList_AddDrawCmd(self: [*c]ImDrawList) void;
pub extern fn ImDrawList_CloneOutput(self: [*c]const ImDrawList) [*c]ImDrawList;
pub extern fn ImDrawList_ChannelsSplit(self: [*c]ImDrawList, count: c_int) void;
pub extern fn ImDrawList_ChannelsMerge(self: [*c]ImDrawList) void;
pub extern fn ImDrawList_ChannelsSetCurrent(self: [*c]ImDrawList, n: c_int) void;
pub extern fn ImDrawList_PrimReserve(self: [*c]ImDrawList, idx_count: c_int, vtx_count: c_int) void;
pub extern fn ImDrawList_PrimUnreserve(self: [*c]ImDrawList, idx_count: c_int, vtx_count: c_int) void;
pub extern fn ImDrawList_PrimRect(self: [*c]ImDrawList, a: ImVec2, b: ImVec2, col: ImU32) void;
pub extern fn ImDrawList_PrimRectUV(self: [*c]ImDrawList, a: ImVec2, b: ImVec2, uv_a: ImVec2, uv_b: ImVec2, col: ImU32) void;
pub extern fn ImDrawList_PrimQuadUV(self: [*c]ImDrawList, a: ImVec2, b: ImVec2, c: ImVec2, d: ImVec2, uv_a: ImVec2, uv_b: ImVec2, uv_c: ImVec2, uv_d: ImVec2, col: ImU32) void;
pub extern fn ImDrawList_PrimWriteVtx(self: [*c]ImDrawList, pos: ImVec2, uv: ImVec2, col: ImU32) void;
pub extern fn ImDrawList_PrimWriteIdx(self: [*c]ImDrawList, idx: ImDrawIdx) void;
pub extern fn ImDrawList_PrimVtx(self: [*c]ImDrawList, pos: ImVec2, uv: ImVec2, col: ImU32) void;
pub extern fn ImDrawList_AddRectImDrawFlags(self: [*c]ImDrawList, p_min: ImVec2, p_max: ImVec2, col: ImU32, rounding: f32, flags: ImDrawFlags, thickness: f32) void;
pub extern fn ImDrawList_AddPolylineImDrawFlags(self: [*c]ImDrawList, points: [*c]const ImVec2, num_points: c_int, col: ImU32, flags: ImDrawFlags, thickness: f32) void;
pub extern fn ImDrawList_PathStrokeImDrawFlags(self: [*c]ImDrawList, col: ImU32, flags: ImDrawFlags, thickness: f32) void;
pub extern fn ImDrawList_PushTextureID(self: [*c]ImDrawList, tex_ref: ImTextureRef) void;
pub extern fn ImDrawList_PopTextureID(self: [*c]ImDrawList) void;
pub extern fn ImDrawList__SetDrawListSharedData(self: [*c]ImDrawList, data: ?*ImDrawListSharedData) void;
pub extern fn ImDrawList__ResetForNewFrame(self: [*c]ImDrawList) void;
pub extern fn ImDrawList__ClearFreeMemory(self: [*c]ImDrawList) void;
pub extern fn ImDrawList__PopUnusedDrawCmd(self: [*c]ImDrawList) void;
pub extern fn ImDrawList__TryMergeDrawCmds(self: [*c]ImDrawList) void;
pub extern fn ImDrawList__OnChangedClipRect(self: [*c]ImDrawList) void;
pub extern fn ImDrawList__OnChangedTexture(self: [*c]ImDrawList) void;
pub extern fn ImDrawList__OnChangedVtxOffset(self: [*c]ImDrawList) void;
pub extern fn ImDrawList__SetTexture(self: [*c]ImDrawList, tex_ref: ImTextureRef) void;
pub extern fn ImDrawList__CalcCircleAutoSegmentCount(self: [*c]const ImDrawList, radius: f32) c_int;
pub extern fn ImDrawList__PathArcToFastEx(self: [*c]ImDrawList, center: ImVec2, radius: f32, a_min_sample: c_int, a_max_sample: c_int, a_step: c_int) void;
pub extern fn ImDrawList__PathArcToN(self: [*c]ImDrawList, center: ImVec2, radius: f32, a_min: f32, a_max: f32, num_segments: c_int) void;
pub extern fn ImDrawData_Clear(self: [*c]ImDrawData) void;
pub extern fn ImDrawData_AddDrawList(self: [*c]ImDrawData, draw_list: [*c]ImDrawList) void;
pub extern fn ImDrawData_DeIndexAllBuffers(self: [*c]ImDrawData) void;
pub extern fn ImDrawData_ScaleClipRects(self: [*c]ImDrawData, fb_scale: ImVec2) void;
pub const ImTextureFormat_RGBA32: c_int = 0;
pub const ImTextureFormat_Alpha8: c_int = 1;
pub const ImTextureFormat = c_uint;
pub const ImTextureStatus_OK: c_int = 0;
pub const ImTextureStatus_Destroyed: c_int = 1;
pub const ImTextureStatus_WantCreate: c_int = 2;
pub const ImTextureStatus_WantUpdates: c_int = 3;
pub const ImTextureStatus_WantDestroy: c_int = 4;
pub const ImTextureStatus = c_uint;
pub extern fn ImTextureData_Create(self: [*c]ImTextureData, format: ImTextureFormat, w: c_int, h: c_int) void;
pub extern fn ImTextureData_DestroyPixels(self: [*c]ImTextureData) void;
pub extern fn ImTextureData_GetPixels(self: [*c]ImTextureData) ?*anyopaque;
pub extern fn ImTextureData_GetPixelsAt(self: [*c]ImTextureData, x: c_int, y: c_int) ?*anyopaque;
pub extern fn ImTextureData_GetSizeInBytes(self: [*c]const ImTextureData) c_int;
pub extern fn ImTextureData_GetPitch(self: [*c]const ImTextureData) c_int;
pub extern fn ImTextureData_GetTexRef(self: [*c]ImTextureData) ImTextureRef;
pub extern fn ImTextureData_GetTexID(self: [*c]const ImTextureData) ImTextureID;
pub extern fn ImTextureData_SetTexID(self: [*c]ImTextureData, tex_id: ImTextureID) void;
pub extern fn ImTextureData_SetStatus(self: [*c]ImTextureData, status: ImTextureStatus) void;
pub extern fn ImFontGlyphRangesBuilder_Clear(self: [*c]ImFontGlyphRangesBuilder) void;
pub extern fn ImFontGlyphRangesBuilder_GetBit(self: [*c]const ImFontGlyphRangesBuilder, n: usize) bool;
pub extern fn ImFontGlyphRangesBuilder_SetBit(self: [*c]ImFontGlyphRangesBuilder, n: usize) void;
pub extern fn ImFontGlyphRangesBuilder_AddChar(self: [*c]ImFontGlyphRangesBuilder, c: ImWchar) void;
pub extern fn ImFontGlyphRangesBuilder_AddText(self: [*c]ImFontGlyphRangesBuilder, text: [*c]const u8, text_end: [*c]const u8) void;
pub extern fn ImFontGlyphRangesBuilder_AddRanges(self: [*c]ImFontGlyphRangesBuilder, ranges: [*c]const ImWchar) void;
pub extern fn ImFontGlyphRangesBuilder_BuildRanges(self: [*c]ImFontGlyphRangesBuilder, out_ranges: [*c]ImVector_ImWchar) void;
pub const ImFontAtlasRectId = c_int;
pub const ImFontAtlasFlags_None: c_int = 0;
pub const ImFontAtlasFlags_NoPowerOfTwoHeight: c_int = 1;
pub const ImFontAtlasFlags_NoMouseCursors: c_int = 2;
pub const ImFontAtlasFlags_NoBakedLines: c_int = 4;
pub const ImFontAtlasFlags_ = c_uint;
pub extern fn ImFontAtlas_AddFont(self: [*c]ImFontAtlas, font_cfg: [*c]const ImFontConfig) [*c]ImFont;
pub extern fn ImFontAtlas_AddFontDefault(self: [*c]ImFontAtlas, font_cfg: [*c]const ImFontConfig) [*c]ImFont;
pub extern fn ImFontAtlas_AddFontDefaultVector(self: [*c]ImFontAtlas, font_cfg: [*c]const ImFontConfig) [*c]ImFont;
pub extern fn ImFontAtlas_AddFontDefaultBitmap(self: [*c]ImFontAtlas, font_cfg: [*c]const ImFontConfig) [*c]ImFont;
pub extern fn ImFontAtlas_AddFontFromFileTTF(self: [*c]ImFontAtlas, filename: [*c]const u8, size_pixels: f32, font_cfg: [*c]const ImFontConfig, glyph_ranges: [*c]const ImWchar) [*c]ImFont;
pub extern fn ImFontAtlas_AddFontFromMemoryTTF(self: [*c]ImFontAtlas, font_data: ?*anyopaque, font_data_size: c_int, size_pixels: f32, font_cfg: [*c]const ImFontConfig, glyph_ranges: [*c]const ImWchar) [*c]ImFont;
pub extern fn ImFontAtlas_AddFontFromMemoryCompressedTTF(self: [*c]ImFontAtlas, compressed_font_data: ?*const anyopaque, compressed_font_data_size: c_int, size_pixels: f32, font_cfg: [*c]const ImFontConfig, glyph_ranges: [*c]const ImWchar) [*c]ImFont;
pub extern fn ImFontAtlas_AddFontFromMemoryCompressedBase85TTF(self: [*c]ImFontAtlas, compressed_font_data_base85: [*c]const u8, size_pixels: f32, font_cfg: [*c]const ImFontConfig, glyph_ranges: [*c]const ImWchar) [*c]ImFont;
pub extern fn ImFontAtlas_RemoveFont(self: [*c]ImFontAtlas, font: [*c]ImFont) void;
pub extern fn ImFontAtlas_CompactCache(self: [*c]ImFontAtlas) void;
pub extern fn ImFontAtlas_SetFontLoader(self: [*c]ImFontAtlas, font_loader: ?*const ImFontLoader) void;
pub extern fn ImFontAtlas_Clear(self: [*c]ImFontAtlas) void;
pub extern fn ImFontAtlas_ClearFonts(self: [*c]ImFontAtlas) void;
pub extern fn ImFontAtlas_ClearInputData(self: [*c]ImFontAtlas) void;
pub extern fn ImFontAtlas_ClearTexData(self: [*c]ImFontAtlas) void;
pub extern fn ImFontAtlas_Build(self: [*c]ImFontAtlas) bool;
pub extern fn ImFontAtlas_GetTexDataAsAlpha8(self: [*c]ImFontAtlas, out_pixels: [*c][*c]u8, out_width: [*c]c_int, out_height: [*c]c_int, out_bytes_per_pixel: [*c]c_int) void;
pub extern fn ImFontAtlas_GetTexDataAsRGBA32(self: [*c]ImFontAtlas, out_pixels: [*c][*c]u8, out_width: [*c]c_int, out_height: [*c]c_int, out_bytes_per_pixel: [*c]c_int) void;
pub extern fn ImFontAtlas_SetTexID(self: [*c]ImFontAtlas, id: ImTextureID) void;
pub extern fn ImFontAtlas_SetTexIDImTextureRef(self: [*c]ImFontAtlas, id: ImTextureRef) void;
pub extern fn ImFontAtlas_IsBuilt(self: [*c]const ImFontAtlas) bool;
pub extern fn ImFontAtlas_GetGlyphRangesDefault(self: [*c]ImFontAtlas) [*c]const ImWchar;
pub extern fn ImFontAtlas_GetGlyphRangesGreek(self: [*c]ImFontAtlas) [*c]const ImWchar;
pub extern fn ImFontAtlas_GetGlyphRangesKorean(self: [*c]ImFontAtlas) [*c]const ImWchar;
pub extern fn ImFontAtlas_GetGlyphRangesJapanese(self: [*c]ImFontAtlas) [*c]const ImWchar;
pub extern fn ImFontAtlas_GetGlyphRangesChineseFull(self: [*c]ImFontAtlas) [*c]const ImWchar;
pub extern fn ImFontAtlas_GetGlyphRangesChineseSimplifiedCommon(self: [*c]ImFontAtlas) [*c]const ImWchar;
pub extern fn ImFontAtlas_GetGlyphRangesCyrillic(self: [*c]ImFontAtlas) [*c]const ImWchar;
pub extern fn ImFontAtlas_GetGlyphRangesThai(self: [*c]ImFontAtlas) [*c]const ImWchar;
pub extern fn ImFontAtlas_GetGlyphRangesVietnamese(self: [*c]ImFontAtlas) [*c]const ImWchar;
pub extern fn ImFontAtlas_AddCustomRect(self: [*c]ImFontAtlas, width: c_int, height: c_int, out_r: [*c]ImFontAtlasRect) ImFontAtlasRectId;
pub extern fn ImFontAtlas_RemoveCustomRect(self: [*c]ImFontAtlas, id: ImFontAtlasRectId) void;
pub extern fn ImFontAtlas_GetCustomRect(self: [*c]const ImFontAtlas, id: ImFontAtlasRectId, out_r: [*c]ImFontAtlasRect) bool;
pub extern fn ImFontAtlas_AddCustomRectRegular(self: [*c]ImFontAtlas, w: c_int, h: c_int) ImFontAtlasRectId;
pub extern fn ImFontAtlas_GetCustomRectByIndex(self: [*c]ImFontAtlas, id: ImFontAtlasRectId) [*c]const ImFontAtlasRect;
pub extern fn ImFontAtlas_CalcCustomRectUV(self: [*c]const ImFontAtlas, r: [*c]const ImFontAtlasRect, out_uv_min: [*c]ImVec2, out_uv_max: [*c]ImVec2) void;
pub extern fn ImFontAtlas_AddCustomRectFontGlyph(self: [*c]ImFontAtlas, font: [*c]ImFont, codepoint: ImWchar, w: c_int, h: c_int, advance_x: f32, offset: ImVec2) ImFontAtlasRectId;
pub extern fn ImFontAtlas_AddCustomRectFontGlyphForSize(self: [*c]ImFontAtlas, font: [*c]ImFont, font_size: f32, codepoint: ImWchar, w: c_int, h: c_int, advance_x: f32, offset: ImVec2) ImFontAtlasRectId;
pub extern fn ImFontBaked_ClearOutputData(self: ?*ImFontBaked) void;
pub extern fn ImFontBaked_FindGlyph(self: ?*ImFontBaked, c: ImWchar) ?*ImFontGlyph;
pub extern fn ImFontBaked_FindGlyphNoFallback(self: ?*ImFontBaked, c: ImWchar) ?*ImFontGlyph;
pub extern fn ImFontBaked_GetCharAdvance(self: ?*ImFontBaked, c: ImWchar) f32;
pub extern fn ImFontBaked_IsGlyphLoaded(self: ?*ImFontBaked, c: ImWchar) bool;
pub const ImFontFlags_None: c_int = 0;
pub const ImFontFlags_NoLoadError: c_int = 2;
pub const ImFontFlags_NoLoadGlyphs: c_int = 4;
pub const ImFontFlags_LockBakedSizes: c_int = 8;
pub const ImFontFlags_ImplicitRefSize: c_int = 16;
pub const ImFontFlags_ = c_uint;
pub extern fn ImFont_IsGlyphInFont(self: [*c]ImFont, c: ImWchar) bool;
pub extern fn ImFont_IsLoaded(self: [*c]const ImFont) bool;
pub extern fn ImFont_GetDebugName(self: [*c]const ImFont) [*c]const u8;
pub extern fn ImFont_GetFontBaked(self: [*c]ImFont, font_size: f32) ?*ImFontBaked;
pub extern fn ImFont_GetFontBakedEx(self: [*c]ImFont, font_size: f32, density: f32) ?*ImFontBaked;
pub extern fn ImFont_CalcTextSizeA(self: [*c]ImFont, size: f32, max_width: f32, wrap_width: f32, text_begin: [*c]const u8) ImVec2;
pub extern fn ImFont_CalcTextSizeAEx(self: [*c]ImFont, size: f32, max_width: f32, wrap_width: f32, text_begin: [*c]const u8, text_end: [*c]const u8, out_remaining: [*c][*c]const u8) ImVec2;
pub extern fn ImFont_CalcWordWrapPosition(self: [*c]ImFont, size: f32, text: [*c]const u8, text_end: [*c]const u8, wrap_width: f32) [*c]const u8;
pub extern fn ImFont_RenderChar(self: [*c]ImFont, draw_list: [*c]ImDrawList, size: f32, pos: ImVec2, col: ImU32, c: ImWchar) void;
pub extern fn ImFont_RenderCharEx(self: [*c]ImFont, draw_list: [*c]ImDrawList, size: f32, pos: ImVec2, col: ImU32, c: ImWchar, cpu_fine_clip: [*c]const ImVec4) void;
pub extern fn ImFont_RenderText(self: [*c]ImFont, draw_list: [*c]ImDrawList, size: f32, pos: ImVec2, col: ImU32, clip_rect: ImVec4, text_begin: [*c]const u8, text_end: [*c]const u8, wrap_width: f32, flags: ImDrawTextFlags) void;
pub extern fn ImFont_CalcWordWrapPositionA(self: [*c]ImFont, scale: f32, text: [*c]const u8, text_end: [*c]const u8, wrap_width: f32) [*c]const u8;
pub extern fn ImFont_ClearOutputData(self: [*c]ImFont) void;
pub extern fn ImFont_AddRemapChar(self: [*c]ImFont, from_codepoint: ImWchar, to_codepoint: ImWchar) void;
pub extern fn ImFont_IsGlyphRangeUnused(self: [*c]ImFont, c_begin: c_uint, c_last: c_uint) bool;
pub const ImGuiViewportFlags_None: c_int = 0;
pub const ImGuiViewportFlags_IsPlatformWindow: c_int = 1;
pub const ImGuiViewportFlags_IsPlatformMonitor: c_int = 2;
pub const ImGuiViewportFlags_OwnedByApp: c_int = 4;
pub const ImGuiViewportFlags_NoDecoration: c_int = 8;
pub const ImGuiViewportFlags_NoTaskBarIcon: c_int = 16;
pub const ImGuiViewportFlags_NoFocusOnAppearing: c_int = 32;
pub const ImGuiViewportFlags_NoFocusOnClick: c_int = 64;
pub const ImGuiViewportFlags_NoInputs: c_int = 128;
pub const ImGuiViewportFlags_NoRendererClear: c_int = 256;
pub const ImGuiViewportFlags_NoAutoMerge: c_int = 512;
pub const ImGuiViewportFlags_TopMost: c_int = 1024;
pub const ImGuiViewportFlags_CanHostOtherWindows: c_int = 2048;
pub const ImGuiViewportFlags_IsMinimized: c_int = 4096;
pub const ImGuiViewportFlags_IsFocused: c_int = 8192;
pub const ImGuiViewportFlags_ = c_uint;
pub extern fn ImGuiViewport_GetCenter(self: [*c]const ImGuiViewport) ImVec2;
pub extern fn ImGuiViewport_GetWorkCenter(self: [*c]const ImGuiViewport) ImVec2;
pub extern fn ImGuiViewport_GetDebugName(self: [*c]const ImGuiViewport) [*c]const u8;
pub extern fn ImGuiPlatformIO_ClearPlatformHandlers(self: [*c]ImGuiPlatformIO) void;
pub extern fn ImGuiPlatformIO_ClearRendererHandlers(self: [*c]ImGuiPlatformIO) void;
pub extern fn igSetColorEditOptions(flags: ImGuiColorEditFlags) void;
pub extern fn igPushFont(font: [*c]ImFont) void;
pub extern fn igSetWindowFontScale(scale: f32) void;
pub extern fn igImageImVec4(tex_ref: ImTextureRef, image_size: ImVec2, uv0: ImVec2, uv1: ImVec2, tint_col: ImVec4, border_col: ImVec4) void;
pub extern fn igPushButtonRepeat(repeat: bool) void;
pub extern fn igPopButtonRepeat() void;
pub extern fn igPushTabStop(tab_stop: bool) void;
pub extern fn igPopTabStop() void;
pub extern fn igGetContentRegionMax() ImVec2;
pub extern fn igGetWindowContentRegionMin() ImVec2;
pub extern fn igGetWindowContentRegionMax() ImVec2;
pub const ImFontAtlasCustomRect = ImFontAtlasRect;

pub const __VERSION__ = "Aro 0.0.0";
pub const __Aro__ = "";
pub const __STDC__ = @as(c_int, 1);
pub const __STDC_HOSTED__ = @as(c_int, 1);
pub const __STDC_UTF_16__ = @as(c_int, 1);
pub const __STDC_UTF_32__ = @as(c_int, 1);
pub const __STDC_EMBED_NOT_FOUND__ = @as(c_int, 0);
pub const __STDC_EMBED_FOUND__ = @as(c_int, 1);
pub const __STDC_EMBED_EMPTY__ = @as(c_int, 2);
pub const __STDC_NO_THREADS__ = @as(c_int, 1);
pub const __STDC_VERSION__ = @as(c_long, 201710);
pub const __GNUC__ = @as(c_int, 7);
pub const __GNUC_MINOR__ = @as(c_int, 1);
pub const __GNUC_PATCHLEVEL__ = @as(c_int, 0);
pub const __ARO_EMULATE_NO__ = @as(c_int, 0);
pub const __ARO_EMULATE_CLANG__ = @as(c_int, 1);
pub const __ARO_EMULATE_GCC__ = @as(c_int, 2);
pub const __ARO_EMULATE_MSVC__ = @as(c_int, 3);
pub const __ARO_EMULATE__ = __ARO_EMULATE_NO__;
pub inline fn __building_module(x: anytype) @TypeOf(@as(c_int, 0)) {
    _ = &x;
    return @as(c_int, 0);
}
pub const __OPTIMIZE__ = @as(c_int, 1);
pub const __OPTIMIZE_SIZE__ = @as(c_int, 1);
pub const __APPLE__ = @as(c_int, 1);
pub const __APPLE_CC__ = @as(c_int, 6000);
pub const __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__ = __helpers.promoteIntLiteral(c_int, 260502, .decimal);
pub const __ENVIRONMENT_OS_VERSION_MIN_REQUIRED__ = __helpers.promoteIntLiteral(c_int, 260502, .decimal);
pub const __aarch64__ = @as(c_int, 1);
pub const __ARM_64BIT_STATE = @as(c_int, 1);
pub const __ARM_ARCH_ISA_A64 = @as(c_int, 1);
pub const __ARM_ALIGN_MAX_STACK_PWR = @as(c_int, 4);
pub const __ARM_FEATURE_CLZ = @as(c_int, 1);
pub const __ARM_FEATURE_FMA = @as(c_int, 1);
pub const __ARM_FEATURE_LDREX = @as(c_int, 0xF);
pub const __ARM_FEATURE_IDIV = @as(c_int, 1);
pub const __ARM_FEATURE_DIV = @as(c_int, 1);
pub const __ARM_FEATURE_NUMERIC_MAXMIN = @as(c_int, 1);
pub const __ARM_FEATURE_DIRECTED_ROUNDING = @as(c_int, 1);
pub inline fn __ARM_ACLE_VERSION(year: anytype, quarter: anytype, patch: anytype) @TypeOf(((@as(c_int, 100) * year) + (@as(c_int, 10) * quarter)) + patch) {
    _ = &year;
    _ = &quarter;
    _ = &patch;
    return ((@as(c_int, 100) * year) + (@as(c_int, 10) * quarter)) + patch;
}
pub const __ARM_ACLE = __helpers.promoteIntLiteral(c_int, 202420, .decimal);
pub const __ARM_ARCH_8_6A__ = @as(c_int, 1);
pub const __ARM_ARCH = @as(c_int, 8);
pub const __ARM_ARCH_PROFILE = 'A';
pub const __AARCH64EL__ = @as(c_int, 1);
pub const __AARCH64_SIMD__ = @as(c_int, 1);
pub const __ARM64_ARCH_8__ = @as(c_int, 1);
pub const __ARM_NEON__ = @as(c_int, 1);
pub const __arm64 = @as(c_int, 1);
pub const __arm64__ = @as(c_int, 1);
pub const __AARCH64_CMODEL_SMALL__ = @as(c_int, 1);
pub const __ARM_FP = @as(c_int, 0xE);
pub const __ARM_NEON = @as(c_int, 1);
pub const __ARM_NEON_FP = @as(c_int, 0xE);
pub const __ARM_FEATURE_BF16 = @as(c_int, 1);
pub const __ARM_FEATURE_BF16_VECTOR_ARITHMETIC = @as(c_int, 1);
pub const __ARM_BF16_FORMAT_ALTERNATIVE = @as(c_int, 1);
pub const __ARM_FEATURE_BF16_SCALAR_ARITHMETIC = @as(c_int, 1);
pub const __ARM_FEATURE_SHA3 = @as(c_int, 1);
pub const __ARM_FEATURE_SHA512 = @as(c_int, 1);
pub const __ARM_FEATURE_UNALIGNED = @as(c_int, 1);
pub const __ARM_FEATURE_FP16_VECTOR_ARITHMETIC = @as(c_int, 1);
pub const __ARM_FEATURE_RCPC = @as(c_int, 1);
pub const __ARM_FEATURE_CRC32 = @as(c_int, 1);
pub const __ARM_FEATURE_AES = @as(c_int, 1);
pub const __ARM_FEATURE_SHA2 = @as(c_int, 1);
pub const __ARM_FEATURE_PAUTH = @as(c_int, 1);
pub const __ARM_FEATURE_BTI = @as(c_int, 1);
pub const __ARM_FEATURE_FP16_SCALAR_ARITHMETIC = @as(c_int, 1);
pub const __ARM_FEATURE_DOTPROD = @as(c_int, 1);
pub const __ARM_FEATURE_MATMUL_INT8 = @as(c_int, 1);
pub const __ARM_FEATURE_ATOMICS = @as(c_int, 1);
pub const __ARM_FEATURE_SVE_MATMUL_INT8 = @as(c_int, 1);
pub const __ARM_FEATURE_FP16_FML = @as(c_int, 1);
pub const _LP64 = @as(c_int, 1);
pub const __LP64__ = @as(c_int, 1);
pub const __ORDER_LITTLE_ENDIAN__ = @as(c_int, 1234);
pub const __ORDER_BIG_ENDIAN__ = @as(c_int, 4321);
pub const __ORDER_PDP_ENDIAN__ = @as(c_int, 3412);
pub const __BYTE_ORDER__ = __ORDER_LITTLE_ENDIAN__;
pub const __LITTLE_ENDIAN__ = @as(c_int, 1);
pub const __MACH__ = @as(c_int, 1);
pub const __nonnull = @compileError("unable to translate C expr: unexpected token '_Nonnull'"); // <builtin>:81:9
pub const __null_unspecified = @compileError("unable to translate C expr: unexpected token '_Null_unspecified'"); // <builtin>:82:9
pub const __nullable = @compileError("unable to translate C expr: unexpected token '_Nullable'"); // <builtin>:83:9
pub const __ATOMIC_RELAXED = @as(c_int, 0);
pub const __ATOMIC_CONSUME = @as(c_int, 1);
pub const __ATOMIC_ACQUIRE = @as(c_int, 2);
pub const __ATOMIC_RELEASE = @as(c_int, 3);
pub const __ATOMIC_ACQ_REL = @as(c_int, 4);
pub const __ATOMIC_SEQ_CST = @as(c_int, 5);
pub const __ATOMIC_BOOL_LOCK_FREE = @as(c_int, 1);
pub const __ATOMIC_CHAR_LOCK_FREE = @as(c_int, 1);
pub const __ATOMIC_CHAR16_T_LOCK_FREE = @as(c_int, 1);
pub const __ATOMIC_CHAR32_T_LOCK_FREE = @as(c_int, 1);
pub const __ATOMIC_WCHAR_T_LOCK_FREE = @as(c_int, 1);
pub const __ATOMIC_WINT_T_LOCK_FREE = @as(c_int, 1);
pub const __ATOMIC_SHORT_LOCK_FREE = @as(c_int, 1);
pub const __ATOMIC_INT_LOCK_FREE = @as(c_int, 1);
pub const __ATOMIC_LONG_LOCK_FREE = @as(c_int, 1);
pub const __ATOMIC_LLONG_LOCK_FREE = @as(c_int, 1);
pub const __ATOMIC_POINTER_LOCK_FREE = @as(c_int, 1);
pub const __CHAR_BIT__ = @as(c_int, 8);
pub const __BOOL_WIDTH__ = @as(c_int, 8);
pub const __SCHAR_MAX__ = @as(c_int, 127);
pub const __SCHAR_WIDTH__ = @as(c_int, 8);
pub const __SHRT_MAX__ = @as(c_int, 32767);
pub const __SHRT_WIDTH__ = @as(c_int, 16);
pub const __INT_MAX__ = __helpers.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __INT_WIDTH__ = @as(c_int, 32);
pub const __LONG_MAX__ = __helpers.promoteIntLiteral(c_long, 9223372036854775807, .decimal);
pub const __LONG_WIDTH__ = @as(c_int, 64);
pub const __LONG_LONG_MAX__ = @as(c_longlong, 9223372036854775807);
pub const __LONG_LONG_WIDTH__ = @as(c_int, 64);
pub const __WCHAR_MAX__ = __helpers.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __WCHAR_WIDTH__ = @as(c_int, 32);
pub const __WINT_MAX__ = __helpers.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __WINT_WIDTH__ = @as(c_int, 32);
pub const __INTMAX_MAX__ = __helpers.promoteIntLiteral(c_long, 9223372036854775807, .decimal);
pub const __INTMAX_WIDTH__ = @as(c_int, 64);
pub const __SIZE_MAX__ = __helpers.promoteIntLiteral(c_ulong, 18446744073709551615, .decimal);
pub const __SIZE_WIDTH__ = @as(c_int, 64);
pub const __UINTMAX_MAX__ = __helpers.promoteIntLiteral(c_ulong, 18446744073709551615, .decimal);
pub const __UINTMAX_WIDTH__ = @as(c_int, 64);
pub const __PTRDIFF_MAX__ = __helpers.promoteIntLiteral(c_long, 9223372036854775807, .decimal);
pub const __PTRDIFF_WIDTH__ = @as(c_int, 64);
pub const __INTPTR_MAX__ = __helpers.promoteIntLiteral(c_long, 9223372036854775807, .decimal);
pub const __INTPTR_WIDTH__ = @as(c_int, 64);
pub const __UINTPTR_MAX__ = __helpers.promoteIntLiteral(c_ulong, 18446744073709551615, .decimal);
pub const __UINTPTR_WIDTH__ = @as(c_int, 64);
pub const __SIG_ATOMIC_MAX__ = __helpers.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __SIG_ATOMIC_WIDTH__ = @as(c_int, 32);
pub const __BITINT_MAXWIDTH__ = __helpers.promoteIntLiteral(c_int, 65535, .decimal);
pub const __SIZEOF_FLOAT__ = @as(c_int, 4);
pub const __SIZEOF_DOUBLE__ = @as(c_int, 8);
pub const __SIZEOF_LONG_DOUBLE__ = @as(c_int, 8);
pub const __SIZEOF_SHORT__ = @as(c_int, 2);
pub const __SIZEOF_INT__ = @as(c_int, 4);
pub const __SIZEOF_LONG__ = @as(c_int, 8);
pub const __SIZEOF_LONG_LONG__ = @as(c_int, 8);
pub const __SIZEOF_POINTER__ = @as(c_int, 8);
pub const __SIZEOF_PTRDIFF_T__ = @as(c_int, 8);
pub const __SIZEOF_SIZE_T__ = @as(c_int, 8);
pub const __SIZEOF_WCHAR_T__ = @as(c_int, 4);
pub const __SIZEOF_WINT_T__ = @as(c_int, 4);
pub const __SIZEOF_INT128__ = @as(c_int, 16);
pub const __INTPTR_TYPE__ = c_long;
pub const __UINTPTR_TYPE__ = c_ulong;
pub const __INTMAX_TYPE__ = c_long;
pub const __INTMAX_C_SUFFIX__ = @compileError("unable to translate macro: undefined identifier `L`"); // <builtin>:148:9
pub const __INTMAX_C = __helpers.L_SUFFIX;
pub const __UINTMAX_TYPE__ = c_ulong;
pub const __UINTMAX_C_SUFFIX__ = @compileError("unable to translate macro: undefined identifier `UL`"); // <builtin>:151:9
pub const __UINTMAX_C = __helpers.UL_SUFFIX;
pub const __PTRDIFF_TYPE__ = c_long;
pub const __SIZE_TYPE__ = c_ulong;
pub const __WCHAR_TYPE__ = c_int;
pub const __WINT_TYPE__ = c_int;
pub const __CHAR16_TYPE__ = c_ushort;
pub const __CHAR32_TYPE__ = c_uint;
pub const __INT8_TYPE__ = i8;
pub const __INT8_FMTd__ = "hhd";
pub const __INT8_FMTi__ = "hhi";
pub const __INT8_C_SUFFIX__ = "";
pub inline fn __INT8_C(c: anytype) @TypeOf(c) {
    _ = &c;
    return c;
}
pub const __INT16_TYPE__ = c_short;
pub const __INT16_FMTd__ = "hd";
pub const __INT16_FMTi__ = "hi";
pub const __INT16_C_SUFFIX__ = "";
pub inline fn __INT16_C(c: anytype) @TypeOf(c) {
    _ = &c;
    return c;
}
pub const __INT32_TYPE__ = c_int;
pub const __INT32_FMTd__ = "d";
pub const __INT32_FMTi__ = "i";
pub const __INT32_C_SUFFIX__ = "";
pub inline fn __INT32_C(c: anytype) @TypeOf(c) {
    _ = &c;
    return c;
}
pub const __INT64_TYPE__ = c_longlong;
pub const __INT64_FMTd__ = "lld";
pub const __INT64_FMTi__ = "lli";
pub const __INT64_C_SUFFIX__ = @compileError("unable to translate macro: undefined identifier `LL`"); // <builtin>:177:9
pub const __INT64_C = __helpers.LL_SUFFIX;
pub const __UINT8_TYPE__ = u8;
pub const __UINT8_FMTo__ = "hho";
pub const __UINT8_FMTu__ = "hhu";
pub const __UINT8_FMTx__ = "hhx";
pub const __UINT8_FMTX__ = "hhX";
pub const __UINT8_C_SUFFIX__ = "";
pub inline fn __UINT8_C(c: anytype) @TypeOf(c) {
    _ = &c;
    return c;
}
pub const __UINT8_MAX__ = @as(c_int, 255);
pub const __INT8_MAX__ = @as(c_int, 127);
pub const __UINT16_TYPE__ = c_ushort;
pub const __UINT16_FMTo__ = "ho";
pub const __UINT16_FMTu__ = "hu";
pub const __UINT16_FMTx__ = "hx";
pub const __UINT16_FMTX__ = "hX";
pub const __UINT16_C_SUFFIX__ = "";
pub inline fn __UINT16_C(c: anytype) @TypeOf(c) {
    _ = &c;
    return c;
}
pub const __UINT16_MAX__ = __helpers.promoteIntLiteral(c_int, 65535, .decimal);
pub const __INT16_MAX__ = @as(c_int, 32767);
pub const __UINT32_TYPE__ = c_uint;
pub const __UINT32_FMTo__ = "o";
pub const __UINT32_FMTu__ = "u";
pub const __UINT32_FMTx__ = "x";
pub const __UINT32_FMTX__ = "X";
pub const __UINT32_C_SUFFIX__ = @compileError("unable to translate macro: undefined identifier `U`"); // <builtin>:202:9
pub const __UINT32_C = __helpers.U_SUFFIX;
pub const __UINT32_MAX__ = __helpers.promoteIntLiteral(c_uint, 4294967295, .decimal);
pub const __INT32_MAX__ = __helpers.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __UINT64_TYPE__ = c_ulonglong;
pub const __UINT64_FMTo__ = "llo";
pub const __UINT64_FMTu__ = "llu";
pub const __UINT64_FMTx__ = "llx";
pub const __UINT64_FMTX__ = "llX";
pub const __UINT64_C_SUFFIX__ = @compileError("unable to translate macro: undefined identifier `ULL`"); // <builtin>:211:9
pub const __UINT64_C = __helpers.ULL_SUFFIX;
pub const __UINT64_MAX__ = @as(c_ulonglong, 18446744073709551615);
pub const __INT64_MAX__ = @as(c_longlong, 9223372036854775807);
pub const __INT_LEAST8_TYPE__ = i8;
pub const __INT_LEAST8_MAX__ = @as(c_int, 127);
pub const __INT_LEAST8_WIDTH__ = @as(c_int, 8);
pub const INT_LEAST8_FMTd__ = "hhd";
pub const INT_LEAST8_FMTi__ = "hhi";
pub const __UINT_LEAST8_TYPE__ = u8;
pub const __UINT_LEAST8_MAX__ = @as(c_int, 255);
pub const UINT_LEAST8_FMTo__ = "hho";
pub const UINT_LEAST8_FMTu__ = "hhu";
pub const UINT_LEAST8_FMTx__ = "hhx";
pub const UINT_LEAST8_FMTX__ = "hhX";
pub const __INT_FAST8_TYPE__ = i8;
pub const __INT_FAST8_MAX__ = @as(c_int, 127);
pub const __INT_FAST8_WIDTH__ = @as(c_int, 8);
pub const INT_FAST8_FMTd__ = "hhd";
pub const INT_FAST8_FMTi__ = "hhi";
pub const __UINT_FAST8_TYPE__ = u8;
pub const __UINT_FAST8_MAX__ = @as(c_int, 255);
pub const UINT_FAST8_FMTo__ = "hho";
pub const UINT_FAST8_FMTu__ = "hhu";
pub const UINT_FAST8_FMTx__ = "hhx";
pub const UINT_FAST8_FMTX__ = "hhX";
pub const __INT_LEAST16_TYPE__ = c_short;
pub const __INT_LEAST16_MAX__ = @as(c_int, 32767);
pub const __INT_LEAST16_WIDTH__ = @as(c_int, 16);
pub const INT_LEAST16_FMTd__ = "hd";
pub const INT_LEAST16_FMTi__ = "hi";
pub const __UINT_LEAST16_TYPE__ = c_ushort;
pub const __UINT_LEAST16_MAX__ = __helpers.promoteIntLiteral(c_int, 65535, .decimal);
pub const UINT_LEAST16_FMTo__ = "ho";
pub const UINT_LEAST16_FMTu__ = "hu";
pub const UINT_LEAST16_FMTx__ = "hx";
pub const UINT_LEAST16_FMTX__ = "hX";
pub const __INT_FAST16_TYPE__ = c_short;
pub const __INT_FAST16_MAX__ = @as(c_int, 32767);
pub const __INT_FAST16_WIDTH__ = @as(c_int, 16);
pub const INT_FAST16_FMTd__ = "hd";
pub const INT_FAST16_FMTi__ = "hi";
pub const __UINT_FAST16_TYPE__ = c_ushort;
pub const __UINT_FAST16_MAX__ = __helpers.promoteIntLiteral(c_int, 65535, .decimal);
pub const UINT_FAST16_FMTo__ = "ho";
pub const UINT_FAST16_FMTu__ = "hu";
pub const UINT_FAST16_FMTx__ = "hx";
pub const UINT_FAST16_FMTX__ = "hX";
pub const __INT_LEAST32_TYPE__ = c_int;
pub const __INT_LEAST32_MAX__ = __helpers.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __INT_LEAST32_WIDTH__ = @as(c_int, 32);
pub const INT_LEAST32_FMTd__ = "d";
pub const INT_LEAST32_FMTi__ = "i";
pub const __UINT_LEAST32_TYPE__ = c_uint;
pub const __UINT_LEAST32_MAX__ = __helpers.promoteIntLiteral(c_uint, 4294967295, .decimal);
pub const UINT_LEAST32_FMTo__ = "o";
pub const UINT_LEAST32_FMTu__ = "u";
pub const UINT_LEAST32_FMTx__ = "x";
pub const UINT_LEAST32_FMTX__ = "X";
pub const __INT_FAST32_TYPE__ = c_int;
pub const __INT_FAST32_MAX__ = __helpers.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __INT_FAST32_WIDTH__ = @as(c_int, 32);
pub const INT_FAST32_FMTd__ = "d";
pub const INT_FAST32_FMTi__ = "i";
pub const __UINT_FAST32_TYPE__ = c_uint;
pub const __UINT_FAST32_MAX__ = __helpers.promoteIntLiteral(c_uint, 4294967295, .decimal);
pub const UINT_FAST32_FMTo__ = "o";
pub const UINT_FAST32_FMTu__ = "u";
pub const UINT_FAST32_FMTx__ = "x";
pub const UINT_FAST32_FMTX__ = "X";
pub const __INT_LEAST64_TYPE__ = c_longlong;
pub const __INT_LEAST64_MAX__ = @as(c_longlong, 9223372036854775807);
pub const __INT_LEAST64_WIDTH__ = @as(c_int, 64);
pub const INT_LEAST64_FMTd__ = "lld";
pub const INT_LEAST64_FMTi__ = "lli";
pub const __UINT_LEAST64_TYPE__ = c_ulonglong;
pub const __UINT_LEAST64_MAX__ = @as(c_ulonglong, 18446744073709551615);
pub const UINT_LEAST64_FMTo__ = "llo";
pub const UINT_LEAST64_FMTu__ = "llu";
pub const UINT_LEAST64_FMTx__ = "llx";
pub const UINT_LEAST64_FMTX__ = "llX";
pub const __INT_FAST64_TYPE__ = c_longlong;
pub const __INT_FAST64_MAX__ = @as(c_longlong, 9223372036854775807);
pub const __INT_FAST64_WIDTH__ = @as(c_int, 64);
pub const INT_FAST64_FMTd__ = "lld";
pub const INT_FAST64_FMTi__ = "lli";
pub const __UINT_FAST64_TYPE__ = c_ulonglong;
pub const __UINT_FAST64_MAX__ = @as(c_ulonglong, 18446744073709551615);
pub const UINT_FAST64_FMTo__ = "llo";
pub const UINT_FAST64_FMTu__ = "llu";
pub const UINT_FAST64_FMTx__ = "llx";
pub const UINT_FAST64_FMTX__ = "llX";
pub const __FLT16_DENORM_MIN__ = @as(f16, 5.9604644775390625e-8);
pub const __FLT16_HAS_DENORM__ = "";
pub const __FLT16_DIG__ = @as(c_int, 3);
pub const __FLT16_DECIMAL_DIG__ = @as(c_int, 5);
pub const __FLT16_EPSILON__ = @as(f16, 9.765625e-4);
pub const __FLT16_HAS_INFINITY__ = "";
pub const __FLT16_HAS_QUIET_NAN__ = "";
pub const __FLT16_MANT_DIG__ = @as(c_int, 11);
pub const __FLT16_MAX_10_EXP__ = @as(c_int, 4);
pub const __FLT16_MAX_EXP__ = @as(c_int, 16);
pub const __FLT16_MAX__ = @as(f16, 6.5504e+4);
pub const __FLT16_MIN_10_EXP__ = -@as(c_int, 4);
pub const __FLT16_MIN_EXP__ = -@as(c_int, 13);
pub const __FLT16_MIN__ = @as(f16, 6.103515625e-5);
pub const __FLT_DENORM_MIN__ = @as(f32, 1.40129846e-45);
pub const __FLT_HAS_DENORM__ = "";
pub const __FLT_DIG__ = @as(c_int, 6);
pub const __FLT_DECIMAL_DIG__ = @as(c_int, 9);
pub const __FLT_EPSILON__ = @as(f32, 1.19209290e-7);
pub const __FLT_HAS_INFINITY__ = "";
pub const __FLT_HAS_QUIET_NAN__ = "";
pub const __FLT_MANT_DIG__ = @as(c_int, 24);
pub const __FLT_MAX_10_EXP__ = @as(c_int, 38);
pub const __FLT_MAX_EXP__ = @as(c_int, 128);
pub const __FLT_MAX__ = @as(f32, 3.40282347e+38);
pub const __FLT_MIN_10_EXP__ = -@as(c_int, 37);
pub const __FLT_MIN_EXP__ = -@as(c_int, 125);
pub const __FLT_MIN__ = @as(f32, 1.17549435e-38);
pub const __DBL_DENORM_MIN__ = @as(f64, 4.9406564584124654e-324);
pub const __DBL_HAS_DENORM__ = "";
pub const __DBL_DIG__ = @as(c_int, 15);
pub const __DBL_DECIMAL_DIG__ = @as(c_int, 17);
pub const __DBL_EPSILON__ = @as(f64, 2.2204460492503131e-16);
pub const __DBL_HAS_INFINITY__ = "";
pub const __DBL_HAS_QUIET_NAN__ = "";
pub const __DBL_MANT_DIG__ = @as(c_int, 53);
pub const __DBL_MAX_10_EXP__ = @as(c_int, 308);
pub const __DBL_MAX_EXP__ = @as(c_int, 1024);
pub const __DBL_MAX__ = @as(f64, 1.7976931348623157e+308);
pub const __DBL_MIN_10_EXP__ = -@as(c_int, 307);
pub const __DBL_MIN_EXP__ = -@as(c_int, 1021);
pub const __DBL_MIN__ = @as(f64, 2.2250738585072014e-308);
pub const __LDBL_DENORM_MIN__ = @as(c_longdouble, 4.9406564584124654e-324);
pub const __LDBL_HAS_DENORM__ = "";
pub const __LDBL_DIG__ = @as(c_int, 15);
pub const __LDBL_DECIMAL_DIG__ = @as(c_int, 17);
pub const __LDBL_EPSILON__ = @as(c_longdouble, 2.2204460492503131e-16);
pub const __LDBL_HAS_INFINITY__ = "";
pub const __LDBL_HAS_QUIET_NAN__ = "";
pub const __LDBL_MANT_DIG__ = @as(c_int, 53);
pub const __LDBL_MAX_10_EXP__ = @as(c_int, 308);
pub const __LDBL_MAX_EXP__ = @as(c_int, 1024);
pub const __LDBL_MAX__ = @as(c_longdouble, 1.7976931348623157e+308);
pub const __LDBL_MIN_10_EXP__ = -@as(c_int, 307);
pub const __LDBL_MIN_EXP__ = -@as(c_int, 1021);
pub const __LDBL_MIN__ = @as(c_longdouble, 2.2250738585072014e-308);
pub const __FLT_EVAL_METHOD__ = @as(c_int, 0);
pub const __FLT_RADIX__ = @as(c_int, 2);
pub const __DECIMAL_DIG__ = __LDBL_DECIMAL_DIG__;
pub const __pic__ = @as(c_int, 2);
pub const __PIC__ = @as(c_int, 2);
pub const NDEBUG = @as(c_int, 1);
pub const IMGUI_VERSION = "1.92.9";
pub const IMGUI_VERSION_NUM = @as(c_int, 19290);
pub const IMGUI_HAS_TABLE = "";
pub const IMGUI_HAS_TEXTURES = "";
pub const IMGUI_HAS_VIEWPORT = "";
pub const IMGUI_HAS_DOCK = "";
pub const IMGUI_DEAR_BINDINGS_HAS_GETWINDOWFRAMEBUFFERSCALE = "";
pub const IMGUI_DEAR_BINDINGS_HAS_GETWINDOWWORKAREAINSETS = "";
pub const _STDINT_H_ = "";
pub const __WORDSIZE = @as(c_int, 64);
pub const _INT8_T = "";
pub const _INT16_T = "";
pub const _INT32_T = "";
pub const _INT64_T = "";
pub const _UINT8_T = "";
pub const _UINT16_T = "";
pub const _UINT32_T = "";
pub const _UINT64_T = "";
pub const _SYS__TYPES_H_ = "";
pub const _CDEFS_H_ = "";
pub const __BEGIN_DECLS = "";
pub const __END_DECLS = "";
pub inline fn __has_cpp_attribute(x: anytype) @TypeOf(@as(c_int, 0)) {
    _ = &x;
    return @as(c_int, 0);
}
pub inline fn __P(protos: anytype) @TypeOf(protos) {
    _ = &protos;
    return protos;
}
pub const __CONCAT = @compileError("unable to translate C expr: unexpected token '##'"); // /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk/usr/include/sys/cdefs.h:116:9
pub const __STRING = @compileError("unable to translate C expr: unexpected token ''"); // /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk/usr/include/sys/cdefs.h:117:9
pub const __const = @compileError("unable to translate C expr: unexpected token 'const'"); // /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk/usr/include/sys/cdefs.h:119:9
pub const __signed = c_int;
pub const __volatile = @compileError("unable to translate C expr: unexpected token 'volatile'"); // /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk/usr/include/sys/cdefs.h:121:9
pub const __dead2 = @compileError("unable to translate macro: undefined identifier `__noreturn__`"); // /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk/usr/include/sys/cdefs.h:165:9
pub const __pure2 = @compileError("unable to translate C expr: unexpected token '__attribute__'"); // /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk/usr/include/sys/cdefs.h:166:9
pub const __stateful_pure = @compileError("unable to translate macro: undefined identifier `__pure__`"); // /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk/usr/include/sys/cdefs.h:167:9
pub const __unused = @compileError("unable to translate macro: undefined identifier `__unused__`"); // /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk/usr/include/sys/cdefs.h:172:9
pub const __used = @compileError("unable to translate macro: undefined identifier `__used__`"); // /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk/usr/include/sys/cdefs.h:177:9
pub const __cold = @compileError("unable to translate macro: undefined identifier `__cold__`"); // /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk/usr/include/sys/cdefs.h:183:9
pub const __returns_nonnull = @compileError("unable to translate macro: undefined identifier `returns_nonnull`"); // /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk/usr/include/sys/cdefs.h:190:9
pub const __exported = @compileError("unable to translate macro: undefined identifier `__visibility__`"); // /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk/usr/include/sys/cdefs.h:200:9
pub const __exported_push = @compileError("unable to translate macro: undefined identifier `_Pragma`"); // /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk/usr/include/sys/cdefs.h:201:9
pub const __exported_push_hidden = @compileError("unable to translate macro: undefined identifier `_Pragma`"); // /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk/usr/include/sys/cdefs.h:203:9
pub const __exported_pop = @compileError("unable to translate macro: undefined identifier `_Pragma`"); // /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk/usr/include/sys/cdefs.h:204:9
pub const __exported_hidden = @compileError("unable to translate macro: undefined identifier `__private_extern__`"); // /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk/usr/include/sys/cdefs.h:205:9
pub const __deprecated = @compileError("unable to translate macro: undefined identifier `__deprecated__`"); // /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk/usr/include/sys/cdefs.h:223:9
pub const __deprecated_msg = @compileError("unable to translate macro: undefined identifier `__deprecated__`"); // /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk/usr/include/sys/cdefs.h:227:10
pub inline fn __deprecated_enum_msg(_msg: anytype) void {
    _ = &_msg;
    return;
}
pub inline fn __kpi_deprecated(_msg: anytype) void {
    _ = &_msg;
    return;
}
pub const __unavailable = @compileError("unable to translate macro: undefined identifier `__unavailable__`"); // /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk/usr/include/sys/cdefs.h:244:9
pub const __kpi_unavailable = "";
pub const __kpi_deprecated_arm64_macos_unavailable = "";
pub const __dead = "";
pub const __pure = "";
pub const __restrict = @compileError("unable to translate C expr: unexpected token 'restrict'"); // /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk/usr/include/sys/cdefs.h:266:9
pub const __disable_tail_calls = "";
pub const __not_tail_called = "";
pub const __result_use_check = @compileError("unable to translate macro: undefined identifier `__warn_unused_result__`"); // /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk/usr/include/sys/cdefs.h:322:9
pub const __swift_unavailable = @compileError("unable to translate macro: undefined identifier `__availability__`"); // /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk/usr/include/sys/cdefs.h:332:9
pub inline fn __swift_unavailable_from_async(_msg: anytype) void {
    _ = &_msg;
    return;
}
pub const __swift_nonisolated = "";
pub const __swift_nonisolated_unsafe = "";
pub const __abortlike = __dead2 ++ __cold;
pub const __header_inline = @compileError("unable to translate C expr: unexpected token 'extern'"); // /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk/usr/include/sys/cdefs.h:383:10
pub const __header_always_inline = @compileError("unable to translate macro: undefined identifier `__always_inline__`"); // /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk/usr/include/sys/cdefs.h:392:10
pub const __unreachable_ok_push = @compileError("unable to translate macro: undefined identifier `_Pragma`"); // /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk/usr/include/sys/cdefs.h:411:10
pub const __unreachable_ok_pop = @compileError("unable to translate macro: undefined identifier `_Pragma`"); // /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk/usr/include/sys/cdefs.h:414:10
pub const __printflike = @compileError("unable to translate macro: undefined identifier `__format__`"); // /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk/usr/include/sys/cdefs.h:429:9
pub const __printf0like = @compileError("unable to translate macro: undefined identifier `__format__`"); // /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk/usr/include/sys/cdefs.h:431:9
pub const __scanflike = @compileError("unable to translate macro: undefined identifier `__format__`"); // /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk/usr/include/sys/cdefs.h:433:9
pub const __osloglike = @compileError("unable to translate macro: undefined identifier `__format__`"); // /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk/usr/include/sys/cdefs.h:435:9
pub const __IDSTRING = @compileError("unable to translate C expr: unexpected token 'static'"); // /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk/usr/include/sys/cdefs.h:438:9
pub const __COPYRIGHT = @compileError("unable to translate macro: undefined identifier `copyright`"); // /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk/usr/include/sys/cdefs.h:441:9
pub const __RCSID = @compileError("unable to translate macro: undefined identifier `rcsid`"); // /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk/usr/include/sys/cdefs.h:445:9
pub const __SCCSID = @compileError("unable to translate macro: undefined identifier `sccsid`"); // /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk/usr/include/sys/cdefs.h:449:9
pub const __PROJECT_VERSION = @compileError("unable to translate macro: undefined identifier `project_version`"); // /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk/usr/include/sys/cdefs.h:453:9
pub inline fn __FBSDID(s: anytype) void {
    _ = &s;
    return;
}
pub const __DECONST = @compileError("unable to translate C expr: unexpected token 'const'"); // /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk/usr/include/sys/cdefs.h:462:9
pub const __DEVOLATILE = @compileError("unable to translate C expr: unexpected token 'volatile'"); // /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk/usr/include/sys/cdefs.h:466:9
pub const __DEQUALIFY = @compileError("unable to translate C expr: unexpected token 'const'"); // /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk/usr/include/sys/cdefs.h:470:9
pub const __alloc_align = @compileError("unable to translate macro: undefined identifier `alloc_align`"); // /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk/usr/include/sys/cdefs.h:479:9
pub const __alloc_size = @compileError("unable to translate macro: undefined identifier `alloc_size`"); // /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk/usr/include/sys/cdefs.h:500:9
pub const __has_safe_buffers = @as(c_int, 0);
pub const __unsafe_buffer_usage = "";
pub const __unsafe_buffer_usage_begin = "";
pub const __unsafe_buffer_usage_end = "";
pub const __DARWIN_ONLY_64_BIT_INO_T = @as(c_int, 1);
pub const __DARWIN_ONLY_UNIX_CONFORMANCE = @as(c_int, 1);
pub const __DARWIN_ONLY_VERS_1050 = @as(c_int, 1);
pub const __DARWIN_UNIX03 = @as(c_int, 1);
pub const __DARWIN_64_BIT_INO_T = @as(c_int, 1);
pub const __DARWIN_VERS_1050 = @as(c_int, 1);
pub const __DARWIN_NON_CANCELABLE = @as(c_int, 0);
pub const __DARWIN_SUF_UNIX03 = "";
pub const __DARWIN_SUF_64_BIT_INO_T = "";
pub const __DARWIN_SUF_1050 = "";
pub const __DARWIN_SUF_NON_CANCELABLE = "";
pub const __DARWIN_SUF_EXTSN = "$DARWIN_EXTSN";
pub const __DARWIN_ALIAS = @compileError("unable to translate C expr: unexpected token '__asm'"); // /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk/usr/include/sys/cdefs.h:790:9
pub const __DARWIN_ALIAS_C = @compileError("unable to translate C expr: unexpected token '__asm'"); // /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk/usr/include/sys/cdefs.h:791:9
pub const __DARWIN_ALIAS_I = @compileError("unable to translate C expr: unexpected token '__asm'"); // /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk/usr/include/sys/cdefs.h:792:9
pub const __DARWIN_NOCANCEL = @compileError("unable to translate C expr: unexpected token '__asm'"); // /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk/usr/include/sys/cdefs.h:793:9
pub const __DARWIN_INODE64 = @compileError("unable to translate C expr: unexpected token '__asm'"); // /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk/usr/include/sys/cdefs.h:794:9
pub const __DARWIN_1050 = @compileError("unable to translate C expr: unexpected token '__asm'"); // /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk/usr/include/sys/cdefs.h:796:9
pub const __DARWIN_1050ALIAS = @compileError("unable to translate C expr: unexpected token '__asm'"); // /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk/usr/include/sys/cdefs.h:797:9
pub const __DARWIN_1050ALIAS_C = @compileError("unable to translate C expr: unexpected token '__asm'"); // /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk/usr/include/sys/cdefs.h:798:9
pub const __DARWIN_1050ALIAS_I = @compileError("unable to translate C expr: unexpected token '__asm'"); // /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk/usr/include/sys/cdefs.h:799:9
pub const __DARWIN_1050INODE64 = @compileError("unable to translate C expr: unexpected token '__asm'"); // /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk/usr/include/sys/cdefs.h:800:9
pub const __DARWIN_EXTSN = @compileError("unable to translate C expr: unexpected token '__asm'"); // /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk/usr/include/sys/cdefs.h:802:9
pub const __DARWIN_EXTSN_C = @compileError("unable to translate C expr: unexpected token '__asm'"); // /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk/usr/include/sys/cdefs.h:803:9
pub inline fn __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_2_0(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_2_1(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_2_2(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_3_0(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_3_1(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_3_2(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_4_0(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_4_1(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_4_2(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_4_3(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_5_0(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_5_1(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_6_0(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_6_1(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_7_0(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_7_1(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_8_0(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_8_1(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_8_2(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_8_3(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_8_4(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_9_0(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_9_1(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_9_2(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_9_3(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_10_0(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_10_1(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_10_2(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_10_3(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_11_0(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_11_1(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_11_2(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_11_3(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_11_4(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_12_0(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_12_1(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_12_2(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_12_3(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_12_4(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_13_0(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_13_1(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_13_2(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_13_3(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_13_4(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_13_5(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_13_6(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_13_7(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_14_0(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_14_1(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_14_2(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_14_3(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_14_5(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_14_6(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_14_7(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_14_8(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_15_0(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_15_1(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_15_2(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_15_3(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_15_4(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_15_5(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_15_6(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_15_7(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_15_8(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_16_0(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_16_1(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_16_2(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_16_3(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_16_4(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_16_5(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_16_6(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_16_7(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_17_0(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_17_1(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_17_2(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_17_3(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_17_4(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_17_5(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_17_6(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_17_7(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_18_0(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_18_1(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_18_2(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_18_3(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_18_4(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_18_5(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_18_6(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_19_0(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_26_0(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_26_1(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_26_2(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_26_3(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_26_4(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_26_5(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_10_0(x: anytype) @TypeOf(x) {
    _ = &x;
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_10_1(x: anytype) @TypeOf(x) {
    _ = &x;
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_10_2(x: anytype) @TypeOf(x) {
    _ = &x;
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_10_3(x: anytype) @TypeOf(x) {
    _ = &x;
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_10_4(x: anytype) @TypeOf(x) {
    _ = &x;
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_10_5(x: anytype) @TypeOf(x) {
    _ = &x;
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_10_6(x: anytype) @TypeOf(x) {
    _ = &x;
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_10_7(x: anytype) @TypeOf(x) {
    _ = &x;
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_10_8(x: anytype) @TypeOf(x) {
    _ = &x;
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_10_9(x: anytype) @TypeOf(x) {
    _ = &x;
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_10_10(x: anytype) @TypeOf(x) {
    _ = &x;
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_10_10_2(x: anytype) @TypeOf(x) {
    _ = &x;
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_10_10_3(x: anytype) @TypeOf(x) {
    _ = &x;
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_10_11(x: anytype) @TypeOf(x) {
    _ = &x;
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_10_11_2(x: anytype) @TypeOf(x) {
    _ = &x;
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_10_11_3(x: anytype) @TypeOf(x) {
    _ = &x;
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_10_11_4(x: anytype) @TypeOf(x) {
    _ = &x;
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_10_12(x: anytype) @TypeOf(x) {
    _ = &x;
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_10_12_1(x: anytype) @TypeOf(x) {
    _ = &x;
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_10_12_2(x: anytype) @TypeOf(x) {
    _ = &x;
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_10_12_4(x: anytype) @TypeOf(x) {
    _ = &x;
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_10_13(x: anytype) @TypeOf(x) {
    _ = &x;
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_10_13_1(x: anytype) @TypeOf(x) {
    _ = &x;
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_10_13_2(x: anytype) @TypeOf(x) {
    _ = &x;
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_10_13_4(x: anytype) @TypeOf(x) {
    _ = &x;
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_10_14(x: anytype) @TypeOf(x) {
    _ = &x;
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_10_14_1(x: anytype) @TypeOf(x) {
    _ = &x;
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_10_14_4(x: anytype) @TypeOf(x) {
    _ = &x;
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_10_14_5(x: anytype) @TypeOf(x) {
    _ = &x;
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_10_14_6(x: anytype) @TypeOf(x) {
    _ = &x;
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_10_15(x: anytype) @TypeOf(x) {
    _ = &x;
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_10_15_1(x: anytype) @TypeOf(x) {
    _ = &x;
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_10_15_4(x: anytype) @TypeOf(x) {
    _ = &x;
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_10_16(x: anytype) @TypeOf(x) {
    _ = &x;
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_11_0(x: anytype) @TypeOf(x) {
    _ = &x;
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_11_1(x: anytype) @TypeOf(x) {
    _ = &x;
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_11_3(x: anytype) @TypeOf(x) {
    _ = &x;
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_11_4(x: anytype) @TypeOf(x) {
    _ = &x;
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_11_5(x: anytype) @TypeOf(x) {
    _ = &x;
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_11_6(x: anytype) @TypeOf(x) {
    _ = &x;
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_12_0(x: anytype) @TypeOf(x) {
    _ = &x;
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_12_1(x: anytype) @TypeOf(x) {
    _ = &x;
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_12_2(x: anytype) @TypeOf(x) {
    _ = &x;
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_12_3(x: anytype) @TypeOf(x) {
    _ = &x;
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_12_4(x: anytype) @TypeOf(x) {
    _ = &x;
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_12_5(x: anytype) @TypeOf(x) {
    _ = &x;
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_12_6(x: anytype) @TypeOf(x) {
    _ = &x;
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_12_7(x: anytype) @TypeOf(x) {
    _ = &x;
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_13_0(x: anytype) @TypeOf(x) {
    _ = &x;
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_13_1(x: anytype) @TypeOf(x) {
    _ = &x;
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_13_2(x: anytype) @TypeOf(x) {
    _ = &x;
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_13_3(x: anytype) @TypeOf(x) {
    _ = &x;
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_13_4(x: anytype) @TypeOf(x) {
    _ = &x;
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_13_5(x: anytype) @TypeOf(x) {
    _ = &x;
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_13_6(x: anytype) @TypeOf(x) {
    _ = &x;
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_13_7(x: anytype) @TypeOf(x) {
    _ = &x;
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_14_0(x: anytype) @TypeOf(x) {
    _ = &x;
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_14_1(x: anytype) @TypeOf(x) {
    _ = &x;
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_14_2(x: anytype) @TypeOf(x) {
    _ = &x;
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_14_3(x: anytype) @TypeOf(x) {
    _ = &x;
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_14_4(x: anytype) @TypeOf(x) {
    _ = &x;
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_14_5(x: anytype) @TypeOf(x) {
    _ = &x;
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_14_6(x: anytype) @TypeOf(x) {
    _ = &x;
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_14_7(x: anytype) @TypeOf(x) {
    _ = &x;
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_15_0(x: anytype) @TypeOf(x) {
    _ = &x;
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_15_1(x: anytype) @TypeOf(x) {
    _ = &x;
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_15_2(x: anytype) @TypeOf(x) {
    _ = &x;
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_15_3(x: anytype) @TypeOf(x) {
    _ = &x;
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_15_4(x: anytype) @TypeOf(x) {
    _ = &x;
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_15_5(x: anytype) @TypeOf(x) {
    _ = &x;
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_15_6(x: anytype) @TypeOf(x) {
    _ = &x;
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_16_0(x: anytype) @TypeOf(x) {
    _ = &x;
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_26_0(x: anytype) @TypeOf(x) {
    _ = &x;
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_26_1(x: anytype) @TypeOf(x) {
    _ = &x;
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_26_2(x: anytype) @TypeOf(x) {
    _ = &x;
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_26_3(x: anytype) @TypeOf(x) {
    _ = &x;
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_26_4(x: anytype) @TypeOf(x) {
    _ = &x;
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_26_5(x: anytype) @TypeOf(x) {
    _ = &x;
    return x;
}
pub const __DARWIN_ALIAS_STARTING = @compileError("unable to translate macro: undefined identifier `__DARWIN_ALIAS_STARTING_MAC_`"); // /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk/usr/include/sys/cdefs.h:813:9
pub const ___POSIX_C_DEPRECATED_STARTING_198808L = "";
pub const ___POSIX_C_DEPRECATED_STARTING_199009L = "";
pub const ___POSIX_C_DEPRECATED_STARTING_199209L = "";
pub const ___POSIX_C_DEPRECATED_STARTING_199309L = "";
pub const ___POSIX_C_DEPRECATED_STARTING_199506L = "";
pub const ___POSIX_C_DEPRECATED_STARTING_200112L = "";
pub const ___POSIX_C_DEPRECATED_STARTING_200809L = "";
pub const __POSIX_C_DEPRECATED = @compileError("unable to translate macro: undefined identifier `___POSIX_C_DEPRECATED_STARTING_`"); // /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk/usr/include/sys/cdefs.h:876:9
pub const __DARWIN_C_ANSI = @as(c_long, 0o10000);
pub const __DARWIN_C_FULL = @as(c_long, 900000);
pub const __DARWIN_C_LEVEL = __DARWIN_C_FULL;
pub const __STDC_WANT_LIB_EXT1__ = @as(c_int, 1);
pub const __DARWIN_NO_LONG_LONG = @as(c_int, 0);
pub const _DARWIN_FEATURE_64_BIT_INODE = @as(c_int, 1);
pub const _DARWIN_FEATURE_ONLY_64_BIT_INODE = @as(c_int, 1);
pub const _DARWIN_FEATURE_ONLY_VERS_1050 = @as(c_int, 1);
pub const _DARWIN_FEATURE_ONLY_UNIX_CONFORMANCE = @as(c_int, 1);
pub const _DARWIN_FEATURE_UNIX_CONFORMANCE = @as(c_int, 3);
pub const __CAST_AWAY_QUALIFIER = @compileError("unable to translate macro: undefined identifier `_Pragma`"); // /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk/usr/include/sys/cdefs.h:974:9
pub const __XNU_PRIVATE_EXTERN = @compileError("unable to translate macro: undefined identifier `visibility`"); // /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk/usr/include/sys/cdefs.h:988:9
pub const __has_ptrcheck = @as(c_int, 0);
pub const __single = "";
pub const __unsafe_indexable = "";
pub inline fn __counted_by(N: anytype) void {
    _ = &N;
    return;
}
pub inline fn __counted_by_or_null(N: anytype) void {
    _ = &N;
    return;
}
pub inline fn __sized_by(N: anytype) void {
    _ = &N;
    return;
}
pub inline fn __sized_by_or_null(N: anytype) void {
    _ = &N;
    return;
}
pub inline fn __ended_by(E: anytype) void {
    _ = &E;
    return;
}
pub inline fn __terminated_by(T: anytype) void {
    _ = &T;
    return;
}
pub const __null_terminated = "";
pub inline fn __ptrcheck_abi_assume_single() void {
    return;
}
pub inline fn __ptrcheck_abi_assume_unsafe_indexable() void {
    return;
}
pub inline fn __unsafe_forge_bidi_indexable(T: anytype, P: anytype, S: anytype) @TypeOf(T(P)) {
    _ = &T;
    _ = &P;
    _ = &S;
    return T(P);
}
pub const __unsafe_forge_single = __helpers.CAST_OR_CALL;
pub inline fn __unsafe_forge_terminated_by(T: anytype, P: anytype, E: anytype) @TypeOf(T(P)) {
    _ = &T;
    _ = &P;
    _ = &E;
    return T(P);
}
pub const __unsafe_forge_null_terminated = __helpers.CAST_OR_CALL;
pub inline fn __terminated_by_to_indexable(P: anytype) @TypeOf(P) {
    _ = &P;
    return P;
}
pub inline fn __unsafe_terminated_by_to_indexable(P: anytype) @TypeOf(P) {
    _ = &P;
    return P;
}
pub inline fn __null_terminated_to_indexable(P: anytype) @TypeOf(P) {
    _ = &P;
    return P;
}
pub inline fn __unsafe_null_terminated_to_indexable(P: anytype) @TypeOf(P) {
    _ = &P;
    return P;
}
pub inline fn __unsafe_terminated_by_from_indexable(T: anytype, P: anytype) @TypeOf(P) {
    _ = &T;
    _ = &P;
    return P;
}
pub inline fn __unsafe_null_terminated_from_indexable(P: anytype) @TypeOf(P) {
    _ = &P;
    return P;
}
pub const __array_decay_dicards_count_in_parameters = "";
pub const __ptrcheck_unavailable = "";
pub inline fn __ptrcheck_unavailable_r(REPLACEMENT: anytype) void {
    _ = &REPLACEMENT;
    return;
}
pub const __ASSUME_PTR_ABI_SINGLE_BEGIN = __ptrcheck_abi_assume_single();
pub const __ASSUME_PTR_ABI_SINGLE_END = __ptrcheck_abi_assume_unsafe_indexable();
pub const __header_indexable = "";
pub const __header_bidi_indexable = "";
pub const __compiler_barrier = @compileError("unable to translate C expr: unexpected token '__asm__'"); // /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk/usr/include/sys/cdefs.h:1073:9
pub const __enum_open = "";
pub const __enum_closed = "";
pub const __enum_options = "";
pub const __enum_decl = @compileError("unable to translate C expr: unexpected token 'typedef'"); // /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk/usr/include/sys/cdefs.h:1106:9
pub const __enum_closed_decl = @compileError("unable to translate C expr: unexpected token 'typedef'"); // /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk/usr/include/sys/cdefs.h:1108:9
pub const __options_decl = @compileError("unable to translate C expr: unexpected token 'typedef'"); // /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk/usr/include/sys/cdefs.h:1110:9
pub const __options_closed_decl = @compileError("unable to translate C expr: unexpected token 'typedef'"); // /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk/usr/include/sys/cdefs.h:1112:9
pub const __kernel_ptr_semantics = "";
pub const __kernel_data_semantics = "";
pub const __kernel_dual_semantics = "";
pub const __xnu_data_size = "";
pub const __xnu_returns_data_pointer = "";
pub const _BSD_MACHINE__TYPES_H_ = "";
pub const _BSD_ARM__TYPES_H_ = "";
pub const __DARWIN_NULL = __helpers.cast(?*anyopaque, @as(c_int, 0));
pub const _SYS__PTHREAD_TYPES_H_ = "";
pub const __PTHREAD_SIZE__ = @as(c_int, 8176);
pub const __PTHREAD_ATTR_SIZE__ = @as(c_int, 56);
pub const __PTHREAD_MUTEXATTR_SIZE__ = @as(c_int, 8);
pub const __PTHREAD_MUTEX_SIZE__ = @as(c_int, 56);
pub const __PTHREAD_CONDATTR_SIZE__ = @as(c_int, 8);
pub const __PTHREAD_COND_SIZE__ = @as(c_int, 40);
pub const __PTHREAD_ONCE_SIZE__ = @as(c_int, 8);
pub const __PTHREAD_RWLOCK_SIZE__ = @as(c_int, 192);
pub const __PTHREAD_RWLOCKATTR_SIZE__ = @as(c_int, 16);
pub const __offsetof = @compileError("unable to translate macro: undefined identifier `__builtin_offsetof`"); // /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk/usr/include/sys/_types.h:97:9
pub const _INTPTR_T = "";
pub const _UINTPTR_T = "";
pub const _INTMAX_T = "";
pub const _UINTMAX_T = "";
pub inline fn INT8_C(v: anytype) @TypeOf(v) {
    _ = &v;
    return v;
}
pub inline fn INT16_C(v: anytype) @TypeOf(v) {
    _ = &v;
    return v;
}
pub inline fn INT32_C(v: anytype) @TypeOf(v) {
    _ = &v;
    return v;
}
pub const INT64_C = __helpers.LL_SUFFIX;
pub inline fn UINT8_C(v: anytype) @TypeOf(v) {
    _ = &v;
    return v;
}
pub inline fn UINT16_C(v: anytype) @TypeOf(v) {
    _ = &v;
    return v;
}
pub const UINT32_C = __helpers.U_SUFFIX;
pub const UINT64_C = __helpers.ULL_SUFFIX;
pub const INTMAX_C = __helpers.L_SUFFIX;
pub const UINTMAX_C = __helpers.UL_SUFFIX;
pub const INT8_MAX = @as(c_int, 127);
pub const INT16_MAX = @as(c_int, 32767);
pub const INT32_MAX = __helpers.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const INT64_MAX = @as(c_longlong, 9223372036854775807);
pub const INT8_MIN = -@as(c_int, 128);
pub const INT16_MIN = -__helpers.promoteIntLiteral(c_int, 32768, .decimal);
pub const INT32_MIN = -INT32_MAX - @as(c_int, 1);
pub const INT64_MIN = -INT64_MAX - @as(c_int, 1);
pub const UINT8_MAX = @as(c_int, 255);
pub const UINT16_MAX = __helpers.promoteIntLiteral(c_int, 65535, .decimal);
pub const UINT32_MAX = __helpers.promoteIntLiteral(c_uint, 4294967295, .decimal);
pub const UINT64_MAX = @as(c_ulonglong, 18446744073709551615);
pub const INT_LEAST8_MIN = INT8_MIN;
pub const INT_LEAST16_MIN = INT16_MIN;
pub const INT_LEAST32_MIN = INT32_MIN;
pub const INT_LEAST64_MIN = INT64_MIN;
pub const INT_LEAST8_MAX = INT8_MAX;
pub const INT_LEAST16_MAX = INT16_MAX;
pub const INT_LEAST32_MAX = INT32_MAX;
pub const INT_LEAST64_MAX = INT64_MAX;
pub const UINT_LEAST8_MAX = UINT8_MAX;
pub const UINT_LEAST16_MAX = UINT16_MAX;
pub const UINT_LEAST32_MAX = UINT32_MAX;
pub const UINT_LEAST64_MAX = UINT64_MAX;
pub const INT_FAST8_MIN = INT8_MIN;
pub const INT_FAST16_MIN = INT16_MIN;
pub const INT_FAST32_MIN = INT32_MIN;
pub const INT_FAST64_MIN = INT64_MIN;
pub const INT_FAST8_MAX = INT8_MAX;
pub const INT_FAST16_MAX = INT16_MAX;
pub const INT_FAST32_MAX = INT32_MAX;
pub const INT_FAST64_MAX = INT64_MAX;
pub const UINT_FAST8_MAX = UINT8_MAX;
pub const UINT_FAST16_MAX = UINT16_MAX;
pub const UINT_FAST32_MAX = UINT32_MAX;
pub const UINT_FAST64_MAX = UINT64_MAX;
pub const INTPTR_MAX = __helpers.promoteIntLiteral(c_long, 9223372036854775807, .decimal);
pub const INTPTR_MIN = -INTPTR_MAX - @as(c_int, 1);
pub const UINTPTR_MAX = __helpers.promoteIntLiteral(c_ulong, 18446744073709551615, .decimal);
pub const INTMAX_MAX = INTMAX_C(__helpers.promoteIntLiteral(c_int, 9223372036854775807, .decimal));
pub const UINTMAX_MAX = UINTMAX_C(__helpers.promoteIntLiteral(c_int, 18446744073709551615, .decimal));
pub const INTMAX_MIN = -INTMAX_MAX - @as(c_int, 1);
pub const PTRDIFF_MIN = INTMAX_MIN;
pub const PTRDIFF_MAX = INTMAX_MAX;
pub const SIZE_MAX = UINTPTR_MAX;
pub const RSIZE_MAX = SIZE_MAX >> @as(c_int, 1);
pub const WCHAR_MAX = __WCHAR_MAX__;
pub const WCHAR_MIN = -WCHAR_MAX - @as(c_int, 1);
pub const WINT_MIN = INT32_MIN;
pub const WINT_MAX = INT32_MAX;
pub const SIG_ATOMIC_MIN = INT32_MIN;
pub const SIG_ATOMIC_MAX = INT32_MAX;
pub const @"bool" = bool;
pub const @"true" = @as(c_int, 1);
pub const @"false" = @as(c_int, 0);
pub const __bool_true_false_are_defined = @as(c_int, 1);
pub const __STDC_VERSION_STDARG_H__ = @as(c_int, 0);
pub const va_start = @compileError("unable to translate macro: undefined identifier `__builtin_va_start`"); // zig-pkg/aro-0.0.0-JSD1Qi67OgBha4mHZCopfKKFBHoPsXXMVl5D_sfSZfrw/include/stdarg.h:12:9
pub const va_end = @compileError("unable to translate macro: undefined identifier `__builtin_va_end`"); // zig-pkg/aro-0.0.0-JSD1Qi67OgBha4mHZCopfKKFBHoPsXXMVl5D_sfSZfrw/include/stdarg.h:14:9
pub const va_arg = @compileError("unable to translate macro: undefined identifier `__builtin_va_arg`"); // zig-pkg/aro-0.0.0-JSD1Qi67OgBha4mHZCopfKKFBHoPsXXMVl5D_sfSZfrw/include/stdarg.h:15:9
pub const __va_copy = @compileError("unable to translate macro: undefined identifier `__builtin_va_copy`"); // zig-pkg/aro-0.0.0-JSD1Qi67OgBha4mHZCopfKKFBHoPsXXMVl5D_sfSZfrw/include/stdarg.h:18:9
pub const va_copy = @compileError("unable to translate macro: undefined identifier `__builtin_va_copy`"); // zig-pkg/aro-0.0.0-JSD1Qi67OgBha4mHZCopfKKFBHoPsXXMVl5D_sfSZfrw/include/stdarg.h:22:9
pub const __GNUC_VA_LIST = @as(c_int, 1);
pub const __STDDEF_H__ = "";
pub const __TYPES_H_ = "";
pub const _LIBC_BOUNDS_H_ = "";
pub inline fn _LIBC_COUNT(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn _LIBC_COUNT_OR_NULL(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn _LIBC_SIZE(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn _LIBC_SIZE_OR_NULL(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn _LIBC_ENDED_BY(x: anytype) void {
    _ = &x;
    return;
}
pub const _LIBC_SINGLE = "";
pub const _LIBC_UNSAFE_INDEXABLE = "";
pub const _LIBC_CSTR = "";
pub const _LIBC_NULL_TERMINATED = "";
pub inline fn _LIBC_FLEX_COUNT(FIELD: anytype, INTCOUNT: anytype) @TypeOf(INTCOUNT) {
    _ = &FIELD;
    _ = &INTCOUNT;
    return INTCOUNT;
}
pub inline fn _LIBC_SINGLE_BY_DEFAULT() void {
    return;
}
pub inline fn _LIBC_PTRCHECK_REPLACED(R: anytype) void {
    _ = &R;
    return;
}
pub inline fn _LIBC_FORGE_PTR(P: anytype, S: anytype) @TypeOf(P) {
    _ = &P;
    _ = &S;
    return P;
}
pub const __strfmonlike = @compileError("unable to translate macro: undefined identifier `__format__`"); // /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk/usr/include/_types.h:34:9
pub const __strftimelike = @compileError("unable to translate macro: undefined identifier `__format__`"); // /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk/usr/include/_types.h:36:9
pub const __DARWIN_WCHAR_MAX = __WCHAR_MAX__;
pub const __DARWIN_WCHAR_MIN = -__helpers.promoteIntLiteral(c_int, 0x7fffffff, .hex) - @as(c_int, 1);
pub const __DARWIN_WEOF = __helpers.cast(__darwin_wint_t, -@as(c_int, 1));
pub const _FORTIFY_SOURCE = @as(c_int, 2);
pub const NULL = __DARWIN_NULL;
pub inline fn offsetof(@"type": anytype, field: anytype) @TypeOf(__offsetof(@"type", field)) {
    _ = &@"type";
    _ = &field;
    return __offsetof(@"type", field);
}
pub const _PTRDIFF_T = "";
pub const _BSD_MACHINE_TYPES_H_ = "";
pub const _ARM_MACHTYPES_H_ = "";
pub const _MACHTYPES_H_ = "";
pub const _U_INT8_T = "";
pub const _U_INT16_T = "";
pub const _U_INT32_T = "";
pub const _U_INT64_T = "";
pub const USER_ADDR_NULL = __helpers.cast(user_addr_t, @as(c_int, 0));
pub inline fn CAST_USER_ADDR_T(a_ptr: anytype) user_addr_t {
    _ = &a_ptr;
    return __helpers.cast(user_addr_t, __helpers.cast(usize, a_ptr));
}
pub const _RSIZE_T = "";
pub const _SIZE_T = "";
pub const _WCHAR_T = "";
pub const _WINT_T = "";
pub const CIMGUI_API = "";
pub const CIMGUI_IMPL_API = "";
pub inline fn assert(e: anytype) anyopaque {
    _ = &e;
    return __helpers.cast(anyopaque, @as(c_int, 0));
}
pub const _ASSERT_H_ = "";
pub const static_assert = @compileError("unable to translate C expr: unexpected token '_Static_assert'"); // /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk/usr/include/_static_assert.h:29:9
pub inline fn IM_ASSERT(_EXPR: anytype) @TypeOf(assert(_EXPR)) {
    _ = &_EXPR;
    return assert(_EXPR);
}
pub inline fn IM_COUNTOF(_ARR: anytype) c_int {
    _ = &_ARR;
    return __helpers.cast(c_int, __helpers.div(__helpers.sizeof(_ARR), __helpers.sizeof(_ARR.*)));
}
pub const IM_UNUSED = __helpers.DISCARD;
pub const IM_STRINGIFY_HELPER = @compileError("unable to translate C expr: unexpected token ''"); // ./src-docking/cimgui.h:113:9
pub inline fn IM_STRINGIFY(_EXPR: anytype) @TypeOf(IM_STRINGIFY_HELPER(_EXPR)) {
    _ = &_EXPR;
    return IM_STRINGIFY_HELPER(_EXPR);
}
pub const CIMGUI_CHECKVERSION = @compileError("unable to translate macro: undefined identifier `ImGui_DebugCheckVersionAndDataLayout`"); // ./src-docking/cimgui.h:117:9
pub const IM_FMTARGS = @compileError("unable to translate macro: undefined identifier `format`"); // ./src-docking/cimgui.h:129:9
pub const IM_FMTLIST = @compileError("unable to translate macro: undefined identifier `format`"); // ./src-docking/cimgui.h:130:9
pub const IM_MSVC_RUNTIME_CHECKS_OFF = "";
pub const IM_MSVC_RUNTIME_CHECKS_RESTORE = "";
pub const ImTextureID_Invalid = __helpers.cast(ImTextureID, @as(c_int, 0));
pub const IMGUI_PAYLOAD_TYPE_COLOR_3F = "_COL3F";
pub const IMGUI_PAYLOAD_TYPE_COLOR_4F = "_COL4F";
pub const IMGUI_DEBUG_LOG = @compileError("unable to translate macro: undefined identifier `ImGui_DebugLog`"); // ./src-docking/cimgui.h:2465:9
pub const CIM_ALLOC = @compileError("unable to translate macro: undefined identifier `ImGui_MemAlloc`"); // ./src-docking/cimgui.h:2478:9
pub const CIM_FREE = @compileError("unable to translate macro: undefined identifier `ImGui_MemFree`"); // ./src-docking/cimgui.h:2479:9
pub const IM_UNICODE_CODEPOINT_INVALID = __helpers.promoteIntLiteral(c_int, 0xFFFD, .hex);
pub const IM_UNICODE_CODEPOINT_MAX = __helpers.promoteIntLiteral(c_int, 0xFFFF, .hex);
pub const IM_COL32_R_SHIFT = @as(c_int, 0);
pub const IM_COL32_G_SHIFT = @as(c_int, 8);
pub const IM_COL32_B_SHIFT = @as(c_int, 16);
pub const IM_COL32_A_SHIFT = @as(c_int, 24);
pub const IM_COL32_A_MASK = __helpers.promoteIntLiteral(c_int, 0xFF000000, .hex);
pub inline fn IM_COL32(R: anytype, G: anytype, B: anytype, A: anytype) @TypeOf((((__helpers.cast(ImU32, A) << IM_COL32_A_SHIFT) | (__helpers.cast(ImU32, B) << IM_COL32_B_SHIFT)) | (__helpers.cast(ImU32, G) << IM_COL32_G_SHIFT)) | (__helpers.cast(ImU32, R) << IM_COL32_R_SHIFT)) {
    _ = &R;
    _ = &G;
    _ = &B;
    _ = &A;
    return (((__helpers.cast(ImU32, A) << IM_COL32_A_SHIFT) | (__helpers.cast(ImU32, B) << IM_COL32_B_SHIFT)) | (__helpers.cast(ImU32, G) << IM_COL32_G_SHIFT)) | (__helpers.cast(ImU32, R) << IM_COL32_R_SHIFT);
}
pub const IM_COL32_WHITE = IM_COL32(@as(c_int, 255), @as(c_int, 255), @as(c_int, 255), @as(c_int, 255));
pub const IM_COL32_BLACK = IM_COL32(@as(c_int, 0), @as(c_int, 0), @as(c_int, 0), @as(c_int, 255));
pub const IM_COL32_BLACK_TRANS = IM_COL32(@as(c_int, 0), @as(c_int, 0), @as(c_int, 0), @as(c_int, 0));
pub const IM_DRAWLIST_TEX_LINES_WIDTH_MAX = @as(c_int, 32);
pub const ImFontAtlasRectId_Invalid = -@as(c_int, 1);
pub const ImDrawCallback_ResetRenderState = __helpers.cast(ImDrawCallback, -@as(c_int, 8));
pub const IM_ARRAYSIZE = IM_COUNTOF;
pub const __darwin_pthread_handler_rec = struct___darwin_pthread_handler_rec;
pub const _opaque_pthread_attr_t = struct__opaque_pthread_attr_t;
pub const _opaque_pthread_cond_t = struct__opaque_pthread_cond_t;
pub const _opaque_pthread_condattr_t = struct__opaque_pthread_condattr_t;
pub const _opaque_pthread_mutex_t = struct__opaque_pthread_mutex_t;
pub const _opaque_pthread_mutexattr_t = struct__opaque_pthread_mutexattr_t;
pub const _opaque_pthread_once_t = struct__opaque_pthread_once_t;
pub const _opaque_pthread_rwlock_t = struct__opaque_pthread_rwlock_t;
pub const _opaque_pthread_rwlockattr_t = struct__opaque_pthread_rwlockattr_t;
pub const _opaque_pthread_t = struct__opaque_pthread_t;
pub const ImVec2_t = struct_ImVec2_t;
pub const ImVec4_t = struct_ImVec4_t;
pub const ImTextureRect_t = struct_ImTextureRect_t;
pub const ImVector_ImTextureRect_t = struct_ImVector_ImTextureRect_t;
pub const ImTextureData_t = struct_ImTextureData_t;
pub const ImTextureRef_t = struct_ImTextureRef_t;
pub const ImGuiTextFilter_ImGuiTextRange_t = struct_ImGuiTextFilter_ImGuiTextRange_t;
pub const ImVector_ImGuiTextRange_t = struct_ImVector_ImGuiTextRange_t;
pub const ImVector_char_t = struct_ImVector_char_t;
pub const ImGuiStoragePair_t = struct_ImGuiStoragePair_t;
pub const ImVector_ImGuiStoragePair_t = struct_ImVector_ImGuiStoragePair_t;
pub const ImGuiSelectionRequest_t = struct_ImGuiSelectionRequest_t;
pub const ImVector_ImGuiSelectionRequest_t = struct_ImVector_ImGuiSelectionRequest_t;
pub const ImVector_ImDrawIdx_t = struct_ImVector_ImDrawIdx_t;
pub const ImDrawVert_t = struct_ImDrawVert_t;
pub const ImVector_ImDrawVert_t = struct_ImVector_ImDrawVert_t;
pub const ImDrawListSharedData_t = struct_ImDrawListSharedData_t;
pub const ImVector_ImVec2_t = struct_ImVector_ImVec2_t;
pub const ImDrawCmdHeader_t = struct_ImDrawCmdHeader_t;
pub const ImDrawListSplitter_t = struct_ImDrawListSplitter_t;
pub const ImVector_ImVec4_t = struct_ImVector_ImVec4_t;
pub const ImVector_ImTextureRef_t = struct_ImVector_ImTextureRef_t;
pub const ImVector_ImU8_t = struct_ImVector_ImU8_t;
pub const ImDrawList_t = struct_ImDrawList_t;
pub const ImDrawCmd_t = struct_ImDrawCmd_t;
pub const ImVector_ImDrawCmd_t = struct_ImVector_ImDrawCmd_t;
pub const ImDrawChannel_t = struct_ImDrawChannel_t;
pub const ImVector_ImDrawChannel_t = struct_ImVector_ImDrawChannel_t;
pub const ImVector_ImDrawListPtr_t = struct_ImVector_ImDrawListPtr_t;
pub const ImVector_ImU32_t = struct_ImVector_ImU32_t;
pub const ImVector_ImWchar_t = struct_ImVector_ImWchar_t;
pub const ImVector_float_t = struct_ImVector_float_t;
pub const ImVector_ImU16_t = struct_ImVector_ImU16_t;
pub const ImFontGlyph_t = struct_ImFontGlyph_t;
pub const ImVector_ImFontGlyph_t = struct_ImVector_ImFontGlyph_t;
pub const ImFontBaked_t = struct_ImFontBaked_t;
pub const ImVector_ImTextureDataPtr_t = struct_ImVector_ImTextureDataPtr_t;
pub const ImFontLoader_t = struct_ImFontLoader_t;
pub const ImFontConfig_t = struct_ImFontConfig_t;
pub const ImVector_ImFontConfig_t = struct_ImVector_ImFontConfig_t;
pub const ImVector_ImDrawListSharedDataPtr_t = struct_ImVector_ImDrawListSharedDataPtr_t;
pub const ImFontAtlasBuilder_t = struct_ImFontAtlasBuilder_t;
pub const ImGuiContext_t = struct_ImGuiContext_t;
pub const ImFontAtlasRect_t = struct_ImFontAtlasRect_t;
pub const ImFontAtlas_t = struct_ImFontAtlas_t;
pub const ImVector_ImFontConfigPtr_t = struct_ImVector_ImFontConfigPtr_t;
pub const ImGuiStorage_t = struct_ImGuiStorage_t;
pub const ImFont_t = struct_ImFont_t;
pub const ImVector_ImFontPtr_t = struct_ImVector_ImFontPtr_t;
pub const ImGuiPlatformMonitor_t = struct_ImGuiPlatformMonitor_t;
pub const ImVector_ImGuiPlatformMonitor_t = struct_ImVector_ImGuiPlatformMonitor_t;
pub const ImDrawData_t = struct_ImDrawData_t;
pub const ImGuiViewport_t = struct_ImGuiViewport_t;
pub const ImVector_ImGuiViewportPtr_t = struct_ImVector_ImGuiViewportPtr_t;
pub const ImFontGlyphRangesBuilder_t = struct_ImFontGlyphRangesBuilder_t;
pub const ImColor_t = struct_ImColor_t;
pub const ImGuiKeyData_t = struct_ImGuiKeyData_t;
pub const ImGuiIO_t = struct_ImGuiIO_t;
pub const ImGuiInputTextCallbackData_t = struct_ImGuiInputTextCallbackData_t;
pub const ImGuiListClipper_t = struct_ImGuiListClipper_t;
pub const ImGuiMultiSelectIO_t = struct_ImGuiMultiSelectIO_t;
pub const ImGuiPayload_t = struct_ImGuiPayload_t;
pub const ImGuiPlatformImeData_t = struct_ImGuiPlatformImeData_t;
pub const ImGuiPlatformIO_t = struct_ImGuiPlatformIO_t;
pub const ImGuiSelectionBasicStorage_t = struct_ImGuiSelectionBasicStorage_t;
pub const ImGuiSelectionExternalStorage_t = struct_ImGuiSelectionExternalStorage_t;
pub const ImGuiSizeCallbackData_t = struct_ImGuiSizeCallbackData_t;
pub const ImGuiStyle_t = struct_ImGuiStyle_t;
pub const ImGuiTableColumnSortSpecs_t = struct_ImGuiTableColumnSortSpecs_t;
pub const ImGuiTableSortSpecs_t = struct_ImGuiTableSortSpecs_t;
pub const ImGuiTextBuffer_t = struct_ImGuiTextBuffer_t;
pub const ImGuiTextFilter_t = struct_ImGuiTextFilter_t;
pub const ImGuiWindowClass_t = struct_ImGuiWindowClass_t;
