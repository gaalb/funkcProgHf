defmodule Khf3 do

  @moduledoc """
  Ciklikus számlisták
  @author "Gaál Botond <kisgal98@gmail.com>"
  @date   "2025-10-03"
  """
  @type count() :: integer() # számsorozatok száma, n (1 < n)
  @type cycle() :: integer() # számsorozat hossza, m (1 <= m)
  @type size()  :: integer() # listahossz, len (1 < len)
  @type value() :: integer() # listaelem értéke, val (0 <= val <= m)
  @type index() :: integer() # listaelem sorszáma, ix (1 <= ix <= len)
  @type index_value() :: {index(), value()} # listaelem indexe és értéke

  @spec cyclists(
    {n::count(), # n darab sorozat
    m::cycle(), # m hosszú egy sorozat
    len::size()}, # len hosszú a lista -> n*m pozitív szám, többi 0
    constraints::[index_value()]) # constraints tuplek listája, benne első elem egy index, második egy érték kényszer
    :: results::[[value()]]
  # results az összes olyan len hosszú lista listája, melyekben
  # * az 1-től m-ig tartó számsorozat – ebben a sorrendben, esetleg
  #   közbeszúrt 0-kal – n-szer ismétlődik,
  # * len-n*m számú helyen 0-k vannak,
  # * a constraints korlát-listában felsorolt indexű cellákban a megadott
  #   értékű elemek vannak.
  def cyclists({n, m, len}, constraints) do
    total_vals = n * m # total_vals az összes nem0 érték
    zeros = len - total_vals
    cmap = Map.new(constraints) # {ix,val} -> map (utolsó nyer, ha duplikált)

    # indulás: i=1 (1-alapú indexelés a feladat szerint), t=0 (eddig kiírt nem-0 darab)
    dfs(1, len, _t = 0, total_vals, zeros, m, cmap, []) |> Enum.sort()  # rekurzív mélységi keresés
  end

  @spec dfs(
    i::index(), # i-edik indexről hozunk döntést
    len::size(), # len hosszú listák a megoldások
    t::non_neg_integer(), # már elhasznált nem nulla helyek száma
    total::non_neg_integer(), # n*m, tehát az elhasználandó nem nulla helyek száma
    zleft::non_neg_integer(), # ennyi nullát kell még használni
    m::cycle(), # ilyen hosszúak a sorozatok (1, 2,..., m)
    cmap::map(), # constraint-ek
    acc_rev::[value()]) # akkumulátor, fordított sorrendben, hogy O(1) legyen a hozzáfűzés
    :: [[value()]]
  # Backtracking: pozíciónként döntünk 0 vagy "következő érték" között, korlátokkal, pruneléssel.
  defp dfs(i, len, t, total, zleft, _m, _cmap, acc_rev) when i > len do  # i>len -> levél a keresési fában
    # csak akkor fogadjuk el, ha minden kötelező elem és 0 elfogyott
    if t == total and zleft == 0, do: [Enum.reverse(acc_rev)], else: [] # üres lista -> prune-olt ág
  end

  defp dfs(i, len, t, total, zleft, m, cmap, acc_rev) do
    req = Map.get(cmap, i, :any)
    vals_left = total - t
    slots_left = len - i + 1

    # ha akár a köv. lépés előtt is nyilvánvalóan lehetetlen a hátralévő mennyiség, vágjunk
    cond do
      vals_left > slots_left -> []
      zleft > slots_left -> []
      true ->
        step(i, len, t, total, zleft, m, cmap, acc_rev, req)
    end
  end

  @spec step(
    i::index(), # i-edik indexről induló részfát építjük
    len::size(),  # len hosszú listák a megoldások
    t::non_neg_integer(), # már elhasznált nem nulla helyek száma
    total::non_neg_integer(), # n*m, tehát az elhasználandó nem nulla helyek száma
    zleft::non_neg_integer(), # ennyi nullát kell még használni
    m::cycle(), # ilyen hosszúak a sorozatok (1, 2,..., m)
    cmap::map(), # constraint-ek
    acc_rev::[value()], # akkumulátor, fordított sorrendben, hogy O(1) legyen a hozzáfűzés
    v::value() | :any) # kényszer az i-edik értékre
    :: [[value()]]
  # Egy pozíció eldöntése a req (korlát) alapján.
  defp step(i, len, t, total, zleft, m, cmap, acc_rev, 0) do # kövi érték 0 constraint klóz
    # csak 0 mehet ide
    vals_left = total - t # ennyi darab nemnullát kell még kipakolni
    # ha kevesebb vagy egyenlő hely van, mint szükséges nem nulla érték, és van még
    # kipakolandó 0, akkor ez egy valid konstrukció lehet, és tovább kell iterálni
    if zleft > 0 and vals_left <= (len - i) do
      dfs(i + 1, len, t, total, zleft - 1, m, cmap, [0 | acc_rev]) # pozíció++, zleft--
    else
      [] # egyéb esetben prune
    end
  end

  defp step(i, len, t, total, zleft, m, cmap, acc_rev, v) when is_integer(v) and v > 0 do # az a klóz, mikor nem 0 constraintre futottunk
    # csak a soron következő érték mehet ide, és annak egyeznie kell req-vel
    next = next_val(t, m)
    cond do
      (total - t) == 0 -> [] # elhasználtuk az összes nemnullát -> prune
      zleft <= (len - i) and v == next -> # jó a v elem, nincs túl sok beszúrandó 0 -> valid setup lehet
        dfs(i + 1, len, t + 1, total, zleft, m, cmap, [next | acc_rev]) # pozíció++, értékek++
      true -> []
    end
  end

  defp step(i, len, t, total, zleft, m, cmap, acc_rev, :any) do # az a klóz, mikor nincs constraint
    next = next_val(t, m)

    # próbáljuk a soron következő nemnulla értéket
    take_val = # van még nemnulla elhasználandó és nincs túl sok beszúrandó 0
      if (total - t) > 0 and zleft <= (len - i) do
        dfs(i + 1, len, t + 1, total, zleft, m, cmap, [next | acc_rev]) # index++, értékek++
      else
        []
      end

    # 2) próbáljuk a 0-t
    take_zero =
      if zleft > 0 and (total - t) <= (len - i) do # van még beszúrandó 0 és elférnek a nem nulla elemek
        dfs(i + 1, len, t, total, zleft - 1, m, cmap, [0 | acc_rev]) # index++, nullák--
      else
        []
      end

    take_val ++ take_zero
  end

  @spec next_val(
    t::non_neg_integer(), # ennyi nem nulla számot használtunk
    m::cycle()) # ilyen hosszúk a sorozatok
    :: value()
  # A soron következő (nem 0) érték: 1..m ismétlődve, t már kiírt darab.
  defp next_val(t, m), do: rem(t, m) + 1
end
