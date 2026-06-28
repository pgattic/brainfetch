
# Nix Implementation

No, not as a derivation!

BrainF*** interpreter written in pure Nix. Implementation found in `src/`, not `module.nix`.

By Preston Corless

## Usage

```bash
# Nix has a hard time with relative paths from strings
nix-instantiate --strict --eval brainfetch.nix --argstr file "/absolute/path/to/file.bf"
```

## Performance

Awful.

