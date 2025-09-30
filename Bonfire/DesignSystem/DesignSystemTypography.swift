import SwiftUI
import UIKit

/// Font tokens tuned for Hearthstone-inspired typography.
/// Headers lean into a serif display while body styles favor legibility.
enum DesignTypography {
    enum Display {
        static let font = Font.system(.largeTitle, design: .serif).weight(.black)
        static let uiFont = UIFont.designSystemSerif(textStyle: .largeTitle, weight: .black)
    }

    enum Title {
        static let font = Font.system(.title, design: .serif).weight(.semibold)
        static let uiFont = UIFont.designSystemSerif(textStyle: .title1, weight: .semibold)
    }

    enum Body {
        /// SF Pro body text prioritises legibility and dynamic type.
        static let font = Font.system(.body, design: .default)
        static let uiFont = UIFont.preferredFont(forTextStyle: .body)
    }

    enum Caption {
        static let font = Font.system(.caption, design: .default)
        static let uiFont = UIFont.preferredFont(forTextStyle: .caption1)
    }
}

private extension UIFont {
    static func designSystemSerif(textStyle: UIFont.TextStyle, weight: UIFont.Weight) -> UIFont {
        let baseDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: textStyle)
        let serifDescriptor = baseDescriptor.withDesign(.serif) ?? baseDescriptor
        let weightedDescriptor = serifDescriptor.addingAttributes([
            UIFontDescriptor.AttributeName.traits: [UIFontDescriptor.TraitKey.weight: weight]
        ])
        return UIFont(descriptor: weightedDescriptor, size: 0)
    }
}
