//


//

//

import MapKit
import SwiftUI
import UIKit

class CustomAnnotationView: MKAnnotationView {
    private var imageView: UIImageView?
    private var containerView: UIView?
    private var shadowView: UIView?
    private var categoryIndicator: UIView?
    private var titleLabel: UILabel?
    
    private var activeImageTask: Task<Void, Never>?
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        activeImageTask?.cancel()
        activeImageTask = nil
        imageView?.image = nil
    }
    
    private func setupView() {
        frame = CGRect(x: -30, y: 0, width: 100, height: 70)  
        backgroundColor = .clear
        
        
        shadowView = UIView(frame: CGRect(x: 30, y: 0, width: 40, height: 40))  
        shadowView?.backgroundColor = .clear
        shadowView?.layer.shadowColor = UIColor.black.cgColor
        shadowView?.layer.shadowRadius = 3
        shadowView?.layer.shadowOpacity = 0.3
        shadowView?.layer.shadowOffset = CGSize(width: 0, height: 1)
        
        
        containerView = UIView(frame: CGRect(x: 0, y: 0, width: 36, height: 36))
        containerView?.backgroundColor = .white
        containerView?.layer.cornerRadius = 18
        containerView?.layer.masksToBounds = true
        containerView?.layer.borderWidth = 2
        containerView?.layer.borderColor = UIColor.white.cgColor
        
        
        imageView = UIImageView(frame: CGRect(x: 2, y: 2, width: 32, height: 32))
        imageView?.contentMode = .scaleAspectFill
        imageView?.backgroundColor = .lightGray
        imageView?.layer.cornerRadius = 16
        imageView?.layer.masksToBounds = true
        
        
        categoryIndicator = UIView(frame: CGRect(x: 26, y: 26, width: 12, height: 12))
        categoryIndicator?.backgroundColor = .systemBlue
        categoryIndicator?.layer.cornerRadius = 6
        categoryIndicator?.layer.borderWidth = 2
        categoryIndicator?.layer.borderColor = UIColor.white.cgColor
        
        if let containerView = containerView, let imageView = imageView {
            containerView.addSubview(imageView)
        }
        
        if let shadowView = shadowView, let containerView = containerView {
            shadowView.addSubview(containerView)
        }
        
        if let shadowView = shadowView {
            addSubview(shadowView)
        }
        
        if let containerView = containerView, let categoryIndicator = categoryIndicator {
            containerView.addSubview(categoryIndicator)
        }
        
        titleLabel = UILabel(frame: CGRect(x: 0, y: 42, width: 100, height: 24))
        titleLabel?.textAlignment = .center
        titleLabel?.font = UIFont.systemFont(ofSize: 11, weight: .semibold)
        titleLabel?.textColor = .black
        titleLabel?.backgroundColor = UIColor.white.withAlphaComponent(0.85)
        titleLabel?.layer.cornerRadius = 5
        titleLabel?.layer.masksToBounds = true
        titleLabel?.adjustsFontSizeToFitWidth = true
        titleLabel?.minimumScaleFactor = 0.8
        titleLabel?.lineBreakMode = .byTruncatingMiddle
        titleLabel?.numberOfLines = 2  
        
        if let titleLabel = titleLabel {
            addSubview(titleLabel)
        }
        
        canShowCallout = true
    }
    
    func configure(with annotation: MKAnnotation, tintColor: UIColor?) {
        guard let annotation = annotation as? CustomPointAnnotation else { return }
        
        if let color = tintColor {
            categoryIndicator?.backgroundColor = color
        }
        
        
        if let title = annotation.title {
            titleLabel?.text = title
            let titleWidth = min(max((title as NSString).size(withAttributes: [.font: UIFont.systemFont(ofSize: 11, weight: .semibold)]).width + 10, 60), 100)
            titleLabel?.frame = CGRect(x: (100 - titleWidth) / 2, y: 42, width: titleWidth, height: 24)
        }
        
        if let imageURL = annotation.imageURL {
            loadImage(from: imageURL)
        } else if let activityInfo = annotation.activityInfo {
            setPlaceholderImage(for: activityInfo.category)
        } else {
            imageView?.image = UIImage(systemName: "photo")
            imageView?.tintColor = .darkGray
            imageView?.contentMode = .center
        }
    }
    
    private func loadImage(from url: URL) {
        activeImageTask?.cancel()
        
        activeImageTask = Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let image = UIImage(data: data) {
                    await MainActor.run {
                        self.imageView?.image = image
                        self.imageView?.contentMode = .scaleAspectFill
                    }
                }
            } catch {
                print("Failed to load image: \(error)")
                await MainActor.run {
                    self.imageView?.image = UIImage(systemName: "photo")
                    self.imageView?.tintColor = .darkGray
                    self.imageView?.contentMode = .center
                }
            }
        }
    }
    
    private func setPlaceholderImage(for category: String) {
        let lowercasedCategory = category.lowercased()
        var symbolName: String
        var symbolColor: UIColor
        
        if lowercasedCategory.contains("art") || lowercasedCategory.contains("museum") {
            symbolName = "paintpalette.fill"
            symbolColor = .systemPurple
        } else if lowercasedCategory.contains("history") || lowercasedCategory.contains("monument") {
            symbolName = "building.columns.fill"
            symbolColor = .systemOrange
        } else if lowercasedCategory.contains("architecture") {
            symbolName = "building.2.fill"
            symbolColor = .systemBlue
        } else if lowercasedCategory.contains("gastronomy") || lowercasedCategory.contains("restaurant") {
            symbolName = "fork.knife"
            symbolColor = .systemRed
        } else if lowercasedCategory.contains("shopping") {
            symbolName = "bag.fill"
            symbolColor = .systemPink
        } else if lowercasedCategory.contains("nightlife") {
            symbolName = "moon.stars.fill"
            symbolColor = .systemIndigo
        } else if lowercasedCategory.contains("culture") {
            symbolName = "theatermasks.fill"
            symbolColor = .systemTeal
        } else if lowercasedCategory.contains("sightseeing") {
            symbolName = "binoculars.fill"
            symbolColor = .systemGreen
        } else {
            symbolName = "mappin.and.ellipse"
            symbolColor = .systemBlue
        }
        
        containerView?.backgroundColor = symbolColor.withAlphaComponent(0.2)
        
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        
        imageView?.image = UIImage(systemName: symbolName, withConfiguration: config)
        imageView?.tintColor = symbolColor
        imageView?.contentMode = .center
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        if selected, animated {
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: [], animations: {
                self.shadowView?.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
                self.titleLabel?.alpha = 1.0
                self.titleLabel?.backgroundColor = UIColor.white
                self.titleLabel?.layer.shadowColor = UIColor.black.cgColor
                self.titleLabel?.layer.shadowRadius = 2
                self.titleLabel?.layer.shadowOpacity = 0.3
                self.titleLabel?.layer.shadowOffset = CGSize(width: 0, height: 1)
            }) { _ in
                UIView.animate(withDuration: 0.1) {
                    self.shadowView?.transform = CGAffineTransform.identity
                    
                    if !selected {
                        self.titleLabel?.alpha = 0.85
                        self.titleLabel?.backgroundColor = UIColor.white.withAlphaComponent(0.85)
                        self.titleLabel?.layer.shadowOpacity = 0
                    }
                }
            }
        }
    }
}
