export const send = (conn) => (message) => () => conn.send(message);

export const close = (conn) => () => conn.close();

export const _onData = (conn) => (callback) => () => conn.on("data", callback);

export const onClose = (conn) => (callback) => () => conn.on("close", callback);

export const peer = (conn) => conn.peer;
