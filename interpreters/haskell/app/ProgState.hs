module ProgState(execute) where

import Command
import Memory
import qualified Data.Map as Map

data ProgState = ProgState {
  memory :: Memory,
  pc :: Int
}

execute :: [Command] -> Map.Map Int Int -> ProgState
execute program jt = execute' program jt ProgState { memory = Memory.newMem, pc = 0 }

execute' :: [Command] -> Map.Map Int Int -> ProgState -> IO ()
execute' program jt state =
  if pc state == length program - 1 then -- Program done
    ()
  else
    case program !! pc state of
      IncPtr -> execute' program jt ProgState {memory = inc (memory state), pc = pc state + 1}
      _ -> ()

