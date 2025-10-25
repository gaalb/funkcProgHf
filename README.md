---
title: "Deklaratív Programozás NHF1 – Számtekercs"
stylesheet:
  - styles.css
body_class: md-just
pdf_options:
  format: A4
  printBackground: true
  margin:
    top: 10mm
    right: 10mm
    bottom: 10mm
    left: 10mm
---

# Deklaratív Programozás NHF1 (FP): Számtekercs

Szerző: Gaál Botond [CRQEYD]

## Feladatkiírás

Adott egy n\*n mezőből álló, négyzet alakú tábla, amelynek egyes mezőiben 1 és m közötti számok vannak. A feladat az, hogy további 1 és m közötti számokat helyezzünk el a táblában úgy, hogy az alábbi feltételek teljesüljenek:

1. Minden sorban és minden oszlopban az 1..m számok mindegyike pontosan egyszer szerepel.
2. A bal felső sarokból induló tekeredő vonal mentén a számok rendre az 1,2,...m,1,2,...,m,... sorrendben követik egymást.

A tekeredő vonalat a következőképpen definiáljuk. Először a négyzet első sorában haladunk balról jobbra, majd az utolsó oszlopban felülről lefelé. Ezután az utolsó sorban megyünk jobbról balra, majd az első oszlopban alulról fölfelé, egészen a 2. sor 1. mezőjéig. Miután így bejártuk a négyzetes tábla szélső sorait és oszlopait, rekurzívan folytatjuk a bejárást a 2. sor 2. mezőjében kezdődő (n-2)\*(n-2) mezőből álló négyzettel

A feladat annak a helix/1 Elixir függvénynek a megírása, mely egyetlen paramétere a feladványt írja le, visszatérési értéke pedig a feladvány összes megoldásának a listája, tetszőleges sorrendben. Ha egy feladványnak nincs megoldása, a visszatérési érték az üres lista. Egy-egy megoldás a kitöltött táblát írja egész számokból álló listák listájaként. Minden szám a tábla egy mezőjének értéket adja meg: ha 0, a mező üres, egyébként pedig az i értek, ahol 1<=i<=m.

Például ha a bemenet {6, 3, \[{{1,5},2},{{2,2},1},{{4,6},1}\]}, akkor a visszatérési érték [[[1,0,0,0,2,3],[0,1,2,3,0,0],[0,3,1,2,0,0],[0,2,3,0,0,1],[3,0,0,0,1,2],[2,0,0,1,3,0]]]

## Követelmények elemzése

A feladatot egy sudoku kitöltéséhez lehet hasonlítani: adottak a kitöltési szabályok (ezek részben hasonlítanak is a sudokuhoz), és peremfeltételek/kiindulási konfiguráció. A feladat pedig az üres mezők kitöltése az adott konfigurációból kiindulva, úgy, hogy a kitöltési szabályokat betartsuk. A sudokuhoz hasonlóan nekünk is egy négyzet alakú, tehát n\*n méretű pályánk van, amelybe számokat helyezhetünk el. A számok kétfélék lehetnek: 0, vagy pedig 1 és m közöttiek, ahol m szintén egy bemeneti paraméter. A nullát akárhányszor, akárhol használhatjuk, de a nemnulla számokra az alábbi követelmények vannak megfogalmazva:

- a sudokuhoz hasonlóan minden oszlopban és minden sorban egy számnak pontosan egyszer kell szerepelnie
- a tekeredő vonal ("spirálos") körbejárás során a számoknak egymást 1,2,...m,1,2,...m sorrendben kell követniük egymást

A spirálos körbejárást / tekeredő vonalat a feladatkiírás definiálja, és gyakorlatilag egy sorrendet rendel az n\*n-es mátrix (sor, oszlop) indexeihez.

A fenti megkötések következményei az alábbiak:

- mivel minden sorban 1..m szerepelnek a számok, az n\*n kitöltendő mezőből n\*m darab lesz nemnulla
- mivel n\*m darab nemnulla szám lesz, n\*n-n\*m darab nullát kell "kiosztanunk"

