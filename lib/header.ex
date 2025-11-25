defmodule Tabebuia.Header do
  @moduledoc """
  Handles TAR header creation and encoding.
  """
  
  defstruct [
    name: "",
    mode: 0o644,
    uid: 0,
    gid: 0,
    size: 0,
    mtime: 0,
    typeflag: "0",
    linkname: "",
    magic: "ustar",
    version: "00",
    uname: "",
    gname: "",
    devmajor: 0,
    devminor: 0,
    prefix: ""
  ]

  @type t :: %__MODULE__{
    name: String.t(),
    mode: non_neg_integer(),
    uid: non_neg_integer(),
    gid: non_neg_integer(),
    size: non_neg_integer(),
    mtime: non_neg_integer(),
    typeflag: String.t(),
    linkname: String.t(),
    magic: String.t(),
    version: String.t(),
    uname: String.t(),
    gname: String.t(),
    devmajor: non_neg_integer(),
    devminor: non_neg_integer(),
    prefix: String.t()
  }
 #
  # @block_size 512
  # @header_size 500 

  @doc """
  Create a header for a file entry.
  """
  @spec for_file(String.t(), non_neg_integer(), non_neg_integer() | nil ) :: t
  def for_file(name, size, mtime \\ nil) do
    mtime = mtime || System.system_time(:second)
    
    %__MODULE__{
      name: name,
      size: size,
      mtime: mtime,
      typeflag: "0"
    }
  end

  @doc """
  Create a header for a directory entry.
  """
  @spec for_directory(String.t(), non_neg_integer()) :: t
  def for_directory(name, mtime \\ nil) do
    mtime = mtime || System.system_time(:second)
    
    %__MODULE__{
      name: ensure_trailing_slash(name),
      mode: 0o755,
      size: 0,
      mtime: mtime,
      typeflag: "5"
    }
  end

  @doc """
  Encode header to binary format (pure function).
  Returns a 512-byte block with header + padding.
  """
  @spec encode(t) :: binary()
  def encode(header) do
    # Convert header fields to tar format strings
    name = String.pad_trailing(header.name, 100, <<0>>)
    mode = format_octal(header.mode, 7) <> <<0>>
    uid = format_octal(header.uid, 7) <> <<0>>
    gid = format_octal(header.gid, 7) <> <<0>>
    size = format_octal(header.size, 11) <> <<0>>
    mtime = format_octal(header.mtime, 11) <> <<0>>
    typeflag = header.typeflag
    linkname = String.pad_trailing(header.linkname, 100, <<0>>)
    magic = String.pad_trailing(header.magic, 6, <<0>>)
    version = String.pad_trailing(header.version, 2, <<0>>)
    uname = String.pad_trailing(header.uname, 32, <<0>>)
    gname = String.pad_trailing(header.gname, 32, <<0>>)
    devmajor = format_octal(header.devmajor, 7) <> <<0>>
    devminor = format_octal(header.devminor, 7) <> <<0>>
    prefix = String.pad_trailing(header.prefix, 155, <<0>>)

    header_without_checksum = 
      name <> mode <> uid <> gid <> size <> mtime <> 
      "        " <> 
      typeflag <> linkname <> magic <> version <> uname <> gname <> 
      devmajor <> devminor <> prefix

    # Calculate checksum and create final header
    checksum = calculate_checksum(header_without_checksum)
    header_with_checksum = insert_checksum(header_without_checksum, checksum)
    
    # Add padding to make it a 512-byte block
    pad_to_block(header_with_checksum)
  end

  defp format_octal(value, length) do
    value
    |> Integer.to_string(8)
    |> String.pad_leading(length, "0")
  end

  defp calculate_checksum(header_binary) do
    header_binary
    |> :binary.bin_to_list()
    |> Enum.reduce(0, fn byte, sum -> sum + byte end)
  end

  defp insert_checksum(header_binary, checksum) do
    # Split the header: everything before checksum, checksum placeholder, everything after
    <<before_checksum::binary-size(148), _checksum_placeholder::binary-size(8), after_checksum::binary>> = header_binary
    
    # Format checksum as 6 octal digits + null + space
    checksum_str = 
      checksum
      |> Integer.to_string(8)
      |> String.pad_leading(6, "0")
      |> Kernel.<>(<<0>>)
      |> String.pad_trailing(8, " ")
    
    before_checksum <> checksum_str <> after_checksum
  end

  defp pad_to_block(header_binary) when byte_size(header_binary) == 500 do
    # Add 12 bytes of padding to make 512-byte block
    header_binary <> <<0::96>> 
  end

  defp ensure_trailing_slash(name) do
    if String.ends_with?(name, "/"), do: name, else: name <> "/"
  end
end
