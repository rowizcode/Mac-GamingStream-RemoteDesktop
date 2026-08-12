/**
 * @file src/platform/macos/hid_gamepad.m
 * @brief Xbox-compatible IOHIDUserDevice backend for Moonlight controller
 *        input on macOS.
 */
#import "hid_gamepad.h"
#import <mach/mach_time.h>

#define SF_DPAD_UP      0x0001
#define SF_DPAD_DOWN    0x0002
#define SF_DPAD_LEFT    0x0004
#define SF_DPAD_RIGHT   0x0008
#define SF_START        0x0010
#define SF_BACK         0x0020
#define SF_LEFT_STICK   0x0040
#define SF_RIGHT_STICK  0x0080
#define SF_LEFT_BUTTON  0x0100
#define SF_RIGHT_BUTTON 0x0200
#define SF_HOME         0x0400
#define SF_A            0x1000
#define SF_B            0x2000
#define SF_X            0x4000
#define SF_Y            0x8000

/* Xbox-compatible HID report descriptor adapted from the Lumen macOS backend. */
static const uint8_t kHIDReportDescriptor[] = {
  0x05, 0x01, 0x09, 0x05, 0xa1, 0x01, 0x85, 0x01, 0x09, 0x01, 0xa1, 0x00,
  0x09, 0x30, 0x09, 0x31, 0x15, 0x00, 0x27, 0xff, 0xff, 0x00, 0x00, 0x95,
  0x02, 0x75, 0x10, 0x81, 0x02, 0xc0, 0x09, 0x01, 0xa1, 0x00, 0x09, 0x33,
  0x09, 0x34, 0x15, 0x00, 0x27, 0xff, 0xff, 0x00, 0x00, 0x95, 0x02, 0x75,
  0x10, 0x81, 0x02, 0xc0, 0x05, 0x01, 0x09, 0x32, 0x15, 0x00, 0x26, 0xff,
  0x03, 0x95, 0x01, 0x75, 0x0a, 0x81, 0x02, 0x15, 0x00, 0x25, 0x00, 0x75,
  0x06, 0x95, 0x01, 0x81, 0x03, 0x05, 0x01, 0x09, 0x35, 0x15, 0x00, 0x26,
  0xff, 0x03, 0x95, 0x01, 0x75, 0x0a, 0x81, 0x02, 0x15, 0x00, 0x25, 0x00,
  0x75, 0x06, 0x95, 0x01, 0x81, 0x03, 0x05, 0x01, 0x09, 0x39, 0x15, 0x01,
  0x25, 0x08, 0x35, 0x00, 0x46, 0x3b, 0x01, 0x66, 0x14, 0x00, 0x75, 0x04,
  0x95, 0x01, 0x81, 0x42, 0x75, 0x04, 0x95, 0x01, 0x15, 0x00, 0x25, 0x00,
  0x35, 0x00, 0x45, 0x00, 0x65, 0x00, 0x81, 0x03, 0x05, 0x09, 0x19, 0x01,
  0x29, 0x0a, 0x15, 0x00, 0x25, 0x01, 0x75, 0x01, 0x95, 0x0a, 0x81, 0x02,
  0x15, 0x00, 0x25, 0x00, 0x75, 0x06, 0x95, 0x01, 0x81, 0x03, 0x05, 0x01,
  0x09, 0x80, 0x85, 0x02, 0xa1, 0x00, 0x09, 0x85, 0x15, 0x00, 0x25, 0x01,
  0x95, 0x01, 0x75, 0x01, 0x81, 0x02, 0x15, 0x00, 0x25, 0x00, 0x75, 0x07,
  0x95, 0x01, 0x81, 0x03, 0xc0, 0x05, 0x0f, 0x09, 0x21, 0x85, 0x03, 0xa1,
  0x02, 0x09, 0x97, 0x15, 0x00, 0x25, 0x01, 0x75, 0x04, 0x95, 0x01, 0x91,
  0x02, 0x15, 0x00, 0x25, 0x00, 0x75, 0x04, 0x95, 0x01, 0x91, 0x03, 0x09,
  0x70, 0x15, 0x00, 0x25, 0x64, 0x75, 0x08, 0x95, 0x04, 0x91, 0x02, 0x09,
  0x50, 0x66, 0x01, 0x10, 0x55, 0x0e, 0x15, 0x00, 0x26, 0xff, 0x00, 0x75,
  0x08, 0x95, 0x01, 0x91, 0x02, 0x09, 0xa7, 0x15, 0x00, 0x26, 0xff, 0x00,
  0x75, 0x08, 0x95, 0x01, 0x91, 0x02, 0x65, 0x00, 0x55, 0x00, 0x09, 0x7c,
  0x15, 0x00, 0x26, 0xff, 0x00, 0x75, 0x08, 0x95, 0x01, 0x91, 0x02, 0xc0,
  0x85, 0x04, 0x05, 0x06, 0x09, 0x20, 0x15, 0x00, 0x26, 0xff, 0x00, 0x75,
  0x08, 0x95, 0x01, 0x81, 0x02, 0xc0, 0x00
};