## Megoldási eljárás áttekintése

A megoldás lépései az alábbiak:

1. Az n\*n-es mátrix {row, col} koordinátáit kiterítjük a tekeredő vonal szabály szerint egy 1D reprezentációba: [{row, col}, {row, col}, ....]. Ebben a struktúrában oldjuk meg a feladványt, tehát rendelünk konkrét számértéket a {row, col} párosokhoz. A ráció emögött az, hogy ha mindig a listában előre haladva írjuk az elemeket, és mindig csak nullát, vagy pedig az 1,2,...m,1,2,...m sorozatban a soron következő elemet engedünk írni, akkor a spirálos körbejárással szemben támasztott követelményt implicit teljesítettük.
2. A feladat innentől a következő: végig haladni a kiterített {row, col} koordináta párok kigöngyölt listáján, és dönteni minden esetben, hogy nullát, vagy a soron következő nemnulla számot rendeljük hozzájuk, úgy hogy a beszúrt elem ne sértse a követelményeket.
3. Minden indexen tehát döntést hozunk: nulla, vagy nemnulla. Ezen döntések egy fát képeznek, és a döntési fa levelei konkrét n\*n mátrix kialakításokat jelentenek, melyek potenciális megoldásai a feladványnak. Ezen döntési fának a bejárása a feladatunk, úgy, hogy azon ágakat, amelyekről korán el lehet dönteni, hogy nem vezethetnek megoldáshoz, elhagyjuk/vágjuk.
4. A kész listákat visszarendezzük az elvárt kimeneti formátumba.

### Használt Elixir típusok

A megoldási eljárás és algoritmus kifejtése során szerepeltetni fogom a kapcsolódó Elixir kódot. Az alábbi típusokra lesz hivatkozás benne:

```Elixir
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
```

### Tekeredő vonal körüljárás

A spirál körüljárást biztosító függvény a `spiral_coords/1`, mely egyetlen bemenete a mátrix mérete, amelynek koordinátáit spirál körüljárás szerint kell kiteríteni 1D-be. A visszatérési értéke {row, col} tuple-ek listája.

```Elixir
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
```

A körüljárási sorrendet a dirs-ben definiáljuk: jobbra, le, balra, és felfele megyünk, mindig ebben a sorrendben. Az elv a következő: teszünk egy lépést a haladási irányba (a dirs lista első eleme a jelenlegi haladási irány), és a megfelelő indexet léptetjük felfele vagy lefele. Felírjuk a koordinátáit annak a mezőnek, amire ráléptünk. Ezt addig tesszük, amíg a haladási irányba megtehető lépéseket meg nem tettük: ehhez számon tartjuk a függőleges és vízszintes irányba megtehető lépések számát. Akkor végzünk a körbejárással, mikor egyik irányba sem tudunk már lépni. Mikor fordul az irány, az azt jelenti, hogy végiggyalogoltunk a mátrixon valamelyik irányba, tehát egy sor vagy oszlop megtelt, és csökkenteni kell a maximálisan bejárható távolságot a megfelelő irányban. Ezt a `walk/5` rekurzív függvény valósítja meg.

```Elixir
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
```

A `walk/5` farokrekurzív, és a gyorsabb appendálás végett fordított sorrendben építi az akkumulátorába az koordináta párok sorrendjét. Egy hívásban eldönti, melyik irányba kell haladni, hogy mekkora távolságot kell megtenni, majd ennyiszer lép. Ezután rekurzívan hívja a következő `walk/5`-öt, az új iránnyal, és a megfelelően csökkentett megtehető távolságokkal. A legelső hívásnál tehát a `walk/5`-öt az {1, 0} mezőről indítjuk, jobbra, úgy, hogy n mindkét irányban a megtehető távolság. Az {1, 0} nincs benne az 1-től indexelt mátrixban, a körüljárás első lépése az lesz, hogy belép az {1, 1} mezőre, és jobbra kezdődik a spirál. Ezzel előállt a tekeredő spirál körüljárása a koordinátáknak, amely valahogy így néz ki:
`[{1, 1}, {1, 2}, ...]`.

