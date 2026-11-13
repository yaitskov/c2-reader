{-# LANGUAGE CPP #-}

module Main where

import           App (app)
import           Miso

#ifdef WASM
foreign export javascript "hs_start" main :: IO ()
#endif

main :: IO ()
main = do
  startAppWithContext (defaultEvents <> mouseEvents) () app
