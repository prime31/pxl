//! Render pass management — mirrors `pxl.beginPass` / `pxl.endPass`.

use pxl_sys;

use crate::Color;

pub struct Pass {
    pub clear_color: Option<Color>,
    pub camera: Option<Camera>,
    pub pixel_snap: bool,
}

impl Default for Pass {
    fn default() -> Self {
        Self {
            clear_color: Some(Color::BLACK),
            camera: None,
            pixel_snap: true,
        }
    }
}

pub struct Camera {
    pub offset_x: f32,
    pub offset_y: f32,
    pub zoom: f32,
    pub rotation: f32,
}

impl Camera {
    pub fn new(offset_x: f32, offset_y: f32) -> Self {
        Self {
            offset_x,
            offset_y,
            zoom: 1.0,
            rotation: 0.0,
        }
    }

    pub fn with_zoom(mut self, zoom: f32) -> Self {
        self.zoom = zoom;
        self
    }

    pub fn with_rotation(mut self, rotation: f32) -> Self {
        self.rotation = rotation;
        self
    }
}

pub fn begin(pass: Pass) {
    let c_pass = pxl_sys::PxlPass {
        clear_color_value: pass.clear_color.map_or(0, |c| c.0),
        has_clear_color: pass.clear_color.is_some(),
        has_camera: pass.camera.is_some(),
        cam_offset_x: pass.camera.as_ref().map_or(0.0, |c| c.offset_x),
        cam_offset_y: pass.camera.as_ref().map_or(0.0, |c| c.offset_y),
        cam_zoom: pass.camera.as_ref().map_or(1.0, |c| c.zoom),
        cam_rotation: pass.camera.as_ref().map_or(0.0, |c| c.rotation),
        pixel_snap: pass.pixel_snap,
    };
    unsafe { pxl_sys::pxl_pass_begin(c_pass) };
}

pub fn end() {
    unsafe { pxl_sys::pxl_pass_end() };
}