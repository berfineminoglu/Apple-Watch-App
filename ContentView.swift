import SwiftUI
import WatchKit

private func playTapFeedback(_ haptic: WKHapticType = .click) {
    WKInterfaceDevice.current().play(haptic)
}

struct ContentView: View {
    private enum RootScreen {
        case launch
        case recipePager
        case detail
        case cooking
    }

    private enum RecipePagerPage: Int {
        case choose
        case recipes
        case notifications
    }

    @State private var screen: RootScreen = .launch
    @State private var recipePagerSelection: RecipePagerPage = .recipes
    @State private var selectedRecipe: Recipe = .etSote
    @State private var showLaunchSplash = true
    @State private var didScheduleSplashDismissal = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            screenView

            if showLaunchSplash {
                LogoPage()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .task {
            guard !didScheduleSplashDismissal else { return }
            didScheduleSplashDismissal = true

            try? await Task.sleep(nanoseconds: 1_300_000_000)
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.28)) {
                    showLaunchSplash = false
                }
            }
        }
    }

    @ViewBuilder
    private var screenView: some View {
        switch screen {
        case .launch:
            ChooseRecipePage(
                onChoose: {
                    playTapFeedback()
                    withAnimation(.easeInOut(duration: 0.28)) {
                        recipePagerSelection = .recipes
                        screen = .recipePager
                    }
                }
            )
        case .recipePager:
            TabView(selection: $recipePagerSelection) {
                ChooseRecipePage(
                    onChoose: {
                        playTapFeedback()
                        withAnimation(.easeInOut(duration: 0.28)) {
                            recipePagerSelection = .recipes
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
                    onOpenRecipe: {
                        playTapFeedback()
                        withAnimation(.easeInOut(duration: 0.28)) {
                            screen = .detail
                        }
                    },
                    onReturnToCooking: {
                        playTapFeedback()
                        withAnimation(.easeInOut(duration: 0.28)) {
                            screen = .cooking
                        }
                    }
                )
                .tag(RecipePagerPage.notifications)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .background(Color.black.ignoresSafeArea())
        case .detail:
            DetailPage(
                recipe: selectedRecipe,
                onBack: {
                    playTapFeedback()
                    withAnimation(.easeInOut(duration: 0.28)) {
                        recipePagerSelection = .recipes
                        screen = .recipePager
                    }
                },
                onContinue: {
                    playTapFeedback()
                    withAnimation(.easeInOut(duration: 0.28)) {
                        screen = .cooking
                    }
                }
            )
        case .cooking:
            CookingPage(
                recipe: selectedRecipe,
                onNotifications: {
                    playTapFeedback()
                    withAnimation(.easeInOut(duration: 0.28)) {
                        recipePagerSelection = .notifications
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

    var duration: String {
        switch self {
        case .etSote: return "30 dk"
        case .tazeFasulye: return "26 dk"
        case .kabakYemegi: return "22 dk"
        case .garniturluPilav: return "18 dk"
        case .humus: return "12 dk"
        case .mercimekCorbasi: return "25 dk"
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

    var remaining: String {
        switch self {
        case .etSote: return "21 dk"
        case .tazeFasulye: return "18 dk"
        case .kabakYemegi: return "14 dk"
        case .garniturluPilav: return "12 dk"
        case .humus: return "8 dk"
        case .mercimekCorbasi: return "16 dk"
        }
    }

    func remainingText(for remainingSeconds: Int) -> String {
        let roundedMinutes = max(0, Int(ceil(Double(remainingSeconds) / 60.0)))
        return "\(roundedMinutes) dk"
    }

    var notificationTitle: String {
        "\"Sıcak Tutma\""
    }

    var notificationText: String {
        "\(title) için \(notificationTitle) moduna geçildi."
    }

    var alertText: String {
        "Yemeğin 5 dakikaya hazır :)"
    }

    var ingredientLines: [String] {
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
    }

    var preparationLines: [String] {
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
    }
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

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<count, id: \.self) { index in
                Circle()
                    .fill(index == activeIndex ? Color.white : Color.white.opacity(0.28))
                    .frame(width: 5, height: 5)
            }
        }
        .padding(.top, 2)
        .padding(.bottom, 2)
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

    var body: some View {
        HStack(spacing: 8) {
            RecipeThumbnail(recipe: recipe, size: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(recipe.title)
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                Text(subtitle)
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundStyle(.white.opacity(0.8))
                    .lineLimit(1)
            }
            Spacer(minLength: 4)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(red: 0.14, green: 0.14, blue: 0.14))
        )
    }
}

struct RecipeButtonRow: View {
    let recipe: Recipe
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 10) {
            RecipeThumbnail(recipe: recipe, size: 28)
            Text(recipe.title)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
            Spacer(minLength: 4)
        }
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, minHeight: 42, maxHeight: 42)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isSelected ? Color(red: 0.22, green: 0.22, blue: 0.22) : Color(red: 0.15, green: 0.15, blue: 0.15))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(isSelected ? Color.white.opacity(0.18) : Color.clear, lineWidth: 1)
        )
    }
}

struct RecipeChip: View {
    let label: String

    var body: some View {
        Text(label)
            .font(.system(size: 13, weight: .medium, design: .rounded))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 30)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color(red: 0.14, green: 0.14, blue: 0.14))
            )
    }
}

