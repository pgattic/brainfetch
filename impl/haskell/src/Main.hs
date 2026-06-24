module Main where

import System.Environment (getArgs)
import System.Exit (ExitCode (ExitFailure), exitWith)
import Parser (parseBf)
import InterpVec (interp)
import System.IO.Error (tryIOError)

info :: IO ()
info = do
  putStrLn "A BrainF*** interpreter written in Haskell"
  putStrLn "By Preston Corless"
  putStrLn ""
  putStrLn "Usage: brainfetch [FILE]"
  putStrLn ""
  putStrLn "Options:"
  putStrLn "  -h, --help        Display this help info"

safeReadFile :: FilePath -> IO (Either IOError String)
safeReadFile path = tryIOError (readFile path)

main :: IO ()
main = do
  args <- getArgs
  if elem "--help" args || elem "-h" args then do
    info
  else case args of
    [] -> do
      info
    (arg : []) -> do
      result <- safeReadFile arg
      case result of
        Left err -> do
          putStrLn (show err)
          exitWith (ExitFailure 1)
        Right contents -> case parseBf contents of
          Left ast -> do
            _ <- (interp ast)
            return ()
          Right err -> do
            print err
            exitWith (ExitFailure 1)
    _ -> do
      putStrLn "Error: Too many arguments."
      putStrLn ""
      putStrLn "For usage information, type `brainfetch --help`"
      exitWith (ExitFailure 1)

