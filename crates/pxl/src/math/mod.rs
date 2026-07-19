use glam::vec2;
pub use glam::{Affine2, IVec2, Mat3, Vec2};

mod circle;
mod color;
mod rect;

pub use circle::Circle;
pub use color::{Color, colors::*};
pub use rect::{Rect, RectOffset};

/// Converts 2d polar coordinates to 2d cartesian coordinates.
pub fn polar_to_cartesian(rho: f32, theta: f32) -> Vec2 {
    vec2(rho * theta.cos(), rho * theta.sin())
}

/// Converts 2d cartesian coordinates to 2d polar coordinates.
pub fn cartesian_to_polar(cartesian: Vec2) -> Vec2 {
    vec2(
        (cartesian.x.powi(2) + cartesian.y.powi(2)).sqrt(),
        cartesian.y.atan2(cartesian.x),
    )
}
