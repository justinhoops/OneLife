import Foundation

// MARK: - Finance Domain

enum InvestmentRiskProfile: String, Codable, CaseIterable {
    case defensive
    case conservative
    case balanced
    case speculative

    var displayLabel: String {
        switch self {
        case .defensive: return "Defensive"
        case .conservative: return "Conservative"
        case .balanced: return "Balanced"
        case .speculative: return "Speculative"
        }
    }
}

enum DebtPressureBand: String, Codable, CaseIterable {
    case clear
    case manageable
    case heavy
    case crushing

    var displayLabel: String {
        switch self {
        case .clear: return "Clear"
        case .manageable: return "Manageable"
        case .heavy: return "Heavy"
        case .crushing: return "Crushing"
        }
    }
}

enum DebtPaymentStrategy: String, Codable, CaseIterable {
    case standard
    case aggressive
    case minimumOnly
    case deferStudentLoans
}

enum MarketPhase: String, Codable, CaseIterable {
    case stable
    case boom
    case correction
    case recession
}

enum RiskTolerance: String, Codable, CaseIterable {
    case conservative
    case moderate
    case aggressive
    case speculative
}

struct EconomyState: Codable, Equatable {
    var marketCycle: MarketPhase = .stable
    var inflationRate: Double = 0.02
    var techSectorMultiplier: Double = 1.0
    var energySectorMultiplier: Double = 1.0
    var broadMarketMultiplier: Double = 1.0
    var speculativeMultiplier: Double = 1.0
    var bondMultiplier: Double = 1.0
    var forecast: String? = nil
}

struct StockHolding: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var tickerOrSector: String // e.g. "TECH", "ENERGY", "INDEX"
    var sharesOrValue: Double
    var entryBasis: Double
    var volatilityFactor: Double // 0.5-2.0 based on sector + current economy

    var totalValue: Int { Int(sharesOrValue) }
    var totalProfit: Int { Int(sharesOrValue - entryBasis) }
}

struct CryptoAsset: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    let symbol: String
    var coins: Double
    var averageCost: Double
    var currentPrice: Double
    
    var totalValue: Int { Int(coins * currentPrice) }
}

struct RentalProperty: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String
    var propertyValue: Int
    var mortgagePrincipal: Int
    var monthlyRent: Int
    var monthlyMaintenance: Int
    
    var equity: Int { max(0, propertyValue - mortgagePrincipal) }
    var annualNetIncome: Int { (monthlyRent - (mortgagePrincipal > 0 ? (monthlyRent/2) : 0) - monthlyMaintenance) * 12 }
}

struct InvestmentPortfolio: Codable, Equatable {
    var stocks: [StockHolding] = []
    var crypto: [CryptoAsset] = []
    var rentals: [RentalProperty] = []
    var totalMarketExposure: Double = 0 // % of net worth
    var riskProfile: RiskTolerance = .moderate
    var lastVolatilityEventAge: Int? // for narrative echo
    
    var totalValue: Int {
        let stockVal = stocks.reduce(0) { $0 + $1.totalValue }
        let cryptoVal = crypto.reduce(0) { $0 + $1.totalValue }
        let rentalEquity = rentals.reduce(0) { $0 + $1.equity }
        return stockVal + cryptoVal + rentalEquity
    }
}

