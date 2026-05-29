module Interp(interp) where

import Memory(Memory, newMem, add, set, move, curr)
import Parser(ASTNode(Add, Move, PutChar, GetChar, Loop, Zero), AST)
import Data.Char (chr, ord)

iterUntilM :: (x -> Bool) -> (x -> IO x) -> x -> IO x
iterUntilM t f x = if t x then return x else do
  res <- (f x)
  res' <- (iterUntilM t f res)
  return res'

interpOne :: ASTNode -> Memory -> IO Memory
interpOne x mem =
  case x of
    Add n -> pure (add n mem)
    Move n -> pure (move n mem)
    PutChar -> do
      putChar (chr (fromIntegral (curr mem)))
      return (mem)
    GetChar -> do
      ch <- getChar
      return (set (fromIntegral (ord ch)) mem)
    Zero -> pure (set 0 mem)
    Loop n -> do
      new_mem <- (iterUntilM (\m -> curr m == 0) (interpMany n)) mem
      return new_mem

interpMany :: AST -> Memory -> IO Memory
interpMany [] mem = pure mem
interpMany (x : xs) mem = do
  i <- interpOne x mem
  (interpMany xs (i))

-- Helper function that inserts fresh memory
interp :: AST -> IO Memory
interp prog = interpMany prog newMem

