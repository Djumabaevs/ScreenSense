# ScreenSense — FIXES.md

> Дата: 4 марта 2026
> 3 бага от Бакыта + дополнительные находки при аудите

---

## Баг 1: «Используйте телефон чтобы данные появились» — данные не появляются

### Симптом
На главном экране (Dashboard) всегда видна карточка "Collecting Data / Use your device for a few minutes, then tap Refresh to see your stats." — даже после длительного использования.

### Корень проблемы
Данные проходят длинный путь: **DeviceActivityReport extension** → **App Group / Keychain** → **ScreenTimeDataSyncService** → **SwiftData DailyReport** → **DashboardView**.

Проблема в том, что `effectiveDashboardReport` возвращает `nil`:

```swift
// DashboardView.swift, строка ~240
private var effectiveDashboardReport: DisplayReport? {
    if let report = todayReport, !report.topApps.isEmpty {
        return DisplayReport.from(report)
    }
    if let shared = sharedFallbackData, Calendar.current.isDateInToday(shared.date) {
        return DisplayReport.from(shared)
    }
    return DisplayReport.loadFromSharedContainers()
}
```

**3 точки отказа:**

1. **App Group ID mismatch или entitlement отсутствует** — extension пишет данные в `group.com.screensense.shared`, но если entitlement не настроен на обоих таргетах (app + report extension), `UserDefaults(suiteName:)` возвращает `nil` → данные не сохраняются/не читаются.

2. **DeviceActivityReport extension sandbox** — в `ScreenSenseReport.swift` при `processActivityData()` данные сохраняются через `AppGroupManager.shared.save()`, но комментарий в коде прямо говорит: `"// Attempt to save to app group (may fail due to ExtensionKit sandbox)"`. Если App Group не работает — данные визуально рендерятся в DeviceActivityReport (верхняя часть Dashboard), но **НЕ попадают** в SwiftData для нижних карточек.

3. **Keychain fallback тоже может не работать** — `KeychainTransport` использует wildcard access group `"R56999TGTG.*"`, но Team ID должен точно совпадать. Если Keychain Sharing не настроен — fallback тоже не сработает.

4. **`sharedFallbackData` загружается только в `loadReportDiagnostics()`** — который вызывается таймером каждые 15 сек, но `loadDirectFile()` ищет `latest_daily.json` в App Group контейнере (который может быть недоступен).

### План исправления

**Шаг 1: Диагностика (быстро, 15 мин)**
- Добавить в DashboardView скрытую кнопку диагностики (долгий тап на "Collecting Data"):
```swift
VStack {
    Text("Container: \(AppGroupManager.shared.isSharedContainerAvailable ? "✅" : "❌")")
    Text("Path: \(AppGroupManager.shared.sharedContainerPath ?? "nil")")
    Text("Shared data: \(sharedFallbackData != nil ? "✅" : "❌")")
    Text("Keychain: \(KeychainTransport.load() != nil ? "✅" : "❌")")
    Text("Report extension ran: \(lastReportGeneratedAt?.description ?? "never")")
}
```

**Шаг 2: Фикс App Group entitlement (30 мин)**
- Проверить в Xcode → каждый таргет (ScreenSense, ScreenSenseReport, ScreenSenseMonitor) → Signing & Capabilities → App Groups
- Все 3 таргета ДОЛЖНЫ иметь `group.com.screensense.shared`
- Проверить Provisioning Profile на Apple Developer Portal

**Шаг 3: Добавить запись через JSON файл + Keychain из extension (30 мин)**
- В `processActivityData()` (ScreenSenseReport.swift) — добавить запись в файл и Keychain как дополнительные каналы:
```swift
// После appGroup.save(summary, ...)
// Также сохранить в файл
if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppConstants.appGroupID) {
    let fileURL = containerURL.appendingPathComponent("latest_daily.json")
    if let data = try? JSONEncoder().encode(summary) {
        try? data.write(to: fileURL)
    }
}
// Также сохранить в Keychain
KeychainTransport.save(summary)
```

**Шаг 4: Убрать блокировку по `isDateInToday` в первый час (15 мин)**
- `effectiveDashboardReport` проверяет `Calendar.current.isDateInToday(shared.date)` — если extension записал данные в 23:59, а юзер смотрит в 00:01 — данные не покажутся. Добавить grace period.

**Шаг 5: Fallback на extension view (15 мин)**
- DeviceActivityReport в верхней части Dashboard (`screenTimeReportSection`) рендерится ВСЕГДА если авторизован — потому что extension получает данные напрямую от системы. Проблема в том, что overlay `Color.white.opacity(0.001)` блокирует взаимодействие. Нижние карточки (`nativeDashboardCards`) зависят от SwiftData sync. **Фикс: если SwiftData данных нет, показывать больше данных из extension view и убрать overlay.**

