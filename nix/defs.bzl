load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository")

def nix_dependencies():
    """Defines the Nixpkgs repository."""
    # Track the nixos-unstable channel by following the branch in Git.
    # This is intentionally unpinned to keep in sync with the channel.
    git_repository(
        name = "nixpkgs",
        remote = "https://github.com/NixOS/nixpkgs.git",
        branch = "nixos-unstable",
    )
