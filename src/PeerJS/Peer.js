import Peer from "peerjs";

export const _new = (config) => () => new Peer(config);

export const destroy = (peer) => () => peer.destroy();

export const _onOpen = (peer) => (callback) => () => peer.on("open", callback);

export const onClose = (peer) => (callback) => () => peer.on("close", callback);

export const connect = (peer) => (peerID) => () => peer.connect(peerID);

export const _onConnection = (peer) => (callback) => () =>
  peer.on("connection", callback);
