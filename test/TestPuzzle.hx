#if macro
import haxe.macro.Context;
#end
import puzzle.*;
import puzzle.macro.ExprUtils;
import puzzle.macro.ComplexTypeUtils;

interface A extends Puzzle {
	public var a(get_a, null):Int;
	public function new():Void {}
}

interface A_impl extends Puzzle {
	private function get_a():Int {
		return 123;
	}
}

class RealA implements A implements A_impl {}

class RealA2 implements A implements A_impl {
	override private function get_a():Int {
		return 456;
	}
}

class TestPuzzle extends haxe.unit.TestCase {
	macro static function typeOf(e) {
		return Context.makeExpr(Std.string(Context.typeof(e)), e.pos);
	}
	
	public function testSimple():Void {
		this.assertEquals(123, new RealA().a);
	}
	
	public function testOverride():Void {
		this.assertEquals(456, new RealA2().a);
	}
	
	static public function main():Void {
		var runner = new haxe.unit.TestRunner();
		runner.add(new TestPuzzle());
		runner.run();
	}
}