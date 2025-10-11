defmodule Nhf1 do
  @moduledoc """
  Számtekercs
  @author "Gaál Botond <kisgal98@gmail.com>"
  @date   "2025-10-11"
  ...
  """
  @type size()  :: integer() # tábla mérete (0 < n)
  @type cycle() :: integer() # ciklus hossza (0 < m <= n)
  @type value() :: integer() # mező értéke (0 < v <= m)

  @type row()   :: integer()       # sor száma (1-től n-ig)
  @type col()   :: integer()       # oszlop száma (1-től n-ig)
  @type field() :: {row(), col()}  # mező koordinátái

  @type field_value() :: {field(), value()}                 # mező és értéke
  @type puzzle_desc() :: {size(), cycle(), [field_value()]} # feladvány

  @type retval()    :: integer()    # eredménymező értéke (0 <= rv <= m)
  @type solution()  :: [[retval()]] # egy megoldás
  @type solutions() :: [solution()] # összes megoldás

  @spec helix(
    sd::puzzle_desc() # tuple, amiben n, m, és a "constraint"-ek listája
    ) :: ss::solutions() # lehetséges megoldások, mind egy-egy list[list[int]]
  # ss az sd feladványleíróval megadott feladvány összes megoldásának listája
  def helix({n, m, fixed}) when n > 0 and m > 0 and m <= n do
    coords = spiral_coords(n) # kigöngyölve a koordináták
    len = n * n  # a kigöngyölt számsorozat hossza
    nz_total = n * m # a nemnulla elemek száma: minden sorban m db elem
    z_total = len - nz_total # kizárásos alapon a nullák száma

    rc_to_ix =
      coords
      |> Enum.with_index(1) # 1-től felindexeljük
      # az {rc, ix} tuple-t szétszedi úgy, hogy {r,c} => ix lesz a lookup
      |> Map.new(fn {rc, ix} -> {rc, ix} end)

    # a {r, c} constrainteket a kitekert lista indexeihez rendeljük
    ix_constraint =
      for {{r, c}, v} <- fixed, into: %{} do
        { rc_to_ix[{r, c}], v }
      end

    row_used = for i <- 1..n, into: %{}, do: {i, MapSet.new()} # mely értékek használtak adott sorban
    col_used = for i <- 1..n, into: %{}, do: {i, MapSet.new()} # mely értékek használtak adott oszlopban
    row_filled = for i <- 1..n, into: %{}, do: {i, 0} # hány cella van kitöltve a sorban
    col_filled = for i <- 1..n, into: %{}, do: {i, 0} # hány cella van kitöltve az oszlopban

    # lefuttatjuk a megoldás keresést, melynek eredménye egy lista, melynek
    # minden eleme egy megoldás (a rekurzív hívásoknál részmegoldás is lehet,
    # de itt kívül csak teljes megoldások lesznek), mely {{r, c}, v} értékek
    # listája
    dfs(
      1, len, 0, z_total, m, coords, ix_constraint,
      row_used, col_used, row_filled, col_filled, n, nz_total, []
    )
    |> Enum.map(&pairs_to_grid(&1, n))
  end

  @spec dfs(
    i::integer(), # a spirál index, amiről döntést kell hozni
    len::integer(), # a megoldás elvárt hossza, n*n
    t::integer(), # az elhasznált nemnulla elemek száma
    zleft::integer(), # a még elhasználandó nullák száma
    m::cycle(), # milyen hosszúnak kell lenni a ciklusoknak
    coords::[field()], # a kigöngyölt koordináták listája
    ix_const::map(), # index=>constraint
    row_used::map(), # mely értékek használtak adott sorban
    col_used::map(), # mely értékek használtak adott oszlopban
    row_filled::map(), # hány cella van kitöltve a sorban
    col_filled::map(), # hány cella van kitöltve az oszlopban
    n::size(), # mátrix mérete
    nz_total::integer(), # nemnulla elemek száma összesen
    acc::list() # akkumulátor amibe építjük a részmegoldást
  ) :: [list()]
  # Mélységi keresés egy lépése, a keresés állapota a bemenete, a kimenete
  # pedig az adott állapotból kiinduló részfákon lévő megoldások listája.
  # A fában az elágazást az fogja jelenteni, hogy nullát vagy a következő
  # számot (1..m-ig) írjuk-e az i-edik indexre.
  defp dfs(i, len, t, zleft, _m, _coords, _ix_const,
           _row_used, _col_used, _row_filled, _col_filled, _n, nz_total, acc)
       when i > len do # i > len -> levél a keresési fában
    # pontosan annyi nemnulla elem van benne, amennyi kell ÉS
    # nem maradt már elhasználandó nulla elem
    # akkor ez egy helyes megoldás, az akkumulátor jelenlegi állása egy megoldás
    # itt nincs lentebb részfa, ezen a részfán a megoldások listája
    # ebből az egyetlen megoldásból áll
    if t == nz_total and zleft == 0, do: [acc], else: []
  end

  # általános eset, visszaadja a részfán lévő megoldások listáját
  defp dfs(i, len, t, zleft, m, coords, ix_const,
           row_used, col_used, row_filled, col_filled, n, nz_total, acc) do
    nz_left = nz_total - t # nz_left nemnullát kell még kiosztani
    # slots_left darab hely van hátra a mostani index kiosztása után
    slots_left = len - i + 1
    # ha több nulla vagy nemnulla van még hátra, mint hely, egyértelműen
    # nem keletkezhet jó megoldás
    if nz_left > slots_left or zleft > slots_left do
      []
    else
      {r, c} = Enum.at(coords, i - 1) # r, c a koordinátái az i-edik elemnek
      req = Map.get(ix_const, i) # az i-edik koordinátára requirement

      # take_val lesz azon részfákban található megoldások listája, ahol
      # az i-edik helyre egy nemnulla számot választunk
      take_val =
        with v <- next_val(t, m), # v a soron következő érték
          true <- nz_left > 0, # férnie kell még nem0 elemnek
          true <- (is_nil(req) or req == v), # kompatibilis v a constrainttel
          true <- not MapSet.member?(row_used[r], v), # nincs még a sorban
          true <- not MapSet.member?(col_used[c], v), # nincs még az oszlopban
          row_used1   = Map.update!(row_used,   r, &MapSet.put(&1, v)), # r sorban benne lesz v innentől
          col_used1   = Map.update!(col_used,   c, &MapSet.put(&1, v)), # c oszlopban benne lesz v innentől
          row_filled1 = Map.update!(row_filled, r, &(&1 + 1)), # r sorban +1 elem
          col_filled1 = Map.update!(col_filled, c, &(&1 + 1)), # c oszlopban +1 elem
          true <- feasible_line?(row_used1[r], row_filled1[r], n, m), # sorban elférnek 1...m
          true <- feasible_line?(col_used1[c], col_filled1[c], n, m) # oszlopban elférnek 1...m
        do
          dfs( # mélyül a rekurzió
            i + 1, len, t + 1, zleft, m, coords, ix_const,
            row_used1, col_used1, row_filled1, col_filled1, n, nz_total,
            [{{r, c}, v} | acc] # az akkumulátorba beletesszük az új elem bejegyzését -> v
          )
        else
          _ -> [] # ellenkező esetben nincs valid megoldás
        end

      # take_zero lesz azon részfákban található megoldások listája,
      # ahol az i-edik elemre nullát választunk
      take_zero =
        with true <- is_nil(req), # nincs kikötött nemnulla elem
          true <- zleft > 0, # van még lerakandó nullás elem
          true <- nz_left <= (slots_left - 1), # a nemnulla elemek is el fognak férni
          row_filled1 = Map.update!(row_filled, r, &(&1 + 1)), # r sorban +1 elem
          col_filled1 = Map.update!(col_filled, c, &(&1 + 1)), # c oszlopban +1 elem
          true <- feasible_line?(row_used[r], row_filled1[r], n, m), # sorban elférnek 1...m
          true <- feasible_line?(col_used[c], col_filled1[c], n, m) # oszlopban elférnek 1...m
        do
          dfs( # mélyül a rekurzió
            i + 1, len, t, zleft - 1, m, coords, ix_const,
            row_used, col_used, row_filled1, col_filled1, n, nz_total,
            [{{r, c}, 0} | acc] # az akkumulátorba beletesszük az új elem bejegyzését -> 0
          )
        else
          _ -> [] # ellenkező esetben nincs valid megoldás
        end
      take_val ++ take_zero
    end
  end

  @spec feasible_line?(
    used::MapSet.t(value()), # a már lerakott nem nulla elemek halmaza egy sorban/oszlopban
    filled::integer(), # a sorban/oszlopban (akár nullával) kitöltött elemek száma
    n::size(), # a sor/oszlop hossza
    m::cycle() # a nemnulla elemek sorozatának hossza
    ) :: boolean()
  # eldönti, hogy egy sorban/oszlopban még hátralévő üres helyeken elférnek-e
  # a lerakandó számok 1...m-ig
  defp feasible_line?(used, filled, n, m) do
    missing = m - MapSet.size(used) # 1..m tartományból még ennyi kell
    remaining = n - filled # ennyi hely van még
    missing <= remaining
  end

  @spec next_val(
    t::non_neg_integer(), # legutóbb használt nem0 számjegy
    m::cycle() # ciklus hossz
    ) :: value()
  # megadja, melyik elemet kell a spirálban legközelebb lerakni,
  # ha az előző lerakott nemnulla elem t volt
  defp next_val(t, m), do: rem(t, m) + 1

  @spec spiral_coords(
    n::size() # mekkora mátrixot kell kigöngyölni
    ) :: [field()]
  # n méretű "mátrixot" koordinátáit göngyöli ki egy listába, úgy, hogy a
  # spirál bejárás sorrendjében legyenek benne {r, c} tuplek
  defp spiral_coords(n) do
    dirs = [:right, :down, :left, :up] # körüljárási sorrend: jobbra, le, balra, fel
    # körüljárunk, eleinte üres akkumulátorral, az {1,0} mezőről
    # az {1, 0} mező kívül esik a mátrixon, az első lépés a valódi mátrixba belépés tulajdonképpen
    # a gyorsabb beszúrás érdekében fordított sorrendben építjük az akkumulátort,
    # ezért a végén kell egy reverse
    # a kiindulási állapot tehát az, hogy jobbra megyünk az első sorban, és minden
    # irányban n lépést tudunk megtenni
    walk([], {1, 0}, dirs, n, n) |> Enum.reverse() # reverse, a gyorsabb beszúráshoz
  end

  @spec walk(
    acc::[field()], # akkumulátor a farokrekurzióhoz
    pos::field(), # aktuális mező ahol járunk
    dirs::[:right | :down | :left | :up], # irányok listája, ahol a nulladik a jelenlegi irány
    ud::integer(), # fel-le irányban megtehető távolság
    lr::integer() # bal-jobb irányban megtehető távolság
    ) :: [field()]
  # egy lépés a ciklikus körbejárásban, visszaadja a spirál bejárásban
  # az érintett mezők {row, col} indexpárjainak fordított sorrendjét mint listát
  defp walk(acc, _pos, _dirs, ud, lr) when ud <= 0 or lr <= 0, do: acc # nincs hely mozogni
  defp walk(acc, pos, [dir | rest], ud, lr) do
    # a megtehető távolság eldöntése az irány függvényében
    d = if dir in [:up, :down], do: ud, else: lr
    # lépünk d darabszor a megfelelő irányba, acc1 a frissült akkumulátor,
    # pos1 pedig a legújabb pozíció
    {acc1, pos1} =
      Enum.reduce(1..d, {acc, pos}, fn _i, {acc2, {r, c}} ->
        {dr, dc} = # delta row, delta col, tehát merre lépünk
          case dir do # tulajdonképpen ezek az irányok definíciói
            :right -> {0, 1} # jobbra úgy megyünk, hogy az oszlop nő
            :down -> {1, 0} # le úgy megyünk, hogy a sor nő
            :left -> {0, -1} # balra úgy megyünk, hogy az oszlop csökken
            :up -> {-1, 0} # fel úgy megyünk, hogy a sor csökken
          end
        new = {r + dr, c + dc} # új pozíció
        {[new | acc2], new} # az új pozíció az eleje az új akkumulátornak (reverselve lesz)
      end)
    # attól függően, merre mentünk, frissül az abba az irányba megjárható távolság
    # ha fel/le mentünk akkor populáltunk egy bal/jobb szélső oszlopot, így a
    # balra-jobbra megtehető táv csökkent, és vice versa
    {ud1, lr1} = if dir in [:up, :down], do: {ud, lr - 1}, else: {ud - 1, lr}
    walk(acc1, pos1, rest ++ [dir], ud1, lr1) # farokrekurzió
  end

  @spec pairs_to_grid(
    pairs_rev::list(), # {{r, c}, v} értékek listája: a dfs kimenete
    n::size() # az építendő mátrix mérete
    ) :: solution()
  # az elvárt kimeneti formátumba rendezi a dfs kimenetét:
  # [{{r, c}, v}, ...] helyett [[v, v, ...], [v, v, ...], ...]
  defp pairs_to_grid(pairs_rev, n) do
    m = Enum.into(pairs_rev, %{}) # {r, c} => value
    for r <- 1..n do
      for c <- 1..n do
        Map.get(m, {r, c}, 0)
      end
    end
  end
end
