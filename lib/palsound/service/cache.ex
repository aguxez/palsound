defmodule Palsound.Service.Cache do
  @moduledoc """
  Module in charge on saving the state of a playlist search if succesful
  so we don't hit the same page twice unnecessarily.
  """

  # TODO: Make it multi-user; maybe add a pool of workers so it doesn't grow
  # too much.

  use GenServer

  # API
  def start_link do
    GenServer.start_link(__MODULE__, [], name: :cache)
  end

  def show do
    GenServer.call(:cache, :show)
  end

  def save(list) do
    GenServer.cast(:cache, {:save, list})
  end

  def clean do
    GenServer.cast(:cache, :clean)
  end

  # Server
  def init(state),
    do: {:ok, state}

  def handle_call(:show, _from, state) do
    {:reply, state, state}
  end

  def handle_cast({:save, list}, _state) do
    {:noreply, list}
  end

  def handle_cast(:clean, _state) do
    {:noreply, []}
  end
end
