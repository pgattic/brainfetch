module Main where

import System.Environment (getArgs)
-- import Memory (prev, next, newMem)
import Parser
-- import ProgState

main :: IO ()
main = do
  args <- getArgs
  if null args then
    putStrLn "Please specify a file."
  else do
    contents <- readFile (head args)
    putStrLn contents
    case parseBf contents of
      Left ast -> print ast
      Right err -> print err

