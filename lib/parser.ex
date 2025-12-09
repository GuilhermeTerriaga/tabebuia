defmodule Tabebuia.Parser do
@moduledoc """
  Functions for parsing TAR
""" 
  @block_size 512
  def parse_archive(archive_data) do
    parse_blocks(archive_data, 0, [])
  end

  defp parse_blocks(data, position, acc) do
    case :binary.part(data, position, min(@block_size, byte_size(data) - position)) do
      block when byte_size(block) < @block_size ->
        {:ok, Enum.reverse(acc)}
        
      block ->
        case Tabebuia.Header.decode(block) do
          {:ok, header} ->
            content_blocks = ceil(header.size / @block_size)
            content_size = content_blocks * @block_size
            content_start = position + @block_size
            <<content_data::binary-size(header.size), _padding::binary>> = 
              :binary.part(data, content_start, content_size)
            
            next_position = position + @block_size + content_size
            parse_blocks(data, next_position, [{header, content_data} | acc])
            
          {:end, _} ->
            next_position = position + @block_size
            if next_position + @block_size <= byte_size(data) do
              next_block = :binary.part(data, next_position, @block_size)
              case Tabebuia.Header.decode(next_block) do
                {:end, _} -> {:ok, Enum.reverse(acc)}
                _ -> parse_blocks(data, next_position, acc)
              end
            else
              {:ok, Enum.reverse(acc)}
            end
            
          {:error, reason} ->
            {:error, reason}
        end
    end
  rescue
    _e in ArgumentError -> {:error, :truncated_archive}
  end
end
