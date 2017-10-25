defmodule Palsound.Retriever.Videos do
  @moduledoc false

  use Agent

  require Logger

  alias TubEx.Playlist
  alias Porcelain.Process, as: Proc
  alias Palsound.{Retriever.Checker, Service.Cache}

  # @playlist_id "PLbggoxi0-M8zfSf5gu4AVHO5BhX6zyv0Z"
  # Palsound.Retriever.Videos.run("PLbggoxi0-M8zfSf5gu4AVHO5BhX6zyv0Z")

  # Agent
  def start_link do
    Agent.start_link(fn -> [] end, name: :videos)
  end

  def save(list) do
    Agent.update(:videos, fn x -> List.insert_at(x, -1, list) end)
  end

  def show do
    Agent.get(:videos, &(&1))
  end

  def clean do
    Agent.update(:videos, fn _state -> [] end)
  end

  # Server and API
  def run(playlist_id, amount \\ nil) do
    playlist_id
    |> get_list()
    |> Cache.save()

    case Cache.show() do
      {:ok, playlist, meta} ->
        songs_list =
          process_playlist({:ok, playlist, meta}, [maxResults: 50], playlist_id)

        songs = fn ->
          if amount do
            songs_list
            |> List.flatten()
            |> Enum.take(amount)
          else
            List.flatten(songs_list)
          end
        end

        unless File.exists?("songs"), do: File.mkdir("songs")

        Checker.start_link(:songs)
        Checker.queue(:songs, songs.())

        queued = "Queued songs"
        Logger.info(queued)
        queued
      {:error, _} ->
        []
    end
  end

  def get_list(playlist_id, opts \\ []) do
    defaults = [maxResults: 50]

    Playlist.get_items(playlist_id, Keyword.merge(defaults, opts))
  end

  defp process_playlist({:ok, playlist, meta}, defaults, playlist_id) do
    next_page = meta["nextPageToken"]

    playlist
    |> Enum.map(fn x -> "youtube.com/watch?v=" <> x.resource_id["videoId"] end)
    |> save()

    if next_page do
      options = Keyword.merge(defaults, [pageToken: next_page])
      get_list(playlist_id, options)
    else
      state = show()
      clean()
      state
    end
  end

  defp process_playlist({:error, _}, _, _), do: []

  def queue_and_download(songs, songs_path) do
    Enum.each(songs, fn curr_song ->
      %Proc{out: audio} =
        Porcelain.spawn(System.find_executable("youtube-dl"),
          ~w(-i --audio-format mp3 --extract-audio
            -o #{songs_path} #{curr_song}), out: :stream)

      #TODO: Find a way to make thumbnails optional.
      audio
    end)
  end
end
