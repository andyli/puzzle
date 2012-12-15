package puzzle.macro;

import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.Type;
using Lambda;
using puzzle.macro.ComplexTypeUtils;
using puzzle.macro.ConstantUtils;
using puzzle.macro.TypeParamUtils;
using puzzle.macro.TypeParamDeclUtils;
using puzzle.macro.TypePathUtils;

enum TraverseControl {
	/** Keep traversing. */
	TCContinue;
	
	/** Do not process the children of this expr, skip to the next Expr. Only for preorder traversal. */
	TCNoChildren;
	
	/** Stop traversing. */
	TCExit;
}

class ExprUtils {
	/**
	 * Traverse the Expr recusively.
	 * @param	expr
	 * @param	callb				Accepts a Null<Expr> and a stack(List<Expr> using push/pop, first is current), return a TraverseControl.
	 * @param	?preorder = true	Should the traversal run in preorder or postorder.
	 * @param	?getChildrenFunc	Default to getChildren.
	 * @param	?stack				Internal use to maintain the travesal stack to pass to callb.
	 * @return						Did the traversal reach the end, ie. hadn't stopped by TCExit.
	 */
	static public function traverse(expr:Null<Expr>, callb:Null<Expr>->List<Expr>->TraverseControl, ?preorder:Bool = true, ?getChildrenFunc:Null<Expr>->Array<Null<Expr>>, ?stack:List<Expr>):Bool {
		if (stack == null) stack = new List();
		if (getChildrenFunc == null) getChildrenFunc = callback(getExprs, _, false);
		stack.push(expr);
		
		var ret:Bool;
		try {
			ret = 
				(preorder ? switch (callb(expr,stack)) {
						case TCContinue: true;
						case TCNoChildren: throw TCNoChildren;
						case TCExit: false;
					} : true) 
				&& getChildrenFunc(expr).foreach(function(e) return traverse(e,callb,preorder,getChildrenFunc,stack))
				&& (preorder ? true : switch (callb(expr,stack)) {
						case TCContinue: true;
						case TCExit: false;
						case TCNoChildren: throw #if debug "TCNoChildren has no effect on postorder traversal." #else TCNoChildren #end ;
					});
		} catch (tc:TraverseControl) {
			ret = switch(tc) {
				case TCNoChildren: true;
				default: throw tc;
			}
		}
		
		stack.pop();
		return ret;
	}
	
	/**
	 * Return an Array of Expr that the input holds.
	 */
	static public function getExprs(expr:Null<Expr>, ?inComplexType:Bool = false):Array<Null<Expr>> {
		return expr == null ? [] : switch (expr.expr) {
			case EConst(_):
				[];
			case EArray(e1, e2):
				[e1, e2];
			case EBinop(_, e1, e2):
				[e1, e2];
			case EField(e, _):
				[e];
			case EParenthesis(e):
				[e];
			case EObjectDecl(fields):
				fields.map(function(f) return f.expr).array();
			case EArrayDecl(values):
				values.copy();
			case ECall(e, params):
				[e].concat(params);
			case ENew(t, params):
				inComplexType ? t.getExprs().concat(params) : params.copy();
			case EUnop(_, _, e):
				[e];
			case EVars(vars):
				if (inComplexType)
					vars.fold(function(v, a:Array<Null<Expr>>) return 
						v.type.getExprs(inComplexType).concat([v.expr]
					), []);
				else
					vars.map(function(v) return v.expr).array();
			case EFunction(_, f): 
				if (inComplexType)
					f.args.fold(function(arg, a:Array<Null<Expr>>) return a
						.concat(arg.type.getExprs(inComplexType))
						.concat([arg.value]), []
					).concat([f.expr]);
				else
					f.args.map(function(a) return a.value).array().concat([f.expr]);
			case EBlock(exprs): 
				exprs.copy();
			case EFor(it, expr): 
				[it, expr];
			case EIn(e1, e2): 
				[e1, e2];
			case EIf(econd, eif, eelse): 
				[econd, eif, eelse];
			case EWhile(econd, e, _): 
				[econd, e];
			case ESwitch(e, cases, edef): 
				[e]
					.concat(cases.fold(function(c,a) return c.values.concat([c.guard, c.expr]).concat(a),[]))
					.concat([edef]);
			case ETry(e, catches):
				if (inComplexType)
					[e].concat(catches.fold(function(c, a:Array<Null<Expr>>) return a
						.concat([c.expr])
						.concat(c.type.getExprs(inComplexType))
					, []));
				else
					[e].concat(catches.map(function(c) return c.expr).array());
			case EReturn(e):
				[e];
			case EBreak:
				[];
			case EContinue:
				[];
			case EUntyped(e):
				[e];
			case EThrow(e):
				[e];
			case ECast(e, t):
				inComplexType ? [e].concat(t.getExprs(inComplexType)) : [e];
			case EDisplay(e, _):
				[e];
			case EDisplayNew(t): 
				inComplexType ? t.getExprs(inComplexType) : [];
			case ETernary(econd, eif, eelse):
				[econd, eif, eelse];
			case ECheckType(e, t):
				inComplexType ? [e].concat(t.getExprs(inComplexType)) : [e];
			case EMeta(s, e): 
				s.params.concat([e]);
			#if !haxe3
			case EType(e):
				[e];
			#end
		}
	}
	
