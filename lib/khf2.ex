defmodule Khf2 do

  @moduledoc """
  Számtekercs kiterítése
  @author "Gaál Botond <kisgal98@gmail.com>"
  @date   "2025-10-02"
  """

  # Alapadatok
  @type size()  :: integer() # tábla mérete (0 < n)
  @type cycle() :: integer() # ciklus hossza (0 < m <= n)
  @type value() :: integer() # mező értéke (0 < v <= m vagy "")

  # Mezőkoordináták
  @type row()   :: integer()       # sor száma (1-től n-ig)
  @type col()   :: integer()       # oszlop száma (1-től n-ig)
  @type field() :: {row(), col()}  # mező koordinátái

  # Feladványleírók
  @type field_value() :: {field(), value()}           # mező és értéke
  @type field_opt_value() :: {field(), value() | nil} # mező és opcionális értéke

  @type list_desc() :: [String.t()] # 1. elem: méret, 2. elem: ciklushossz,
                                    # többi elem esetleg: mezők és értékük

  @spec helix(ps::list_desc()) :: gs::[field_opt_value()]
  # A ps szöveges feladványleíró-lista szerinti számtekercs kiterített listája gs

  def helix(ps) do
    {n, _m, fixed_map} = parse_desc(ps)
    spiral_coords(n) |> Enum.map(fn rc -> {rc, Map.get(fixed_map, rc)} end)
  end

  @spec parse_desc(list_desc()) :: {size(), cycle(), map()}
  # n, m és az előre adott mezők (r,c)->v mapot csomagolja ki
  defp parse_desc([n_s, m_s | rest]) do
    n = parse_single_int(n_s)
    m = parse_single_int(m_s)

    fixed_map =
      for line <- rest,
          [r, c, v] <- [parse_ints(line)],
          into: %{},
          do: {{r, c}, v}

    {n, m, fixed_map}
  end

  @spec parse_single_int(String.t()) :: integer()
  # Egyetlen egész szám kiolvasása.
  defp parse_single_int(s) do
    s |> String.trim() |> String.to_integer()
  end

  @spec parse_ints(String.t()) :: [integer()]
  # Az összes egész szám kiemelése (legalább egy szóköz van köztük).
  defp parse_ints(s) do
    s |> String.split(~r/\s+/, trim: true) |> Enum.map(&String.to_integer/1)
  end

  @spec spiral_coords(size()) :: [field()]
  # n méretű "mmátrixot" göngyöl ki egy listába, úgy, hogy a spirál bejárás sorrendjében legyenek benne {r, c} tuplek
  defp spiral_coords(n) when n >= 1 do
    # indulás: pos = {1,0}, első irány :right, hosszak ud = n, lr = n
    dirs = [:right, :down, :left, :up]
    walk([], {1, 0}, dirs, n, n) |> Enum.reverse()
  end

  @spec walk([field()], field(), [:right | :down | :left | :up], integer(), integer()) :: [field()]
  # while ud > 0 and lr > 0: lépkedünk egy szakaszt, csökkentjük a megfelelő hosszt, irányt forgatunk
  defp walk(acc, _pos, _dirs, ud, lr) when ud <= 0 or lr <= 0, do: acc
  defp walk(acc, pos, [dir | rest], ud, lr) do
    d = if vertical?(dir), do: ud, else: lr

    {acc1, pos1} =
      Enum.reduce(1..d, {acc, pos}, fn _,
                                      {acc, {r, c}} ->
        {dr, dc} = delta(dir)
        new = {r + dr, c + dc}
        {[new | acc], new}
      end)

    {ud1, lr1} = if vertical?(dir), do: {ud, lr - 1}, else: {ud - 1, lr}
    walk(acc1, pos1, rest ++ [dir], ud1, lr1)
  end

  @spec delta(:right | :down | :left | :up) :: {integer(), integer()}
  # irányfüggően megadja, merre kell lépni
  defp delta(:right), do: {0, 1}
  defp delta(:down),  do: {1, 0}
  defp delta(:left),  do: {0, -1}
  defp delta(:up),    do: {-1, 0}

  @spec vertical?(:right | :down | :left | :up) :: boolean()
  # megadja, melyik irány vízszintes vs függőleges
  defp vertical?(:up), do: true
  defp vertical?(:down), do: true
  defp vertical?(_), do: false
end
