defmodule PalsoundWeb.ProcessingChannel do
  use Phoenix.Channel

  def join("process:" <> _id, _message, socket) do
    {:ok, socket}
  end
end
