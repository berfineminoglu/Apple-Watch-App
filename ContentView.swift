import SwiftUI
import WatchKit

private func playTapFeedback(_ haptic: WKHapticType = .click) {
    WKInterfaceDevice.current().play(haptic)
}

// MARK: - App Settings
final class AppSettings: ObservableObject {
    enum AppTheme: String, CaseIterable, Identifiable {
        case dark  = "Koyu"
        case light = "Açık"
        case red   = "Kırmızı"
        case blue  = "Mavi"
        var id: String { rawValue }

        func displayName(language: AppLanguage) -> String {
            switch self {
            case .dark:
                return language == .turkish ? "Koyu" : "Dark"
            case .light:
                return language == .turkish ? "Açık" : "Light"
            case .red:
                return language == .turkish ? "Kırmızı" : "Red"
            case .blue:
                return language == .turkish ? "Mavi" : "Blue"
            }
        }
        var accent: Color {
            switch self {
            case .dark:  return Color(red: 0.86, green: 0.12, blue: 0.16)
            case .light: return Color(red: 0.86, green: 0.12, blue: 0.16)
            case .red:   return Color(red: 0.95, green: 0.25, blue: 0.10)
            case .blue:  return Color(red: 0.10, green: 0.50, blue: 0.95)
            }
        }
        var background: Color {
            switch self {
            case .dark:  return .black
            case .light: return .white
            case .red:   return Color(red: 0.14, green: 0.06, blue: 0.06)
            case .blue:  return Color(red: 0.06, green: 0.10, blue: 0.16)
            }
        }
        var foreground: Color {
            switch self {
            case .dark, .red, .blue: return .white
            case .light: return Color(red: 0.08, green: 0.08, blue: 0.10)
            }
        }
        var surface: Color {
            switch self {
            case .dark:  return Color(red: 0.14, green: 0.14, blue: 0.14)
            case .light: return Color(red: 0.88, green: 0.88, blue: 0.90)
            case .red:   return Color(red: 0.20, green: 0.10, blue: 0.10)
            case .blue:  return Color(red: 0.10, green: 0.14, blue: 0.22)
            }
        }
    }
    enum AppLanguage: String, CaseIterable, Identifiable {
        case turkish = "Türkçe"
        case english = "English"
        var id: String { rawValue }

        func displayName(language: AppLanguage) -> String {
            switch self {
            case .turkish:
                return language == .turkish ? "Türkçe" : "Turkish"
            case .english:
                return "English"
            }
        }
    }

    @Published var theme: AppTheme    = .dark
    @Published var voiceEnabled: Bool = true
    @Published var language: AppLanguage = .turkish

    func t(_ turkish: String, _ english: String) -> String {
        language == .turkish ? turkish : english
    }
}

struct ContentView: View {
    private enum RootScreen {
        case recipePager
        case detail
    }

    private enum RecipePagerPage: Int {
        case choose
        case recipes
        case notifications
    }

    @StateObject private var settings = AppSettings()
    @Environment(\.scenePhase) private var scenePhase
    @State private var screen: RootScreen = .recipePager
    @State private var recipePagerSelection: RecipePagerPage = .choose
    @State private var selectedRecipe: Recipe = .etSote
    @State private var showLaunchSplash = false
    @State private var wentToBackground = false

    // Cooking timer state (persists across navigation)
    @State private var isCooking = false
    @State private var cookingIsRunning = false
    @State private var cookingAccumulatedElapsed: TimeInterval = 0
    @State private var cookingRunningSince: Date? = nil
    @State private var cookingHasStarted = false
    private let demoDuration: TimeInterval = 10

    // Notifications and toast
    @State private var cookingNotifications: [CookingNotificationItem] = []
    @State private var showCookingDoneToast = false

    var body: some View {
        ZStack {
            settings.theme.background.ignoresSafeArea()
            screenView

            if showLaunchSplash {
                LogoPage(onDismiss: {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        showLaunchSplash = false
                    }
                })
                .transition(.opacity)
                .zIndex(1)
            }

            if showCookingDoneToast {
                VStack {
                    Spacer()
                    Text(settings.t("Afiyet olsun", "Bon appétit"))
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Capsule(style: .continuous)
                                .fill(Color(red: 0.22, green: 0.60, blue: 0.14))
                        )
                    Spacer().frame(height: 20)
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
                .zIndex(2)
                .ignoresSafeArea()
            }
        }
        .environmentObject(settings)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background {
                wentToBackground = true
            } else if newPhase == .active && wentToBackground {
                wentToBackground = false
                showLaunchSplash = true
            }
        }
    }

    @ViewBuilder
    private var screenView: some View {
        switch screen {
        case .recipePager:
            TabView(selection: $recipePagerSelection) {
                TarifSecPage(
                    isCooking: isCooking,
                    recipe: selectedRecipe,
                    demoDuration: demoDuration,
                    cookingIsRunning: $cookingIsRunning,
                    cookingAccumulatedElapsed: $cookingAccumulatedElapsed,
                    cookingRunningSince: $cookingRunningSince,
                    cookingHasStarted: $cookingHasStarted,
                    onChoose: {
                        playTapFeedback()
                        withAnimation(.easeInOut(duration: 0.28)) {
                            recipePagerSelection = .recipes
                        }
                    },
                    onNotifications: {
                        playTapFeedback()
                        withAnimation(.easeInOut(duration: 0.28)) {
                            recipePagerSelection = .notifications
                        }
                    },
                    onKeepWarmEnabled: {
                        cookingNotifications.append(
                            CookingNotificationItem(recipe: selectedRecipe, timestamp: Date(), type: .keepWarm)
                        )
                    },
                    onCookingComplete: {
                        isCooking = false
                        cookingNotifications.append(
                            CookingNotificationItem(recipe: selectedRecipe, timestamp: Date(), type: .completed)
                        )
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showCookingDoneToast = true
                        }
                        Task {
                            try? await Task.sleep(nanoseconds: 2_000_000_000)
                            await MainActor.run {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showCookingDoneToast = false
                                }
                                cookingAccumulatedElapsed = 0
                                cookingRunningSince = nil
                                cookingIsRunning = false
                                cookingHasStarted = false
                            }
                        }
                    }
                )
                .tag(RecipePagerPage.choose)

                RecipesPage(
                    selectedRecipe: $selectedRecipe,
                    onContinue: {
                        playTapFeedback()
                        withAnimation(.easeInOut(duration: 0.28)) {
                            screen = .detail
                        }
                    }
                )
                .tag(RecipePagerPage.recipes)

                NotificationsPage(
                    recipe: selectedRecipe,
                    notifications: cookingNotifications,
                    onOpenRecipe: {
                        playTapFeedback()
                        withAnimation(.easeInOut(duration: 0.28)) {
                            screen = .detail
                        }
                    },
                    onReturnToCooking: {
                        playTapFeedback()
                        withAnimation(.easeInOut(duration: 0.28)) {
                            recipePagerSelection = .choose
                        }
                    }
                )
                .tag(RecipePagerPage.notifications)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .background(settings.theme.background.ignoresSafeArea())
        case .detail:
            DetailPage(
                recipe: selectedRecipe,
                isCooking: isCooking,
                onBack: {
                    playTapFeedback()
                    withAnimation(.easeInOut(duration: 0.28)) {
                        recipePagerSelection = .recipes
                        screen = .recipePager
                    }
                },
                onContinue: {
                    playTapFeedback()
                    cookingAccumulatedElapsed = 0
                    cookingRunningSince = nil
                    cookingIsRunning = false
                    cookingHasStarted = false
                    isCooking = true
                    cookingNotifications.append(
                        CookingNotificationItem(recipe: selectedRecipe, timestamp: Date(), type: .started)
                    )
                    withAnimation(.easeInOut(duration: 0.28)) {
                        recipePagerSelection = .choose
                        screen = .recipePager
                    }
                }
            )
        }
    }
}

