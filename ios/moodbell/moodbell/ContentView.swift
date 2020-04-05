import SwiftUI

struct ContentView: View {
  @EnvironmentObject var state: MoodbellState
  @State var message = ""

  var body: some View {
    VStack {
      TextField("Put your message here", text: $message) {
        self.state.setText(self.message)
      }.padding()
      Spacer()
      Text(state.ringing ? "🔔🔔🔔" : " ").padding()
      Spacer()
      LedSwitchesArrayView()
      Spacer()
      Text(state.connection).padding()
    }.padding()
  }
}

struct LedSwitchesArrayView: View {
  @EnvironmentObject var state: MoodbellState

  var body: some View {
    HStack(spacing: 25) {
      ForEach(StateLed.allCases.reversed(), id: \.self) { led in
        LedSwitchView(color: led.color, value: self.state.bindLedValue(led))
      }
    }
  }
}

struct LedSwitchView: View {
  let color: Color
  @Binding var value: Int

  var body: some View {
    Button(action: {
      self.value = self.value == 0 ? 255 : 0
    }, label: {
      Circle().fill(color).frame(width: 60, height: 60).opacity(value > 0 ? 1.0 : 0.3)
    })
  }
}

extension MoodbellState {
  func bindLedValue(_ led: StateLed) -> Binding<Int> {
    Binding(get: {
      self.leds[led] ?? 0
    }, set: { value in
      self.setLed(led, value: value)
    })
  }
}

extension StateLed {
  var color: Color {
    switch self {
    case .red:
      return .red
    case .yellow:
      return .yellow
    case .green:
      return .green
    case .blue:
      return .blue
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView().environmentObject(MoodbellState())
  }
}

