defmodule PalsoundWeb.ProcessingChannel do
  use Phoenix.Channel

  def join("process:" <> _id, _message, socket), do: {:ok, socket}

  def push(playlist) do
    PalsoundWeb.Endpoint.broadcast("process:#{playlist}", "pushing_file", %{})
  end
end
