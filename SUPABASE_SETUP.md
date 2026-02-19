# Supabase Database Setup for High Aggregator Depot

## Database Schema Overview

The database schema consists of 5 main tables with the `high_aggregator_` prefix:

### Tables

1. **high_aggregator_branches** - Aggregator branch information
   - Stores details about collection branches (e.g., Aggregator A, B, C)
   - Fields: id, name, contact_person, phone, location, active

2. **high_aggregator_bins** - Collection bin tracking
   - Tracks each bin's status and location
   - Statuses: IN_FIELD, IN_TRANSIT, RECEIVED_AT_DEPOT, STORED, DISPATCHED, CLOSED
   - Fields: id, aggregator_id, status, last_event_ts, stored_at

3. **high_aggregator_storage_locations** - Depot storage locations
   - Manages storage bays, racks, and slots
   - Includes capacity tracking and oil type restrictions
   - Fields: id, name, location_type, depot_id, capacity, current_count, allowed_oil_types

4. **high_aggregator_events** - Event log
   - Records all transactions (receipts, storage, dispatch)
   - Captures metadata: litres, oil type, notes, photos
   - Fields: id, event_type, bin_id, depot_id, aggregator_id, location_id, timestamp, inbound_litres, drainage_litres, oil_type, notes, photo_url

5. **high_aggregator_users** - Depot staff
   - User accounts for depot managers and staff
   - Fields: id, name, email, role, depot_id, active

## Setup Instructions

### 1. Create Supabase Project
1. Go to [https://supabase.com](https://supabase.com)
2. Create a new project
3. Note your project URL and anon key

### 2. Run the Schema
1. Open your Supabase project dashboard
2. Go to **SQL Editor**
3. Copy the contents of `supabase-schema.sql`
4. Paste and run the SQL script
5. Verify all tables are created under **Table Editor**

### 3. Configure Application
1. Copy `supabase-config.TEMPLATE.js` to `supabase-config.js`
2. Add your Supabase project URL and anon key
3. Never commit `supabase-config.js` to git (it's in .gitignore)

## Features

### Indexes
- Optimized queries for bin status, aggregator lookup, event history
- Fast searches on timestamp and event type

### Views
- `high_aggregator_bin_status` - Current status of all bins with latest event
- `high_aggregator_location_utilization` - Storage capacity and utilization

### Functions
- `get_bins_ready_for_storage()` - Returns bins in RECEIVED_AT_DEPOT status

### Row Level Security (RLS)
- All tables have RLS enabled
- Authenticated users can read/write all data
- Ready for custom policies based on user roles

## Sample Data

The schema includes sample data:
- 3 aggregator branches (AGG-001, AGG-002, AGG-003)
- 4 bins (BIN-1001, BIN-1002, BIN-2001, BIN-3001)
- 3 storage locations at Depot A
- 1 depot manager user

## Oil Types
- UCO (Used Cooking Oil)
- WINTERIZED
- ACID_OIL
- GUM_OIL
- MIXED_OIL

## Status Flow
```
IN_FIELD → RECEIVED_AT_DEPOT → STORED → DISPATCHED → CLOSED
```

## Next Steps
1. Set up Supabase project
2. Run the schema SQL
3. Configure the app with Supabase credentials
4. Update app.js to use Supabase instead of localStorage
