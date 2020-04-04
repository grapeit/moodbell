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
      Text(state.connection)
      Spacer()
    }.padding()
  }
}

struct LedSwitchesArrayView: View {
  var body: some View {
    HStack(spacing: 25) {
      ForEach(StateLed.allCases.reversed(), id: \.self) { led in
        LedSwitchView(led: led)
      }
    }
  }
}

struct LedSwitchView: View {
  @EnvironmentObject var state: MoodbellState
  @State private var on = false

  let led: StateLed

  var body: some View {
    Button(action: {
      self.on.toggle()
      self.state.setLed(self.led, value: self.on ? 255 : 0)
    }, label: {
      Circle().fill(led.color).frame(width: 60, height: 60).opacity(self.on ? 1.0 : 0.3)
    })
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView().environmentObject(MoodbellState())
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
