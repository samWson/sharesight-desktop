defmodule SharesightDesktop.ApiClientTest do
  use ExUnit.Case

  describe "body/1" do
    test "returns the body of a HTTP response" do
      response = %HTTPoison.Response{
        body: "response body",
        headers: [],
        request: %HTTPoison.Request{url: ""},
        request_url: "",
        status_code: 200
      }

      body = SharesightDesktop.ApiClient.body(response)

      assert body == "response body"
    end
  end
end
