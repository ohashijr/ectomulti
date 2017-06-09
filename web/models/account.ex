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
