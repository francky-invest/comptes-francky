-- Comptes Francky — schema Supabase
-- À exécuter dans Supabase : SQL Editor -> New query -> coller -> Run

create extension if not exists "pgcrypto";

create table comptes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) default auth.uid(),
  nom text not null,
  banque text,
  created_at timestamptz not null default now()
);

create table categories (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) default auth.uid(),
  nom text not null,
  sens text not null check (sens in ('depense','revenu')),
  icone_key text,
  created_at timestamptz not null default now()
);

create table operations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) default auth.uid(),
  compte_id uuid not null references comptes(id) on delete cascade,
  categorie_id uuid references categories(id),
  tiers text not null,
  montant numeric(10,2) not null, -- signé : négatif = dépense, positif = revenu
  date date not null,
  mode text, -- CB / PRL / VIR / CHQ / ESP
  pointee boolean not null default false,
  is_future boolean not null default false, -- échéance à venir (pas encore débitée)
  recurrence_id uuid, -- si générée par une récurrence/achat échelonné, lien vers sa définition
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table recurrences (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) default auth.uid(),
  compte_id uuid not null references comptes(id) on delete cascade,
  categorie_id uuid references categories(id),
  nom text not null,
  sens text not null check (sens in ('depense','revenu')),
  montant numeric(10,2) not null,
  date_debut date not null,
  duree text not null check (duree in ('indef','once','limitee')),
  nb_mois integer, -- utilisé seulement si duree = 'limitee'
  actif boolean not null default true,
  created_at timestamptz not null default now()
);

create index idx_operations_compte on operations(compte_id);
create index idx_operations_date on operations(date);
create index idx_recurrences_compte on recurrences(compte_id);

alter table comptes enable row level security;
alter table categories enable row level security;
alter table operations enable row level security;
alter table recurrences enable row level security;

create policy "own rows only - comptes" on comptes
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "own rows only - categories" on categories
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "own rows only - operations" on operations
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "own rows only - recurrences" on recurrences
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
