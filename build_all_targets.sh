#!/bin/bash
set -e

# Cross-compilation build script for ca_search
# Builds release binaries for all supported platforms

# Define targets: WolframSystemID Rust_target
TARGETS=(
    "MacOSX-x86-64:x86_64-apple-darwin"
    "MacOSX-ARM64:aarch64-apple-darwin"
    "Linux-x86-64:x86_64-unknown-linux-gnu"
    "Linux-ARM64:aarch64-unknown-linux-gnu"
    "Windows-x86-64:x86_64-pc-windows-gnu"
)

echo "Building ca_search for all targets..."
echo

CURRENT_ARCH=$(uname -m)

for entry in "${TARGETS[@]}"; do
    system_id="${entry%%:*}"
    target="${entry##*:}"
    echo "=== Building for $system_id ($target) ==="
    
    # Use target-cpu=native for local architecture builds
    BUILD_RUSTFLAGS=""
    if [[ ("$CURRENT_ARCH" == "arm64" && "$target" == "aarch64-apple-darwin") || \
          ("$CURRENT_ARCH" == "x86_64" && "$target" == "x86_64-apple-darwin") ]]; then
        BUILD_RUSTFLAGS="-C target-cpu=native"
        echo "  (using target-cpu=native)"
    fi

    if RUSTFLAGS="$BUILD_RUSTFLAGS" cargo build --release --target "$target"; then
        echo "✓ $system_id build succeeded"
    else
        echo "✗ $system_id build failed"
        exit 1
    fi
    echo
done

echo "=== All builds completed successfully ==="

# Show output locations
echo
echo "Built libraries:"
for entry in "${TARGETS[@]}"; do
    system_id="${entry%%:*}"
    target="${entry##*:}"
    case "$target" in
        *-windows-*)
            ext="dll.a"
            ;;
        *-apple-*)
            ext="dylib"
            ;;
        *)
            ext="so"
            ;;
    esac
    echo "  $system_id: target/$target/release/libca_search.$ext"
done
