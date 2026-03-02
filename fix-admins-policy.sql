-- Quick fix for admins table RLS policy
-- Run this in your Supabase SQL Editor to fix the signup issue

-- TEMPORARY: Disable RLS on admins table to allow signups
ALTER TABLE admins DISABLE ROW LEVEL SECURITY;

-- Alternative: If you want to keep RLS enabled, uncomment below and comment out the line above
-- DROP POLICY IF EXISTS "Service role can insert admin records" ON admins;
-- DROP POLICY IF EXISTS "Users can insert own admin record" ON admins;
-- DROP POLICY IF EXISTS "Allow signup to insert admin record" ON admins;
-- DROP POLICY IF EXISTS "Allow all inserts to admins" ON admins;
-- 
-- CREATE POLICY "Allow all inserts to admins"
--     ON admins
--     FOR INSERT
--     WITH CHECK (true);
--
-- CREATE POLICY "Users can read own admin record"
--     ON admins
--     FOR SELECT
--     USING (auth.uid() = id);
--
-- CREATE POLICY "Users can update own last_login"
--     ON admins
--     FOR UPDATE
--     USING (auth.uid() = id)
--     WITH CHECK (auth.uid() = id);