// MARK: - Recipe Model

enum Recipe: String, CaseIterable, Identifiable {
    case etSote
    case tazeFasulye
    case kabakYemegi
    case garniturluPilav
    case humus
    case mercimekCorbasi

    var id: String { rawValue }

    var title: String {
        switch self {
        case .etSote: return "Et Sote"
        case .tazeFasulye: return "Taze Fasulye"
        case .kabakYemegi: return "Kabak Yemeği"
        case .garniturluPilav: return "Garnitürlü Pilav"
        case .humus: return "Humus"
        case .mercimekCorbasi: return "Mercimek Çorbası"
        }
    }

    func localizedTitle(language: AppSettings.AppLanguage) -> String {
        switch (self, language) {
        case (.etSote, .turkish): return "Et Sote"
        case (.etSote, .english): return "Meat Saute"
        case (.tazeFasulye, .turkish): return "Taze Fasulye"
        case (.tazeFasulye, .english): return "Green Beans"
        case (.kabakYemegi, .turkish): return "Kabak Yemeği"
        case (.kabakYemegi, .english): return "Zucchini Stew"
        case (.garniturluPilav, .turkish): return "Garnitürlü Pilav"
        case (.garniturluPilav, .english): return "Rice with Vegetables"
        case (.humus, .turkish): return "Humus"
        case (.humus, .english): return "Hummus"
        case (.mercimekCorbasi, .turkish): return "Mercimek Çorbası"
        case (.mercimekCorbasi, .english): return "Lentil Soup"
        }
    }

    var imageName: String {
        switch self {
        case .etSote: return "et-sote"
        case .tazeFasulye: return "taze-fasulye"
        case .kabakYemegi: return "kabak-yemegi"
        case .garniturluPilav: return "garniturlu-pilav"
        case .humus: return "humus"
        case .mercimekCorbasi: return "mercimek-corbasi"
        }
    }

    func durationText(language: AppSettings.AppLanguage) -> String {
        let unit = language == .turkish ? "dk" : "min"
        switch self {
        case .etSote: return "30 \(unit)"
        case .tazeFasulye: return "26 \(unit)"
        case .kabakYemegi: return "22 \(unit)"
        case .garniturluPilav: return "18 \(unit)"
        case .humus: return "12 \(unit)"
        case .mercimekCorbasi: return "25 \(unit)"
        }
    }

    var durationMinutes: Int {
        switch self {
        case .etSote: return 30
        case .tazeFasulye: return 26
        case .kabakYemegi: return 22
        case .garniturluPilav: return 18
        case .humus: return 12
        case .mercimekCorbasi: return 25
        }
    }

    var durationSeconds: Int {
        durationMinutes * 60
    }

    var calories: String {
        switch self {
        case .etSote: return "400 cal"
        case .tazeFasulye: return "220 cal"
        case .kabakYemegi: return "180 cal"
        case .garniturluPilav: return "280 cal"
        case .humus: return "160 cal"
        case .mercimekCorbasi: return "150 cal"
        }
    }

    func remainingText(language: AppSettings.AppLanguage) -> String {
        let unit = language == .turkish ? "dk" : "min"
        switch self {
        case .etSote: return "21 \(unit)"
        case .tazeFasulye: return "18 \(unit)"
        case .kabakYemegi: return "14 \(unit)"
        case .garniturluPilav: return "12 \(unit)"
        case .humus: return "8 \(unit)"
        case .mercimekCorbasi: return "16 \(unit)"
        }
    }

    func remainingText(for remainingSeconds: Int, language: AppSettings.AppLanguage) -> String {
        let roundedMinutes = max(0, Int(ceil(Double(remainingSeconds) / 60.0)))
        return "\(roundedMinutes) \(language == .turkish ? "dk" : "min")"
    }

    func notificationTitle(language: AppSettings.AppLanguage) -> String {
        language == .turkish ? "\"Sıcak Tutma\"" : "\"Keep Warm\""
    }