---

## Баг 2: Карточки не кликабельны — нельзя видеть детали Apps, Pickups, и т.д.

### Симптом
Карточки Pickups, Apps, Focus и другие на Dashboard не реагируют на нажатие.

### Корень проблемы
**Этот баг — следствие Бага 1.** Кликабельные карточки рендерятся ТОЛЬКО внутри `nativeDashboardCards`, которые показываются при условии:

```swift
if let dr = effectiveDashboardReport, screenTimeService.isAuthorized {
    // Score Ring Card - tappable ✅
    // Quick Stats Row (Pickups, Apps, Focus) - tappable ✅
    // Time Quality Card - tappable ✅
    // Top Apps Section - tappable ✅
} else if screenTimeService.isAuthorized {
    // "Collecting Data" card ❌ — ничего кликабельного!
}
```

Когда `effectiveDashboardReport == nil` → показывается только "Collecting Data" и **DeviceActivityReport extension view** (верхняя часть). Extension view рендерится в отдельном процессе и **не поддерживает интерактивность** (нельзя добавить onTapGesture к нему — это системное ограничение).

Кроме того, overlay на DeviceActivityReport:
```swift
.overlay {
    Color.white.opacity(0.001)  // Блокирует ВСЕ тапы на extension view!
}
```
Этот overlay был добавлен чтобы ScrollView работал поверх extension view, но он перехватывает все жесты.

### План исправления

**Шаг 1: Исправить Баг 1** — если данные попадут в SwiftData, нативные кликабельные карточки появятся автоматически.

**Шаг 2: Показывать нативные карточки даже при частичных данных (30 мин)**
- Изменить условие с `if let dr = effectiveDashboardReport` на fallback с дефолтными значениями:
```swift
let dr = effectiveDashboardReport ?? DisplayReport(
    totalScreenTime: 0,
    productiveTime: 0,
    neutralTime: 0,
    mindlessTime: 0,
    score: 0,
    pickups: 0,
    apps: []
)
// Всегда показывать кликабельные карточки, даже с нулями
```

**Шаг 3: Убрать overlay с DeviceActivityReport (10 мин)**
```swift
// Было:
.overlay {
    Color.white.opacity(0.001)
}
// Стало: убрать полностью
// Для скролла использовать .allowsHitTesting(false) на extension view
// или обернуть в ScrollView с координированной прокруткой
```

**Шаг 4: Добавить `TappableGlassCard` вокруг Top Apps в extension view (30 мин)**
- В `TotalActivityView.swift` (extension view) — apps показываются но без onTap. Но extension view не может открывать sheets в хост-приложении. Решение: убрать Top Apps из extension view, оставить только score + stats, а Top Apps показывать нативно (как уже сделано в `nativeDashboardCards`).

---

## Баг 3: Deep Analysis (кнопка мозг) всегда пустая

### Симптом
При нажатии на 🧠 в Insights → открывается BrainAnalysisSheet → секция "AI Analysis" пустая или показывает "No Data Yet".

### Корень проблемы
`BrainAnalysisSheet` пытает загрузить данные в `.task`:

```swift
.task {
    // 1. Попытка sync
    if todayReport == nil {
        ScreenTimeDataSyncService.shared.syncLatestDailyData(into: modelContext)
    }
    
    // 2. Fallback из shared containers
    if todayReport == nil {
        displayReport = DisplayReport.loadFromSharedContainers()
    }
    
    // 3. AI анализ
    if let report = todayReport {
        if aiEngine.isAvailable {
            await aiEngine.analyze(...)  // iOS 26+ Foundation Models
        } else {
            aiEngine.analysisState = .completed(generateLocalAnalysis(from: dr))
        }
    } else if let dr = effectiveReport {
        aiEngine.analysisState = .completed(generateLocalAnalysis(from: dr))
    }
    // Если ни todayReport ни effectiveReport нет → ничего не происходит!
}
```

**Проблемы:**

1. **Тот же корень что Баг 1** — `todayReport` из SwiftData пустой, и `DisplayReport.loadFromSharedContainers()` возвращает `nil` если App Group не работает.

2. **`aiEngine.isAvailable` возвращает `false`** на iOS < 26:
```swift
var isAvailable: Bool {
    #if canImport(FoundationModels)
    if #available(iOS 26, *) {
        return SystemLanguageModel.default.isAvailable
    }
    #endif
    return false  // ← Всегда false на iOS 18/19!
}
```
Но это ок — есть fallback `generateLocalAnalysis()`, который генерирует анализ без AI. **Проблема в том, что fallback вызывается только если `effectiveReport != nil`**, а он `nil` из-за Бага 1.

