// Copyright (C) 2021 Toitware ApS. All rights reserved.
// Use of this source code is governed by an MIT-style license that can be found
// in the LICENSE file.

/**
A low level driver for the VCNL4040 sensor.

This sensor combines proximity features with ambient light sensor features. It
  is connected with I2C. The use of the interrupt-related features is untested
  and will depend on how the device is wired up.

Documentation is available at
* https://cdn.sparkfun.com/assets/2/3/8/f/c/VCNL4040_Datasheet.pdf and
*/

import serial
import io

class Vcnl4040:
  static I2C-ADDRESS ::= 0x60
  static DEVICE-ID ::= 0x186

  registers_ /serial.Registers ::= ?

  // TODO: When we have moved to the SDK that supports it, this should just
  // call registers_.read_u16_le.
  read-u16-le_ reg/int -> int:
    ba := registers_.read-bytes reg 2
    return io.LITTLE-ENDIAN.uint16 ba 0

  // TODO: When we have moved to the SDK that supports it, this should just
  // call registers_.write_u16_le.
  write-u16-le_ reg/int value/int -> none:
    ba := ByteArray 2
    io.LITTLE-ENDIAN.put-uint16 ba 0 value
    registers_.write-bytes reg ba

  constructor device/serial.Device:
    registers_ = device.registers

  read-als-integration-time -> int:
    return ALS-IT-VALUES_[((read-u16-le_ ALS-CONF_) & ALS-IT-MASK_) >> ALS-IT-SHIFT_]

  /**
  Ambient light sensor integration time. Longer time has higher sensitivity.
  Valid values in ms are 80, 160, 320, or 640.
  */
  set-als-integration-time ms -> none:
    // An appropriate exception will be thrown by write_masked_ if this
    // index_of returns -1.
    value /int := ALS-IT-VALUES_.index-of ms
    write-masked_ ALS-CONF_ ALS-IT-MASK_ value << ALS-IT-SHIFT_

  read-als-persistence -> int:
    return ALS-PERS-VALUES_[((read-u16-le_ ALS-CONF_) & ALS-PERS-MASK_) >> ALS-PERS-SHIFT_]

  /**
  Changes the ambient light sensor interrupt persistence setting.
  This is the number of consecutive hits needed before an interrupt event occurs.
  Valid numbers of required hits are 1, 2, 4, or 8.
  */
  set-als-persistence hits -> none:
    value /int := ALS-PERS-VALUES_.index-of hits
    write-masked_ ALS-CONF_ ALS-PERS-MASK_ value << ALS-PERS-SHIFT_

  read-als-interrupt-enable -> bool:
    return ((read-u16-le_ ALS-CONF_) & ALS-INT-EN-MASK_) == ALS-INT-ENABLE_

  /**
  Ambient light sensor interrupt enable.
  */
  set-als-interrupt-enable value/bool -> none:
    write-masked_
      ALS-CONF_
      ALS-INT-EN-MASK_
      value ? ALS-INT-ENABLE_ : ALS-INT-DISABLE_

  /**
  Whether the ambient light sensor is powered on.
  */
  read-als-power -> bool:
    return ((read-u16-le_ ALS-CONF_) & ALS-SHUT-DOWN-MASK_) == ALS-POWER-ON_

  /**
  Turns the ambient light sensor on or off.
  */
  set-als-power value/bool -> none:
    write-masked_
      ALS-CONF_
      ALS-SHUT-DOWN-MASK_
      value ? ALS-POWER-ON_ : ALS-SHUT-DOWN_

  read-als-high-interrupt-threshold -> int:
    return read-u16-le_ ALS-THDH_

  /**
  Sets high threshold for ambient light sensor.
  The $threshold is a value from 0-65535.  What this means in lux depends on
    the integration time setting.  See table 14 in the data sheet.
  */
  write-als-high-interrupt-threshold threshold/int -> none:
    write-masked_ ALS-THDH_ FULL-REGISTER-MASK_ threshold

  read-als-low-interrupt-threshold -> int:
    return read-u16-le_ ALS-THDL_

  /**
  Sets low threshold for ambient light sensor.
  The $threshold is a value from 0-65535.  What this means in lux depends on
    the integration time setting.  See table 14 in the data sheet.
  */
  write-als-low-interrupt-threshold threshold/int -> none:
    write-masked_ ALS-THDL_ FULL-REGISTER-MASK_ threshold

  read-ps-duty-cycle -> int:
    return PS-DUTY-VALUES_[((read-u16-le_ PS-CONF-1-2_) & PS-DUTY-MASK_) >> PS-DUTY-SHIFT_]

  /**
  Sets proximity sensor infrared on-off duty ratio.
  Valid values in are 40, 80, 160, or 320, indicating ratios of 1/40, 1/80,
    1/160, or 1/320.
  */
  set-ps-duty-cycle ratio/int -> none:
    value /int := PS-DUTY-VALUES_.index-of ratio
    write-masked_ PS-CONF-1-2_ PS-DUTY-MASK_ value << PS-DUTY-SHIFT_

  read-ps-persistence -> int:
    return (((read-u16-le_ PS-CONF-1-2_) & PS-PERS-MASK_) >> PS-PERS-SHIFT_) + PS-PERS-OFFSET_

  /**
  Changes the proximity sensor interrupt persistence setting.
  The number of consecutive hits needed before an interrupt event occurs. Valid
    numbers of hits required are 1, 2, 3, or 4.
  */
  set-ps-persistence hits -> none:
    write-masked_ PS-CONF-1-2_ PS-PERS-MASK_ (hits - PS-PERS-OFFSET_) << PS-PERS-SHIFT_

  /**
  Gets proximity sensor integration time.
  Valid results are: PS_IT_1T, PS_IT_1_5T, PS_IT_2T, PS_IT_2_5T, PS_IT_3T,
    PS_IT_3_5T, PS_IT_4T, and PS_IT_8T.
  */
  read-ps-integration-time -> int:
    return (read-u16-le_ PS-CONF-1-2_) & PS-IT-MASK_

  /**
  Sets proximity sensor integration time.
  Valid values are: PS_IT_1T, PS_IT_1_5T, PS_IT_2T, PS_IT_2_5T, PS_IT_3T,
    PS_IT_3_5T, PS_IT_4T, and PS_IT_8T.
  */
  set-ps-integration-time time/int -> none:
    write-masked_ PS-CONF-1-2_ PS-IT-MASK_ time

  /**
  Whether the proximity sensor is powered on.
  */
  read-ps-power -> bool:
    return ((read-u16-le_ PS-CONF-1-2_) & PS-SD-MASK_) == PS-POWER-ON_

  /**
  Turns the proximity sensor power on or off.
  */
  set-ps-power value/bool -> none:
    write-masked_
      PS-CONF-1-2_
      PS-SD-MASK_
      value ? PS-POWER-ON_ : PS-SHUT-DOWN_

  /**
  Returns the proximity sensor resolution. Returns 12 for 12 bit resolution or
    16 for 16 bit resolution.
  */
  read-ps-resolution -> int:
    value := (read-u16-le_ PS-CONF-1-2_) & PS-HD-MASK_
    return value == PS-12-BIT_ ? 12 : 16

  /**
  Sets proximity sensor resolution.
  Valid values for $bits are 12 and 16.
  */
  set-ps-resolution bits/int -> none:
    if bits != 12 and bits != 16: throw "Value out of range"
    write-masked_ PS-CONF-1-2_ PS-HD-MASK_
      bits == 12 ? PS-12-BIT_ : PS-16-BIT_

  /**
  Gets proximity sensor interrupt trigger condition.
  Valid results are: PS_INT_NO_TRIGGER, PS_INT_CLOSE_TRIGGER,
    PS_INT_AWAY_TRIGGER, PS_INT_BOTH_TRIGGER.
  */
  read-ps-interrupt-trigger -> int:
    return (read-u16-le_ PS-CONF-1-2_) & PS-INT-MASK_

  /**
  Sets proximity sensor interrupt trigger condition.
  Valid values are: PS_INT_NO_TRIGGER, PS_INT_CLOSE_TRIGGER,
    PS_INT_AWAY_TRIGGER, PS_INT_BOTH_TRIGGER.
  */
  set-ps-interrupt-trigger value/int -> none:
    write-masked_ PS-CONF-1-2_ PS-INT-MASK_ value

  read-ps-smart-persistence -> bool:
    return ((read-u16-le_ PS-CONF-3-MS_) & PS-SMART-PERS-MASK_) == PS-SMART-PERS-ON_

  /**
  Enables or disables proximity sensor smart persistence.
  */
  set-ps-smart-persistence value/bool -> none:
    write-masked_
      PS-CONF-3-MS_
      PS-SMART-PERS-MASK_
      value ? PS-SMART-PERS-ON_ : PS-SMART-PERS-OFF_

  read-ps-active-force -> bool:
    return ((read-u16-le_ PS-CONF-3-MS_) & PS-AF-MASK_) == PS-AF-ON_

  /**
  Enables or disables proximity sensor active force mode.
  */
  set-ps-active-force value/bool -> none:
    write-masked_
      PS-CONF-3-MS_
      PS-AF-MASK_
      value ? PS-AF-ON_ : PS-AF-OFF_

  /**
  Proximity sensor active active force trigger. The device resets itself after
    one output cycle.
  */
  ps-active-force-trigger -> none:
    write-masked_
      PS-CONF-3-MS_
      PS-TRIG-MASK_
      PS-TRIG-ON_

  read-ps-white-channel -> bool:
    return ((read-u16-le_ PS-CONF-3-MS_) & PS-WHITE-EN-MASK_) == PS-WHITE-ENABLE_

  /**
  Enables or disables proximity sensor active force mode.
  */
  set-ps-white-channel value/bool -> none:
    write-masked_
      PS-CONF-3-MS_
      PS-WHITE-EN-MASK_
      value ? PS-WHITE-ENABLE_ : PS-WHITE-DISABLE_

  /**
  Gets proximity sensor mode.
  Valid return values are $PS-LOGIC-LEVEL-MODE and $PS-INTERRUPT-MODE.
  */
  read-ps-proximity-mode -> int:
    return (read-u16-le_ PS-CONF-3-MS_) & PS-MS-MASK_

  /**
  Sets proximity sensor mode.
  Valid values are PS_LOGIC_LEVEL_MODE and PS_INTERRUPT_MODE.
  */
  set-ps-proximity-mode value/int -> none:
    write-masked_
      PS-CONF-3-MS_
      PS-MS-MASK_
      value

  read-ps-led-current -> int:
    return PS-LED-I-VALUES_[((read-u16-le_ PS-CONF-3-MS_) & PS-LED-I-MASK_) >> PS-LED-I-SHIFT_]

  /**
  Sets proximity sensor LED current.
  Valid values in mA are 50, 75, 100, 120, 140, 160, 180, and 200.
  */
  set-ps-led-current milli-amps -> none:
    value /int := PS-LED-I-VALUES_.index-of milli-amps
    write-masked_ PS-CONF-3-MS_ PS-LED-I-MASK_ value << PS-LED-I-SHIFT_

  read-ps-cancellation-level -> int:
    return read-u16-le_ PS-CANC_

  /**
  Sets cancellation level for proximity sensor.
  The $level is a value from 0-65535.
  */
  write-ps-cancellation-level level/int -> none:
    write-masked_ PS-CANC_ FULL-REGISTER-MASK_ level

  read-ps-high-interrupt-threshold -> int:
    return read-u16-le_ PS-THDH_

  /**
  Sets high threshold for proximity sensor.
  The $threshold is a value from 0-65535.
  */
  write-ps-high-interrupt-threshold threshold/int -> none:
    write-masked_ PS-THDH_ FULL-REGISTER-MASK_ threshold

  read-ps-low-interrupt-threshold -> int:
    return read-u16-le_ PS-THDL_

  /**
  Sets low threshold for proximity sensor.
  The $threshold is a value from 0-65535.
  */
  write-ps-low-interrupt-threshold threshold/int -> none:
    write-masked_ PS-THDL_ FULL-REGISTER-MASK_ threshold

  /// Reads a value from 0-65535 from the proximity sensor.
  read-ps-data -> int:
    return read-u16-le_ PS-DATA_

  /// Reads a value from 0-65535 from the ambient light sensor.
  read-als-data -> int:
    return read-u16-le_ ALS-DATA_

  /// Reads a value from 0-65535 from the white channel sensor.
  read-white-data -> int:
    return read-u16-le_ WHITE-DATA_

  /**
  Resets the interrupt, and stores a value that indicates
    the reason(s) for the interrupt.
  This is a destructive operation - if you call it twice after an interrupt,
    the second time will overwrite the reasons the reasons. The reasons can be
    interrogated with the last_interrupt* methods.
  */
  reset-interrupt -> none:
    last-reasons_ = read-u16-le_ INT-FLAG_

  last-reasons_ /int := 0

  /**
  Returns whether the last interrupt was caused by the proximity sensor
    protection mode.
  Before reading this value, the interrupt must be reset with $reset-interrupt.
  */
  last-interrupt-was-ps-protection-mode -> bool:
    return last-reasons_ & PS-SP-FLAG_ != 0

  /**
  Returns whether the last interrupt was caused by the ambient light sensor
    crossing the low threshold.
  Before reading this value, the interrupt must be reset with $reset-interrupt.
  */
  last-interrupt-was-als-low -> bool:
    return last-reasons_ & ALS-IF-L_ != 0

  /**
  Returns whether the last interrupt was caused by the ambient light sensor
    crossing the high threshold.
  Before reading this value, the interrupt must be reset with $reset-interrupt.
  */
  last-interrupt-was-als-high -> bool:
    return last-reasons_ & ALS-IF-H_ != 0

  /**
  Returns whether the last interrupt was caused by the proximity sensor
    detecting something close.
  Before reading this value, the interrupt must be reset with $reset-interrupt.
  */
  last-interrupt-was-ps-close -> bool:
    return last-reasons_ & PS-IF-CLOSE_ != 0

  /**
  Returns whether the last interrupt was caused by the proximity sensor
    detecting something far away.
  Before reading this value, the interrupt must be reset with $reset-interrupt.
  */
  last-interrupt-was-ps-away -> bool:
    return last-reasons_ & PS-IF-AWAY_ != 0

  /**
  Gets the ID from the device. Is expected to be $DEVICE-ID.
  */
  get-id:
    return read-u16-le_ ID_

  write-masked_ reg/int mask/int value/int -> none:
    if (~mask & value) != 0: throw "Value out of range"
    old := read-u16-le_ reg
    old &= ~mask
    new := old | value
    write-u16-le_ reg new

  static ALS-CONF_      ::= 0x00
  static ALS-THDH_      ::= 0x01
  static ALS-THDL_      ::= 0x02
  static PS-CONF-1-2_   ::= 0x03 // PS_CONF1 is lower, PS_CONF2 is upper.
  static PS-CONF-3-MS_  ::= 0x04 //Lower
  static PS-CANC_       ::= 0x05
  static PS-THDL_       ::= 0x06
  static PS-THDH_       ::= 0x07
  static PS-DATA_       ::= 0x08
  static ALS-DATA_      ::= 0x09
  static WHITE-DATA_    ::= 0x0A
  static INT-FLAG_      ::= 0x0B //Upper
  static ID_            ::= 0x0C

  static FULL-REGISTER-MASK_ ::= 0xffff

  // Masks for the ALS_CONF_ register.
  static ALS-IT-MASK_ ::= 0b1100_0000
  static ALS-IT-SHIFT_ ::= 6
  static ALS-IT-VALUES_ ::= [80, 160, 320, 640]

  static ALS-PERS-MASK_ ::= 0b0000_1100
  static ALS-PERS-SHIFT_ ::= 2
  static ALS-PERS-VALUES_ ::= [1, 2, 4, 8]

  static ALS-INT-EN-MASK_ ::= 0b0000_0010
  static ALS-INT-DISABLE_ ::= 0b0000_0000
  static ALS-INT-ENABLE_ ::= 0b0000_0010

  static ALS-SHUT-DOWN-MASK_ ::= 0b0000_0001
  static ALS-POWER-ON_ ::= 0b0000_0000
  static ALS-SHUT-DOWN_ ::= 0b0000_0001

  // Masks for the low half of the PS_CONF_1_2 register, which is called the
  // PS_CONF1 register in the data sheet.
  static PS-DUTY-MASK_ ::= 0b1100_0000
  static PS-DUTY-SHIFT_ ::= 6
  static PS-DUTY-VALUES_ ::= [40, 80, 160, 320]

  static PS-PERS-MASK_ ::= 0b0011_0000
  static PS-PERS-SHIFT_ ::= 4
  static PS-PERS-OFFSET_ ::= 1

  static PS-IT-MASK_ ::= 0b0000_1110
  static PS-IT-1T   ::= 0b000_0
  static PS-IT-1-5T ::= 0b001_0
  static PS-IT-2T   ::= 0b010_0
  static PS-IT-2-5T ::= 0b011_0
  static PS-IT-3T   ::= 0b100_0
  static PS-IT-3-5T ::= 0b101_0
  static PS-IT-4T   ::= 0b110_0
  static PS-IT-8T   ::= 0b111_0

  static PS-SD-MASK_   ::= 0b0000_0001
  static PS-POWER-ON_  ::= 0b0000_0000
  static PS-SHUT-DOWN_ ::= 0b0000_0001

  // Masks for the high half of the PS_CONF_1_2 register, which is called the
  // PS_CONF2 register in the data sheet.
  static PS-HD-MASK_ ::= 0b0000_1000_0000_0000
  static PS-12-BIT_  ::= 0b0000_0000_0000_0000
  static PS-16-BIT_  ::= 0b0000_1000_0000_0000

  static PS-INT-MASK_         ::= 0b0000_0011_0000_0000
  static PS-INT-NO-TRIGGER    ::= 0b0000_0000_0000_0000
  static PS-INT-CLOSE-TRIGGER ::= 0b0000_0001_0000_0000
  static PS-INT-AWAY-TRIGGER  ::= 0b0000_0010_0000_0000
  static PS-INT-BOTH-TRIGGER  ::= 0b0000_0011_0000_0000

  // Masks for the low half of the PS_CONF_3_MS register, which is called the
  // PS_CONF3 register in the data sheet.
  static PS-SMART-PERS-MASK_ ::= 0b0001_0000
  static PS-SMART-PERS-ON_   ::= 0b0001_0000
  static PS-SMART-PERS-OFF_  ::= 0b0000_0000

  static PS-AF-MASK_ ::= 0b0000_1000
  static PS-AF-ON_   ::= 0b0000_1000
  static PS-AF-OFF_  ::= 0b0000_0000

  static PS-TRIG-MASK_ ::= 0b0000_1000
  static PS-TRIG-ON_   ::= 0b0000_1000

  // Masks for the high half of the PS_CONF_3_MS register, which is called the
  // PS_MS register in the data sheet.
  static PS-WHITE-EN-MASK_ ::= 0b1000_0000_0000_0000
  static PS-WHITE-ENABLE_  ::= 0b1000_0000_0000_0000
  static PS-WHITE-DISABLE_ ::= 0b0000_0000_0000_0000

  static PS-MS-MASK_          ::= 0b0100_0000_0000_0000
  static PS-LOGIC-LEVEL-MODE  ::= 0b0100_0000_0000_0000
  static PS-INTERRUPT-MODE    ::= 0b0000_0000_0000_0000

  static PS-LED-I-MASK_       ::= 0b0000_0111_0000_0000
  static PS-LED-I-SHIFT_      ::= 8
  static PS-LED-I-VALUES_     ::= [50, 75, 100, 120, 140, 160, 180, 200]

  // Masks for the INT_FLAG register.
  static PS-SP-FLAG_   ::= 0b0100_0000_0000_0000
  static ALS-IF-L_     ::= 0b0010_0000_0000_0000
  static ALS-IF-H_     ::= 0b0001_0000_0000_0000
  static PS-IF-CLOSE_  ::= 0b0000_0010_0000_0000
  static PS-IF-AWAY_   ::= 0b0000_0001_0000_0000
