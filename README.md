# CASA — Real Estate Intelligence Platform

> The Bloomberg Terminal for Real Estate

Built with: **Next.js 14 · Supabase · Tailwind · Stripe · ATTOM · Estated · CourtListener**

---

## Quick Start

### 1. Install dependencies
```bash
npm install
```

### 2. Set up environment variables
```bash
cp .env.example .env.local
```
Then fill in every key in `.env.local` (see API key guide below).

### 3. Set up Supabase database
1. Create a project at [supabase.com](https://supabase.com)
2. Go to **SQL Editor → New Query**
3. Paste the entire contents of `supabase-schema.sql` and run it
4. Copy your project URL and anon key into `.env.local`

### 4. Run the dev server
```bash
npm run dev
```
Open [http://localhost:3000](http://localhost:3000)

---

## API Keys — Where to Get Them

| Key | Service | Free Tier | What it powers |
|-----|---------|-----------|----------------|
| `ATTOM_API_KEY` | [api.developer.attomdata.com](https://api.developer.attomdata.com) | 1,000 calls/mo | Property values, AVM, sale history, comps |
| `ESTATED_API_KEY` | [estated.com/developers](https://estated.com/developers) | 100 calls/mo dev | **Ownership (real owner name)**, liens, parcel data |
| `COURTLISTENER_TOKEN` | [courtlistener.com](https://www.courtlistener.com/register/) | Free | Federal litigation search (PACER) |
| `NEXT_PUBLIC_GOOGLE_MAPS_API_KEY` | [console.cloud.google.com](https://console.cloud.google.com) | $200 credit/mo | Address autocomplete, geocoding |
| `STRIPE_SECRET_KEY` | [dashboard.stripe.com](https://dashboard.stripe.com) | Free test mode | Subscriptions, billing |
| `NEXT_PUBLIC_SUPABASE_URL` | [supabase.com](https://supabase.com) | Free tier | Database, auth, storage |

> **Important:** ATTOM and Estated are the only paid APIs. Both have free dev tiers.
> Estated specifically returns **real, current owner names** from deed records — this is what fixes the "wrong owner" bug from the prototype.

---

## Why Data Was Wrong in the Prototype

The HTML prototype had **hardcoded fake data** (Martinez, R. & L.) — it wasn't pulling from any real source.

CASA now pulls ownership from **Estated** (deed records) and cross-verifies with **ATTOM**. If they conflict, a confidence score and conflict flag are shown transparently to the user. This is intentional — real estate data is fragmented, and surfacing that honestly is CASA's competitive edge.

**Data priority:**
- Owner name → Estated (most current deed data)
- Valuation / AVM → ATTOM (best AVM model)
- Sale history → ATTOM
- Liens / mortgage → Estated
- Litigation → CourtListener (PACER)
- Address autocomplete → Google Maps

---

## Project Structure

```
casa/
├── src/
│   ├── app/
│   │   ├── page.tsx                 # Splash / landing
│   │   ├── dashboard/               # Management module
│   │   ├── invest/                  # Investment Intel (real data)
│   │   ├── brokerage/               # Deal pipeline
│   │   ├── mortgage/                # Loan files + calculator
│   │   ├── land/                    # Parcel acquisition
│   │   ├── development/             # Project tracking
│   │   └── api/
│   │       ├── properties/route.ts  # Main property data API
│   │       └── stripe/              # Checkout + webhooks
│   ├── components/
│   │   ├── property/
│   │   │   ├── SearchBar.tsx        # Google Places autocomplete
│   │   │   └── DataConfidence.tsx   # Source transparency panel
│   ├── lib/
│   │   ├── attom.ts                 # ATTOM API wrapper
│   │   ├── estated.ts               # Estated API wrapper
│   │   ├── courtlistener.ts         # Litigation search
│   │   ├── intelligence.ts          # Multi-source aggregator + confidence scoring
│   │   ├── stripe.ts                # Payments
│   │   └── supabase.ts              # DB client
│   └── types/index.ts               # All TypeScript types
├── supabase-schema.sql              # Run this in Supabase SQL editor
├── .env.example                     # Copy to .env.local, fill in keys
└── README.md
```

---

## Deploy to Vercel

```bash
npm install -g vercel
vercel
```

Then add all `.env.local` variables in your Vercel project settings under **Settings → Environment Variables**.

For Stripe webhooks on production:
1. Go to [dashboard.stripe.com/webhooks](https://dashboard.stripe.com/webhooks)
2. Add endpoint: `https://your-domain.com/api/stripe/webhook`
3. Select events: `checkout.session.completed`, `customer.subscription.deleted`, `invoice.payment_failed`
4. Copy the webhook secret into `STRIPE_WEBHOOK_SECRET`

---

## Pricing Plans (configure in Stripe)

Create 3 products in your Stripe dashboard:
- **Starter** — $49/mo — 5 properties, basic comps
- **Pro** — $149/mo — unlimited, all modules, litigation search
- **Enterprise** — $499/mo — white-label, custom integrations

Copy each Price ID into `.env.local` as `STRIPE_PRICE_STARTER`, etc.

---

## Next Steps (recommended build order)

1. ✅ Connect API keys and test property search
2. ✅ Run Supabase schema and test auth signup
3. Add Stripe test checkout flow
4. Build out Management dashboard with real Supabase data
5. Add Regrid for parcel map layer (Land Acquisition tab)
6. Add San Diego County Assessor API for ground-truth ownership
7. Add document upload + AI extraction (OpenAI / Claude API)
8. Customer discovery interviews before building further
