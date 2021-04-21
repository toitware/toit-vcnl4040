// Copyright (C) 2021 Toitware ApS. All rights reserved.
// Use of this source code is governed by an MIT-style license that can be found
// in the LICENSE file.

/**
A simple example of how to use the VCNL4040 driver.
*/

import gpio
import serial.protocols.i2c as i2c
import drivers.vcnl4040 show Vcnl4040

main:
  bus := i2c.Bus
    --sda=gpio.Pin 21
    --scl=gpio.Pin 22
    --frequency=1000
  
  device := bus.device Vcnl4040.I2C_ADDRESS
  
  sensor := Vcnl4040 device

  id := sensor.get_id

  if id != Vcnl4040.DEVICE_ID:
    throw "Id was 0x$(%x id). Wrong device attached to I2C bus?"

  sensor.set_ps_led_current 200         // Max is 200mA.
  sensor.set_ps_duty_cycle 40           // Max infrared duty cycle is 1/40.
  sensor.set_ps_integration_time Vcnl4040.PS_IT_8T  // Max integration time.
  sensor.set_ps_resolution 16           // 16 bit output.
  sensor.set_ps_smart_persistence true  // Enable smart persistence.
  sensor.set_ps_power true              // Power on.
  // sensor.set_als_integration_time 80 // Short integration time.
  // sensor.set_als_power true          // Power on the ambient light sensor.
  
  while true:
    print "$sensor.read_ps_data"
    sleep --ms=250
