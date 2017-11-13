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
    songs_checkbox = song["all"]
    quantity_string = song["songs_quantity"]
    thumbnail_checkbox = song["thumbnail"]

    # Check the value of the 'thumbnail'
    thumbnail_value =
      if thumbnail_checkbox == "true" do
        :get_thumbnail
      else
        :no_thumbnail
      end


    # Check if the user is requesting the whole playlist of songs
    # or just a specified amount
    fetched_songs? =
      if songs_checkbox == "true" do
        Videos.run(playlist, nil, thumbnail_value)
      else
        quantity = String.to_integer(quantity_string)
        Videos.run(playlist, quantity, thumbnail_value)
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
