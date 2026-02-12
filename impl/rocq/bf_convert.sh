#!/usr/bin/env bash
#
# bf2coq.sh - Convert a Brainfuck program into Coq bf_program notation
# using:
#   - bf_program as a tree: bf_nil / bf_cons / bf_loop
#   - custom entry syntax like: <[ + + [ - ! ] > . ! ]>
# where "!" denotes bf_nil.
#
# Usage:
#   ./bf2coq.sh '++[->+<]>.'
#   echo '++[->+<]>.' | ./bf2coq.sh

# Read input: from first argument if given, otherwise from stdin
if [ -n "$1" ]; then
  raw="$1"
else
  raw="$(cat)"
fi

# Keep only valid Brainfuck characters
bf=$(printf "%s" "$raw" | tr -d -c '+-<>[],.')

out=""

# Process each character and map to Coq tokens
#   + - > < , . stay the same (just spaced)
#   [ becomes " ["
#   ] becomes " ! ]"  (insert loop body terminator before each closing bracket)
for ((i=0; i<${#bf}; i++)); do
  ch=${bf:i:1}
  case "$ch" in
    '+') out+=" +" ;;
    '-') out+=" -" ;;
    '>') out+=" >" ;;
    '<') out+=" <" ;;
    ',') out+=" ," ;;
    '.') out+=" @" ;;
    '[') out+=" [" ;;
    ']') out+=" ! ]" ;;
  esac
done

# Add final terminator for the whole program
out+=" !"

# Wrap in the Coq bf_program notation
printf "<[%s ]>\n" "$out"
