module Parser(ASTNode(Add, Move, PutChar, GetChar, Loop, Zero), AST, parseBf) where

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

type CmdStr = [Command]

-- Turn a string into a list of Command tokens, stripping comments
parseCmds :: String -> CmdStr
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
  | Zero
  deriving (Show, Eq)

type AST = [ASTNode]
type Parser a = CmdStr -> Maybe (a, CmdStr)

-- GENERAL PARSER COMBINATORS --

firstJust :: [Maybe x] -> Maybe x
firstJust [] = Nothing
firstJust (Just x : _) = Just x
firstJust (Nothing : t) = firstJust t

parseChoice :: [Parser x] -> Parser x
parseChoice parsers str = firstJust (map (\x -> x str) parsers)

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

-- BF-SPECIFIC PARSERS --

-- Parse repeated +/- into (Add x) where x is a signed number
parseAdd :: Parser ASTNode
parseAdd str =
  let
    parseInc = parseCmd CIncVal 1
    parseDec = parseCmd CDecVal (-1)
  in case parseMany (parseChoice [ parseInc, parseDec ]) str of
    Just (items, rest) -> if sum items == 0 then Nothing else Just (Add (sum items), rest)
    Nothing -> Nothing

-- Parse repeated >/< into (Move x) where x is a signed number
parseMove :: Parser ASTNode
parseMove str =
  let
    parseNext = parseCmd CIncPtr 1
    parsePrev = parseCmd CDecPtr (-1)
  in case parseMany (parseChoice [parseNext, parsePrev]) str of
    Just (items, rest) -> if sum items == 0 then Nothing else Just (Move (sum items), rest)
    Nothing -> Nothing

-- Parse . into PutChar node
parsePutCh :: Parser ASTNode
parsePutCh = parseCmd CPutChar PutChar

-- Parse , into GetChar node
parseGetCh :: Parser ASTNode
parseGetCh = parseCmd CGetChar GetChar

-- Parse [] sections, recurses using bfParser
parseLoop :: Parser ASTNode
parseLoop (COpenBr : t) =
  case bfParser t of
    Just (x, rest) ->
      case (parseCmd CCloseBr ()) rest of
        Just ((), rest') -> Just (Loop x, rest')
        Nothing -> error "Unparseable token"
    Nothing -> Just (Loop [], t)
parseLoop _ = Nothing

parseZero :: Parser ASTNode
parseZero (COpenBr : (CDecVal : (CCloseBr : rest))) = Just (Zero, rest)
parseZero (COpenBr : (CIncVal : (CCloseBr : rest))) = Just (Zero, rest)
parseZero _ = Nothing

-- Parse multiple tokens into a list of AST nodes
bfParser :: Parser AST
bfParser =
  let
    parsers = [parseZero, parseAdd, parseMove, parsePutCh, parseGetCh, parseLoop]
  in parseMany (parseChoice parsers)

-- Wrapper that provides a simpler return type to work with
parseBf :: String -> Either AST String
parseBf str = case bfParser (parseCmds str) of
  Just (result, []) -> Left result
  Just (_, CCloseBr : _) -> Right "Unopened ]"
  Just (_, _) -> Right "Unknown Error"
  Nothing -> Right "Unknown Error"

