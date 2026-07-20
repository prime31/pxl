use std::{panic::AssertUnwindSafe, pin::Pin};

use glam::Vec2;
use miniquad::{EventHandler, KeyCode, KeyMods, MouseButton, conf, date};

use crate::{CONTEXT, Context, MiniquadInputEvent, get_context};

pub struct App {
    update: fn(),
}

impl App {
    pub fn run(setup: fn(), update: fn()) {
        let mut conf = conf::Conf::default();
        let metal = std::env::args().nth(1).as_deref() == Some("metal");
        conf.platform.apple_gfx_api = if metal {
            conf::AppleGfxApi::Metal
        } else {
            conf::AppleGfxApi::OpenGl
        };

        miniquad::start(conf, move || {
            let context = Context::new(miniquad::FilterMode::Nearest, 0, 0);
            unsafe { CONTEXT = Some(context) };

            setup();
            Box::new(App { update })
        });
    }
}

impl EventHandler for App {
    fn update(&mut self) {
        // Unless called every frame, cursor will not remain grabbed
        miniquad::window::set_cursor_grab(get_context().cursor_grabbed);

        #[cfg(not(target_arch = "wasm32"))]
        {
            // TODO: consider making it a part of miniquad?
            std::thread::yield_now();
        }
        (self.update)()
    }

    fn draw(&mut self) {
        {
            {
                get_context().begin_frame();
            }

            {
                get_context().end_frame();
            }

            get_context().frame_time = date::now() - get_context().last_frame_time;
            get_context().last_frame_time = date::now();

            // glFinish waits until the drawing is done. See https://registry.khronos.org/OpenGL-Refpages/gl4/html/glFinish.xhtml.
            // Some drivers do this by a busy loop which increases CPU usage to close to 100%.
            // For discussion see https://github.com/not-fl3/macroquad/issues/275.
            // If telemetry is enabled it kinda makes sense to call glFinish so that the telemetry
            // timing is more representative of the time it took to draw. But for general use and
            // in particular when double buffer is used it's not recommended to call glFinish,
            // unless we use SyncObjects or we have to wait for other async operations to finish.
            // See https://wikis.khronos.org/opengl/Common_Mistakes#glFinish_and_glFlush.
            #[cfg(any(target_arch = "wasm32", target_os = "linux"))]
            if telemetry::is_enabled() {
                let _z = telemetry::ZoneGuard::new("glFinish/glFLush");
                unsafe {
                    miniquad::gl::glFlush();
                    miniquad::gl::glFinish();
                }
            }
        }
    }

    fn resize_event(&mut self, width: f32, height: f32) {
        get_context().screen_width = width;
        get_context().screen_height = height;

        if miniquad::window::blocking_event_loop() {
            miniquad::window::schedule_update();
        }
    }

    fn raw_mouse_motion(&mut self, x: f32, y: f32) {
        let context = get_context();

        if context.cursor_grabbed {
            context.mouse_position += Vec2::new(x, y);

            let event = MiniquadInputEvent::MouseMotion {
                x: context.mouse_position.x,
                y: context.mouse_position.y,
            };
            context
                .input_events
                .iter_mut()
                .for_each(|arr| arr.push(event.clone()));
        }
    }

    fn mouse_motion_event(&mut self, x: f32, y: f32) {
        let context = get_context();

        if !context.cursor_grabbed {
            context.mouse_position = Vec2::new(x, y);

            context
                .input_events
                .iter_mut()
                .for_each(|arr| arr.push(MiniquadInputEvent::MouseMotion { x, y }));
        }
    }

    fn mouse_wheel_event(&mut self, x: f32, y: f32) {
        let context = get_context();

        context.mouse_wheel.x = x;
        context.mouse_wheel.y = y;

        context
            .input_events
            .iter_mut()
            .for_each(|arr| arr.push(MiniquadInputEvent::MouseWheel { x, y }));
    }

