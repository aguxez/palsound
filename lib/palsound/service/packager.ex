defmodule Palsound.Service.Packager do
  @moduledoc """
  Module in charge of packaging songs when they're done downloading and
  sending them in a .tar.gz file to the session.
  """

  use GenServer

  # API
  def start_link,
    do: GenServer.start_link(__MODULE__, [], name: :packager)

  def package(id) do
    GenServer.call(:packager, {:package, id})
  end

  # Server
  def init(state), do: {:ok, state}

  def handle_call({:package, playlist}, _from, state) do
    tar = System.find_executable("tar")

    # Create the 'songs' folder if it doesn't exists and then
    # creates each folder for each playlist respectively.
    unless File.exists?("priv/static/songs"),
      do: File.mkdir("priv/static/songs/")

    unless File.exists?("priv/static/songs/songs_#{playlist}"),
      do: File.mkdir("priv/static/songs/songs_#{playlist}")

    System.cmd(tar, ~w(-cvf priv/static/songs/songs_#{playlist}.tar songs_#{playlist}/))

    {:reply, :ok, state}
  end
end
