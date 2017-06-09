# EctoMulti

O objetivo é testar a funcionalidade do Ecto.Multi, persistindo várias tabelas em uma transação. Temos User - Membership - Account, e Registration que vai criar os três ao mesmo tempo.

* Criar a base de dados
```elixir
mix ecto.create
```

* Gerar o User, Account e Membership
```elixir
mix phoenix.gen.html User users email

mix phoenix.gen.html Account accounts name

mix phoenix.gen.html Membership memberships role user_id:references:users account_id:references:accounts
```

* Adicionar as rotas

```elixir
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
  end

  # Other scopes may use custom stacks.
  # scope "/api", EctoMulti do
  #   pipe_through :api
  # end
end
```

* Adicionar a restrição no email do User
```elixir
defmodule EctoMulti.Repo.Migrations.CreateUser do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :email, :string

      timestamps()
    end

    create unique_index(:users, [:email])
  end
end
```

* migrar
```elixir
mix ecto.migrate
```

* Configurar os modelos

```elixir
defmodule EctoMulti.Account do
  use EctoMulti.Web, :model

  schema "accounts" do
    field :name, :string
    has_many :memberships, EctoMulti.Membership
    has_many :users, through: [:memberships, :user]

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:name])
    |> validate_required([:name])
  end
end

defmodule EctoMulti.User do
  use EctoMulti.Web, :model

  schema "users" do
    field :email, :string

    has_many :memberships, EctoMulti.Membership
    has_many :accounts, through: [:memberships, :account]

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:email])
    |> validate_required([:email])
    |> unique_constraint(:email)
  end
end
```

* Teste a aplicação
Teste o CRUD dos usuários `/users`, das contas `/accounts` e membership `/memberships`

* Gerar o model Registration
mix phoenix.gen.model Registration registrations --no-migration

```elixir
defmodule EctoMulti.Registration do
  use EctoMulti.Web, :model
  alias EctoMulti.{Account, User, Membership, Repo}

  embedded_schema do
    field :email
    field :org_name
  end

  @required_fields ~w(email org_name)a

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
  end

  def to_multi(params \\ %{}) do
    Ecto.Multi.new
    |> Ecto.Multi.insert(:account, account_changeset(params))
    |> Ecto.Multi.insert(:user, user_changeset(params))
    |> Ecto.Multi.run :membership, fn changes ->
      Repo.insert membership_changeset(changes)
    end
  end

  defp account_changeset(%{"org_names" => org_name}) do
    Account.changeset(%Account{name: org_name})
  end

  defp user_changeset(params) do
    user_params = Map.take(params, ["email"])
    User.changeset(%User{}, user_params)
  end

  defp membership_changeset(changes) do
    %Membership{account_id: changes.account.id}, user_id: changes.user.id, role: :admin}
  end

end
```

* Controller Registration

```elixir
defmodule EctoMulti.RegistrationController do
  use EctoMulti.Web, :controller
  alias EctoMulti.{Registration, Repo, Membership}

  def index(conn, _params) do
    memberships = Repo.all(Membership) |> Repo.preload([:account, :user])
    render conn, "index.html", memberships: memberships
  end

  def new(conn, _params) do
    changeset = Registration.changeset(%Registration{})
    render conn, "new.html", changeset: changeset
  end

  def create(conn, %{"registration" => registration_params}) do
    changeset = Registration.changeset(%Registration{}, registration_params)
    if changeset.valid? do
      case Repo.transaction(Registration.to_multi(registration_params)) do
        {:ok, _} ->
          redirect conn, to: registration_path(conn, :index)
        {:error, _operation, repo_changeset, _changeset} ->
          changeset = copy_errors(repo_changeset, changeset)
          render conn, :new, changeset: %{changeset | action: :insert}
      end
    else
      render conn, :new, changeset: %{changeset | action: :insert}
    end
  end

  defp copy_errors(from, to) do
    Enum.reduce from.errors, to, fn {field, {msg, additional}}, acc ->
      Ecto.Changeset.add_error(acc, field, msg, additional: additional)
    end
  end
end
```

* Criar /templates/registration

** form.html.eex
```elixir
<%= form_for @changeset, registration_path(@conn, :create), fn f -> %>
  <div class="form-group">
    <%= label f, :org_name %>
    <%= text_input f, :org_name, class: "form-control" %>
    <%= error_tag f, :org_name %>
  </div>
  <div class="form-group">
    <%= label f, :email %>
    <%= text_input f, :email, class: "form-control" %>
    <%= error_tag f, :email %>
  </div>
  <%= submit "Create", class: "btn btn-primary" %>
<% end %>
```
** index.html.eex
```elixir
<h2>Listing registration</h2>

<table class="table">
  <thead>
    <tr>
      <th>Nome</th>
      <th>Email</th>
      <th></th>
    </tr>
  </thead>
  <tbody>
    <%= for memb <- @memberships do %>
      <tr>
        <td><%= memb.account.name %></td>
        <td><%= memb.user.email %></td>
        <td class="text-right">

        </td>
      </tr>
    <% end %>
  </tbody>
</table>

<%= link "New registration", to: registration_path(@conn, :new) %>
```

** new.html.eex
```elixir
<h2>New registration</h2>

<%= render "form.html", changeset: @changeset, conn: @conn,
                        action: registration_path(@conn, :create) %>

<%= link "Back", to: registration_path(@conn, :index) %>
```

* Criar /views/registration_view.ex
```elixir
defmodule EctoMulti.RegistrationView do
  use EctoMulti.Web, :view
end
```

* Adicionar as rotas
```elixir
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
```
