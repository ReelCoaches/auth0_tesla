# Tesla Auth0 Middleware

Used to add middleware to Tesla client that will fetch an access token from Auth0 and add it to the `Authorization` header of the request as a `Bearer` token.

Token is saved between requests until a request returns a `401` status code at which point a new token will be retrieved. 

Intended for use by Machine-to-Machine clients with a `client_credentials` grant type.

## Installation

Add `auth0_tesla` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:auth0_tesla, "https://github.com/ReelCoaches/auth0_tesla.git"}
  ]
end
```

## Example Usage

```elixir
defmodule MyClient do
  use Tesla

  # static configuration
  plug Auth0Tesla.Middleware, base_url: "https://my-auth0-tenant.auth0.com", client_id: "ABCD1234", client_secret: "some-secret", audience: "https://my-auth0-tenant.auth0.com/", grant_type: "client_credentials"

  # dynamic configuration
  def new(client_id, client_secret, audience, grant_type) do
    opts = [
      client_id: client_id,
      client_secret: client_secret,
      audience: audience,
      grant_type: grant_type
    ]

    Tesla.client [
      {Auth0Tesla.Middleware, opts}
    ]
  end
end
```

 ## Options
  - `:base_url` - URL of Auth0 API to request token for (defaults to `"https://api.auth0.com"`)
  - `:client_id` - Auth0 Client ID (defaults to `""`)
  - `:client_secret` - Auth0 Client Secret (defaults to `""`)
  - `:audience` - Audience identifier of Auth0 API to request token for (defaults to `""`)
  - `:grant_type` - Grant type (defaults to `"client_credentials"`)
  - `:adapter` - Tesla adapter that will be used to make the request to Auth0. Useful for setting adapter to `Tesla.Mock` when writing tests (defaults to `Tesla.Adapter.Httpc`)
