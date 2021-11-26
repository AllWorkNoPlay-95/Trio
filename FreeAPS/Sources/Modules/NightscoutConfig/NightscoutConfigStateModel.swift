import Combine
import SwiftUI

extension NightscoutConfig {
    final class StateModel: BaseStateModel<Provider> {
        @Injected() var keychain: Keychain!

        @Published var url = ""
        @Published var secret = ""
        @Published var message = ""
        @Published var connecting = false
        @Published var isUploadEnabled = false

        @Published var useLocalSource = false
        @Published var localPort: Decimal = 0

        override func subscribe() {
            url = keychain.getValue(String.self, forKey: Config.urlKey) ?? ""
            secret = keychain.getValue(String.self, forKey: Config.secretKey) ?? ""
            isUploadEnabled = settingsManager.settings.isUploadEnabled
            useLocalSource = settingsManager.settings.useLocalGlucoseSource
            localPort = Decimal(settingsManager.settings.localGlucosePort)

            subscribeSetting(\.isUploadEnabled, on: $isUploadEnabled)
            subscribeSetting(\.useLocalGlucoseSource, on: $useLocalSource)
            subscribeSetting(\.localGlucosePort, on: $localPort.map(Int.init))
        }

        func connect() {
            guard let url = URL(string: url) else {
                message = "Invalid URL"
                return
            }
            connecting = true
            message = ""
            provider.checkConnection(url: url, secret: secret.isEmpty ? nil : secret)
                .receive(on: DispatchQueue.main)
                .sink { completion in
                    switch completion {
                    case .finished: break
                    case let .failure(error):
                        self.message = "Error: \(error.localizedDescription)"
                    }
                    self.connecting = false
                } receiveValue: {
                    self.message = "Connected!"
                    self.keychain.setValue(self.url, forKey: Config.urlKey)
                    self.keychain.setValue(self.secret, forKey: Config.secretKey)
                }
                .store(in: &lifetime)
        }

        func delete() {
            keychain.removeObject(forKey: Config.urlKey)
            keychain.removeObject(forKey: Config.secretKey)
            url = ""
            secret = ""
        }
    }
}
