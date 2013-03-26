import haxe.unit.*;

class TestAll {
	static public function main():Void {
		var runner = new TestRunner();
		runner.add(new TestPuzzle());
		runner.add(new TestMacroComplexTypeUtils());
		runner.add(new TestMacroExprUtils());
		runner.run();
		
		#if sys
		var result:TestResult = untyped runner.result;
		Sys.exit(result.success ? 0 : 1);
		#end
	}
}