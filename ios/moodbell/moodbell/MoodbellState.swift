import AVFoundation

class MoodbellState: ObservableObject {
  @Published var connection = ""
  @Published var ringing = false

  private let ringSystemSoundId = SystemSoundID(1005)
  private let ringDurationSec = 2.0

  private let btConnection = BtConnection()
  private var dataCollected = Data()

  init() {
    btConnection.delegate = self
    btConnection.start()
  }

  func setText(_ text: String) {
    sendCommand("TXT " + text.replacingOccurrences(of: "’", with: "'"))
  }

  func setLed(_ led: StateLed, value: Int) {
    sendCommand("LED \(led.rawValue) \(value)")
  }

  private func sendCommand(_ command: String) {
    let toSend = command + "\n"
    guard let data = toSend.data(using: .utf8) else {
      return
    }
    btConnection.send(data)
  }

  private func processInput(_ input: String) {
    if input == "RING" {
      ring()
    }
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
    connection = status
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

enum StateLed: String, CaseIterable {
  case red = "R"
  case yellow = "Y"
  case green = "G"
  case blue = "B"
}
