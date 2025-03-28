#include "MPU9250.h"

MPU9250 imu(Wire, 0x68); // I2C, address 0x68 (AD0 low)

void setup() {
  Serial.begin(115200);
  Wire.begin();
  
  // Initialize MPU9250
  int status = imu.begin();
  if (status < 0) {
    Serial.println("IMU initialization failed");
    Serial.print("Error code: "); Serial.println(status);
    while(1) {}
  }

  // Configure ranges
  imu.setAccelRange(MPU9250::ACCEL_RANGE_8G);
  imu.setGyroRange(MPU9250::GYRO_RANGE_500DPS);
  imu.setDlpfBandwidth(MPU9250::DLPF_BANDWIDTH_20HZ);
  
  Serial.println("time(ms),accelX(m/s²),accelY(m/s²),accelZ(m/s²)");
}

void loop() {
  imu.readSensor(); // Read all sensors
  
  // Print timestamped data
  Serial.print(millis());
  Serial.print(",");
  Serial.print(imu.getAccelX_mss(), 4);
  Serial.print(",");
  Serial.print(imu.getAccelY_mss(), 4);
  Serial.print(",");
  Serial.println(imu.getAccelZ_mss(), 4);
  
  delay(10); // ~100Hz sampling
}