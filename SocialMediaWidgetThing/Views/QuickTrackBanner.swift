import SwiftUI

struct QuickTrackBanner: View {
    @EnvironmentObject var store: SharedDataStore
    @EnvironmentObject var clipboard: ClipboardTracker
    @State private var showLogged = false

    var body: some View {
        if let url = clipboard.pendingURL, let platform = clipboard.pendingPlatform {
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: platform.iconName)
                        .font(.title2)
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(platform.gradient, in: RoundedRectangle(cornerRadius: 10))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Video link detected")
                            .font(.subheadline.bold())
                            .foregroundStyle(.white)
                        Text(platform.displayName)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                    }

                    Spacer()

                    Button {
                        clipboard.dismissPending()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.caption.bold())
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }

                HStack(spacing: 10) {
                    Button("Track Share") {
                        clipboard.trackPendingShare(store: store)
                        withAnimation { showLogged = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            showLogged = false
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    Button("Dismiss") {
                        clipboard.dismissPending()
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [platform.brandColor.opacity(0.3), AppColors.accent.opacity(0.2)],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                in: RoundedRectangle(cornerRadius: 16)
            )
            .overlay {
                if showLogged {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Tracked! +\(platform.pointsPerShare) pts")
                            .font(.subheadline.bold())
                            .foregroundStyle(.white)
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
    }
}
