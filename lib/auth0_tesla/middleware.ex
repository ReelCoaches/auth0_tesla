defmodule Auth0Tesla.Middleware do
  @behaviour Tesla.Middleware

  @middleware [
    Tesla.Middleware.JSON,
    Tesla.Middleware.Logger,
    Tesla.Middleware.Retry
  ]

  alias Auth0Tesla.TokenStore

  @adapter Tesla.Adapter.Httpc

  @spec call(Tesla.Env.t(), Tesla.Env.stack(), any) :: Tesla.Env.result()
  def call(env, next, opts) do
    with {:ok, env} <- put_access_token(env, opts),
         {:ok, %Tesla.Env{status: 401}} <- Tesla.run(env, next),
         {:ok, %Tesla.Env{} = env} <- refresh_access_token(env, opts) do
      Tesla.run(env, next)
    end
  end

  defp put_access_token(env, opts) do
    case TokenStore.get() do
      "" ->
        refresh_access_token(env, opts)

      token ->
        {:ok, %Tesla.Env{env | headers: env.headers ++ [{"authorization", "Bearer #{token}"}]}}
    end
  end

  defp refresh_access_token(env, opts) do
    base_url = Keyword.get(opts, :base_url, "https://api.auth0.com")
    adapter = Keyword.get(opts, :adapter, @adapter)

    client = new(base_url, adapter)

    body = %{
      client_id: Keyword.get(opts, :client_id, ""),
      client_secret: Keyword.get(opts, :client_secret, ""),
      audience: Keyword.get(opts, :audience, ""),
      grant_type: Keyword.get(opts, :grant_type, "client_credentials")
    }

    with {:ok, %{body: %{"access_token" => access_token}}} <-
           Tesla.post(client, "/oauth/token", body) do
      TokenStore.put(access_token)

      env = %Tesla.Env{
        env
        | headers: env.headers ++ [{"authorization", "Bearer #{access_token}"}]
      }

      {:ok, env}
    else
      _ ->
        {:error, env}
    end
  end

  defp new(base_url, adapter) do
    middleware =
      [
        {Tesla.Middleware.BaseUrl, base_url}
      ] ++ @middleware

    Tesla.client(middleware, adapter)
  end
end