struct FinanceState: Codable, Equatable {
    var cashOnHand: Int = 250
    var studentDebt: Int = 0
    var creditDebt: Int = 0
    var medicalDebt: Int = 0
    var investedBalance: Int = 0
    var indexFundBalance: Int = 0
    var stockPortfolioBalance: Int = 0
    var costBasis: Int = 0
    var portfolio: InvestmentPortfolio = InvestmentPortfolio()
    var lastYearInvestmentDelta: Int = 0
    var investmentRiskProfile: InvestmentRiskProfile = .defensive
    var homeDownPaymentSavings: Int = 0
    var homeEquity: Int = 0
    var lastYearHomeValueDelta: Int = 0
    var lastYearMortgagePrincipalPaid: Int = 0
    var housingDebtBurden: Int = 0
    var annualGrossIncome: Int = 0
    var annualNetIncome: Int = 0
    var annualLivingCost: Int = 0
    var annualEducationCost: Int = 0
    var annualDependentCost: Int = 0
    var annualDiscretionaryCost: Int = 0
    var annualTotalExpenses: Int = 0
    var annualDebtPayments: Int = 0
    var effectiveTaxRate: Int = 0
    var financialStress: Int = 18
    var debtPressureBand: DebtPressureBand = .clear
    var debtDelinquencyRisk: Int = 0
    var recentDebtReliefYears: Int = 0
    var debtStrategy: DebtPaymentStrategy = .standard
    var consecutiveDeficitYears: Int = 0
    var stabilityStreakYears: Int = 0
    var wealthVelocity: Int = 0
    var lifestyleCreep: Int = 0
    var majorSetbackCount: Int = 0
    var peakWealth: Int = 250
    var compoundingYears: Int = 0
    var currentRegionPolicyID: String? = nil
    var lastYearBalanceDelta: Int = 0

    private enum CodingKeys: String, CodingKey {
        case cashOnHand
        case studentDebt
        case creditDebt
        case medicalDebt
        case investedBalance
        case indexFundBalance
        case stockPortfolioBalance
        case costBasis
        case portfolio
        case lastYearInvestmentDelta
        case investmentRiskProfile
        case homeDownPaymentSavings
        case homeEquity
        case lastYearHomeValueDelta
        case lastYearMortgagePrincipalPaid
        case housingDebtBurden
        case annualGrossIncome
        case annualNetIncome
        case annualLivingCost
        case annualEducationCost
        case annualDependentCost
        case annualDiscretionaryCost
        case annualTotalExpenses
        case annualDebtPayments
        case effectiveTaxRate
        case financialStress
        case debtPressureBand
        case debtDelinquencyRisk
        case recentDebtReliefYears
        case debtStrategy
        case consecutiveDeficitYears
        case stabilityStreakYears
        case wealthVelocity
        case lifestyleCreep
        case majorSetbackCount
        case peakWealth
        case compoundingYears
        case currentRegionPolicyID
        case lastYearBalanceDelta
    }

    init() {}

