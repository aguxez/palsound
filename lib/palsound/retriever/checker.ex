defmodule Palsound.Retriever.Checker do
  @moduledoc """
  Since (at the moment) there's no a way of knowing if all downloads are
  finished or still going but by checking the extension, we'll run
  a check to see if all files are ".mp3", if there's at least two files
  without the .mp3 extension we'll delete them and start downloading
  the other ones in the queue, that way the system doesn't crash because
  of a overload.
  """

  # TODO: Make this in a form of queue so Songs will be dispatched
  # like the should...

  use GenServer

  alias Palsound.Retriever.Videos

  def start_link(name) do
    GenServer.start_link(__MODULE__, %{name: name}, name: via_tuple(name))
  end

  def queue(name, songs) do
    GenServer.cast(via_tuple(name), {:queue, songs})
  end

  def dispatch(name) do
    GenServer.cast(via_tuple(name), :dispatch)
  end

  def via_tuple(name) do
    {:via, :gproc, {:n, :l, {:name, name}}}
  end

  # Server
  def init(%{name: name} = state) do
    schedule_checks(name)
    {:ok, state}
  end

  defp schedule_checks(name) do
    Process.send_after(name, :check, 60_000)
  end

  def handle_info(:check, state) do
    files =
      "songs"
      |> File.ls!()
      |> Enum.reject(fn x -> String.ends_with?(x, "mp3") end)

    if length(files) <= 2 do
      Enum.each(files, &File.rm_rf("songs/" <> &1))
      dispatch(:songs)
    end

    {:ok, state}
  end

  def handle_cast({:queue, songs}, state) do
    new_state =
      state
      |> Map.put(:songs, [])
      |> Map.put(:songs, songs)

    Videos.queue_and_download(songs, songs_path)

    {:noreply, new_state}
  end

  def handle_cast(:dispatch, state) do
    new_songs_list = Enum.take(state, 10)
    songs_path = "songs/%(title)s.%(ext)s"
    new_state = Enum.reject(state, fn x -> x in new_songs_list end)

    queue(:songs, new_songs_list)

    {:noreply, new_state}
  end
end
