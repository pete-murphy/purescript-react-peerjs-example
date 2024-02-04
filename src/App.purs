module App where

import Prelude

import Data.Foldable as Foldable
import Data.Map as Map
import Data.Maybe (Maybe(..))
import Data.Maybe as Maybe
import Data.Tuple (Tuple(..))
import Effect (Effect)
import Effect.Now as Effect
import JS.Intl.DateTimeFormat as Intl.DateTimeFormat
import PeerJS.Connection as Connection
import PeerJS.Peer as Peer
import PeerJS.PeerID (PeerID)
import PeerJS.PeerID as PeerID
import React.Basic.DOM as DOM
import React.Basic.DOM.Events as DOM.Events
import React.Basic.Events as Events
import React.Basic.Hooks (Component, (/\))
import React.Basic.Hooks as Hooks

mkApp :: Component Unit
mkApp = do
  let config = { host: "localhost", port: 9000, path: "/example" }

  activeConnection <- mkActiveConnection

  timeFormat <-
    Intl.DateTimeFormat.format <$>
      Intl.DateTimeFormat.new [] { hour: "numeric", minute: "numeric", second: "numeric" }

  Hooks.component "App" \_ -> Hooks.do
    peer /\ setPeer <- Hooks.useState' Nothing
    peerID /\ setPeerID <- Hooks.useState' Nothing

    peerInput /\ setPeerInput <- Hooks.useState' ""

    activeConnectionsByPeer /\ setActiveConnectionsByPeer <- Hooks.useState Map.empty
    messagesByPeer /\ setMessagesByPeer <- Hooks.useState Map.empty

    activeConnectionsAndMessagesByPeer <- Hooks.useMemo { activeConnectionsByPeer, messagesByPeer } \_ -> do
      Map.intersectionWith
        (\connection messages -> { connection, messages })
        activeConnectionsByPeer
        messagesByPeer

    handleConnection <- Hooks.useMemo unit \_ connection -> do
      let other = Connection.peer connection
      setActiveConnectionsByPeer (Map.insert other connection)
      setMessagesByPeer (Map.insert other [])

      Connection.onData connection \data_ -> do
        now <- Effect.nowDateTime
        setMessagesByPeer (Map.insertWith (<>) other [ { timeStamp: timeFormat now, content: data_, fromSelf: false } ])

      Connection.onClose connection do
        setActiveConnectionsByPeer (Map.delete other)

    sendMessage <- Hooks.useMemo unit \_ connection message -> do
      let other = Connection.peer connection
      now <- Effect.nowDateTime
      setMessagesByPeer (Map.insertWith (<>) other [ { timeStamp: timeFormat now, content: message, fromSelf: true } ])
      Connection.send connection message

    Hooks.useEffectOnce do
      self <- Peer.new config
      setPeer (Just self)

      Peer.onOpen self \id -> do
        setPeerID (Just id)

        Peer.onConnection self handleConnection

        Peer.onClose self do
          setPeerID Nothing

      pure (Peer.destroy self)

    let
      newConnectionForm = DOM.form
        { className: "grid gap-4"
        , onSubmit: Events.handler DOM.Events.preventDefault \_ -> do
            let other = PeerID.unsafeFromString peerInput
            Foldable.for_ peer \peer_ -> do
              Peer.connect peer_ other >>= handleConnection
            setPeerInput ""
            mempty
        , children:
            [ DOM.label
                { className: "grid gap-2 w-max"
                , children:
                    [ DOM.text "Enter an ID to connect to:"
                    , DOM.input
                        { className: "border-2 border-black rounded p-1"
                        , value: peerInput
                        , onChange: Events.handler DOM.Events.targetValue \value -> do
                            Foldable.for_ value setPeerInput
                        }
                    ]
                }
            , DOM.div_
                [ DOM.button
                    { className: "bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded"
                    , children: [ DOM.text "Connect" ]
                    }
                ]
            ]
        }

    pure
      ( DOM.div
          { className: "grid grid-rows-[auto_1fr] min-h-[100dvh] *:p-4"
          , children:
              [ DOM.header_ [ DOM.text ("This ID: " <> (peerID <#> PeerID.toString # Maybe.fromMaybe "...")) ]
              , DOM.main
                  { className: ""
                  , children:
                      ( if Foldable.null activeConnectionsByPeer then
                          [ DOM.h1
                              { className: "text-3xl mb-8"
                              , children: [ DOM.text "No active connections" ]
                              }
                          ]

                        else
                          activeConnectionsAndMessagesByPeer
                            # Map.toUnfoldable
                            <#> \(Tuple id { connection, messages }) ->
                              Hooks.keyed (PeerID.toString id) (activeConnection { messages, sendMessage: sendMessage connection, other: Connection.peer connection })
                      )
                        <> [ newConnectionForm ]
                  }
              ]
          }
      )

type Message =
  { timeStamp :: String
  , content :: String
  , fromSelf :: Boolean
  }

mkActiveConnection
  :: Component
       { sendMessage :: String -> Effect Unit
       , messages :: Array Message
       , other :: PeerID
       }
mkActiveConnection = do
  Hooks.component "ActiveConnection" \props -> Hooks.do
    messageInput /\ setMessageInput <- Hooks.useState' ""

    pure
      ( DOM.div
          { className: "grid gap-1 py-2"
          , children:
              [ DOM.h2_ [ DOM.text ("Connected to: " <> PeerID.toString props.other) ]
              , DOM.ul_
                  ( props.messages <#> \message ->
                      DOM.li
                        { className: if message.fromSelf then "text-blue-600" else ""
                        , children:
                            [ DOM.span { className: "font-bold", children: [ DOM.text (message.timeStamp <> " ") ] }
                            , DOM.text message.content
                            ]
                        }
                  )
              , DOM.form
                  { className: "flex gap-2"
                  , onSubmit: Events.handler DOM.Events.preventDefault \_ -> do
                      props.sendMessage messageInput
                      setMessageInput ""
                  , children:
                      [ DOM.input
                          { className: "border-2 border-black rounded p-1"
                          , value: messageInput
                          , onChange: Events.handler DOM.Events.targetValue \value -> do
                              Foldable.for_ value setMessageInput
                          }
                      , DOM.button
                          { children: [ DOM.text "Send" ]
                          }
                      ]
                  }
              ]
          }
      )