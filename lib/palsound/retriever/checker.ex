defmodule Palsound.Retriever.Checker do
  @moduledoc """
  Since (at the moment) there's no a way of knowing if all downloads are
  finished or still going but by checking the extension, we'll run
  a check to see if all files are ".mp3", if there's at least two files
  without the .mp3 extension we'll delete them and start downloading
  the other ones in the queue, that way the system doesn't crash because
  of a overload.
  """

  use GenServer

  require Logger

  alias Palsound.Retriever.Videos

  def start_link(name) do
    GenServer.start_link(__MODULE__, %{name: name, songs: []},
                        name: via_tuple(name))
  end

  def queue(name, songs) do
    GenServer.cast(via_tuple(name), {:queue, songs})
  end

  def dispatch(name) do
    GenServer.cast(via_tuple(name), :dispatch)
  end

  def via_tuple(name) do
    {:via, Registry, {:songs_registry, name}}
  end

  # Server
  def init(%{name: name, songs: songs}) do
    pid = get_gen_pid(name)

    schedule_checks(pid)
    {:ok, songs}
  end

  defp schedule_checks(pid) do
    Process.send_after(pid, :check, 30_000)
  end

  def handle_info(:check, state) do
    files =
      "songs"
      |> File.ls!()
      |> Enum.reject(fn x -> String.ends_with?(x, "mp3") end)

    if length(files) <= 1 do
      Enum.each(files, &File.rm_rf("songs/" <> &1))
      dispatch(:songs)
      IO.inspect(state, label: "STATE")
    end

    unless state[:songs] == [] do
      pid = get_gen_pid(:songs)
      schedule_checks(pid)
    end

    {:noreply, state}
  end

  # This function takes 10 elements of the passed list to start the queue
  # then after all the process the `dispatch/1` function will send the
  # remaining songs, 10 by 10.
  def handle_cast({:queue, songs}, state) do
    ten_songs = Enum.take(songs, 10)
    songs_path = "songs/%(title)s.%(ext)s"
    state_map = Keyword.put(state, :songs, songs)

    new_state =
      Enum.reject(state_map[:songs], fn x -> x in ten_songs end)

    Videos.queue_and_download(ten_songs, songs_path)

    {:noreply, [songs: new_state]}
  end

  def handle_cast(:dispatch, state) do
    new_songs_list = Enum.take(state[:songs], 10)
    new_state = Enum.reject(state[:songs], fn x -> x in new_songs_list end)

    Logger.info("Sending #{length(new_songs_list)} songs to queue")
    queue(:songs, new_state)

    {:noreply, [songs: new_state]}
  end

  defp get_gen_pid(name) do
    [{pid, _}] = Registry.lookup(:songs_registry, name)
    pid
  end
end