struct ExpandableRow: View {
    let title: String
    let lines: [String]
    @State private var expanded = false

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
                        .foregroundStyle(.white)
                    Spacer(minLength: 8)
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.8))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(Color(red: 0.14, green: 0.14, blue: 0.14))
                )
            }
            .buttonStyle(.plain)

            if expanded {
                VStack(alignment: .leading, spacing: 3) {
                    ForEach(lines, id: \.self) { line in
                        Text("• \(line)")
                            .font(.system(size: 11.5, weight: .regular, design: .rounded))
                            .foregroundStyle(.white.opacity(0.84))
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
    var body: some View {
        Circle()
            .fill(Color.red)
            .frame(width: 24, height: 24)
            .overlay(
                Image(systemName: "flame.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
            )
            .accessibilityHidden(true)
    }
}

struct HomeBubble: View {
    let symbol: String
    let background: Color
    var symbolColor: Color = .white
    var size: CGFloat = 28
    var customText: String? = nil
    var customTextColor: Color = .black
    var action: (() -> Void)? = nil

    var body: some View {
        let icon = ZStack {
            Circle()
                .fill(background)

            if let customText {
                Text(customText)
                    .font(.system(size: 8, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(customTextColor)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
            } else {
                Image(systemName: symbol)
                    .font(.system(size: max(10, size * 0.34), weight: .bold))
                    .foregroundStyle(symbolColor)
            }
        }
        .frame(width: size, height: size)
        .shadow(color: .black.opacity(0.3), radius: 1.5, x: 0, y: 1)

        Group {
            if let action {
                Button(action: action) {
                    icon
                }
                .buttonStyle(.plain)
                .contentShape(Circle())
            } else {
                icon
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

struct PrimaryLaunchCard: View {
    let recipe: Recipe
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                VestelLogoBadge(size: 36)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Pişirme akışını aç")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Text("Son tarif: \(recipe.title)")
                        .font(.system(size: 11.5, weight: .regular, design: .rounded))
                        .foregroundStyle(.white.opacity(0.74))
                        .lineLimit(1)
                }

                Spacer(minLength: 4)

                Image(systemName: "play.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white.opacity(0.92))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, minHeight: 58, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(0.07))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(recipe.theme.accent.opacity(0.20), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
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

struct HomePage: View {
    let recipe: Recipe
    let onCenterLaunch: () -> Void
    let onOpenRecipes: () -> Void
    let onOpenNotifications: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 8) {
                Spacer(minLength: 4)

                HStack(spacing: 8) {
                    HomeBubble(symbol: "cloud.fill", background: Color(red: 0.15, green: 0.49, blue: 0.97), size: 27)
                    HomeBubble(symbol: "calendar", background: Color.white, symbolColor: .black, size: 34, customText: "Tue\n15", customTextColor: .red)
                    HomeBubble(symbol: "square.grid.2x2.fill", background: Color(red: 0.45, green: 0.24, blue: 0.93), size: 27)
                }

                HStack(spacing: 10) {
                    HomeBubble(symbol: "location.fill", background: Color.white, symbolColor: Color(red: 0.15, green: 0.49, blue: 0.97), size: 27)

                    Button(action: onCenterLaunch) {
                        VestelLogoBadge(size: 52)
                            .frame(width: 66, height: 66)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.02))
                                    .frame(width: 66, height: 66)
                            )
                    }
                    .buttonStyle(.plain)
                    .contentShape(Circle())
                    .zIndex(10)

                    HomeBubble(symbol: "bell.fill", background: Color(red: 0.84, green: 0.88, blue: 0.95), symbolColor: Color(red: 0.12, green: 0.48, blue: 0.88), size: 27, action: onOpenNotifications)
                }

                HStack(spacing: 8) {
                    HomeBubble(symbol: "globe", background: Color(red: 0.99, green: 0.53, blue: 0.11), size: 27)
                    HomeBubble(symbol: "book.fill", background: Color(red: 1.0, green: 0.60, blue: 0.15), size: 27, action: onOpenRecipes)
                    HomeBubble(symbol: "music.note", background: Color(red: 0.96, green: 0.31, blue: 0.47), size: 27)
                }

                HStack(spacing: 8) {
                    HomeBubble(symbol: "circle.grid.3x3.fill", background: Color(red: 0.76, green: 0.85, blue: 0.24), symbolColor: .black, size: 25)
                    HomeBubble(symbol: "waveform.path.ecg", background: Color(red: 0.96, green: 0.21, blue: 0.27), size: 25)
                    HomeBubble(symbol: "figure.run", background: Color(red: 0.75, green: 0.95, blue: 0.24), symbolColor: .black, size: 25)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 8)
            .padding(.top, 6)
            .padding(.bottom, 4)
        }
    }
}

struct VestelLogoBadge: View {
    let size: CGFloat

    var body: some View {
        Circle()
            .fill(Color.white)
            .frame(width: size, height: size)
            .overlay(
                Text("V")
                    .font(.system(size: size * 0.52, weight: .heavy, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 0.93, green: 0.14, blue: 0.18),
                                Color(red: 0.98, green: 0.58, blue: 0.12)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .offset(y: 1)
            )
            .shadow(color: .black.opacity(0.25), radius: 2, x: 0, y: 1)
    }
}

struct RecipesPage: View {
    @Binding var selectedRecipe: Recipe
    let onContinue: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 8) {
                TopBar(title: "Tariflerim", titleColor: Color(red: 0.88, green: 0.18, blue: 0.22), showBack: false)
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

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

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

                RecipeSummaryCard(recipe: recipe, subtitle: "Kalan süre : \(recipe.duration)")
                    .onTapGesture(perform: onChooseRecipe)

                PageDots(activeIndex: 0)
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 6)
        }
    }
}

struct LogoPage: View {
    @State private var visible = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VestelLogoBadge(size: 64)
                .scaleEffect(visible ? 1.0 : 0.86)
                .opacity(visible ? 1.0 : 0.2)
                .animation(.spring(response: 0.38, dampingFraction: 0.72), value: visible)
        }
        .onAppear {
            visible = true
        }
    }
}

struct CookingPage: View {
    let recipe: Recipe
    let onNotifications: () -> Void

    @State private var isRunning = true
    @State private var accumulatedElapsed: TimeInterval = 0
    @State private var runningSince: Date?
    @State private var hasStarted = false
    private let demoDuration: TimeInterval = 10

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
            let track = Color.white.opacity(0.45)
            let buttonFill = isActive ? Color(red: 0.70, green: 0.14, blue: 0.16) : Color(red: 0.34, green: 0.64, blue: 0.22)

            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 8) {
                    HStack(spacing: 6) {
                        HeatBadge()
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
                        guard !hasStarted else { return }
                        hasStarted = true
                        isRunning = true
                        runningSince = context.date
                    }

                    Spacer(minLength: 8)

                    RecipeSummaryCard(
                        recipe: recipe,
                        subtitle: isComplete ? "Tamamlandı" : isActive ? "Kalan süre : \(recipe.remainingText(for: remainingSeconds))" : "Duraklatıldı"
                    )
                    .onTapGesture(perform: onNotifications)

                    PageDots(activeIndex: 0)
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 6)
            }
        }
    }
}

