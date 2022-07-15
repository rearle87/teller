# Teller

# Startup Instructions

## 1. Install Elixir, Hex, and Erlang

- Make sure you have [the latest version of Elixir installed](https://elixir-lang.org/install.html)
- Run `mix local.hex` to get Elixir's package manager, Hex, installed and up to date.
- Installing Elixir should install Erlang as well. [Follow these instructions](https://elixir-lang.org/install.html#installing-erlang) if it does not.
- Run `elixir -v` to check that you are on Elixir 1.12 and Erlang 22

## 2. Running the Server

- Clone this repo
- Make sure you are in the `teller` folder
- Install dependencies with `mix deps.get`
- Run `mix phx.server`
- The server should be running on [localhost:4000](http://localhost:4000).

# HTTP Endpoints

## POST `/api/request_token`

Requires no payload.

**Response Payload**
Returns an API token with the current UTC datetime encoded in it.

```yaml
{
  "token": "test_QTEyOEdDTQ.TcZyMjtJ59GDGGsF1MQ0az52j-GdI23MIgsu9jvzlziu1Ge68SWDDv4FIBk.D5aCPJR0CXeHI73J.5m9QtMQP7xGTbM_341xVxcxvHprprqwgpWOF7M7n4pD6dQPFNyvghfNBdsibKLyQ5g.38-tBhnuWINusDs8jLHTuw",
}
```

**Note** The results of all other endpoints are based on the token you receive. Calls authenticated with the same token will always return the same results. Calls authenticated with different tokens will always return different results.

**TODO** Phoenix tokens are very long. I found the Joken library too late in this process (early this morning while still writing tests), but if I had more time I would use Joken to produce more compact tokens.

## GET `/api/accounts`

**Authentication**
Requires HTTP Basic Auth, with the API token in the "username" field and the "password" field left blank.

**Response Payload**
Lists all accounts associated with the provided API token.

```yaml
{
    "data": [
        {
            "currency": "USD",
            "enrollment_id": "enr_IZXsjo6-Wk-sZL8kl41Y1w",
            "id": "acc_vs80xFIwXgSuxwRtwarSNA",
            "institution": {
                "id": "chase",
                "name": "Chase"
            },
            "last_four": 5648,
            "links": {
                "balances": "localhost:4000/api/accounts/acc_vs80xFIwXgSuxwRtwarSNA/balances",
                "details": "localhost:4000/api/accounts/acc_vs80xFIwXgSuxwRtwarSNA/details",
                "self": "localhost:4000/api/accounts/acc_vs80xFIwXgSuxwRtwarSNA",
                "transactions": "localhost:4000/api/accounts/acc_vs80xFIwXgSuxwRtwarSNA/transactions"
            },
            "name": "My Checking",
            "subtype": "checking",
            "type": "depository"
        },
        {"another account"},
        {"another account"},
        ...
```

**TODO** Currently all accounts are in USD, as I wasn't clear on what sort of weight I should give to different countries to make the results seem realistic. Going forward I would figure out what Teller's customer base looked like, and make sure the distribution of currency results roughly matched that.

## GET `/api/accounts/:account_id`

**Authentication**
Requires HTTP Basic Auth, with the API token in the "username" field and the "password" field left blank.

**Response Payload**
Returns the account associated with the given account_id

```yaml
{
  "data":
    {
      "currency": "USD",
      "enrollment_id": "enr_IZXsjo6-Wk-sZL8kl41Y1w",
      "id": "acc_vs80xFIwXgSuxwRtwarSNA",
      "institution": { "id": "chase", "name": "Chase" },
      "last_four": 5648,
      "links":
        {
          "balances": "localhost:4000/api/accounts/acc_vs80xFIwXgSuxwRtwarSNA/balances",
          "details": "localhost:4000/api/accounts/acc_vs80xFIwXgSuxwRtwarSNA/details",
          "self": "localhost:4000/api/accounts/acc_vs80xFIwXgSuxwRtwarSNA",
          "transactions": "localhost:4000/api/accounts/acc_vs80xFIwXgSuxwRtwarSNA/transactions",
        },
      "name": "My Checking",
      "subtype": "checking",
      "type": "depository",
    },
}
```

## GET `/api/accounts/:account_id/details`

**Authentication**
Requires HTTP Basic Auth, with the API token in the "username" field and the "password" field left blank.

**Response Payload**
Returns the account details associated with the given account_id

```yaml
{
  "data":
    {
      "account_id": "acc_a72P6BmcX0a8O6RQR3eYYQ",
      "account_number": 56115837210,
      "links":
        {
          "account": "localhost:4000/api/accounts/acc_a72P6BmcX0a8O6RQR3eYYQ",
          "self": "localhost:4000/api/accounts/acc_a72P6BmcX0a8O6RQR3eYYQ/details",
        },
      "routing_numbers": { "ach": 811171131, "wire": 731007157 },
    },
}
```

## GET `/api/accounts/:account_id/balance`

**Authentication**
Requires HTTP Basic Auth, with the API token in the "username" field and the "password" field left blank.

**Response Payload**
Returns the account balance associated with the given account_id.

```yaml
{
  "data":
    {
      "account_id": "acc_a72P6BmcX0a8O6RQR3eYYQ",
      "available": 70682.77,
      "ledger": 70515.38,
      "links":
        {
          "account": "localhost:4000/api/accounts/acc_a72P6BmcX0a8O6RQR3eYYQ",
          "self": "localhost:4000/api/accounts/acc_a72P6BmcX0a8O6RQR3eYYQ/balances",
        },
    },
}
```

## GET `/api/accounts/:account_id/transactions?count=count?from_id=txn_id`

**Authentication**
Requires HTTP Basic Auth, with the API token in the "username" field and the "password" field left blank.

**Optional Parameters**
Both query params are entirely optional. If you include one or both, they should be passed into the request URL.

_from_id_ - The transaction at which the results should start. It will be the second transaction in the list.

_count_ - The number of transactions to return in the results.

**Response Payload**
Returns the transactions associated with the given account_id. Transactions will start 90 days before the API token was generated, and will continue until the current date. There will be 0-5 transactions per day.

```yaml
{
  "data":
    [
      {
        "account_id": "acc_a72P6BmcX0a8O6RQR3eYYQ",
        "amount": -71.37,
        "date": "2022-04-21",
        "description": "Duane Reade",
        "details":
          {
            "category": "health",
            "counterparty": { "name": "DUANE READE", "type": "organization" },
          },
        "id": "txn_BzkJIh4dXhqVy-E-3PiXng",
        "links":
          {
            "account": "localhost:4000/api/accounts/acc_a72P6BmcX0a8O6RQR3eYYQ",
            "self": "localhost:4000/api/accounts/acc_a72P6BmcX0a8O6RQR3eYYQ/transactions/txn_BzkJIh4dXhqVy-E-3PiXng",
          },
        "processing_status": "complete",
        "running_balance": 95422.11,
        "status": "posted",
        "type": "card_payment",
      },
      {
        "account_id": "acc_a72P6BmcX0a8O6RQR3eYYQ",
        "amount": -71.4,
        "date": "2022-04-21",
        "description": "Chipotle Mexican Grill",
        "details":
          {
            "category": "dining",
            "counterparty":
              { "name": "CHIPOTLE MEXICAN GRILL", "type": "organization" },
          },
        "id": "txn_UunWhjzPWvGu9LSUoV1uzA",
        "links":
          {
            "account": "localhost:4000/api/accounts/acc_a72P6BmcX0a8O6RQR3eYYQ",
            "self": "localhost:4000/api/accounts/acc_a72P6BmcX0a8O6RQR3eYYQ/transactions/txn_UunWhjzPWvGu9LSUoV1uzA",
          },
        "processing_status": "complete",
        "running_balance": 95350.71,
        "status": "posted",
        "type": "card_payment",
      },
    ],
}
```

**NOTE** The first transaction always starts with a balance in the tens of thousands of dollars to avoid months of negative transactions, which probably wouldn't look realistic if most accounts looked like that.

**TODO** Make starting balances look less like Don Draper's second bank account and more like an average Joe's. Also, randomize starting balances so that occasoinally an account overdrafts during the 90 days.

## GET `/api/accounts/:account_id/transactions/:transaction_id`

**Authentication**
Requires HTTP Basic Auth, with the API token in the "username" field and the "password" field left blank.

**Response Payload**
Returns the transactions associated with the given account_id and transaction_id

```yaml
{
  "data":
    {
      "account_id": "acc_a72P6BmcX0a8O6RQR3eYYQ",
      "amount": -71.37,
      "date": "2022-04-21",
      "description": "Duane Reade",
      "details":
        {
          "category": "health",
          "counterparty": { "name": "DUANE READE", "type": "organization" },
        },
      "id": "txn_BzkJIh4dXhqVy-E-3PiXng",
      "links":
        {
          "account": "localhost:4000/api/accounts/acc_a72P6BmcX0a8O6RQR3eYYQ",
          "self": "localhost:4000/api/accounts/acc_a72P6BmcX0a8O6RQR3eYYQ/transactions/txn_BzkJIh4dXhqVy-E-3PiXng",
        },
      "processing_status": "complete",
      "running_balance": 95422.11,
      "status": "posted",
      "type": "card_payment",
    },
}
```
