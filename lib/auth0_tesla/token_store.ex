defmodule Auth0Tesla.TokenStore do
  use Agent

  def start_link(_) do
    Agent.start_link(fn -> "" end, name: __MODULE__)
  end

  def get do
    Agent.get(__MODULE__, & &1)
  end

  def put(token) do
    Agent.update(__MODULE__, fn _ -> token end)
  end
end
