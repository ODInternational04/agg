-- Fix RLS Policies to allow anon access for High Aggregator tables
-- Run this in Supabase SQL Editor

-- Branches - Allow anon read access
DROP POLICY IF EXISTS "Allow anon users to read branches" ON high_aggregator_branches;
CREATE POLICY "Allow anon users to read branches"
    ON high_aggregator_branches FOR SELECT
    TO anon
    USING (true);

DROP POLICY IF EXISTS "Allow anon users to insert branches" ON high_aggregator_branches;
CREATE POLICY "Allow anon users to insert branches"
    ON high_aggregator_branches FOR INSERT
    TO anon
    WITH CHECK (true);

DROP POLICY IF EXISTS "Allow anon users to update branches" ON high_aggregator_branches;
CREATE POLICY "Allow anon users to update branches"
    ON high_aggregator_branches FOR UPDATE
    TO anon
    USING (true);

-- Bins - Allow anon read/write access
DROP POLICY IF EXISTS "Allow anon users to read bins" ON high_aggregator_bins;
CREATE POLICY "Allow anon users to read bins"
    ON high_aggregator_bins FOR SELECT
    TO anon
    USING (true);

DROP POLICY IF EXISTS "Allow anon users to insert bins" ON high_aggregator_bins;
CREATE POLICY "Allow anon users to insert bins"
    ON high_aggregator_bins FOR INSERT
    TO anon
    WITH CHECK (true);

DROP POLICY IF EXISTS "Allow anon users to update bins" ON high_aggregator_bins;
CREATE POLICY "Allow anon users to update bins"
    ON high_aggregator_bins FOR UPDATE
    TO anon
    USING (true);

-- Storage Locations - Allow anon read access
DROP POLICY IF EXISTS "Allow anon users to read locations" ON high_aggregator_storage_locations;
CREATE POLICY "Allow anon users to read locations"
    ON high_aggregator_storage_locations FOR SELECT
    TO anon
    USING (true);

DROP POLICY IF EXISTS "Allow anon users to insert locations" ON high_aggregator_storage_locations;
CREATE POLICY "Allow anon users to insert locations"
    ON high_aggregator_storage_locations FOR INSERT
    TO anon
    WITH CHECK (true);

DROP POLICY IF EXISTS "Allow anon users to update locations" ON high_aggregator_storage_locations;
CREATE POLICY "Allow anon users to update locations"
    ON high_aggregator_storage_locations FOR UPDATE
    TO anon
    USING (true);

-- Events - Allow anon read/write access
DROP POLICY IF EXISTS "Allow anon users to read events" ON high_aggregator_events;
CREATE POLICY "Allow anon users to read events"
    ON high_aggregator_events FOR SELECT
    TO anon
    USING (true);

DROP POLICY IF EXISTS "Allow anon users to insert events" ON high_aggregator_events;
CREATE POLICY "Allow anon users to insert events"
    ON high_aggregator_events FOR INSERT
    TO anon
    WITH CHECK (true);

-- Users - Allow anon read access
DROP POLICY IF EXISTS "Allow anon users to read users" ON high_aggregator_users;
CREATE POLICY "Allow anon users to read users"
    ON high_aggregator_users FOR SELECT
    TO anon
    USING (true);
