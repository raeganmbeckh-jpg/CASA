-- ─────────────────────────────────────────────────────────────────────────────
--  CASA — Supabase Database Schema
--  Run this in your Supabase project → SQL Editor → New Query
-- ─────────────────────────────────────────────────────────────────────────────

-- Enable Row Level Security on all tables
-- Users can only see their own data

-- ── Users (extends Supabase auth.users) ──────────────────────────────────────
create table public.users (
  id                     uuid references auth.users(id) on delete cascade primary key,
  email                  text not null,
  full_name              text,
  company                text,
  plan                   text not null default 'starter' check (plan in ('starter','pro','enterprise')),
  stripe_customer_id     text unique,
  stripe_subscription_id text unique,
  api_calls_used         integer not null default 0,
  created_at             timestamptz not null default now()
);
alter table public.users enable row level security;
create policy "Users can view own profile"   on public.users for select using (auth.uid() = id);
create policy "Users can update own profile" on public.users for update using (auth.uid() = id);

-- ── Portfolio Properties ──────────────────────────────────────────────────────
create table public.properties (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid references public.users(id) on delete cascade not null,
  address         text not null,
  city            text,
  state           text,
  zip             text,
  apn             text,
  property_type   text,
  units           integer default 1,
  monthly_rent    numeric(10,2),
  status          text default 'occupied' check (status in ('occupied','vacant','partial','overdue','prospecting')),
  cap_rate        numeric(5,2),
  estimated_value numeric(12,2),
  notes           text,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);
alter table public.properties enable row level security;
create policy "Users manage own properties" on public.properties for all using (auth.uid() = user_id);
create index on public.properties(user_id);

-- ── Landlords ────────────────────────────────────────────────────────────────
create table public.landlords (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid references public.users(id) on delete cascade not null,
  name       text not null,
  email      text,
  phone      text,
  status     text default 'active' check (status in ('active','inactive','review')),
  notes      text,
  created_at timestamptz not null default now()
);
alter table public.landlords enable row level security;
create policy "Users manage own landlords" on public.landlords for all using (auth.uid() = user_id);

-- ── Deals (Brokerage) ─────────────────────────────────────────────────────────
create table public.deals (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid references public.users(id) on delete cascade not null,
  address       text not null,
  price         numeric(12,2),
  stage         text default 'lead' check (stage in ('lead','offer','contract','inspection','closed')),
  side          text default 'buyer' check (side in ('buyer','seller','dual')),
  commission    numeric(10,2),
  closing_date  date,
  notes         text,
  created_at    timestamptz not null default now()
);
alter table public.deals enable row level security;
create policy "Users manage own deals" on public.deals for all using (auth.uid() = user_id);

-- ── Loan Files (Mortgage) ─────────────────────────────────────────────────────
create table public.loan_files (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid references public.users(id) on delete cascade not null,
  borrower_name  text not null,
  address        text,
  loan_type      text check (loan_type in ('purchase','refinance','heloc','construction')),
  loan_amount    numeric(12,2),
  interest_rate  numeric(5,3),
  term_years     integer,
  status         text default 'application' check (status in ('pre_approval','application','underwriting','approved','closed','denied')),
  submitted_at   timestamptz,
  created_at     timestamptz not null default now()
);
alter table public.loan_files enable row level security;
create policy "Users manage own loans" on public.loan_files for all using (auth.uid() = user_id);

-- ── Target Parcels (Land Acquisition) ────────────────────────────────────────
create table public.target_parcels (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid references public.users(id) on delete cascade not null,
  apn           text not null,
  address       text,
  city          text,
  acres         numeric(8,2),
  zoning        text,
  owner_name    text,
  tax_delinquent boolean default false,
  priority      text default 'medium' check (priority in ('high','medium','low','pass')),
  notes         text,
  created_at    timestamptz not null default now()
);
alter table public.target_parcels enable row level security;
create policy "Users manage own parcels" on public.target_parcels for all using (auth.uid() = user_id);

-- ── Development Projects ──────────────────────────────────────────────────────
create table public.projects (
  id                      uuid primary key default gen_random_uuid(),
  user_id                 uuid references public.users(id) on delete cascade not null,
  name                    text not null,
  address                 text,
  project_type            text,
  budget_total            numeric(12,2),
  budget_spent            numeric(12,2) default 0,
  stage                   text default 'acquire' check (stage in ('acquire','entitle','permit','build','co')),
  target_completion_date  date,
  projected_roi           numeric(5,2),
  notes                   text,
  created_at              timestamptz not null default now()
);
alter table public.projects enable row level security;
create policy "Users manage own projects" on public.projects for all using (auth.uid() = user_id);

-- ── Leases / Legal Docs ───────────────────────────────────────────────────────
create table public.leases (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid references public.users(id) on delete cascade not null,
  property_id    uuid references public.properties(id) on delete set null,
  landlord_id    uuid references public.landlords(id) on delete set null,
  tenant_name    text,
  document_type  text default 'lease' check (document_type in ('lease','eviction','nda','other')),
  status         text default 'active',
  start_date     date,
  end_date       date,
  monthly_rent   numeric(10,2),
  notes          text,
  created_at     timestamptz not null default now()
);
alter table public.leases enable row level security;
create policy "Users manage own leases" on public.leases for all using (auth.uid() = user_id);

-- ── Property Search Cache (avoid duplicate paid API calls) ───────────────────
create table public.property_cache (
  id           uuid primary key default gen_random_uuid(),
  address_key  text not null unique,  -- normalized address used as cache key
  data         jsonb not null,
  confidence   jsonb,
  cached_at    timestamptz not null default now(),
  expires_at   timestamptz not null default (now() + interval '24 hours')
);
-- No RLS on cache — shared across all users (public data)
create index on public.property_cache(address_key);
create index on public.property_cache(expires_at);

-- ── Trigger: auto-update updated_at ──────────────────────────────────────────
create or replace function update_updated_at()
returns trigger as $$
begin new.updated_at = now(); return new; end;
$$ language plpgsql;

create trigger properties_updated_at
  before update on public.properties
  for each row execute function update_updated_at();

-- ── Auto-create user profile on signup ───────────────────────────────────────
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.users (id, email)
  values (new.id, new.email);
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
