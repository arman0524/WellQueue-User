-- Migration: Fix Row Level Security (RLS) policies and Realtime for queue_entries

-- 1. Ensure RLS is enabled on queue_entries
ALTER TABLE public.queue_entries ENABLE ROW LEVEL SECURITY;

-- 2. Drop existing restrictive policies if any to avoid conflicts
DROP POLICY IF EXISTS "Users can view their own queue entries" ON public.queue_entries;
DROP POLICY IF EXISTS "Users can view their own and active queue entries" ON public.queue_entries;
DROP POLICY IF EXISTS "Users can view active queue entries" ON public.queue_entries;
DROP POLICY IF EXISTS "Users can insert their own queue entries" ON public.queue_entries;
DROP POLICY IF EXISTS "Users can update their own queue entries" ON public.queue_entries;
DROP POLICY IF EXISTS "Users can delete their own queue entries" ON public.queue_entries;
DROP POLICY IF EXISTS "Allow authenticated insert on queue_entries" ON public.queue_entries;
DROP POLICY IF EXISTS "Allow authenticated select on queue_entries" ON public.queue_entries;

-- 3. Policy: Allow users to view their own entries AND active queue entries (for position calculation)
CREATE POLICY "Users can view their own and active queue entries"
  ON public.queue_entries FOR SELECT
  TO authenticated
  USING (
    (select auth.uid()) = user_id 
    OR status IN ('waiting', 'calling', 'serving')
  );

-- 4. Policy: Allow authenticated users to insert their own queue entries
CREATE POLICY "Users can insert their own queue entries"
  ON public.queue_entries FOR INSERT
  TO authenticated
  WITH CHECK (
    (select auth.uid()) = user_id
  );

-- 5. Policy: Allow authenticated users to update their own entries (for leave/cancel/check-in)
CREATE POLICY "Users can update their own queue entries"
  ON public.queue_entries FOR UPDATE
  TO authenticated
  USING ( (select auth.uid()) = user_id )
  WITH CHECK ( (select auth.uid()) = user_id );

-- 6. Policy: Allow authenticated users to delete their own entries if needed
CREATE POLICY "Users can delete their own queue entries"
  ON public.queue_entries FOR DELETE
  TO authenticated
  USING ( (select auth.uid()) = user_id );

-- 7. Ensure queue_entries is added to supabase_realtime publication for real-time updates
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' 
    AND schemaname = 'public' 
    AND tablename = 'queue_entries'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.queue_entries;
  END IF;
END $$;
