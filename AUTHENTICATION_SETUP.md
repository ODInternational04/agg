# Authentication Setup Guide

This application now requires authentication using Supabase Auth and the `admins` table.

## Features

- **Signup**: New users can create an account
- **Login**: Existing users can login with email/password
- **Role-Based Access**: Only users with `depot_manager` or `super_admin` role can access the app
- **Status Check**: Users must have `active` status
- **Session Management**: Automatic session persistence and logout
- **Last Login Tracking**: Updates last_login timestamp on each login

## Setup Instructions

### 1. Run the Admin Table SQL Script

1. Open your Supabase project dashboard
2. Go to the SQL Editor
3. Open the file `admin-table-setup.sql` from this project
4. Copy and paste the entire content into the SQL Editor
5. Click "Run" to create the admins table and its policies

### 2. Configure Email Settings (Optional but Recommended)

By default, Supabase requires email verification for new signups. To configure this:

1. Go to **Authentication > Email Templates** in your Supabase dashboard
2. Customize the confirmation email template if desired
3. Go to **Authentication > Providers** 
4. Enable/configure email provider settings

**For testing**, you can disable email confirmation:
- Go to **Authentication > Settings**
- Uncheck "Enable email confirmations"

### 3. Test the Authentication

1. Open the application in your browser
2. You should see the login/signup screen
3. Click "Sign up" to create a new account
4. Enter your full name, email, and password (minimum 6 characters)
5. If email confirmation is enabled, check your email for the verification link
6. Login with your credentials

## User Roles

The admins table supports these roles:

- **super_admin**: Full access to all features (can manage other admins)
- **depot_manager**: Can receive and store bins (required for this app)
- **depot_staff**: Limited permissions
- **viewer**: Read-only access

Only users with `depot_manager` or `super_admin` roles can access the Depot Workflow application.

## Admin Table Structure

```sql
id             UUID          (matches Supabase auth.users.id)
email          TEXT          (unique)
full_name      TEXT          
role           TEXT          (depot_manager, super_admin, etc.)
permissions    JSONB         (array of permission strings)
status         TEXT          (active, inactive, suspended)
last_login     TIMESTAMPTZ   (automatically updated on login)
created_at     TIMESTAMPTZ   
updated_at     TIMESTAMPTZ   (automatically updated on changes)
```

## Permissions Examples

The `permissions` field is a JSONB array that can include:

```json
[
  "receive_bins",
  "store_bins",
  "view_reports",
  "manage_locations",
  "manage_admins"
]
```

## Creating Your First Admin User Manually

If you need to create an admin user manually:

1. First, create an account through the signup form (or create it in Supabase Auth dashboard)
2. Get the user's UUID from the Supabase **Authentication > Users** page
3. Run this SQL in the Supabase SQL Editor:

```sql
INSERT INTO admin (id, email, full_name, role, permissions, status)
VALUES (
    'uuid-from-auth-users-here',
    'your-email@example.com',
    'Your Full Name',
    'super_admin',
    '["verify_users", "manage_jobs", "view_analytics", "manage_admins"]'::jsonb,
    'active'
);
```

## Security Notes

- **Row Level Security (RLS)** is enabled on the admins table
- Users can only read their own admin record
- Users can update their own last_login timestamp
- Only super_admins can manage other admin records
- All passwords are securely handled by Supabase Auth

## Troubleshooting

### "Admin record not found"
- Make sure the admins table has a record with the same UUID as your auth user
- Check that the SQL script was run successfully

### "Account is not active"
- Check the `status` field in the admins table - it must be 'active'
- Update it using: `UPDATE admins SET status = 'active' WHERE email = 'your-email@example.com';`

### "Access denied. Depot manager role required"
- Check the `role` field in the admins table
- It must be either 'depot_manager' or 'super_admin'
- Update it using: `UPDATE admins SET role = 'depot_manager' WHERE email = 'your-email@example.com';`

### Email not being sent
- Check your Supabase email settings
- For testing, disable email confirmation in Authentication settings
- Check spam folder

## Next Steps

Once authenticated, users with depot_manager role can:
- Receive bins at the depot
- Store bins in designated locations
- View bin information and history
- Track oil collection and storage

All actions are now tracked with the authenticated user's ID in the database.