static NSDictionary *deviceProperties(BOOL includeIdentity, int index) {
    NSMutableDictionary *props = [@{
        @"PrimaryUsagePage": @1,
        @"PrimaryUsage": @5,
        @"VendorID": @(0x045e),
        @"ProductID": @(0x02fd),
        @"VersionNumber": @(0x0903),
        @"Manufacturer": @"Microsoft",
        @"Product": @"Xbox Wireless Controller",
        @"Transport": @"Bluetooth",
        @"ReportDescriptor": [NSData dataWithBytes:kHIDReportDescriptor length:sizeof(kHIDReportDescriptor)]
    } mutableCopy];
    if (includeIdentity) {
        props[@"SerialNumber"] = [NSString stringWithFormat:@"SUNSHINE-XBOX-%d", index];
    }
    return props;
}

static uint16_t axisValue(int16_t value, BOOL invert) {
    int32_t adjusted = invert ? -(int32_t)value : (int32_t)value;
    if (adjusted > INT16_MAX) adjusted = INT16_MAX;
    return (uint16_t)MIN(adjusted + 32768, 65534);
}

static uint16_t triggerValue(uint8_t value) {
    return (uint16_t)(((uint32_t)value * 1023u + 127u) / 255u);
}

static uint8_t dpadValue(uint32_t buttons) {
    BOOL up = (buttons & SF_DPAD_UP) != 0;
    BOOL down = (buttons & SF_DPAD_DOWN) != 0;
    BOOL left = (buttons & SF_DPAD_LEFT) != 0;
    BOOL right = (buttons & SF_DPAD_RIGHT) != 0;
    if (up && right) return 2;
    if (down && right) return 4;
    if (down && left) return 6;
    if (up && left) return 8;
    if (up) return 1;
    if (right) return 3;
    if (down) return 5;
    if (left) return 7;
    return 0;
}

static uint16_t buttonValue(uint32_t sf) {
    uint16_t result = 0;
    if (sf & SF_A) result |= 1u << 0;
    if (sf & SF_B) result |= 1u << 1;
    if (sf & SF_X) result |= 1u << 2;
    if (sf & SF_Y) result |= 1u << 3;
    if (sf & SF_LEFT_BUTTON) result |= 1u << 4;
    if (sf & SF_RIGHT_BUTTON) result |= 1u << 5;
    if (sf & SF_START) result |= 1u << 6;
    if (sf & SF_BACK) result |= 1u << 7;
    if (sf & SF_LEFT_STICK) result |= 1u << 8;
    if (sf & SF_RIGHT_STICK) result |= 1u << 9;
    return result;
}

@implementation HIDGamepad

+ (BOOL)isAvailable {
    IOHIDUserDeviceRef probe = IOHIDUserDeviceCreateWithProperties(
        kCFAllocatorDefault, (__bridge CFDictionaryRef)deviceProperties(NO, 0), 0);
    if (!probe) return NO;
    CFRelease(probe);
    return YES;
}

- (instancetype)initWithIndex:(int)index {
    self = [super init];
    if (self) {
        _gamepadIndex = index;
        _isConnected = NO;
        _homePressed = NO;
        _hidDevice = NULL;
        _hidQueue = nil;
    }
    return self;
}

- (void)dealloc {
    [self disconnect];
    [super dealloc];
}

