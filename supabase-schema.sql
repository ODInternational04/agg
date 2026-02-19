-- Supabase Database Schema for High Aggregator Depot Workflow
-- Created: 2026-02-18

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- Table: high_aggregator_branches
-- Stores information about aggregator branches
-- =====================================================
CREATE TABLE IF NOT EXISTS high_aggregator_branches (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    contact_person TEXT,
    phone TEXT,
    location TEXT,
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- Table: high_aggregator_bins
-- Stores information about collection bins
-- =====================================================
CREATE TABLE IF NOT EXISTS high_aggregator_bins (
    id TEXT PRIMARY KEY,
    aggregator_id TEXT REFERENCES high_aggregator_branches(id),
    status TEXT NOT NULL DEFAULT 'IN_FIELD',
    last_event_ts TIMESTAMPTZ,
    stored_at TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT valid_status CHECK (
        status IN ('IN_FIELD', 'IN_TRANSIT', 'RECEIVED_AT_DEPOT', 'STORED', 'DISPATCHED', 'CLOSED')
    )
);

-- =====================================================
-- Table: high_aggregator_storage_locations
-- Stores depot storage location information
-- =====================================================
CREATE TABLE IF NOT EXISTS high_aggregator_storage_locations (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    location_type TEXT NOT NULL,
    depot_id TEXT NOT NULL,
    capacity INTEGER DEFAULT 0,
    current_count INTEGER DEFAULT 0,
    allowed_oil_types TEXT[], -- Array of allowed oil types
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT valid_location_type CHECK (
        location_type IN ('AGGREGATOR_BAY', 'RACK_SLOT', 'BULK_TANK', 'FLOOR_SPACE')
    )
);

-- =====================================================
-- Table: high_aggregator_events
-- Stores all events (receipts, storage assignments, etc.)
-- =====================================================
CREATE TABLE IF NOT EXISTS high_aggregator_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_type TEXT NOT NULL,
    bin_id TEXT NOT NULL REFERENCES high_aggregator_bins(id),
    depot_id TEXT NOT NULL,
    aggregator_id TEXT REFERENCES high_aggregator_branches(id),
    location_id TEXT,
    timestamp TIMESTAMPTZ DEFAULT NOW(),
    user_id TEXT NOT NULL,
    
    -- Metadata fields
    inbound_litres DECIMAL(10,2),
    drainage_litres DECIMAL(10,2),
    oil_type TEXT,
    notes TEXT,
    photo_url TEXT,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT valid_event_type CHECK (
        event_type IN ('RECEIVED', 'STORED', 'DISPATCHED', 'TRANSFERRED', 'QUALITY_CHECK')
    ),
    CONSTRAINT valid_oil_type CHECK (
        oil_type IS NULL OR oil_type IN ('UCO', 'WINTERIZED', 'ACID_OIL', 'GUM_OIL', 'MIXED_OIL')
    )
);

-- =====================================================
-- Table: high_aggregator_users
-- Stores depot user information
-- =====================================================
CREATE TABLE IF NOT EXISTS high_aggregator_users (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT UNIQUE,
    role TEXT NOT NULL DEFAULT 'depot_staff',
    depot_id TEXT,
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT valid_role CHECK (
        role IN ('depot_manager', 'depot_staff', 'admin', 'viewer')
    )
);

