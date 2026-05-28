module Parser where

data Command =
    CIncPtr
  | CDecPtr
  | CIncVal
  | CDecVal
  | COpenBr
  | CCloseBr
  | CPutChar
  | CGetChar
  deriving (Show, Eq)

parseCmds :: String -> [Command]
parseCmds [] = []
parseCmds (ch : rest) = case ch of
  '+' -> CIncVal : parseCmds rest
  '-' -> CDecVal : parseCmds rest
  '>' -> CIncPtr : parseCmds rest
  '<' -> CDecPtr : parseCmds rest
  '[' -> COpenBr : parseCmds rest
  ']' -> CCloseBr : parseCmds rest
  '.' -> CPutChar : parseCmds rest
  ',' -> CGetChar : parseCmds rest
  _ -> parseCmds rest

data ASTNode =
    AddPtr Int
  | SubPtr Int
  | Next Int
  | Prev Int
  | PutChar
  | GetChar
  | Loop [ASTNode]
  deriving (Show, Eq)

type AST = [ASTNode]
type CmdStr = [Command]
type Parser a = CmdStr -> Maybe (a, CmdStr)

leadingJust :: [Maybe x] -> [x]
leadingJust [] = []
leadingJust (Nothing : _) = []
leadingJust (Just x : t) = x : leadingJust t

firstJust :: [Maybe x] -> Maybe x
firstJust [] = Nothing
firstJust (Just x : _) = Just x
firstJust (Nothing : t) = firstJust t

parseCmd :: Command -> ASTNode -> Parser ASTNode
parseCmd _ _ [] = Nothing
parseCmd cmd val (h : t) = if h == cmd then Just (val, t) else Nothing

parseInc :: Parser ASTNode
parseInc = parseCmd CIncVal (AddPtr 1)

-- parseAdd :: Parser ASTNode
-- parseAdd str = case countLeadingSome (map parseInc str) of
--   0 -> Nothing
--   x -> Just (AddPtr x)

parseDec :: Parser ASTNode
parseDec = parseCmd CDecVal (SubPtr 1)

parseNext :: Parser ASTNode
parseNext = parseCmd CIncPtr (Next 1)

parsePrev :: Parser ASTNode
parsePrev = parseCmd CDecPtr (Prev 1)

parsePutCh :: Parser ASTNode
parsePutCh = parseCmd CPutChar PutChar

parseGetCh :: Parser ASTNode
parseGetCh = parseCmd CGetChar GetChar

parseChoice :: [Parser x] -> Parser x
parseChoice parsers str = firstJust (map (\x -> x str) parsers)

-- parseMany :: (CmdStr -> Maybe (a, CmdStr)) -> (CmdStr -> Maybe ([a], CmdStr))
parseMany :: Parser x -> Parser [x]
parseMany p str =
  case p str of
    Just (x, rest) -> 
      case parseMany p rest of
        Just (xs, rest') -> Just (x : xs, rest')
        Nothing -> Nothing
    Nothing -> Just ([], str)

bfParsers :: [ Parser ASTNode ]
bfParsers = [parseDec, parseNext, parsePrev, parsePutCh, parseGetCh, loopParser]

loopParser :: Parser ASTNode
loopParser [] = Nothing
loopParser (h : t) =
  if h == COpenBr then
    case parseMany (parseChoice bfParsers) t of
      Just (x, rest) -> Just (Loop x, rest)
      Nothing -> Just (Loop [], t)
  else
    Nothing

bfParser :: Parser [ASTNode]
bfParser input = parseMany (parseChoice bfParsers) input

-- TODO: This does not correctly handle `]`, the parsers all stop on that character.

