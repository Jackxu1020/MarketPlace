import { Socket } from 'phoenix';
import type { Channel } from 'phoenix';

const SOCKET_URL = 'ws://localhost:4000/socket';

let socket: Socket | null = null;

export function getSocket(): Socket {
  if (!socket) {
    socket = new Socket(SOCKET_URL, {});
    socket.connect();
  }
  return socket;
}

export function joinCompanyChannel(companyId: number): Channel {
  const s = getSocket();
  const channel = s.channel(`company:${companyId}`, {});
  return channel;
}

export function joinUserChannel(userId: number): Channel {
  const s = getSocket();
  const channel = s.channel(`user:${userId}`, {});
  return channel;
}

export function leaveChannel(channel: Channel | null): void {
  if (channel) {
    channel.leave();
  }
}
