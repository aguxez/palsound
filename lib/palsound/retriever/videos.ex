defmodule Palsound.Retriever.Videos do
  @moduledoc false

  use Agent

  alias TubEx.Playlist
  alias Porcelain.Process, as: Proc

  @playlist_id "PLbggoxi0-M8ytOrH6_-pS6ynp8bAWgHUK"

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
  def run do
    songs = get_list() |> List.flatten() |> Enum.take(10)

    unless File.exists?("songs"), do: File.mkdir("songs")
    songs_path = "songs/%(title)s.%(ext)s"

    IO.puts("Starting download")

    Enum.each(songs, fn curr_song ->
      %Proc{out: audio} =
        Porcelain.spawn(System.find_executable("youtube-dl"),
          ~w(-i --quiet --audio-format mp3 --extract-audio
            -o #{songs_path} #{curr_song}), out: :stream)

      audio
    end)
  end

  def get_list(opts \\ []) do
    defaults = [maxResults: 50]

    {:ok, playlist, meta} =
      Playlist.get_items(@playlist_id, Keyword.merge(defaults, opts))

    next_page = meta["nextPageToken"]

    playlist
    |> Enum.map(fn x -> "youtube.com/watch?v=" <> x.resource_id["videoId"] end)
    |> save()

    IO.inspect next_page, label: "NEXT_PAGE"

    if next_page do
      defaults
      |> Keyword.merge([pageToken: next_page])
      |> get_list()
    else
      state = show()
      clean()
      state
    end
  end
end