import SwiftUI
import PDFKit
import UIKit

class PDFGenerator {
    static func generatePDF(from travelPlan: TravelPlan, languageManager: LanguageManager) -> Data? {
        let pageWidth: CGFloat = 595.2
        let pageHeight: CGFloat = 841.8
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        
        let data = renderer.pdfData { context in
            context.beginPage()
            drawTitlePage(travelPlan: travelPlan, pageRect: pageRect, languageManager: languageManager)
            
            if let dailyPlans = travelPlan.dailyPlans {
                for dailyPlan in dailyPlans {
                    context.beginPage()
                    drawDailyPlan(dailyPlan: dailyPlan, pageRect: pageRect, languageManager: languageManager)
                }
            }
        }
        
        return data
    }
    
    private static func drawTitlePage(travelPlan: TravelPlan, pageRect: CGRect, languageManager: LanguageManager) {
        let titleFont = UIFont.systemFont(ofSize: 28, weight: .bold)
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: UIColor.black
        ]
        
        let title = "\(languageManager.localize("travel_plan_for")) \(travelPlan.location)"
        let titleStringSize = title.size(withAttributes: titleAttributes)
        let titleRect = CGRect(
            x: (pageRect.width - titleStringSize.width) / 2.0,
            y: 100,
            width: titleStringSize.width,
            height: titleStringSize.height
        )
        title.draw(in: titleRect, withAttributes: titleAttributes)
        
        let dateFont = UIFont.systemFont(ofSize: 18, weight: .medium)
        let dateAttributes: [NSAttributedString.Key: Any] = [
            .font: dateFont,
            .foregroundColor: UIColor.darkGray
        ]
        
        let dateRange = "\(DateFormatterUtils.formatDateString(travelPlan.period.startDate)) - \(DateFormatterUtils.formatDateString(travelPlan.period.endDate))"
        let dateStringSize = dateRange.size(withAttributes: dateAttributes)
        let dateRect = CGRect(
            x: (pageRect.width - dateStringSize.width) / 2.0,
            y: titleRect.maxY + 20,
            width: dateStringSize.width,
            height: dateStringSize.height
        )
        dateRange.draw(in: dateRect, withAttributes: dateAttributes)
        
        let infoFont = UIFont.systemFont(ofSize: 16)
        let infoAttributes: [NSAttributedString.Key: Any] = [
            .font: infoFont,
            .foregroundColor: UIColor.darkGray
        ]
        
        let infoY: CGFloat = dateRect.maxY + 40
        
        let durationString = "\(languageManager.localize("duration")): \(travelPlan.period.durationInDays) \(travelPlan.period.durationInDays > 1 ? languageManager.localize("days") : languageManager.localize("day_singular"))"
        let durationRect = CGRect(
            x: 60,
            y: infoY,
            width: pageRect.width - 120,
            height: 20
        )
        durationString.draw(in: durationRect, withAttributes: infoAttributes)
        
        let footerFont = UIFont.systemFont(ofSize: 10)
        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: footerFont,
            .foregroundColor: UIColor.lightGray
        ]
        
        let footer = "© CityTailor \(Calendar.current.component(.year, from: Date()))"
        let footerRect = CGRect(
            x: 60,
            y: pageRect.height - 40,
            width: pageRect.width - 120,
            height: 20
        )
        footer.draw(in: footerRect, withAttributes: footerAttributes)
    }
    
    private static func drawDailyPlan(dailyPlan: DailyPlan, pageRect: CGRect, languageManager: LanguageManager) {
        let titleFont = UIFont.systemFont(ofSize: 20, weight: .bold)
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: UIColor.black
        ]
        
        let title = "\(languageManager.localize("day")) \(dailyPlan.dayNumber) - \(DateFormatterUtils.formatDateString(dailyPlan.date))"
        let titleRect = CGRect(
            x: 40,
            y: 40,
            width: pageRect.width - 80,
            height: 30
        )
        title.draw(in: titleRect, withAttributes: titleAttributes)
        
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 40, y: titleRect.maxY + 5))
        path.addLine(to: CGPoint(x: pageRect.width - 40, y: titleRect.maxY + 5))
        UIColor.lightGray.setStroke()
        path.lineWidth = 1
        path.stroke()
        
        var currentY = titleRect.maxY + 20
        let activityFont = UIFont.systemFont(ofSize: 14, weight: .medium)
        let activityAttributes: [NSAttributedString.Key: Any] = [
            .font: activityFont,
            .foregroundColor: UIColor.black
        ]
        
        let descriptionFont = UIFont.systemFont(ofSize: 12)
        let descriptionAttributes: [NSAttributedString.Key: Any] = [
            .font: descriptionFont,
            .foregroundColor: UIColor.darkGray
        ]
        
        let locationFont = UIFont.systemFont(ofSize: 12, weight: .light)
        let locationAttributes: [NSAttributedString.Key: Any] = [
            .font: locationFont,
            .foregroundColor: UIColor.darkGray
        ]
        
        for activity in dailyPlan.activities {
            let activityTitle = "\(activity.time) - \(activity.title)"
            let activityRect = CGRect(
                x: 40,
                y: currentY,
                width: pageRect.width - 80,
                height: 20
            )
            activityTitle.draw(in: activityRect, withAttributes: activityAttributes)
            currentY += 20
            
            let descriptionRect = CGRect(
                x: 40,
                y: currentY,
                width: pageRect.width - 80,
                height: 40
            )
            activity.description.draw(in: descriptionRect, withAttributes: descriptionAttributes)
            currentY += 40
            
            let locationRect = CGRect(
                x: 40,
                y: currentY,
                width: pageRect.width - 80,
                height: 20
            )
            
            let locationString = "\(languageManager.localize("location")): \(activity.displayAddress)"
            locationString.draw(in: locationRect, withAttributes: locationAttributes)
            currentY += 30
        }
        
        let pageNumberFont = UIFont.systemFont(ofSize: 10)
        let pageNumberAttributes: [NSAttributedString.Key: Any] = [
            .font: pageNumberFont,
            .foregroundColor: UIColor.lightGray
        ]
        
        let pageNumber = "\(languageManager.localize("day")) \(dailyPlan.dayNumber)"
        let pageNumberRect = CGRect(
            x: pageRect.width - 80,
            y: pageRect.height - 30,
            width: 60,
            height: 20
        )
        pageNumber.draw(in: pageNumberRect, withAttributes: pageNumberAttributes)
    }
}