### Döntési fában megoldás keresés

A feladat az, hogy a megalkotott `[{1, 1}, {1, 2}, ...]` pozíciók mindegyikéhez rendeljünk hozzá egy számot: `[{{1, 1}, 1}, {{1, 2}, 2}, ...]`. Végig lépünk az összes elemen, és mindegyiknél eldöntjük, hogy arra a pozícióra nullát, vagy nem nullát (tehát a soron következő számot) írjuk. A soron következő szám ezzel a segédfüggvénnyel adódik:

```Elixir
@spec next_val(
  t::non_neg_integer(), # eddig használt nem0 számjegyegy száma
  m::cycle() # ciklus hossz
  ) :: value()
# megadja, melyik elemet kell a spirálban legközelebb lerakni,
# ha az előző lerakott nemnulla elem t volt
defp next_val(t, m), do: rem(t, m) + 1
```

Minden {row, col} értéknél dönthetünk kétféleképp, ez egy döntési fát ad, amelyet minél gyorsabban akarunk bejárni, eldobva azon részfákat amik nem tartalmazhatnak érvényes megoldást.
Ehhez az alábbi segédfüggvény használandó:

```Elixir
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
```

A `feasible_line?/4` azt ellenőrzi, hogy egy félig kitöltött sor vagy oszlop jelenlegi állapota inkompatibilissé teszi-e egy teljes megoldással: helytelen megoldáshoz vezetne ugyanis, ha kevesebb üres hely van még abban a sorban/oszlopban, mint ahány nemnulla számnak még el kell ott férnie. Ha például n=6, m=4 és egy sor: [0, 0, 0, 1, _, _] akkor nem férnek már el a fennálló két helyre a 2, 3, 4-es számjegyek, és a `feasible_line?/4` false-ot ad. Ez azt jelenti, hogy ha a döntési fa egy belső (nem levél) csomópontjában egy sor így néz ki, akkor az abból a csomópontból induló részfa levelei nem tartalmazhatnak megoldást, és nem szükséges tovább vizsgálni azt a részfát.

A döntési fában keresést a `dfs/14` függvény valósítja meg. Rekurzív, mindig a döntési fa egy csomópontjában hívjuk meg. A visszatérési értéke az azon csompontból kiinduló részfa megoldásainak listája. Mivel minden csomópontban kétféle döntés van, a megoldások listája: [megoldások ha nullát választunk] ++ [megoldások ha nem nullát választunk].
Mindkét eset egy-egy rekurzív hívást jelent egy új csomópontból, amely csomópont úgy adódik, hogy a kérdéses helyre a kiterített listában nullát, vagy nem nullát írunk. Ennek tényét úgy adjuk át a következő rekurzív hívásnak, hogy akkumulátorba építjük a megoldást.

A `dfs/14` fejléce, és rekurziójának kilépési feltétele:

```Elixir
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
```

Tehát akkor áll le a ha az összes elemről (row-col koordináta párról) döntést hoztunk. Elfogadható a megoldás ha ez egy olyan kialakítást eredményezett, amiben megfelelő mind a nullás, mind a nemnulla elemek száma. Olyan megoldás itt már nem tud létezni, ami a követelményeknek ellent mond, mert ezeket figyelembe véve járjuk be a döntési fát. A döntési fa azon csomópontjaiban, melyek nem levelek, az általánosab klóz hívódik meg:

```Elixir
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
```

Azon felül, hogy a fent taglalt működést valósítja meg, korai vágásokat is végez, tehát ha valamely feltétel alapján a csomópontban eldönthető, hogy nem vezet a részfája megoldáshoz, akkor üres listával tér vissza (nem tartalmaz megoldást). Működése:

