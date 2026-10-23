package com.wayfarer.ai.service;

/** Two-decimal rounding for the planner's USD figures. */
final class Money {
    private Money() {}

    static double round2(double n) { return Math.round((n + Math.ulp(1.0)) * 100.0) / 100.0; }
}