    init(
        cashOnHand: Int = 250,
        studentDebt: Int = 0,
        creditDebt: Int = 0,
        medicalDebt: Int = 0,
        investedBalance: Int = 0,
        indexFundBalance: Int = 0,
        stockPortfolioBalance: Int = 0,
        costBasis: Int = 0,
        portfolio: InvestmentPortfolio = InvestmentPortfolio(),
        lastYearInvestmentDelta: Int = 0,
        investmentRiskProfile: InvestmentRiskProfile = .defensive,
        homeDownPaymentSavings: Int = 0,
        homeEquity: Int = 0,
        lastYearHomeValueDelta: Int = 0,
        lastYearMortgagePrincipalPaid: Int = 0,
        housingDebtBurden: Int = 0,
        annualGrossIncome: Int = 0,
        annualNetIncome: Int = 0,
        annualLivingCost: Int = 0,
        annualEducationCost: Int = 0,
        annualDependentCost: Int = 0,
        annualDiscretionaryCost: Int = 0,
        annualTotalExpenses: Int = 0,
        annualDebtPayments: Int = 0,
        effectiveTaxRate: Int = 0,
        financialStress: Int = 18,
        debtPressureBand: DebtPressureBand = .clear,
        debtDelinquencyRisk: Int = 0,
        recentDebtReliefYears: Int = 0,
        debtStrategy: DebtPaymentStrategy = .standard,
        consecutiveDeficitYears: Int = 0,
        stabilityStreakYears: Int = 0,
        wealthVelocity: Int = 0,
        lifestyleCreep: Int = 0,
        majorSetbackCount: Int = 0,
        peakWealth: Int = 250,
        compoundingYears: Int = 0,
        currentRegionPolicyID: String? = nil,
        lastYearBalanceDelta: Int = 0
    ) {
        self.cashOnHand = cashOnHand
        self.studentDebt = studentDebt
        self.creditDebt = creditDebt
        self.medicalDebt = medicalDebt
        self.investedBalance = investedBalance
        self.indexFundBalance = indexFundBalance
        self.stockPortfolioBalance = stockPortfolioBalance
        self.costBasis = costBasis
        self.portfolio = portfolio
        self.lastYearInvestmentDelta = lastYearInvestmentDelta
        self.investmentRiskProfile = investmentRiskProfile
        self.homeDownPaymentSavings = homeDownPaymentSavings
        self.homeEquity = homeEquity
        self.lastYearHomeValueDelta = lastYearHomeValueDelta
        self.lastYearMortgagePrincipalPaid = lastYearMortgagePrincipalPaid
        self.housingDebtBurden = housingDebtBurden
        self.annualGrossIncome = annualGrossIncome
        self.annualNetIncome = annualNetIncome
        self.annualLivingCost = annualLivingCost
        self.annualEducationCost = annualEducationCost
        self.annualDependentCost = annualDependentCost
        self.annualDiscretionaryCost = annualDiscretionaryCost
        self.annualTotalExpenses = annualTotalExpenses
        self.annualDebtPayments = annualDebtPayments
        self.effectiveTaxRate = effectiveTaxRate
        self.financialStress = financialStress
        self.debtPressureBand = debtPressureBand
        self.debtDelinquencyRisk = debtDelinquencyRisk
        self.recentDebtReliefYears = recentDebtReliefYears
        self.debtStrategy = debtStrategy
        self.consecutiveDeficitYears = consecutiveDeficitYears
        self.stabilityStreakYears = stabilityStreakYears
        self.wealthVelocity = wealthVelocity
        self.lifestyleCreep = lifestyleCreep
        self.majorSetbackCount = majorSetbackCount
        self.peakWealth = peakWealth
        self.compoundingYears = compoundingYears
        self.currentRegionPolicyID = currentRegionPolicyID
        self.lastYearBalanceDelta = lastYearBalanceDelta
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        cashOnHand = try container.decodeIfPresent(Int.self, forKey: .cashOnHand) ?? 250
        studentDebt = try container.decodeIfPresent(Int.self, forKey: .studentDebt) ?? 0
        creditDebt = try container.decodeIfPresent(Int.self, forKey: .creditDebt) ?? 0
        medicalDebt = try container.decodeIfPresent(Int.self, forKey: .medicalDebt) ?? 0
        investedBalance = try container.decodeIfPresent(Int.self, forKey: .investedBalance) ?? 0
        indexFundBalance = try container.decodeIfPresent(Int.self, forKey: .indexFundBalance) ?? 0
        stockPortfolioBalance = try container.decodeIfPresent(Int.self, forKey: .stockPortfolioBalance) ?? 0
        costBasis = try container.decodeIfPresent(Int.self, forKey: .costBasis) ?? 0
        portfolio = try container.decodeIfPresent(InvestmentPortfolio.self, forKey: .portfolio) ?? InvestmentPortfolio()
        lastYearInvestmentDelta = try container.decodeIfPresent(Int.self, forKey: .lastYearInvestmentDelta) ?? 0
        investmentRiskProfile = try container.decodeIfPresent(InvestmentRiskProfile.self, forKey: .investmentRiskProfile) ?? .defensive
        homeDownPaymentSavings = try container.decodeIfPresent(Int.self, forKey: .homeDownPaymentSavings) ?? 0
        homeEquity = try container.decodeIfPresent(Int.self, forKey: .homeEquity) ?? 0
        lastYearHomeValueDelta = try container.decodeIfPresent(Int.self, forKey: .lastYearHomeValueDelta) ?? 0
        lastYearMortgagePrincipalPaid = try container.decodeIfPresent(Int.self, forKey: .lastYearMortgagePrincipalPaid) ?? 0
        housingDebtBurden = try container.decodeIfPresent(Int.self, forKey: .housingDebtBurden) ?? 0
        annualGrossIncome = try container.decodeIfPresent(Int.self, forKey: .annualGrossIncome) ?? 0
        annualNetIncome = try container.decodeIfPresent(Int.self, forKey: .annualNetIncome) ?? 0
        annualLivingCost = try container.decodeIfPresent(Int.self, forKey: .annualLivingCost) ?? 0
        annualEducationCost = try container.decodeIfPresent(Int.self, forKey: .annualEducationCost) ?? 0
        annualDependentCost = try container.decodeIfPresent(Int.self, forKey: .annualDependentCost) ?? 0
        annualDiscretionaryCost = try container.decodeIfPresent(Int.self, forKey: .annualDiscretionaryCost) ?? 0
        annualTotalExpenses = try container.decodeIfPresent(Int.self, forKey: .annualTotalExpenses) ?? 0
        annualDebtPayments = try container.decodeIfPresent(Int.self, forKey: .annualDebtPayments) ?? 0
        effectiveTaxRate = try container.decodeIfPresent(Int.self, forKey: .effectiveTaxRate) ?? 0
        financialStress = try container.decodeIfPresent(Int.self, forKey: .financialStress) ?? 18
        debtPressureBand = try container.decodeIfPresent(DebtPressureBand.self, forKey: .debtPressureBand) ?? .clear
        debtDelinquencyRisk = try container.decodeIfPresent(Int.self, forKey: .debtDelinquencyRisk) ?? 0
        recentDebtReliefYears = try container.decodeIfPresent(Int.self, forKey: .recentDebtReliefYears) ?? 0
        debtStrategy = try container.decodeIfPresent(DebtPaymentStrategy.self, forKey: .debtStrategy) ?? .standard
        consecutiveDeficitYears = try container.decodeIfPresent(Int.self, forKey: .consecutiveDeficitYears) ?? 0
        stabilityStreakYears = try container.decodeIfPresent(Int.self, forKey: .stabilityStreakYears) ?? 0
        wealthVelocity = try container.decodeIfPresent(Int.self, forKey: .wealthVelocity) ?? 0
        lifestyleCreep = try container.decodeIfPresent(Int.self, forKey: .lifestyleCreep) ?? 0
        majorSetbackCount = try container.decodeIfPresent(Int.self, forKey: .majorSetbackCount) ?? 0
        peakWealth = try container.decodeIfPresent(Int.self, forKey: .peakWealth) ?? 250
        compoundingYears = try container.decodeIfPresent(Int.self, forKey: .compoundingYears) ?? 0
        currentRegionPolicyID = try container.decodeIfPresent(String.self, forKey: .currentRegionPolicyID)
        lastYearBalanceDelta = try container.decodeIfPresent(Int.self, forKey: .lastYearBalanceDelta) ?? 0
        normalizeInvestmentBalances()
    }

