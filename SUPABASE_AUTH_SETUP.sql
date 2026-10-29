-- McCrack Chat: Supabase Auth + cloud profiles setup
-- Run this entire script in Supabase Dashboard -> SQL Editor -> New query.
-- This does NOT change or delete existing rooms, messages, or chat-images data.

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text not null unique,
  display_name text not null default 'User',
  status text not null default 'Available to chat',
  avatar_url text,
  updated_at timestamptz not null default now()
);

create table if not exists public.user_preferences (
  id uuid primary key references auth.users(id) on delete cascade,
  settings jsonb not null default '{}'::jsonb,
  contacts jsonb not null default '{}'::jsonb,
  recent_rooms jsonb not null default '[]'::jsonb,
  updated_at timestamptz not null default now()
);

alter table public.profiles enable row level security;
alter table public.user_preferences enable row level security;

grant select on public.profiles to anon, authenticated;
grant insert, update on public.profiles to authenticated;
grant select, insert, update on public.user_preferences to authenticated;

drop policy if exists "Public profiles are readable" on public.profiles;
create policy "Public profiles are readable"
  on public.profiles for select
  using (true);

drop policy if exists "Users can create their own profile" on public.profiles;
create policy "Users can create their own profile"
  on public.profiles for insert to authenticated
  with check (auth.uid() = id);

drop policy if exists "Users can update their own profile" on public.profiles;
create policy "Users can update their own profile"
  on public.profiles for update to authenticated
  using (auth.uid() = id)
  with check (auth.uid() = id);

drop policy if exists "Users can read their own preferences" on public.user_preferences;
create policy "Users can read their own preferences"
  on public.user_preferences for select to authenticated
  using (auth.uid() = id);

drop policy if exists "Users can create their own preferences" on public.user_preferences;
create policy "Users can create their own preferences"
  on public.user_preferences for insert to authenticated
  with check (auth.uid() = id);

drop policy if exists "Users can update their own preferences" on public.user_preferences;
create policy "Users can update their own preferences"
  on public.user_preferences for update to authenticated
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- One public bucket for profile photos and wallpaper images.
-- Objects can be read by chat users, but only the owning signed-in user can upload/edit/delete files in their folder.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'mcchat-user-media',
  'mcchat-user-media',
  true,
  8388608,
  array['image/jpeg', 'image/png', 'image/webp', 'image/gif', 'image/avif']
)
on conflict (id) do update
set public = true,
    file_size_limit = 8388608,
    allowed_mime_types = array['image/jpeg', 'image/png', 'image/webp', 'image/gif', 'image/avif'];

drop policy if exists "McCrack profile media is publicly readable" on storage.objects;
create policy "McCrack profile media is publicly readable"
  on storage.objects for select
  using (bucket_id = 'mcchat-user-media');

drop policy if exists "Users upload their own McCrack media" on storage.objects;
create policy "Users upload their own McCrack media"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'mcchat-user-media'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "Users update their own McCrack media" on storage.objects;
create policy "Users update their own McCrack media"
  on storage.objects for update to authenticated
  using (
    bucket_id = 'mcchat-user-media'
    and (storage.foldername(name))[1] = auth.uid()::text
  )
  with check (
    bucket_id = 'mcchat-user-media'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "Users delete their own McCrack media" on storage.objects;
create policy "Users delete their own McCrack media"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'mcchat-user-media'
    and (storage.foldername(name))[1] = auth.uid()::text
  );


-- Friend requests: a user can send requests and only the sender/recipient can read them.
create table if not exists public.friend_requests (
  id uuid primary key default gen_random_uuid(),
  sender_id uuid not null references auth.users(id) on delete cascade,
  recipient_id uuid not null references auth.users(id) on delete cascade,
  status text not null default 'pending' check (status in ('pending','accepted','declined')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint friend_requests_not_self check (sender_id <> recipient_id),
  constraint friend_requests_unique_pair unique (sender_id, recipient_id)
);
alter table public.friend_requests enable row level security;
grant select, insert, update, delete on public.friend_requests to authenticated;
drop policy if exists "Users can see their own friend requests" on public.friend_requests;
create policy "Users can see their own friend requests" on public.friend_requests
  for select to authenticated using (auth.uid() = sender_id or auth.uid() = recipient_id);
drop policy if exists "Users can send friend requests as themselves" on public.friend_requests;
create policy "Users can send friend requests as themselves" on public.friend_requests
  for insert to authenticated with check (auth.uid() = sender_id and status = 'pending');
drop policy if exists "Recipients can respond to friend requests" on public.friend_requests;
create policy "Recipients can respond to friend requests" on public.friend_requests
  for update to authenticated using (auth.uid() = recipient_id)
  with check (auth.uid() = recipient_id and status in ('accepted','declined'));
drop policy if exists "Senders can cancel pending friend requests" on public.friend_requests;
create policy "Senders can cancel pending friend requests" on public.friend_requests
  for delete to authenticated using (auth.uid() = sender_id and status = 'pending');
