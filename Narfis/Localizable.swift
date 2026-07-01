import Foundation
import Combine

enum AppLanguage: String, CaseIterable {
    case english = "en"
    case korean = "ko"
    
    var displayName: String {
        switch self {
        case .english: return "English"
        case .korean: return "한국어"
        }
    }
}

class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    
    @Published var currentLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "appLanguage")
        }
    }
    
    init() {
        let savedLanguage = UserDefaults.standard.string(forKey: "appLanguage") ?? "ko"
        self.currentLanguage = AppLanguage(rawValue: savedLanguage) ?? .korean
    }
    
    func localizedString(_ key: LocalizedStringKey) -> String {
        return strings[key]?[currentLanguage] ?? key.rawValue
    }
}

enum LocalizedStringKey: String {
    case search
    case settings
    case dockSettings
    case selectAppsDescription
    case browseApps
    case searchApps
    case selectDeselect
    case savePreferences
    case appsSelected
    case deselectAll
    case save
    case cancel
    case wifiSettings
    case batterySettings
    case volumeSettings
    case openCalendar
    case loading
    case searchingApps
    case noAppsFound
    case systemApps
    case thirdPartyApps
    case language
    case dockColor
    case appearance
    case darkMode
    case lightMode
    case customColor
    case opacity
    case blurEffect
    case backgroundImage
    case chooseImage
    case removeImage
    case imageBlur
    case dockSize
    case small
    case medium
    case large
}

private let strings: [LocalizedStringKey: [AppLanguage: String]] = [
    .search: [
        .english: "Search",
        .korean: "검색"
    ],
    .settings: [
        .english: "Settings",
        .korean: "설정"
    ],
    .dockSettings: [
        .english: "Narfis Dock Settings",
        .korean: "Narfis Dock 설정"
    ],
    .selectAppsDescription: [
        .english: "Select apps to display in dock",
        .korean: "Dock에 표시할 앱을 선택하세요"
    ],
    .browseApps: [
        .english: "Browse all installed apps",
        .korean: "설치된 모든 앱 탐색"
    ],
    .searchApps: [
        .english: "Search apps...",
        .korean: "앱 검색..."
    ],
    .selectDeselect: [
        .english: "Click to select/deselect",
        .korean: "클릭하여 선택/해제"
    ],
    .savePreferences: [
        .english: "Save your preferences",
        .korean: "환경설정 저장"
    ],
    .appsSelected: [
        .english: "apps selected",
        .korean: "개 앱 선택됨"
    ],
    .deselectAll: [
        .english: "Deselect All",
        .korean: "모두 선택 해제"
    ],
    .save: [
        .english: "Save",
        .korean: "저장"
    ],
    .cancel: [
        .english: "Cancel",
        .korean: "취소"
    ],
    .wifiSettings: [
        .english: "Wi-Fi Settings",
        .korean: "Wi-Fi 설정"
    ],
    .batterySettings: [
        .english: "Battery Settings",
        .korean: "배터리 설정"
    ],
    .volumeSettings: [
        .english: "Volume Settings",
        .korean: "음량 설정"
    ],
    .openCalendar: [
        .english: "Open Calendar",
        .korean: "캘린더 열기"
    ],
    .loading: [
        .english: "Loading...",
        .korean: "로딩 중..."
    ],
    .searchingApps: [
        .english: "Searching apps...",
        .korean: "앱 검색 중..."
    ],
    .noAppsFound: [
        .english: "No apps found",
        .korean: "앱을 찾을 수 없습니다"
    ],
    .systemApps: [
        .english: "System Apps",
        .korean: "시스템 앱"
    ],
    .thirdPartyApps: [
        .english: "Third-party Apps",
        .korean: "서드파티 앱"
    ],
    .language: [
        .english: "Language",
        .korean: "언어"
    ],
    .dockColor: [
        .english: "Dock Color",
        .korean: "Dock 색상"
    ],
    .appearance: [
        .english: "Appearance",
        .korean: "외관"
    ],
    .darkMode: [
        .english: "Dark Mode",
        .korean: "다크 모드"
    ],
    .lightMode: [
        .english: "Light Mode",
        .korean: "라이트 모드"
    ],
    .customColor: [
        .english: "Custom Color",
        .korean: "커스텀 색상"
    ],
    .opacity: [
        .english: "Opacity",
        .korean: "투명도"
    ],
    .blurEffect: [
        .english: "Blur Effect",
        .korean: "블러 효과"
    ],
    .backgroundImage: [
        .english: "Background Image",
        .korean: "배경 이미지"
    ],
    .chooseImage: [
        .english: "Choose Image",
        .korean: "이미지 선택"
    ],
    .removeImage: [
        .english: "Remove Image",
        .korean: "이미지 제거"
    ],
    .imageBlur: [
        .english: "Image Blur",
        .korean: "이미지 블러"
    ],
    .dockSize: [
        .english: "Dock Size",
        .korean: "Dock 크기"
    ],
    .small: [
        .english: "Small",
        .korean: "작게"
    ],
    .medium: [
        .english: "Medium",
        .korean: "보통"
    ],
    .large: [
        .english: "Large",
        .korean: "크게"
    ]
]

extension String {
    static func localized(_ key: LocalizedStringKey) -> String {
        return LocalizationManager.shared.localizedString(key)
    }
}
