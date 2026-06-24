module InterpVec(interp) where

import MemoryVec(Memory, newMem, add, set, move, curr)
import Parser(ASTNode(Add, Move, PutChar, GetChar, Loop, Zero), AST)
import Data.Char (chr, ord)

iterUntilM :: (x -> IO Bool) -> (x -> IO x) -> x -> IO x
iterUntilM t f x = do
  cond <- t x
  if cond then return x else do
    res <- (f x)
    res' <- (iterUntilM t f res)
    return res'

checkMemZero :: Memory -> IO Bool
checkMemZero mem = do
  cur <- curr mem
  return (cur == 0)

interpOne :: ASTNode -> Memory -> IO Memory
interpOne x mem =
  case x of
    Add n -> (add n mem)
    Move n -> pure (move n mem)
    PutChar -> do
      cur <- curr mem
      putChar (chr (fromIntegral cur))
      return (mem)
    GetChar -> do
      ch <- getChar
      res <- (set (fromIntegral (ord ch)) mem)
      return res
    Zero -> (set 0 mem)
    Loop n -> do
      new_mem <- (iterUntilM checkMemZero (interpMany n)) mem
      return new_mem

interpMany :: AST -> Memory -> IO Memory
interpMany [] mem = pure mem
interpMany (x : xs) mem = do
  i <- interpOne x mem
  (interpMany xs (i))

-- Helper function that inserts fresh memory
interp :: AST -> IO Memory
interp prog = do
  mem <- newMem
  interpMany prog mem