-- =====================================================
-- Indexes for Performance
-- =====================================================
CREATE INDEX IF NOT EXISTS idx_bins_status ON high_aggregator_bins(status);
CREATE INDEX IF NOT EXISTS idx_bins_aggregator ON high_aggregator_bins(aggregator_id);
CREATE INDEX IF NOT EXISTS idx_events_bin ON high_aggregator_events(bin_id);
CREATE INDEX IF NOT EXISTS idx_events_timestamp ON high_aggregator_events(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_events_type ON high_aggregator_events(event_type);
CREATE INDEX IF NOT EXISTS idx_locations_active ON high_aggregator_storage_locations(active);

-- =====================================================
-- Updated_at Trigger Function
-- =====================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply triggers to tables
DROP TRIGGER IF EXISTS update_bins_updated_at ON high_aggregator_bins;
CREATE TRIGGER update_bins_updated_at BEFORE UPDATE ON high_aggregator_bins
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_branches_updated_at ON high_aggregator_branches;
CREATE TRIGGER update_branches_updated_at BEFORE UPDATE ON high_aggregator_branches
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_locations_updated_at ON high_aggregator_storage_locations;
CREATE TRIGGER update_locations_updated_at BEFORE UPDATE ON high_aggregator_storage_locations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_users_updated_at ON high_aggregator_users;
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON high_aggregator_users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- Row Level Security (RLS) Policies
-- =====================================================

-- Enable RLS on all tables
ALTER TABLE high_aggregator_branches ENABLE ROW LEVEL SECURITY;
ALTER TABLE high_aggregator_bins ENABLE ROW LEVEL SECURITY;
ALTER TABLE high_aggregator_storage_locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE high_aggregator_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE high_aggregator_users ENABLE ROW LEVEL SECURITY;

-- Policies for branches (all authenticated users can read)
DROP POLICY IF EXISTS "Allow authenticated users to read branches" ON high_aggregator_branches;
CREATE POLICY "Allow authenticated users to read branches"
    ON high_aggregator_branches FOR SELECT
    TO authenticated
    USING (true);

DROP POLICY IF EXISTS "Allow authenticated users to insert branches" ON high_aggregator_branches;
CREATE POLICY "Allow authenticated users to insert branches"
    ON high_aggregator_branches FOR INSERT
    TO authenticated
    WITH CHECK (true);

DROP POLICY IF EXISTS "Allow authenticated users to update branches" ON high_aggregator_branches;
CREATE POLICY "Allow authenticated users to update branches"
    ON high_aggregator_branches FOR UPDATE
    TO authenticated
    USING (true);

-- Policies for bins (all authenticated users can read/write)
DROP POLICY IF EXISTS "Allow authenticated users to read bins" ON high_aggregator_bins;
CREATE POLICY "Allow authenticated users to read bins"
    ON high_aggregator_bins FOR SELECT
    TO authenticated
    USING (true);

DROP POLICY IF EXISTS "Allow authenticated users to insert bins" ON high_aggregator_bins;
CREATE POLICY "Allow authenticated users to insert bins"
    ON high_aggregator_bins FOR INSERT
    TO authenticated
    WITH CHECK (true);

DROP POLICY IF EXISTS "Allow authenticated users to update bins" ON high_aggregator_bins;
CREATE POLICY "Allow authenticated users to update bins"
    ON high_aggregator_bins FOR UPDATE
    TO authenticated
    USING (true);

-- Policies for storage locations
DROP POLICY IF EXISTS "Allow authenticated users to read locations" ON high_aggregator_storage_locations;
CREATE POLICY "Allow authenticated users to read locations"
    ON high_aggregator_storage_locations FOR SELECT
    TO authenticated
    USING (true);

DROP POLICY IF EXISTS "Allow authenticated users to insert locations" ON high_aggregator_storage_locations;
CREATE POLICY "Allow authenticated users to insert locations"
    ON high_aggregator_storage_locations FOR INSERT
    TO authenticated
    WITH CHECK (true);

DROP POLICY IF EXISTS "Allow authenticated users to update locations" ON high_aggregator_storage_locations;
CREATE POLICY "Allow authenticated users to update locations"
    ON high_aggregator_storage_locations FOR UPDATE
    TO authenticated
    USING (true);

-- Policies for events
DROP POLICY IF EXISTS "Allow authenticated users to read events" ON high_aggregator_events;
CREATE POLICY "Allow authenticated users to read events"
    ON high_aggregator_events FOR SELECT
    TO authenticated
    USING (true);

DROP POLICY IF EXISTS "Allow authenticated users to insert events" ON high_aggregator_events;
CREATE POLICY "Allow authenticated users to insert events"
    ON high_aggregator_events FOR INSERT
    TO authenticated
    WITH CHECK (true);

-- Policies for users
DROP POLICY IF EXISTS "Allow authenticated users to read users" ON high_aggregator_users;
CREATE POLICY "Allow authenticated users to read users"
    ON high_aggregator_users FOR SELECT
    TO authenticated
    USING (true);

-- =====================================================
-- Sample Data for Testing
-- =====================================================

-- Insert sample aggregator branches
INSERT INTO high_aggregator_branches (id, name, contact_person, location, active) VALUES
('AGG-001', 'Aggregator A', 'John Doe', 'Nairobi', true),
('AGG-002', 'Aggregator B', 'Jane Smith', 'Mombasa', true),
('AGG-003', 'Aggregator C', 'Mike Johnson', 'Kisumu', true)
ON CONFLICT (id) DO NOTHING;

-- Insert sample depot user
INSERT INTO high_aggregator_users (id, name, email, role, depot_id) VALUES
('USER-DEPOT-MANAGER-001', 'Depot Manager', 'manager@depot.com', 'depot_manager', 'DEPOT-A')
ON CONFLICT (id) DO NOTHING;

-- Insert sample storage locations
INSERT INTO high_aggregator_storage_locations (id, name, location_type, depot_id, capacity, allowed_oil_types, active) VALUES
('LOC-DEPOT-A-BAY-1', 'Depot A • Bay 1', 'AGGREGATOR_BAY', 'DEPOT-A', 2, ARRAY['UCO','WINTERIZED','ACID_OIL','GUM_OIL','MIXED_OIL'], true),
('LOC-DEPOT-A-BAY-3-RACK-2', 'Depot A • Bay 3 • Rack 2', 'RACK_SLOT', 'DEPOT-A', 3, ARRAY['UCO','WINTERIZED','ACID_OIL'], true),
('LOC-DEPOT-A-BAY-2', 'Depot A • Bay 2', 'AGGREGATOR_BAY', 'DEPOT-A', 3, ARRAY['UCO','WINTERIZED','ACID_OIL','GUM_OIL','MIXED_OIL'], true)
ON CONFLICT (id) DO NOTHING;

-- Insert sample bins
INSERT INTO high_aggregator_bins (id, aggregator_id, status) VALUES
('BIN-1001', 'AGG-001', 'IN_FIELD'),
('BIN-1002', 'AGG-001', 'IN_FIELD'),
('BIN-2001', 'AGG-002', 'IN_FIELD'),
('BIN-3001', 'AGG-003', 'IN_FIELD')
ON CONFLICT (id) DO NOTHING;

-- =====================================================
-- Useful Views
-- =====================================================

-- View: Current bin status with latest event info
DROP VIEW IF EXISTS high_aggregator_bin_status;
CREATE VIEW high_aggregator_bin_status AS
SELECT 
    b.id,
    b.aggregator_id,
    a.name as aggregator_name,
    b.status,
    b.stored_at,
    b.last_event_ts,
    e.inbound_litres,
    e.drainage_litres,
    e.oil_type,
    e.notes,
    b.created_at
FROM high_aggregator_bins b
LEFT JOIN high_aggregator_branches a ON b.aggregator_id = a.id
LEFT JOIN LATERAL (
    SELECT * FROM high_aggregator_events 
    WHERE bin_id = b.id 
    ORDER BY timestamp DESC 
    LIMIT 1
) e ON true;

-- View: Storage location utilization
DROP VIEW IF EXISTS high_aggregator_location_utilization;
CREATE VIEW high_aggregator_location_utilization AS
SELECT 
    l.id,
    l.name,
    l.location_type,
    l.capacity,
    l.current_count,
    l.capacity - l.current_count as available_slots,
    ROUND((l.current_count::DECIMAL / NULLIF(l.capacity, 0) * 100), 2) as utilization_percent,
    l.active
FROM high_aggregator_storage_locations l;

-- =====================================================
-- Helper Functions
-- =====================================================

-- Function to get bins ready for storage
CREATE OR REPLACE FUNCTION get_bins_ready_for_storage()
RETURNS TABLE (
    bin_id TEXT,
    aggregator_name TEXT,
    inbound_litres DECIMAL,
    oil_type TEXT,
    received_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        b.id,
        a.name,
        e.inbound_litres,
        e.oil_type,
        e.timestamp
    FROM high_aggregator_bins b
    LEFT JOIN high_aggregator_branches a ON b.aggregator_id = a.id
    LEFT JOIN LATERAL (
        SELECT * FROM high_aggregator_events 
        WHERE bin_id = b.id AND event_type = 'RECEIVED'
        ORDER BY timestamp DESC 
        LIMIT 1
    ) e ON true
    WHERE b.status = 'RECEIVED_AT_DEPOT'
    ORDER BY e.timestamp ASC;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- Comments for Documentation
-- =====================================================
COMMENT ON TABLE high_aggregator_branches IS 'Stores information about aggregator branches that collect oil';
COMMENT ON TABLE high_aggregator_bins IS 'Stores collection bin information and current status';
COMMENT ON TABLE high_aggregator_storage_locations IS 'Depot storage locations with capacity and constraints';
COMMENT ON TABLE high_aggregator_events IS 'Event log for all bin movements and transactions';
COMMENT ON TABLE high_aggregator_users IS 'Depot staff and user information';