    var totalWealth: Int {
        cashOnHand + investedBalance + portfolio.totalValue + homeDownPaymentSavings + homeEquity - totalNonHousingDebt
    }

    var totalNonHousingDebt: Int {
        studentDebt + creditDebt + medicalDebt
    }

    var hasInvestments: Bool {
        investedBalance > 0 || indexFundBalance > 0 || stockPortfolioBalance > 0 || portfolio.totalValue > 0
    }

    var lastYearHousingGainLoss: Int {
        lastYearHomeValueDelta + lastYearMortgagePrincipalPaid
    }

    var hasMillionaireFoundation: Bool {
        hasMillionaireFoundation(using: .playableRealismV1)
    }

    var requiredAnnualDebtPayment: Int {
        let studentPayment = studentDebt == 0 ? 0 : max(600, Int((Double(studentDebt) * 0.06).rounded()))
        let creditPayment = creditDebt == 0 ? 0 : max(900, Int((Double(creditDebt) * 0.14).rounded()))
        let medicalPayment = medicalDebt == 0 ? 0 : max(400, Int((Double(medicalDebt) * 0.08).rounded()))
        return annualDebtPayments > 0 ? annualDebtPayments : (studentPayment + creditPayment + medicalPayment)
    }

    var debtToIncomeBurden: Int {
        guard annualGrossIncome > 0 else { return totalNonHousingDebt > 0 ? 100 : 0 }
        return Int((Double(requiredAnnualDebtPayment) / Double(annualGrossIncome) * 100.0).rounded())
    }

