This is the BLEKit Firmware repository.

There are 4 firmware projects here. 

* starter
The base BLEKit code base. It is a simple firmware load to get your BLE-113 device started.

* BLEKitRC
Basic Remote Control BLEKit with 4 PWM channels, and several peripherals such as GPIOs, ADCs, and more.

* CarBeacon
An iBeacon with BLEKit capabilities, that senses car battery voltage changes and turns the iBeacon on when
the car is turned off.

* iBeacon
A simple iBeacon project

# Building

You should be familiar with the [Bluegiga](http://bluegiga.com) toolset for Bluetooth Smart. 
Use `bgbuild` to build and flash the firmware to your BLEKit board.
