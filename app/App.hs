{-# LANGUAGE OverloadedStrings #-}

module App
  ( app
  ) where

import           Data.Maybe (fromMaybe)
import           GHC.Generics (Generic)
import           Help (helpView)
import           Miso
import qualified Miso.Html.Element as H
import qualified Miso.Html.Event as E
import           Miso.JSON
import           Miso.Lens hiding (at, (.=))
import           Miso.Router (route)
import           Route (Route(..))
import           Welcome (welcomeView)

data Action
  = NoOp
  | Init
  | OpenNewBook
  | ShowHelp
  | OpenSettings
  | GoBack
  | EscapePressed
  | RouteChanged Route
  deriving (Eq, Show)

data KeyEvent = KeyEvent
  { eventKey    :: MisoString
  , eventRepeat :: Bool
  }

keyEventDecoder :: Decoder KeyEvent
keyEventDecoder =
  at [] $ withObject "event" $ \o ->
    KeyEvent <$> o .: "key" <*> o .: "repeat"

keyAction :: KeyEvent -> Action
keyAction keyEvent
  | eventRepeat keyEvent = NoOp
  | otherwise =
      fromMaybe NoOp
        (lookup (eventKey keyEvent) keyActions)

keyActions :: [(MisoString, Action)]
keyActions =
  [ ("O", OpenNewBook)
  , ("o", OpenNewBook)
  , ("H", ShowHelp)
  , ("h", ShowHelp)
  , ("K", ShowHelp)
  , ("k", ShowHelp)
  , ("S", OpenSettings)
  , ("s", OpenSettings)
  , ("Escape", EscapePressed)
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
updateModel OpenNewBook = do
  io_ $ consoleLog "Open New Book"
updateModel ShowHelp = do
  io_ $ consoleLog "Show Help"
  navigateTo Help
updateModel OpenSettings = do
  io_ $ consoleLog "Open Settings"
  navigateTo Settings
updateModel GoBack = do
  io_ $ consoleLog "Go back"
  io_ back
updateModel EscapePressed = do
  current <- use this
  case currentRoute current of
    Help -> updateModel GoBack
    Settings -> updateModel GoBack
    _ -> io_ $ consoleLog "Escape ignored"

viewModel :: Model -> View () props Model Action
viewModel m = case currentRoute m of
  Index -> welcomeView OpenNewBook ShowHelp OpenSettings
  Help -> helpView
  Settings -> settingsView m

settingsView :: Model -> View () props Model Action
settingsView _m = H.div_
  [ ]
  [ H.h1_  [] [ text "Settings" ]
  , H.div_ []
    [ H.button_
      [ E.onClick GoBack ]
      [ text "Cancel" ]
    ]
  ]
