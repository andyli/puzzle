import puzzle.macro.*;
import haxe.macro.Expr;

class TestMacroComplexTypeUtils extends haxe.unit.TestCase {	
	public function test_getExprs():Void {
		var exprs = ComplexTypeUtils.getExprs(null);
		this.assertEquals(0, exprs.length);
		
		var t = macro : Test<Dynamic>;
		var exprs = ComplexTypeUtils.getExprs(t);
		this.assertEquals(0, exprs.length);
		
		var t = macro : Test<123>;
		var exprs = ComplexTypeUtils.getExprs(t, true);
		this.assertEquals(1, exprs.length);
		
		var t = macro : Test<123>;
		var exprs = ComplexTypeUtils.getExprs(t, false);
		this.assertEquals(1, exprs.length);
		
		var t = macro : Test<123> -> Test<123>;
		var exprs = ComplexTypeUtils.getExprs(t, true);
		this.assertEquals(2, exprs.length);
		
		var t = macro : Test<123> -> Test<123>;
		var exprs = ComplexTypeUtils.getExprs(t, false);
		this.assertEquals(0, exprs.length);
		
		var t = macro : Test<Test<123, Test<123, 456>>>;
		var exprs = ComplexTypeUtils.getExprs(t, true);
		this.assertEquals(3, exprs.length);
		
		var t = macro : Test<Test<123, Test<123, 456>>>;
		var exprs = ComplexTypeUtils.getExprs(t, false);
		this.assertEquals(0, exprs.length);
		
		var t = macro : Test<123, Test<123, Test<123, 456>>>;
		var exprs = ComplexTypeUtils.getExprs(t, false);
		this.assertEquals(1, exprs.length);
	}
	
	public function test_clone():Void {
		var tc = ComplexTypeUtils.clone(null);
		this.assertEquals(null, tc);
		
		var d = macro : Dynamic;
		var t = macro : Test<$d>;
		var tc = ComplexTypeUtils.clone(t);
		this.assertTrue(t == t);
		this.assertTrue(tc == tc);
		this.assertTrue(t != tc);
		
		this.assertTrue(Type.enumEq(t, ComplexTypeUtils.clone(t, false)));
		
		function getD(t:ComplexType):ComplexType {
			return switch(t) {
				case TPath(p): switch(p.params[0]) {
					case TPType(t): t;
					default: throw "It should be a TPType.";
				};
				default: throw "It should be a TPath.";
			}
		}

		this.assertTrue(d == d);
		this.assertTrue(d == getD(t));
		
		this.assertTrue(d == d);
		this.assertTrue(d != getD(tc));
		
		this.assertEquals(Type.enumConstructor(getD(t)), Type.enumConstructor(getD(tc)));
	}
}