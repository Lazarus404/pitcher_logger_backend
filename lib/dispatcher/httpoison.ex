defmodule Logger.Backend.Pitcher.Dispatcher.HTTPoison do
  alias Logger.Backend.Pitcher.Dispatcher.Context, as: Ctx

  def init(method \\ :post, url \\ "", headers \\ [], opts \\ []) do
    %Ctx{
      method: method,
      url: url,
      header: headers,
      opts: opts
    }
  end

  def send(%Ctx{} = ctx, body) do
    ret = HTTPoison.request(ctx.method, ctx.url, body, ctx.headers, ctx.opts)

    case ret do
      {:ok, %HTTPoison.Response{status_code: status, body: body}}
      when is_nil(body) or (body == "" and (status >= 200 and status < 300)) ->
        :ok

      {:ok, %HTTPoison.Response{status_code: status, body: body}}
      when status >= 200 and status < 300 ->
        {:ok, body}

      _ ->
        :error
    end
  end
end
