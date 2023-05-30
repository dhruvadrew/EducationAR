//
//  BLE.swift
//  EducationAR
//
//  Created by Dhruva barua on 7/8/22.
//

import Foundation
import CoreBluetooth
import UIKit

//UUIDs for the arduino service and different characteristics in that service like pressure sensor, power switch, and keypad values

let arduinoCBUUID = CBUUID(string: "fd654490-aba5-40eb-b784-23a166312bd6")

let arduinoServiceCBUUID = CBUUID(string: "ee4130ab-85ef-4603-acb4-a2e694ceefcd")
let arduinoPressureStateCharacteristicCBUUID = CBUUID(string: "d06bfecd-8a97-44a1-b761-f3c5228c7bba")
let arduinoPowerStateCharacteristicCBUUID = CBUUID(string: "aedd045b-8cc0-421f-87af-b8e4d1be4a97")
let arduinoKeypadStateCharacteristicCBUUID = CBUUID(string: "56759d86-59f1-4345-b688-aa3317b91ff1")

class BLEController: UIViewController {
    
    @IBOutlet weak var BluetoothStatus: UILabel!
    
    @IBOutlet weak var label1: UILabel! //invisible labels for debugging
    
    var arduinoPeripheral: CBPeripheral! // peripheral is the device sending data, the arudino in this case
    
  var centralManager: CBCentralManager! //the app or phone is the central device
    
    //load view if view is on
  override func viewDidLoad() {
      centralManager = CBCentralManager(delegate: self, queue: nil) //when view loads, load up a centralManager
      super.viewDidLoad()
  }
}

//Manage the central device (the iPhone), scan for the arduino and get its service using its advertised UUIDs to then find the characteristics with data inside that service using their the characteristics' UUIDs.

extension BLEController: CBCentralManagerDelegate {
    //checks if phone is powered on
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
      switch central.state {
        case .unknown:
          print("central.state is .unknown")
        case .resetting:
          print("central.state is .resetting")
        case .unsupported:
          print("central.state is .unsupported")
        case .unauthorized:
          print("central.state is .unauthorized")
        case .poweredOff:
          print("central.state is .poweredOff")
        case .poweredOn:
          print("central.state is .poweredOn")
          centralManager.scanForPeripherals(withServices: [arduinoCBUUID]) //scan for the arduino peripheral device
      }
  }
    
    //did find arduino, connect to it
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
      print(peripheral)
        //it has discovered the arduino and is connecting
      arduinoPeripheral = peripheral
      arduinoPeripheral.delegate = self;
      centralManager.stopScan() //stop searching for peripherals
      centralManager.connect(arduinoPeripheral) //connect to arduino
    }
    
    //connected to arduino, find its services
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
      print("Connected!")
      BluetoothStatus.text = "Connected"
      arduinoPeripheral.discoverServices([arduinoServiceCBUUID]) //discover the service that the arduino is sending
    }
  }

//found its service(s), find its characteristics

extension BLEController: CBPeripheralDelegate {
  func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
    
    guard let services = peripheral.services else { return }
    
    for service in services {
      print(service)
      peripheral.discoverCharacteristics(nil, for: service) //find the various characteristics in the arduino service
    }
  }
    
    //did find characteristics, read value for each characteristic and set their notify value to true to notify us when data is changed
  
  func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
    guard let characteristics = service.characteristics else { return }

    for characteristic in characteristics {
      print(characteristic)
      if characteristic.properties.contains(.read) {
        print("\(characteristic.uuid): properties contains .read")
        peripheral.readValue(for: characteristic)
      }
      if characteristic.properties.contains(.notify) {
        print("\(characteristic.uuid): properties contains .notify")
        peripheral.setNotifyValue(true, for: characteristic)
      }
      if characteristic.properties.contains(.write) {
        print("\(characteristic.uuid): properties contains .write")
      }
        //debugging and setting read and notify properties for the characteristics to true to be able to read the data
    }
  }
    
    //when characteristic(s) update value, check which characteristic it is, using their UUID, and either calling the keypad, pressure sensor, or power switch respective methods in the other class.
  func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
    switch characteristic.uuid {
        case arduinoKeypadStateCharacteristicCBUUID: //if the keypad value updates, it sends it here to the method
            var keypadStatus = keypadState(from: characteristic)
            readPad(input: keypadStatus)
        case arduinoPressureStateCharacteristicCBUUID: // if the arduino pressure value updates, sends it here to the method
            var pressureStatus = pressureState(from: characteristic)
            readPressure(input: Float(pressureStatus))
        case arduinoPowerStateCharacteristicCBUUID: //if power switch changes, data goes here into this method
            var powerStatus = powerState(from: characteristic)
            readPower(input: powerStatus)
        default:
          print("Unhandled Characteristic UUID: \(characteristic.uuid)")
      }
  }
    
    //convert Data (Apple makes characteristic info from arduino into a type of data called "Data") to string
    private func powerState(from characteristic: CBCharacteristic) -> String { //reads data, converts Data type to String type and if recieves "N" from Arduino, it means switch is On, thus returning it, if "F" then off thus returning off, this powerState goes into the readPower in viewController
        guard let characteristicData = String(bytes: characteristic.value!, encoding: String.Encoding.utf8),
        let byte = characteristicData.first else { return "Error"}
        
        switch byte {
            case "N":
                return "ON"
            case "F":
                return "OFF"
            default:
                return "OFF"
        }
    }
    
    //convert Data (Apple makes characteristic info from arduino into a type of data called "Data") to Float
    
    private func pressureState(from characteristic: CBCharacteristic) -> Float {
        guard let characteristicData = characteristic.value,
              let byte = characteristicData.to(type: Float.self) else { return 33.0 } // converts Data to Float using Data extension at the bottom of this file
        
        return byte
    }
    
    
    // converts Data into string and returns it to public function in ViewController to be manipulated
  private func keypadState(from characteristic: CBCharacteristic) -> String {
        guard let characteristicData = String(bytes: characteristic.value!, encoding: String.Encoding.utf8),
              let byte = characteristicData.first else { return "Error"}
        
        switch byte {
            case "0":
                return "0"
            case "1":
                return "1"
            case "2":
                return "2"
            case "3":
                return "3"
            case "4":
                return "4"
            case "5":
                return "5"
            case "6":
                return "6"
            case "7":
                return "7"
            case "8":
                return "8"
            case "9":
                return "9"
            case "A":
                return "A"
            case "B":
                return "B"
            case "C":
                    return "C"
            case "D":
                return "D"
            case "*":
                return "*"
            case "#":
                return "#"
            default:
                return "Reserved for future use"
        }
    }
    
    //if iphone disconnects from arduino via bluetooth....
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Device Disconnected.")
        BluetoothStatus.text = "Disconnected"
    } // if disconnected
}

//data extension to convert data type values from Data to simple data types (not arrays and the like)
extension Data {

    init<T>(from value: T) {
        self = Swift.withUnsafeBytes(of: value) { Data($0) }
    }

    func to<T>(type: T.Type) -> T? where T: ExpressibleByIntegerLiteral {
        var value: T = 0
        guard count >= MemoryLayout.size(ofValue: value) else { return nil }
        _ = Swift.withUnsafeMutableBytes(of: &value, { copyBytes(to: $0)} )
        return value
    }
}

