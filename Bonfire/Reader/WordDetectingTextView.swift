import SwiftUI
import UIKit

struct WordDetectingTextView: UIViewRepresentable {
    struct WordSelection: Equatable {
        let original: String
        let normalized: String
        let boundingRects: [CGRect]
    }

    var text: String
    var onSingleTap: (WordSelection) -> Void
    var onDoubleTap: (WordSelection) -> Void

    func makeUIView(context: Context) -> WordMappedTextView {
        let textView = WordMappedTextView()
        textView.isEditable = false
        textView.isSelectable = false
        textView.isScrollEnabled = false
        textView.adjustsFontForContentSizeCategory = true
        textView.backgroundColor = .clear
        textView.textColor = UIColor.label
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        textView.textContainer.lineFragmentPadding = 0
        textView.onSingleTap = { token in
            context.coordinator.handleSingleTap(token)
        }
        textView.onDoubleTap = { token in
            context.coordinator.handleDoubleTap(token)
        }
        return textView
    }

    func updateUIView(_ uiView: WordMappedTextView, context: Context) {
        context.coordinator.parent = self
        uiView.textColor = UIColor.label
        uiView.font = UIFont.preferredFont(forTextStyle: .body)

        if uiView.text != text {
            uiView.text = text
            uiView.rebuildTokens()
        } else {
            uiView.requestBoundingBoxUpdate()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator {
        var parent: WordDetectingTextView

        init(parent: WordDetectingTextView) {
            self.parent = parent
        }

        func handleSingleTap(_ token: WordMappedTextView.Token) {
            parent.onSingleTap(token.selection)
        }

        func handleDoubleTap(_ token: WordMappedTextView.Token) {
            parent.onDoubleTap(token.selection)
        }
    }
}

final class WordMappedTextView: UITextView {
    struct Token {
        let original: String
        let normalized: String
        let range: NSRange
        var boundingRects: [CGRect]

        var selection: WordDetectingTextView.WordSelection {
            WordDetectingTextView.WordSelection(
                original: original,
                normalized: normalized,
                boundingRects: boundingRects
            )
        }
    }

    var onSingleTap: ((Token) -> Void)?
    var onDoubleTap: ((Token) -> Void)?

    private var tokens: [Token] = []
    private var needsBoundingBoxUpdate: Bool = false
    private var lastMeasuredBounds: CGRect = .zero

    private lazy var singleTapRecognizer: UITapGestureRecognizer = {
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(handleSingleTap(_:)))
        recognizer.numberOfTapsRequired = 1
        return recognizer
    }()

    private lazy var doubleTapRecognizer: UITapGestureRecognizer = {
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        recognizer.numberOfTapsRequired = 2
        return recognizer
    }()

    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        doubleTapRecognizer.delaysTouchesBegan = true
        singleTapRecognizer.require(toFail: doubleTapRecognizer)
        addGestureRecognizer(singleTapRecognizer)
        addGestureRecognizer(doubleTapRecognizer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        if lastMeasuredBounds.size != bounds.size {
            lastMeasuredBounds = bounds
            needsBoundingBoxUpdate = true
        }

        updateBoundingBoxesIfNeeded()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        requestBoundingBoxUpdate()
    }

    func rebuildTokens() {
        tokens = tokenizeText()
        needsBoundingBoxUpdate = true
        setNeedsLayout()
    }

    func requestBoundingBoxUpdate() {
        needsBoundingBoxUpdate = true
        setNeedsLayout()
    }

    private func tokenizeText() -> [Token] {
        guard let text = text, !text.isEmpty else { return [] }

        var collected: [Token] = []
        text.enumerateSubstrings(in: text.startIndex..<text.endIndex, options: [.byWords]) { substring, range, _, _ in
            guard let substring, !substring.isEmpty else { return }
            let normalized = substring.normalizedToken()
            guard !normalized.isEmpty else { return }
            let nsRange = NSRange(range, in: text)
            collected.append(
                Token(
                    original: substring,
                    normalized: normalized,
                    range: nsRange,
                    boundingRects: []
                )
            )
        }
        return collected
    }

    private func updateBoundingBoxesIfNeeded() {
        guard needsBoundingBoxUpdate else { return }
        guard bounds.width > 0 else { return }

        layoutManager.ensureLayout(for: textContainer)

        for index in tokens.indices {
            let characterRange = tokens[index].range
            let glyphRange = layoutManager.glyphRange(forCharacterRange: characterRange, actualCharacterRange: nil)
            var rects: [CGRect] = []
            layoutManager.enumerateEnclosingRects(
                forGlyphRange: glyphRange,
                withinSelectedGlyphRange: NSRange(location: NSNotFound, length: 0),
                in: textContainer
            ) { rect, _ in
                var adjusted = rect
                adjusted.origin.x += textContainerInset.left
                adjusted.origin.y += textContainerInset.top
                adjusted = adjusted.integral
                rects.append(adjusted)
            }
            tokens[index].boundingRects = rects
        }

        needsBoundingBoxUpdate = false
    }

    @objc private func handleSingleTap(_ recognizer: UITapGestureRecognizer) {
        guard recognizer.state == .ended else { return }
        let location = recognizer.location(in: self)
        if let token = token(at: location) {
            onSingleTap?(token)
        }
    }

    @objc private func handleDoubleTap(_ recognizer: UITapGestureRecognizer) {
        guard recognizer.state == .ended else { return }
        let location = recognizer.location(in: self)
        if let token = token(at: location) {
            onDoubleTap?(token)
        }
    }

    private func token(at point: CGPoint) -> Token? {
        for token in tokens {
            for rect in token.boundingRects {
                if rect.contains(point) {
                    return token
                }
            }
        }
        return nil
    }
}

private extension String {
    func normalizedToken() -> String {
        trimmingCharacters(in: CharacterSet.punctuationCharacters.union(.whitespacesAndNewlines))
            .lowercased()
    }
}
