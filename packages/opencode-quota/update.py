#!/usr/bin/env nix
#! nix shell --inputs-from .# nixpkgs#python3 --command python3

"""Update script for opencode-quota package.

opencode-quota tags releases as `v3.8.7`, but upstream tags the release
commit *before* the npm publish workflow bumps `package.json`, so the
tree at the tag still carries the previous version string. package.nix
patches that at build time; this updater only tracks the release tag and
refreshes the source and pnpm dependency hashes through hashes.json.
"""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent / "scripts"))

from updater import (
    calculate_dependency_hash,
    calculate_url_hash,
    fetch_github_latest_release,
    load_hashes,
    save_hashes,
    should_update,
)
from updater.hash import DUMMY_SHA256_HASH
from updater.nix import NixCommandError

HASHES_FILE = Path(__file__).parent / "hashes.json"
OWNER = "slkiser"
REPO = "opencode-quota"


def main() -> None:
    """Update opencode-quota hashes to the latest GitHub release."""
    data = load_hashes(HASHES_FILE)
    current = data["version"]
    latest = fetch_github_latest_release(OWNER, REPO)
    print(f"Current: {current}, Latest: {latest}")
    if not should_update(current, latest):
        print("Already up to date")
        return

    src_url = f"https://github.com/{OWNER}/{REPO}/archive/refs/tags/v{latest}.tar.gz"

    new_data = {
        "version": latest,
        "hash": calculate_url_hash(src_url, unpack=True),
        "pnpmDepsHash": DUMMY_SHA256_HASH,
    }
    save_hashes(HASHES_FILE, new_data)

    # pnpmDepsHash falls out of the fetchPnpmDeps FOD build failure.
    try:
        print("Calculating pnpmDepsHash...")
        new_data["pnpmDepsHash"] = calculate_dependency_hash(
            ".#opencode-quota", "pnpmDepsHash", HASHES_FILE, new_data
        )
        save_hashes(HASHES_FILE, new_data)
    except (ValueError, NixCommandError) as e:
        print(f"Error: {e}")
        sys.exit(1)

    print(f"Updated to {latest}")


if __name__ == "__main__":
    main()
