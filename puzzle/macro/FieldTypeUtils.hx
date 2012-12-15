package puzzle.macro;

import haxe.macro.Expr;
using Lambda;
using puzzle.macro.ComplexTypeUtils;
using puzzle.macro.ExprUtils;
using puzzle.macro.TypeParamUtils;
using puzzle.macro.TypeParamDeclUtils;

class FieldTypeUtils {
	static public function clone(ft:Null<FieldType>, ?deep:Bool = true):Null<FieldType> {
		return ft == null ? null : switch (ft) {
			case FVar(t, e):
				deep ? FVar(t.clone(deep), e.clone(deep)) : FVar(t, e);
			case FFun(f):
				deep ? FFun({
					args: f.args.map(function(a) return { name:a.name, opt:a.opt, type:a.type.clone(deep), value:a.value.clone(deep) }).array(),
					ret: f.ret.clone(deep),
					expr: f.expr.clone(deep),
					params: f.params.map(function(p) return p.clone(deep)).array()
				}) : FFun(f);
			case FProp(get, set, t, e):
				deep ? FProp(get, set, t.clone(deep), e.clone(deep)) : FProp(get, set, t, e);
		}
	}
	
	static public function getExprs(ft:Null<FieldType>, ?inComplexType = false):Array<Null<Expr>> {
		return ft == null ? [] : switch (ft) {
			case FVar(t, e):
				inComplexType ? t.getExprs(inComplexType).concat([e]) : [e];
			case FFun(f):
				if (inComplexType)
					f
						.args.fold(function(arg, a:Array<Null<Expr>>) return a.concat(arg.type.getExprs(inComplexType)).concat([arg.value]), [])
						.concat([f.expr])
						.concat(f.params.fold(function(p, a:Array<Null<Expr>>) return a.concat(p.getExprs(inComplexType)), []))
						.concat(f.ret.getExprs(inComplexType));
				else
					f
						.args.map(function(arg) return arg.value).array()
						.concat([f.expr]);
			case FProp(_, _, t, e):
				inComplexType ? t.getExprs(inComplexType).concat([e]) : [e];
		};
	}
}