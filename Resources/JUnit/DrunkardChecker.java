public class DrunkardChecker {
	private static int totalTestsCount = 0;
	private static int passingTestsCount = 0;

	public static void main(String[] args) {
		DrunkardChecker check = new DrunkardChecker();
		check.go();
	}

	public void go() {
		DrunkardPublicWrapper myDrunkard = this.new DrunkardPublicWrapper(-1, 6);

		myDrunkard.step();
		int expectedDistance = 1;
		assertEquals(myDrunkard.howFar(), expectedDistance, "Single Step Distance");

		myDrunkard.fastForward(25);
		int x = myDrunkard.getXCoordinate();
		int y = myDrunkard.getYCoordinate();
		int initX = myDrunkard.getInitialXCoordinate();
		int initY = myDrunkard.getInitialYCoordinate();
		assertEquals(
				myDrunkard.howFar(),
				Math.abs(initY - y) + Math.abs(initX - x),
				"Fast Forward Distance"
		);
	}

	private static void setUp() {
		System.out.println("--- Running Tests ---");
	}

	private static void tearDown() {
		System.out.println(passingTestsCount + "/" + totalTestsCount + " tests passed.");
	}

	private static void assertEquals(int actual, int expected, String testName) {
		totalTestsCount++;
		System.out.print(testName);

		if((actual - expected) == 0) {
			passingTestsCount++;
			System.out.println(" -- Passed");
		}
		else {
			System.out.println(" -- Failed");
		}
		System.out.println("Expected: " + expected);
		System.out.println("Actual: " + actual + "\n");
	}

	private class DrunkardPublicWrapper extends Drunkard {
		public DrunkardPublicWrapper(int x, int y) {
			super(x, y);
		}

		public int getXCoordinate() {
			return this.x;
		}

		public int getYCoordinate() {
			return this.y;
		}

		public int getInitialXCoordinate() {
			return this.initialX;
		}

		public int getInitialYCoordinate() {
			return this.initialY;
		}
	}
}
