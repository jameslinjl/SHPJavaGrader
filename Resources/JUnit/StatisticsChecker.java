public class StatisticsChecker {
    private static int totalTestsCount = 0;
    private static int passingTestsCount = 0;

    public static void main(String[] args) {
        System.out.println("--- Running Tests ---");

        double[][] arrays = {
            {0, 1, 7, 7, 10},
            {1, 0, 5, -7.44, 9.123, 1.5366, 1.5366},
            {17, 5, 5, 4.5, 3.5, 2, 1, -1}
        };

        double[] expectedMins = {
            0,
            -7.44,
            -1
        };
        for (int i = 0; i < arrays.length; i++) {
            assertEquals(
                Statistics.min(arrays[i]),
                expectedMins[i],
                "Min Test " + i
            );
        }

        double[] expectedMaxs = {
            10,
            9.123,
            17
        };
        for (int i = 0; i < arrays.length; i++) {
            assertEquals(
                Statistics.max(arrays[i]),
                expectedMaxs[i],
                "Max Test " + i
            );
        }

        double[] expectedMeans = {
            5,
            1.5366,
            4.625
        };
        for (int i = 0; i < arrays.length; i++) {
            assertEquals(
                Statistics.mean(arrays[i]),
                expectedMeans[i],
                "Mean Test " + i
            );
        }

        double[] expectedMedians = {
            7,
            1.5366,
            4
        };
        for (int i = 0; i < arrays.length; i++) {
            assertEquals(
                Statistics.median(arrays[i]),
                expectedMedians[i],
                "Mean Test " + i
            );
        }

        double[] expectedModes = {
            7,
            1.5366,
            5
        };
        for (int i = 0; i < arrays.length; i++) {
            assertEquals(
                Statistics.mode(arrays[i]),
                expectedModes[i],
                "Mode Test " + i
            );
        }

        System.out.println(passingTestsCount + "/" + 
            totalTestsCount + " tests passed.");
    }

    private static void assertEquals(double actual, double expected, 
        String testName) {
        
        totalTestsCount++;
        System.out.print(testName);
        
        if(Math.abs(actual - expected) < 0.000000001) {
            passingTestsCount++;
            System.out.println(" -- Passed");
        }
        else {
            System.out.println(" -- Failed");
        }
        System.out.println("Expected: " + expected);
        System.out.println("Actual: " + actual + "\n");
    }
}
