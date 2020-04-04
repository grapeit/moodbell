import Foundation
import CoreBluetooth

protocol BtConnectionDelegate: class {
  func status(_ status: String)
  func update(_ data: Data)
}

class BtConnection: NSObject {
  private let deviceName = "doorbell"
  private let serviceId = CBUUID(string: "FFE0")
  private let characteristicId = CBUUID(string: "FFE1")
  private let retryInterval = 2.0

  private var manager: CBCentralManager!
  private var peripheral: CBPeripheral!
  private var characteristic: CBCharacteristic!

  private(set) var connected = false

  weak var delegate: BtConnectionDelegate?

  func start() {
    manager = CBCentralManager(delegate: self, queue: nil)
  }

  func send(_ data: Data) {
    guard peripheral != nil && characteristic != nil else {
      return
    }
    peripheral.writeValue(data, for: characteristic, type: CBCharacteristicWriteType.withoutResponse)
  }

  private func onConnectionFailed(_ error: String) {
    connected = false
    delegate?.status("connection failed: " + error)
    characteristic = nil
    peripheral = nil
    Timer.scheduledTimer(withTimeInterval: retryInterval, repeats: false) {_ in
      if self.manager.state == CBManagerState.poweredOn {
        self.delegate?.status("searching for device")
        self.manager.scanForPeripherals(withServices: [self.serviceId], options: nil)
      }
    }
  }
}

extension BtConnection: CBCentralManagerDelegate {
  func centralManagerDidUpdateState(_ central: CBCentralManager) {
    if central.state == CBManagerState.poweredOn {
      central.scanForPeripherals(withServices: [serviceId], options: nil)
      delegate?.status("searching for device")
    } else {
      self.characteristic = nil
      self.peripheral = nil
      delegate?.status("bluetooth is not available")
    }
  }

  func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
    let device = (advertisementData as NSDictionary).object(forKey: CBAdvertisementDataLocalNameKey) as? NSString
    if device?.isEqual(to: deviceName) == true {
      manager.stopScan()
      self.peripheral = peripheral
      self.peripheral.delegate = self
      delegate?.status("connecting (stage 1 of 3)")
      manager.connect(peripheral, options: nil)
    }
  }

  func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
    delegate?.status("connecting (stage 2 of 3)")
    peripheral.discoverServices([serviceId])
  }

  func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
    onConnectionFailed("failed to connect")
  }

  func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
    onConnectionFailed("device disconnected")
  }
}

extension BtConnection: CBPeripheralDelegate {
  func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
    for service in peripheral.services! where service.uuid == serviceId {
      peripheral.discoverCharacteristics(nil, for: service)
      delegate?.status("connecting (stage 3 of 3)")
      return
    }
    onConnectionFailed("requred service is not found")
  }

  func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
    for characteristic in service.characteristics! where characteristic.uuid == characteristicId {
      self.characteristic = characteristic
      peripheral.setNotifyValue(true, for: characteristic)
      connected = true
      delegate?.status("connected")
      return
    }
    onConnectionFailed("required characteristic not found")
  }

  func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
    if characteristic.uuid == characteristicId, let data = characteristic.value {
      delegate?.update(data)
    }
  }
}
