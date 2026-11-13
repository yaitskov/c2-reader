{-# LANGUAGE OverloadedStrings #-}

module App
  ( app
  ) where

import           Data.Maybe (fromMaybe)
import           GHC.Generics (Generic)
import           Miso
import qualified Miso.Html.Element as H
import qualified Miso.Html.Event as E
import           Miso.JSON
import           Miso.Lens hiding (at, (.=))
import           Miso.Router (route)
import           Route (Route(..))

data Action
  = NoOp
  | Init
  | OpenSettings
  | CancelSettings
  | RouteChanged Route
  deriving (Eq, Show)

data KeyEvent = KeyEvent
  { eventCode   :: MisoString
  , eventKey    :: MisoString
  , eventRepeat :: Bool
  }

keyEventDecoder :: Decoder KeyEvent
keyEventDecoder =
  at [] $ withObject "event" $ \o ->
    KeyEvent <$> o .: "code" <*> o .: "key" <*> o .: "repeat"

keyAction :: KeyEvent -> Action
keyAction keyEvent
  | eventRepeat keyEvent = NoOp
  | otherwise =
      fromMaybe NoOp
        (lookup (eventKey keyEvent) keyActions)

keyActions :: [(MisoString, Action)]
keyActions =
  [ ("S", OpenSettings)
  , ("s", OpenSettings)
  ]

data Model = Model
  { currentRoute    :: Route
  } deriving (Eq, Show, Generic)

initialModel :: Model
initialModel = Model
  { currentRoute = Index
  }

app :: Component () () Model Action
app = (component initialModel updateModel viewModel)
  { subs =
      [ windowSub "keydown" keyEventDecoder keyAction
      , routerSub (RouteChanged . either (const Index) id)
      ]
  , mount = Just Init
  }


navigateTo :: Route -> Effect ctx props Model Action
navigateTo tr = do
  io_ $ pushRoute tr
  modify (\x -> x { currentRoute = tr })


initialRoute :: IO Route
initialRoute = either (const Index) id . route <$> getURI

updateModel :: Action -> Effect context props Model Action
updateModel NoOp = do
  io_ $ consoleLog "NoOp"
updateModel Init = do
  io_ $ consoleLog "Init C2"
  sync (RouteChanged <$> initialRoute)
updateModel (RouteChanged target) = do
  current <- use this
  io_ $ consoleLog ("Navigate to " <> (ms $ show target))
  assign this current { currentRoute = target }
updateModel OpenSettings = do
  io_ $ consoleLog "Open Settings"
  navigateTo Settings
updateModel CancelSettings = do
  io_ $ consoleLog "Cancel Settings"
  io_ back

viewModel :: Model -> View () props Model Action
viewModel m = case currentRoute m of
  Index -> mainView m
  Settings -> settingsView m

mainView :: Model -> View () props Model Action
mainView _m = H.div_
  [ onWithOptions BUBBLE preventDefault "mousedown" emptyDecoder (\() _ _ -> NoOp) ]
  [ H.h1_ [] [ text "C2 reader" ]
  ]

settingsView :: Model -> View () props Model Action
settingsView _m = H.div_
  [ ]
  [ H.h1_  [] [ text "Settings" ]
  , H.div_ []
    [ H.button_
      [ E.onClick CancelSettings ]
      [ text "Cancel" ]
    ]
  ]