3. **Даже если данные есть** — `brainHeaderSection` покажет score, но `aiAnalysisSection` может застрять в `.idle` если task не вызвал `aiEngine.analyze()`.

### План исправления

**Шаг 1: Исправить Баг 1** — это решит 90% проблемы. Если данные будут синкаться → `effectiveReport` будет доступен → `generateLocalAnalysis()` сгенерирует анализ.

**Шаг 2: Добавить explicit loading state и retry (20 мин)**
```swift
.task {
    // ...existing sync logic...
    
    // Если после всех попыток данных нет — показать полезное сообщение
    if effectiveReport == nil {
        aiEngine.analysisState = .completed(BrainAnalysis(
            overallAssessment: "Not enough data yet. Use your phone for at least 5 minutes, then go back to Home and tap Refresh.",
            topStrength: "You're already tracking your habits!",
            topConcern: "Data sync needs time — check back in a few minutes.",
            actionItems: ["Go to Home tab", "Tap the Refresh button", "Come back to Brain Analysis"],
            moodInsight: "",
            scoreInterpretation: "Score will appear once data syncs."
        ))
    }
}
```

**Шаг 3: Добавить кнопку Retry в no-data section (10 мин)**
```swift
private var noDataSection: some View {
    GlassCard {
        VStack(spacing: 16) {
            // ...existing...
            Button("Try Syncing Now") {
                ScreenTimeDataSyncService.shared.syncLatestDailyData(into: modelContext)
                displayReport = DisplayReport.loadFromSharedContainers()
                if let dr = effectiveReport {
                    aiEngine.analysisState = .completed(generateLocalAnalysis(from: dr))
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }
}
```

---

## Дополнительные находки при аудите

### 4. Overlay блокирует scroll на DeviceActivityReport
**Файл:** `DashboardView.swift` (строка ~160)
```swift
.overlay {
    Color.white.opacity(0.001)
}
```
Этот прозрачный overlay должен перехватывать scroll, но он также блокирует тапы. Заменить на `.contentShape(Rectangle())` или `.allowsHitTesting(false)` на самом DeviceActivityReport.

### 5. `TappableGlassCard` не определён в показанных файлах
Карточки используют `TappableGlassCard(action:)` — убедиться что этот компонент действительно обрабатывает тапы и не «проглатывает» их. Проверить `GlassCard.swift` и `GlassButton.swift`.

### 6. Дублирование логики классификации
Классификация приложений (productive/neutral/mindless) дублируется в 3 местах:
- `TotalActivityView.swift` (extension) — хардкод classify()
- `InsightsReportView.swift` (extension) — отдельный classify()  
- `ClassificationEngine.swift` (main app)

**Риск:** расхождение классификации между extension view и нативными карточками.
**Фикс:** вынести `classify()` в Shared/ (доступный обоим таргетам).

### 7. Extension view `minHeight: 800` жёстко задан
```swift
DeviceActivityReport(.totalActivity, filter: filterForToday)
    .frame(minHeight: 800)
```
800 пикселей — слишком много, занимает весь экран. Если внизу есть нативные карточки — юзер должен скроллить далеко вниз. Уменьшить до 400-500 или сделать динамическим.

### 8. `filterForToday` использует `.hourly` сегменты
```swift
DeviceActivityFilter(
    segment: .hourly(during: interval),
    users: .all,
    devices: .all
)
```
`.hourly` создаёт отдельный сегмент на каждый час — это может раздувать данные. Для дневного обзора `.daily` может быть достаточно и эффективнее.

---

## Порядок исправления

| # | Что | Файлы | Время | Приоритет |
|---|-----|-------|-------|-----------|
| 1 | **Диагностика App Group** — добавить debug view | `DashboardView.swift` | 15 мин | 🔴 |
| 2 | **Проверить entitlements** — App Group на всех 3 таргетах | Xcode project settings | 30 мин | 🔴 |
| 3 | **Добавить file + keychain write** в extension | `ScreenSenseReport.swift` | 30 мин | 🔴 |
| 4 | **Убрать overlay** с DeviceActivityReport | `DashboardView.swift` | 10 мин | 🟡 |
| 5 | **Показывать нативные карточки** даже без данных | `DashboardView.swift` | 30 мин | 🟡 |
| 6 | **Fix BrainAnalysisSheet** — retry + fallback message | `InsightsView.swift` | 30 мин | 🟡 |
| 7 | **Уменьшить minHeight** extension view | `DashboardView.swift` | 5 мин | 🟢 |
| 8 | **Унифицировать classify()** в Shared/ | `Shared/`, extensions | 45 мин | 🟢 |

**Общее время: ~3-4 часа**

---

*Все 3 бага имеют один корень — данные из DeviceActivityReport extension не попадают в основное приложение через App Group. Починим App Group → починим всё. 💕 — Friday*