    var canUseDebtReset: Bool {
        debtPressureBand == .crushing && recentDebtReliefYears == 0 && (creditDebt > 0 || medicalDebt > 0)
    }

    var isBlockedFromCompounding: Bool {
        debtPressureBand == .heavy || debtPressureBand == .crushing || recentDebtReliefYears > 0
    }

    func hasMillionaireFoundation(using profile: SimulationBalanceProfile) -> Bool {
        stabilityStreakYears >= profile.wealth.millionaireFoundationStabilityYears ||
        compoundingYears >= profile.wealth.millionaireFoundationCompoundingYears
    }

    func isEligibleToCompound(
        emergencyReserve: Int = SimulationBalanceProfile.playableRealismV1.wealth.compoundingEmergencyReserve,
        profile: SimulationBalanceProfile = .playableRealismV1
    ) -> Bool {
        stabilityStreakYears >= 2 &&
        consecutiveDeficitYears == 0 &&
        cashOnHand >= emergencyReserve &&
        studentDebt <= max(profile.wealth.compoundingDebtIncomeCap, annualGrossIncome) &&
        financialStress <= 55 &&
        !isBlockedFromCompounding
    }

    mutating func resetAnnualWealthVelocity() {
        wealthVelocity = 0
    }

    mutating func accumulateWealthDelta(from previousTotalWealth: Int) {
        wealthVelocity += totalWealth - previousTotalWealth
        peakWealth = max(peakWealth, totalWealth)
    }

    mutating func normalizeInvestmentBalances() {
        indexFundBalance = max(0, indexFundBalance)
        stockPortfolioBalance = max(0, stockPortfolioBalance)
        studentDebt = max(0, studentDebt)
        creditDebt = max(0, creditDebt)
        medicalDebt = max(0, medicalDebt)
        investedBalance = max(0, indexFundBalance + stockPortfolioBalance)
        costBasis = min(max(0, costBasis), investedBalance)
        homeDownPaymentSavings = max(0, homeDownPaymentSavings)
        homeEquity = max(0, homeEquity)
        housingDebtBurden = max(0, housingDebtBurden)
        annualDebtPayments = max(0, annualDebtPayments)
        debtDelinquencyRisk = debtDelinquencyRisk.clamped(to: 0...100)
        recentDebtReliefYears = max(0, recentDebtReliefYears)
        stabilityStreakYears = max(0, stabilityStreakYears)
        lifestyleCreep = max(0, lifestyleCreep)
        majorSetbackCount = max(0, majorSetbackCount)
        peakWealth = max(0, max(peakWealth, totalWealth))
        compoundingYears = max(0, compoundingYears)
        if totalNonHousingDebt == 0, debtPressureBand != .clear {
            debtPressureBand = .clear
        }
        if !hasInvestments {
            investedBalance = 0
            indexFundBalance = 0
            stockPortfolioBalance = 0
            costBasis = 0
            if investmentRiskProfile != .defensive {
                investmentRiskProfile = .defensive
            }
        }
    }
}

struct FederalFinancePolicy: Equatable {
    var taxBands: [FinanceTaxBand]
}

struct FinanceTaxBand: Equatable {
    var minimumIncome: Int
    var ratePercent: Int
}

struct StateFinancePolicy: Equatable {
    var id: String
    var incomeTaxRateDelta: Int = 0
    var costOfLivingMultiplier: Double = 1.0
    var educationCostMultiplier: Double = 1.0
    var dependentCostMultiplier: Double = 1.0
    var healthcareCostMultiplier: Double = 1.0
    var schoolSupportLevel: Int = 0
}

struct FinancePolicySet: Equatable {
    var federal: FederalFinancePolicy
    var states: [String: StateFinancePolicy]

