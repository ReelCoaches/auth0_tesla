defmodule Auth0Tesla.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {Auth0Tesla.TokenStore, []}
    ]

    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
