defmodule Mix.Tasks.Tabebuia do
  use Mix.Task
  @shortdoc "Create and manipulate tar archives"

  @moduledoc """
  Tabebuia - Tar archive utility

  ## Create an archive
  mix tabebuia create archive.tar file1.txt file2.txt or directory

  ## List archive contents
  mix tabebuia list archive.tar

  ## Extract an archive
  mix tabebuia extract archive.tar [destination]
  """

  def run(args) do
    case parse_args(args) do
      {:create, archive_path, files} ->
        create_archive(archive_path, files)

      {:list, archive_path} ->
        list_archive(archive_path)

      {:extract, archive_path, dest_path} ->
        extract_archive(archive_path, dest_path)

      {:help} ->
        print_help()
    end
  end

  defp parse_args(["create", archive_path | files]) when length(files) > 0 do
    {:create, archive_path, files}
  end

  defp parse_args(["list", archive_path]) do
    {:list, archive_path}
  end

  defp parse_args(["extract", archive_path]) do
    {:extract, archive_path, "."}
  end

  defp parse_args(["extract", archive_path, dest_path]) do
    {:extract, archive_path, dest_path}
  end

  defp parse_args(_) do
    {:help}
  end

  defp create_archive(archive_path, files) do
    IO.puts("Creating archive: #{archive_path}")
    IO.puts("Including files: #{Enum.join(files, ", ")}")

    case Tabebuia.create(archive_path, files) do
      :ok ->
        size = File.stat!(archive_path).size
        IO.puts("Created #{archive_path} (#{size} bytes)")

      {:error, reason} ->
        IO.puts(:stderr, "Failed to create archive: #{inspect(reason)}")
        System.halt(1)
    end
  end

  defp list_archive(archive_path) do
    IO.puts("Listing contents of: #{archive_path}")

    case Tabebuia.list(archive_path) do
      {:ok, files} ->
        if files == [] do
          IO.puts("Archive is empty")
        else
          IO.puts("Archive contents (#{length(files)} files):")
          Enum.each(files, fn file -> IO.puts("  - #{file}") end)
        end

      {:error, reason} ->
        IO.puts(:stderr, "Failed to list archive: #{inspect(reason)}")
        System.halt(1)
    end
  end

  defp extract_archive(archive_path, dest_path) do
    IO.puts("Extracting #{archive_path} to #{dest_path}")

    case Tabebuia.extract(archive_path, dest_path) do
      {:ok, files} ->
        IO.puts("Extracted #{length(files)} files:")
        Enum.each(files, fn file -> IO.puts("  - #{file}") end)

      {:error, reason} ->
        IO.puts(:stderr, "Failed to extract archive: #{inspect(reason)}")
        System.halt(1)
    end
  end

  defp print_help() do
    IO.puts("""
    Tabebuia 💐

    Usage:
      mix tabebuia create ARCHIVE FILE1 [FILE2 ...]  # Create archive
      mix tabebuia list ARCHIVE                      # List archive contents  
      mix tabebuia extract ARCHIVE [DEST]            # Extract archive

    Examples:
      mix tabebuia create backup.tar file1.txt docs/
      mix tabebuia list backup.tar
      mix tabebuia extract backup.tar ./backup
    """)
  end
end