    static let usBaseline = FinancePolicySet(
        federal: FederalFinancePolicy(
            taxBands: [
                FinanceTaxBand(minimumIncome: 0, ratePercent: 8),
                FinanceTaxBand(minimumIncome: 10_000, ratePercent: 12),
                FinanceTaxBand(minimumIncome: 30_000, ratePercent: 18),
                FinanceTaxBand(minimumIncome: 60_000, ratePercent: 24)
            ]
        ),
        states: [
            "mountain_standard": StateFinancePolicy(id: "mountain_standard", incomeTaxRateDelta: 1, costOfLivingMultiplier: 1.0, educationCostMultiplier: 0.95, dependentCostMultiplier: 1.0, healthcareCostMultiplier: 1.0, schoolSupportLevel: 2),
            "expensive_coastal": StateFinancePolicy(id: "expensive_coastal", incomeTaxRateDelta: 4, costOfLivingMultiplier: 1.28, educationCostMultiplier: 1.15, dependentCostMultiplier: 1.12, healthcareCostMultiplier: 1.1, schoolSupportLevel: 4),
            "factory_town": StateFinancePolicy(id: "factory_town", incomeTaxRateDelta: 0, costOfLivingMultiplier: 0.88, educationCostMultiplier: 0.92, dependentCostMultiplier: 0.94, healthcareCostMultiplier: 0.97, schoolSupportLevel: -1)
        ]
    )
}

enum WealthBand: String, Codable, CaseIterable {
    case struggling
    case stable
    case comfortable
    case wealthy
    case millionaire
    case billionaire
}

enum MoneyFormatting {
    static func compact(_ amount: Int) -> String {
        let absAmount = abs(amount)
        let sign = amount < 0 ? "-" : ""
        if absAmount >= 1_000_000_000 {
            let billions = Double(absAmount) / 1_000_000_000.0
            if billions >= 10 {
                return "\(sign)$\(Int(billions.rounded()))B"
            }
            return String(format: "%@$%.1fB", sign, billions)
        }
        if absAmount >= 1_000_000 {
            let millions = Double(absAmount) / 1_000_000.0
            if millions >= 100 {
                return "\(sign)$\(Int(millions.rounded()))M"
            }
            return String(format: "%@$%.1fM", sign, millions)
        }
        return "\(sign)$\(absAmount.formatted(.number.grouping(.automatic)))"
    }
}

struct BalanceRunSummary: Equatable {
    var seed: Int
    var finalWealthBand: WealthBand
    var ageOfFirstStableSurplus: Int?
    var experiencedHeavyDebt: Bool
    var graduated: Bool
    var unemploymentYears: Int
    var becameHomeowner: Bool
    var achievedLongTermPartnership: Bool
    var severeHealthDecline: Bool
    var millionaireMilestone: Bool
}

struct BalanceReport: Equatable {
    var profileName: String
    var runCount: Int
    var summaries: [BalanceRunSummary]

    func rate(where predicate: (BalanceRunSummary) -> Bool) -> Double {
        guard runCount > 0 else { return 0 }
        return Double(summaries.filter(predicate).count) / Double(runCount)
    }

    var wealthBandCounts: [WealthBand: Int] {
        summaries.reduce(into: [:]) { partial, summary in
            partial[summary.finalWealthBand, default: 0] += 1
        }
    }

    var humanReadableSummary: String {
        let orderedBands = WealthBand.allCases.map { band in
            "\(band.rawValue): \(wealthBandCounts[band, default: 0])"
        }.joined(separator: ", ")
        let age30ishStability = summaries.compactMap(\.ageOfFirstStableSurplus).filter { $0 <= 30 }.count
        return [
            "Profile: \(profileName)",
            "Runs: \(runCount)",
            "Wealth bands: \(orderedBands)",
            "Stable by 30: \(age30ishStability)",
            "Heavy debt rate: \(Int((rate { $0.experiencedHeavyDebt } * 100).rounded()))%",
            "Graduation rate: \(Int((rate { $0.graduated } * 100).rounded()))%",
            "Homeownership rate: \(Int((rate { $0.becameHomeowner } * 100).rounded()))%",
            "Long-term partnership rate: \(Int((rate { $0.achievedLongTermPartnership } * 100).rounded()))%",
            "Millionaire rate: \(Int((rate { $0.millionaireMilestone } * 100).rounded()))%"
        ].joined(separator: "\n")
    }
}

