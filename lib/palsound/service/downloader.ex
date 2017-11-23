defmodule Palsound.Service.Downloader do
  @moduledoc false

  use GenServer

  alias Porcelain.Process, as: Proc

  # API

  def queue_and_download(songs, songs_path, thumb) do
    thumbnail_value =
      case thumb do
        :no_thumbnail -> ""
        _ -> "--write-thumbnail"
      end

    Enum.each(songs, fn x ->
      %Proc{out: audio} =
        Porcelain.spawn(System.find_executable("youtube-dl"),
          ~w(-i --audio-format mp3 --extract-audio #{thumbnail_value}
            -o #{songs_path} #{x}), out: :stream)

      audio
    end)
  end
end
