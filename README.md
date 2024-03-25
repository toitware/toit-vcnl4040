# VCNL4040

A low level driver for the VCNL4040 sensor.

This sensor combines proximity features with ambient light sensor features. It
is connected with I2C. The use of the interrupt-related features is untested
and will depend on how the device is wired up.

Documentation is available at
* [data sheet][datasheet]

## Usage
A simple usage example.

``` toit
import gpio
import i2c
import vcnl4040 show Vcnl4040

main:
  bus := i2c.Bus
    --sda=gpio.Pin 21
    --scl=gpio.Pin 22
    --frequency=1000

  device := bus.device Vcnl4040.I2C_ADDRESS

  sensor := Vcnl4040 device

  print "Sensor id is $(%04x sensor.get_id)"  // Should print 0x0186.

  sensor.set_ps_led_current 200         // Max is 200mA.
  sensor.set_ps_duty_cycle 40           // Max infrared duty cycle is 1/40.
  sensor.set_ps_integration_time Vcnl4040.PS_IT_8T  // Max integration time.
  sensor.set_ps_resolution 16           // 16 bit output.
  sensor.set_ps_smart_persistence true  // Enable smart persistence.
  sensor.set_ps_power true              // Power on.

  while true:
    print "$sensor.read_ps_data"
    sleep --ms=250
```

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[datasheet]: https://cdn.sparkfun.com/assets/2/3/8/f/c/VCNL4040_Datasheet.pdf
[tracker]: https://github.com/toitware/toit-vcnl4040/issues
