# McCrack Chat — Supabase account setup

The website now includes account sign-up/sign-in, password reset, profile syncing, and a Friends interface. You must run the SQL setup before cloud profiles and friend requests will work.

## One-time Supabase setup

1. Open your project at https://supabase.com/dashboard.
2. Select **SQL Editor → New query**.
3. Open [SUPABASE_AUTH_SETUP.sql](./SUPABASE_AUTH_SETUP.sql) in this repository.
4. Copy the **entire file**, paste it into the SQL Editor, and click **Run**.
5. Confirm the **Table Editor** contains `profiles`, `user_preferences`, and `friend_requests`.
6. Confirm **Storage → Buckets** contains `mcchat-user-media`.
7. Under **Authentication → URL Configuration**, set **Site URL** to the actual deployed McCrack Chat URL. Add that exact URL as an allowed redirect URL too.
8. Under **Authentication → Providers → Email**, leave Email enabled. Email confirmation is currently disabled in your existing configuration, so new accounts may sign in immediately. Consider enabling confirmation before sharing the app widely.

## Test it

1. Open the deployed chat and click your profile in the lower-left.
2. Choose **Create account / Sign in** and create a test account with an email you can access and a strong, unique password.
3. After signing in, edit your display name/photo and change a setting.
4. Open the site in another browser/device and sign in with that same account. The profile, settings, contact labels, and recent room list should load from Supabase.
5. Open the **Friends** icon, search the other account's exact username, send a request, then sign in as that other account and accept it.

## Important notes

- The existing public/anon key remains in the browser, which is expected for Supabase's client-side SDK. Never put a service-role/secret key in the website.
- Profile photos and custom wallpaper files are stored in the public `mcchat-user-media` bucket. Anyone who has a public media URL can view that image; do not upload anything private.
- Existing chat rooms and messages are not changed by this SQL.
- Friend requests are supported by this first version. A friend list does not automatically create private conversations; messaging friends privately is a separate feature to build.
- Existing room chat itself still uses its current room/username model. Accounts and friend requests do not yet enforce that every chat message belongs to an authenticated user.
- If the website is hosted at more than one URL, add each exact URL used for sign-in/password recovery to Supabase's Redirect URLs.
