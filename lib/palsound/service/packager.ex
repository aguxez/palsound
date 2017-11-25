defmodule Palsound.Service.Packager do
  @moduledoc """
  Module in charge of packaging songs when they're done downloading and
  sending them in a .tar.gz file to the session.
  """

  use GenServer

  # API
  def start_link,
    do: GenServer.start_link(__MODULE__, [], name: :packager)

  def package(id),
    do: GenServer.call(:packager, {:package, id})

  def remove(id),
    do: GenServer.call(:packager, {:remove, id})

  # Server
  def init(state), do: {:ok, state}

  def handle_call({:package, playlist}, _from, state) do
    zip = System.find_executable("zip")

    # Creates the folder from where the songs are going to be dispatched
    unless File.exists?("priv/static/to_be_served/"),
      do: File.mkdir_p("priv/static/to_be_served/")

      options = ~w(-rj priv/static/to_be_served/song_#{playlist}.zip priv/static/songs/song_#{playlist})

    System.cmd(zip, options)

    {:reply, :package_completed, state}
  end

  def handle_call({:remove, id}, _from, state) do
    Process.sleep(1000)
    File.rm_rf("priv/static/songs/song_#{id}")
    File.rm_rf("priv/static/to_be_served/song_#{id}.zip")

    {:reply, :removed_package, state}
  end
end
