module PeerJS.Connection
  ( Connection
  , close
  , onClose
  , onData
  , peer
  , send
  ) where

import Prelude

import Effect (Effect)
import Effect.Uncurried (EffectFn1)
import Effect.Uncurried as Effect.Uncurried
import PeerJS.PeerID (PeerID)
import Unsafe.Reference as Unsafe.Reference

foreign import data Connection :: Type

instance Eq Connection where
  eq = Unsafe.Reference.unsafeRefEq

foreign import send
  :: Connection
  -> String -- TODO: could be Foreign
  -> Effect Unit

foreign import _onData
  :: Connection
  -> EffectFn1 String Unit -- TODO: could be EffectFn1 Foreign Unit
  -> Effect Unit

onData :: Connection -> (String -> Effect Unit) -> Effect Unit
onData connection callback = _onData connection (Effect.Uncurried.mkEffectFn1 callback)

foreign import onClose :: Connection -> Effect Unit -> Effect Unit
foreign import close :: Connection -> Effect Unit

foreign import peer :: Connection -> PeerID
