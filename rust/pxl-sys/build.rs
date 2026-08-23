/// Locates and statically links libpxl.a from a zig build. Searches in order:
/// 1. PXL_LIB_DIR environment variable (path to directory containing libpxl.a)
/// 2. ../zig-out/lib relative to the crate root
fn main() {
    // Compute the project root from the crate manifest directory.
    // rust/pxl-sys/Cargo.toml → rust/pxl-sys → rust → project root.
    let crate_root = std::env::var("CARGO_MANIFEST_DIR").unwrap();
    let project_root = std::path::Path::new(&crate_root)
        .parent() // pxl-sys/
        .unwrap()
        .parent() // rust/
        .unwrap();

    let lib_dir = std::env::var("PXL_LIB_DIR")
        .ok()
        .or_else(|| {
            let relative = project_root.join("zig-out").join("lib");
            if relative.exists() {
                Some(relative.to_string_lossy().to_string())
            } else {
                None
            }
        })
        .expect("libpxl.a not found. Set PXL_LIB_DIR or run `zig build lib` in the project root.");

    println!("cargo:rustc-link-search=native={}", lib_dir);
    // sokol's C code is a separate archive that libpxl.a links against.
    println!("cargo:rustc-link-lib=static=pxl");
    println!("cargo:rustc-link-lib=static=sokol_clib");

    // Export the project root so pxl_game! / simple_game! can chdir at launch.
    println!(
        "cargo:rustc-env=PXL_PROJECT_ROOT={}",
        project_root.display()
    );

    // macOS system frameworks required by sokol
    let target_os = std::env::var("CARGO_CFG_TARGET_OS").unwrap();
    if target_os == "macos" {
        // Force-load Objective-C classes/categories from the static archives
        // (sokol_app is ObjC on macOS); without this the linker drops them.
        println!("cargo:rustc-link-arg=-Wl,-ObjC");
        println!("cargo:rustc-link-lib=framework=Foundation");
        println!("cargo:rustc-link-lib=framework=Metal");
        println!("cargo:rustc-link-lib=framework=QuartzCore");
        println!("cargo:rustc-link-lib=framework=AppKit");
        println!("cargo:rustc-link-lib=framework=AudioToolbox");
        println!("cargo:rustc-link-lib=framework=GameController");
    }
}
