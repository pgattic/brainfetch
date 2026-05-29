module Memory(Memory, newMem, add, set, move, curr) where
import Data.Word

data Memory = Memory {
  left :: [Word8],
  curr :: !Word8,
  right :: [Word8]
} deriving (Show, Eq)

newMem :: Memory
newMem = Memory {
  left = repeat 0,
  curr = 0,
  right = repeat 0
}

add :: Int -> Memory -> Memory
add x mem = Memory {
  left = left mem,
  curr = (curr mem) + fromIntegral x,
  right = right mem
}

set :: Int -> Memory -> Memory
set x mem = Memory {
  left = left mem,
  curr = fromIntegral x,
  right = right mem
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

move :: Int -> Memory -> Memory
move x mem = case x of
  0 -> mem
  n | n > 0 -> iterate next mem !! n
    | n < 0 -> iterate prev mem !! (-n)
  _ -> error "IDK how you got here"

