defmodule PalsoundWeb.SongProcess do
  @moduledoc """
  Do the process to start downloading songs
  """

  use PalsoundWeb, :controller

  alias Palsound.Retriever.Videos

  def process_songs(conn, %{"song" => song}) do
    playlist = song["search"]

    Videos.run(playlist)

    conn
    |> put_flash(:info, "Songs are being processed")
    |> redirect(to: "/")
  end
end
