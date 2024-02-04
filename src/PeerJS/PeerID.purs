module PeerJS.PeerID
  ( PeerID
  , toString
  , unsafeFromString
  ) where

import Prelude

newtype PeerID = PeerID String

derive newtype instance Show PeerID
derive newtype instance Eq PeerID
derive newtype instance Ord PeerID

toString :: PeerID -> String
toString (PeerID peerID) = peerID

-- TODO: This is only exposed to allow constructing a PeerID from user input,
-- which would be copy-pasted from another browser window.
unsafeFromString :: String -> PeerID
unsafeFromString = PeerID