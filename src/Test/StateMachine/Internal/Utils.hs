-----------------------------------------------------------------------------
-- |
-- Module      :  Test.StateMachine.Internal.Utils
-- Copyright   :  (C) 2017, ATS Advanced Telematic Systems GmbH
-- License     :  BSD-style (see the file LICENSE)
--
-- Maintainer  :  Stevan Andjelkovic <stevan@advancedtelematic.com>
-- Stability   :  provisional
-- Portability :  non-portable (GHC extensions)
--
-- This module exports some QuickCheck utility functions. Some of these should
-- perhaps be upstreamed.
--
-----------------------------------------------------------------------------

module Test.StateMachine.Internal.Utils
  ( anyP
  , liftProperty
  , shrinkPropertyHelper
  , shrinkPropertyHelper'
  , shrinkPair
  ) where

import           Test.QuickCheck
                   (Property, Result(Failure), chatty, counterexample,
                   output, property, quickCheckWithResult, stdArgs)
import           Test.QuickCheck.Monadic
                   (PropertyM(MkPropertyM), monadicIO, run)
import           Test.QuickCheck.Property
                   ((.&&.), (.||.))

------------------------------------------------------------------------

-- | Lifts 'Prelude.any' to properties.
anyP :: (a -> Property) -> [a] -> Property
anyP p = foldr (\x ih -> p x .||. ih) (property False)

-- | Lifts a plain property into a monadic property.
liftProperty :: Monad m => Property -> PropertyM m ()
liftProperty prop = MkPropertyM (\k -> fmap (prop .&&.) <$> k ())

-- | Write a metaproperty on the output of QuickChecking a property using a
--   boolean predicate on the output.
shrinkPropertyHelper :: Property -> (String -> Bool) -> Property
shrinkPropertyHelper prop p = shrinkPropertyHelper' prop (property . p)

-- | Same as above, but using a property predicate.
shrinkPropertyHelper' :: Property -> (String -> Property) -> Property
shrinkPropertyHelper' prop p = monadicIO $ do
  result <- run $ quickCheckWithResult (stdArgs {chatty = False}) prop
  case result of
    Failure { output = outputLines } -> liftProperty $
      counterexample ("failed: " ++ outputLines) $ p outputLines
    _                                -> return ()

-- | Given shrinkers for the components of a pair we can shrink the pair.
shrinkPair :: (a -> [a]) -> (b -> [b]) -> ((a, b) -> [(a, b)])
shrinkPair shrinkerA shrinkerB (x, y) =
  [ (x', y) | x' <- shrinkerA x ] ++
  [ (x, y') | y' <- shrinkerB y ]
