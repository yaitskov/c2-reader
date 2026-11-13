{-# LANGUAGE OverloadedStrings #-}

module Welcome
  ( welcomeView
  ) where

import           Miso
import qualified Miso.Html.Element as H
import qualified Miso.Html.Event as E
import qualified Miso.Html.Property as P

welcomeView
  :: action
  -> action
  -> action
  -> View context props model action
welcomeView onOpenNewBook onShowHelp onShowSettings =
  H.section_ [ P.id_ "c2-welcome" ]
  [ H.header_ []
    [ H.h1_ []
      [ text "📖 Adaptive E-reader "
      , H.span_ [ P.class_ "c2" ] [ text "C2" ]
      ]
    ]
  , H.p_ []
    [ text "Welcome to "
    , H.span_ [ P.class_ "c2" ] [ text "C2" ]
    , text " bookreader! It's a bookreader dedicated for "
    , H.em_ [] [ text "ESL" ]
    , text " readers that adapts a book content to user's language level. If a book vocabulary is too hard for you, lower down the threshold for the minimum allowed word frequency in the app settings."
    ]
  , H.p_ []
    [ text "There is no an open book. Click "
    , H.button_
      [ P.id_ "load-new-book"
      , P.type_ "button"
      , P.autofocus_ True
      , P.class_ "cta"
      , E.onClick onOpenNewBook
      ]
      [ text "open" ]
    , text " or press "
    , H.kbd_ [] [ text "o" ]
    , text " key to choose a book from the device."
    ]
  , H.p_ []
    [ text "Click "
    , H.button_
      [ P.id_ "show-help"
      , P.type_ "button"
      , P.class_ "cta"
      , E.onClick onShowHelp
      ]
      [ text "help" ]
    , text " or press "
    , H.kbd_ [] [ text "h" ]
    , text " key to see keyboard shortcuts and mouse actions."
    ]
  , H.p_ []
    [ text "Click "
    , H.button_
      [ P.id_ "show-settings"
      , P.type_ "button"
      , P.class_ "cta"
      , E.onClick onShowSettings
      ]
      [ text "settings" ]
    , text " or press "
    , H.kbd_ [] [ text "s" ]
    , text " key to change app settings."
    ]
  ]
