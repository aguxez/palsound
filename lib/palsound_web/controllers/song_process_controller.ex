defmodule PalsoundWeb.SongProcess do
  @moduledoc """
  Do the process to start downloading songs
  """

  use PalsoundWeb, :controller

  alias Palsound.Retriever.Videos

  def processing(conn, %{"playlist_id" => id}) do
    render(conn, "song_processing.html", id: id)
  end

  def process_songs(conn, %{"song" => song}) do
    playlist = song["search"]
    checkbox = song["all"]
    quantity_string = song["songs_quantity"]

    fetched_songs? =
      if checkbox == "true" do
        Videos.run(playlist)
      else
        quantity = String.to_integer(quantity_string)
        Videos.run(playlist, quantity)
      end

    case fetched_songs? do
      "Queued songs" ->
        conn
        |> put_flash(:info, "Songs are being processed.")
        |> redirect(to: song_process_path(conn, :processing, playlist))
      _ ->
        conn
        |> put_flash(:error, "Something went wrong while processing your playlist.")
        |> redirect(to: "/")
    end
  end
end
