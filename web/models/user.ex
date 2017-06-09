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
