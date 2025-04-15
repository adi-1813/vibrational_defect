#include <Wire.h>

#define MPU1_ADDR 0x68  // First MPU-9250 address
#define MPU2_ADDR 0x69  // Second MPU-9250 address
#define ACCEL_CONFIG 0x1C
#define ACCEL_XOUT_H 0x3B

// Calibration values
float ax1_offset = 0, ay1_offset = 0, az1_offset = 0;
float ax2_offset = 0, ay2_offset = 0, az2_offset = 0;

void setup() {
    Serial.begin(115200);
    Wire.begin();

    setupMPU(MPU1_ADDR);
    setupMPU(MPU2_ADDR);

    Serial.println("Calibrating sensors...");
    calibrateMPU(MPU1_ADDR, ax1_offset, ay1_offset, az1_offset);
    calibrateMPU(MPU2_ADDR, ax2_offset, ay2_offset, az2_offset);
    Serial.println("Calibration complete.");
}

void loop() {
    float ax1, ay1, az1, ax2, ay2, az2;
    
    readAccelerometer(MPU1_ADDR, ax1, ay1, az1);
    readAccelerometer(MPU2_ADDR, ax2, ay2, az2);

    // Apply calibration offsets
    ax1 -= (ax1_offset - 1.00);
    ay1 -= ay1_offset;
    az1 -= az1_offset; // Subtracting 1g (gravity)
    
    ax2 -= (ax2_offset - 1.00);
    ay2 -= ay2_offset;
    az2 -= az2_offset; // Subtracting 1g (gravity)

    // Print calibrated values
    Serial.print(ax1); Serial.print(","); Serial.print(ay1); Serial.print(",");
    Serial.print(az1); Serial.print(","); Serial.print(ax2); Serial.print(",");
    Serial.print(ay2); Serial.print(","); Serial.println(az2);

    delay(1); // Sampling at ~1000Hz
}

void setupMPU(int addr) {
    Wire.beginTransmission(addr);
    Wire.write(0x6B);  // Power management register
    Wire.write(0x00);  // Wake up MPU
    Wire.endTransmission();

    Wire.beginTransmission(addr);
    Wire.write(ACCEL_CONFIG);
    Wire.write(0x00);  // ±2g sensitivity
    Wire.endTransmission();
}

void calibrateMPU(int addr, float &ax_offset, float &ay_offset, float &az_offset) {
    int numSamples = 1000;
    float sum_ax = 0, sum_ay = 0, sum_az = 0;

    for (int i = 0; i < numSamples; i++) {
        float ax, ay, az;
        readAccelerometer(addr, ax, ay, az);
        sum_ax += ax;
        sum_ay += ay;
        sum_az += az;
        delay(2);
    }

    ax_offset = sum_ax / numSamples;
    ay_offset = sum_ay / numSamples;
    az_offset = sum_az / numSamples;
}

void readAccelerometer(int addr, float &ax, float &ay, float &az) {
    Wire.beginTransmission(addr);
    Wire.write(ACCEL_XOUT_H);
    Wire.endTransmission(false);
    Wire.requestFrom(addr, 6, true);

    ax = (Wire.read() << 8 | Wire.read()) / 16384.0;
    ay = (Wire.read() << 8 | Wire.read()) / 16384.0;
    az = (Wire.read() << 8 | Wire.read()) / 16384.0;
}
