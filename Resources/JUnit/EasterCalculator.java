/* 
 * James Lin
 * Columbia Science Honors Program, Fall 2015
 * EasterCalculator - this program calculates what date Easter will fall on in
 * a given year
*/

import java.util.Scanner;

public class EasterCalculator {
    
    public static void main(String[] args) {

        // get user input
        Scanner myScanner = new Scanner(System.in);
        System.out.print("Enter a year to find its Easter date: ");
        int y = myScanner.nextInt();

        String result = computeEaster(y);
        System.out.println(result);
    }

    protected static String computeEaster(int y) {

        // perform Gauss's computation
        int a = y % 19;
        int b = y / 100;
        int c = y % 100;
        int d = b / 4;
        int e = b % 4;
        int g = (8 * b + 13) / 25;
        int h = (19 * a + b - d - g + 15) % 30;
        int j = c / 4;
        int k = c % 4;
        int m = (a + 11 * h) / 319;
        int r = (2 * e + 2 * j - k - h + m + 32) % 7;
        int n = (h - m + r + 90) / 25;
        int p = (h - m + r + n + 19) % 32;

        return n + "/" + p;
    }
}
