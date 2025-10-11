defmodule Khf1_rec do

  @moduledoc """
  Hányféle módon állítható elő a célérték
  @author "Gaál Botond <kisgal98@gmail.com>"
  @date   "2025-09-22"
  """
  @type ertek() :: integer() # az összeg előállítására felhasználható érték (0 < ertek)
  @type darab() :: integer() # az értékből rendelkezésre álló maximális darabszám (0 ≤ darabszám)
  @type ertekek() :: %{ertek() => darab()}

  @spec hanyfele(ertekek :: ertekek(), celertek :: integer()) :: ennyifele :: integer()
  # ennyifele a celertek összes különböző előállításainak száma ertekek felhasználásával
  def hanyfele(_ertekek, 0), do: 1

  def hanyfele(ertekek, celertek) do
    # any fixed order is OK; we sort for determinism (drop if you prefer)
    items =
      ertekek
      |> Enum.filter(fn {v, _cap} -> v > 0 and v <= celertek end)
      |> Enum.sort_by(fn {v, _} -> v end)

    # start from the last index ⇒ "use items 0..i"
    i0 = length(items) - 1
    {ans, _memo} = count(items, i0, celertek, %{})
    ans
  end

  # ----------------- helpers (backward version: recurse to i-1) ----------------

  # base: exact hit
  defp count(_items, _i, 0, memo), do: {1, memo}
  # base: no items left but still positive sum
  defp count(_items, i, s, memo) when i < 0 and s > 0, do: {0, memo}
  # base: overshoot
  defp count(_items, _i, s, memo) when s < 0, do: {0, memo}

  # memo hit: we’ve already computed (i, s)
  defp count(_items, i, s, memo) when is_map_key(memo, {i, s}), do: {memo[{i, s}], memo}


  # memo miss: decide how many copies of items[i] to take, then move to i-1
  defp count(items, i, s, memo) do
    {v, cap} = Enum.at(items, i)        # current (value, capacity)
    base_kmax = div(s, v)
    kmax = if cap == 0, do: base_kmax, else: min(base_kmax, cap) # max copies we can take

    # try all k = 0..kmax; after choosing k, only items 0..i-1 remain
    {sum, memo2} = sum_over_k(items, i, s, v, 0, kmax, 0, memo)

    # remember result for (i, s)
    {sum, Map.put(memo2, {i, s}, sum)}
  end

  # tail-recursive loop over k, threading the immutable memo forward
  defp sum_over_k(_items, _i, _s, _v, k, kmax, acc, memo) when k > kmax, do: {acc, memo}

  defp sum_over_k(items, i, s, v, k, kmax, acc, memo) do
    take_sum = s - k * v
    {ways_k, memo1} = count(items, i - 1, take_sum, memo)
    sum_over_k(items, i, s, v, k + 1, kmax, acc + ways_k, memo1)
  end

end
