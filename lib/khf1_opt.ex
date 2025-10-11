defmodule Khf1_opt do

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
  def hanyfele(ertekek, celertek) do
    has_infinite = Enum.any?(ertekek, fn {v, cap} -> v > 0 and cap == 0 end)
    bound = # a "szótár" "összege", egy korai sanity checkhhez
      for {value, cap} <- ertekek, reduce: 0 do
        acc -> acc + cap * value
      end
    hanyfele_sane(has_infinite, bound, ertekek, celertek)
  end

  @spec hanyfele_sane(boolean(), integer(), ertekek(), integer()) :: integer()
  # sanity check diszpécser függvény
  defp hanyfele_sane(false, bound, _ertekek, celertek) when bound < celertek, do: 0 # elbukik a sanity check
  defp hanyfele_sane(_, _bound, ertekek, celertek), do: do_dp(ertekek, celertek)

  @spec do_dp(ertekek(), integer()) :: integer()
  # ennyifele a celertek összes különböző előállításainak száma ertekek felhasználásával
  defp do_dp(ertekek, celertek) do
    sorted = ertekek |> Enum.sort_by(fn{v, _} -> v end) # debugolás megkönnyítése végett
    dp_start = :array.new(size: celertek+1, fixed: true, default: 0)
    dp_start = :array.set(0, 1, dp_start)
    dp_end = for {value, cap} <- sorted, reduce: dp_start do # dp[s] megadja s hányféleképp adódik ki
      dp -> dp_after_v(dp, value, cap, celertek)
    end
    :array.get(celertek, dp_end)
  end

  @spec dp_after_v(:array.array(), ertek(), darab(), non_neg_integer()) :: :array.array()
  # dp, sum hosszú tömb s-edik eleme megmondja, s-t hányféleképp tudtuk előállítani. Ez a függvény
  # megmondja, hogy ha mostmár value-t is használhatunk, maximum cap alkalommal, akkor hogyan
  # alakul dp tömb. cap=0 eset azt jelenti, bárhányszor használhatjuk.
  defp dp_after_v(dp, value, _cap, sum) when value > sum, do: dp # nem lehet összeg része
  defp dp_after_v(dp, value, 0, sum) do # 0-szor használható = végtelenszer használható
    # dp[s] += dp[s-value], mert ahányféleképp s-value megkapható, annyiszor megkapható s is
    # dp[s-value] viszont annyiszor kapható meg ahányszor s-2value, és így tovább
    # ez a for-reduce először dp[value]-t növeli meg eggyel (mert dp[0]=1), aztán
    # ezt a növekményt figyelembe véve kaszkádozik tovább
    for s <- value..sum, reduce: dp do
      acc -> :array.set(s, :array.get(s, acc) + :array.get(s-value, acc), acc)
    end
  end
  defp dp_after_v(dp, value, cap, sum) when cap > 0 and cap >= div(sum, value) do
  dp_after_v(dp, value, 0, sum)
end

defp dp_after_v(dp, value, cap, sum) when cap > 0 do
  dp_new = :array.new(size: sum + 1, fixed: true, default: 0)
  capw = cap + 1

  # process each residue class r = 0..value-1
  for r <- 0..(value - 1), reduce: dp_new do
    acc -> process_residue(dp, acc, value, capw, sum, r, 0, 0)
  end
end

# Walk s = r, r+value, r+2*value, ... keeping a window of size capw
@spec process_residue(:array.array(), :array.array(), pos_integer(), pos_integer(), non_neg_integer(), non_neg_integer(), non_neg_integer(), non_neg_integer()) ::
        :array.array()
defp process_residue(_dp, acc, _value, _capw, sum, s, _qlen, _winsum) when s > sum, do: acc
defp process_residue(dp, acc, value, capw, sum, s, qlen, winsum) do
  term_new = :array.get(s, dp)
  qlen2 = qlen + 1
  winsum2 = winsum + term_new

  {winsum3, qlen3} = adjust_window(dp, value, capw, s, qlen2, winsum2)
  acc2 = :array.set(s, winsum3, acc)
  process_residue(dp, acc2, value, capw, sum, s + value, qlen3, winsum3)
end

# Drop the oldest term once the window exceeds capw
@spec adjust_window(:array.array(), pos_integer(), pos_integer(), non_neg_integer(), non_neg_integer(), non_neg_integer()) ::
        {non_neg_integer(), non_neg_integer()}
defp adjust_window(dp, value, capw, s, qlen, winsum) when qlen > capw do
  drop_idx = s - capw * value
  {winsum - :array.get(drop_idx, dp), qlen - 1}
end
defp adjust_window(_dp, _value, _capw, _s, qlen, winsum), do: {winsum, qlen}

end
