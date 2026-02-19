# Depot Workflow App

Mobile-friendly depot workflow app with QR code scanning for receiving and storing oil bins.

## Features

- ✅ **Receive Bins** - Scan bin QR codes, capture inbound litres, oil type, notes, and photos
- ✅ **Storage Assignment** - Capture drainage amounts and scan storage location QR codes
- ✅ **Real-time Database** - Connected to Supabase for persistent data storage
- ✅ **QR Scanner** - Camera-based scanning with image upload fallback
- ✅ **Mobile-Friendly** - Responsive design optimized for mobile devices

## Quick Start

### 1. Set Up Supabase

1. Create a free account at [supabase.com](https://supabase.com)
2. Create a new project
3. Go to **SQL Editor** and run the contents of `supabase-schema.sql`
4. Go to **Project Settings → API** to get your credentials

### 2. Configure the App

1. Copy your Supabase credentials
2. Edit `supabase-config.js` and add your URL and anon key:
   ```javascript
   const SUPABASE_CONFIG = {
     url: 'https://your-project.supabase.co',
     anonKey: 'your-anon-key-here'
   };
   ```
3. Never commit `supabase-config.js` to git (it's in .gitignore)

### 3. Run the App

Serve the app with a local web server (required for camera access):

```bash
# Python
python -m http.server 8080

# Node.js
npx http-server -p 8080

# PHP
php -S localhost:8080
```

Open **http://localhost:8080** in your browser.

## Database Schema

See [SUPABASE_SETUP.md](SUPABASE_SETUP.md) for full database documentation.

**Tables:**
- `high_aggregator_branches` - Aggregator branch information
- `high_aggregator_bins` - Bin tracking and status
- `high_aggregator_storage_locations` - Depot storage locations
- `high_aggregator_events` - Event log (receipts, storage, etc.)
- `high_aggregator_users` - Depot staff and managers

## Workflow

### Receive Flow
1. Scan or enter bin QR code
2. New bins are created automatically if not found
3. Enter **inbound litres** and select **oil type**
4. Add optional notes and photo
5. Click **"Confirm Receipt"**
6. Bin status changes to `RECEIVED_AT_DEPOT`

### Store Flow
1. View list of received bins ready for storage
2. Enter **amount after drainage** for each bin
3. Click **"Store"** button
4. Scan **storage location** QR code
5. Bin status changes to `STORED`

## Oil Types

- UCO (Used Cooking Oil)
- Winterized
- Acid Oil
- Gum Oil
- Mixed Oil

## Status Flow

```
IN_FIELD → RECEIVED_AT_DEPOT → STORED → DISPATCHED → CLOSED
```

## Development

**Files:**
- `index.html` - Main UI structure
- `app.js` - Application logic (Supabase version)
- `styles.css` - Styling
- `supabase-schema.sql` - Database schema
- `supabase-config.js` - Your credentials (not in git)
- `SUPABASE_SETUP.md` - Database documentation

**Local Version (Backup)**  
The original localStorage version is saved as `app-local.js.backup`

## Browser Compatibility

- Modern browsers (Chrome, Safari, Firefox, Edge)
- Camera access requires HTTPS or localhost
- Mobile browsers fully supported

## Sample Data

The schema includes sample data:
- 3 aggregator branches (AGG-001, AGG-002, AGG-003)
- 4 bins (BIN-1001, BIN-1002, BIN-2001, BIN-3001)
- 3 storage locations at Depot A

## Troubleshooting

**"Configuration Required" error**
- Make sure you've updated `supabase-config.js` with your actual Supabase credentials

**Camera not working**
- Use a local web server (not file://)
- Grant camera permissions when prompted
- Use the image upload fallback if camera fails

**Data not saving**
- Check browser console for errors
- Verify Supabase credentials are correct
- Check that the schema was run successfully in Supabase

## License

Private repository - All rights reserved
