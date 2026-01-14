import { WebSocketServer, WebSocket } from "ws";
import { v4 as uuid } from "uuid";

type ClientId = string;
type RoomId = string;

type ClientRole = "leader" | "member";

type Incoming =
  | { type: "join"; roomId: RoomId; riderId?: string }
  | { type: "heartbeat"; roomId: RoomId }
  | { type: "chat"; roomId: RoomId; body: string }
  | { type: "rtc-offer"; roomId: RoomId; sdp: string; to?: ClientId }
  | { type: "rtc-answer"; roomId: RoomId; sdp: string; to: ClientId }
  | { type: "rtc-ice"; roomId: RoomId; candidate: unknown; to: ClientId }
  | {
      type: "location";
      roomId: RoomId;
      riderId: string;
      lat: number;
      lng: number;
      heading?: number;
      speed?: number;
      ts: number;
    }
  | {
      type: "route-set";
      roomId: RoomId;
      route: RoutePayload;
    }
  | {
      type: "leader-transfer";
      roomId: RoomId;
      to: ClientId;
    };

type Outgoing =
  | { type: "joined"; roomId: RoomId; clientId: ClientId; leaderId: ClientId }
  | { type: "presence"; roomId: RoomId; clients: PresencePayload[]; leaderId: ClientId }
  | { type: "chat"; roomId: RoomId; from: ClientId; body: string; ts: number }
  | { type: "pong"; roomId: RoomId; ts: number }
  | { type: "rtc-offer"; roomId: RoomId; from: ClientId; sdp: string }
  | { type: "rtc-answer"; roomId: RoomId; from: ClientId; sdp: string; to: ClientId }
  | { type: "rtc-ice"; roomId: RoomId; from: ClientId; candidate: unknown; to: ClientId }
  | {
      type: "location";
      roomId: RoomId;
      riderId: string;
      from: ClientId;
      lat: number;
      lng: number;
      heading?: number;
      speed?: number;
      ts: number;
    }
  | { type: "route-set"; roomId: RoomId; route: RoutePayload; from: ClientId }
  | { type: "leader-transfer"; roomId: RoomId; leaderId: ClientId };

type RoutePayload = {
  id: string;
  start: RouteStop;
  destination: RouteStop;
  stops: RouteStop[];
  polyline?: string;
};

type RouteStop = {
  id: string;
  name: string;
  lat: number;
  lng: number;
};

type PresencePayload = { clientId: ClientId; role: ClientRole; lastSeen: number };

type Room = {
  clients: Map<ClientId, { ws: WebSocket; lastSeen: number }>;
  leaderId: ClientId | null;
};

const rooms: Map<RoomId, Room> = new Map();
const HEARTBEAT_TIMEOUT_MS = 30_000;
const TICK_MS = 5_000;
const PORT = process.env.PORT ? Number(process.env.PORT) : 8080;

const wss = new WebSocketServer({ port: PORT });
console.log(`🚀 RidePulse realtime server running on ws://localhost:${PORT}`);

