package com.ceylonheritage.backend.utils;

import java.security.SecureRandom;

public class OtpUtil {

    private static final SecureRandom random = new SecureRandom();

    private OtpUtil() {
    }

    public static String generateOtp() {
        int number = random.nextInt(900000) + 100000;
        return String.valueOf(number);
    }
}