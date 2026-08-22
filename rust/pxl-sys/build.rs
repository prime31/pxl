/// Detects and links libpxl.dylib from a zig build. Searches in order:
/// 1. PXL_LIB_DIR environment variable (path to directory containing libpxl.dylib)
/// 2. ../zig-out/lib relative to the crate root
fn main() {
    let lib_dir = std::env::var("PXL_LIB_DIR")
        .or_else(|_| {
            let crate_root = std::env::var("CARGO_MANIFEST_DIR").unwrap();
            let relative = std::path::Path::new(&crate_root)
                .parent() // rust/
                .unwrap()
                .parent() // project root
                .unwrap()
                .join("zig-out")
                .join("lib");
            if relative.exists() {
                Ok(relative.to_string_lossy().to_string())
            } else {
                Err(std::env::VarError::NotPresent)
            }
        })
        .expect(
            "libpxl.dylib not found. Set PXL_LIB_DIR or run `zig build lib` in the project root.",
        );

    println!("cargo:rustc-link-search=native={}", lib_dir);
    println!("cargo:rustc-link-lib=dylib=pxl");

    // Embed a runpath so the binary can find libpxl.dylib at runtime.
    // The dylib already has install_name @rpath/libpxl.dylib.
    // We use an absolute path to avoid CWD-relative issues.
    println!("cargo:rustc-link-arg=-Wl,-rpath,{}", lib_dir);
    println!("cargo:rustc-link-arg=-Wl,-rpath,@loader_path/../../../zig-out/lib");

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