    func notificationText(language: AppSettings.AppLanguage) -> String {
        if language == .turkish {
            return "\(localizedTitle(language: language)) için \(notificationTitle(language: language)) moduna geçildi."
        } else {
            return "Switched to \(notificationTitle(language: language)) mode for \(localizedTitle(language: language))."
        }
    }

    func alertText(language: AppSettings.AppLanguage) -> String {
        language == .turkish ? "Yemeğin 5 dakikaya hazır :)" : "Your meal will be ready in 5 minutes :)"
    }

    func ingredientLines(language: AppSettings.AppLanguage) -> [String] {
        switch language {
        case .turkish:
            switch self {
            case .etSote:
                return ["250 g kuşbaşı et", "1 soğan, 1 biber", "Domates salçası, baharat"]
            case .tazeFasulye:
                return ["500 g taze fasulye", "Domates, soğan", "Zeytinyağı, tuz"]
            case .kabakYemegi:
                return ["3 kabak", "Havuç, dereotu", "Yoğurtlu servis"]
            case .garniturluPilav:
                return ["1 su bardağı pirinç", "Garnitür, bezelye", "Tereyağı, tuz"]
            case .humus:
                return ["2 su bardağı nohut", "Tahin, limon, sarımsak", "Zeytinyağı, kimyon"]
            case .mercimekCorbasi:
                return ["1 su bardağı kırmızı mercimek", "Soğan, havuç", "Salça, tereyağı, baharat"]
            }
        case .english:
            switch self {
            case .etSote:
                return ["250 g diced beef", "1 onion, 1 pepper", "Tomato paste, spices"]
            case .tazeFasulye:
                return ["500 g green beans", "Tomatoes, onion", "Olive oil, salt"]
            case .kabakYemegi:
                return ["3 zucchinis", "Carrot, dill", "Serve with yogurt"]
            case .garniturluPilav:
                return ["1 cup rice", "Mixed vegetables, peas", "Butter, salt"]
            case .humus:
                return ["2 cups chickpeas", "Tahini, lemon, garlic", "Olive oil, cumin"]
            case .mercimekCorbasi:
                return ["1 cup red lentils", "Onion, carrot", "Tomato paste, butter, spices"]
            }
        }
    }

    func preparationLines(language: AppSettings.AppLanguage) -> [String] {
        switch language {
        case .turkish:
            switch self {
            case .etSote:
                return ["Et ve sebzeleri yerleştir.", "Süreyi onayla ve başlat."]
            case .tazeFasulye:
                return ["Malzemeleri tencereye ekle.", "Suyu ve baharatı ayarla."]
            case .kabakYemegi:
                return ["Kabakları doğra.", "Kısa pişirme programını seç."]
            case .garniturluPilav:
                return ["Pirinci ve garnitürü ekle.", "Pişirme süresini başlat."]
            case .humus:
                return ["Nohutu ve tahini ekle.", "Karıştırıp kıvam ver."]
            case .mercimekCorbasi:
                return ["Mercimek ve sebzeleri ekle.", "Çorba programını başlat."]
            }
        case .english:
            switch self {
            case .etSote:
                return ["Place the beef and vegetables.", "Confirm the time and start."]
            case .tazeFasulye:
                return ["Add the ingredients to the pot.", "Adjust water and spices."]
            case .kabakYemegi:
                return ["Chop the zucchinis.", "Choose the short cooking program."]
            case .garniturluPilav:
                return ["Add rice and vegetables.", "Start the cooking cycle."]
            case .humus:
                return ["Add chickpeas and tahini.", "Blend and adjust the texture."]
            case .mercimekCorbasi:
                return ["Add lentils and vegetables.", "Start the soup program."]
            }
        }
    }
}

// MARK: - Cooking Notification

enum CookingNotificationType {
    case started
    case completed
    case keepWarm
}

struct CookingNotificationItem: Identifiable {
    let id = UUID()
    let recipe: Recipe
    let timestamp: Date
    let type: CookingNotificationType
}

struct RecipeTheme {
    let accent: Color
    let accentSoft: Color
    let accentMuted: Color
    let surface: Color
    let surfaceStrong: Color
    let border: Color
}

extension Recipe {
    var theme: RecipeTheme {
        switch self {
        case .etSote:
            return RecipeTheme(
                accent: Color(red: 0.88, green: 0.16, blue: 0.20),
                accentSoft: Color(red: 0.23, green: 0.10, blue: 0.11),
                accentMuted: Color(red: 0.57, green: 0.12, blue: 0.14),
                surface: Color(red: 0.15, green: 0.14, blue: 0.14),
                surfaceStrong: Color(red: 0.19, green: 0.16, blue: 0.16),
                border: Color.white.opacity(0.08)
            )
        case .tazeFasulye:
            return RecipeTheme(
                accent: Color(red: 0.24, green: 0.66, blue: 0.27),
                accentSoft: Color(red: 0.10, green: 0.20, blue: 0.11),
                accentMuted: Color(red: 0.16, green: 0.46, blue: 0.18),
                surface: Color(red: 0.13, green: 0.15, blue: 0.13),
                surfaceStrong: Color(red: 0.16, green: 0.19, blue: 0.16),
                border: Color.white.opacity(0.08)
            )
        case .kabakYemegi:
            return RecipeTheme(
                accent: Color(red: 0.92, green: 0.61, blue: 0.17),
                accentSoft: Color(red: 0.20, green: 0.18, blue: 0.09),
                accentMuted: Color(red: 0.61, green: 0.50, blue: 0.13),
                surface: Color(red: 0.15, green: 0.15, blue: 0.11),
                surfaceStrong: Color(red: 0.19, green: 0.18, blue: 0.14),
                border: Color.white.opacity(0.08)
            )
        case .garniturluPilav:
            return RecipeTheme(
                accent: Color(red: 0.72, green: 0.76, blue: 0.24),
                accentSoft: Color(red: 0.18, green: 0.19, blue: 0.10),
                accentMuted: Color(red: 0.50, green: 0.56, blue: 0.16),
                surface: Color(red: 0.14, green: 0.15, blue: 0.12),
                surfaceStrong: Color(red: 0.18, green: 0.20, blue: 0.15),
                border: Color.white.opacity(0.08)
            )
        case .humus:
            return RecipeTheme(
                accent: Color(red: 0.88, green: 0.73, blue: 0.30),
                accentSoft: Color(red: 0.22, green: 0.19, blue: 0.10),
                accentMuted: Color(red: 0.62, green: 0.51, blue: 0.17),
                surface: Color(red: 0.16, green: 0.15, blue: 0.11),
                surfaceStrong: Color(red: 0.20, green: 0.19, blue: 0.15),
                border: Color.white.opacity(0.08)
            )
        case .mercimekCorbasi:
            return RecipeTheme(
                accent: Color(red: 0.95, green: 0.56, blue: 0.12),
                accentSoft: Color(red: 0.22, green: 0.12, blue: 0.07),
                accentMuted: Color(red: 0.66, green: 0.31, blue: 0.10),
                surface: Color(red: 0.17, green: 0.13, blue: 0.10),
                surfaceStrong: Color(red: 0.22, green: 0.17, blue: 0.13),
                border: Color.white.opacity(0.08)
            )
        }
    }
}