struct SimulationBalanceProfile: Equatable {
    struct DebtSettings: Equatable {
        var studentInterestRatePercent: Int
        var deferredStudentInterestRatePercent: Int
        var creditInterestRatePercent: Int
        var restructuredCreditInterestRatePercent: Int
        var medicalInterestRatePercent: Int
        var restructuredMedicalInterestRatePercent: Int
        var studentMinimumPayment: Int
        var studentPaymentRatePercent: Int
        var creditMinimumPayment: Int
        var creditPaymentRatePercent: Int
        var medicalMinimumPayment: Int
        var medicalPaymentRatePercent: Int
    }

    struct WealthSettings: Equatable {
        var adultStableSurplusThreshold: Int
        var adultStableStressCeiling: Int
        var compoundingEmergencyReserve: Int
        var compoundingDebtIncomeCap: Int
        var millionaireMinimumAge: Int
        var millionaireFoundationStabilityYears: Int
        var millionaireFoundationCompoundingYears: Int
        var stableBandLowerBound: Int
        var comfortableBandLowerBound: Int
        var wealthyBandLowerBound: Int
    }

    struct HomeownershipSettings: Equatable {
        var minimumLiquidReserve: Int
        var minimumYearsWorked: Int
        var minimumPositiveBalanceDelta: Int
        var downPaymentRatePercent: Int
        var closingCostRatePercent: Int
    }

    struct CareerSettings: Equatable {
        var promotionBaseThreshold: Int
    }

    struct EconomySettings: Equatable {
        var baseInflationRate: Double
        var marketBoomMultiplier: Double
        var marketStableMultiplier: Double
        var marketCorrectionMultiplier: Double
        var marketRecessionMultiplier: Double
    }

    var debt: DebtSettings
    var wealth: WealthSettings
    var homeownership: HomeownershipSettings
    var career: CareerSettings
    var economy: EconomySettings

    func wealthBand(for totalWealth: Int) -> WealthBand {
        if totalWealth >= 1_000_000_000 { return .billionaire }
        if totalWealth >= 1_000_000 { return .millionaire }
        if totalWealth >= wealth.wealthyBandLowerBound { return .wealthy }
        if totalWealth >= wealth.comfortableBandLowerBound { return .comfortable }
        if totalWealth >= wealth.stableBandLowerBound { return .stable }
        return .struggling
    }

    static let playableRealismV1 = SimulationBalanceProfile(
        debt: DebtSettings(
            studentInterestRatePercent: 4,
            deferredStudentInterestRatePercent: 6,
            creditInterestRatePercent: 18,
            restructuredCreditInterestRatePercent: 14,
            medicalInterestRatePercent: 7,
            restructuredMedicalInterestRatePercent: 5,
            studentMinimumPayment: 600,
            studentPaymentRatePercent: 6,
            creditMinimumPayment: 900,
            creditPaymentRatePercent: 14,
            medicalMinimumPayment: 400,
            medicalPaymentRatePercent: 8
        ),
        wealth: WealthSettings(
            adultStableSurplusThreshold: 2_500,
            adultStableStressCeiling: 48,
            compoundingEmergencyReserve: 6_000,
            compoundingDebtIncomeCap: 18_000,
            millionaireMinimumAge: 30,
            millionaireFoundationStabilityYears: 5,
            millionaireFoundationCompoundingYears: 6,
            stableBandLowerBound: 0,
            comfortableBandLowerBound: 75_000,
            wealthyBandLowerBound: 300_000
        ),
        homeownership: HomeownershipSettings(
            minimumLiquidReserve: 8_000,
            minimumYearsWorked: 2,
            minimumPositiveBalanceDelta: 0,
            downPaymentRatePercent: 12,
            closingCostRatePercent: 4
        ),
        career: CareerSettings(
            promotionBaseThreshold: 85
        ),
        economy: EconomySettings(
            baseInflationRate: 0.02,
            marketBoomMultiplier: 1.15,
            marketStableMultiplier: 1.05,
            marketCorrectionMultiplier: 0.92,
            marketRecessionMultiplier: 0.80
        )
    )
}

