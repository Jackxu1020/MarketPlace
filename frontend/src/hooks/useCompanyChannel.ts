import { useEffect, useState, useCallback } from 'react';
import type { Channel } from 'phoenix';
import { joinCompanyChannel, leaveChannel } from '../lib/socket';
import type { OrderBook, Trade } from '../types';

interface UseCompanyChannelResult {
  orderBook: OrderBook | null;
  recentTrades: Trade[];
  isConnected: boolean;
}

export function useCompanyChannel(companyId: number | null): UseCompanyChannelResult {
  const [channel, setChannel] = useState<Channel | null>(null);
  const [orderBook, setOrderBook] = useState<OrderBook | null>(null);
  const [recentTrades, setRecentTrades] = useState<Trade[]>([]);
  const [isConnected, setIsConnected] = useState(false);

  const addTrade = useCallback((trade: Trade) => {
    setRecentTrades((prev) => [trade, ...prev].slice(0, 50));
  }, []);

  useEffect(() => {
    if (companyId === null) {
      leaveChannel(channel);
      setChannel(null);
      setOrderBook(null);
      setRecentTrades([]);
      setIsConnected(false);
      return;
    }

    leaveChannel(channel);

    const newChannel = joinCompanyChannel(companyId);
    setChannel(newChannel);

    newChannel
      .join()
      .receive('ok', (response: { order_book: OrderBook; recent_trades: Trade[] }) => {
        setOrderBook(response.order_book);
        setRecentTrades(response.recent_trades);
        setIsConnected(true);
      })
      .receive('error', (err) => {
        console.error('Failed to join company channel:', err);
        setIsConnected(false);
      });

    newChannel.on('order_book_update', (orderBook: OrderBook) => {
      setOrderBook(orderBook);
    });

    newChannel.on('new_trade', (trade: Trade) => {
      addTrade(trade);
    });

    return () => {
      leaveChannel(newChannel);
    };
  }, [companyId, addTrade]);

  return { orderBook, recentTrades, isConnected };
}
