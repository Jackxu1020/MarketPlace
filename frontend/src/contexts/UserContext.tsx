import { createContext, useContext, useState, useEffect } from 'react';
import type { ReactNode } from 'react';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import type { Channel } from 'phoenix';
import { api } from '../api/client';
import { joinUserChannel, leaveChannel } from '../lib/socket';
import type { User, Order } from '../types';

interface UserContextValue {
  users: User[];
  currentUser: User | null;
  setCurrentUserId: (id: number | null) => void;
  isLoading: boolean;
}

const UserContext = createContext<UserContextValue | null>(null);

export function UserProvider({ children }: { children: ReactNode }) {
  const queryClient = useQueryClient();
  const [currentUserId, setCurrentUserId] = useState<number | null>(null);
  const [userChannel, setUserChannel] = useState<Channel | null>(null);

  const { data: usersData, isLoading: usersLoading } = useQuery({
    queryKey: ['users'],
    queryFn: () => api.getUsers(),
  });

  const { data: userData, isLoading: userLoading } = useQuery({
    queryKey: ['user', currentUserId],
    queryFn: () => api.getUser(currentUserId!),
    enabled: currentUserId !== null,
  });

  // Join user channel when user changes
  useEffect(() => {
    if (currentUserId === null) {
      leaveChannel(userChannel);
      setUserChannel(null);
      return;
    }

    leaveChannel(userChannel);
    const channel = joinUserChannel(currentUserId);
    setUserChannel(channel);

    channel.join();

    channel.on('order_filled', (order: Order) => {
      console.log('Order filled:', order);
      // Invalidate user data to refresh balance
      queryClient.invalidateQueries({ queryKey: ['user', currentUserId] });
    });

    channel.on('order_cancelled', (order: Order) => {
      console.log('Order cancelled:', order);
    });

    channel.on('order_expired', (order: Order) => {
      console.log('Order expired:', order);
    });

    return () => {
      leaveChannel(channel);
    };
  }, [currentUserId, queryClient]);

  const users = usersData?.data || [];
  const currentUser = userData?.data || null;

  return (
    <UserContext.Provider
      value={{
        users,
        currentUser,
        setCurrentUserId,
        isLoading: usersLoading || (currentUserId !== null && userLoading),
      }}
    >
      {children}
    </UserContext.Provider>
  );
}

export function useUser() {
  const context = useContext(UserContext);
  if (!context) {
    throw new Error('useUser must be used within a UserProvider');
  }
  return context;
}
