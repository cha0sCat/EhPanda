//
//  ViewModifiers.swift
//  EhPanda
//

import SwiftUI

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }

    @ViewBuilder func withHorizontalSpacing(width: CGFloat = 8, height: CGFloat? = nil) -> some View {
        Color.clear.frame(width: width, height: height)
        self
        Color.clear.frame(width: width, height: height)
    }

    func withArrow(isVisible: Bool = true) -> some View {
        HStack {
            self
            Spacer()
            Image(systemSymbol: .chevronRight)
                .foregroundColor(.secondary)
                .imageScale(.small)
                .opacity(isVisible ? 0.5 : 0)
        }
    }

    func autoBlur(radius: Double) -> some View {
        blur(radius: radius)
            .allowsHitTesting(radius < 1)
            .animation(.linear(duration: 0.1), value: radius)
    }

    func synchronize<Value: Equatable>(
        _ first: Binding<Value>,
        _ second: Binding<Value>,
        initial: (first: Bool, second: Bool) = (false, false)
    ) -> some View {
        self
            .onChange(of: first.wrappedValue, initial: initial.first) { _, newValue in
                second.wrappedValue = newValue
            }
            .onChange(of: second.wrappedValue, initial: initial.second) { _, newValue in
                first.wrappedValue = newValue
            }
    }

    func synchronize<Value>(
        _ first: Binding<Value>,
        _ second: FocusState<Value>.Binding,
        initial: (first: Bool, second: Bool) = (false, false)
    ) -> some View {
        self
            .onChange(of: first.wrappedValue, initial: initial.first) { _, newValue in
                second.wrappedValue = newValue
            }
            .onChange(of: second.wrappedValue, initial: initial.second) { _, newValue in
                first.wrappedValue = newValue
            }
    }
}

struct PlainLinearProgressViewStyle: ProgressViewStyle {
    func makeBody(configuration: ProgressViewStyleConfiguration) -> some View {
        ProgressView(value: CGFloat(configuration.fractionCompleted ?? 0), total: 1)
    }
}
extension ProgressViewStyle where Self == PlainLinearProgressViewStyle {
    static var plainLinear: PlainLinearProgressViewStyle {
        PlainLinearProgressViewStyle()
    }
}

// MARK: Image Modifier
extension Image {
    func defaultModifier(withRoundedCorners: Bool = true) -> Image {
        if withRoundedCorners {
            return self.cornerRadius(5)
        }
        return self
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(
                width: radius,
                height: radius
            )
        )
        return Path(path.cgPath)
    }
}

struct PreviewResolver {
    static func getPreviewConfigs(originalURL: URL?) -> URL? {
        guard let url = originalURL,
              let (plainURL, _, _) = Parser.parsePreviewConfigs(url: url)
        else {
            return originalURL
        }
        return plainURL
    }
}
