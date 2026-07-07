import SwiftUI

struct MiniChartView: View {
    let data: [DailyCount]
    let color: Color

    var body: some View {
        GeometryReader { geo in
            let maxVal = max(data.map(\.total).max() ?? 1, 1)
            HStack(alignment: .bottom, spacing: 2) {
                ForEach(data.suffix(7)) { day in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color.opacity(0.8))
                        .frame(height: max(4, geo.size.height * CGFloat(day.total) / CGFloat(maxVal)))
                }
            }
        }
    }
}
