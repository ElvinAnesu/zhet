# Supabase Database Setup for Chat System

Since the tables are empty, we'll create a clean setup from scratch.

## Setup Steps

Execute these SQL statements in your Supabase SQL Editor:

```sql
-- Drop existing tables if they exist
DROP TABLE IF EXISTS messages;
DROP TABLE IF EXISTS chat_rooms;

-- Create chat_rooms table with user-based structure
CREATE TABLE chat_rooms (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user1_id UUID NOT NULL REFERENCES auth.users(id),
  user2_id UUID NOT NULL REFERENCES auth.users(id),
  last_message TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Ensure users are ordered consistently for uniqueness
  CONSTRAINT user_ordering CHECK (user1_id < user2_id),
  -- Make sure we don't create multiple chat rooms for the same users
  UNIQUE(user1_id, user2_id)
);

-- Create messages table
CREATE TABLE messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  chat_room_id UUID NOT NULL REFERENCES chat_rooms(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES auth.users(id),
  content TEXT NOT NULL,
  status TEXT DEFAULT 'sent',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX chat_rooms_user1_id_idx ON chat_rooms(user1_id);
CREATE INDEX chat_rooms_user2_id_idx ON chat_rooms(user2_id);
CREATE INDEX messages_chat_room_id_idx ON messages(chat_room_id);
CREATE INDEX messages_sender_id_idx ON messages(sender_id);
CREATE INDEX messages_created_at_idx ON messages(created_at);

-- Set up Row Level Security
ALTER TABLE chat_rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- Create policies for chat_rooms
-- Users can view chat rooms they are a part of
CREATE POLICY chat_rooms_select_policy ON chat_rooms 
FOR SELECT USING (
  auth.uid() = user1_id OR auth.uid() = user2_id
);

-- Users can update chat rooms they are a part of
CREATE POLICY chat_rooms_update_policy ON chat_rooms 
FOR UPDATE USING (
  auth.uid() = user1_id OR auth.uid() = user2_id
) WITH CHECK (
  auth.uid() = user1_id OR auth.uid() = user2_id
);

-- Users can create chat rooms only if they are one of the participants
CREATE POLICY chat_rooms_insert_policy ON chat_rooms 
FOR INSERT WITH CHECK (
  auth.uid() = user1_id OR auth.uid() = user2_id
);

-- Create policies for messages
-- Users can view messages in their chat rooms
CREATE POLICY "Users can view messages in their chat rooms" ON messages
FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM chat_rooms
    WHERE id = messages.chat_room_id
    AND (auth.uid() = user1_id OR auth.uid() = user2_id)
  )
);

-- Users can send messages to their chat rooms
CREATE POLICY "Users can send messages to their chat rooms" ON messages
FOR INSERT WITH CHECK (
  EXISTS (
    SELECT 1 FROM chat_rooms
    WHERE id = messages.chat_room_id
    AND (auth.uid() = user1_id OR auth.uid() = user2_id)
  ) AND auth.uid() = sender_id
);

-- Users can update their own messages
CREATE POLICY "Users can update their own messages" ON messages
FOR UPDATE USING (
  auth.uid() = sender_id
) WITH CHECK (
  auth.uid() = sender_id
);

-- Set up realtime for both tables
BEGIN;
  DROP PUBLICATION IF EXISTS supabase_realtime;
  CREATE PUBLICATION supabase_realtime;
COMMIT;

-- Add tables to the publication
ALTER PUBLICATION supabase_realtime ADD TABLE chat_rooms;
ALTER PUBLICATION supabase_realtime ADD TABLE messages;
```

## Verifying the Setup

After running the above SQL:

1. Verify that both tables were created correctly
2. Test creating a new chat between two users
3. Test sending messages between users
4. Confirm that realtime updates work in your application

## Usage Notes

- When creating a new chat, ensure user IDs are sorted (smaller ID first) to maintain the `user_ordering` constraint
- When sending messages, make sure the sender ID matches the authenticated user
- The tables have RLS policies to ensure users can only access their own chats and messages 