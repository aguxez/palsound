defmodule Palsound.Service.Packager do
  @moduledoc """
  Module in charge of packaging songs when they're done downloading and
  sending them in a .tar.gz file to the session.
  """

  # TODO: This should take the name of a folder and then packaging
  # that one, deleting it right after the process is done.

  use GenServer

  # API
  def start_link do
    GenServer.start_link(__MODULE__, [], name: :packager)
  end

  def package do
    GenServer.call(:packager, :package)
  end

  # Server
  def init(state), do: {:ok, state}

  def handle_call(:package, _from, state) do
    tar = System.find_executable("tar")

    System.cmd(tar, ~w(-cvf priv/static/songs/songs.tar songs/))

    {:noreply, state}
  end
end
