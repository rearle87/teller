defmodule TellerWeb.Router do
  use TellerWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {TellerWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug TellerWeb.Plugs.APIAuth
  end

  scope "/", TellerWeb do
    pipe_through :browser

    get "/", PageController, :index
  end

  # Other scopes may use custom stacks.
  scope "/api", TellerWeb do
    pipe_through :api

    # Tokens
    post("/request_token", APITokenController, :new)

    # Accounts
    resources("/accounts", AccountController, except: [:new, :edit])
    get("accounts/:account_id", AccountController, :show)
    get("accounts/:account_id/details", AccountController, :show_details)
    get("accounts/:account_id/balance", AccountController, :show_balance)

    # Account Transactions
    get("accounts/:account_id/transactions", TransactionController, :show_for_account)

    get(
      "accounts/:account_id/transactions/:transaction_id",
      TransactionController,
      :show
    )
  end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: TellerWeb.Telemetry
    end
  end

  # Enables the Swoosh mailbox preview in development.
  #
  # Note that preview only shows emails that were sent by the same
  # node running the Phoenix server.
  if Mix.env() == :dev do
    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
