import puzzle.macro.*;
import haxe.macro.Expr;

class TestMacroExprUtils extends haxe.unit.TestCase {	
	public function test_getExprs():Void {
		var exprs = ExprUtils.getExprs(null);
		this.assertEquals(0, exprs.length);
		
		var e = macro true;
		var exprs = ExprUtils.getExprs(e);
		this.assertEquals(0, exprs.length);
		
		var e = macro (true);
		var exprs = ExprUtils.getExprs(e);
		this.assertEquals(1, exprs.length);
		
		var e = macro new Test<123>(test);
		var exprs = ExprUtils.getExprs(e, false);
		this.assertEquals(1, exprs.length);
		
		var e = macro new Test<123>(test);
		var exprs = ExprUtils.getExprs(e, true);
		this.assertEquals(2, exprs.length);
	}
	
	public function test_clone():Void {
		var e = ExprUtils.clone(null);
		this.assertEquals(null, e);
		
		var e = macro true;
		var ec = ExprUtils.clone(e);
		this.assertTrue(Type.enumEq(e.expr, ec.expr));
		this.assertTrue(e.expr != ec.expr);
		
		var e = macro (true);
		var ec = ExprUtils.clone(e, false);
		this.assertTrue(Type.enumEq(e.expr, ec.expr));
		this.assertTrue(e.expr != ec.expr);
		
		var e = macro (true);
		var ec = ExprUtils.clone(e, true);
		this.assertEquals(Type.enumConstructor(e.expr), Type.enumConstructor(ec.expr));
		this.assertTrue(e.expr != ec.expr);
	}
}