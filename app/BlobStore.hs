{-# LANGUAGE DerivingStrategies         #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE OverloadedStrings          #-}

module BlobStore
  ( BSM
  , BlobStoreEntry(..)
  , FileName
  , Sha1(..)
  , StoreName
  , deleteEntry
  , getEntry
  , listEntries
  , persist
  , withinBlobStore
  ) where

import           Control.Monad.IO.Class (MonadIO, liftIO)
import           Control.Monad.Trans.Reader (ReaderT, ask, runReaderT)
import           Data.Time.Clock (UTCTime)
import           Data.Time.Clock.POSIX (posixSecondsToUTCTime)
import           Miso (ArrayBuffer, MisoString, await, fromJSValUnchecked, jsg, (#))
import qualified Miso.String as MS

-- | Name of an object store inside the blob database.
type StoreName = String

-- | Original name of a persisted file.
type FileName = String

-- | Lowercase hex SHA-1 digest of a blob, used as its primary key.
newtype Sha1 = Sha1 { unSha1 :: String }
  deriving stock (Eq, Ord, Show)

-- | Metadata for a persisted blob.
data BlobStoreEntry = BlobStoreEntry
  { blobKey :: Sha1
  , name :: String
  , uploadedAt :: UTCTime
  }
  deriving stock (Eq, Show)

-- | A computation scoped to a single 'StoreName' within the blob database.
newtype BSM m a = BSM (ReaderT StoreName m a)
  deriving newtype (Functor, Applicative, Monad, MonadIO)

askStore :: Monad m => BSM m StoreName
askStore = BSM ask

-- | Runs a blob-store computation against the given object store.
withinBlobStore :: MonadIO m => StoreName -> BSM m a -> m a
withinBlobStore storeName (BSM action) = runReaderT action storeName

-- | Stores a blob and returns the SHA-1 key it is addressed by. Persisting
-- identical content again overwrites the stored name and timestamp.
persist :: MonadIO m => FileName -> ArrayBuffer -> BSM m Sha1
persist fileName buffer = do
  store <- askStore
  liftIO $ do
    blob <- jsg "c2blob"
    key <- await =<< (blob # "persist" $ (MS.ms store, MS.ms fileName, buffer))
    Sha1 . MS.unpack <$> (fromJSValUnchecked key :: IO MisoString)

-- | Lists the metadata of every blob in the current object store.
listEntries :: MonadIO m => BSM m [BlobStoreEntry]
listEntries = do
  store <- askStore
  liftIO $ do
    blob <- jsg "c2blob"
    raw <- await =<< (blob # "list" $ MS.ms store)
    entries <- fromJSValUnchecked raw :: IO [(MisoString, MisoString, Double)]
    pure (map toEntry entries)
  where
    toEntry (key, entryName, millis) =
      BlobStoreEntry
        { blobKey = Sha1 (MS.unpack key)
        , name = MS.unpack entryName
        , uploadedAt = posixSecondsToUTCTime (realToFrac (millis / 1000))
        }

-- | Deletes a blob by key. Missing keys are ignored.
deleteEntry :: MonadIO m => Sha1 -> BSM m ()
deleteEntry (Sha1 key) = do
  store <- askStore
  liftIO $ do
    blob <- jsg "c2blob"
    _ <- await =<< (blob # "remove" $ (MS.ms store, MS.ms key))
    pure ()

-- | Loads a blob by key, throwing a 'JSException' if it is missing.
getEntry :: MonadIO m => Sha1 -> BSM m ArrayBuffer
getEntry (Sha1 key) = do
  store <- askStore
  liftIO $ do
    blob <- jsg "c2blob"
    raw <- await =<< (blob # "get" $ (MS.ms store, MS.ms key))
    fromJSValUnchecked raw
