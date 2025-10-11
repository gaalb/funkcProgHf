defmodule Split do
  @spec split(xs :: [any()], n :: integer()) :: {ps :: [any()], ss :: [any()]}
  # Az xs lista n hosszú prefixuma (első n eleme) ps, length(xs)-n
  # hosszú szuffixuma (első n eleme utáni része) pedig ss
  def split([h | t], 0), do: {[], [h | t]}
  def split([h | t], 1), do: {[h], t}
  def split([h | t], n) do
    {ps, ss} = split(t, n-1)
    {[h | ps], ss}
  end
end
IO.puts(Split.split([10, 20, 30, 40, 50], 3) === {[10, 20, 30], [40, 50]})
IO.puts(IO.inspect(Split.split(~c"egyedem-begyedem", 8)) === Enum.split(~c"egyedem-begyedem", 8))
IO.puts(IO.inspect(Split.split(~c"papás-mamás", 6)) === Enum.split(~c"papás-mamás", 6))
IO.puts(Split.split(~c"nem_vágom", 0) === Enum.split(~c"nem_vágom", 0))
IO.puts(Split.split(~c"", 10) === Enum.split(~c"", 10))
IO.puts(Split.split(~c"", 0) === Enum.split(~c"", 0))
