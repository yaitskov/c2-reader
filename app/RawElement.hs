{-# LANGUAGE OverloadedStrings #-}

module RawElement
  ( RawElementAction
  , rawElementComponent
  ) where

import           Control.Monad (void)
import           Miso
import qualified Miso.Html.Element as H
import qualified Miso.Html.Property as P
import qualified Miso.Lens as Lens

data RawElementAction
  = RawElementCreated JSVal DOMRef
  | RawElementChanged JSVal

rawElementComponent :: Component context JSVal () RawElementAction
rawElementComponent =
  (component () updateRawElement viewRawElement)
    { onPropsChanged = Just (\_ newRaw -> RawElementChanged newRaw)
    }

viewRawElement :: () -> View context JSVal () RawElementAction
viewRawElement _ =
  vprops $ \raw ->
    H.div_
      [ P.class_ "raw-element-host"
      , onCreatedWith (RawElementCreated raw)
      ]
      []

updateRawElement :: RawElementAction -> Effect context JSVal () RawElementAction
updateRawElement (RawElementCreated raw host) =
  io_ (void (host # "appendChild" $ raw))
updateRawElement (RawElementChanged raw) = do
  host <- Lens.view componentInfoDOMRef
  io_ (void (host # "replaceChildren" $ raw))
