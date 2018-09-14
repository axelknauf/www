---
date: "2015-12-20"
title: 'Java: Dynamic Event Throttling'
---

In the code snippet described below I outline an algorithm for dynamically throttle the number of events occurring. In the example I limit the rate of exceptions being thrown, but theoretically this can be any kind of event, e. g. requests coming from some event source or user.

<!--more-->

## Throttling / rate limiting for requests (or in this case, exceptions)

        import java.util.Random;

        import org.junit.Test;

        public class Bar {

          private static final long rate = 10L; // ten exceptions allowed
          private static final long per = 60000L; // per minute (= 12.000
                              // milliseconds)
          private static long allowance = rate;
          private static long last = System.currentTimeMillis();

          @Test
          public void testThresholding() {
            // Algorithm adapted from:
            // http://stackoverflow.com/questions/667508/whats-a-good-rate-limiting-algorithm
            for (int i = 0; i < 120; i++) {
              try {
                businessMethod();
              }
              catch (RuntimeException e) {
                long time = System.currentTimeMillis();
                long passedMs = Math.max(time - last, 1);
                last = time;

                double coeff = (double) rate / (double) per;
                long increment = Math.round(passedMs * coeff);

                allowance += increment;

                System.out.printf("-----------------------------\n");
                System.out.printf("time\t\t:%d\n", time);
                System.out.printf("passed (ms)\t:%d\n", passedMs);
                System.out.printf("increment\t:%d\n", increment);
                System.out.printf("allowance\t:%d\n", allowance);

                // Uncomment this block to enable throttling to the
                // defined rate.
                // if (allowance > rate) {
                // allowance = rate; // throttle
                // }
                // System.out.printf("throttled\t:%d\n", allowance);

                if (allowance < 1) {
                  System.out.println("==> too many exceptions!");
                }
                else {
                  System.out.println("==> still inside the limit.");
                  allowance--;
                }

              }
            }
          }

          private void businessMethod() {
            // How many percent of business calls result in an exception
            final int exceptionPercent = 10;

            System.out.println("Business method");

            int val = new Random().nextInt(101);
            int delay = new Random().nextInt(1001);
            try {
              Thread.sleep(delay);
              if (val <= exceptionPercent) {
                throw new RuntimeException("BusinessException");
              }
            }
            catch (InterruptedException e) {
              // ignore
            }
          }
        }

