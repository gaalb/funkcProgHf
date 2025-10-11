alias Khf1

defmodule Check do
  def assert_equal(actual, expected, label) do
    if actual == expected do
      IO.puts("✓ #{label}: OK (#{actual})")
    else
      IO.puts("✗ #{label}: expected #{expected}, got #{actual}")
      System.halt(1)
    end
  end
end

# --- Bounded-only cases ---
Check.assert_equal(
  Khf1.hanyfele(%{1 => 2, 2 => 3, 3 => 4}, 4),
  3,
  "case 1"
)

Check.assert_equal(
  Khf1.hanyfele(%{2 => 2, 1 => 1, 3 => 3}, 4),
  2,
  "case 2"
)

Check.assert_equal(
  Khf1.hanyfele(%{3 => 3, 2 => 1, 1 => 1}, 5),
  1,
  "case 4"
)

# --- Unbounded cases (0 ⇒ unlimited). Comment out if not supported yet. ---
Check.assert_equal(
  Khf1.hanyfele(%{3 => 1, 1 => 0, 2 => 0}, 4),
  4,
  "case 3 (unbounded present)"
)

Check.assert_equal(
  Khf1.hanyfele(%{1 => 0, 2 => 0, 3 => 0}, 20),
  44,
  "case 5 (all unbounded)"
)

Check.assert_equal(
  Khf1.hanyfele(%{2 => 0, 3 => 0, 1 => 0}, 3000),
  751_501,
  "case 6 (all unbounded, big)"
)

Check.assert_equal(
  Khf1.hanyfele(%{1 => 50, 3 => 0, 2 => 0}, 3000),
  25_309,
  "case 7 (mixed bounded+unbounded)"
)

Check.assert_equal(
  Khf1.hanyfele(%{3 => 0, 1 => 100, 2 => 0}, 499_000),
  8_399_034,
  "case 8 (big, unbounded present)"
)

IO.puts("🎉 All tests passed.")
