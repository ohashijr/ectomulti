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
