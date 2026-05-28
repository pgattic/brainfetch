module Parser(parseBf) where

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
    Add Int
  | Move Int
  | PutChar
  | GetChar
  | Loop [ASTNode]
  deriving (Show, Eq)

type AST = [ASTNode]
type CmdStr = [Command]
type Parser a = CmdStr -> Maybe (a, CmdStr)

firstJust :: [Maybe x] -> Maybe x
firstJust [] = Nothing
firstJust (Just x : _) = Just x
firstJust (Nothing : t) = firstJust t

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

parseCmd :: Command -> x -> Parser x
parseCmd _ _ [] = Nothing
parseCmd cmd val (h : t) = if h == cmd then Just (val, t) else Nothing



parseAdd :: Parser ASTNode
parseAdd str =
  let
    parseInc = parseCmd CIncVal 1
    parseDec = parseCmd CDecVal (-1)
  in case parseMany (parseChoice [ parseInc, parseDec ]) str of
    Just (items, rest) -> if items == [] then Nothing else Just (Add (sum items), rest)
    Nothing -> Nothing

parseMove :: Parser ASTNode
parseMove str =
  let
    parseNext = parseCmd CIncPtr 1
    parsePrev = parseCmd CDecPtr (-1)
  in case parseMany (parseChoice [parseNext, parsePrev]) str of
    Just (items, rest) -> if items == [] then Nothing else Just (Move (sum items), rest)
    Nothing -> Nothing

parsePutCh :: Parser ASTNode
parsePutCh = parseCmd CPutChar PutChar

parseGetCh :: Parser ASTNode
parseGetCh = parseCmd CGetChar GetChar

bfParsers :: [Parser ASTNode]
bfParsers = [parseAdd, parseMove, parsePutCh, parseGetCh, loopParser]

loopParser :: Parser ASTNode
loopParser [] = Nothing
loopParser (h : t) =
  if h == COpenBr then
    case bfParser t of
      Just (x, rest) -> let
          cbParser = parseCmd CCloseBr ()
        in case cbParser rest of 
          Just ((), rest') -> Just (Loop x, rest')
          Nothing -> error "Unparseable token"
      Nothing -> Just (Loop [], t)
  else
    Nothing

bfParser :: Parser AST
bfParser = parseMany (parseChoice bfParsers)

parseBf :: String -> Either AST String
parseBf str = case bfParser (parseCmds str) of
  Just (result, []) -> Left result
  Just (_, CCloseBr : _) -> Right "Unopened ]"
  Just (_, _) -> Right "Unknown Error"
  Nothing -> Right "Unknown Error"

