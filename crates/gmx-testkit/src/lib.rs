//! GMX test support.
//!
//! Provides golden-file helpers over `examples/`, a capture replay driver
//! and fake servers for differential testing against the Python reference
//! servers.

use std::path::{Path, PathBuf};

/// Returns the repository root, which holds the `examples/` golden inputs.
pub fn repo_root() -> PathBuf {
    Path::new(env!("CARGO_MANIFEST_DIR"))
        .ancestors()
        .nth(2)
        .expect("gmx-testkit lives two levels below the repository root")
        .to_path_buf()
}

/// Returns the `examples/` directory used as golden input.
pub fn examples_dir() -> PathBuf {
    repo_root().join("examples")
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn examples_dir_exists() {
        let dir = examples_dir();
        assert!(dir.is_dir(), "missing golden inputs at {}", dir.display());
        assert!(dir.join("layouts").is_dir());
        assert!(dir.join("records").is_dir());
        assert!(dir.join("collections").is_dir());
    }
}
