/// pxl color, stored as RGBA packed u32 (0xAABBGGRR). Use the constants or
/// `Color::rgba(r, g, b, a)` for custom colors.

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Color(pub u32);

impl Default for Color {
    fn default() -> Color {
        Color::WHITE
    }
}

impl Color {
    pub const WHITE: Self = Self(0xFFFF_FFFF);
    pub const BLACK: Self = Self(0xFF00_0000);
    pub const TRANSPARENT: Self = Self(0x0000_0000);
    pub const RED: Self = Self(0xFFE6_2937);
    pub const GREEN: Self = Self(0xFF00_E430);
    pub const BLUE: Self = Self(0xFF00_79F1);
    pub const YELLOW: Self = Self(0xFFFD_F900);
    pub const MAGENTA: Self = Self(0xFFFF_00FF);
    pub const CYAN: Self = Self(0xFF00_FFFF);
    pub const ORANGE: Self = Self(0xFFFF_A100);
    pub const PINK: Self = Self(0xFFFF_6DC2);
    pub const PURPLE: Self = Self(0xFFC8_7AFF);
    pub const GRAY: Self = Self(0xFF82_8282);
    pub const AYA: Self = Self(0xFFCC_334D);

    pub const fn rgba(r: u8, g: u8, b: u8, a: u8) -> Self {
        Self((r as u32) | ((g as u32) << 8) | ((b as u32) << 16) | ((a as u32) << 24))
    }

    pub const fn rgb(r: u8, g: u8, b: u8) -> Self {
        Self::rgba(r, g, b, 255)
    }
}
