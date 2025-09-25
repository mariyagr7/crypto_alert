# README

# Crypto Alert System

This Rails system provides automated price alerts for cryptocurrency symbols, using Sidekiq for background processing, Redis for caching prices, and multiple notification channels (Telegram, email, log).  

---

## Table of Contents

1. [Overview](#overview)  
2. [Architecture](#architecture)  
3. [Workers](#workers)  
4. [Notifications](#notifications)  
5. [Price Fetching](#price-fetching)  
6. [Alert Flow](#alert-flow)  
7. [Installation](#installation)  
8. [Usage](#usage)  

---

## Overview

- Users can create **alerts** with:
  - `symbol` (e.g., BTCUSDT)
  - `direction` (`up` or `down`)
  - `threshold` price
  - `check_interval_seconds` and `cooldown_seconds`
  - `channels` (`log`, `email`, `telegram`)  

- Alerts are **checked automatically** using background jobs.  
- Notifications are dispatched via multiple channels if conditions are met.  

---
flowchart TD
    A[Alerts Table] --> B[AlertSchedulerWorker<br>Runs periodically<br>Schedules AlertCheckerWorker]
    B --> C[AlertCheckerWorker<br>Fetches price from Redis or PriceFetcher<br>Checks alert conditions<br>Marks alert triggered<br>Enqueues NotificationDispatcherWorker]
    C --> D[NotificationDispatcherWorker<br>Formats payload using NotificationFormatter<br>Enqueues NotificationSenderWorker for each channel]
    D --> E[NotificationSenderWorker<br>Dispatches payload to DispatcherNotification]
    E --> F[DispatcherNotification<br>Calls the appropriate channel class<br>(LogNotification, EmailNotification, TelegramNotification)]

## Workers

### AlertSchedulerWorker
- Runs periodically to schedule alerts that are due.
- Uses `next_check_at` to manage intervals.

### AlertCheckerWorker
- Checks alert conditions against the current price.
- Retrieves price from Redis cache, or fetches and caches it if missing.
- Marks the alert as triggered if conditions are met.
- Enqueues `NotificationDispatcherWorker` with alert ID and current price.

### NotificationDispatcherWorker
- Formats alert into a payload (hash with symbol, price, message, timestamp).
- Enqueues a `NotificationSenderWorker` for each notification channel.

### NotificationSenderWorker
- Dispatches the payload to the correct channel using `DispatcherNotification`.

### PriceFetcherWorker
- Fetches current prices for all symbols from an external API.
- Updates Redis cache with the latest prices.

### DispatcherNotification
- A lookup table (hash) mapping channel names (:telegram, :log, :email) → their notification classes.

- Each of those classes (TelegramNotification, LogNotification, EmailNotification) implements .notify(payload)

```ruby
{
  telegram: TelegramNotification,
  log: LogNotification,
  email: EmailNotification
}

{
  "symbol"    => "BTCUSDT",
  "price"     => "67000",
  "message"   => "ALERT: BTCUSDT up threshold=65000, current=67000",
  "timestamp" => "2025-09-25T12:21:33Z"
}
```

### NotificationFormatter

- Converts alert + price into a readable message:

```ruby
    ALERT: BTCUSDT up threshold=65000, current=67000
```

- Builds payload hash for notifications:

```ruby
{
  "symbol"    => "BTCUSDT",
  "price"     => "67000",
  "message"   => "ALERT: BTCUSDT up threshold=65000, current=67000",
  "timestamp" => "2025-09-25T12:21:33Z"
}
```

## Channel Implementations

- **LogNotification**: Logs alert message.  
- **EmailNotification**: Sends email via `AlertMailer`.  
- **TelegramNotification**: Sends message via Telegram bot.  

---

## Alert Flow Example

1. `AlertSchedulerWorker` finds all due alerts.  
2. For each alert, it schedules an `AlertCheckerWorker`.  
3. `AlertCheckerWorker`:
   - Fetches current price.  
   - Checks if the alert should trigger.  
   - Marks the alert as triggered.  
   - Enqueues `NotificationDispatcherWorker`.  
4. `NotificationDispatcherWorker` formats the alert payload.  
5. `NotificationSenderWorker` dispatches the payload to all configured channels.  
6. Each channel handles the payload:
   - Logs it  
   - Sends email  
   - Sends Telegram message  

   ## Docker Installation

```bash
   docker compose build
   docker compose run --rm web bundle exec rails db:create db:migrate db:seed
   docker compose up
```
