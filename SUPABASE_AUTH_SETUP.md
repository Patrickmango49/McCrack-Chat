# McCrack Chat — Supabase Auth setup

The SQL schema for account profiles and cloud preferences is in SUPABASE_AUTH_SETUP.sql.

## Supabase dashboard steps

1. Open the existing McCrack Chat project at https://supabase.com/dashboard.
2. Open SQL Editor and create a new query.
3. Open SUPABASE_AUTH_SETUP.sql in this repository, copy the full file contents, paste them into the SQL Editor, and run the query.
4. Check Table Editor for profiles and user_preferences.
5. Check Storage for the mcchat-user-media bucket.
6. Under Authentication → URL Configuration, make sure the Site URL is your real McCrack Chat website URL and that the same URL is allowed in Redirect URLs.
7. Email sign-up is already enabled in this project. Email confirmation is currently disabled based on the owner's current settings; consider enabling it before opening sign-up widely.

## What the SQL adds

- profiles: public display name, username, status, and avatar URL.
- user_preferences: private per-user settings, contact labels, and recent room list.
- mcchat-user-media: storage for profile pictures and custom wallpaper images.
- Row Level Security policies so authenticated users can only change their own profile, preferences, and uploaded files.

The SQL does not modify existing rooms, messages, or chat-images data. Do not put a Supabase service-role key in browser code; the existing browser client should use the project's public/anon key only.

## Important

Running the SQL creates the backend tables and policies; the website still needs its account UI and client-side Auth integration before sign-up, sign-in, password reset, and cloud sync are available in the app.
