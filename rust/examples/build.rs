/// Embeds a runpath so example binaries can find libpxl.dylib at runtime.
fn main() {
    // rust/examples/Cargo.toml → rust/examples → rust → project root
    let crate_root = std::env::var("CARGO_MANIFEST_DIR").unwrap();
    let project_root = std::path::Path::new(&crate_root)
        .parent() // examples/
        .unwrap()
        .parent() // rust/
        .unwrap();
    let lib_dir = project_root.join("zig-out").join("lib");

    if lib_dir.exists() {
        println!("cargo:rustc-link-arg=-Wl,-rpath,{}", lib_dir.display());
        println!("cargo:rustc-link-arg=-Wl,-rpath,@loader_path/../../../zig-out/lib");
    }
}