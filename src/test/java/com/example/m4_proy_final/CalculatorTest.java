package com.example.m4_proy_final;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

class CalculatorTest {

    @Test
    void testAdd() {
        Calculator calculator = new Calculator();
        assertEquals(5, calculator.add(2, 3));
        assertEquals(-5, calculator.add(-2, -3));
    }

    @Test
    void testSubtract() {
        Calculator calculator = new Calculator();
        assertEquals(2, calculator.subtract(5, 3));
        assertEquals(-8, calculator.subtract(-5, 3));
    }

    @Test
    void testMultiply() {
        Calculator calculator = new Calculator();
        assertEquals(6, calculator.multiply(2, 3));
        assertEquals(0, calculator.multiply(0, 3));
        assertEquals(-3, calculator.multiply(1, -3));
    }

    @Test
    void testDivide() {
        Calculator calculator = new Calculator();
        assertEquals(5.0, calculator.divide(10, 2));

        IllegalArgumentException exception = assertThrows(
                IllegalArgumentException.class,
                () -> calculator.divide(10, 0)
        );

        assertEquals("Denominator cannot be zero", exception.getMessage());
    }

    @Test
    void testFactorial() {
        Calculator calculator = new Calculator();
        assertEquals(1.0, calculator.factorial(0));
        assertEquals(120.0, calculator.factorial(5));
    }

    @Test
    void testFactorialRejectsNegativeNumbers() {
        Calculator calculator = new Calculator();

        IllegalArgumentException exception = assertThrows(
                IllegalArgumentException.class,
                () -> calculator.factorial(-1)
        );

        assertEquals("Negative numbers are not allowed", exception.getMessage());
    }
}
