package puzzle;

import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.Type;
using Lambda;

class Builder {
	static var puzzleFields = new Hash<Array<Field>>();
	
	/**
	* Try infer the type from e
	*/
	static function inferType(t:Null<ComplexType>, e:Null<Expr>):Null<ComplexType> {
		if (t == null && e != null) {
			try {
				return Context.toComplexType(Context.typeof(e));
			} catch (e:Dynamic){}
		}
		
		return t;
	}
	
	/**
	* Try infer the type of a function
	*/
	static function inferFunctionType(func:Function, pos:Position):Null<{args : Array<ComplexType>, ret : ComplexType}> {
		try {
			switch(Context.toComplexType(Context.typeof({
				expr: EFunction(null, func),
				pos: pos
			}))) {
				case TFunction(args, ret): 
					return {
						args: args,
						ret: ret
					};
				default:
			}
		} catch (e:Dynamic){}
		
		return null;
	}
	
	@:macro public static function build():Array<Field> {
		var localClass = Context.getLocalClass().get();
		var fields = Context.getBuildFields();
		
		if (localClass.meta.has(Meta.puzzleProcessed))
			return fields;
		
		var newFields = [];
		
		if (localClass.interfaces.exists(function(t) return t.t.toString() == "puzzle.Puzzle")) { 
			//base Puzzle
			
			puzzleFields.set(Context.getLocalClass().toString(), fields);
		
			for (field in fields) {
				var kind = switch (field.kind) {
					case FVar(t, e):
						FieldType.FVar(inferType(t, e), null);
					case FFun(f):
						if (field.name == "new") continue;
						var ft = inferFunctionType(f, field.pos);
						FieldType.FFun({
							args: f.args.mapi(function(i, a) return {
								name: a.name,
								opt: a.opt,
								type: ft.args[i],
								value: a.value
							}).array(),
							ret: ft.ret,
							expr: null,
							params: f.params
						});
					case FProp(get, set, t, e):
						FieldType.FProp(get, set, inferType(t, e), null);
				}
				
				newFields.push({
					name: field.name,
					doc: field.doc,
					access: field.access.has(APublic) ? field.access : field.access.concat([APrivate]),
					kind: kind,
					pos: field.pos,
					meta: field.meta
				});
			}
		} else {
			//subclass of a base Puzzle
			
			newFields = fields;
			for (t in localClass.interfaces) {
				var tname = t.t.toString();
				if (puzzleFields.exists(tname)) {
					var puzzleField = puzzleFields.get(tname);
					newFields = newFields.concat(puzzleField);
				}
			}
		}
		
		localClass.meta.add(Meta.puzzleProcessed, [], localClass.pos);
		
		return newFields;
	}
}