module Command(Command, parseCmds, buildJumpTable) where

import qualified Data.Map as Map

data Command = IncPtr
  | DecPtr
  | IncVal
  | DecVal
  | OpenBr
  | CloseBr
  | PutChar
  | GetChar
  deriving Show

parseCmds :: [Char] -> [Command]
parseCmds [] = []
parseCmds (ch : rest) = case ch of
  '+' -> IncVal : parseCmds rest
  '-' -> DecVal : parseCmds rest
  '>' -> IncPtr : parseCmds rest
  '<' -> DecPtr : parseCmds rest
  '[' -> OpenBr : parseCmds rest
  ']' -> CloseBr : parseCmds rest
  '.' -> PutChar : parseCmds rest
  ',' -> GetChar : parseCmds rest
  _ -> parseCmds rest


buildJumpTable :: [Command] -> Map.Map Int Int
buildJumpTable cmds = buildJumpTable' cmds [] 0

buildJumpTable' :: [Command] -> [Int] -> Int -> Map.Map Int Int
buildJumpTable' [] _ _ = Map.empty
buildJumpTable' (next : rest) stack count = case next of
  OpenBr -> buildJumpTable' rest (count : stack) (count+1)
  CloseBr -> do
    let stackH : stackRest = stack
    Map.insert stackH count (Map.insert count stackH (buildJumpTable' rest stackRest (count+1)))
  _ -> buildJumpTable' rest stack (count+1)