	/**
	 * Recursivly reconstruct an Expr with postorder traversal.
	 * @param	expr
	 * @param	callb	Accepts a Null<Expr> and a stack(List<Expr> using push/pop, first is current), return a Null<Expr> that replace the input.
	 * @param	?stack	Internal use to maintain the travesal stack to pass to callb.
	 * @return			A new reconstructed Expr.
	 */
	static public function reconstruct(expr:Null<Expr>, callb:Null<Expr>->List<Expr>->Null<Expr>, ?stack:List<Expr>):Null<Expr> {
		if (stack == null) stack = new List();
		stack.push(expr);
		
		var r = expr == null ? callb(expr, stack) : callb(switch (expr.expr) {
			case EConst(_): 
				expr;
			case EArray(e1, e2): 
				{ expr:EArray(reconstruct(e1,callb,stack), reconstruct(e2,callb,stack)), pos:expr.pos };
			case EBinop(op, e1, e2):
				{ expr:EBinop(op, reconstruct(e1,callb,stack), reconstruct(e2,callb,stack)), pos:expr.pos };
			case EField(e, field): 
				{ expr:EField(reconstruct(e,callb,stack), field), pos:expr.pos };
			case EParenthesis(e): 
				{ expr:EParenthesis(reconstruct(e,callb,stack)), pos:expr.pos };
			case EObjectDecl(fields):
				var newfields = [];
				for (f in fields) newfields.push({ field:f.field, expr:reconstruct(f.expr,callb,stack) });
				{ expr:EObjectDecl(newfields), pos:expr.pos };
			case EArrayDecl(values):
				var newvalues = [];
				for (v in values) newvalues.push(reconstruct(v,callb,stack));
				{ expr:EArrayDecl(newvalues), pos:expr.pos };
			case ECall(e, params):
				var newparams = [];
				for (p in params) newparams.push(reconstruct(p,callb,stack));
				{ expr:ECall(reconstruct(e,callb,stack),newparams), pos:expr.pos };
			case ENew(t, params):
				var newparams = [];
				for (p in params) newparams.push(reconstruct(p,callb,stack));
				{ expr:ENew(t,newparams), pos:expr.pos };
			case EUnop(op, postFix, e): 
				{ expr:EUnop(op, postFix, reconstruct(e,callb,stack)), pos:expr.pos };
			case EVars(vars): 
				var newvars = [];
				for (v in vars) newvars.push( { name:v.name, type:v.type, expr:reconstruct(v.expr,callb,stack) } );
				{ expr:EVars(newvars), pos:expr.pos };
			case EFunction(n, f):
				var newf = {
					args: [],
					ret: f.ret,
					expr: reconstruct(f.expr,callb,stack),
					params: f.params
				}
				for (a in f.args) newf.args.push( { name:a.name, opt:a.opt, type:a.type, value:reconstruct(a.value,callb,stack) } );
				{ expr:EFunction(n, newf), pos:expr.pos };
			case EBlock(exprs):
				var newexprs = [];
				for (e in exprs) newexprs.push(reconstruct(e,callb,stack));
				{ expr:EBlock(newexprs), pos:expr.pos };
			case EFor(it, expr):
				{ expr:EFor(reconstruct(it,callb,stack), reconstruct(expr,callb,stack)), pos:expr.pos };
			case EIn(e1, e2):
				{ expr:EIn(reconstruct(e1,callb,stack), reconstruct(e2,callb,stack)), pos:expr.pos };
			case EIf(econd, eif, eelse):
				{ expr:EIf(reconstruct(econd,callb,stack), reconstruct(eif,callb,stack), reconstruct(eelse,callb,stack)), pos:expr.pos };
			case EWhile(econd, e, normalWhile):
				{ expr:EWhile(reconstruct(econd,callb,stack), reconstruct(e,callb,stack), normalWhile), pos:expr.pos };
			case ESwitch(e, cases, edef):
				var newcases = [];
				for (c in cases) {
					var newvalues = [];
					for (v in c.values) newvalues.push(reconstruct(v,callb,stack));
					newcases.push( { values:newvalues, guard:reconstruct(c.guard,callb,stack), expr:reconstruct(c.expr,callb,stack) } );
				}
				{ expr:ESwitch(reconstruct(e,callb,stack), newcases, reconstruct(edef,callb,stack)), pos:expr.pos };
			case ETry(e, catches):
				var newcatches = [];
				for (c in catches) newcatches.push( { name:c.name, type:c.type, expr:reconstruct(c.expr,callb,stack) } );
				{ expr:ETry(reconstruct(e,callb,stack), newcatches), pos:expr.pos };
			case EReturn(e):
				{ expr:EReturn(reconstruct(e,callb,stack)), pos:expr.pos };
			case EBreak: 
				expr;
			case EContinue: 
				expr;
			case EUntyped(e): 
				{ expr:EUntyped(reconstruct(e,callb,stack)), pos:expr.pos };
			case EThrow(e):
				{ expr:EThrow(reconstruct(e,callb,stack)), pos:expr.pos };
			case ECast(e, t):
				{ expr:ECast(reconstruct(e,callb,stack), t), pos:expr.pos };
			case EDisplay(e, isCall):
				{ expr:EDisplay(reconstruct(e,callb,stack), isCall), pos:expr.pos };
			case EDisplayNew(_):
				expr;
			case ETernary(econd, eif, eelse):
				{ expr:ETernary(reconstruct(econd,callb,stack), reconstruct(eif,callb,stack), reconstruct(eelse,callb,stack)), pos:expr.pos };
			case ECheckType(e, t):
				{ expr:ECheckType(reconstruct(e,callb,stack), t), pos:expr.pos };
			case EMeta(s, e):
				{ expr:EMeta({ name: s.name, params: s.params.map(function(p) return reconstruct(p,callb,stack)).array(), pos:expr.pos }, reconstruct(e,callb,stack)), pos:expr.pos };
			#if !haxe3
			case EType(e, field): 
				{ expr:EType(reconstruct(e,callb,stack), field), pos:expr.pos };
			#end
		},stack);
		
		stack.pop();
		return r;
	}
	
