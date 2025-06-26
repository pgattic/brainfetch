
def bracket-map [chars] {
  mut stack = []
  mut map = {}
  let ch_len = ($chars | length) - 1
  for idx in 0..$ch_len {
    let ch = $chars | get $idx
    if $ch == '[' {
      $stack = ($stack | append $idx)
    } else if $ch == ']' {
      let open = ($stack | last)
      $stack = ($stack | drop)
      $map = ($map | merge {$open: $idx, $idx: $open})
    }
  }
  $map
}

def brainfetch [file] {
  let code = open $file
  | split chars
  | where {|ch| ['+', '-', '<', '>', '[', ']', '.', ','] | any {|cmd| $cmd == $ch}}
  let jt = bracket-map $code

  let code_len = ($code | length)

  mut pc = 0
  mut mem_ptr = 0
  mut mem = (1..30_000 | each {0})

  while $pc < $code_len {
    match ($code | get $pc) {
      '+' => ($mem = $mem | update $mem_ptr ((($mem | get $mem_ptr) + 1) mod 256))
      '-' => ($mem = $mem | update $mem_ptr ((($mem | get $mem_ptr) + 255) mod 256))
      '>' => ($mem_ptr = ($mem_ptr + 1))
      '<' => ($mem_ptr = ($mem_ptr - 1))
      '.' => (print --no-newline (char --integer ($mem | get $mem_ptr)))
      ',' => (let b = (open --raw /dev/stdin | get 0? | default 0); $mem = $mem | update $mem_ptr $b)
      '[' => (if ($mem | get $mem_ptr) == 0 { $pc = ($jt | get ($pc | into string)) })
      ']' => (if ($mem | get $mem_ptr) != 0 { $pc = ($jt | get ($pc | into string)) })
      _ => {}
    }
    $pc = ($pc + 1)
  }
}

