import AppKit
import AuthenticationServices

// No nib, IPC, real vault, or external dependency. This isolates OS acceptance.
final class ProbeCredentialProvider: ASCredentialProviderViewController {
    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 380, height: 120))
        let label = NSTextField(labelWithString: "Synthetic AutoFill provider; no real vault data.")
        label.frame = NSRect(x: 16, y: 50, width: 350, height: 40)
        view.addSubview(label)
    }

    override func prepareInterfaceForExtensionConfiguration() {
        extensionContext.completeExtensionConfigurationRequest()
    }

    override func provideCredentialWithoutUserInteraction(for credentialIdentity: ASPasswordCredentialIdentity) {
        extensionContext.cancelRequest(withError: ASExtensionError(.userInteractionRequired))
    }

    override func provideCredentialWithoutUserInteraction(for credentialRequest: any ASCredentialRequest) {
        extensionContext.cancelRequest(withError: ASExtensionError(.userInteractionRequired))
    }

    private func completeSyntheticCredential() {
        extensionContext.completeRequest(withSelectedCredential: ASPasswordCredential(user: "synthetic-user", password: "synthetic-password"), completionHandler: nil)
    }

    override func prepareInterfaceToProvideCredential(for credentialIdentity: ASPasswordCredentialIdentity) {
        completeSyntheticCredential()
    }

    override func prepareInterfaceToProvideCredential(for credentialRequest: any ASCredentialRequest) {
        guard credentialRequest is ASPasswordCredentialRequest else {
            extensionContext.cancelRequest(withError: ASExtensionError(.failed))
            return
        }
        completeSyntheticCredential()
    }

    override func prepareCredentialList(for serviceIdentifiers: [ASCredentialServiceIdentifier]) {
        completeSyntheticCredential()
    }
}
