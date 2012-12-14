#if macro
import haxe.macro.Context;
#end
import puzzle.*;

interface A implements Puzzle {
	public var a(get_a, null):Int;
	public function new():Void {}
}

interface A_impl implements Puzzle {
	private function get_a():Int {
		return 123;
	}
}

class RealA implements A, implements A_impl {}

class Test extends haxe.unit.TestCase {
	@:macro static function typeOf(e) {
		return Context.makeExpr(Std.string(Context.typeof(e)), e.pos);
	}
	
	public function testSimple():Void {
		this.assertEquals(123, new RealA().a);
	}
	
	static public function main():Void {
		var runner = new haxe.unit.TestRunner();
		runner.add(new Test());
		runner.run();
	}
}