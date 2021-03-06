module TicketDispenserSpec (spec) where

import           Test.Hspec
                   (Spec, around, describe, it)
import           Test.Hspec.QuickCheck
                   (modifyMaxSuccess)

import           HspecInstance
                   ()
import           TicketDispenser

------------------------------------------------------------------------

spec :: Spec
spec = do

  describe "Sequential property" $

    around withDbLock $

      it "`prop_ticketDispenser`: the model is sequentially sound"
        prop_ticketDispenser

  describe "Parallel property" $ do

    it "prop_ticketGenParallelValid: generated parallel programs are valid"
      prop_ticketGenParallelValid

    it "prop_ticketShrinkParallelValid: shrinked parallel programs are valid"
      prop_ticketShrinkParallelValid

    around withDbLock $ modifyMaxSuccess (const 5) $

      it "`prop_ticketDispenserParallelOK`: works with exclusive file locks"
        prop_ticketDispenserParallelOK

    around withDbLock $ modifyMaxSuccess (const 5) $

      it "`prop_ticketDispenserParallelBad`: counterexample is found when file locks are shared"
        prop_ticketDispenserParallelBad
