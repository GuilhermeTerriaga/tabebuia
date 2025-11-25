defmodule Tabebuia.Builder do
  @moduledoc """
  Pure functions for building TAR archive binary data.
  """

  @block_size 512
  @end_blocks <<0::size(1024)>>

  @doc """
  Build archive binary from a list of file entries (pure function).
  """
  @spec build_archive([{Tabebuia.Header.t(), binary()}]) :: binary()
  def build_archive(entries) do
    entries
    |> Enum.flat_map(&encode_entry/1)
    |> Enum.reduce(<<>>, &(&2 <> &1))
    |> append_end_blocks()
  end

  defp encode_entry({header, content}) do
    header_block = Tabebuia.Header.encode(header)
    content_blocks = pad_content(content, header.size)
    [header_block | content_blocks]
  end

  defp pad_content(content, size) when byte_size(content) == size do
    blocks_needed = ceil(size / @block_size)
    total_bytes_needed = blocks_needed * @block_size
    padding_size = total_bytes_needed - size

    if padding_size > 0 do
      [content, <<0::size(padding_size * 8)>>]
    else
      [content]
    end
  end

  defp append_end_blocks(archive) do
    archive <> @end_blocks
  end
end
