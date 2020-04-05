import SwiftUI

struct ContentView: View {
  @EnvironmentObject var state: MoodbellState

  var body: some View {
    VStack {
      TextField("Put your message here", text: $state.textMessage)
        .modifier(ClearButton(text: $state.textMessage))
        .padding()
      Spacer()
      Slider(value: $state.backlight, in: 0.0...1.0, step: 0.005).padding()
      Spacer()
      Text(state.ringing ? "🔔🔔🔔" : " ").padding()
      Spacer()
      if state.lightSensor > 0 {
        AmbientLightIndicatorView(value: $state.lightSensor)
      } else {
        AmbientLightIndicatorView(value: $state.lightSensor).hidden()
      }
      Spacer()
      LedSwitchesArrayView()
      Text(state.connectionStatus).padding()
    }.padding()
  }
}

struct AmbientLightIndicatorView: View {
  @Binding var value: Double

  var body: some View {
    ZStack {
      Circle()
        .fill(Color(red: 0.2, green: 0.2, blue: 0.0))
        .brightness(value)
        .overlay(Circle().stroke(Color.primary, lineWidth: 1))
      Text(String(format: "%.0f%%", value * 100.0))
        .foregroundColor(value >= 0.33 ? Color.black : Color.white)
    }.frame(width: 80, height: 80)
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
  @Binding var value: Double

  var body: some View {
    Button(action: {
      self.value = self.value == 0.0 ? 1.0 : 0.0
    }, label: {
      Circle()
        .fill(color)
        .frame(width: 60, height: 60).opacity(value > 0.0 ? 1.0 : 0.3)
        .overlay(Circle().stroke(Color.primary, lineWidth: 0.5))
    })
  }
}

struct ClearButton: ViewModifier {
    @Binding var text: String

    public func body(content: Content) -> some View {
        HStack {
            content
            Spacer()
            Image(systemName: "multiply.circle.fill")
              .foregroundColor(.secondary)
              .opacity(text.isEmpty ? 0 : 0.5)
              .onTapGesture { self.text = "" }
        }
    }
}

extension MoodbellState {
  func bindLedValue(_ led: StateLed) -> Binding<Double> {
    Binding(get: {
      self.leds[led] ?? 0.0
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
