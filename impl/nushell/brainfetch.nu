
def brainfetch [file] {
  def bracket-map [chars] {
    mut stack = []
    let ch_len = ($chars | length)
    mut map = (1..$ch_len | each { 0 })
    for idx in 0..($ch_len - 1) {
      let ch = $chars | get $idx
      if $ch == '[' {
        $stack = ($stack | append $idx)
      } else if $ch == ']' {
        let open = ($stack | last)
        $stack = ($stack | drop)
        $map = ($map | update $open $idx)
        $map = ($map | update $idx $open)
      }
    }
    $map
  }

  let code = open $file
  | split chars
  | where {|ch| ['+', '-', '<', '>', '[', ']', '.', ','] | any {|cmd| $cmd == $ch}}
  let jt = bracket-map $code

  let code_len = ($code | length)

  mut pc = 0
  mut mem_l = []
  mut mem_c = 0
  mut mem_r = []

  while $pc < $code_len {
    match ($code | get $pc) {
      '+' => ($mem_c = (($mem_c + 1) mod 256))
      '-' => ($mem_c = (($mem_c + 255) mod 256))
      '>' => ($mem_l = [$mem_c, $mem_l]; $mem_c = ($mem_r | get 0? | default 0); $mem_r = ($mem_r | slice 1..))
      '<' => ($mem_r = [$mem_c, $mem_r]; $mem_c = ($mem_l | get 0? | default 0); $mem_l = ($mem_l | slice 1..))
      '.' => (print --no-newline (char --integer $mem_c))
      ',' => ($mem_c = (open --raw /dev/stdin | get 0? | default 0))
      '[' => (if $mem_c == 0 { $pc = ($jt | get $pc) })
      ']' => (if $mem_c != 0 { $pc = ($jt | get $pc) })
    }
    $pc = ($pc + 1)
  }
}

