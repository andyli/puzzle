class TestAll {
	static public function main():Void {
		var runner = new haxe.unit.TestRunner();
		runner.add(new TestPuzzle());
		runner.add(new TestMacroComplexTypeUtils());
		runner.add(new TestMacroExprUtils());
		runner.run();
	}
}