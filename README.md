# Adaptive Book reader C2

## Requirements

Nix with flakes enabled.

## Build

```bash
nix flake lock
nix develop .#wasm --accept-flake-config --command bash -c 'make'
```

`--accept-flake-config` enables the Miso binary cache, so the GHC WASM
toolchain does not need to be rebuilt. The build output is written to
`public/`.

## Serve

```bash
nix run .#serve
```

Then open <http://localhost:8080>.

Alternatively:

```bash
nix develop .#wasm --command bash -c 'make serve'
```

## Development

The default shell provides both the WASM toolchain and
`haskell-language-server`:

```bash
nix develop
make
make serve
```

Use the lean build-only shell if you do not need HLS:

```bash
nix develop .#wasm
```

Use the HLS-only shell if you only need editor tooling:

```bash
nix develop .#hls
```
