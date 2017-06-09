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

  defp account_changeset(%{"org_name" => org_name}) do
    Account.changeset(%Account{name: org_name})
  end

  defp user_changeset(params) do
    user_params = Map.take(params, ["email"])
    User.changeset(%User{}, user_params)
  end

  defp membership_changeset(changes) do
    %Membership{account_id: changes.account.id, user_id: changes.user.id, role: "admin"}
  end

end
