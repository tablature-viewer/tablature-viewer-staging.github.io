module Utils where

import Prelude

import Data.Either (Either(..))
import Data.Enum (class Enum)
import Data.List (List(..), (:))
import Data.List.NonEmpty (NonEmptyList)
import Data.Tuple (Tuple, fst, snd)
import Text.Parsing.StringParser (Parser(..), unParser)
import Text.Parsing.StringParser.Combinators (many, many1, many1Till, manyTill)

-- Show is for debugging, Print has to give a string that is actually how it is supposed to be presented to the user.
class Print a where
  print :: a -> String

class Enum a <= CyclicEnum a where
  succ' :: a -> a
  pred' :: a -> a

foreach :: forall a b s. s -> List a -> (s -> a -> Tuple s b) -> List b
foreach _ Nil _ = Nil
foreach state (x : xs) loop = snd next : (foreach (fst next) xs loop)
  where next = loop state x

applyUntilIdempotent :: forall a. (Eq a) => (a -> a) -> a -> a
applyUntilIdempotent f x = if result == x then result else applyUntilIdempotent f result
  where result = f x

-- NOTES
-- many p will get stuck in a loop if p possibly doesn't consume any input but still succeeds
-- many (many p) will get stuck for any p
-- parseEndOfLine doesn't consume input at the end of the file but still succeeds

-- TODO: make pull request for this combinator
-- Fails with parse error if parser did not consume any input
assertConsume :: forall a. Parser a -> Parser a
assertConsume p = Parser $ \posStrBefore ->
  case unParser p posStrBefore of
    Right result ->
      if posStrBefore.pos < result.suffix.pos
      then Right result
      else Left { pos: result.suffix.pos, error: "Consumed no input." }
    x -> x

safeMany :: forall a. Parser a -> Parser (List a)
safeMany = many <<< assertConsume

safeMany1 :: forall a. Parser a -> Parser (NonEmptyList a)
safeMany1 = many1 <<< assertConsume

safeManyTill :: forall a end. Parser a -> Parser end -> Parser (List a)
safeManyTill p = manyTill (assertConsume p)

safeMany1Till :: forall a end. Parser a -> Parser end -> Parser (NonEmptyList a)
safeMany1Till p = many1Till (assertConsume p)
