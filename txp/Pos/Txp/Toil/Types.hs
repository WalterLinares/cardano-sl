{-# LANGUAGE TypeFamilies #-}

-- | Types used for managing of transactions
-- and synchronization with database.

module Pos.Txp.Toil.Types
       ( Utxo
       , formatUtxo
       , utxoF
       , GenesisUtxo (..)
       , _GenesisUtxo

       , TxFee(..)
       , MemPool (..)
       , mpLocalTxs
       , mpSize
       , TxMap
       , StakesView (..)
       , svStakes
       , svTotal
       , UndoMap
       , UtxoModifier
       , fromUtxo
       , GenericToilModifier (..)
       , ToilModifier
       , tmUtxo
       , tmStakes
       , tmMemPool
       , tmUndos
       , tmExtra
       ) where

import           Universum

import           Control.Lens           (makeLenses, makePrisms, makeWrapped)
import           Data.Default           (Default, def)
import qualified Data.Map               as M (toList)
import           Data.Text.Lazy.Builder (Builder)
import           Formatting             (Format, later)
import           Serokell.Util.Text     (mapBuilderJson)

import           Pos.Core               (Coin, StakeholderId)
import           Pos.Txp.Core           (TxAux, TxId, TxIn, TxOutAux (..), TxUndo)
import qualified Pos.Util.Modifier      as MM

----------------------------------------------------------------------------
-- UTXO
----------------------------------------------------------------------------

-- | Unspent transaction outputs.
--
-- Transaction inputs are identified by (transaction ID, index in list of
-- output) pairs.
type Utxo = Map TxIn TxOutAux

-- | Format 'Utxo' map for showing
formatUtxo :: Utxo -> Builder
formatUtxo = mapBuilderJson . M.toList

-- | Specialized formatter for 'Utxo'.
utxoF :: Format r (Utxo -> r)
utxoF = later formatUtxo

-- | Wrapper for genesis utxo.
newtype GenesisUtxo = GenesisUtxo
    { unGenesisUtxo :: Utxo
    } deriving (Show)

makePrisms  ''GenesisUtxo
makeWrapped ''GenesisUtxo

----------------------------------------------------------------------------
-- Fee
----------------------------------------------------------------------------

-- | tx.fee = sum(tx.in) - sum (tx.out)
newtype TxFee = TxFee Coin
    deriving (Show, Eq, Ord, Generic, Buildable)

----------------------------------------------------------------------------
-- StakesView
----------------------------------------------------------------------------

data StakesView = StakesView
    { _svStakes :: !(HashMap StakeholderId Coin)
    , _svTotal  :: !(Maybe Coin)
    }

makeLenses ''StakesView

instance Default StakesView where
    def = StakesView mempty Nothing

----------------------------------------------------------------------------
-- MemPool
----------------------------------------------------------------------------

type TxMap = HashMap TxId TxAux

data MemPool = MemPool
    { _mpLocalTxs :: !TxMap
      -- | Number of transactions in the memory pool.
    , _mpSize     :: !Int
    }

makeLenses ''MemPool

instance Default MemPool where
    def =
        MemPool
        { _mpLocalTxs = mempty
        , _mpSize     = 0
        }

----------------------------------------------------------------------------
-- ToilModifier
----------------------------------------------------------------------------

type UtxoModifier = MM.MapModifier TxIn TxOutAux
type UndoMap = HashMap TxId TxUndo

fromUtxo :: Utxo -> UtxoModifier
fromUtxo = foldr (uncurry MM.insert) mempty . M.toList

instance Default UndoMap where
    def = mempty

data GenericToilModifier extension = ToilModifier
    { _tmUtxo    :: !UtxoModifier
    , _tmStakes  :: !StakesView
    , _tmMemPool :: !MemPool
    , _tmUndos   :: !UndoMap
    , _tmExtra   :: !extension
    }

type ToilModifier = GenericToilModifier ()

instance Default ext => Default (GenericToilModifier ext) where
    def = ToilModifier mempty def def mempty def

makeLenses ''GenericToilModifier