// MARK: - Shared Components

struct PageDots: View {
    let activeIndex: Int
    let count: Int
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<count, id: \.self) { index in
                Circle()
                    .fill(index == activeIndex ? settings.theme.foreground : settings.theme.foreground.opacity(0.38))
                    .frame(width: index == activeIndex ? 7 : 5, height: index == activeIndex ? 7 : 5)
                    .animation(.easeInOut(duration: 0.2), value: activeIndex)
            }
        }
        .padding(.top, 4)
        .padding(.bottom, 4)
        .accessibilityHidden(true)
    }

    init(activeIndex: Int, count: Int = 3) {
        self.activeIndex = activeIndex
        self.count = count
    }
}

struct TopBar: View {
    let title: String
    let titleColor: Color
    let showBack: Bool
    var onBack: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 6) {
            if showBack {
                Button(action: { onBack?() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.black)
                        .frame(width: 20, height: 20)
                        .background(Circle().fill(Color.red))
                }
                .buttonStyle(.plain)
            }

            if !title.isEmpty {
                Text(title)
                    .font(.system(size: showBack ? 15 : 16, weight: showBack ? .medium : .semibold, design: .rounded))
                    .foregroundStyle(titleColor)
                    .lineLimit(1)
            }

            Spacer(minLength: 4)
        }
    }
}

struct RecipeSummaryCard: View {
    let recipe: Recipe
    let subtitle: String
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        HStack(spacing: 8) {
            RecipeThumbnail(recipe: recipe, size: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(recipe.localizedTitle(language: settings.language))
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .foregroundStyle(settings.theme.foreground)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                Text(subtitle)
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundStyle(settings.theme.foreground.opacity(0.8))
                    .lineLimit(1)
            }
            Spacer(minLength: 4)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(settings.theme.surface)
        )
    }
}

struct RecipeButtonRow: View {
    let recipe: Recipe
    let isSelected: Bool
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        HStack(spacing: 10) {
            RecipeThumbnail(recipe: recipe, size: 28)
            Text(recipe.localizedTitle(language: settings.language))
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(settings.theme.foreground)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
            Spacer(minLength: 4)
        }
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, minHeight: 42, maxHeight: 42)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(settings.theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(isSelected ? settings.theme.foreground.opacity(0.22) : Color.clear, lineWidth: 1)
        )
    }
}

struct RecipeChip: View {
    let label: String
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        Text(label)
            .font(.system(size: 13, weight: .medium, design: .rounded))
            .foregroundStyle(settings.theme.foreground)
            .frame(maxWidth: .infinity, minHeight: 30)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(settings.theme.surface)
            )
    }
}

struct ExpandableRow: View {
    let title: String
    let lines: [String]
    @State private var expanded = false
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Button {
                withAnimation(.easeInOut(duration: 0.18)) {
                    expanded.toggle()
                }
            } label: {
                HStack {
                    Text(title)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(settings.theme.foreground)
                    Spacer(minLength: 8)
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(settings.theme.foreground.opacity(0.8))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(settings.theme.surface)
                )
            }
            .buttonStyle(.plain)

