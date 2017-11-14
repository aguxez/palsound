defmodule Palsound.DownloadSup do
  @moduledoc false

  use Supervisor

  alias Palsound.Service.Downloader

  def start_link,
    do: Supervisor.start_link(__MODULE__, :ok, name: :download_supervisor)

  def init(:ok) do
    poolboy_config = [
      {:name, {:local, :worker_downloader}},
      {:worker_module, Downloader},
      {:size, 10},
      {:max_overflow, 12}
    ]

    children = [
      :poolboy.child_spec(:worker_downloader, poolboy_config, [])
    ]

    supervise(children, strategy: :one_for_one)
  end
end
