-- Admin Table Setup for Depot Workflow Authentication
-- This script sets up the admins table and its policies
-- Run this in your Supabase SQL Editor

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create admins table
CREATE TABLE IF NOT EXISTS admins (
    id UUID PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    full_name TEXT NOT NULL,
    role TEXT NOT NULL DEFAULT 'depot_manager',
    permissions JSONB DEFAULT '[]'::jsonb,
    status TEXT NOT NULL DEFAULT 'active',
    last_login TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT valid_role CHECK (
        role IN ('super_admin', 'depot_manager', 'depot_staff', 'viewer')
    ),
    CONSTRAINT valid_status CHECK (
        status IN ('active', 'inactive', 'suspended')
    )
);

-- Create index on email for faster lookups
CREATE INDEX IF NOT EXISTS idx_admins_email ON admins(email);
CREATE INDEX IF NOT EXISTS idx_admins_role ON admins(role);
CREATE INDEX IF NOT EXISTS idx_admins_status ON admins(status);

-- Updated_at trigger function (if not already exists)
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to admins table
DROP TRIGGER IF EXISTS update_admins_updated_at ON admins;
CREATE TRIGGER update_admins_updated_at 
    BEFORE UPDATE ON admins
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Enable Row Level Security
ALTER TABLE admins ENABLE ROW LEVEL SECURITY;

-- RLS Policies for admins table

-- Allow users to read their own admin record
DROP POLICY IF EXISTS "Users can read own admin record" ON admins;
CREATE POLICY "Users can read own admin record"
    ON admins
    FOR SELECT
    USING (auth.uid() = id);

-- Allow users to update their own last_login
DROP POLICY IF EXISTS "Users can update own last_login" ON admins;
CREATE POLICY "Users can update own last_login"
    ON admins
    FOR UPDATE
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- Allow authenticated users to insert their own admin record (for signup)
DROP POLICY IF EXISTS "Users can insert own admin record" ON admins;
CREATE POLICY "Users can insert own admin record"
    ON admins
    FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = id);

-- Allow super_admin to manage all admin records
DROP POLICY IF EXISTS "Super admins can manage all admins" ON admins;
CREATE POLICY "Super admins can manage all admins"
    ON admins
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM admins
            WHERE id = auth.uid()
            AND role = 'super_admin'
            AND status = 'active'
        )
    );

-- Comments
COMMENT ON TABLE admins IS 'Stores admin user information for depot workflow authentication';
COMMENT ON COLUMN admins.id IS 'UUID matches auth.users.id from Supabase Auth';
COMMENT ON COLUMN admins.role IS 'User role: super_admin, depot_manager, depot_staff, viewer';
COMMENT ON COLUMN admins.permissions IS 'JSON array of permission strings';
COMMENT ON COLUMN admins.status IS 'Account status: active, inactive, suspended';

-- Sample depot manager permissions (customize as needed)
-- ['receive_bins', 'store_bins', 'view_reports', 'manage_locations']

-- Sample insert (uncomment and modify for your first admin user)
/*
INSERT INTO admins (id, email, full_name, role, permissions, status)
VALUES (
    'your-auth-user-id-here',
    'admin@example.com',
    'Admin User',
    'super_admin',
    '["verify_users", "manage_jobs", "view_analytics", "manage_admins"]'::jsonb,
    'active'
);
*/
