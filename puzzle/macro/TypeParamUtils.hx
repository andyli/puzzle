package puzzle.macro;

import haxe.macro.Expr;
using puzzle.macro.ComplexTypeUtils;
using puzzle.macro.ExprUtils;

class TypeParamUtils {
	static public function clone(tp:Null<TypeParam>, ?deep:Bool = true):Null<TypeParam> {
		return tp == null ? null : switch (tp) {
			case TPType(t): deep ? TPType(t.clone(deep)) : TPType(t);
			case TPExpr(e): deep ? TPExpr(e.clone(deep)) : TPExpr(e);
		}
	}
}