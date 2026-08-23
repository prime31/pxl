/// Exports the project root so example binaries can resolve relative asset paths.
fn main() {
    // rust/examples/Cargo.toml → rust/examples → rust → project root
    let crate_root = std::env::var("CARGO_MANIFEST_DIR").unwrap();
    let project_root = std::path::Path::new(&crate_root)
        .parent() // examples/
        .unwrap()
        .parent() // rust/
        .unwrap();

    println!(
        "cargo:rustc-env=PXL_PROJECT_ROOT={}",
        project_root.display()
    );
}
