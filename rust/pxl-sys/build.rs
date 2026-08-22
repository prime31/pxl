/// Detects and links libpxl.dylib from a zig build. Searches in order:
/// 1. PXL_LIB_DIR environment variable (path to directory containing libpxl.dylib)
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
        .expect(
            "libpxl.dylib not found. Set PXL_LIB_DIR or run `zig build lib` in the project root.",
        );

    println!("cargo:rustc-link-search=native={}", lib_dir);
    println!("cargo:rustc-link-lib=dylib=pxl");

    // Embed runpaths so the binary can find libpxl.dylib at runtime.
    println!("cargo:rustc-link-arg=-Wl,-rpath,{}", lib_dir);
    println!("cargo:rustc-link-arg=-Wl,-rpath,@loader_path/../../../zig-out/lib");

    // Export the project root so pxl_game! / simple_game! can chdir at launch.
    println!(
        "cargo:rustc-env=PXL_PROJECT_ROOT={}",
        project_root.display()
    );

    // macOS system frameworks required by sokol
    let target_os = std::env::var("CARGO_CFG_TARGET_OS").unwrap();
    if target_os == "macos" {
        println!("cargo:rustc-link-lib=framework=Foundation");
        println!("cargo:rustc-link-lib=framework=Metal");
        println!("cargo:rustc-link-lib=framework=QuartzCore");
        println!("cargo:rustc-link-lib=framework=AppKit");
        println!("cargo:rustc-link-lib=framework=AudioToolbox");
        println!("cargo:rustc-link-lib=framework=GameController");
    }
}