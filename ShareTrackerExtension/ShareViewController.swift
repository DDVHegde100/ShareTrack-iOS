import UIKit
import UniformTypeIdentifiers
import WidgetKit

class ShareViewController: UIViewController {
    private var detectedPlatform: SocialPlatform = .instagram
    private var contentURL: String?
    private var detectedCategory: ContentCategory = .other
    private var platformButtons: [SocialPlatform: UIButton] = [:]
    private var categoryScroll = UIScrollView()
    private var categoryStack = UIStackView()

    private let stackView = UIStackView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let platformStack = UIStackView()
    private let trackButton = UIButton(type: .system)
    private let cancelButton = UIButton(type: .system)
    private let statusLabel = UILabel()
    private let spinner = UIActivityIndicatorView(style: .large)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.10, alpha: 1)
        setupUI()
        processSharedContent()
    }

    private func setupUI() {
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.text = "Track This Share"
        titleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center

        subtitleLabel.text = "Select platform and tap Track"
        subtitleLabel.font = .systemFont(ofSize: 14)
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.6)
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0

        platformStack.axis = .horizontal
        platformStack.spacing = 10
        platformStack.distribution = .fillEqually

        for platform in SocialPlatform.allCases {
            let button = UIButton(type: .system)
            button.setTitle(platform.displayName.prefix(4).description, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 11, weight: .semibold)
            button.layer.cornerRadius = 10
            button.tag = SocialPlatform.allCases.firstIndex(of: platform) ?? 0
            button.addTarget(self, action: #selector(platformTapped(_:)), for: .touchUpInside)
            platformButtons[platform] = button
            platformStack.addArrangedSubview(button)
        }
        updatePlatformSelection()

        trackButton.setTitle("Track Share", for: .normal)
        trackButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        trackButton.backgroundColor = UIColor(red: 0.55, green: 0.35, blue: 0.95, alpha: 1)
        trackButton.setTitleColor(.white, for: .normal)
        trackButton.layer.cornerRadius = 14
        trackButton.addTarget(self, action: #selector(trackTapped), for: .touchUpInside)

        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.setTitleColor(UIColor.white.withAlphaComponent(0.5), for: .normal)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)

        statusLabel.font = .systemFont(ofSize: 14, weight: .medium)
        statusLabel.textColor = UIColor(red: 0.3, green: 0.85, blue: 0.5, alpha: 1)
        statusLabel.textAlignment = .center
        statusLabel.isHidden = true

        spinner.color = .white
        spinner.hidesWhenStopped = true

        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(subtitleLabel)
        stackView.addArrangedSubview(platformStack)

        categoryScroll.translatesAutoresizingMaskIntoConstraints = false
        categoryStack.axis = .horizontal
        categoryStack.spacing = 8
        categoryStack.translatesAutoresizingMaskIntoConstraints = false
        categoryScroll.addSubview(categoryStack)
        categoryScroll.showsHorizontalScrollIndicator = false
        stackView.addArrangedSubview(categoryScroll)

        NSLayoutConstraint.activate([
            categoryScroll.heightAnchor.constraint(equalToConstant: 36),
            categoryStack.topAnchor.constraint(equalTo: categoryScroll.topAnchor),
            categoryStack.bottomAnchor.constraint(equalTo: categoryScroll.bottomAnchor),
            categoryStack.leadingAnchor.constraint(equalTo: categoryScroll.leadingAnchor),
            categoryStack.trailingAnchor.constraint(equalTo: categoryScroll.trailingAnchor),
            categoryStack.heightAnchor.constraint(equalTo: categoryScroll.heightAnchor)
        ])

        for category in ContentCategory.allCases {
            let btn = UIButton(type: .system)
            btn.setTitle(category.displayName, for: .normal)
            btn.titleLabel?.font = .systemFont(ofSize: 11, weight: .medium)
            btn.layer.cornerRadius = 8
            btn.contentEdgeInsets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
            btn.addTarget(self, action: #selector(categoryTapped(_:)), for: .touchUpInside)
            btn.tag = ContentCategory.allCases.firstIndex(of: category) ?? 0
            categoryStack.addArrangedSubview(btn)
        }
        updateCategorySelection()

        stackView.addArrangedSubview(trackButton)
        stackView.addArrangedSubview(cancelButton)
        stackView.addArrangedSubview(spinner)
        stackView.addArrangedSubview(statusLabel)

        view.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            trackButton.heightAnchor.constraint(equalToConstant: 50),
            platformStack.heightAnchor.constraint(equalToConstant: 40)
        ])
    }

    private func updatePlatformSelection() {
        for (platform, button) in platformButtons {
            let selected = platform == detectedPlatform
            button.backgroundColor = selected
                ? UIColor(red: 0.55, green: 0.35, blue: 0.95, alpha: 1)
                : UIColor.white.withAlphaComponent(0.1)
            button.setTitleColor(.white, for: .normal)
        }
    }

    @objc private func categoryTapped(_ sender: UIButton) {
        let index = sender.tag
        guard index < ContentCategory.allCases.count else { return }
        detectedCategory = ContentCategory.allCases[index]
        updateCategorySelection()
    }

    private func updateCategorySelection() {
        for (i, view) in categoryStack.arrangedSubviews.enumerated() {
            guard let btn = view as? UIButton, i < ContentCategory.allCases.count else { continue }
            let selected = ContentCategory.allCases[i] == detectedCategory
            btn.backgroundColor = selected
                ? UIColor(red: 0.55, green: 0.35, blue: 0.95, alpha: 1)
                : UIColor.white.withAlphaComponent(0.1)
            btn.setTitleColor(.white, for: .normal)
        }
    }

    @objc private func platformTapped(_ sender: UIButton) {
        let index = sender.tag
        guard index < SocialPlatform.allCases.count else { return }
        detectedPlatform = SocialPlatform.allCases[index]
        updatePlatformSelection()
    }

    @objc private func trackTapped() {
        guard ShareEventManager.loadUser()?.friendID != nil else {
            showStatus("Connect a friend in ShareTrack first", success: false)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { self.completeRequest() }
            return
        }

        spinner.startAnimating()
        trackButton.isEnabled = false

        if let event = ShareEventManager.logShare(platform: detectedPlatform, contentURL: contentURL, category: detectedCategory) {
            WidgetCenter.shared.reloadAllTimelines()
            showStatus("Tracked! +\(event.pointsEarned) points", success: true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { self.completeRequest() }
        } else {
            showStatus("Already tracked recently", success: false)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { self.completeRequest() }
        }
    }

    @objc private func cancelTapped() {
        completeRequest()
    }

    private func showStatus(_ text: String, success: Bool) {
        spinner.stopAnimating()
        statusLabel.text = text
        statusLabel.textColor = success
            ? UIColor(red: 0.3, green: 0.85, blue: 0.5, alpha: 1)
            : UIColor(red: 1.0, green: 0.6, blue: 0.3, alpha: 1)
        statusLabel.isHidden = false
    }

    private func processSharedContent() {
        guard let extensionItems = extensionContext?.inputItems as? [NSExtensionItem] else { return }

        for item in extensionItems {
            guard let attachments = item.attachments else { continue }
            for provider in attachments {
                if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                    provider.loadItem(forTypeIdentifier: UTType.url.identifier) { [weak self] item, _ in
                        DispatchQueue.main.async {
                            if let url = item as? URL {
                                self?.contentURL = url.absoluteString
                                self?.detectedPlatform = PlatformURLDetector.detectPlatform(from: url)
                                self?.updatePlatformSelection()
                            }
                        }
                    }
                    return
                }
                if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                    provider.loadItem(forTypeIdentifier: UTType.plainText.identifier) { [weak self] item, _ in
                        DispatchQueue.main.async {
                            if let text = item as? String,
                               let url = PlatformURLDetector.extractURL(from: text) {
                                self?.contentURL = url.absoluteString
                                self?.detectedPlatform = PlatformURLDetector.detectPlatform(from: url)
                                self?.updatePlatformSelection()
                            }
                        }
                    }
                    return
                }
            }
        }
    }

    private func completeRequest() {
        extensionContext?.completeRequest(returningItems: nil)
    }
}
