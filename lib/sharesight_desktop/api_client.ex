defmodule SharesightDesktop.ApiClient do
  use HTTPoison.Base

  @impl true
  def start() do
    HTTPoison.start()
  end

  @impl true
  def get!(url) do
    HTTPoison.get!(url)
  end

  def body(%HTTPoison.Response{body: body}) do
    body
  end
end