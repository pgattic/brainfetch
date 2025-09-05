module Memory(Memory, newMem, next, prev, inc, dec) where

data Memory = Memory {
  left :: [Int],
  curr :: Int,
  right :: [Int]
}

newMem :: Memory
newMem = Memory {
  left = repeat 0,
  curr = 0,
  right = repeat 0
}

next :: Memory -> Memory
next mem = Memory {
  left = curr mem : left mem,
  curr = head (right mem),
  right = tail (right mem)
}

prev :: Memory -> Memory
prev mem = Memory {
  left = tail (left mem),
  curr = head (left mem),
  right = curr mem : right mem
}

inc :: Memory -> Memory
inc mem = Memory {
  left = left mem,
  curr = succ (curr mem),
  right = right mem
}

dec :: Memory -> Memory
dec mem = Memory {
  left = left mem,
  curr = pred (curr mem),
  right = right mem
}

