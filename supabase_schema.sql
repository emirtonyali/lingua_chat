-- ============================================================================
-- LinguaChat — Supabase veritabanı kurulumu
-- ----------------------------------------------------------------------------
-- KULLANIM: Supabase panelinde sol menüden "SQL Editor" → "New query" →
-- bu dosyanın TAMAMINI yapıştır → "Run". Bir kez çalıştırman yeterli.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- TABLOLAR
-- ---------------------------------------------------------------------------

-- Kullanıcı profilleri (auth.users ile 1-1 bağlı)
create table if not exists public.profiles (
  id                 uuid primary key references auth.users(id) on delete cascade,
  name               text not null default '',
  email              text not null default '',
  username           text unique,
  preferred_language text not null default 'en',
  photo_url          text,
  created_at         timestamptz not null default now()
);

-- Arkadaşlık istekleri
create table if not exists public.friend_requests (
  id         uuid primary key default gen_random_uuid(),
  from_user  uuid not null references public.profiles(id) on delete cascade,
  to_user    uuid not null references public.profiles(id) on delete cascade,
  status     text not null default 'pending',  -- pending | accepted | rejected
  created_at timestamptz not null default now()
);

-- Kurulmuş arkadaşlıklar (user_a < user_b sırasıyla tutulur)
create table if not exists public.friendships (
  id         uuid primary key default gen_random_uuid(),
  user_a     uuid not null references public.profiles(id) on delete cascade,
  user_b     uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (user_a, user_b)
);

-- Sohbetler (id = iki uid'nin alfabetik birleşimi "uidA_uidB")
create table if not exists public.chats (
  id                text primary key,
  member_a          uuid not null references public.profiles(id) on delete cascade,
  member_b          uuid not null references public.profiles(id) on delete cascade,
  last_message_text text default '',
  last_message_at   timestamptz default now()
);

-- Mesajlar. translations: çeviri cache'i, ör: {"en":"Hello","de":"Hallo"}
create table if not exists public.messages (
  id                uuid primary key default gen_random_uuid(),
  chat_id           text not null references public.chats(id) on delete cascade,
  sender_id         uuid not null references public.profiles(id) on delete cascade,
  text              text not null,
  original_language text not null default 'en',
  translations      jsonb not null default '{}'::jsonb,
  created_at        timestamptz not null default now()
);

create index if not exists idx_messages_chat on public.messages(chat_id, created_at);

-- ---------------------------------------------------------------------------
-- GÜVENLİK (Row Level Security) — herkes sadece kendi verisine erişir
-- ---------------------------------------------------------------------------
alter table public.profiles        enable row level security;
alter table public.friend_requests enable row level security;
alter table public.friendships     enable row level security;
alter table public.chats           enable row level security;
alter table public.messages        enable row level security;

-- PROFILES: giriş yapmış herkes profilleri görebilir (kullanıcı adıyla arama için),
-- ama yalnızca kendi profilini oluşturup güncelleyebilir.
drop policy if exists profiles_select on public.profiles;
create policy profiles_select on public.profiles
  for select to authenticated using (true);

drop policy if exists profiles_insert on public.profiles;
create policy profiles_insert on public.profiles
  for insert to authenticated with check (auth.uid() = id);

drop policy if exists profiles_update on public.profiles;
create policy profiles_update on public.profiles
  for update to authenticated using (auth.uid() = id);

-- FRIEND_REQUESTS: taraf olduğun istekleri görürsün; kendi adına gönderirsin;
-- sana geleni güncelleyebilirsin (kabul/ret).
drop policy if exists fr_select on public.friend_requests;
create policy fr_select on public.friend_requests
  for select to authenticated
  using (auth.uid() = from_user or auth.uid() = to_user);

drop policy if exists fr_insert on public.friend_requests;
create policy fr_insert on public.friend_requests
  for insert to authenticated with check (auth.uid() = from_user);

drop policy if exists fr_update on public.friend_requests;
create policy fr_update on public.friend_requests
  for update to authenticated
  using (auth.uid() = to_user or auth.uid() = from_user);

-- FRIENDSHIPS: üyesi olduğun arkadaşlıkları görür/oluşturursun.
drop policy if exists fs_select on public.friendships;
create policy fs_select on public.friendships
  for select to authenticated
  using (auth.uid() = user_a or auth.uid() = user_b);

drop policy if exists fs_insert on public.friendships;
create policy fs_insert on public.friendships
  for insert to authenticated
  with check (auth.uid() = user_a or auth.uid() = user_b);

-- CHATS: üyesi olduğun sohbetler.
drop policy if exists chats_all on public.chats;
create policy chats_all on public.chats
  for all to authenticated
  using (auth.uid() = member_a or auth.uid() = member_b)
  with check (auth.uid() = member_a or auth.uid() = member_b);

-- MESSAGES: üyesi olduğun sohbetin mesajlarını okur; kendi adına gönderir;
-- çeviri cache'i için güncelleyebilirsin.
drop policy if exists msg_select on public.messages;
create policy msg_select on public.messages
  for select to authenticated
  using (exists (
    select 1 from public.chats c
    where c.id = chat_id and (auth.uid() = c.member_a or auth.uid() = c.member_b)
  ));

drop policy if exists msg_insert on public.messages;
create policy msg_insert on public.messages
  for insert to authenticated
  with check (auth.uid() = sender_id and exists (
    select 1 from public.chats c
    where c.id = chat_id and (auth.uid() = c.member_a or auth.uid() = c.member_b)
  ));

drop policy if exists msg_update on public.messages;
create policy msg_update on public.messages
  for update to authenticated
  using (exists (
    select 1 from public.chats c
    where c.id = chat_id and (auth.uid() = c.member_a or auth.uid() = c.member_b)
  ));

-- ---------------------------------------------------------------------------
-- REALTIME — mesaj ve sohbet değişikliklerinin anlık gelmesi için
-- ---------------------------------------------------------------------------
alter publication supabase_realtime add table public.messages;
alter publication supabase_realtime add table public.chats;
alter publication supabase_realtime add table public.friend_requests;
