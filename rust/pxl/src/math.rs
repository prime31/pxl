/// Conversions between glam and pxl C types.

use glam::{Vec2, Vec4};

pub use pxl_sys::PxlAnimCell as AnimCell;

use pxl_sys::{PxlColor, PxlRect, PxlVec2};

use crate::Color;

#[allow(dead_code)]
pub(crate) fn to_pxl_vec2(v: Vec2) -> PxlVec2 {
    PxlVec2 { x: v.x, y: v.y }
}

#[allow(dead_code)]
pub(crate) fn to_pxl_rect(r: crate::draw::Rect) -> PxlRect {
    PxlRect {
        x: r.x,
        y: r.y,
        w: r.w,
        h: r.h,
    }
}

pub(crate) fn to_color(c: Color) -> PxlColor {
    c.0
}

#[allow(dead_code)]
pub(crate) fn to_vec4(c: Color) -> Vec4 {
    Vec4::new(
        (c.0 & 0xFF) as f32 / 255.0,
        ((c.0 >> 8) & 0xFF) as f32 / 255.0,
        ((c.0 >> 16) & 0xFF) as f32 / 255.0,
        ((c.0 >> 24) & 0xFF) as f32 / 255.0,
    )
}

// ── Enums ────────────────────────────────────────────────────────────────────

#[repr(i32)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Anchor {
    Center = 0,
    TopLeft = 1,
    TopCenter = 2,
    TopRight = 3,
    CenterLeft = 4,
    CenterRight = 5,
    BottomLeft = 6,
    BottomCenter = 7,
    BottomRight = 8,
}

#[repr(i32)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum BlendMode {
    None = 0,
    Alpha = 1,
    Add = 2,
    Multiply = 3,
}

#[repr(i32)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum SfxPreset {
    Coin = 0,
    Laser = 1,
    Explosion = 2,
    Powerup = 3,
    Hurt = 4,
    Jump = 5,
    Blip = 6,
    Tone = 7,
}

#[repr(i32)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum LoopMode {
    Loop = 0,
    Once = 1,
    ClampForever = 2,
    PingPong = 3,
    PingPongOnce = 4,
    Reverse = 5,
    ReverseOnce = 6,
}

#[repr(i32)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Keycode {
    Space = 32,
    Apostrophe = 39,
    Comma = 44,
    Minus = 45,
    Period = 46,
    Slash = 47,
    Key0 = 48,
    Key1 = 49,
    Key2 = 50,
    Key3 = 51,
    Key4 = 52,
    Key5 = 53,
    Key6 = 54,
    Key7 = 55,
    Key8 = 56,
    Key9 = 57,
    Semicolon = 59,
    Equal = 61,
    A = 65,
    B = 66,
    C = 67,
    D = 68,
    E = 69,
    F = 70,
    G = 71,
    H = 72,
    I = 73,
    J = 74,
    K = 75,
    L = 76,
    M = 77,
    N = 78,
    O = 79,
    P = 80,
    Q = 81,
    R = 82,
    S = 83,
    T = 84,
    U = 85,
    V = 86,
    W = 87,
    X = 88,
    Y = 89,
    Z = 90,
    LeftBracket = 91,
    Backslash = 92,
    RightBracket = 93,
    GraveAccent = 96,
    Escape = 256,
    Enter = 257,
    Tab = 258,
    Backspace = 259,
    Insert = 260,
    Delete = 261,
    Right = 262,
    Left = 263,
    Down = 264,
    Up = 265,
    PageUp = 266,
    PageDown = 267,
    Home = 268,
    End = 269,
    CapsLock = 280,
    ScrollLock = 281,
    NumLock = 282,
    PrintScreen = 283,
    Pause = 284,
    F1 = 290,
    F2 = 291,
    F3 = 292,
    F4 = 293,
    F5 = 294,
    F6 = 295,
    F7 = 296,
    F8 = 297,
    F9 = 298,
    F10 = 299,
    F11 = 300,
    F12 = 301,
    Kp0 = 320,
    Kp1 = 321,
    Kp2 = 322,
    Kp3 = 323,
    Kp4 = 324,
    Kp5 = 325,
    Kp6 = 326,
    Kp7 = 327,
    Kp8 = 328,
    Kp9 = 329,
    KpDecimal = 330,
    KpDivide = 331,
    KpMultiply = 332,
    KpSubtract = 333,
    KpAdd = 334,
    KpEnter = 335,
    KpEqual = 336,
    LeftShift = 340,
    LeftControl = 341,
    LeftAlt = 342,
    LeftSuper = 343,
    RightShift = 344,
    RightControl = 345,
    RightAlt = 346,
    RightSuper = 347,
}

#[repr(i32)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum MouseButton {
    Left = 0,
    Right = 1,
    Middle = 2,
}

#[repr(i32)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ResolutionPolicy {
    Default = 0,
    NoBorder = 1,
    NoBorderPixelPerfect = 2,
    ShowAll = 3,
    ShowAllPixelPerfect = 4,
    BestFit = 5,
}

/// How to normalize diagonals in `input::get_vector`.
#[repr(i32)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum AxisDiagonal {
    Raw = 0,
    Normalized = 1,
    Square = 2,
    Digital = 3,
}

