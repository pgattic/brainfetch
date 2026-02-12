
# Formally Verified BrainF*** Interpreter Written in Rocq Prover

## Usage

- `nix develop`
- `rocq makefile -f _RocqProject -o Makefile`
- `make`

In addition, the `bf_convert.sh` helper script is provided to convert a normal BrainF*** program file into a copyable list of `bf_command` to be copied/pasted into Rocq. This is the closest thing I have to parsing for now, haha.
