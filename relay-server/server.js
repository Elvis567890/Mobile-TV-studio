/**
 * Mobile TV Studio — signaling relay.
 *
 * What this server does:
 *   - Keeps a list of rooms. Each room has at most a few clients
 *     (phones) inside it.
 *   - Forwards signaling messages between clients in the same room:
 *     offer, answer, candidate, join, leave.
 *   - That is it. Video never touches this server. Once the two
 *     phones have exchanged offer/answer/candidates, WebRTC carries
 *     the video directly between them.
 *
 * What this server does NOT do:
 *   - It does not relay video bytes.
 *   - It does not store anything.
 *   - It does not authenticate.
 *
 * If peer-to-peer fails (strict carrier NAT), you also need a TURN
 * server. See the README in this folder.
 */

'use strict';

const WebSocket = require('ws');

const PORT = process.env.PORT || 8080;
const MAX_CLIENTS_PER_ROOM = 8;

// roomId -> Set<WebSocket>
const rooms = new Map();

const wss = new WebSocket.Server({ port: PORT });

console.log(`[relay] listening on port ${PORT}`);

wss.on('connection', (ws, req) => {
  ws.roomId = null;
  ws.clientId = null;

  ws.on('message', (raw) => {
    let msg;
    try {
      msg = JSON.parse(raw.toString());
    } catch (e) {
      return; // ignore malformed frames
    }

    const type = msg.type;
    const room = msg.room;

    if (!room || !type) return;

    // Handle join / leave ourselves.
    if (type === 'join') {
      ws.roomId = room;
      ws.clientId = msg.from || 'anon';

      if (!rooms.has(room)) rooms.set(room, new Set());
      const set = rooms.get(room);

      if (set.size >= MAX_CLIENTS_PER_ROOM) {
        ws.send(JSON.stringify({
          type: 'error',
          room,
          from: 'server',
          reason: 'room_full',
        }));
        ws.close();
        return;
      }

      set.add(ws);
      console.log(`[relay] ${ws.clientId} joined ${room} (${set.size} in room)`);

      // Tell everyone else a new peer arrived.
      broadcast(room, ws, {
        type: 'peerJoined',
        room,
        from: ws.clientId,
      });
      return;
    }

    if (type === 'leave') {
      leaveRoom(ws);
      return;
    }

    // Everything else is forwarded to other clients in the room.
    broadcast(room, ws, msg);
  });

  ws.on('close', () => {
    leaveRoom(ws);
  });

  ws.on('error', () => {
    leaveRoom(ws);
  });
});

function broadcast(roomId, sender, msg) {
  const set = rooms.get(roomId);
  if (!set) return;
  const payload = JSON.stringify(msg);
  for (const client of set) {
    if (client === sender) continue;
    if (client.readyState === WebSocket.OPEN) {
      client.send(payload);
    }
  }
}

function leaveRoom(ws) {
  const room = ws.roomId;
  const id = ws.clientId;
  if (!room) return;

  const set = rooms.get(room);
  if (set) {
    set.delete(ws);
    if (set.size === 0) rooms.delete(room);
    else {
      broadcast(room, ws, {
        type: 'peerLeft',
        room,
        from: id || 'anon',
      });
    }
  }

  console.log(`[relay] ${id || 'anon'} left ${room}`);

  ws.roomId = null;
  ws.clientId = null;
}

// Health check for hosting platforms.
const http = require('http');
const server = http.createServer((req, res) => {
  if (req.url === '/health') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({
      ok: true,
      rooms: rooms.size,
      clients: [...rooms.values()].reduce((n, s) => n + s.size, 0),
    }));
    return;
  }
  res.writeHead(404);
  res.end();
});

// Bind the plain HTTP server on a second port so health checks work
// while WebSocket traffic stays on the main port. Or just reuse one.
server.listen(PORT + 1, () => {
  console.log(`[relay] health on port ${PORT + 1} (/health)`);
});

process.on('SIGTERM', () => {
  console.log('[relay] shutting down');
  wss.close();
  server.close();
  process.exit(0);
});
