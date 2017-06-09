defmodule EctoMulti.Router do
  use EctoMulti.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", EctoMulti do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index

    resources "/users", UserController
    resources "/accounts", AccountController
    resources "/memberships", MembershipController
    get "/registrations", RegistrationController, :index
    get "/registrations/new", RegistrationController, :new
    post "/registrations", RegistrationController, :create
  end

  # Other scopes may use custom stacks.
  # scope "/api", EctoMulti do
  #   pipe_through :api
  # end
end
