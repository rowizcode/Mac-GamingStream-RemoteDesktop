/**
 * @file src/platform/macos/hid_gamepad.h
 * @brief Xbox-compatible virtual HID gamepad for macOS.
 */
#pragma once

#import <Foundation/Foundation.h>
#import <IOKit/hidsystem/IOHIDUserDevice.h>

/** 16-byte input report used by the tested Xbox-compatible macOS profile. */
typedef struct __attribute__((packed)) {
    uint8_t reportId;       // 1
    uint16_t leftStickX;    // unsigned, neutral 0x8000
    uint16_t leftStickY;    // unsigned and Y-inverted, neutral 0x8000
    uint16_t rightStickX;   // unsigned, neutral 0x8000
    uint16_t rightStickY;   // unsigned and Y-inverted, neutral 0x8000
    uint16_t leftTrigger;   // 0..1023
    uint16_t rightTrigger;  // 0..1023
    uint8_t hatSwitch;      // 0 neutral, 1..8 clockwise from north
    uint16_t buttons;       // Xbox ABXY/LB/RB/Menu/View/L3/R3 layout
} HIDGamepadReport;

_Static_assert(sizeof(HIDGamepadReport) == 16, "Xbox HID input report must be 16 bytes");

@interface HIDGamepad : NSObject

@property(nonatomic, assign) int gamepadIndex;
@property(nonatomic, assign) BOOL isConnected;
@property(nonatomic, assign) BOOL homePressed;
@property(nonatomic, assign) IOHIDUserDeviceRef hidDevice;
@property(nonatomic, strong) dispatch_queue_t hidQueue;

+ (BOOL)isAvailable;
- (instancetype)initWithIndex:(int)index;
- (BOOL)createDevice;
- (void)updateState:(uint32_t)buttons
         leftStickX:(int16_t)lsX
         leftStickY:(int16_t)lsY
        rightStickX:(int16_t)rsX
        rightStickY:(int16_t)rsY
        leftTrigger:(uint8_t)lt
       rightTrigger:(uint8_t)rt;
- (void)disconnect;

@end
