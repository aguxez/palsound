defmodule Palsound.Application do
  use Application

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    # Define workers and child supervisors to be supervised
    children = [
      # Start the Ecto repository
      supervisor(Palsound.Repo, []),
      # Start the endpoint when the application starts
      supervisor(PalsoundWeb.Endpoint, []),
      supervisor(Registry, [:unique, :songs_registry]),
      worker(Palsound.Retriever.Videos, []),
      worker(Palsound.Service.Cache, []),
    ]

    dynamically = [worker(Palsound.Retriever.Checker, [])]
    supervise(dynamically, strategy: :simple_one_for_one)

    opts = [strategy: :one_for_one, name: Palsound.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    PalsoundWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
