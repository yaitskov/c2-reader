{-# LANGUAGE DeriveAnyClass     #-}
{-# LANGUAGE DeriveGeneric      #-}
{-# LANGUAGE DerivingStrategies #-}

module Route
  ( Route(..)
  ) where

import           GHC.Generics (Generic)
import           Miso.JSON
import           Miso.Router (Router(..))

data Route = Index | Settings
  deriving stock (Eq, Show, Generic)
  deriving anyclass (Router)

instance ToJSON Route
instance FromJSON Route
