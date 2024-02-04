module PeerJS.Peer
  ( Peer
  , Config
  , connect
  , new
  , newAff
  , destroy
  , onClose
  , onConnection
  , onOpen
  ) where

import Prelude

import Data.Either (Either(..))
import Effect (Effect)
import Effect.Aff as Aff
import Effect.Aff.Class (class MonadAff)
import Effect.Aff.Class as Aff.Class
import Effect.Uncurried (EffectFn1)
import Effect.Uncurried as Effect.Uncurried
import PeerJS.Connection (Connection)
import PeerJS.PeerID (PeerID)

foreign import data Peer :: Type
type Config = { host :: String, port :: Int, path :: String }

foreign import _new :: Config -> Effect Peer

new :: Config -> Effect Peer
new = _new

foreign import destroy :: Peer -> Effect Unit

foreign import _onOpen :: Peer -> EffectFn1 PeerID Unit -> Effect Unit

onOpen :: Peer -> (PeerID -> Effect Unit) -> Effect Unit
onOpen peer callback = _onOpen peer (Effect.Uncurried.mkEffectFn1 callback)

foreign import onClose :: Peer -> Effect Unit -> Effect Unit

-- | Create a new Peer and wait for the "open" event before returning
-- | the Peer instance.
newAff
  :: forall m
   . MonadAff m
  => Config
  -> (PeerID -> Effect (Effect Unit))
  -> m Peer
newAff config callback = Aff.Class.liftAff do
  Aff.makeAff \k -> do
    peer <- new config
    onOpen peer \peerID -> do
      handleClose <- callback peerID
      onClose peer handleClose
      k (Right peer)
    pure Aff.nonCanceler

foreign import connect :: Peer -> PeerID -> Effect Connection

foreign import _onConnection :: Peer -> EffectFn1 Connection Unit -> Effect Unit

onConnection :: Peer -> (Connection -> Effect Unit) -> Effect Unit
onConnection peer callback = _onConnection peer (Effect.Uncurried.mkEffectFn1 callback)