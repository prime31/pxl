//! Audio — mirrors `pxl.audio.*` in Zig.

use pxl_sys;

use crate::SfxPreset;

/// Loaded sound handle. 0 = invalid. Drop to unload.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Sound(pub u64);

impl Sound {
    /// Consume the handle to unload. Same as letting it drop.
    pub fn unload(self) {
        if self.0 != 0 {
            unsafe { pxl_sys::pxl_audio_unload(self.0) };
        }
    }
}

impl Drop for Sound {
    fn drop(&mut self) {
        if self.0 != 0 {
            unsafe { pxl_sys::pxl_audio_unload(self.0) };
        }
    }
}

/// Active playback handle. 0 = invalid. Drop to stop.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Playback(pub u64);

// NOTE: no Drop impl — dropping a Playback handle does NOT stop playback.
// One-shot sfxr and play_one_shot sounds play to completion; call .stop()
// explicitly if you need to interrupt a looping or streamed playback.

impl Playback {
    pub fn is_playing(&self) -> bool {
        self.0 != 0 && unsafe { pxl_sys::pxl_audio_is_playing(self.0) }
    }

    pub fn stop(mut self) {
        if self.0 != 0 {
            unsafe { pxl_sys::pxl_audio_stop(self.0) };
            self.0 = 0;
        }
    }

    pub fn position(&self) -> f64 {
        if self.0 == 0 { return 0.0; }
        unsafe { pxl_sys::pxl_audio_playback_position(self.0) }
    }

    pub fn duration(&self) -> f64 {
        if self.0 == 0 { return 0.0; }
        unsafe { pxl_sys::pxl_audio_playback_duration(self.0) }
    }
}

pub struct PlayOptions {
    pub volume: f32,
    pub pan: f32,
    pub pitch: f32,
    pub loop_: bool,
}

impl Default for PlayOptions {
    fn default() -> Self {
        Self { volume: 1.0, pan: 0.0, pitch: 1.0, loop_: false }
    }
}

pub fn load(path: &str, streamed: bool) -> Option<Sound> {
    let c = std::ffi::CString::new(path).unwrap();
    let handle = unsafe { pxl_sys::pxl_audio_load(c.as_ptr(), streamed) };
    if handle == 0 { None } else { Some(Sound(handle)) }
}

pub fn play(sound: &Sound, opts: PlayOptions) -> Option<Playback> {
    let handle = unsafe {
        pxl_sys::pxl_audio_play(sound.0, opts.volume, opts.pan, opts.pitch, opts.loop_)
    };
    if handle == 0 { None } else { Some(Playback(handle)) }
}

pub fn play_one_shot(sound: &Sound, opts: PlayOptions) {
    unsafe { pxl_sys::pxl_audio_play_one_shot(sound.0, opts.volume, opts.pan, opts.pitch) };
}

pub fn sfx(preset: SfxPreset, opts: PlayOptions) -> Option<Playback> {
    let handle = unsafe {
        pxl_sys::pxl_audio_sfx(preset as i32, opts.volume, opts.pan, opts.pitch)
    };
    if handle == 0 { None } else { Some(Playback(handle)) }
}

impl Sound {
    pub fn duration(&self) -> f64 {
        if self.0 == 0 { return 0.0; }
        unsafe { pxl_sys::pxl_audio_sound_duration(self.0) }
    }
}