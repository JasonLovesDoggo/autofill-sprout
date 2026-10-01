import AppKit
import AuthenticationServices

final class Probe: NSObject, NSApplicationDelegate {
    let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 630, height: 300), styleMask: [.titled, .closable], backing: .buffered, defer: false)
    let status = NSTextField(wrappingLabelWithString: "No vault data. Synthetic signing and activation experiment.")

    override init() {
        super.init()
        window.title = "AutoFill Sprout 🌱"
        status.frame = NSRect(x: 24, y: 110, width: 580, height: 140)
        status.maximumNumberOfLines = 8
        window.contentView?.addSubview(status)
        let actions: [(String, Selector)] = [
            ("Check store", #selector(checkStore)),
            ("Request activation", #selector(activate)),
            ("Publish test identity", #selector(publishIdentity))
        ]
        for (index, action) in actions.enumerated() {
            let button = NSButton(title: action.0, target: self, action: action.1)
            button.frame = NSRect(x: 24 + index * 195, y: 45, width: 185, height: 36)
            window.contentView?.addSubview(button)
        }
        window.center()
        window.makeKeyAndOrderFront(nil)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    func show(_ text: String) {
        DispatchQueue.main.async { self.status.stringValue = text }
    }

    @objc func checkStore() {
        ASCredentialIdentityStore.shared.getState { state in
            self.show("Identity store enabled: \(state.isEnabled)\nIncremental updates: \(state.supportsIncrementalUpdates)")
        }
    }

    @objc func activate() {
        ASSettingsHelper.requestToTurnOnCredentialProviderExtension { enabled in
            self.show("Activation API result: \(enabled)")
        }
    }

    @objc func publishIdentity() {
        let identity = ASPasswordCredentialIdentity(
            serviceIdentifier: ASCredentialServiceIdentifier(identifier: "http://localhost:9876", type: .URL),
            user: "synthetic-user",
            recordIdentifier: "probe-login"
        )
        ASCredentialIdentityStore.shared.saveCredentialIdentities([identity]) { success, error in
            let error = error as NSError?
            self.show("Synthetic identity saved: \(success)\nError domain: \(error?.domain ?? "none")\nError code: \(error?.code ?? 0)\n\(error?.localizedDescription ?? "")")
        }
    }
}

let application = NSApplication.shared
application.setActivationPolicy(.regular)
let probe = Probe()
application.delegate = probe
application.run()
