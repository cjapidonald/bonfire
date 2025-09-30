import SwiftUI
import UIKit

/// Canonical color tokens for the Bonfire design system.
/// These colors are inspired by a hearthstone palette with
/// rich woods, warm parchment, and luminous magical accents.
enum DesignColor {
    static let deepWalnut = Color("DeepWalnut")
    static let agedParchment = Color("AgedParchment")
    static let ink = Color("Ink")
    static let aquaGlow = Color("AquaGlow")
    static let amberGlow = Color("AmberGlow")

    /// UIKit compatibility for the color palette.
    enum UIKit {
        static let deepWalnut = UIColor(named: "DeepWalnut")!
        static let agedParchment = UIColor(named: "AgedParchment")!
        static let ink = UIColor(named: "Ink")!
        static let aquaGlow = UIColor(named: "AquaGlow")!
        static let amberGlow = UIColor(named: "AmberGlow")!
    }
}
