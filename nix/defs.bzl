load("@rules_nixpkgs//nixpkgs:nixpkgs.bzl", "nixpkgs_git_repository")

def nix_dependencies():
    """Defines the Nixpkgs repository."""
    nixpkgs_git_repository(
        name = "nixpkgs",
        # Corresponds to the 23.11 release channel
        revision = "d20072a737d6a8001340f3a2182025756c352e4f",
        sha256 = "0k19z57743scg31i0i6j2r4r2y185ff0g2i8q326v15k2m3i5j7k",
    )