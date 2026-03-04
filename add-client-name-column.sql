-- Add company_name column to high_aggregator_events table
-- This allows tracking which company the inbound oil is received from

ALTER TABLE high_aggregator_events 
ADD COLUMN IF NOT EXISTS company_name TEXT;

-- Add index for faster queries by company
CREATE INDEX IF NOT EXISTS idx_events_company_name 
ON high_aggregator_events(company_name);

-- Add comment
COMMENT ON COLUMN high_aggregator_events.company_name IS 'Name of the company/client the oil is received from';
