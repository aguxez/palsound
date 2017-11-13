defmodule PalsoundWeb.ProcessingChannel do
  @moduledoc false

  use Phoenix.Channel

  alias PalsoundWeb.Endpoint

  def join("process:" <> _id, _message, socket), do: {:ok, socket}

  def push(playlist) do
    Endpoint.broadcast("process:#{playlist}", "pushing_file",
                       %{playlist: playlist})
  end
end
