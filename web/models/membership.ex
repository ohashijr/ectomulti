defmodule EctoMulti.Membership do
  use EctoMulti.Web, :model

  schema "memberships" do
    field :role, :string
    belongs_to :user, EctoMulti.User
    belongs_to :account, EctoMulti.Account

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:role])
    |> validate_required([:role])
  end
end
