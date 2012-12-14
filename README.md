# Puzzle

A tiny macro-based framework to compose class from puzzles.

## Learn by example

Puzzles are interfaces that directly implement `puzzle.Puzzle`:

```
interface A implements puzzle.Puzzle {
	public var a(get_a, null):Int;
	public function new():Void {}
}

interface A_impl implements puzzle.Puzzle {
	private function get_a():Int {
		return 123;
	}
}
```

The puzzle macros will store all the member definitions (`haxe.macro.Field`), remove all the unnecessary things (function bodies, contructor etc), infer the types if needed, making them normal valid Haxe interfaces.

Notice that `A` contains a contructor, which is forbidden in interface in Haxe, will actually be removed.

Here we come to put the two pieces together:

```
class RealA implements A, implements A_impl {}
```

`RealA` now contains all the members of `A` and `A_impl`, including the constructor from `A`.