	/**
	 * Clone an Expr.
	 * @param	expr
	 * @param	?deep	Recursivly or not.
	 * @return			The clone of input.
	 */
	static public function clone(expr:Null<Expr>, ?deep:Bool = true):Null<Expr> {
		return expr == null ? null : { pos: expr.pos, expr: switch (expr.expr) {
			case EConst(c): 
				deep ? EConst(c.clone()) : EConst(c);
			case EArray(e1, e2): 
				deep ? EArray(clone(e1, deep), clone(e2, deep)) : EArray(e1, e2);
			case EBinop(op, e1, e2): 
				deep ? EBinop(op, clone(e1, deep), clone(e2, deep)) : EBinop(op, e1, e2);
			case EField(e, field): 
				deep ? EField(clone(e, deep), field) : EField(e, field);
			case EParenthesis(e): 
				deep ? EParenthesis(clone(e, deep)) : EParenthesis(e);
			case EObjectDecl(fields):
				deep ? EObjectDecl(fields.map(function(f) return { field:f.field, expr:clone(f.expr, deep) }).array()) : EObjectDecl(fields);
			case EArrayDecl(values):
				deep ? EArrayDecl(values.map(function(v) return clone(v, deep)).array()) : EArrayDecl(values);
			case ECall(e, params):
				deep ? ECall(clone(e, deep), params.map(function(p) return clone(p, deep)).array()) : ECall(e, params);
			case ENew(t, params):
				deep ? ENew({
					pack: t.pack.copy(),
					name: t.name,
					params: t.params.map(function(param) return param.clone(deep)).array(),
					sub: t.sub
				}, params.map(function(p) return clone(p, deep)).array()): ENew(t, params);
			case EUnop(p, postFix, e): 
				deep ? EUnop(p, postFix, clone(e, deep)) : EUnop(p, postFix, e);
			case EVars(vars):
				deep ? EVars(vars.map(function(v) return { name:v.name, type:v.type.clone(deep), expr:clone(v.expr, deep) }).array()) : EVars(vars);
			case EFunction(n, f):
				deep ? EFunction(n, {
					args: f.args.map(function(a) return { name:a.name, opt:a.opt, type:a.type.clone(deep), value:clone(a.value, deep) }).array(),
					ret: f.ret.clone(deep),
					expr: clone(f.expr, deep),
					params: f.params.map(function(p) return { 
						name: p.name, 
						constraints: p.constraints.map(function(c) return c.clone(deep)).array(), 
						params: p.params.map(function(p) return p.clone(deep)).array(), 
					}).array()
				}) : EFunction(n, f);
			case EBlock(exprs):
				deep ? EBlock(exprs.map(function(e) return clone(e, deep)).array()) : EBlock(exprs);
			case EFor(it, expr):
				deep ? EFor(clone(it, deep), clone(expr, deep)) : EFor(it, expr);
			case EIn(e1, e2):
				deep ? EIn(clone(e1, deep), clone(e2, deep)) : EIn(e1, e2);
			case EIf(econd, eif, eelse):
				deep ? EIf(clone(econd, deep), clone(eif, deep), clone(eelse, deep)) : EIf(econd, eif, eelse);
			case EWhile(econd, e, normalWhile):
				deep ? EWhile(clone(econd, deep), clone(e, deep), normalWhile) : EWhile(econd, e, normalWhile);
			case ESwitch(e, cases, edef):
				deep ? ESwitch(e, cases.map(function(c) return { 
					values: c.values.map(function(v) return clone(v, deep)).array(),
					guard: clone(c.guard, deep),
					expr: clone(c.expr, deep) 
				}).array(), clone(edef, deep)) : ESwitch(e, cases, edef);
			case ETry(e, catches):
				deep ? ETry(e, catches.map(function(c) return { 
					name: c.name, 
					type: c.type.clone(deep), 
					expr: clone(c.expr, deep)
				}).array()) : ETry(e, catches);
			case EReturn(e):
				deep ? EReturn(clone(e, deep)) : EReturn(e);
			case EBreak: 
				EBreak;
			case EContinue: 
				EContinue;
			case EUntyped(e): 
				deep ? EUntyped(clone(e, deep)) : EUntyped(e);
			case EThrow(e):
				deep ? EThrow(clone(e, deep)) : EThrow(e);
			case ECast(e, t):
				deep ? ECast(clone(e, deep), t.clone(deep)) : ECast(e, t);
			case EDisplay(e, isCall):
				deep ? EDisplay(clone(e, deep), isCall) : EDisplay(e, isCall);
			case EDisplayNew(t):
				deep ? EDisplayNew({
					pack: t.pack.copy(),
					name: t.name,
					params: t.params.map(function(param) return param.clone(deep)).array(),
					sub: t.sub
				}) : EDisplayNew(t);
			case ETernary(econd, eif, eelse):
				deep ? ETernary(clone(econd, deep), clone(eif, deep), clone(eelse, deep)) : ETernary(econd, eif, eelse);
			case ECheckType(e, t):
				deep ? ECheckType(clone(e, deep), t.clone(deep)) : ECheckType(e, t);
			case EMeta(s, e):
				deep ? EMeta({
					name: s.name,
					params: s.params.map(function(p) return clone(p, deep)).array(),
					pos: s.pos
				}, clone(e, deep)) : EMeta(s, e);
			#if !haxe3
			case EType(e, field): 
				deep ? EType(clone(e, deep), field) : EType(e, field);
			#end
		}}
	}
}