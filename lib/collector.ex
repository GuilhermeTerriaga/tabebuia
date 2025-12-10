defmodule Tabebuia.Collector do
  @moduledoc """
  Handles file system operations for collecting files and their contents.
  """

  @spec gather_files([String.t()]) :: {:ok, [{Tabebuia.Header.t(), binary()}]} | {:error, any()}
  def gather_files(paths) do
    paths
    |> Enum.reduce_while([], fn path, acc ->
      case gather_path(path, "") do
        {:ok, entries} -> {:cont, acc ++ entries}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:error, reason} -> {:error, reason}
      entries -> {:ok, List.flatten(entries)}
    end
  end

  defp gather_path(path, base_dir) do
    absolute_path = Path.expand(path)

    if File.exists?(absolute_path) do
      if File.dir?(absolute_path) do
        gather_directory(absolute_path, base_dir)
      else
        gather_file(absolute_path, base_dir)
      end
    else
      {:error, "Path does not exist: #{path}"}
    end
  end

  defp gather_directory(dir_path, base_dir) do
    relative_path = make_relative_path(dir_path, base_dir)

    dir_header = Tabebuia.Header.for_directory(relative_path)
    dir_entry = {dir_header, ""}

    case File.ls(dir_path) do
      {:ok, children} ->
        entries =
          Enum.reduce(children, [dir_entry], fn child, acc ->
            child_path = Path.join(dir_path, child)

            case gather_path(child_path, base_dir) do
              {:ok, child_entries} -> acc ++ child_entries
              {:error, _reason} -> acc
            end
          end)

        {:ok, entries}

      {:error, reason} ->
        {:error, "Cannot list directory #{dir_path}: #{inspect(reason)}"}
    end
  end

  defp gather_file(file_path, base_dir) do
    relative_path = make_relative_path(file_path, base_dir)

    case File.read(file_path) do
      {:ok, content} ->
        # TODO calculate the time using unix timestamp
        header = Tabebuia.Header.for_file(relative_path, byte_size(content))
        {:ok, [{header, content}]}

      {:error, reason} ->
        {:error, "Cannot read file #{file_path}: #{inspect(reason)}"}
    end
  end

  defp make_relative_path(path, base_dir) do
    if base_dir == "" do
      Path.basename(path)
    else
      Path.relative_to(path, base_dir)
    end
  end
end
