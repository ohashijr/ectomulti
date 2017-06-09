defmodule EctoMulti.PageController do
  use EctoMulti.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
