defmodule Tabebuia.Extractor do
  @moduledoc """
  Handles extraction of TAR archives to filesystem.
  """
  
  @spec extract_entries([{Tabebuia.Header.t(), binary()}], Path.t()) :: 
        {:ok, [String.t()]} | {:error, {String.t(), atom()}}
  def extract_entries(entries, dest_path) do
    File.mkdir_p!(dest_path)
    
    entries
    |> Enum.reduce_while([], fn {header, content}, extracted_files ->
      case extract_entry(header, content, dest_path) do
        {:ok, path} -> {:cont, [path | extracted_files]}
        {:error, reason} -> {:halt, {:error, {header.name, reason}}}
      end
    end)
    |> case do
      {:error, error} -> {:error, error}
      files -> {:ok, Enum.reverse(files)}
    end
  end

  defp extract_entry(header, content, dest_path) do
    full_name = Tabebuia.Header.full_name(header)
    target_path = Path.join(dest_path, full_name)
    
    target_path
    |> Path.dirname()
    |> File.mkdir_p!()
    
    case header.typeflag do
      "0" -> extract_file(target_path, content, header.mode)
      
      "5" -> extract_directory(target_path, header.mode)
      
      "2" -> {:ok, target_path} # ainda não implementei
      
      _ -> 
        IO.puts("Skipping unsupported file type: #{header.typeflag} for #{full_name}")
        {:ok, target_path}
    end
  end

  defp extract_file(path, content, mode) do
    case File.write(path, content) do
      :ok ->
        File.chmod!(path, mode)
        {:ok, path}
        
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp extract_directory(path, mode) do
    case File.mkdir(path) do
      :ok ->
        File.chmod!(path, mode)
        {:ok, path}
        
      {:error, :eexist} ->
        {:ok, path}
        
      {:error, reason} ->
        {:error, reason}
    end
  end
end
