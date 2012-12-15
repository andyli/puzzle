package puzzle.macro;

import haxe.macro.Expr;
using Lambda;
using puzzle.macro.ExprUtils;
using puzzle.macro.FieldTypeUtils;
using puzzle.macro.TypeParamUtils;
using puzzle.macro.TypePathUtils;

class ComplexTypeUtils {
	static public function clone(ct:Null<ComplexType>, ?deep:Bool = true):Null<ComplexType> {
		return ct == null ? null : switch (ct) {
			case TPath(p):
				deep ? TPath(p.clone(deep)) : TPath(p);
			case TFunction(args, ret):
				deep ? TFunction(args.map(function (a) return clone(a, deep)).array(), clone(ret)) : TFunction(args, ret);
			case TAnonymous(fields):
				deep ? TAnonymous(fields.map(function(field) return {
					name: field.name,
					doc: field.doc,
					access: field.access.copy(),
					kind: field.kind.clone(deep),
					pos: field.pos,
					meta: field.meta.map(function(m) return {
						name: m.name,
						params : m.params.map(function(param) return param.clone(deep)).array(),
						pos: m.pos
					}).array()
				}).array()) : TAnonymous(fields);
			case TParent(t):
				deep ? TParent(clone(t, deep)) : TParent(t);
			case TExtend(p, fields):
				deep ? TExtend(p.clone(deep), fields.map(function(field) return {
					name: field.name,
					doc: field.doc,
					access: field.access.copy(),
					kind: field.kind.clone(deep),
					pos: field.pos,
					meta: field.meta.map(function(m) return {
						name: m.name,
						params : m.params.map(function(param) return param.clone(deep)).array(),
						pos: m.pos
					}).array()
				}).array()) : TExtend(p, fields);
			case TOptional(t):
				deep ? TOptional(clone(t, deep)) : TOptional(t);
		}
	}
	
	static public function getExprs(ct:Null<ComplexType>, ?inComplexType:Bool = false):Array<Null<Expr>> {
		return ct == null ? [] : switch (ct) {
			case TPath(p):
				p.getExprs(inComplexType);
			case TFunction(args, ret):
				if (inComplexType)
					args.fold(function(t, a:Array<Null<Expr>>) return a.concat(getExprs(t, inComplexType)), [])
						.concat(getExprs(ret, inComplexType))
				else 
					[];
			case TAnonymous(fields):
				fields.fold(function(f, a:Array<Null<Expr>>) return a
					.concat(f.kind.getExprs(inComplexType))
					.concat(f.meta.fold(function(m, a:Array<Null<Expr>>) return a.concat(m.params), []))
				, []);
			case TParent(t):
				inComplexType ? getExprs(t, inComplexType) : [];
			case TExtend(p, fields):
				p.getExprs(inComplexType).concat(
					fields.fold(function(f, a:Array<Null<Expr>>) return a
						.concat(f.kind.getExprs(inComplexType))
						.concat(f.meta.fold(function(m, a:Array<Null<Expr>>) return a.concat(m.params), [])
				), []));
			case TOptional(t):
				inComplexType ? getExprs(t, inComplexType) : [];
		}
	}
}