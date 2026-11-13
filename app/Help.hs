{-# LANGUAGE OverloadedStrings #-}

module Help
  ( helpView
  ) where

import           Miso
import qualified Miso.Html.Element as H
import qualified Miso.Html.Property as P

data HelpShortcut = HelpShortcut
  { shortcutKeys   :: MisoString
  , shortcutAction :: MisoString
  }

data HelpSection = HelpSection
  { sectionTitle     :: MisoString
  , sectionShortcuts :: [HelpShortcut]
  }

helpSections :: [HelpSection]
helpSections =
  [ HelpSection "Navigation"
    [ HelpShortcut "← / →" "Previous / next chapter"
    , HelpShortcut "↑ or Shift+Space" "Previous chapter when at the top"
    , HelpShortcut "↓ or Space" "Next chapter when at the bottom"
    , HelpShortcut "c" "Go to book content"
    ]
  , HelpSection "Book"
    [ HelpShortcut "o" "Open a new book"
    , HelpShortcut "q" "Close the book"
    , HelpShortcut "r" "Remove the open book from the library"
    ]
  , HelpSection "Help"
    [ HelpShortcut "h / k" "Show this help"
    , HelpShortcut "s" "Open settings"
    , HelpShortcut "Esc" "Close menus and dialogs"
    ]
  , HelpSection "Mouse"
    [ HelpShortcut "Ctrl/Cmd + click" "Follow the link"
    ]
  ]

helpView :: View context props model action
helpView = H.section_ [ P.id_ "c2-help" ] (map sectionView helpSections)

sectionView :: HelpSection -> View context props model action
sectionView section = H.section_ []
  [ H.h2_ [] [ text (sectionTitle section) ]
  , H.dl_ [] (concatMap shortcutView (sectionShortcuts section))
  ]

shortcutView :: HelpShortcut -> [View context props model action]
shortcutView shortcut =
  [ H.dt_ [] [ H.kbd_ [] [ text (shortcutKeys shortcut) ] ]
  , H.dd_ [] [ text (shortcutAction shortcut) ]
  ]
