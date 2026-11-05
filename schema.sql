-- DRAMA KITA / Supabase SQL Editor
-- Jalankan seluruh skrip ini pada proyek Supabase baru.
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default 'Kreator',
  role text not null default 'creator' check (role in ('creator','admin')),
  created_at timestamptz not null default now()
);

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, coalesce(nullif(new.raw_user_meta_data->>'display_name',''), split_part(new.email,'@',1)));
  return new;
end;
$$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
for each row execute procedure public.handle_new_user();

create table if not exists public.episodes (
  id uuid primary key,
  title text not null check (char_length(title) between 1 and 80),
  episode_no int not null check (episode_no > 0),
  category text not null,
  description text not null default '',
  creator_id uuid not null references public.profiles(id) on delete cascade,
  video_path text not null,
  cover_path text,
  status text not null default 'pending' check (status in ('pending','approved','rejected')),
  rights_confirmed boolean not null default false,
  moderation_note text,
  created_at timestamptz not null default now()
);
create table if not exists public.reports (
  id uuid primary key default gen_random_uuid(),
  episode_id uuid not null references public.episodes(id) on delete cascade,
  reporter_id uuid not null references public.profiles(id) on delete cascade,
  reason text not null check (char_length(reason) between 1 and 500),
  status text not null default 'open' check (status in ('open','reviewed','dismissed')),
  created_at timestamptz not null default now(),
  unique (episode_id, reporter_id)
);

alter table public.profiles enable row level security;
alter table public.episodes enable row level security;
alter table public.reports enable row level security;

create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path = '' as $$
  select exists(select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin');
$$;

drop policy if exists "profiles public names" on public.profiles;
create policy "profiles public names" on public.profiles for select using (true);
-- Profil tidak dapat diubah oleh pengguna dari klien pada versi awal.
-- Admin dapat mengubah role melalui SQL Editor (di luar kebijakan RLS).

drop policy if exists "approved episodes readable" on public.episodes;
create policy "approved episodes readable" on public.episodes for select using (status='approved' or creator_id=auth.uid() or public.is_admin());
drop policy if exists "creator submits own pending episodes" on public.episodes;
create policy "creator submits own pending episodes" on public.episodes for insert with check (creator_id=auth.uid() and status='pending' and rights_confirmed=true);
drop policy if exists "admin manages episodes" on public.episodes;
create policy "admin manages episodes" on public.episodes for update using (public.is_admin()) with check (public.is_admin());
drop policy if exists "admin deletes episodes" on public.episodes;
create policy "admin deletes episodes" on public.episodes for delete using (public.is_admin());

drop policy if exists "signed-in users report" on public.reports;
create policy "signed-in users report" on public.reports for insert with check (reporter_id=auth.uid());
drop policy if exists "reporter sees own reports" on public.reports;
create policy "reporter sees own reports" on public.reports for select using (reporter_id=auth.uid() or public.is_admin());
drop policy if exists "admin reviews reports" on public.reports;
create policy "admin reviews reports" on public.reports for update using (public.is_admin()) with check (public.is_admin());

-- Buat bucket PRIVATE bernama drama-media di Storage dashboard.
-- Batas awal yang disarankan untuk proyek kecil: 100 MB per file; sesuaikan kuota akun.
-- Policies di bawah mengunci folder pertama pada UID pemilik.
drop policy if exists "owner uploads own media" on storage.objects;
create policy "owner uploads own media" on storage.objects for insert to authenticated
with check (bucket_id='drama-media' and (storage.foldername(name))[1]=auth.uid()::text);
drop policy if exists "owner or admin reads own media" on storage.objects;
create policy "owner or admin reads own media" on storage.objects for select to authenticated
using (bucket_id='drama-media' and ((storage.foldername(name))[1]=auth.uid()::text or public.is_admin() or exists (
  select 1 from public.episodes e where e.video_path=name and e.status='approved'
) or exists (
  select 1 from public.episodes e where e.cover_path=name and e.status='approved'
)));
drop policy if exists "owner deletes own media" on storage.objects;
create policy "owner deletes own media" on storage.objects for delete to authenticated
using (bucket_id='drama-media' and (storage.foldername(name))[1]=auth.uid()::text);

-- Setelah akun admin dibuat melalui aplikasi, jalankan sekali dengan UID akun admin:
-- update public.profiles set role='admin' where id='GANTI-DENGAN-UUID-AKUN-ADMIN';
-- Jangan pernah memberi role admin melalui form publik.
