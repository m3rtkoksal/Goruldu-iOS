import SwiftUI

/// The double check mark of the brand, drawn on a 24 pt grid.
struct TicksShape: Shape {
    func path(in rect: CGRect) -> Path {
        let scale = min(rect.width, rect.height) / 24
        let origin = CGPoint(x: rect.midX - 12 * scale, y: rect.midY - 12 * scale)
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: origin.x + x * scale, y: origin.y + y * scale)
        }
        var path = Path()
        path.move(to: point(2, 12.5))
        path.addLine(to: point(6.5, 17))
        path.addLine(to: point(16, 7.5))
        path.move(to: point(11.5, 16.5))
        path.addLine(to: point(12.5, 17.5))
        path.addLine(to: point(22, 7.5))
        return path
    }
}

struct TicksIcon: View {
    var size: CGFloat = 18
    var lineWidth: CGFloat = 2.6

    var body: some View {
        TicksShape()
            .stroke(style: StrokeStyle(lineWidth: lineWidth * size / 24, lineCap: .round, lineJoin: .round))
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

/// SF Symbols used by the app, in one place.
enum Symbol {
    static let arrowRight = "arrow.right"
    static let back = "chevron.left"
    static let close = "xmark"
    static let more = "ellipsis"
    static let group = "person.2.fill"
    static let pair = "heart.fill"
    static let plus = "plus"
    static let upload = "square.and.arrow.up"
    static let file = "doc.fill"
    static let alert = "exclamationmark.triangle.fill"
    static let retry = "arrow.clockwise"
    static let check = "checkmark"
    static let lock = "lock.fill"
    static let shield = "lock.shield.fill"
    static let moon = "moon.fill"
    static let trophy = "trophy.fill"
    static let sparkles = "sparkles"
    static let clock = "clock"
    static let download = "square.and.arrow.down"
    static let trash = "trash"
    static let message = "message.fill"
}
