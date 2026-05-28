module ProgState where

import Parser
import Memory
import qualified Data.Map as Map

data ProgState = ProgState {
  memory :: Memory,
  pc :: Int
}

