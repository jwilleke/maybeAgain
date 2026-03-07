# Project Log

AI agent session tracking. See [CHANGELOG.md](./CHANGELOG.md) for version history.

## Format

```
## yyyy-MM-dd-##

- Agent: [Claude/Gemini/Other]
- Subject: [Brief description]
- Key Decision: [decision]
- Current Issue: [issue]
- Testing:
  - npm test: 58 suites passed, 1380 tests passed
- Work Done:
  - [task 1]
  - [task 2]
- Commits: [hash]
- Files Modified:
  - [file1.js]
  - [file2.md]
```

## 2026-03-07

### Local Development Setup

- Installed Ruby 3.4.4 via rbenv
- Installed PostgreSQL 17 via Homebrew
- Installed Redis via Homebrew
- Ran `bin/setup` to create databases and seed data
- Changed dev server port to 4000 (port 3000 in use) via `Procfile.dev`

### Synth API Investigation (Issue #1)

- Confirmed Synth API (`api.synthfinance.com`) is no longer operational
- `synthfinance.com` now appears to be a different product ("Monthly Narratives for CFOs")
- This breaks investment account balance syncing and exchange rate normalization for self-hosters
- USD-only users are less affected by the exchange rate issue

### Alpha Vantage Security Price Provider (Issue #2)

- Added `Provider::AlphaVantage` implementing `Provider::SecurityConcept`
- Registered in `Provider::Registry` for `:securities` concept
- Made `Security::Provided#provider` configurable via `SECURITY_PROVIDER` env var
- Free tier: 25 requests/day, 5 requests/minute — sufficient for personal use
- API key obtained and configured in `.env.local`

### Plaid Setup (Issue #3)

- Plaid required for automated bank and investment account syncing
- Free developer account available at <https://dashboard.plaid.com/signup>
- Sandbox environment for local dev, development environment for real banks (free, up to 100 items)
- Keys to be added to `.env.local` once obtained

### CLAUDE.md Improvements

- Added tech stack section
- Expanded core domain model with delegated type details for Account and Entry
- Documented entry amount sign convention (negative = inflow, positive = outflow)
- Added sync hierarchy documentation
- Added data provider pattern documentation

### Open Items

- [ ] Obtain Plaid API keys and configure for bank sync (Issue #3)
- [ ] Test Alpha Vantage integration end-to-end with real securities
- [ ] Investigate exchange rate provider alternative (Synth also provided exchange rates)
- [ ] Load demo data: `rake demo_data:default`
