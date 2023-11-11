name := 'cosmic-dark-light'
appid := 'com.system76.DarkLight'

# Use lld linker if available
ld-args := if `which lld || true` != '' {
    '-C link-arg=-fuse-ld=lld -C link-arg=-Wl,--build-id=sha1'
} else {
    ''
}

# Use the x86-64-v2 target by default on x86-64 systems.
target-cpu := if arch() == 'x86_64' { 'x86-64-v2' } else { '' }

export RUSTFLAGS := if target-cpu != '' {
    ld-args + ' -C target-cpu=' + target-cpu + ' ' + env_var_or_default('RUSTFLAGS', '')
} else {
    ld-args + ' ' + env_var_or_default('RUSTFLAGS', '')
}

rootdir := ''
prefix := '/usr'


# File paths
bin-src := 'target' / 'release' / name
bin-dest := clean(rootdir / prefix) / 'bin' / name

dark-sh-dest := clean(rootdir / prefix) / 'share' / 'dark-mode.d' / 'cosmic-dark'
light-sh-dest := clean(rootdir / prefix) / 'share' / 'light-mode.d' / 'cosmic-light'

[private]
default: build-release

# Remove Cargo build artifacts
clean:
    cargo clean

# Also remove .cargo and vendored dependencies
clean-dist: clean
    rm -rf .cargo vendor vendor.tar target

# Compile with debug profile
build-debug *args:
    cargo build {{args}}

# Compile with release profile
build-release *args: (build-debug '--release' args)

# Compile with a vendored tarball
build-vendored *args: vendor-extract (build-release '--frozen --offline' args)

# Check for errors and linter warnings
check *args:
    cargo clippy --all-features {{args}} -- -W clippy::pedantic

# Runs a check with JSON message format for IDE integration
check-json: (check '--message-format=json')

# Installation command
[private]
install-cmd options src dest:
    install {{options}} {{src}} {{dest}}

[private]
install-bin src dest: (install-cmd '-Dm0755' src dest)

# Install everything
install: (install-bin bin-src bin-dest) (install-bin 'cosmic-dark' dark-sh-dest) (install-bin 'cosmic-light' light-sh-dest)

# Run the application for testing purposes
run *args:
    env RUST_LOG=debug RUST_BACKTRACE=full cargo run --release {{args}}
# Run `cargo test`
test:
    cargo test

# Uninstalls everything (requires same arguments as given to install)
uninstall:
    rm -rf {{bin-dest}} {{dark-sh-dest}} {{light-sh-dest}}

# Vendor Cargo dependencies locally
vendor:
    mkdir -p .cargo
    cargo vendor --sync Cargo.toml \
        | head -n -1 > .cargo/config
    echo 'directory = "vendor"' >> .cargo/config
    tar pcf vendor.tar vendor
    rm -rf vendor

# Extracts vendored dependencies
[private]
vendor-extract:
    rm -rf vendor
    tar pxf vendor.tar

# Show the name of the project
name:
    @cargo pkgid | sed -e 's:.*/::' -e 's:[#^].*::'

# Show the current version
version:
    @cargo pkgid | sed -e 's:.*/::' -e 's:.*#::'

# Show the current git commit
git-rev:
    @git rev-parse --short HEAD
