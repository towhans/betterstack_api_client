defmodule BetterstackApiClient do
  @moduledoc false

  @default_api_path "/"

  @callback post_logs(Tesla.Client.t(), list(map), String.t()) ::
              {:ok, Tesla.Env.t()} | {:error, term}

  @spec new(%{url: String.t(), api_key: String.t()}) :: Tesla.Client.t()
  def new(%{url: url, api_key: api_key}) when is_binary(url) and is_binary(api_key) do
    middlewares = [
      Tesla.Middleware.FollowRedirects,
      {Tesla.Middleware.Headers,
       [
         {"authorization", "Bearer #{api_key}"}, # TODO refactor to source_id
         {"Content-Type", "application/msgpack"}
       ]},
      {Tesla.Middleware.BaseUrl, url}
    ]

    Tesla.client(
      middlewares,
      {Tesla.Adapter.Finch, name: BetterstackApiClient.Finch, receive_timeout: 30_000}
    )
  end

  @spec post_logs(Tesla.Client.t(), [map], String.t()) :: {:ok, Tesla.Env.t()} | {:error, term}
  def post_logs(%Tesla.Client{} = client, batch, _source_id) when is_list(batch) do # TODO remove source_id
    body = Msgpax.pack!(batch)

    Tesla.post(client, api_path(), body)
  end

  def api_path, do: @default_api_path
end
