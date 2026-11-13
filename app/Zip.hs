{-# LANGUAGE OverloadedStrings #-}

module Zip
  ( unzip
  ) where

import           Data.Map.Strict (Map)
import qualified Data.Map.Strict as Map
import           Miso (ArrayBuffer, JSVal, MisoString, await, createWith,
                       fromJSValUnchecked, inline, (!))
import qualified Miso.String as MS
import           Prelude hiding (unzip)

-- | Extracts every file of a zip archive into a map from path to content.
--
-- The archive is parsed by @static\/zip.js@ using the browser's native
-- @DecompressionStream@; entries that are encrypted, stored as ZIP64, or use a
-- compression method other than store\/deflate yield a 'Left' with a message.
unzip :: ArrayBuffer -> IO (Either String (Map FilePath ArrayBuffer))
unzip buffer = do
  context <- createWith [("buf", buffer)]
  result <- await =<< (inline "return globalThis.c2zip.unzip(buf);" context :: IO JSVal)
  ok <- fromJSValUnchecked =<< (result ! "ok") :: IO Bool
  if ok
    then do
      files <- fromJSValUnchecked =<< (result ! "files") :: IO (Map MisoString ArrayBuffer)
      pure (Right (Map.mapKeys MS.unpack files))
    else do
      message <- fromJSValUnchecked =<< (result ! "error") :: IO MisoString
      pure (Left (MS.unpack message))
