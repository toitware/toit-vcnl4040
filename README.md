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

  device := bus.device Vcnl4040.I2C-ADDRESS

  sensor := Vcnl4040 device

  print "Sensor id is $(%04x sensor.get-id)"  // Should print 0x0186.

  sensor.set-ps-led-current 200         // Max is 200mA.
  sensor.set-ps-duty-cycle 40           // Max infrared duty cycle is 1/40.
  sensor.set-ps-integration-time Vcnl4040.PS-IT-8T  // Max integration time.
  sensor.set-ps-resolution 16           // 16 bit output.
  sensor.set-ps-smart-persistence true  // Enable smart persistence.
  sensor.set-ps-power true              // Power on.

  while true:
    print "$sensor.read-ps-data"
    sleep --ms=250
```

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[datasheet]: https://cdn.sparkfun.com/assets/2/3/8/f/c/VCNL4040_Datasheet.pdf
[tracker]: https://github.com/toitware/toit-vcnl4040/issues