wss.on("connection", (ws) => {
  const clientId = uuid();
  let roomId: RoomId | null = null;

  ws.on("message", (data) => {
    let msg: Incoming;
    try {
      msg = JSON.parse(String(data));
    } catch {
      return;
    }

    if (msg.type === "join") {
      roomId = msg.roomId;
      const room = rooms.get(roomId) ?? { clients: new Map(), leaderId: null };
      room.clients.set(clientId, { ws, lastSeen: Date.now() });
      if (!room.leaderId) room.leaderId = clientId;
      rooms.set(roomId, room);
      send(ws, { type: "joined", roomId, clientId, leaderId: room.leaderId! });
      broadcastPresence(roomId);
      return;
    }

    if (!roomId) return;
    const room = rooms.get(roomId);
    if (!room) return;

    switch (msg.type) {
      case "heartbeat":
        touch(roomId, clientId);
        send(ws, { type: "pong", roomId, ts: Date.now() });
        break;
      case "chat":
        touch(roomId, clientId);
        broadcast(roomId, {
          type: "chat",
          roomId,
          from: clientId,
          body: msg.body,
          ts: Date.now(),
        });
        break;
      case "rtc-offer": {
        touch(roomId, clientId);
        const offerMsg: Outgoing = { type: "rtc-offer", roomId, from: clientId, sdp: msg.sdp };
        if (msg.to) {
          sendTo(roomId, msg.to, offerMsg);
        } else {
          broadcastExcept(roomId, clientId, offerMsg);
        }
        break;
      }
      case "rtc-answer": {
        touch(roomId, clientId);
        const answerMsg: Outgoing = { type: "rtc-answer", roomId, from: clientId, sdp: msg.sdp, to: msg.to };
        sendTo(roomId, msg.to, answerMsg);
        break;
      }
      case "rtc-ice": {
        touch(roomId, clientId);
        const iceMsg: Outgoing = { type: "rtc-ice", roomId, from: clientId, candidate: msg.candidate, to: msg.to };
        sendTo(roomId, msg.to, iceMsg);
        break;
      }
      case "location": {
        touch(roomId, clientId);
        const locMsg: Outgoing = {
          type: "location",
          roomId,
          riderId: msg.riderId,
          from: clientId,
          lat: msg.lat,
          lng: msg.lng,
          heading: msg.heading,
          speed: msg.speed,
          ts: msg.ts,
        };
        broadcastExcept(roomId, clientId, locMsg);
        break;
      }
      case "route-set": {
        touch(roomId, clientId);
        const roomLeader = rooms.get(roomId)?.leaderId;
        if (roomLeader && roomLeader !== clientId) {
          return;
        }
        const routeMsg: Outgoing = { type: "route-set", roomId, route: msg.route, from: clientId };
        broadcast(roomId, routeMsg);
        break;
      }
      case "leader-transfer": {
        touch(roomId, clientId);
        const room = rooms.get(roomId);
        if (!room) return;
        if (room.leaderId !== clientId) return;
        if (!room.clients.has(msg.to)) return;
        room.leaderId = msg.to;
        rooms.set(roomId, room);
        broadcastPresence(roomId);
        send(ws, { type: "leader-transfer", roomId, leaderId: msg.to });
        break;
      }
    }
  });

  ws.on("close", () => {
    if (!roomId) return;
    const room = rooms.get(roomId);
    room?.clients.delete(clientId);
    rebalance(roomId);
  });
});

setInterval(() => {
  const now = Date.now();
  for (const [roomId, room] of rooms.entries()) {
    let changed = false;
    for (const [clientId, info] of room.clients.entries()) {
      if (now - info.lastSeen > HEARTBEAT_TIMEOUT_MS) {
        info.ws.terminate();
        room.clients.delete(clientId);
        changed = true;
      }
    }
    if (changed) rebalance(roomId);
  }
}, TICK_MS);

function touch(roomId: RoomId, clientId: ClientId) {
  const room = rooms.get(roomId);
  if (!room) return;
  const client = room.clients.get(clientId);
  if (client) client.lastSeen = Date.now();
}

function rebalance(roomId: RoomId) {
  const room = rooms.get(roomId);
  if (!room) return;
  if (room.clients.size === 0) {
    rooms.delete(roomId);
    return;
  }
  if (!room.leaderId || !room.clients.has(room.leaderId)) {
    const nextLeader = room.clients.keys().next().value as ClientId;
    room.leaderId = nextLeader;
  }
  rooms.set(roomId, room);
  broadcastPresence(roomId);
}

function broadcastPresence(roomId: RoomId) {
  const room = rooms.get(roomId);
  if (!room) return;
  const payload: Outgoing = {
    type: "presence",
    roomId,
    leaderId: room.leaderId!,
    clients: Array.from(room.clients.entries()).map(([clientId, info]) => ({
      clientId,
      role: clientId === room.leaderId ? "leader" : "member",
      lastSeen: info.lastSeen,
    })),
  };
  broadcast(roomId, payload);
}

function broadcast(roomId: RoomId, message: Outgoing) {
  const room = rooms.get(roomId);
  if (!room) return;
  const data = JSON.stringify(message);
  for (const [, { ws }] of room.clients.entries()) {
    ws.readyState === WebSocket.OPEN && ws.send(data);
  }
}

function send(ws: WebSocket, message: Outgoing) {
  ws.readyState === WebSocket.OPEN && ws.send(JSON.stringify(message));
}

function sendTo(roomId: RoomId, to: ClientId, message: Outgoing) {
  const room = rooms.get(roomId);
  if (!room) return;
  const target = room.clients.get(to);
  if (!target) return;
  send(target.ws, message);
}

function broadcastExcept(roomId: RoomId, except: ClientId, message: Outgoing) {
  const room = rooms.get(roomId);
  if (!room) return;
  const data = JSON.stringify(message);
  for (const [clientId, { ws }] of room.clients.entries()) {
    if (clientId === except) continue;
    ws.readyState === WebSocket.OPEN && ws.send(data);
  }
}


