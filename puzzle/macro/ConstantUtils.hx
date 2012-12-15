package puzzle.macro;

import haxe.macro.Expr;

class ConstantUtils {
	static public function clone(c:Null<Constant>):Null<Constant> {
		return c == null ? null : switch (c) {
			case CInt(v): CInt(v);
			case CFloat(f): CFloat(f);
			case CString(s): CString(s);
			case CIdent(s): CIdent(s);
			case CRegexp(r, opt): CRegexp(r, opt);
			#if !haxe3
			case CType(s): CType(s);
			#end
		}
	}
}