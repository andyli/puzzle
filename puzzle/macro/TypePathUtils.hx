package puzzle.macro;

import haxe.macro.Expr;
using Lambda;
using puzzle.macro.ComplexTypeUtils;
using puzzle.macro.ExprUtils;
using puzzle.macro.TypeParamUtils;

class TypePathUtils {
	static public function clone(p:Null<TypePath>, ?deep:Bool = true):Null<TypePath> {
		return p == null ? null : deep ? {
			pack: p.pack.copy(),
			name: p.name,
			params: p.params.map(function(param) return param.clone(deep)).array(),
			sub: p.sub
		} : {
			pack: p.pack,
			name: p.name,
			params: p.params,
			sub: p.sub
		};
	}
	
	static public function getExprs(p:Null<TypePath>, ?inComplexType:Bool = false):Array<Null<Expr>> {
		return p == null ? [] : 
			p.params.fold(function(param, a:Array<Null<Expr>>) return switch(param) {
				case TPType(t):
					inComplexType ? a.concat(t.getExprs(inComplexType)) : a;
				case TPExpr(e):
					a.concat([e]);
			}, []);
	}
}