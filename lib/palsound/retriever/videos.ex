defmodule Palsound.Retriever.Videos do
  @moduledoc false

  use Agent

  alias TubEx.Playlist
  alias Porcelain.Process, as: Proc
  alias Palsound.Retriever.Checker

  # @playlist_id "PLbggoxi0-M8ytOrH6_-pS6ynp8bAWgHUK"
  # Palsound.Retriever.Videos.run("PLbggoxi0-M8ytOrH6_-pS6ynp8bAWgHUK")

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
  def run(playlist) do
    songs =
      playlist
      |> get_list()
      |> List.flatten()

    unless File.exists?("songs"), do: File.mkdir("songs")

    Checker.start_link(:songs)

    IO.puts("Started checkers")

    Checker.queue(:songs, songs)

    IO.puts("Queued songs")
  end

  def get_list(playlist_id, opts \\ []) do
    defaults = [maxResults: 50]

    {:ok, playlist, meta} =
      Playlist.get_items(playlist_id, Keyword.merge(defaults, opts))

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

  def queue_and_download(songs, songs_path) do
    Enum.each(songs, fn curr_song ->
      %Proc{out: audio} =
        Porcelain.spawn(System.find_executable("youtube-dl"),
          ~w(-i --audio-format mp3 --extract-audio --write-thumbnail
            -o #{songs_path} #{curr_song}), out: :stream)

      audio
    end)
  end
end