- (BOOL)createDevice {
    if (_hidDevice) return YES;

    NSString *label = [NSString stringWithFormat:@"com.sunshine.hid.gamepad.%d", _gamepadIndex];
    dispatch_queue_attr_t attr = dispatch_queue_attr_make_with_qos_class(
        DISPATCH_QUEUE_SERIAL, QOS_CLASS_USER_INTERACTIVE, 0);
    _hidQueue = dispatch_queue_create(label.UTF8String, attr);
    _hidDevice = IOHIDUserDeviceCreateWithProperties(
        kCFAllocatorDefault, (__bridge CFDictionaryRef)deviceProperties(YES, _gamepadIndex), 0);
    if (!_hidDevice) {
        _hidQueue = nil;
        NSLog(@"[HIDGamepad] Failed to create Xbox IOHIDUserDevice %d", _gamepadIndex);
        return NO;
    }

    IOHIDUserDeviceSetDispatchQueue(_hidDevice, _hidQueue);
    IOHIDUserDeviceActivate(_hidDevice);
    _isConnected = YES;

    HIDGamepadReport report = {0};
    report.reportId = 1;
    report.leftStickX = report.leftStickY = 0x8000;
    report.rightStickX = report.rightStickY = 0x8000;
    IOReturn status = IOHIDUserDeviceHandleReportWithTimeStamp(
        _hidDevice, mach_absolute_time(), (const uint8_t *)&report, sizeof(report));
    if (status != kIOReturnSuccess) {
        NSLog(@"[HIDGamepad] Initial Xbox report failed for %d (0x%x)", _gamepadIndex, status);
    }
    NSLog(@"[HIDGamepad] Gamepad %d created as Xbox Wireless Controller (Lumen profile)", _gamepadIndex);
    return YES;
}

- (void)updateState:(uint32_t)buttons
         leftStickX:(int16_t)lsX
         leftStickY:(int16_t)lsY
        rightStickX:(int16_t)rsX
        rightStickY:(int16_t)rsY
        leftTrigger:(uint8_t)lt
       rightTrigger:(uint8_t)rt {
    if (!_isConnected || !_hidDevice) return;

    HIDGamepadReport report = {0};
    report.reportId = 1;
    report.leftStickX = axisValue(lsX, NO);
    report.leftStickY = axisValue(lsY, YES);
    report.rightStickX = axisValue(rsX, NO);
    report.rightStickY = axisValue(rsY, YES);
    report.leftTrigger = triggerValue(lt);
    report.rightTrigger = triggerValue(rt);
    report.hatSwitch = dpadValue(buttons);
    report.buttons = buttonValue(buttons);
    IOReturn status = IOHIDUserDeviceHandleReportWithTimeStamp(
        _hidDevice, mach_absolute_time(), (const uint8_t *)&report, sizeof(report));
    if (status != kIOReturnSuccess) {
        NSLog(@"[HIDGamepad] Xbox report failed for %d (0x%x)", _gamepadIndex, status);
    }

    BOOL home = (buttons & SF_HOME) != 0;
    if (home != _homePressed) {
        const uint8_t homeReport[2] = {2, (uint8_t)(home ? 1 : 0)};
        status = IOHIDUserDeviceHandleReportWithTimeStamp(
            _hidDevice, mach_absolute_time(), homeReport, sizeof(homeReport));
        if (status != kIOReturnSuccess) {
            NSLog(@"[HIDGamepad] Home report failed for %d (0x%x)", _gamepadIndex, status);
        }
        _homePressed = home;
    }
}

- (void)disconnect {
    if (!_hidDevice) return;
    _isConnected = NO;
    IOHIDUserDeviceRef device = _hidDevice;
    dispatch_queue_t queue = _hidQueue;
    _hidDevice = NULL;
    if (queue) {
        dispatch_semaphore_t sem = dispatch_semaphore_create(0);
        IOHIDUserDeviceSetCancelHandler(device, ^{
            CFRelease(device);
            dispatch_semaphore_signal(sem);
        });
        IOHIDUserDeviceCancel(device);
        dispatch_semaphore_wait(sem, dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC));
        _hidQueue = nil;
    } else {
        CFRelease(device);
    }
    NSLog(@"[HIDGamepad] Gamepad %d disconnected", _gamepadIndex);
}

@end
