-- Check the current state of message statuses
SELECT 
  id, 
  chat_room_id, 
  sender_id, 
  status, 
  created_at 
FROM messages 
WHERE status != 'read'
ORDER BY created_at DESC;

-- Check how many unread messages there are per chat room
SELECT 
  chat_room_id, 
  COUNT(*) as unread_count 
FROM messages 
WHERE status != 'read' 
GROUP BY chat_room_id;

-- Fix: Mark all messages as read (run this if needed)
UPDATE messages
SET status = 'read'
WHERE status != 'read';

-- Check if there are any RLS policies that might be blocking the update
SELECT * FROM pg_policies WHERE tablename = 'messages';

-- Create or fix the RLS policy for updating messages
-- This ensures users can mark messages as read
DROP POLICY IF EXISTS "Users can update message status" ON messages;

CREATE POLICY "Users can update message status" ON messages
FOR UPDATE 
USING (
  EXISTS (
    SELECT 1 FROM chat_rooms
    WHERE id = messages.chat_room_id
    AND (auth.uid() = user1_id OR auth.uid() = user2_id)
  )
) 
WITH CHECK (
  EXISTS (
    SELECT 1 FROM chat_rooms
    WHERE id = messages.chat_room_id
    AND (auth.uid() = user1_id OR auth.uid() = user2_id)
  )
);

-- Add a trigger function to update the last_activity timestamp
-- This ensures chat rooms are properly updated when messages change status
CREATE OR REPLACE FUNCTION update_chat_room_on_message_update()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE chat_rooms
  SET updated_at = NOW()
  WHERE id = NEW.chat_room_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create the trigger if it doesn't exist
DROP TRIGGER IF EXISTS message_update_chat_room ON messages;
CREATE TRIGGER message_update_chat_room
AFTER UPDATE ON messages
FOR EACH ROW
EXECUTE FUNCTION update_chat_room_on_message_update();

-- Verify that message status can be updated by authenticating as the current user
-- (Run this in your app code or use the Supabase dashboard to test) 