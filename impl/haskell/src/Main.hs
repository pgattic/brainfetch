module Main where

import System.Environment (getArgs)
-- import Memory (prev, next, newMem)
import Parser (parseBf)
-- import ProgState

usage :: IO ()
usage = putStrLn "Usage: `brainfetch path/to/file.bf`"

main :: IO ()
main = do
  args <- getArgs
  if "--help" `elem` args then do
    putStrLn "Brainfetch: Haskell implementation"
    putStrLn "By Preston Corless"
    putStrLn ""
    usage
  else case args of
    [] -> do
      putStrLn "Please specify a file."
      putStrLn ""
      usage
    (arg : []) -> do
      contents <- readFile (arg)
      case parseBf contents of
        Left ast -> print ast
        Right err -> print err
    (_ : _) -> do
      putStrLn "Too many arguments."
      putStrLn ""
      usage

