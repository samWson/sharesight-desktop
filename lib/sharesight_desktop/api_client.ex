defmodule SharesightDesktop.ApiClient do
  import Logger, only: [info: 2, warning: 2]

  use HTTPoison.Base

  @impl true
  def start() do
    HTTPoison.start()
  end

  @impl true
  def get(url, access_token) do
    headers = [
      {:content_type, "application/json"},
      {:authorization, "Bearer #{access_token}"}
    ]

    Logger.info("Sending GET to #{url}")
    {:ok, response} = HTTPoison.get(url, headers)

    Logger.info("Recieved response status #{response.status_code}")
    response
  end

  def body(%HTTPoison.Response{body: body}) do
    body
  end

  def get_access_token!() do
    client_uid = fetch_client_variable("CLIENT_UID")
    client_secret = fetch_client_variable("CLIENT_SECRET")

    # TODO: These three urls should be configurable.
    domain = "https://api.sharesight.com"
    authorize_path = "/oauth2/authorize"
    token_path = "/oauth2/token"

    # BUG: client_id and client_secret can be leaked in plain text in error
    # messages and stack traces.
    oauth_client = OAuth2.Client.new([
        strategy: OAuth2.Strategy.ClientCredentials,
        client_id: client_uid,
        client_secret: client_secret,
        site: domain,
        authorize_url: authorize_path,
        token_url: token_path
      ])

    case OAuth2.Client.get_token(oauth_client) do
      {:ok, client_with_token} ->
        token = client_with_token.token.access_token
        |> Jason.decode!()
        |> Map.get("access_token")

        {:ok, token}
      {:error, %OAuth2.Response{body: body}} ->
        {:error, "Bad response: #{IO.inspect(body)}"}
      {:error, %OAuth2.Error{reason: reason}} ->
        {:error, "Error: #{reason}"}
    end
  end

  defp fetch_client_variable(name) do
    case System.fetch_env(name) do
      {:ok, variable} ->
        variable
      :error ->
        Logger.warning("#{name} not fetched from environment")
        ""
    end
  end
end