            if expanded {
                VStack(alignment: .leading, spacing: 3) {
                    ForEach(lines, id: \.self) { line in
                        Text("• \(line)")
                            .font(.system(size: 11.5, weight: .regular, design: .rounded))
                            .foregroundStyle(settings.theme.foreground.opacity(0.84))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.horizontal, 11)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

struct HeatBadge: View {
    var isActive: Bool = false
    var onToggle: (() -> Void)? = nil

    var body: some View {
        let badge = Circle()
            .fill(isActive ? Color(red: 1.0, green: 0.52, blue: 0.08) : Color.red)
            .frame(width: 24, height: 24)
            .overlay(
                Image(systemName: "flame.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
            )
        Group {
            if let onToggle {
                Button(action: onToggle) { badge }.buttonStyle(.plain)
            } else {
                badge
            }
        }
    }
}


struct StatusPill: View {
    let title: String
    let tint: Color

    var body: some View {
        Text(title)
            .font(.system(size: 11.5, weight: .semibold, design: .rounded))
            .foregroundStyle(tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule(style: .continuous)
                    .fill(tint.opacity(0.14))
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(tint.opacity(0.20), lineWidth: 1)
            )
    }
}


struct CompactActionCard: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(tint.opacity(0.18))
                        .frame(width: 24, height: 24)

                    Image(systemName: systemImage)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(tint)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.system(size: 13.5, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Text(subtitle)
                        .font(.system(size: 10.5, weight: .regular, design: .rounded))
                        .foregroundStyle(.white.opacity(0.68))
                        .lineLimit(1)
                }

                Spacer(minLength: 4)

                Image(systemName: "chevron.right")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.38))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, minHeight: 40, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(Color.white.opacity(0.055))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .stroke(tint.opacity(0.12), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Pages

struct TarifSecPage: View {
    let isCooking: Bool
    let recipe: Recipe
    let demoDuration: TimeInterval
    @Binding var cookingIsRunning: Bool
    @Binding var cookingAccumulatedElapsed: TimeInterval
    @Binding var cookingRunningSince: Date?
    @Binding var cookingHasStarted: Bool
    let onChoose: () -> Void
    let onNotifications: () -> Void
    let onKeepWarmEnabled: () -> Void
    let onCookingComplete: () -> Void

    var body: some View {
        if isCooking {
            CookingPage(
                recipe: recipe,
                demoDuration: demoDuration,
                isRunning: $cookingIsRunning,
                accumulatedElapsed: $cookingAccumulatedElapsed,
                runningSince: $cookingRunningSince,
                hasStarted: $cookingHasStarted,
                onNotifications: onNotifications,
                onCookingComplete: onCookingComplete,
                onKeepWarmEnabled: onKeepWarmEnabled
            )
        } else {
            ChooseRecipePage(onChoose: onChoose)
        }
    }
}


struct RecipesPage: View {
    @Binding var selectedRecipe: Recipe
    let onContinue: () -> Void
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        ZStack {
            settings.theme.background.ignoresSafeArea()

            VStack(spacing: 8) {
                TopBar(title: settings.t("Tariflerim", "My Recipes"), titleColor: Color(red: 0.88, green: 0.18, blue: 0.22), showBack: false)
                    .padding(.top, 2)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 8) {
                        ForEach(Recipe.allCases) { recipe in
                            Button(action: {
                                selectedRecipe = recipe
                                onContinue()
                            }) {
                                RecipeButtonRow(recipe: recipe, isSelected: recipe == selectedRecipe)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.top, 4)
                    .padding(.bottom, 4)
                }
                .frame(maxHeight: .infinity)

                PageDots(activeIndex: 1, count: 3)
            }
            .padding(.horizontal, 4)
            .padding(.top, 4)
            .padding(.bottom, 2)
        }
    }
}

struct StartPage: View {
    let recipe: Recipe
    let onBack: () -> Void
    let onPlay: () -> Void
    let onChooseRecipe: () -> Void
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        ZStack {
            settings.theme.background.ignoresSafeArea()

            VStack(spacing: 8) {
                HStack(spacing: 6) {
                    HeatBadge()
                    Spacer(minLength: 4)
                }
                .padding(.top, 2)

                Spacer(minLength: 0)

                Button(action: onPlay) {
                    ZStack {
                        Circle()
                            .stroke(Color.green.opacity(0.8), style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [16, 8]))
                            .frame(width: 84, height: 84)
                        Circle()
                            .fill(Color(red: 0.32, green: 0.68, blue: 0.18))
                            .frame(width: 64, height: 64)
                        Image(systemName: "play.fill")
                            .font(.system(size: 25, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .buttonStyle(.plain)
                .padding(.top, 2)

                Spacer(minLength: 8)

                RecipeSummaryCard(recipe: recipe, subtitle: settings.t("Kalan süre", "Remaining") + " : \(recipe.durationMinutes) \(settings.t("dk", "min"))")
                    .onTapGesture(perform: onChooseRecipe)

                PageDots(activeIndex: 0)
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 6)
        }
    }
}

// MARK: - Settings Page
struct SettingsPage: View {
    @EnvironmentObject private var settings: AppSettings
    let onBack: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {

                TopBar(
                    title: settings.t("Ayarlar", "Settings"),
                    titleColor: settings.theme.foreground,
                    showBack: true,
                    onBack: onBack
                )
                .padding(.top, 4)

                // Theme
                VStack(alignment: .leading, spacing: 6) {
                    Label(settings.t("Tema", "Theme"),
                          systemImage: "paintpalette.fill")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(settings.theme.foreground.opacity(0.6))

                    ForEach(AppSettings.AppTheme.allCases) { theme in
                        Button {
                            playTapFeedback()
                            settings.theme = theme
                        } label: {
                            HStack {
                                Circle()
                                    .fill(theme.background)
                                    .frame(width: 14, height: 14)
                                    .overlay(
                                        Circle()
                                            .stroke(settings.theme.foreground.opacity(0.25), lineWidth: 1)
                                    )
                                Text(theme.displayName(language: settings.language))
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundStyle(settings.theme.foreground)
                                Spacer()
                                if settings.theme == theme {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(theme.accent)
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 9, style: .continuous)
                                    .fill(settings.theme == theme
                                          ? theme.accent.opacity(0.18)
                                          : settings.theme.foreground.opacity(0.06))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                Divider().background(settings.theme.foreground.opacity(0.12))

                // Voice
                HStack {
                    Label(settings.t("Ses", "Voice"),
                          systemImage: settings.voiceEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(settings.theme.foreground.opacity(0.6))
                    Spacer()
                    Toggle("", isOn: $settings.voiceEnabled)
                        .labelsHidden()
                        .tint(settings.theme.accent)
                }

                Divider().background(settings.theme.foreground.opacity(0.12))

                // Language
                VStack(alignment: .leading, spacing: 6) {
                    Label(settings.t("Dil", "Language"),
                          systemImage: "globe")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(settings.theme.foreground.opacity(0.6))

                    ForEach(AppSettings.AppLanguage.allCases) { lang in
                        Button {
                            playTapFeedback()
                            settings.language = lang
                        } label: {
                            HStack {
                                Text(lang.displayName(language: settings.language))
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundStyle(settings.theme.foreground)
                                Spacer()
                                if settings.language == lang {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(settings.theme.accent)
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 9, style: .continuous)
                                    .fill(settings.language == lang
                                          ? settings.theme.accent.opacity(0.18)
                                          : settings.theme.foreground.opacity(0.06))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                Spacer(minLength: 8)
            }
            .padding(.horizontal, 8)
        }
        .background(settings.theme.background.ignoresSafeArea())
    }
}

// MARK: - Splash Screen

struct VestelLogoBadge: View {
    let size: CGFloat
    var body: some View {
        Image("VestelLogo")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
    }
}

struct LogoPage: View {
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VestelLogoBadge(size: 72)
        }
        .task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            onDismiss()
        }
    }
}

struct CookingPage: View {
    let recipe: Recipe
    let demoDuration: TimeInterval
    @Binding var isRunning: Bool
    @Binding var accumulatedElapsed: TimeInterval
    @Binding var runningSince: Date?
    @Binding var hasStarted: Bool
    let onNotifications: () -> Void
    let onCookingComplete: () -> Void
    let onKeepWarmEnabled: () -> Void

    @EnvironmentObject private var settings: AppSettings
    @State private var completionFired = false
    @State private var keepWarmEnabled = false
    @State private var showKeepWarmAlert = false

    private var totalSeconds: Int {
        recipe.durationSeconds
    }

    private func currentElapsed(at date: Date) -> TimeInterval {
        let runningElapsed = isRunning ? date.timeIntervalSince(runningSince ?? date) : 0
        return min(accumulatedElapsed + runningElapsed, demoDuration)
    }

    private func currentRemainingSeconds(at date: Date) -> Int {
        let progress = currentProgress(at: date)
        let remaining = Double(totalSeconds) * (1.0 - progress)
        return max(Int(ceil(remaining)), 0)
    }

    private func currentProgress(at date: Date) -> Double {
        guard demoDuration > 0 else { return 1 }
        let progress = currentElapsed(at: date) / demoDuration
        return min(max(progress, 0), 1)
    }

    private func toggleTimer(now: Date) {
        if isRunning {
            if let runningSince {
                accumulatedElapsed = min(accumulatedElapsed + now.timeIntervalSince(runningSince), demoDuration)
            }
            runningSince = nil
            isRunning = false
        } else {
            guard accumulatedElapsed < demoDuration else { return }
            runningSince = now
            isRunning = true
        }
    }

    private var ringStyle: StrokeStyle {
        StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
    }

    var body: some View {
        TimelineView(.periodic(from: Date(), by: 1)) { context in
            let remainingSeconds = currentRemainingSeconds(at: context.date)
            let progress = currentProgress(at: context.date)
            let isComplete = currentElapsed(at: context.date) >= demoDuration
            let isActive = isRunning && !isComplete
            let accent = isActive ? Color(red: 0.84, green: 0.14, blue: 0.18) : Color(red: 0.38, green: 0.72, blue: 0.22)
            let track = settings.theme.foreground.opacity(0.3)
            let buttonFill = isActive ? Color(red: 0.70, green: 0.14, blue: 0.16) : Color(red: 0.34, green: 0.64, blue: 0.22)

            ZStack {
                settings.theme.background.ignoresSafeArea()

                VStack(spacing: 8) {
                    HStack(spacing: 6) {
                        HeatBadge(isActive: keepWarmEnabled) {
                            playTapFeedback(.notification)
                            keepWarmEnabled.toggle()
                            if keepWarmEnabled {
                                showKeepWarmAlert = true
                                onKeepWarmEnabled()
                            }
                        }
                        Spacer(minLength: 4)
                    }
                    .padding(.top, 2)

                    Spacer(minLength: 0)

                    Button {
                        playTapFeedback()
                        withAnimation(.easeInOut(duration: 0.18)) {
                            toggleTimer(now: context.date)
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .stroke(track, style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [14, 8]))
                                .frame(width: 88, height: 88)

                            Circle()
                                .trim(from: 0, to: progress)
                                .stroke(accent, style: ringStyle)
                                .rotationEffect(.degrees(-90))
                                .frame(width: 88, height: 88)

                            Circle()
                                .fill(buttonFill)
                                .frame(width: 66, height: 66)

                            Image(systemName: isActive ? "pause.fill" : "play.fill")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                    .buttonStyle(.plain)
                    .onAppear {
                        // Detect re-appear with already-complete timer
                        let elapsed = min(
                            accumulatedElapsed + (isRunning ? Date().timeIntervalSince(runningSince ?? Date()) : 0),
                            demoDuration
                        )
                        if elapsed >= demoDuration && !completionFired {
                            completionFired = true
                            onCookingComplete()
                        }
                        guard !hasStarted else { return }
                        hasStarted = true
                        isRunning = true
                        runningSince = Date()
                    }

                    Spacer(minLength: 8)

                    RecipeSummaryCard(
                        recipe: recipe,
                        subtitle: isComplete ? settings.t("Tamamlandı", "Completed") : isActive ? settings.t("Kalan süre", "Remaining") + " : \(max(0, Int(ceil(Double(remainingSeconds) / 60.0)))) \(settings.t("dk", "min"))" : settings.t("Duraklatıldı", "Paused")
                    )
                    .onTapGesture(perform: onNotifications)

                    PageDots(activeIndex: 0)
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 6)
                .onChange(of: isComplete) { _, newVal in
                    if newVal && !completionFired {
                        completionFired = true
                        onCookingComplete()
                    }
                }
                .alert(settings.t("Sıcak Tutma Aktif", "Keep Warm Active"), isPresented: $showKeepWarmAlert) {
                    Button(settings.t("Tamam", "OK"), role: .cancel) {}
                } message: {
                    Text(settings.t("Yemeğiniz piştikten sonra sıcak tutma modunda kalacaktır.", "Your food will stay in keep warm mode after cooking."))
                }
            }
        }
    }
}

struct ChooseRecipePage: View {
    let onChoose: () -> Void
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        ZStack {
            settings.theme.background.ignoresSafeArea()

            VStack(spacing: 6) {
                HStack {
                    HeatBadge()
                    Spacer()
                }

                Spacer(minLength: 2)

                Button(action: onChoose) {
                    ZStack {
                        Circle()
                            .stroke(settings.theme.foreground.opacity(0.5), style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [14, 8]))
                            .frame(width: 82, height: 82)
                        Circle()
                            .fill(settings.theme.surface)
                            .frame(width: 60, height: 60)
                        Image(systemName: "play.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(settings.theme.foreground)
                    }
                }
                .buttonStyle(.plain)

                Spacer(minLength: 4)

                Button(action: onChoose) {
                    Text(settings.t("Tarif Seçiniz.", "Choose a Recipe"))
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(Color(red: 0.77, green: 0.08, blue: 0.13))
                        .frame(maxWidth: .infinity, minHeight: 38)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(settings.theme.surface)
                        )
                }
                .buttonStyle(.plain)

                PageDots(activeIndex: 0)
            }
            .padding(.horizontal, 4)
            .padding(.top, 4)
            .padding(.bottom, 4)
        }
    }
}

struct NotificationRow: View {
    let notif: CookingNotificationItem
    let onReturnToCooking: () -> Void
    @EnvironmentObject private var settings: AppSettings

    private var isCompleted: Bool { notif.type == .completed }
    private var isKeepWarm: Bool  { notif.type == .keepWarm  }

    private var iconColor: Color {
        switch notif.type {
        case .completed: return Color(red: 0.22, green: 0.60, blue: 0.14)
        case .keepWarm:  return Color(red: 1.0,  green: 0.52, blue: 0.08)
        case .started:   return Color(red: 0.86, green: 0.12, blue: 0.16)
        }
    }

    private var borderColor: Color { iconColor.opacity(0.35) }

    var body: some View {
        let content = HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(iconColor)
                    .frame(width: 26, height: 26)
                Image(systemName: isCompleted ? "checkmark" : isKeepWarm ? "flame.fill" : "play.fill")
                    .font(.system(size: isKeepWarm ? 11 : 9, weight: .bold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(isCompleted
                     ? "\(notif.recipe.localizedTitle(language: settings.language)) \(settings.t("hazır!", "ready!"))"
                     : isKeepWarm
                     ? "\(notif.recipe.localizedTitle(language: settings.language)) \(settings.t("sıcak tutmada", "on keep warm"))"
                     : "\(notif.recipe.localizedTitle(language: settings.language)) \(settings.t("pişmeye başladı", "started cooking"))")
                    .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(settings.theme.foreground)
                    .fixedSize(horizontal: false, vertical: true)
                Text(isCompleted
                     ? settings.t("Afiyet olsun 🎉", "Enjoy your meal 🎉")
                     : isKeepWarm
                     ? settings.t("Sıcak tutma modu aktif 🔥", "Keep warm mode active 🔥")
                     : settings.t("Pişirme ekranına dön", "Return to cooking"))
                    .font(.system(size: 10.5, weight: .regular, design: .rounded))
                    .foregroundStyle(settings.theme.foreground.opacity(0.62))
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(settings.theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(borderColor, lineWidth: 1)
        )

        if notif.type == .started {
            Button(action: onReturnToCooking) { content }
                .buttonStyle(.plain)
        } else {
            content
        }
    }
}

struct NotificationsPage: View {
    let recipe: Recipe
    let notifications: [CookingNotificationItem]
    let onOpenRecipe: () -> Void
    let onReturnToCooking: () -> Void
    @EnvironmentObject private var settings: AppSettings
    @State private var showSettings = false

    var body: some View {
        ZStack {
            if showSettings {
                SettingsPage(onBack: {
                    showSettings = false
                })
                .environmentObject(settings)
            } else {
                settings.theme.background.ignoresSafeArea()

                VStack(spacing: 8) {
                    TopBar(title: settings.t("Bildirimler", "Notifications"), titleColor: Color(red: 0.88, green: 0.18, blue: 0.22), showBack: false)
                        .padding(.top, 2)

                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 8) {
                            if notifications.isEmpty {
                                Text(settings.t("Henüz bildirim yok", "No notifications yet"))
                                    .font(.system(size: 12, weight: .regular, design: .rounded))
                                    .foregroundStyle(settings.theme.foreground.opacity(0.4))
                                    .frame(maxWidth: .infinity)
                                    .padding(.top, 20)
                            } else {
                                ForEach(notifications.reversed()) { notif in
                                    NotificationRow(
                                        notif: notif,
                                        onReturnToCooking: onReturnToCooking
                                    )
                                }
                            }
                        }
                        .padding(.top, 4)
                        .padding(.bottom, 4)
                    }
                    .frame(maxHeight: .infinity)

                    PageDots(activeIndex: 2, count: 3)
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 6)

                // Ayarlar tuşu — sağ üst, saat göstergesinin altı
                VStack {
                    HStack {
                        Spacer()
                        Button {
                            playTapFeedback()
                            showSettings = true
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(settings.theme.foreground.opacity(0.55))
                                .frame(width: 28, height: 28)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 8)
                    .padding(.trailing, 6)
                    Spacer()
                }
            }
        }
    }
}

struct DetailPage: View {
    let recipe: Recipe
    let isCooking: Bool
    let onBack: () -> Void
    let onContinue: () -> Void
    @EnvironmentObject private var settings: AppSettings
    @State private var showConflictAlert = false

    var body: some View {
        ZStack(alignment: .top) {
            settings.theme.background.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 10) {
                    RecipeHeaderCard(recipe: recipe)

                    HStack(spacing: 10) {
                        RecipeChip(label: recipe.durationText(language: settings.language))
                        RecipeChip(label: recipe.calories)
                    }

                    VStack(spacing: 8) {
                        ExpandableRow(title: settings.t("Hazırlanışı", "Preparation"), lines: recipe.preparationLines(language: settings.language))
                        ExpandableRow(title: settings.t("Malzemeler", "Ingredients"), lines: recipe.ingredientLines(language: settings.language))
                    }

                    Button(action: {
                        if isCooking {
                            showConflictAlert = true
                        } else {
                            onContinue()
                        }
                    }) {
                        Text(settings.t("Tarifi Başlat", "Start Recipe"))
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, minHeight: 42)
                            .background(
                                RoundedRectangle(cornerRadius: 11, style: .continuous)
                                    .fill(Color(red: 0.86, green: 0.12, blue: 0.16))
                            )
                    }
                    .buttonStyle(.plain)
                    .alert(settings.t("Şu anda yapılan tarifiniz var", "A recipe is already cooking"), isPresented: $showConflictAlert) {
                        Button(settings.t("Tamam", "OK"), role: .cancel) {}
                    }

                    PageDots(activeIndex: 1)
                }
                .padding(.horizontal, 4)
                .padding(.top, 28)
                .padding(.bottom, 4)
            }

            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.black)
                        .frame(width: 20, height: 20)
                        .background(Circle().fill(Color.red))
                }
                .buttonStyle(.plain)

                Spacer(minLength: 4)
            }
            .padding(.horizontal, 4)
            .padding(.top, 2)
        }
    }
}

struct ConfirmPage: View {
    let recipe: Recipe
    let onBack: () -> Void
    let onStart: () -> Void
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        ZStack {
            settings.theme.background.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 10) {
                    HStack {
                        Button(action: onBack) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.black)
                                .frame(width: 20, height: 20)
                                .background(Circle().fill(Color.red))
                        }
                        .buttonStyle(.plain)

                        Spacer(minLength: 4)
                    }
                    .padding(.top, 2)

                    RecipeConfirmationCard(recipe: recipe)

                    HStack(spacing: 10) {
                        RecipeChip(label: recipe.calories)
                        RecipeChip(label: recipe.durationText(language: settings.language))
                    }

                    VStack(spacing: 8) {
                        ExpandableRow(title: settings.t("Hazırlanışı", "Preparation"), lines: recipe.preparationLines(language: settings.language))
                        ExpandableRow(title: settings.t("Malzemeler", "Ingredients"), lines: recipe.ingredientLines(language: settings.language))
                    }

                    Button(action: onStart) {
                        Text(settings.t("Tarifi Onayla", "Confirm Recipe"))
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, minHeight: 38)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(Color(red: 0.86, green: 0.12, blue: 0.16))
                            )
                    }
                    .buttonStyle(.plain)

                    PageDots(activeIndex: 2)
                }
                .padding(.horizontal, 4)
                .padding(.bottom, 4)
            }
        }
    }
}

