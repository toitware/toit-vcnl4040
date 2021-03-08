// Copyright (C) 2021 Toitware ApS. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found
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
import binary

class Vcnl4040:
  static I2C_ADDRESS ::= 0x60
  static DEVICE_ID ::= 0x186

  registers_/serial.Registers ::= ?

  // TODO: When we have moved to the SDK that supports it, this should just
  // call registers_.read_u16_le.
  read_u16_le_ reg/int -> int:
    ba := registers_.read_bytes reg 2
    return binary.LITTLE_ENDIAN.uint16 ba 0

  // TODO: When we have moved to the SDK that supports it, this should just
  // call registers_.write_u16_le.
  write_u16_le_ reg/int value/int -> none:
    ba := ByteArray 2
    binary.LITTLE_ENDIAN.put_uint16 ba 0 value
    registers_.write_bytes reg ba

  constructor device/serial.Device:
    registers_ = device.registers

  read_als_integration_time -> int:
    return ALS_IT_VALUES_[((read_u16_le_ ALS_CONF_) & ALS_IT_MASK_) >> ALS_IT_SHIFT_]

  /**
  Ambient light sensor integration time. Longer time has higher sensitivity.
  Valid values in ms are 80, 160, 320, or 640.
  */
  set_als_integration_time ms -> none:
    // An appropriate exception will be thrown by write_masked_ if this
    // index_of returns -1.
    value/int := ALS_IT_VALUES_.index_of ms
    write_masked_ ALS_CONF_ ALS_IT_MASK_ value << ALS_IT_SHIFT_

  read_als_persistence -> int:
    return ALS_PERS_VALUES_[((read_u16_le_ ALS_CONF_) & ALS_PERS_MASK_) >> ALS_PERS_SHIFT_]

  /**
  Changes the ambient light sensor interrupt persistence setting.
  This is the number of consecutive hits needed before an interrupt event occurs.
  Valid numbers of required hits are 1, 2, 4, or 8.
  */
  set_als_persistence hits -> none:
    value/int := ALS_PERS_VALUES_.index_of hits
    write_masked_ ALS_CONF_ ALS_PERS_MASK_ value << ALS_PERS_SHIFT_

  read_als_interrupt_enable -> bool:
    return ((read_u16_le_ ALS_CONF_) & ALS_INT_EN_MASK_) == ALS_INT_ENABLE_

  /**
  Ambient light sensor interrupt enable.
  */
  set_als_interrupt_enable value/bool -> none:
    write_masked_
      ALS_CONF_
      ALS_INT_EN_MASK_
      value ? ALS_INT_ENABLE_ : ALS_INT_DISABLE_

  /**
  Whether the ambient light sensor is powered on.
  */
  read_als_power -> bool:
    return ((read_u16_le_ ALS_CONF_) & ALS_SHUT_DOWN_MASK_) == ALS_POWER_ON_

  /**
  Turns the ambient light sensor on or off.
  */
  set_als_power value/bool -> none:
    write_masked_
      ALS_CONF_
      ALS_SHUT_DOWN_MASK_
      value ? ALS_POWER_ON_ : ALS_SHUT_DOWN_

  read_als_high_interrupt_threshold -> int:
    return read_u16_le_ ALS_THDH_

  /**
  Sets high threshold for ambient light sensor.
  The $threshold is a value from 0-65535.  What this means in lux depends on
    the integration time setting.  See table 14 in the data sheet.
  */
  write_als_high_interrupt_threshold threshold/int -> none:
    write_masked_ ALS_THDH_ FULL_REGISTER_MASK_ threshold

  read_als_low_interrupt_threshold -> int:
    return read_u16_le_ ALS_THDL_

  /**
  Sets low threshold for ambient light sensor.
  The $threshold is a value from 0-65535.  What this means in lux depends on
    the integration time setting.  See table 14 in the data sheet.
  */
  write_als_low_interrupt_threshold threshold/int -> none:
    write_masked_ ALS_THDL_ FULL_REGISTER_MASK_ threshold

  read_ps_duty_cycle -> int:
    return PS_DUTY_VALUES_[((read_u16_le_ PS_CONF_1_2_) & PS_DUTY_MASK_) >> PS_DUTY_SHIFT_]

  /**
  Sets proximity sensor infrared on-off duty ratio.
  Valid values in are 40, 80, 160, or 320, indicating ratios of 1/40, 1/80,
    1/160, or 1/320.
  */
  set_ps_duty_cycle ratio/int -> none:
    value/int := PS_DUTY_VALUES_.index_of ratio
    write_masked_ PS_CONF_1_2_ PS_DUTY_MASK_ value << PS_DUTY_SHIFT_

  read_ps_persistence -> int:
    return (((read_u16_le_ PS_CONF_1_2_) & PS_PERS_MASK_) >> PS_PERS_SHIFT_) + PS_PERS_OFFSET_

  /**
  Changes the proximity sensor interrupt persistence setting.
  The number of consecutive hits needed before an interrupt event occurs. Valid
    numbers of hits required are 1, 2, 3, or 4.
  */
  set_ps_persistence hits -> none:
    write_masked_ PS_CONF_1_2_ PS_PERS_MASK_ (hits - PS_PERS_OFFSET_) << PS_PERS_SHIFT_

  /**
  Gets proximity sensor integration time.
  Valid results are: PS_IT_1T, PS_IT_1_5T, PS_IT_2T, PS_IT_2_5T, PS_IT_3T,
    PS_IT_3_5T, PS_IT_4T, and PS_IT_8T.
  */
  read_ps_integration_time -> int:
    return (read_u16_le_ PS_CONF_1_2_) & PS_IT_MASK_

  /**
  Sets proximity sensor integration time.
  Valid values are: PS_IT_1T, PS_IT_1_5T, PS_IT_2T, PS_IT_2_5T, PS_IT_3T,
    PS_IT_3_5T, PS_IT_4T, and PS_IT_8T.
  */
  set_ps_integration_time time/int -> none:
    write_masked_ PS_CONF_1_2_ PS_IT_MASK_ time

  /**
  Whether the proximity sensor is powered on.
  */
  read_ps_power -> bool:
    return ((read_u16_le_ PS_CONF_1_2_) & PS_SD_MASK_) == PS_POWER_ON_

  /**
  Turns the proximity sensor power on or off.
  */
  set_ps_power value/bool -> none:
    write_masked_
      PS_CONF_1_2_
      PS_SD_MASK_
      value ? PS_POWER_ON_ : PS_SHUT_DOWN_

  /**
  Returns the proximity sensor resolution. Returns 12 for 12 bit resolution or
    16 for 16 bit resolution.
  */
  read_ps_resolution -> int:
    value := (read_u16_le_ PS_CONF_1_2_) & PS_HD_MASK_
    return value == PS_12_BIT_ ? 12 : 16

  /**
  Sets proximity sensor resolution.
  Valid values for $bits are 12 and 16.
  */
  set_ps_resolution bits/int -> none:
    if bits != 12 and bits != 16: throw "Value out of range"
    write_masked_ PS_CONF_1_2_ PS_HD_MASK_
      bits == 12 ? PS_12_BIT_ : PS_16_BIT_

  /**
  Gets proximity sensor interrupt trigger condition.
  Valid results are: PS_INT_NO_TRIGGER, PS_INT_CLOSE_TRIGGER,
    PS_INT_AWAY_TRIGGER, PS_INT_BOTH_TRIGGER.
  */
  read_ps_interrupt_trigger -> int:
    return (read_u16_le_ PS_CONF_1_2_) & PS_INT_MASK_

  /**
  Sets proximity sensor interrupt trigger condition.
  Valid values are: PS_INT_NO_TRIGGER, PS_INT_CLOSE_TRIGGER,
    PS_INT_AWAY_TRIGGER, PS_INT_BOTH_TRIGGER.
  */
  set_ps_interrupt_trigger value/int -> none:
    write_masked_ PS_CONF_1_2_ PS_INT_MASK_ value

  read_ps_smart_persistence -> bool:
    return ((read_u16_le_ PS_CONF_3_MS_) & PS_SMART_PERS_MASK_) == PS_SMART_PERS_ON_

  /**
  Enables or disables proximity sensor smart persistence.
  */
  set_ps_smart_persistence value/bool -> none:
    write_masked_
      PS_CONF_3_MS_
      PS_SMART_PERS_MASK_
      value ? PS_SMART_PERS_ON_ : PS_SMART_PERS_OFF_

  read_ps_active_force -> bool:
    return ((read_u16_le_ PS_CONF_3_MS_) & PS_AF_MASK_) == PS_AF_ON_

  /**
  Enables or disables proximity sensor active force mode.
  */
  set_ps_active_force value/bool -> none:
    write_masked_
      PS_CONF_3_MS_
      PS_AF_MASK_
      value ? PS_AF_ON_ : PS_AF_OFF_

  /**
  Proximity sensor active active force trigger. The device resets itself after
    one output cycle.
  */
  ps_active_force_trigger -> none:
    write_masked_
      PS_CONF_3_MS_
      PS_TRIG_MASK_
      PS_TRIG_ON_

  read_ps_white_channel -> bool:
    return ((read_u16_le_ PS_CONF_3_MS_) & PS_WHITE_EN_MASK_) == PS_WHITE_ENABLE_

  /**
  Enables or disables proximity sensor active force mode.
  */
  set_ps_white_channel value/bool -> none:
    write_masked_
      PS_CONF_3_MS_
      PS_WHITE_EN_MASK_
      value ? PS_WHITE_ENABLE_ : PS_WHITE_DISABLE_

  /**
  Gets proximity sensor mode.
  Valid return values are $PS_LOGIC_LEVEL_MODE and $PS_INTERRUPT_MODE.
  */
  read_ps_proximity_mode -> int:
    return (read_u16_le_ PS_CONF_3_MS_) & PS_MS_MASK_

  /**
  Sets proximity sensor mode.
  Valid values are PS_LOGIC_LEVEL_MODE and PS_INTERRUPT_MODE.
  */
  set_ps_proximity_mode value/int -> none:
    write_masked_
      PS_CONF_3_MS_
      PS_MS_MASK_
      value

  read_ps_led_current -> int:
    return PS_LED_I_VALUES_[((read_u16_le_ PS_CONF_3_MS_) & PS_LED_I_MASK_) >> PS_LED_I_SHIFT_]

  /**
  Sets proximity sensor LED current.
  Valid values in mA are 50, 75, 100, 120, 140, 160, 180, and 200.
  */
  set_ps_led_current milli_amps -> none:
    value/int := PS_LED_I_VALUES_.index_of milli_amps
    write_masked_ PS_CONF_3_MS_ PS_LED_I_MASK_ value << PS_LED_I_SHIFT_

  read_ps_cancellation_level -> int:
    return read_u16_le_ PS_CANC_

  /**
  Sets cancellation level for proximity sensor.
  The $level is a value from 0-65535.
  */
  write_ps_cancellation_level level/int -> none:
    write_masked_ PS_CANC_ FULL_REGISTER_MASK_ level

  read_ps_high_interrupt_threshold -> int:
    return read_u16_le_ PS_THDH_

  /**
  Sets high threshold for proximity sensor.
  The $threshold is a value from 0-65535.
  */
  write_ps_high_interrupt_threshold threshold/int -> none:
    write_masked_ PS_THDH_ FULL_REGISTER_MASK_ threshold

  read_ps_low_interrupt_threshold -> int:
    return read_u16_le_ PS_THDL_

  /**
  Setslow threshold for proximity sensor.
  The $threshold is a value from 0-65535.
  */
  write_ps_low_interrupt_threshold threshold/int -> none:
    write_masked_ PS_THDL_ FULL_REGISTER_MASK_ threshold

  /// Reads a value from 0-65535 from the proximity sensor.
  read_ps_data -> int:
    return read_u16_le_ PS_DATA_

  /// Reads a value from 0-65535 from the ambient light sensor.
  read_als_data -> int:
    return read_u16_le_ ALS_DATA_

  /// Reads a value from 0-65535 from the white channel sensor.
  read_white_data -> int:
    return read_u16_le_ WHITE_DATA_

  /**
  Resets the interrupt, and stores a value that indicates
    the reason(s) for the interrupt.
  This is a destructive operation - if you call it twice after an interrupt,
    the second time will overwrite the reasons the reasons. The reasons can be
    interrogated with the last_interrupt* methods.
  */
  reset_interrupt -> none:
    last_reasons_ = read_u16_le_ INT_FLAG_

  last_reasons_/int := 0

  /**
  Returns whether the last interrupt was caused by the proximity sensor
    protection mode.
  Before reading this value, the interrupt must be reset with $reset_interrupt.
  */
  last_interrupt_was_ps_protection_mode -> bool:
    return last_reasons_ & PS_SP_FLAG_ != 0

  /**
  Returns whether the last interrupt was caused by the ambient light sensor
    crossing the low threshold.
  Before reading this value, the interrupt must be reset with $reset_interrupt.
  */
  last_interrupt_was_als_low -> bool:
    return last_reasons_ & ALS_IF_L_ != 0

  /**
  Returns whether the last interrupt was caused by the ambient light sensor
    crossing the high threshold.
  Before reading this value, the interrupt must be reset with $reset_interrupt.
  */
  last_interrupt_was_als_high -> bool:
    return last_reasons_ & ALS_IF_H_ != 0

  /**
  Returns whether the last interrupt was caused by the proximity sensor
    detecting something close.
  Before reading this value, the interrupt must be reset with $reset_interrupt.
  */
  last_interrupt_was_ps_close -> bool:
    return last_reasons_ & PS_IF_CLOSE_ != 0

  /**
  Returns whether the last interrupt was caused by the proximity sensor
    detecting something far away.
  Before reading this value, the interrupt must be reset with $reset_interrupt.
  */
  last_interrupt_was_ps_away -> bool:
    return last_reasons_ & PS_IF_AWAY_ != 0

  /**
  Gets the ID from the device. Is expected to be $DEVICE_ID.
  */
  get_id:
    return read_u16_le_ ID_

  write_masked_ reg/int mask/int value/int -> none:
    if (~mask & value) != 0: throw "Value out of range"
    old := read_u16_le_ reg
    old &= ~mask
    new := old | value
    write_u16_le_ reg new

  static ALS_CONF_      ::= 0x00
  static ALS_THDH_      ::= 0x01
  static ALS_THDL_      ::= 0x02
  static PS_CONF_1_2_   ::= 0x03 // PS_CONF1 is lower, PS_CONF2 is upper.
  static PS_CONF_3_MS_  ::= 0x04 //Lower
  static PS_CANC_       ::= 0x05
  static PS_THDL_       ::= 0x06
  static PS_THDH_       ::= 0x07
  static PS_DATA_       ::= 0x08
  static ALS_DATA_      ::= 0x09
  static WHITE_DATA_    ::= 0x0A
  static INT_FLAG_      ::= 0x0B //Upper
  static ID_            ::= 0x0C

  static FULL_REGISTER_MASK_ ::= 0xffff

  // Masks for the ALS_CONF_ register.
  static ALS_IT_MASK_ ::= 0b1100_0000
  static ALS_IT_SHIFT_ ::= 6
  static ALS_IT_VALUES_ ::= [80, 160, 320, 640]

  static ALS_PERS_MASK_ ::= 0b0000_1100
  static ALS_PERS_SHIFT_ ::= 2
  static ALS_PERS_VALUES_ ::= [1, 2, 4, 8]

  static ALS_INT_EN_MASK_ ::= 0b0000_0010
  static ALS_INT_DISABLE_ ::= 0b0000_0000
  static ALS_INT_ENABLE_ ::= 0b0000_0010

  static ALS_SHUT_DOWN_MASK_ ::= 0b0000_0001
  static ALS_POWER_ON_ ::= 0b0000_0000
  static ALS_SHUT_DOWN_ ::= 0b0000_0001

  // Masks for the low half of the PS_CONF_1_2 register, which is called the
  // PS_CONF1 register in the data sheet.
  static PS_DUTY_MASK_ ::= 0b1100_0000
  static PS_DUTY_SHIFT_ ::= 6
  static PS_DUTY_VALUES_ ::= [40, 80, 160, 320]

  static PS_PERS_MASK_ ::= 0b0011_0000
  static PS_PERS_SHIFT_ ::= 4
  static PS_PERS_OFFSET_ ::= 1

  static PS_IT_MASK_ ::= 0b0000_1110
  static PS_IT_1T   ::= 0b000_0
  static PS_IT_1_5T ::= 0b001_0
  static PS_IT_2T   ::= 0b010_0
  static PS_IT_2_5T ::= 0b011_0
  static PS_IT_3T   ::= 0b100_0
  static PS_IT_3_5T ::= 0b101_0
  static PS_IT_4T   ::= 0b110_0
  static PS_IT_8T   ::= 0b111_0

  static PS_SD_MASK_   ::= 0b0000_0001
  static PS_POWER_ON_  ::= 0b0000_0000
  static PS_SHUT_DOWN_ ::= 0b0000_0001

  // Masks for the high half of the PS_CONF_1_2 register, which is called the
  // PS_CONF2 register in the data sheet.
  static PS_HD_MASK_ ::= 0b0000_1000_0000_0000
  static PS_12_BIT_  ::= 0b0000_0000_0000_0000
  static PS_16_BIT_  ::= 0b0000_1000_0000_0000

  static PS_INT_MASK_         ::= 0b0000_0011_0000_0000
  static PS_INT_NO_TRIGGER    ::= 0b0000_0000_0000_0000
  static PS_INT_CLOSE_TRIGGER ::= 0b0000_0001_0000_0000
  static PS_INT_AWAY_TRIGGER  ::= 0b0000_0010_0000_0000
  static PS_INT_BOTH_TRIGGER  ::= 0b0000_0011_0000_0000

  // Masks for the low half of the PS_CONF_3_MS register, which is called the
  // PS_CONF3 register in the data sheet.
  static PS_SMART_PERS_MASK_ ::= 0b0001_0000
  static PS_SMART_PERS_ON_   ::= 0b0001_0000
  static PS_SMART_PERS_OFF_  ::= 0b0000_0000

  static PS_AF_MASK_ ::= 0b0000_1000
  static PS_AF_ON_   ::= 0b0000_1000
  static PS_AF_OFF_  ::= 0b0000_0000

  static PS_TRIG_MASK_ ::= 0b0000_1000
  static PS_TRIG_ON_   ::= 0b0000_1000

  // Masks for the high half of the PS_CONF_3_MS register, which is called the
  // PS_MS register in the data sheet.
  static PS_WHITE_EN_MASK_ ::= 0b1000_0000_0000_0000
  static PS_WHITE_ENABLE_  ::= 0b1000_0000_0000_0000
  static PS_WHITE_DISABLE_ ::= 0b0000_0000_0000_0000

  static PS_MS_MASK_          ::= 0b0100_0000_0000_0000
  static PS_LOGIC_LEVEL_MODE  ::= 0b0100_0000_0000_0000
  static PS_INTERRUPT_MODE    ::= 0b0000_0000_0000_0000

  static PS_LED_I_MASK_       ::= 0b0000_0111_0000_0000
  static PS_LED_I_SHIFT_      ::= 8
  static PS_LED_I_VALUES_     ::= [50, 75, 100, 120, 140, 160, 180, 200]

  // Masks for the INT_FLAG register.
  static PS_SP_FLAG_   ::= 0b0100_0000_0000_0000
  static ALS_IF_L_     ::= 0b0010_0000_0000_0000
  static ALS_IF_H_     ::= 0b0001_0000_0000_0000
  static PS_IF_CLOSE_  ::= 0b0000_0010_0000_0000
  static PS_IF_AWAY_   ::= 0b0000_0001_0000_0000