1. Vág, ha több nullát kell még beilleszteni, mint ahány hely van még hátra.
2. A `take_val`-ba teszi azon részfa eredményeit, ami úgy keletkezik, hogy nem nullát választ következő elemnek
   1. A with blokk automatikusan vág, ha:
      - nincs már felhasználandó nemnulla elem
      - a soron következő szám ellentmondásban van az előre beírt számokkal
      - a soron következő szám már jelen van a sorban vagy oszlopban
      - a `feasible_line?/4` hibás konfigurációt jelez
   2. Egyéb esetben rekurzív hívás történik, melyben az új csomópont úgy keletkezik, hogy:
      - az akkumulátorba feljegyezzük az új csomópontot
      - i-t növeljük
      - az elhasznált nemnulla elemek számát növeljük
      - feljegyezzük a row_used, col_used, row_filled és col_filled-be a tényt, hogy az értéket elhasználtuk
3. A `take_zero`-ba teszi azon részfa eredményeit, ami úgy keletkezik, hogy nullát választ következő elemnek
   1. A with blokk automatikusan vág, ha:
      - a kérdéses pozícióba előre be volt írva egy szám
      - nincs már felhasználandó nullás
      - kevesebb kitöltendő hely van hátra, mint ahány nullát el kell még használni
      - a `feasible_line?/4` hibás konfigurációt jelez
   2. Egyéb esetben rekurzív hívás történik, melyben az új csomópont úgy keletkezik, hogy:
      - az akkumulátorba feljegyezzük az új csomópontot
      - i-t növeljük
      - az elhasználandó nullások számát csökkentjük
      - feljegyezzük a row_filled és col_filled-be a tényt, hogy feltöltöttünk egy helyet
4. A visszatérési érték a `take_zero` és `take_val` részfák eredményeinek uniója. A dfs név abból fakad, hogy mindig előbb a `take_val` rekurziós ágat járjuk be, így ez egy mélységi keresés (depth first search).

### Az eredmény megfelelő formátumra hozása

A keresés az eredményeket `[{{row, col}, value}, {{row, col}, value}, ...]` formában állítja elő, de a házi specifikáció szerint az elvárt formátum `[[v, v, ...], [v, v, ...], ...]`. Az összerendelés alapja, hogy a külső lista `row`-adik elemének (mely szintén egy lista) `col`-adik helyére azt a `value`-t kell írni, amelyiknél egyezett a `{row, col}` a megoldásban. Ezt a `pairs_to_grid/2` függvény valósítja meg:

```Elixir
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
```

### A keresés inicializálása, a helix/1 függvény

A megoldás teljességéhez már csak az kell, hogy inicializáljuk a keresést, és a felsorolt eljárásokat felhasználjuk:

```Elixir
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
```

Azt, hogy hogyan végzi el a feladatot a `helix/1` már taglaltuk: kiteríti a mátrixot koordináta párok 1D listájává, amin mélységi keresést futtat, melynek eredményei a helyes megoldásai a feladványnak. Ezeket az eredményeket pedig az elvárt formátumba rendezi. A keresés inicializálása:

- Az 1-es indexről indulunk (ez az {1, 1} koordináta pár)
- n\*n hosszúságú megoldásokat keresünk (eddig fut az index)
- kezdetben 0 darab nemnulla elemet használtunk el, tehát n\*m-et kell még elhasználni
- kezdetben 0 darab nullát használtunk el, tehát n\*n - n\*m-et kell még elhasználni
- kezdetben minden oszlopban és sorban 0 elem van jelen (és egy nemnulla szám sincs elhasználva)

## Tesztelési megfontolások, kipróbálási tapasztalatok

A nagyházi bizonyos elemei a korábbi házi feladatokból lettek átemelve, így ezen eljárások helyességét a megfelelő khf sikeressége bizonyította:

- A `spiral_coords/1` függvény változtatás nélkül átemelhető volt a khf2-ből
- A `dfs/14` függvény részben átemelhető volt a khf3-ból, ahol `len`hosszú listát kellett úgy összeállítani, hogy az `m` hosszú számsorozat `n`-szer legyen benne, és bizonyos helyeken már előre be vannak írva a számok. Az nhf1-ben `len=n*n`, ugyanis ekkora a spirál körüljárással kitekert mátrix mérete. Ezen felül újabb megkötés, hogy olyan nem nulla elemet szabad csak beilleszteni egy adott helyre, ami még nem szerepelt abban az oszlopban/sorban.

