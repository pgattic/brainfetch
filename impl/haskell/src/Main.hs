module Main where

import System.Environment (getArgs)
import Memory (prev, next, newMem)
-- import ProgState

data MyStruct = MyStruct {
  a :: Int,
  b :: Int
} deriving Show

main :: IO ()
main = do
  args <- getArgs
  if null args then
    putStrLn "Please specify a file."
  else do
    contents <- readFile (head args)
    putStrLn contents

-- |Calculates the factorial of a number
fact :: (Eq t, Num t) => t -> t
fact 0 = 1
fact x = x * fact (x-1)