struct RecipeHeaderCard: View {
    let recipe: Recipe
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        HStack(spacing: 10) {
            RecipeThumbnail(recipe: recipe, size: 48)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.22), lineWidth: 1)
                )
            VStack(alignment: .leading, spacing: 2) {
                Text(recipe.localizedTitle(language: settings.language))
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                Text(settings.t("Tarif ayrıntıları", "Recipe details"))
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundStyle(.white.opacity(0.74))
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(red: 0.86, green: 0.12, blue: 0.16))
        )
    }
}

struct RecipeConfirmationCard: View {
    let recipe: Recipe
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(red: 0.86, green: 0.12, blue: 0.16))
                .frame(height: 52)

            HStack(spacing: 10) {
                RecipeThumbnail(recipe: recipe, size: 48)
                VStack(alignment: .leading, spacing: 1) {
                    Text(recipe.localizedTitle(language: settings.language))
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                    Text(settings.t("Onay bekliyor", "Awaiting confirmation"))
                        .font(.system(size: 10.5, weight: .regular, design: .rounded))
                        .foregroundStyle(.white.opacity(0.76))
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .frame(height: 52)
        }
    }
}

// MARK: - Recipe Artwork

struct RecipeThumbnail: View {
    let recipe: Recipe
    let size: CGFloat

