defmodule Palsound.Service.Downloader do
  @moduledoc false

  use GenServer

  alias Porcelain.Process, as: Proc

  # API

  def start_link(_),
    do: GenServer.start_link(__MODULE__, [], [])

  def queue_and_download(songs, songs_path, thumb) do
    Enum.each(songs, fn(x) ->
      :poolboy.transaction(:worker_downloader, fn(pid) ->
        request = {:download, x, songs_path, thumb}
        GenServer.call(pid, request)
      end, :infinity)
    end)
  end

  # Server

  def init(state),
    do: {:ok, state}

  def handle_call({:download, song, songs_path, thumbnail}, _from, state) do
    thumbnail_value =
      case thumbnail do
        :no_thumbnail -> ""
        _ -> "--write-thumbnail"
      end

    %Proc{out: audio} =
      Porcelain.spawn(System.find_executable("youtube-dl"),
        ~w(-i --audio-format mp3 --extract-audio #{thumbnail_value}
          -o #{songs_path} #{song}), out: :stream)

    {:reply, audio, state}
  end
end
