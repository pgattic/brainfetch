module Main where

import System.Environment (getArgs)
import Parser (parseBf)
import Interp (interp)

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
        Left ast -> do
          _ <- (interp ast)
          return ()
        Right err -> print err
    (_ : _) -> do
      putStrLn "Too many arguments."
      putStrLn ""
      usage