/// Lightweight scaling factors derived from LifeResilience.
/// Used by pressure, health, and game-over systems to reduce frustration spirals
/// while preserving the core "Life Killer" authenticity.
struct ResilienceScaling: Equatable {
    var spilloverSeverityMultiplier: Double   // 0.65 = resilient (less punishing chain reactions)
    var healthDeclineDampener: Double         // <1.0 reduces negative mental/physical shifts
    var wealthGameOverFloor: Int              // e.g. -35_000 for resilient vs -20_000 grounded
    var earlyLifeBufferYears: Int             // extra forgiveness before ~age 22
}

extension LifeResilience {
    var scaling: ResilienceScaling {
        switch self {
        case .resilient:
            return ResilienceScaling(
                spilloverSeverityMultiplier: 0.68,
                healthDeclineDampener: 0.78,
                wealthGameOverFloor: -35_000,
                earlyLifeBufferYears: 8
            )
        case .grounded:
            return ResilienceScaling(
                spilloverSeverityMultiplier: 1.0,
                healthDeclineDampener: 1.0,
                wealthGameOverFloor: -20_000,
                earlyLifeBufferYears: 0
            )
        }
    }

    /// Returns a human-friendly short label for the current run.
    var shortLabel: String {
        switch self {
        case .resilient: return "Resilient run"
        case .grounded: return "Grounded (hardcore)"
        }
    }

    /// Persistent header label so the mode stays visible during play.
    var persistentPlayLabel: String {
        switch self {
        case .grounded: return "Grounded — fighting back hits harder"
        case .resilient: return "Resilient — compounds fast but scars linger"
        }
    }

    /// Evolving journal texture so the chosen Life Feel stays visible over decades.
    func journalReflection(forAge age: Int) -> (title: String, text: String)? {
        switch self {
        case .resilient:
            switch age {
            case 25:
                return ("Life Feel", "Mid-twenties in a Resilient run: rough years still bend back. Recovery is part of the design.")
            case 40:
                return ("Life Feel", "Forty in a Resilient run: you've had room to correct course. The story still has slack in it.")
            case 60:
                return ("Life Feel", "Sixty in a Resilient run: scars exist, but fewer feel fatal. You outlasted more than you broke.")
            default:
                return nil
            }
        case .grounded:
            switch age {
            case 25:
                return ("Life Feel", "Mid-twenties in a Grounded run: every mistake lands heavier. Choosing care is an act of courage.")
            case 40:
                return ("Life Feel", "Forty in a Grounded run: the weight is real. Small recoveries feel like victories because they are.")
            case 60:
                return ("Life Feel", "Sixty in a Grounded run: you survived without nets. What you built cost more — and means more.")
            default:
                return nil
            }
        }
    }
}

struct FinanceYearContext: Equatable {
    var age: Int
    var isSchoolAge: Bool
    var careerStatus: CareerStatus
    var careerLevel: Int = 0
    var grossIncome: Int
    var traits: [PersonalityTrait]
    var educationPathway: EducationPathway
    var educationStage: EducationStage
    var hasScholarship: Bool
    var housingCostBand: Int
    var housingArrangement: LivingArrangement
    var activeConditionCount: Int
    var ownsHome: Bool
    var hasPrimaryCare: Bool
    var friendCount: Int
    var partnerCount: Int
    var hasSpouse: Bool
    var hasCohabitingPartner: Bool
    var isPregnant: Bool
    var pregnancyPhase: PregnancyPhase?
    var infantCount: Int
    var childCount: Int
}

