module MemoryVec(Memory, newMem, add, set, move, curr) where
import qualified Data.Vector.Unboxed.Mutable as VM
import Data.Word

data Memory = Memory {
  tape :: !(VM.IOVector Word8),
  idx :: !Int
}

newMem :: IO Memory
newMem = do
  vec <- VM.replicate 1000 0
  return Memory {
    tape = vec,
    idx = 0
  }

add :: Word8 -> Memory -> IO Memory
add x mem = do
  VM.modify (tape mem) (+ x) (idx mem)
  return mem

set :: Word8 -> Memory -> IO Memory
set x mem = do
  VM.write (tape mem) (idx mem) x
  return mem

move :: Int -> Memory -> Memory
move x mem =
  Memory {
    tape = tape mem,
    idx = (idx mem) + x
  }

curr :: Memory -> IO Word8
curr mem = VM.read (tape mem) (idx mem)

