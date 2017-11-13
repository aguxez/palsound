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

  alias Palsound.{Retriever.Videos, Service.Packager}
  alias PalsoundWeb.ProcessingChannel

  # @playlist "PLbggoxi0-M8xblFoDD2kq02MNfSyOYKAp"

  def start_link(name, thumb, playlist_id) do
    state = %{name: name, songs: [], thumbnail: thumb, playlist: playlist_id}
    GenServer.start_link(__MODULE__, state, name: via_tuple(name))
  end

  def queue(name, songs, thumbnail, playlist) do
    request = {:queue, songs, thumbnail, playlist}
    GenServer.cast(via_tuple(name), request)
  end

  def dispatch(name, thumbnail, playlist),
    do: GenServer.cast(via_tuple(name), {:dispatch, thumbnail, playlist})

  def via_tuple(name),
    do: {:via, Registry, {:songs_registry, name}}

  # Server
  def init(state) do
    pid = get_gen_pid(state.name)

    schedule_checks(pid, state.thumbnail, state.playlist)
    {:ok, state.songs}
  end

  defp schedule_checks(pid, thumb, playlist) do
    request = {:check, thumb, playlist}
    Process.send_after(pid, request, song_check_seconds())
  end

  def handle_info({:check, thumbnail, playlist}, state) do
    files =
      "songs_#{playlist}"
      |> File.ls!()
      |> Enum.reject(fn x -> String.ends_with?(x, "mp3") end)

    if length(files) <= 1 do
      Enum.each(files, &File.rm_rf("songs_#{playlist}/" <> &1))
      dispatch(:songs, thumbnail, playlist)
    end

    if state[:songs] == [] do
      Packager.package(playlist)
      Logger.info("ALL SONGS DISPATCHED")
      ProcessingChannel.push(playlist)
    else
      pid = get_gen_pid(:songs)
      schedule_checks(pid, thumbnail, playlist)
    end

    {:noreply, state}
  end

  # This function takes 10 elements of the passed list to start the queue
  # then after all the process the `dispatch/1` function will send the
  # remaining songs, 10 by 10.
  def handle_cast({:queue, songs, thumbnail, playlist}, state) do
    ten_songs = Enum.take(songs, 10)
    songs_path = "songs_#{playlist}/%(title)s.%(ext)s"
    state_map = Keyword.put(state, :songs, songs)

    new_state =
      Enum.reject(state_map[:songs], fn x -> x in ten_songs end)

    Videos.queue_and_download(ten_songs, songs_path, thumbnail)

    {:noreply, [songs: new_state]}
  end

  def handle_cast({:dispatch, thumbnail, playlist}, state) do
    new_songs_list = Enum.take(state[:songs], 10)
    new_state = Enum.reject(state[:songs], fn x -> x in new_songs_list end)

    Logger.info("Sending #{length(new_songs_list)} songs to queue")
    queue(:songs, new_state, thumbnail, playlist)

    {:noreply, [songs: new_state]}
  end

  defp get_gen_pid(name) do
    [{pid, _}] = Registry.lookup(:songs_registry, name)
    pid
  end

  # Checks how often the :check message is sent to queue the songs,
  # 30 seconds is the default. This can be changed because download speeds
  # are different to each person.
  defp song_check_seconds,
    do: Application.get_env(:palsound, :check_seconds, 45_000)
end
