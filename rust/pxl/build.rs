/// Computes the project root so pxl_game! / simple_game! can chdir at launch.
fn main() {
    // rust/pxl/Cargo.toml → rust/pxl → rust → project root.
    let crate_root = std::env::var("CARGO_MANIFEST_DIR").unwrap();
    let project_root = std::path::Path::new(&crate_root)
        .parent() // pxl/
        .unwrap()
        .parent() // rust/
        .unwrap();

    println!(
        "cargo:rustc-env=PXL_PROJECT_ROOT={}",
        project_root.display()
    );
}