# Hiive Pre-IPO Secondary Marketplace

A full-stack demo of a pre-IPO secondary marketplace with deal room and order book functionality. Users can buy/sell shares in pre-IPO companies with real-time matching and updates.

## Tech Stack

- **Frontend**: React + TypeScript + Vite + TanStack Query
- **Backend**: Elixir Phoenix
- **Database**: PostgreSQL
- **Real-time**: Phoenix Channels (WebSockets)

## Quick Start

### 1. Start PostgreSQL

```bash
docker-compose up -d
```

### 2. Set up Backend

```bash
cd backend
mix setup  # Creates DB, runs migrations, seeds data
mix phx.server
```

Backend runs on http://localhost:4000

### 3. Set up Frontend

```bash
cd frontend
npm install
npm run dev
```

Frontend runs on http://localhost:5173

## Features

### User Selection
- Select from seeded demo users via dropdown in header
- Each user has different cash balances and share holdings

### Company List
- Browse available pre-IPO companies
- View company name, ticker, sector, and valuation

### Deal Room (Company Detail)
- **Order Book**: Real-time bids and asks, aggregated by price
- **Order Form**: Place buy/sell limit orders
- **Trades Feed**: Live feed of executed trades
- **My Orders**: View and cancel your open orders

### Matching Engine
- Price-time priority matching algorithm
- Partial fills supported
- Executes at maker (resting order) price
- All operations within a single database transaction

### Real-time Updates
- Order book updates via WebSockets
- New trade notifications
- Order status changes (filled, cancelled, expired)

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/v1/users` | List users |
| GET | `/api/v1/users/:id` | User details + holdings |
| GET | `/api/v1/companies` | List companies |
| GET | `/api/v1/companies/:id` | Company details |
| GET | `/api/v1/companies/:id/orders` | Order book (bids/asks) |
| POST | `/api/v1/companies/:id/orders` | Create order |
| DELETE | `/api/v1/orders/:id` | Cancel order |
| GET | `/api/v1/companies/:id/trades` | Trades feed |

## WebSocket Channels

- `company:{id}` - Order book updates, new trades
- `user:{id}` - Personal notifications (fills, cancels)

## Testing

Run backend tests:

```bash
cd backend
mix test
```

## Test Scenarios

1. Select different users from the dropdown
2. View company list, click into a deal room
3. Create buy/sell orders at various prices
4. Verify orders appear in order book
5. Create crossing orders to trigger matches
6. Verify trades appear in feed and balances update
7. Cancel an order
8. Open multiple browser tabs to verify real-time updates

## Project Structure

```
hiive/
├── docker-compose.yml          # PostgreSQL
├── backend/
│   ├── lib/backend/
│   │   ├── accounts/           # Users, holdings
│   │   ├── marketplace/        # Companies, orders, trades
│   │   ├── matching/engine.ex  # Matching engine
│   │   ├── audit/              # Audit logging
│   │   └── scheduler/          # Order expiration
│   ├── lib/backend_web/
│   │   ├── controllers/api/v1/ # REST API
│   │   └── channels/           # Phoenix Channels
│   └── priv/repo/
│       ├── migrations/
│       └── seeds.exs
└── frontend/
    ├── src/
    │   ├── api/                # API client
    │   ├── components/         # React components
    │   ├── contexts/           # User context
    │   ├── hooks/              # Custom hooks
    │   ├── lib/                # Socket client
    │   └── pages/              # Page components
    └── package.json
```

## Seeded Data

### Users (8 total)
- Alice Chen ($500K balance)
- Bob Smith ($750K balance)
- Carol Davis ($1M balance)
- And more...

### Companies (8 total)
- SpaceX (Aerospace, $150B valuation)
- Stripe (Fintech, $50B valuation)
- Databricks (Enterprise Software, $43B valuation)
- Discord (Social Media, $15B valuation)
- Canva (Design Software, $26B valuation)
- Plaid (Fintech, $13B valuation)
- Notion (Productivity, $10B valuation)
- Figma (Design Software, $20B valuation)

Each user has holdings in several companies to enable trading.
