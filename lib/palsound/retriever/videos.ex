defmodule Palsound.Retriever.Videos do
  @moduledoc false

  use Agent

  require Logger

  alias TubEx.Playlist
  alias Porcelain.Process, as: Proc
  alias Palsound.{Retriever.Checker, Service.Cache}

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
  def run(playlist_id, amount \\ nil, thumbnail \\ :no_thumbnail)
  def run(playlist_id, amount, thumbnail) do
    playlist_id
    |> get_list()
    |> Cache.save()

    case Cache.show() do
      {:ok, playlist, meta} ->
        songs_list =
          process_playlist({:ok, playlist, meta}, [maxResults: 50], playlist_id)

        songs = get_songs_amount(songs_list, amount)

        unless File.exists?("songs_#{playlist_id}"),
          do: File.mkdir("songs_#{playlist_id}")

        Checker.start_link(:songs, thumbnail, playlist_id)
        Checker.queue(:songs, songs, thumbnail, playlist_id)

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

  # If an amount is passed then get that amount of songs from the list
  # otherwise, get the whole list
  defp get_songs_amount(songs_list, amount) do
    if amount do
      songs_list
      |> List.flatten()
      |> Enum.take(amount)
    else
      List.flatten(songs_list)
    end
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

  # TODO: Move this to a Pool of workers
  def queue_and_download(songs, songs_path, thumbnail) do
    thumbnail_value =
      case thumbnail do
        :no_thumbnail -> ""
        _ -> "--write-thumbnail"
      end

    Enum.each(songs, fn curr_song ->
      %Proc{out: audio} =
        Porcelain.spawn(System.find_executable("youtube-dl"),
          ~w(-i --audio-format mp3 --extract-audio #{thumbnail_value}
            -o #{songs_path} #{curr_song}), out: :stream)

      audio
    end)
  end
end
