defmodule BetterstackApiClientTest do
  use ExUnit.Case
  alias BetterstackApiClient
  alias BetterstackApiClient.TestUtils
  require Logger

  @port 4444
  @path BetterstackApiClient.api_path()

  @api_key "l3kh47jsakf2370dasg"
  @source_id "source2354551"

  setup do
    bypass = Bypass.open(port: @port)

    {:ok, bypass: bypass}
  end

  test "ApiClient sends a correct POST request with gzip in bert format", %{bypass: bypass} do
    Bypass.expect_once(bypass, "POST", @path, fn conn ->
      {:ok, body, conn} = Plug.Conn.read_body(conn)
      assert {"authorization", "Bearer #{@api_key}"} in conn.req_headers

      body = TestUtils.decode_logger_body(body)

      assert [
               %{
                 "context" => %{"system" => %{"file" => "not_existing.ex"}},
                 "level" => "info",
                 "message" => "Logger message"
               }
             ] = body

      Plug.Conn.resp(conn, 202, "")
    end)

    client = BetterstackApiClient.new(%{api_key: @api_key, url: "http://localhost:#{@port}"})

    batch = [
      %{
        "level" => "info",
        "message" => "Logger message",
        "context" => %{
          "system" => %{
            "file" => "not_existing.ex"
          }
        }
      }
    ]

    {status, _} = BetterstackApiClient.post_logs(client, batch, @source_id)
    assert :ok == status
  end
end
