# Mobile TV Studio — Relay Server

Small Node.js server that lets two phones find each other over the
internet. Video does **not** flow through this server. Only the
signaling messages (offer / answer / ICE candidates) go through here.

Once the two phones have exchanged those messages, WebRTC carries the
video directly between them.

## Why you need it

On the same Wi-Fi, phones can talk directly. Across the internet, they
cannot — neither phone knows the other's public address, and mobile
carriers put phones behind NAT. This server solves that by letting the
two phones introduce themselves.

## What it does not do

This server does **not** relay video. If peer-to-peer fails (some
mobile carriers block it), you also need a TURN server. See "TURN"
below.

## Run it locally

```bash
cd relay-server
npm install
npm start
