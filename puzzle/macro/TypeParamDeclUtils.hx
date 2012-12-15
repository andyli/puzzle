package puzzle.macro;

import haxe.macro.Expr;
using Lambda;
using puzzle.macro.ComplexTypeUtils;
using puzzle.macro.ExprUtils;
using puzzle.macro.TypeParamUtils;

class TypeParamDeclUtils {
	static public function clone(tpd:Null<TypeParamDecl>, ?deep:Bool = true):Null<TypeParamDecl> {
		return tpd == null ? null : { 
			name: tpd.name, 
			constraints: deep ? tpd.constraints == null ? null : tpd.constraints.map(function(c) return c.clone(deep)).array() : tpd.constraints,
			params: deep ? tpd.params == null ? null : tpd.params.map(function(tpd) return clone(tpd, deep)).array() : tpd.params
		};
	}
	
	static public function getExprs(tpd:Null<TypeParamDecl>, ?inComplexType = false):Array<Null<Expr>> {
		return if (inComplexType)
			tpd.constraints.fold(function(c, a:Array<Null<Expr>>) return a.concat(c.getExprs(inComplexType)), [])
				.concat(tpd.params.fold(function(p, a:Array<Null<Expr>>) return a.concat(getExprs(p, inComplexType)), []));
		else
			[];
	}
}