struct ChooseRecipePage: View {
    let onChoose: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 8) {
                HStack(spacing: 6) {
                    HeatBadge()
                    Spacer(minLength: 4)
                }
                .padding(.top, 2)

                Spacer(minLength: 2)

                Button(action: onChoose) {
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.7), style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [14, 8]))
                            .frame(width: 88, height: 88)
                        Circle()
                            .fill(Color(red: 0.47, green: 0.47, blue: 0.47))
                            .frame(width: 66, height: 66)
                        Image(systemName: "play.fill")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .buttonStyle(.plain)

                Spacer(minLength: 10)

                Button(action: onChoose) {
                    Text("Tarif Seçiniz.")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(Color(red: 0.77, green: 0.08, blue: 0.13))
                        .frame(maxWidth: .infinity, minHeight: 42)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color(red: 0.14, green: 0.14, blue: 0.14))
                        )
                }
                .buttonStyle(.plain)

                PageDots(activeIndex: 0)
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 6)
        }
    }
}

struct NotificationsPage: View {
    let recipe: Recipe
    let onOpenRecipe: () -> Void
    let onReturnToCooking: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 8) {
                TopBar(title: "Bildirimler", titleColor: Color(red: 0.88, green: 0.18, blue: 0.22), showBack: false)
                    .padding(.top, 2)

                VStack(spacing: 8) {
                    Button(action: onOpenRecipe) {
                        HStack(spacing: 10) {
                            RecipeThumbnail(recipe: recipe, size: 22)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(recipe.notificationText)
                                    .font(.system(size: 13.5, weight: .medium, design: .rounded))
                                    .foregroundStyle(.white)
                                    .multilineTextAlignment(.leading)
                                    .fixedSize(horizontal: false, vertical: true)

                                Text("Yeni durum kartını aç")
                                    .font(.system(size: 10.5, weight: .regular, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.68))
                            }

                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity, minHeight: 66, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color(red: 0.18, green: 0.18, blue: 0.18))
                        )
                    }
                    .buttonStyle(.plain)

                    Button(action: onReturnToCooking) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(recipe.alertText)
                                .font(.system(size: 12.5, weight: .regular, design: .rounded))
                                .foregroundStyle(.white.opacity(0.82))
                                .multilineTextAlignment(.leading)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color(red: 0.10, green: 0.10, blue: 0.10))
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 4)

                Spacer(minLength: 4)
                PageDots(activeIndex: 2, count: 3)
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 6)
        }
    }
}

