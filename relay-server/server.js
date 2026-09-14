'use strict';

const http = require('http');
const WebSocket = require('ws');

const PORT = process.env.PORT || 8080;
const MAX_CLIENTS_PER_ROOM = 8;

const rooms = new Map();

// HTTP server handles both the health check AND WebSocket upgrades.
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
  res.writeHead(200, { 'Content-Type': 'text/plain' });
  res.end('Mobile TV Studio relay is running.');
});

const wss = new WebSocket.Server({ server });

wss.on('connection', (ws) => {
  ws.roomId = null;
  ws.clientId = null;

  ws.on('message', (raw) => {
    let msg;
    try { msg = JSON.parse(raw.toString()); } catch (e) { return; }
    const type = msg.type;
    const room = msg.room;
    if (!room || !type) return;

    if (type === 'join') {
      ws.roomId = room;
      ws.clientId = msg.from || 'anon';
      if (!rooms.has(room)) rooms.set(room, new Set());
      const set = rooms.get(room);
      if (set.size >= MAX_CLIENTS_PER_ROOM) {
        ws.send(JSON.stringify({ type: 'error', room, from: 'server', reason: 'room_full' }));
        ws.close();
        return;
      }
      set.add(ws);
      console.log(`[relay] ${ws.clientId} joined ${room} (${set.size} in room)`);
      broadcast(room, ws, { type: 'peerJoined', room, from: ws.clientId });
      return;
    }

    if (type === 'leave') {
      leaveRoom(ws);
      return;
    }

    broadcast(room, ws, msg);
  });

  ws.on('close', () => leaveRoom(ws));
  ws.on('error', () => leaveRoom(ws));
});

function broadcast(roomId, sender, msg) {
  const set = rooms.get(roomId);
  if (!set) return;
  const payload = JSON.stringify(msg);
  for (const client of set) {
    if (client === sender) continue;
    if (client.readyState === WebSocket.OPEN) client.send(payload);
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
    else broadcast(room, ws, { type: 'peerLeft', room, from: id || 'anon' });
  }
  console.log(`[relay] ${id || 'anon'} left ${room}`);
  ws.roomId = null;
  ws.clientId = null;
}

server.listen(PORT, '0.0.0.0', () => {
  console.log(`[relay] listening on port ${PORT}`);
});

process.on('SIGTERM', () => {
  console.log('[relay] shutting down');
  wss.close();
  server.close();
  process.exit(0);
});
