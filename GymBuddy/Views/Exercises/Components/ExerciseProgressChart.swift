import SwiftUI
import Charts

struct ExerciseProgressChart: View {
    let progressEntries: [ExerciseProgress]
    
    private var chartData: [(date: Date, weight: Double)] {
        progressEntries
            .sorted { $0.progressDate < $1.progressDate }
            .map { (date: $0.progressDate, weight: $0.weight) }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }
    
    private var trendLinePoints: [(date: Date, weight: Double)] {
        guard chartData.count > 1 else { return [] }
        
        // Convert dates to time intervals for calculation
        let timeIntervals = chartData.map { $0.date.timeIntervalSince1970 }
        let weights = chartData.map { $0.weight }
        
        // Calculate means
        let meanX = timeIntervals.reduce(0.0, +) / Double(timeIntervals.count)
        let meanY = weights.reduce(0.0, +) / Double(weights.count)
        
        // Calculate slope (m) and y-intercept (b) for y = mx + b
        var slope = 0.0
        var numerator = 0.0
        var denominator = 0.0
        
        for i in 0..<timeIntervals.count {
            let diffX = timeIntervals[i] - meanX
            let diffY = weights[i] - meanY
            numerator += diffX * diffY
            denominator += diffX * diffX
        }
        
        slope = denominator != 0 ? numerator / denominator : 0
        let yIntercept = meanY - slope * meanX
        
        // Create two points for the trend line at start and end dates
        if let firstDate = chartData.first?.date,
           let lastDate = chartData.last?.date {
            let firstInterval = firstDate.timeIntervalSince1970
            let lastInterval = lastDate.timeIntervalSince1970
            
            let firstY = slope * firstInterval + yIntercept
            let lastY = slope * lastInterval + yIntercept
            
            return [
                (date: firstDate, weight: firstY),
                (date: lastDate, weight: lastY)
            ]
        }
        
        return []
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !chartData.isEmpty {
                Chart {
                    ForEach(chartData, id: \.date) { item in
                        LineMark(
                            x: .value("Date", item.date),
                            y: .value("Weight", item.weight)
                        )
                        .interpolationMethod(.catmullRom)
                        
                        PointMark(
                            x: .value("Date", item.date),
                            y: .value("Weight", item.weight)
                        )
                    }
                    
                    // Trend line
                    if chartData.count > 1 {
                        ForEach(trendLinePoints, id: \.date) { point in
                            LineMark(
                                x: .value("Date", point.date),
                                y: .value("Weight", point.weight)
                            )
                            .foregroundStyle(.red.opacity(0.5))
                            .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { value in
                        if let date = value.as(Date.self) {
                            AxisValueLabel {
                                Text(dateFormatter.string(from: date))
                                    .font(.caption)
                            }
                        }
                    }
                }
                .frame(height: 200)
                
                // Stats
                HStack(spacing: 16) {
                    if let maxWeight = chartData.max(by: { $0.weight < $1.weight })?.weight {
                        VStack(alignment: .leading) {
                            Text("Max Weight")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(String(format: "%.1f kg", maxWeight))
                                .font(.headline)
                        }
                    }
                    
                    if chartData.count > 1,
                       let firstWeight = chartData.first?.weight,
                       let lastWeight = chartData.last?.weight {
                        let progress = lastWeight - firstWeight
                        VStack(alignment: .leading) {
                            Text("Progress")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(String(format: "%+.1f kg", progress))
                                .font(.headline)
                                .foregroundColor(progress >= 0 ? .green : .red)
                        }
                    }
                    
                    // Trend indicator
                    if let firstTrend = trendLinePoints.first?.weight,
                       let lastTrend = trendLinePoints.last?.weight,
                       chartData.count > 1 {
                        let trendSlope = (lastTrend - firstTrend) / Double(chartData.count - 1)
                        VStack(alignment: .leading) {
                            Text("Trend")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(String(format: "%+.2f kg/week", trendSlope * 7))
                                .font(.headline)
                                .foregroundColor(trendSlope >= 0 ? .green : .red)
                        }
                    }
                }
                .padding(.top, 8)
            } else {
                ContentUnavailableView(
                    "No Progress Data",
                    systemImage: "chart.line.uptrend.xyaxis",
                    description: Text("Start logging your weights to see progression")
                )
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
} 