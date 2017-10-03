defmodule PalsoundWeb.PageController do
  use PalsoundWeb, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
