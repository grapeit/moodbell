import AVFoundation

class MoodbellState: ObservableObject {
  @Published var connectionStatus = ""
  @Published var backlight: Double = 0.5 {
    didSet {
      setBacklight(backlight)
    }
  }
  @Published var textMessage: String = "" {
    didSet {
      self.setTextMessage(self.textMessage)
    }
  }
  @Published var lightSensor = 0.0
  @Published var ringing = false
  @Published var leds = [StateLed: Double]()

  private let ringSystemSoundId = SystemSoundID(1005)
  private let ringDurationSec = 2.0

  private let btConnection = BtConnection()
  private var dataCollected = Data()

  init() {
    btConnection.delegate = self
    btConnection.start()
  }

  func setBacklight(_ value: Double) {
    sendCommand("BACK \(value.to256Range())")
  }

  func setTextMessage(_ text: String) {
    sendCommand("TXT " + text.replacingOccurrences(of: "’", with: "'"))
  }

  func setLed(_ led: StateLed, value: Double) {
    leds[led] = value
    sendCommand("LED \(led.rawValue) \(value.to256Range())")
  }

  private func sendCommand(_ command: String) {
    let toSend = command + "\n"
    guard let data = toSend.data(using: .utf8) else {
      return
    }
    btConnection.send(data)
  }

  private func processInput(_ input: String) {
    print(input)
    if input.starts(with: "MOODBELL ") {
      handshake(input)
    } else if input.starts(with: "LIGHT ") {
      if let value = Int(input[input.index(input.startIndex, offsetBy: 6)...]) {
        light(value)
      }
    } else if input == "RING" {
      ring()
    }
  }

  private func handshake(_ input: String) {
    connectionStatus = "ready"
    setBacklight(backlight)
    setTextMessage(textMessage)
    leds.forEach { (led, value) in
      setLed(led, value: value)
    }
  }

  private func light(_ value: Int) {
    lightSensor = Double(value) / 1024.0
  }

  private func ring() {
    guard !ringing else {
      return
    }
    ringing = true
    AudioServicesPlaySystemSound(ringSystemSoundId)
    Timer.scheduledTimer(withTimeInterval: ringDurationSec, repeats: false) { [weak self] _ in self?.ringing = false }
  }
}

extension MoodbellState: BtConnectionDelegate {
  func status(_ status: String) {
    connectionStatus = status
    if status == "connected" {
      sendCommand("HELLO")
    } else {
      lightSensor = 0.0
    }
  }

  func update(_ data: Data) {
    dataCollected += data
    while let i = dataCollected.firstIndex(of: UInt8(0x0A)) { // 0x0A = `\n`
      if var input = String(data: dataCollected[..<i], encoding: .ascii) {
        if input.last == "\r" {
          input.removeLast()
        }
        processInput(input)
      }
      dataCollected = dataCollected[dataCollected.index(i, offsetBy: 1)...]
    }
  }
}

extension Double {
  func to256Range() -> Int {
    return Int((self * 255).rounded())
  }
}

enum StateLed: String, CaseIterable {
  case red = "R"
  case yellow = "Y"
  case green = "G"
  case blue = "B"
}