struct DetailPage: View {
    let recipe: Recipe
    let onBack: () -> Void
    let onContinue: () -> Void

    var body: some View {
        ZStack(alignment: .top) {
            Color.black.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 10) {
                    RecipeHeaderCard(recipe: recipe)

                    HStack(spacing: 10) {
                        RecipeChip(label: recipe.duration)
                        RecipeChip(label: recipe.calories)
                    }

                    VStack(spacing: 8) {
                        ExpandableRow(title: "Hazırlanışı", lines: recipe.preparationLines)
                        ExpandableRow(title: "Malzemeler", lines: recipe.ingredientLines)
                    }

                    Button(action: onContinue) {
                        Text("Tarifi Başlat")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, minHeight: 42)
                            .background(
                                RoundedRectangle(cornerRadius: 11, style: .continuous)
                                    .fill(Color(red: 0.86, green: 0.12, blue: 0.16))
                            )
                    }
                    .buttonStyle(.plain)

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

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

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
                        RecipeChip(label: recipe.duration)
                    }

                    VStack(spacing: 8) {
                        ExpandableRow(title: "Hazırlanışı", lines: recipe.preparationLines)
                        ExpandableRow(title: "Malzemeler", lines: recipe.ingredientLines)
                    }

                    Button(action: onStart) {
                        Text("Tarifi Onayla")
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

    var body: some View {
        HStack(spacing: 10) {
            RecipeThumbnail(recipe: recipe, size: 48)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.22), lineWidth: 1)
                )
            VStack(alignment: .leading, spacing: 2) {
                Text(recipe.title)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                Text("Tarif ayrıntıları")
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

    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(red: 0.86, green: 0.12, blue: 0.16))
                .frame(height: 52)

            HStack(spacing: 10) {
                RecipeThumbnail(recipe: recipe, size: 48)
                VStack(alignment: .leading, spacing: 1) {
                    Text(recipe.title)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                    Text("Onay bekliyor")
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
