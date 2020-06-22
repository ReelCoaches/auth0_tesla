defmodule Auth0Tesla.MiddlewareTest do
  use ExUnit.Case

  defmodule Auth0Client do
    use Tesla

    adapter(fn env ->
      case env.url do
        "/token-auth" ->
          {:ok, env}

        "/fail-auth" ->
          env = %{env | status: 401}
          {:ok, env}
      end
    end)

    def client(opts) do
      Tesla.client([
        {Auth0Tesla.Middleware, opts}
      ])
    end
  end

  setup do
    Tesla.Mock.mock(fn env ->
      assert env.url == "https://tenant.auth0.com/oauth/token"
      body = Jason.decode!(env.body)
      assert body["audience"] == "https://tenant.auth0.com/"
      assert body["client_id"] == "12345"
      assert body["client_secret"] == "some-secret"
      assert body["grant_type"] == "client_credentials"

      %Tesla.Env{
        status: 200,
        body: %{
          "access_token" => "XXXXXXX"
        }
      }
    end)

    :ok
  end

  test "adds access token to authorization header" do
    opts = [
      adapter: Tesla.Mock,
      base_url: "https://tenant.auth0.com",
      client_id: "12345",
      client_secret: "some-secret",
      audience: "https://tenant.auth0.com/",
      grant_type: "client_credentials"
    ]

    {:ok, request} = Auth0Client.client(opts) |> Auth0Client.get("/token-auth")
    auth_header = Tesla.get_header(request, "authorization")
    assert auth_header == "Bearer XXXXXXX"
    assert Auth0Tesla.TokenStore.get() == "XXXXXXX"

    {:ok, request} = Auth0Client.client(opts) |> Auth0Client.get("/fail-auth")
    auth_header = Tesla.get_header(request, "authorization")
    assert auth_header == "Bearer XXXXXXX"
    assert Auth0Tesla.TokenStore.get() == "XXXXXXX"
  end
end