Tehát ezen eljárások helyessége (valamint azon eljárások helyessége, amiket felhasználnak) korábbi kisházi tapasztalatok alapján feltételezhető volt. Ezzel helyesnek tekinthetők az alábbi függvények:

- dfs
- next_val
- walk

Tesztelni kell még a `pairs_to_grid/2` és `feasible_line?/4` függvényeket:

- `pairs_to_grid/2` elvárt viselkedés: Az eredmény egy `n×n`-es lista-lista. A bemeneti `pairs_rev` listában szereplő `{{r,c}, v}` párok által meghatározott pozíciókba a megfelelő `v` kerül, a többi cella 0.

  - `n = 2`, `pairs_rev = [{{1, 2}, 5}, {{1, 1}, 0}]` -> `[[0, 5], [0, 0]]`
  - `n = 3`, `pairs_rev = [{{1, 1}, 1}, {{2, 3}, 2}, {{3, 2}, 3}]` -> `[[1, 0, 0], [0, 0, 2], [0, 3, 0]]`

- `feasible_line?/4` elvárt viselkedés: Igaz akkor és csak akkor, ha a `{1..m}` halmazból hiányzó értékek száma nem több, mint a sor/oszlop hátralévő férőhelye.
  - Minden megvan, sok hely maradt:  
    `used = MapSet.new([1, 2, 3])`, `filled = 2`, `n = 6`, `m = 3` -> `true`
  - Pont kitelik (határérték):  
    `used = MapSet.new([1])`, `filled = 4`, `n = 6`, `m = 3` -> `true`
  - Nem fér el:  
    `used = MapSet.new([1])`, `filled = 5`, `n = 6`, `m = 3` -> `false`
  - Semmi sincs meg, de kevés hely maradt:  
    `used = MapSet.new([])`, `filled = 3`, `n = 4`, `m = 3` -> `false`
  - Tele van a sor/oszlop, de hiányzik még érték:  
    `used = MapSet.new([1, 2])`, `filled = 6`, `n = 6`, `m = 3` -> `false`
  - Részben töltött, kényelmesen elfér:  
    `used = MapSet.new([2])`, `filled = 1`, `n = 5`, `m = 3` -> `true`

Ezen felül end-to-end rendszerteszteket biztosít a házi feladat kiírásban megtalálható nhf1_teszt.exs. Ezeket Benchee modullal futtattam. A környezet és futtatási paraméterek röviden:

- Windows, 12th Gen Intel i7-12700K, 31.8 GB RAM
- Erlang 27.3.4.3 (JIT: on), Elixir 1.18.4
- Benchee beállítás: `warmup: 1s`, `time: 3s`, `memory_time: 2s`, `parallel: 1`

### Benchee tapasztalatok

- test case 0: átlag 12.68 us, 20.65 KB memória
- test case 1: átlag 20.93 us, 31.44 KB memória
- test case 2: átlag 25.97 us, 30.78 KB memória
- test case 3: átlag 36.25 us, 62.37 KB memória
- test case 4: átlag 98.13 us, 154.32 KB memória
- test case 5: átlag 945.80 us, 1.33 MB memória
- test case 6: átlag 943.38 us, 1.33 MB memória
- test case 7: átlag 855.45 us, 1.25 MB memória
- test case 8: átlag 11.53 ms, 15.06 MB memória
- test case 9: átlag 50.43 ms, 73.73 MB memória
- test case 10: átlag 1s, 1.35 GB memória
- test case 11: átlag 141.66 ms, 193,37 MB memória

A futási idő és memóriahasználat drasztikusan nő a keresési térrel, ami összhangban van a mélységi keresés tulajdonságaival. Ez főleg a 10. tesztesetben figyelhető meg. Az összes kiadott tesztesetre helyes eredményt adott a függvény.