    fn mouse_button_down_event(&mut self, btn: MouseButton, x: f32, y: f32) {
        let context = get_context();

        context.mouse_down.insert(btn);
        context.mouse_pressed.insert(btn);

        context
            .input_events
            .iter_mut()
            .for_each(|arr| arr.push(MiniquadInputEvent::MouseButtonDown { x, y, btn }));

        if !context.cursor_grabbed {
            context.mouse_position = Vec2::new(x, y);
        }
    }

    fn mouse_button_up_event(&mut self, btn: MouseButton, x: f32, y: f32) {
        let context = get_context();
        //     println!("btn = {}", btn as u32);
        context.mouse_down.remove(&btn);
        context.mouse_released.insert(btn);

        context
            .input_events
            .iter_mut()
            .for_each(|arr| arr.push(MiniquadInputEvent::MouseButtonUp { x, y, btn }));

        if !context.cursor_grabbed {
            context.mouse_position = Vec2::new(x, y);
        }
    }

    fn mouse_leave_event(&mut self) {
        let context = get_context();
        context.mouse_released.extend(context.mouse_down.drain());
    }

    fn mouse_enter_event(&mut self, btn: MouseButton, x: f32, y: f32) {
        let context = get_context();

        if !context.cursor_grabbed {
            context.mouse_position = Vec2::new(x, y);
        }

        context
            .input_events
            .iter_mut()
            .for_each(|arr| arr.push(MiniquadInputEvent::MouseButtonUp { x, y, btn }));
        if btn != MouseButton::Unknown {
            context.mouse_down.insert(btn);
            context.mouse_pressed.insert(btn);
        }
    }

    fn char_event(&mut self, character: char, modifiers: KeyMods, repeat: bool) {
        let context = get_context();

        context.chars_pressed_queue.push_back(character);
        context.chars_pressed_ui_queue.push_back(character);

        context.input_events.iter_mut().for_each(|arr| {
            arr.push(MiniquadInputEvent::Char {
                character,
                modifiers,
                repeat,
            });
        });
    }

    fn key_down_event(&mut self, keycode: KeyCode, modifiers: KeyMods, repeat: bool) {
        let context = get_context();
        context.keys_down.insert(keycode);
        if repeat == false {
            context.keys_pressed.insert(keycode);
        }

        context.input_events.iter_mut().for_each(|arr| {
            arr.push(MiniquadInputEvent::KeyDown {
                keycode,
                modifiers,
                repeat,
            });
        });
    }

    fn key_up_event(&mut self, keycode: KeyCode, modifiers: KeyMods) {
        let context = get_context();
        context.keys_down.remove(&keycode);
        context.keys_released.insert(keycode);

        context
            .input_events
            .iter_mut()
            .for_each(|arr| arr.push(MiniquadInputEvent::KeyUp { keycode, modifiers }));

        // if miniquad::window::blocking_event_loop() {
        //     miniquad::window::schedule_update();
        // }
    }

    fn window_restored_event(&mut self) {
        let context = get_context();

        #[cfg(target_os = "android")]
        context.audio_context.resume();
        #[cfg(target_os = "android")]
        if miniquad::window::blocking_event_loop() {
            miniquad::window::schedule_update();
        }

        context
            .input_events
            .iter_mut()
            .for_each(|arr| arr.push(MiniquadInputEvent::WindowRestored));
    }

    fn window_minimized_event(&mut self) {
        let context = get_context();

        #[cfg(target_os = "android")]
        context.audio_context.pause();

        // Clear held down keys and button and announce them as released
        context.mouse_released.extend(context.mouse_down.drain());
        context.keys_released.extend(context.keys_down.drain());

        context
            .input_events
            .iter_mut()
            .for_each(|arr| arr.push(MiniquadInputEvent::WindowMinimized));
    }

    fn quit_requested_event(&mut self) {
        let context = get_context();
        if context.prevent_quit_event {
            miniquad::window::cancel_quit();
            context.quit_requested = true;
        }
    }
}
