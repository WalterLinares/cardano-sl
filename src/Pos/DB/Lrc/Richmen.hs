{-# LANGUAGE AllowAmbiguousTypes       #-}
{-# LANGUAGE ExistentialQuantification #-}
{-# LANGUAGE RankNTypes                #-}
{-# LANGUAGE ScopedTypeVariables       #-}
{-# LANGUAGE TypeFamilies              #-}

-- | Richmen part of LRC DB.

module Pos.DB.Lrc.Richmen
       (
         -- * Generalization
         RichmenComponent (..)
       , SomeRichmenComponent

         -- * Getters
       , getRichmen

       -- * Operations
       , putRichmen

       -- * Initialization
       , prepareLrcRichmen
       ) where

import           Universum

import           Pos.Binary.Class  (Bi, encodeStrict)
import           Pos.Binary.Types  ()
import           Pos.DB.Class      (MonadDB)
import           Pos.DB.Lrc.Common (getBi, putBi)
import           Pos.Types         (EpochIndex, FullRichmenData)

----------------------------------------------------------------------------
-- Class
----------------------------------------------------------------------------

class Bi (RichmenData a) =>
      RichmenComponent a where
    type RichmenData a :: *
    rcToData :: FullRichmenData -> RichmenData a
    rcTag :: Proxy a -> ByteString

data SomeRichmenComponent =
    forall c. RichmenComponent c =>
              SomeRichmenComponent (Proxy c)

----------------------------------------------------------------------------
-- Getters
----------------------------------------------------------------------------

getRichmen
    :: forall c ssc m.
       (RichmenComponent c, MonadDB ssc m)
    => EpochIndex -> m (Maybe (RichmenData c))
getRichmen = getBi . richmenKey @c

getRichmenP
    :: forall c ssc m.
       (RichmenComponent c, MonadDB ssc m)
    => Proxy c -> EpochIndex -> m (Maybe (RichmenData c))
getRichmenP Proxy = getRichmen @c

----------------------------------------------------------------------------
-- Operations
----------------------------------------------------------------------------

putRichmen
    :: forall c ssc m.
       (RichmenComponent c, MonadDB ssc m)
    => EpochIndex -> FullRichmenData -> m ()
putRichmen e = putBi (richmenKey @c e) . (rcToData @c)

putRichmenP
    :: forall c ssc m.
       (RichmenComponent c, MonadDB ssc m)
    => Proxy c -> EpochIndex -> FullRichmenData -> m ()
putRichmenP Proxy = putRichmen @c

----------------------------------------------------------------------------
-- Initialization
----------------------------------------------------------------------------

prepareLrcRichmen
    :: MonadDB ssc m
    => [(SomeRichmenComponent, FullRichmenData)] -> m ()
prepareLrcRichmen = mapM_ prepareLrcRichmenDo
  where
    prepareLrcRichmenDo (SomeRichmenComponent proxy, frd) = do
        putIfEmpty (getRichmenP proxy 0) (putRichmenP proxy 0 undefined)

putIfEmpty
    :: forall a m.
       Monad m
    => (m (Maybe a)) -> m () -> m ()
putIfEmpty getter putter = maybe putter (const pass) =<< getter

----------------------------------------------------------------------------
-- General Keys
----------------------------------------------------------------------------

richmenKey
    :: forall c.
       RichmenComponent c
    => EpochIndex -> ByteString
richmenKey = richmenKeyP proxy
  where
    proxy :: Proxy c
    proxy = Proxy

richmenKeyP
    :: forall c.
       RichmenComponent c
    => Proxy c -> EpochIndex -> ByteString
richmenKeyP proxy e = mconcat ["r/", rcTag proxy, "/", encodeStrict e]

----------------------------------------------------------------------------
-- Instances
----------------------------------------------------------------------------
