// Copyright (C) 2021 Toitware ApS.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the EXAMPLES_LICENSE file.

/**
A simple example of how to use the VCNL4040 driver.
*/

import gpio
import i2c
import vcnl4040 show Vcnl4040

main:
  bus := i2c.Bus
    --sda=gpio.Pin 21
    --scl=gpio.Pin 22
    --frequency=1000
  
  device := bus.device Vcnl4040.I2C-ADDRESS
  
  sensor := Vcnl4040 device

  id := sensor.get-id

  if id != Vcnl4040.DEVICE-ID:
    throw "Id was 0x$(%x id). Wrong device attached to I2C bus?"

  sensor.set-ps-led-current 200         // Max is 200mA.
  sensor.set-ps-duty-cycle 40           // Max infrared duty cycle is 1/40.
  sensor.set-ps-integration-time Vcnl4040.PS-IT-8T  // Max integration time.
  sensor.set-ps-resolution 16           // 16 bit output.
  sensor.set-ps-smart-persistence true  // Enable smart persistence.
  sensor.set-ps-power true              // Power on.
  // sensor.set_als_integration_time 80 // Short integration time.
  // sensor.set_als_power true          // Power on the ambient light sensor.
  
  while true:
    print "$sensor.read-ps-data"
    sleep --ms=250