    var body: some View {
        let thumbnailShape = RoundedRectangle(cornerRadius: max(4, size * 0.2), style: .continuous)

        ZStack {
            thumbnailShape
                .fill(backgroundGradient)

            Image(recipe.imageName, bundle: .main)
                .resizable()
                .scaledToFill()
                .frame(width: size * 0.92, height: size * 0.92)
                .clipShape(thumbnailShape)
                .overlay(
                    thumbnailShape
                        .fill(Color.white.opacity(0.08))
                )

            thumbnailShape
                .stroke(Color.white.opacity(0.18), lineWidth: max(1, size * 0.04))
        }
        .frame(width: size, height: size)
        .shadow(color: .black.opacity(0.24), radius: 1.5, x: 0, y: 1)
        .accessibilityHidden(true)
    }

    private var backgroundGradient: LinearGradient {
        switch recipe {
        case .etSote:
            return LinearGradient(
                colors: [Color(red: 0.33, green: 0.10, blue: 0.08), Color(red: 0.77, green: 0.18, blue: 0.14)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .tazeFasulye:
            return LinearGradient(
                colors: [Color(red: 0.10, green: 0.32, blue: 0.12), Color(red: 0.22, green: 0.68, blue: 0.22)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .kabakYemegi:
            return LinearGradient(
                colors: [Color(red: 0.25, green: 0.30, blue: 0.10), Color(red: 0.76, green: 0.73, blue: 0.20)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .garniturluPilav:
            return LinearGradient(
                colors: [Color(red: 0.26, green: 0.42, blue: 0.16), Color(red: 0.77, green: 0.67, blue: 0.22)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .humus:
            return LinearGradient(
                colors: [Color(red: 0.41, green: 0.33, blue: 0.14), Color(red: 0.87, green: 0.73, blue: 0.34)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .mercimekCorbasi:
            return LinearGradient(
                colors: [Color(red: 0.52, green: 0.21, blue: 0.05), Color(red: 0.95, green: 0.54, blue: 0.11)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

}
