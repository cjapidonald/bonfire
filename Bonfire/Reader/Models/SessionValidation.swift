import Foundation

/// Validates recorded reading sessions and applies lightweight anti-cheat rules.
struct SessionValidator {
    struct Input {
        let totalWords: Int
        let duration: TimeInterval
        let sessionEndedAt: Date
        let lastDifficultyChange: Date?

        init(totalWords: Int, duration: TimeInterval, sessionEndedAt: Date = Date(), lastDifficultyChange: Date? = nil) {
            self.totalWords = totalWords
            self.duration = duration
            self.sessionEndedAt = sessionEndedAt
            self.lastDifficultyChange = lastDifficultyChange
        }
    }

    struct Result {
        enum Status {
            case accepted
            case rejected(reason: FailureReason)
        }

        enum FailureReason: Equatable {
            case noWords
            case zeroDuration
            case paceOutOfRange(wordsPerMinute: Double)
            case belowMinimumDuration(required: TimeInterval)
        }

        let status: Status
        let wordsPerMinute: Double
        let qualityFactor: Double
        let helpfulTip: String?

        var awardsStars: Bool {
            if case .accepted = status { return true }
            return false
        }
    }

    private let acceptablePace: ClosedRange<Double> = 45...160
    private let baselineWPM: Double = 160
    private let fastReadingFactor: Double = 0.6
    private let difficultyChangePenaltyWindow: TimeInterval = 15
    private let difficultyChangePenalty: Double = 0.7

    func validate(_ input: Input) -> Result {
        guard input.totalWords > 0 else {
            return Result(
                status: .rejected(reason: .noWords),
                wordsPerMinute: 0,
                qualityFactor: 0,
                helpfulTip: "Let's add a few words to the session so we can celebrate your progress."
            )
        }

        guard input.duration > 0 else {
            return Result(
                status: .rejected(reason: .zeroDuration),
                wordsPerMinute: 0,
                qualityFactor: 0,
                helpfulTip: "We couldn't measure that session. Try again and we'll keep the timer running."
            )
        }

        let minutes = input.duration / 60
        let wordsPerMinute = Double(input.totalWords) / minutes

        guard acceptablePace.contains(wordsPerMinute) else {
            let tip: String
            if wordsPerMinute < acceptablePace.lowerBound {
                tip = "That pace looks a bit slow for scoring. Read at a comfortable clip and we'll count it."
            } else {
                tip = "That was lightning fast! Take a little more time so we can award stars fairly."
            }

            return Result(
                status: .rejected(reason: .paceOutOfRange(wordsPerMinute: wordsPerMinute)),
                wordsPerMinute: wordsPerMinute,
                qualityFactor: 0,
                helpfulTip: tip
            )
        }

        let fastReadingWPM = baselineWPM * fastReadingFactor
        let minimumDuration = (Double(input.totalWords) / fastReadingWPM) * 60

        guard input.duration >= minimumDuration else {
            let formattedMinimum = Self.formattedDuration(minimumDuration)
            return Result(
                status: .rejected(reason: .belowMinimumDuration(required: minimumDuration)),
                wordsPerMinute: wordsPerMinute,
                qualityFactor: 0,
                helpfulTip: "That session wrapped up quickly. Try reading for about \(formattedMinimum) so we can award points."
            )
        }

        var qualityFactor = 1.0
        var tip: String? = nil

        if let lastChange = input.lastDifficultyChange,
           input.sessionEndedAt.timeIntervalSince(lastChange) < difficultyChangePenaltyWindow {
            qualityFactor *= difficultyChangePenalty
            tip = "Heads up: changing the difficulty right before finishing reduces the bonus a bit."
        }

        return Result(
            status: .accepted,
            wordsPerMinute: wordsPerMinute,
            qualityFactor: qualityFactor,
            helpfulTip: tip
        )
    }

    private static func formattedDuration(_ duration: TimeInterval) -> String {
        let totalSeconds = Int(duration.rounded())
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60

        switch (minutes, seconds) {
        case (0, let seconds):
            return "\(seconds) seconds"
        case (let minutes, 0):
            return "\(minutes) minute\(minutes == 1 ? "" : "s")"
        default:
            return "\(minutes)m \(seconds)s"
        }
    }
}
