defmodule Khf1 do

  @moduledoc """
  Hányféle módon állítható elő a célérték
  @author "Gaál Botond <kisgal98@gmail.com>"
  @date   "2025-09-22"
  """
  @type ertek() :: integer() # az összeg előállítására felhasználható érték (0 < ertek)
  @type darab() :: integer() # az értékből rendelkezésre álló maximális darabszám (0 ≤ darabszám)
  @type ertekek() :: %{ertek() => darab()}

  @spec hanyfele(
        ertekek :: ertekek(),   # érték→darab szótár (cap==0 → végtelen felhasználás)
        celertek :: integer()   # célösszeg
      ) :: ennyifele :: integer()
  # ennyifele a celertek összes különböző előállításainak száma ertekek felhasználásával
  def hanyfele(ertekek, celertek) do
    sorted = ertekek |> Enum.sort_by(fn{v, _} -> v end) # debugolás megkönnyítése végett
    dp_start = :array.new(size: celertek+1, fixed: true, default: 0)
    dp_start = :array.set(0, 1, dp_start)
    dp_end = for {value, cap} <- sorted, reduce: dp_start do # dp[s] megadja s hányféleképp adódik ki
      dp -> dp_after_v(dp, value, cap, celertek)
    end
    :array.get(celertek, dp_end)
  end

  @spec dp_after_v(
        dp    :: :array.array(),   # előző DP állapot (hossz: sum+1)
        value :: ertek(),          # aktuálisan figyelembe vett érték (>0)
        cap   :: darab(),          # maximális darabszám (0 → végtelen)
        sum   :: non_neg_integer() # felső korlát / cél tartomány vége
      ) :: :array.array()
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
  defp dp_after_v(dp, value, cap, sum) when cap > 0 and cap >= div(sum, value) do # irreálisan nagy cap-re egyszerűsítés
    dp_after_v(dp, value, 0, sum)
  end
  defp dp_after_v(dp, value, cap, sum) when cap > 0 do # cap-szor használható value
    # Adott value-t max cap-szor, vagy ahányszor elfér sum-ban, annyiszor használhatunk,
    # amelyik kisebb a kettőből (max_k). Ahányszor kirakható s-value, annyival növekedik s lehetséges
    # kirakásainak a száma, viszont s-value kirakásainak a száma megnövekedett s-2value-val,
    # és így tovább. Tehát ha max max_k-szor lehet használni value-t, akkor az új dp-re (dp_new)
    # igaz, hogy dp_new[s] = sum{k=0..max_k}(dp[s-k*value])
    # ennek a sum-nak a kiszámolása csúszóablakkal történik, mert itt lassult be nagyon a program
    # Ahelyett, hogy s-en végig iterálva mindig végigsummáznánk k-n, észrevesszük, hogy
    # az s-k*value értékek mod value egy maradékosztály. Ezt a maradékosztályt lehet egységesen
    # kezelni, és egy-egy lépésben feldolgozni, tehát azokat az indexeket frissítjük egy
    # lépésben amelyek ugyanaz a maradékosztály, nem egy s-t. Egy maradékosztályra pedig
    # s = r+t*value, r-en iterálunk a külső ciklusban. Legyen egy maradékosztály által
    # kijelölt dp értékek sorozata a, a t-edik elem a(t). Így dp_new[r+t*value]=sum{j=0..min(cap, t)}(a(t-j))
    dp_new = :array.new(size: sum + 1, fixed: true, default: 0)
    capw = cap + 1

    for r <- 0..(value - 1), reduce: dp_new do
      acc -> process_residue(dp, acc, value, capw, sum, r)
    end
  end

  @spec process_residue(
        dp     :: :array.array(),   # dp (előző állapot)
        dp_new :: :array.array(),   # dp_new (készülő új állapot)
        value  :: pos_integer(),    # érték (lépésköz a maradékosztályban)
        capw   :: pos_integer(),    # cap + 1 (ablak maximális elemszáma)
        sum    :: non_neg_integer(),# cél felső korlátja (indexhatár)
        r      :: non_neg_integer() # maradékosztály kezdő indexe (0..value-1)
      ) :: :array.array()
  # Egyetlen maradékosztály (r = s % value) feldolgozása csúszó ablakkal.
  # Olyan tömböt ad vissza, amelyben az adott maradékosztályba tartozó indexek alatt
  # lévő tagok frissítve lettek value számbavételével.
  # Ha a maradékosztály kezdő indexe (r) kívül esik a tartományon, nincs teendő
  defp process_residue(_dp, dp_new, _value, _capw, sum, r) when r > sum, do: dp_new

  # Érvényes r esetén tényleges feldolgozás
  defp process_residue(dp, dp_new, value, capw, sum, r) when r <= sum do
    steps = div(sum - r, value)
    {dp_new_fin, _qlen, _winsum} =
      for t <- 0..steps, reduce: {dp_new, 0, 0} do
        {acc, qlen, winsum} ->
          s = r + t * value

          # Új tag bekerül az ablakba
          term_new = :array.get(s, dp)
          qlen2    = qlen + 1
          winsum2  = winsum + term_new

          # Ha túlcsordulna az ablak, korrigáljuk (levonjuk a legrégebbit)
          {winsum3, qlen3} = adjust_window(dp, value, capw, s, qlen2, winsum2)

          # Az s-hez tartozó új dp_new érték az aktuális ablakösszeg
          { :array.set(s, winsum3, acc), qlen3, winsum3 }
      end

    dp_new_fin
  end

  @spec adjust_window(
          dp     :: :array.array(),   # dp tömb (forrás)
          value  :: pos_integer(),    # érték (lépésköz)
          capw   :: pos_integer(),    # cap + 1 (max ablakméret)
          s      :: non_neg_integer(),# aktuális index
          qlen   :: non_neg_integer(),# ablak jelenlegi elemszáma
          winsum :: non_neg_integer() # ablak jelenlegi összege
        ) :: {non_neg_integer(), non_neg_integer()}
  # A túl hosszú ablakot lecsökkenti, és mellé az összegét is megadja
  defp adjust_window(dp, value, capw, s, qlen, winsum) when qlen > capw do
    drop_idx = s - capw * value
    {winsum - :array.get(drop_idx, dp), qlen - 1}
  end
  defp adjust_window(_dp, _value, _capw, _s, qlen, winsum), do: {winsum, qlen}
end
