import Foundation

/// Authored fictional-dollar policy. Rates are basis points; monetary rounding is nearest dollar.
enum EconomyPolicy {
    static let revision = 1
    static let essentials = 10_800
    static let rent = 14_400
    static let discretionary = 2_400
    static let partnerIncome = 24_000
    static let pension = 15_000
    static func dollars(_ old: Int) -> Int { checkedMultiply(old, 100) }
    static func checkedAdd(_ a: Int, _ b: Int) -> Int {
        let result = a.addingReportingOverflow(b)
        precondition(!result.overflow, "Money exceeds supported integer range")
        return result.partialValue
    }
    static func checkedMultiply(_ a: Int, _ b: Int) -> Int {
        let result = a.multipliedReportingOverflow(by: b)
        precondition(!result.overflow, "Money exceeds supported integer range")
        return result.partialValue
    }
    static func scaled(_ amount: Int, _ multiplier: Double) -> Int {
        let value = (Double(amount) * multiplier).rounded()
        precondition(value.isFinite && value < Double(Int.max) && value > Double(Int.min))
        return Int(value)
    }
    static func rate(_ amount: Int, _ basisPoints: Int) -> Int { scaled(amount, Double(basisPoints) / 10_000) }
    static func salary(_ career: CareerState) -> Int {
        guard career.level.isEmployed else { return career.level == .retired ? pension : 0 }
        let values: [Int] = switch career.track {
        case .undecided: [30_000, 42_000, 60_000]
        case .office: [42_000, 62_000, 92_000]
        case .trades: [44_000, 66_000, 90_000]
        case .careService: [34_000, 48_000, 65_000]
        case .freelance: [38_000, 60_000, 90_000]
        }
        let base = values[career.level == .senior ? 2 : (career.level == .established ? 1 : 0)]
        let classAdjusted = switch career.careerClass {
        case .normal: base
        case .partTime: scaled(base, 0.45)
        case .special: scaled(base, 1.35 + Double(career.specialMomentum) / 250.0)
        case .diamond: scaled(base, 2.0 + Double(career.legacyLeverage) / 100.0)
        }
        return scaled(classAdjusted, 1.0 + Double(career.negotiationLeverage) / 2_000.0)
    }
    static func tax(_ income: Int, payroll: Bool = true) -> Int {
        let taxable = max(0, income - 16_000)
        return rate(min(taxable, 20_000), 1_000)
            + rate(min(max(0, taxable - 20_000), 50_000), 2_000)
            + rate(max(0, taxable - 70_000), 3_000)
            + (payroll ? rate(max(0, income), 750) : 0)
    }
    static func propertyPrice(_ id: String) -> Int? {
        ["house-starter-condo": 150_000, "house-townhouse": 225_000, "house-family": 325_000,
         "house-skyline-penthouse": 900_000, "house-grandview-mansion": 1_800_000,
         "house-luxury-estate": 3_000_000][id]
    }
    static func assetFactor(_ id: String) -> Int {
        if id.hasPrefix("car-") { return 50 }
        if id.hasPrefix("helicopter-") { return 300 }
        return ["plane-light-sport": 50, "plane-twin-engine": 150, "plane-private-jet": 1_000,
                "boat-fishing": 20, "boat-speedboat": 30, "boat-cabin-cruiser": 100,
                "boat-luxury-yacht": 1_000][id] ?? (id.hasPrefix("gun-") ? 5 : 10)
    }
    static func monthlyMortgage(_ balance: Int, months: Int = 360) -> Int {
        guard balance > 0 else { return 0 }
        let factor = pow(1.005, Double(max(1, months)))
        return max(1, scaled(balance, 0.005 * factor / (factor - 1)))
    }
}

struct EconomyState: Codable, Equatable {
    var revision = EconomyPolicy.revision
    var budgetAge: Int?
    var earnedExtras = 0
    var extraWithholding = 0
    var shortfallYears = 0
    var temporaryHousing = false
    var workoutYearsRemaining = 0
    var workoutCompletedAge: Int?
    var workoutStartedAge: Int?
    var forgivenDebt = 0
    var conversionAge: Int?
    var conversionNotice = false
    var historicalSequence: UInt64?
    var lastSettlementAge: Int?
}

extension FinanceState {
    enum CodingKeys: String, CodingKey {
        case studentDebt, consumerDebt, medicalDebt, annualLedger, retirementBalance
        case retirementContributionPercent, financialStress, hardshipExtensionAge, housing, economy
    }
    init(from decoder: Decoder) throws {
        self.init()
        let c = try decoder.container(keyedBy: CodingKeys.self)
        studentDebt = try c.decodeIfPresent(Int.self, forKey: .studentDebt) ?? 0
        consumerDebt = try c.decodeIfPresent(Int.self, forKey: .consumerDebt) ?? 0
        medicalDebt = try c.decodeIfPresent(Int.self, forKey: .medicalDebt) ?? 0
        annualLedger = try c.decodeIfPresent(AnnualLedger.self, forKey: .annualLedger) ?? AnnualLedger()
        retirementBalance = try c.decodeIfPresent(Int.self, forKey: .retirementBalance) ?? 0
        retirementContributionPercent = try c.decodeIfPresent(Int.self, forKey: .retirementContributionPercent) ?? 0
        financialStress = try c.decodeIfPresent(Int.self, forKey: .financialStress) ?? 15
        hardshipExtensionAge = try c.decodeIfPresent(Int.self, forKey: .hardshipExtensionAge)
        housing = try c.decodeIfPresent(HousingState.self, forKey: .housing) ?? HousingState()
        economy = try c.decodeIfPresent(EconomyState.self, forKey: .economy) ?? EconomyState()
    }
}

enum FinancialPurpose: String, Codable { case optionalPurchase, household, medical, education, income, workEarnings, retirementTransfer, debtPayment }
struct FinancialRequest {
    let amount: Int
    let purpose: FinancialPurpose
    var incomeSource: IncomeSource? = nil
}
struct FinancialReceipt: Equatable {
    var paid = 0
    var debtAdded = 0
    var accepted = true
}
struct MortgageReceipt: Codable, Equatable {
    var propertyID: UInt64
    var principal = 0
    var interest = 0
    var unpaidInterest = 0
    var missedPayment = false
    var operatingArrears = 0
    var monthsElapsed = 0
}
struct EconomyAnnualDetail: Codable, Equatable {
    var earnings = 0
    var extraEarnings: Int?
    var withholdingPaid: Int?
    var essentialPaid: Int?
    var operatingPaid: Int?
    var partnerEarnings = 0
    var support = 0
    var pension = 0
    var rentalIncome = 0
    var taxReconciliation = 0
    var totalTaxes = 0
    var essentials = 0
    var primaryHousing = 0
    var secondaryHousing = 0
    var interest = 0
    var principal = 0
    var discretionary = 0
    var retirementDraw = 0
    var retirementContribution = 0
    var unpaid = 0
    var openingCash = 0
    var closingCash = 0
    var expectedNet = 0
    var rentalNet = 0
    var receipts: [MortgageReceipt] = []
}
struct EconomyAnnualResult {
    var finance: FinanceState
    var detail: EconomyAnnualDetail
}

/// Pure calculator shared by previews and actual settlement. Never advances RNG or mutates gameplay.
enum EconomyCalculator {
    static func earnings(_ state: LifeState, world: WorldModifierSnapshot) -> Int {
        guard state.career.level.isEmployed else { return 0 }
        let studying = state.education.college.isEnrolled ? 0.5 : 1.0
        return EconomyPolicy.scaled(EconomyPolicy.salary(state.career), world.incomeMultiplier * studying)
    }
    static func essentialCost(_ state: LifeState, world: WorldModifierSnapshot) -> Int {
        guard state.character.age >= 18 else { return 0 }
        let partner = state.partner?.stage == .committed || state.partner?.stage == .married
        let hasCar = state.assets.movableAssets.contains { $0.vehicle?.kind == .car }
        let base = EconomyPolicy.essentials + (partner ? 6_000 : 0) + state.family.dependentLoad * 6_000 - (hasCar ? 1_200 : 0)
        // Movable assets are finance-first holdings: purchase, condition,
        // maintenance, legal exposure, and resale are handled by Assets.
        // Recurring household pressure belongs to housing and essentials.
        return EconomyPolicy.scaled(base, world.livingCostMultiplier) + YearContext(state: state, world: world).pressure(on: .finance) * 400
    }
    static func ownershipCost(_ assets: AssetState) -> Int {
        // Kept as a compatibility surface for forecasts and older callers.
        // Vehicles, firearms, jewelry, and other movable assets do not add
        // recurring ownership bills in the current lifecycle.
        0
    }
    static func grossHousehold(_ state: LifeState, world: WorldModifierSnapshot) -> Int {
        let partnered = state.partner?.stage == .committed || state.partner?.stage == .married
        return earnings(state, world: world) + (partnered ? EconomyPolicy.scaled(EconomyPolicy.partnerIncome, world.incomeMultiplier) : 0)
            + (state.career.level == .retired ? EconomyPolicy.pension : 0)
    }
    static func debtDue(_ finance: FinanceState) -> Int {
        EconomyPolicy.rate(finance.studentDebt, 1_600)
            + EconomyPolicy.rate(finance.consumerDebt, finance.economy.workoutYearsRemaining > 0 ? 0 : 2_800)
            + EconomyPolicy.rate(finance.medicalDebt, finance.economy.workoutYearsRemaining > 0 ? 0 : 1_000)
    }
    static func qualifies(mortgage: Int, state: LifeState, world: WorldModifierSnapshot) -> Bool {
        guard state.finance.economy.workoutYearsRemaining == 0 else { return false }
        let gross = grossHousehold(state, world: world) + EconomyPolicy.rate(state.assets.lastRentalIncome, 7_000)
        let existing = state.assets.properties.reduce(0) { $0 + EconomyPolicy.monthlyMortgage($1.mortgageBalance, months: $1.mortgageMonthsRemaining) * 12 }
        return gross > 0 && existing + EconomyPolicy.monthlyMortgage(mortgage) * 12 + debtDue(state.finance) < EconomyPolicy.rate(gross, 4_300)
    }
    static func earningsRange(_ state: LifeState) -> ClosedRange<Int> {
        let baseline = earnings(state, world: WorldSystem.modifiers(for: state.world))
        return state.career.track == .freelance ? EconomyPolicy.rate(baseline, 7_500)...EconomyPolicy.rate(baseline, 12_500) : baseline...baseline
    }
    static func forecast(_ state: LifeState) -> EconomyAnnualResult {
        let world = WorldSystem.modifiers(for: state.world)
        let rent = state.assets.properties.reduce(0) { $0 + $1.expectedMarketRent }
        return calculate(state, world: world, earned: earnings(state, world: world), rent: rent)
    }
    static func calculate(_ state: LifeState, world: WorldModifierSnapshot, earned: Int, rent: Int) -> EconomyAnnualResult {
        var finance = state.finance
        var d = EconomyAnnualDetail()
        d.openingCash = state.cash
        guard state.character.age >= 18 else { d.closingCash = state.cash; return .init(finance: finance, detail: d) }
        let partnered = state.partner?.stage == .committed || state.partner?.stage == .married
        d.earnings = earned
        d.extraEarnings = finance.economy.earnedExtras
        d.withholdingPaid = finance.economy.extraWithholding
        d.partnerEarnings = partnered ? EconomyPolicy.scaled(EconomyPolicy.partnerIncome, world.incomeMultiplier) : 0
        d.support = state.career.level == .unemployed ? world.unemploymentSupport : 0
        d.pension = state.career.level == .retired ? EconomyPolicy.pension : 0
        d.rentalIncome = rent
        // Additional earnings were already paid; reconcile their tax without paying the wages twice.
        d.totalTaxes = EconomyPolicy.tax(earned + finance.economy.earnedExtras + d.pension + max(0, rent), payroll: false)
            + EconomyPolicy.rate(earned + finance.economy.earnedExtras, 750) + EconomyPolicy.tax(d.partnerEarnings)
        d.taxReconciliation = d.totalTaxes - finance.economy.extraWithholding
        d.essentials = essentialCost(state, world: world)
        let propertyCosts = state.assets.properties.reduce(0) { $0 + EconomyPolicy.scaled($1.totalAnnualCost, world.housingCostMultiplier) + EconomyPolicy.monthlyMortgage($1.mortgageBalance, months: $1.mortgageMonthsRemaining) * 12 }
        let householdRent = state.assets.primaryProperty == nil ? EconomyPolicy.scaled(EconomyPolicy.rent, world.housingCostMultiplier * (finance.economy.temporaryHousing ? 0.6 : 1)) : 0
        let grossReceipts = earned + d.partnerEarnings + d.support + d.pension + rent
        let essentialShortfall = max(0, d.totalTaxes + d.essentials + householdRent + propertyCosts + debtDue(finance) - grossReceipts)
        finance.retirementBalance = EconomyPolicy.checkedAdd(finance.retirementBalance, EconomyPolicy.rate(finance.retirementBalance, 300))
        if state.career.level == .retired {
            d.retirementDraw = min(finance.retirementBalance, max(EconomyPolicy.rate(finance.retirementBalance, 400), essentialShortfall))
            finance.retirementBalance -= d.retirementDraw
        }
        var cash = EconomyPolicy.checkedAdd(state.cash, grossReceipts + d.retirementDraw)
        var intendedExpenses = 0
        func pay(_ requested: Int) -> Int {
            let amount = max(0, requested)
            intendedExpenses = EconomyPolicy.checkedAdd(intendedExpenses, amount)
            let paid = min(cash, amount); cash -= paid
            d.unpaid = EconomyPolicy.checkedAdd(d.unpaid, amount - paid)
            return paid
        }
        func compulsory(_ amount: Int) {
            let paid = pay(amount)
            finance.consumerDebt = EconomyPolicy.checkedAdd(finance.consumerDebt, amount - paid)
        }
        if d.taxReconciliation < 0 { cash += -d.taxReconciliation } else { compulsory(d.taxReconciliation) }
        let cashBeforeEssentials = cash
        compulsory(d.essentials)
        d.essentialPaid = cashBeforeEssentials - cash
        func property(_ p: OwnedProperty) {
            var receipt = MortgageReceipt(propertyID: p.id)
            let operating = EconomyPolicy.scaled(p.totalAnnualCost, world.housingCostMultiplier) + p.operatingArrears
            let paidOperating = pay(operating)
            d.operatingPaid = (d.operatingPaid ?? 0) + paidOperating
            receipt.operatingArrears = operating - paidOperating
            var balance = p.mortgageBalance
            let installment = p.mortgageMonthlyPayment > 0 ? p.mortgageMonthlyPayment : EconomyPolicy.monthlyMortgage(balance, months: p.mortgageMonthsRemaining)
            for month in 0..<min(12, p.mortgageMonthsRemaining) where balance > 0 {
                let interest = EconomyPolicy.rate(balance, 50)
                let due = p.mortgageMonthsRemaining - month == 1 ? balance + interest : min(balance + interest, max(installment, interest))
                let paid = pay(due)
                let paidInterest = min(paid, interest)
                let principal = min(balance, max(0, paid - interest))
                balance -= principal
                let unpaidInterest = interest - paidInterest
                balance += unpaidInterest
                receipt.interest += paidInterest
                receipt.principal += principal
                receipt.unpaidInterest += unpaidInterest
                receipt.missedPayment = receipt.missedPayment || paid < due
                receipt.monthsElapsed += 1
            }
            receipt.missedPayment = receipt.missedPayment || receipt.operatingArrears > 0
            let total = paidOperating + receipt.principal + receipt.interest
            if p.isPrimaryResidence { d.primaryHousing += total } else { d.secondaryHousing += total }
            d.principal += receipt.principal; d.interest += receipt.interest
            d.receipts.append(receipt)
        }
        if let primary = state.assets.primaryProperty { property(primary) }
        else { d.primaryHousing = min(cash, householdRent); compulsory(householdRent) }
        func debt(_ opening: Int, rate: Int, paused: Bool = false) -> Int {
            guard !paused else { return opening }
            let interest = EconomyPolicy.rate(opening, rate)
            let due = min(opening + interest, interest + EconomyPolicy.rate(opening, 1_000))
            let paid = pay(due)
            d.interest += min(paid, interest); d.principal += max(0, paid - interest)
            return opening + interest - paid
        }
        let hardshipPaused = finance.hardshipExtensionAge == state.character.age - 1
        finance.studentDebt = debt(finance.studentDebt, rate: 600, paused: hardshipPaused)
        let newConsumerBills = max(0, finance.consumerDebt - state.finance.consumerDebt)
        finance.consumerDebt = debt(state.finance.consumerDebt, rate: 1_800, paused: hardshipPaused || finance.economy.workoutYearsRemaining > 0) + newConsumerBills
        finance.medicalDebt = debt(finance.medicalDebt, rate: 0, paused: hardshipPaused || finance.economy.workoutYearsRemaining > 0)
        for p in state.assets.properties.filter({ !$0.isPrimaryResidence }).sorted(by: { $0.id < $1.id }) { property(p) }
        if finance.economy.workoutYearsRemaining > 0 {
            var available = max(0, cash - (d.essentials + householdRent + (state.assets.primaryProperty.map { EconomyPolicy.scaled($0.totalAnnualCost, world.housingCostMultiplier) + EconomyPolicy.monthlyMortgage($0.mortgageBalance, months: $0.mortgageMonthsRemaining) * 12 } ?? 0)) / 4)
            let consumer = min(available, finance.consumerDebt); available -= consumer; finance.consumerDebt -= consumer
            let medical = min(available, finance.medicalDebt); finance.medicalDebt -= medical
            cash -= consumer + medical; d.principal += consumer + medical
            finance.economy.workoutYearsRemaining -= 1
            if finance.economy.workoutYearsRemaining == 0 {
                finance.economy.forgivenDebt += finance.consumerDebt + finance.medicalDebt
                finance.consumerDebt = 0; finance.medicalDebt = 0
                finance.economy.workoutCompletedAge = state.character.age
            }
        }
        let budgeted = finance.economy.budgetAge == state.character.age || finance.economy.budgetAge == state.character.age - 1
        let allowance = finance.economy.workoutYearsRemaining > 0 ? 0 : (budgeted ? 600 : EconomyPolicy.discretionary)
        d.discretionary = min(cash, allowance); cash -= d.discretionary
        intendedExpenses += allowance
        if d.unpaid == 0 && finance.economy.workoutYearsRemaining == 0 && state.career.level.isEmployed {
            d.retirementContribution = min(cash, EconomyPolicy.rate(earned, finance.retirementContributionPercent * 100))
            cash -= d.retirementContribution; finance.retirementBalance += d.retirementContribution
        }
        d.expectedNet = grossReceipts + d.retirementDraw - intendedExpenses - d.retirementContribution + max(0, -d.taxReconciliation)
        d.closingCash = cash
        d.rentalNet = rent - d.secondaryHousing
        finance.economy.shortfallYears = d.unpaid > 0 ? finance.economy.shortfallYears + 1 : 0
        finance.financialStress = min(100, max(0, finance.financialStress + (d.unpaid > 0 ? 8 : -3) + YearContext(state: state, world: world).pressure(on: .finance)))
        if finance.economy.temporaryHousing && d.unpaid == 0 && cash >= EconomyPolicy.rent / 4 { finance.economy.temporaryHousing = false }
        finance.economy.earnedExtras = 0; finance.economy.extraWithholding = 0; finance.economy.budgetAge = nil
        return .init(finance: finance, detail: d)
    }
}

extension FinanceSystem {
    @discardableResult
    static func transact(_ request: FinancialRequest, state: inout LifeState) -> FinancialReceipt {
        defer { observeCash(state: &state) }
        if request.amount >= 0 {
            if request.purpose == .workEarnings {
                let before = state.cash
                creditExtra(request.amount, state: &state)
                return .init(paid: state.cash - before)
            }
            state.cash = EconomyPolicy.checkedAdd(state.cash, request.amount)
            if let source = request.incomeSource { state.aggregates.recordIncome(request.amount, source: source) }
            return .init(paid: request.amount)
        }
        let charge = -request.amount
        if request.purpose == .retirementTransfer {
            guard state.finance.economy.workoutYearsRemaining == 0 && state.finance.economy.shortfallYears == 0 else { return .init(accepted: false) }
            let paid = min(state.cash, charge)
            state.cash -= paid
            state.finance.retirementBalance = EconomyPolicy.checkedAdd(state.finance.retirementBalance, paid)
            return .init(paid: paid)
        }
        if request.purpose == .debtPayment {
            var available = min(state.cash, charge)
            var paid = 0
            for key in [\FinanceState.consumerDebt, \FinanceState.medicalDebt, \FinanceState.studentDebt] {
                let amount = min(available, state.finance[keyPath: key])
                state.finance[keyPath: key] -= amount
                available -= amount; paid += amount
            }
            state.cash -= paid
            return .init(paid: paid)
        }
        if request.purpose == .optionalPurchase && state.cash < charge { return .init(accepted: false) }
        let paid = min(max(0, state.cash), charge)
        state.cash -= paid
        let debt = charge - paid
        switch request.purpose {
        case .medical: state.finance.medicalDebt = EconomyPolicy.checkedAdd(state.finance.medicalDebt, debt)
        case .education: state.finance.studentDebt = EconomyPolicy.checkedAdd(state.finance.studentDebt, debt)
        default: state.finance.consumerDebt = EconomyPolicy.checkedAdd(state.finance.consumerDebt, debt)
        }
        return .init(paid: paid, debtAdded: debt)
    }

    static func observeCash(state: inout LifeState) {
        state.aggregates.peakCash = max(state.aggregates.peakCash, state.cash)
    }
    static func creditExtra(_ gross: Int, state: inout LifeState) {
        let withholding = EconomyPolicy.rate(gross, 2_750)
        state.finance.economy.earnedExtras += gross
        state.finance.economy.extraWithholding += withholding
        _ = transact(.init(amount: gross - withholding, purpose: .income), state: &state)
    }
    static func settleEconomy(state: inout LifeState, world: WorldModifierSnapshot) -> SystemYearDeltas {
        guard state.finance.economy.lastSettlementAge != state.character.age else { return .init() }
        let expected = EconomyCalculator.earnings(state, world: world)
        let earned = state.career.track == .freelance && state.career.level.isEmployed
            ? state.randomStreams.finance.next(in: EconomyPolicy.rate(expected, 7_500)...EconomyPolicy.rate(expected, 12_500)) : expected
        let result = EconomyCalculator.calculate(state, world: world, earned: earned, rent: state.assets.lastRentalIncome)
        let before = state.cash
        state.finance = result.finance
        state.finance.economy.lastSettlementAge = state.character.age
        state.cash = result.detail.closingCash
        let d = result.detail
        state.finance.annualLedger = AnnualLedger(income: d.earnings + (d.extraEarnings ?? 0) + d.partnerEarnings + d.support + d.pension + d.rentalIncome,
            rentalIncome: d.rentalIncome, taxes: d.totalTaxes, rentalTaxes: 0, livingCosts: d.essentials + d.discretionary,
            debtInterest: d.interest, housingCosts: d.primaryHousing + d.secondaryHousing,
            propertyOperatingCosts: d.primaryHousing + d.secondaryHousing - d.receipts.reduce(0) { $0 + $1.principal + $1.interest },
            retirementContribution: d.retirementContribution, net: state.cash - before, economy: d)
        state.aggregates.lifetimeIncome += state.finance.annualLedger.income
        let taxBase = max(1, d.earnings + (d.extraEarnings ?? 0) + d.partnerEarnings + d.pension + d.rentalIncome)
        func afterAllocatedTax(_ gross: Int) -> Int {
            guard gross > 0 else { return 0 }
            let allocatedTax = EconomyPolicy.checkedMultiply(d.totalTaxes, gross) / taxBase
            return max(0, gross - allocatedTax)
        }
        var baseCareer = state.career
        baseCareer.careerClass = .normal
        // A Special or Diamond paycheck mixes conventional occupation pay
        // with pathway-driven upside. Attribute 70% of the normal-class
        // benchmark to salary and the remaining realized pay to the pathway.
        let ordinarySalaryShare = state.career.careerClass == .special || state.career.careerClass == .diamond ? 70 : 100
        let ordinarySalary = min(d.earnings, EconomyPolicy.checkedMultiply(EconomyPolicy.salary(baseCareer), ordinarySalaryShare) / 100)
        state.aggregates.recordIncome(afterAllocatedTax(ordinarySalary), source: .salary)
        let careerPremiumSource: IncomeSource? = switch state.career.careerClass {
        case .normal, .partTime: nil
        case .special: .special
        case .diamond: .diamond
        }
        if let careerPremiumSource {
            state.aggregates.recordIncome(afterAllocatedTax(d.earnings - ordinarySalary), source: careerPremiumSource)
        }
        state.aggregates.recordIncome(afterAllocatedTax(d.extraEarnings ?? 0), source: .sideWork)
        state.aggregates.recordIncome(afterAllocatedTax(d.rentalIncome), source: .rent)
        state.aggregates.lifetimeNet += state.cash - before
        state.aggregates.annualNet = state.cash - before
        state.aggregates.peakCash = max(state.cash, state.aggregates.peakCash)
        var output = SystemYearDeltas(deltas: DeltaSummary(cash: state.cash - before),
            bullets: ["Income $\(state.finance.annualLedger.income) · cash change $\(state.cash - before)"])
        output.mortgageReceipts = d.receipts
        if d.retirementDraw > 0 { output.bullets.append("Retirement draw $\(d.retirementDraw)") }
        if d.unpaid > 0 || state.finance.financialStress >= 85 {
            output.bullets.append("Unpaid obligations $\(d.unpaid) · life continues")
            for target in [ConsequenceDomain.relationships, .health] {
                output.consequences.append(.init(source: .finance, target: target, kind: .debt, magnitude: .major,
                    openedAge: state.character.age, yearsRemaining: 3, headline: "Money Pressure Followed You Home",
                    detail: "Unpaid obligations remain recorded while you rebuild stability."))
            }
        }
        if state.finance.economy.temporaryHousing {
            output.bullets.append("Temporary accommodation · rebuilding stability")
        }
        return output
    }
    static func workoutEligible(_ state: LifeState) -> Bool {
        let e = state.finance.economy
        return state.character.age >= 18 && !state.isGameOver && e.workoutYearsRemaining == 0 && e.shortfallYears >= 2
            && state.finance.consumerDebt + state.finance.medicalDebt > EconomyCalculator.grossHousehold(state, world: WorldSystem.modifiers(for: state.world))
            && e.workoutCompletedAge.map { state.character.age - $0 >= 10 } != false
    }
    static func workoutAssets(_ state: LifeState) -> [UInt64] {
        let keep = state.assets.movableAssets.filter { $0.vehicle?.kind == .car }.min { $0.resaleValue < $1.resaleValue }?.id
        return state.assets.properties.filter { !$0.isPrimaryResidence }.map(\.id)
            + state.assets.movableAssets.filter { $0.id != keep }.map(\.id)
    }
    static func startWorkout(state: inout LifeState) {
        guard workoutEligible(state) else { return }
        let world = WorldSystem.modifiers(for: state.world)
        let buffer = (EconomyCalculator.essentialCost(state, world: world) + (state.assets.primaryProperty.map { EconomyPolicy.scaled($0.totalAnnualCost, world.housingCostMultiplier) + EconomyPolicy.monthlyMortgage($0.mortgageBalance, months: $0.mortgageMonthsRemaining) * 12 } ?? EconomyPolicy.scaled(EconomyPolicy.rent, world.housingCostMultiplier * (state.finance.economy.temporaryHousing ? 0.6 : 1)))) / 12
        var payment = max(0, state.cash - buffer)
        let first = min(payment, state.finance.consumerDebt); payment -= first
        let second = min(payment, state.finance.medicalDebt)
        state.finance.consumerDebt -= first; state.finance.medicalDebt -= second
        state.cash -= first + second
        state.finance.economy.workoutStartedAge = state.character.age
        state.finance.economy.workoutYearsRemaining = 5
        state.finance.retirementContributionPercent = 0
    }
}

/// Converts only monetary fields. Old narrative remains an explicitly labelled historical record.
enum EconomyMigration {
    static func convert(_ old: LifeState) throws -> LifeState {
        guard old.saveVersion < 33 else { return old }
        let encoder = JSONEncoder()
        var object = try JSONSerialization.jsonObject(with: encoder.encode(old)) as! [String: Any]
        func times(_ value: Any?, factor: Int = 100) -> Int { EconomyPolicy.checkedMultiply(value as? Int ?? 0, factor) }
        var finance = object["finance"] as? [String: Any] ?? [:]
        for key in ["studentDebt", "consumerDebt", "medicalDebt", "retirementBalance"] { finance[key] = times(finance[key]) }
        let oldCash = times(object["cash"])
        object["cash"] = max(0, oldCash)
        if oldCash < 0 { finance["consumerDebt"] = EconomyPolicy.checkedAdd(finance["consumerDebt"] as? Int ?? 0, -oldCash) }
        finance["annualLedger"] = [:]
        finance["economy"] = try JSONSerialization.jsonObject(with: encoder.encode(EconomyState(
            shortfallYears: old.recovery?.kind == .financial ? 2 : 0,
            conversionAge: old.character.age, conversionNotice: true, historicalSequence: old.historySequence)))
        object["finance"] = finance
        if old.recovery?.kind == .financial { object.removeValue(forKey: "recovery") }
        var aggregates = object["aggregates"] as? [String: Any] ?? [:]
        for key in ["peakCash", "annualNet", "lifetimeNet", "lifetimeIncome"] where aggregates[key] != nil { aggregates[key] = times(aggregates[key]) }
        object["aggregates"] = aggregates
        var assets = object["assets"] as? [String: Any] ?? [:]
        var properties = assets["properties"] as? [[String: Any]] ?? []
        for i in properties.indices {
            let id = properties[i]["listingID"] as? String ?? ""
            let original = max(1, properties[i]["purchasePrice"] as? Int ?? 1)
            let value = EconomyPolicy.propertyPrice(id) ?? times(properties[i]["purchasePrice"])
            let ratio = Double(value) / Double(original)
            properties[i]["purchasePrice"] = value
            let principal = EconomyPolicy.scaled(properties[i]["mortgageBalance"] as? Int ?? 0, ratio)
            properties[i]["mortgageBalance"] = principal
            properties[i]["mortgageMonthlyPayment"] = EconomyPolicy.monthlyMortgage(principal)
            properties[i]["mortgageMonthsRemaining"] = 360
            properties[i]["annualCost"] = EconomyPolicy.rate(value, 250)
            properties[i]["marketAdjustment"] = EconomyPolicy.scaled(properties[i]["marketAdjustment"] as? Int ?? 0, ratio)
            if var amenities = properties[i]["amenities"] as? [[String: Any]] {
                for j in amenities.indices { for key in ["paidPrice", "valueContribution", "annualUpkeep"] where amenities[j][key] != nil { amenities[j][key] = times(amenities[j][key]) } }
                properties[i]["amenities"] = amenities
            }
            if var rental = properties[i]["rental"] as? [String: Any] {
                rental["lastCollectedRent"] = times(rental["lastCollectedRent"])
                rental["restrictedDeposit"] = 0 // Never invent a historical deposit.
                properties[i]["rental"] = rental
            }
        }
        assets["properties"] = properties
        var movable = assets["movableAssets"] as? [[String: Any]] ?? []
        for i in movable.indices {
            movable[i]["purchasePrice"] = times(movable[i]["purchasePrice"], factor: EconomyPolicy.assetFactor(movable[i]["listingID"] as? String ?? ""))
        }
        assets["movableAssets"] = movable
        assets["lastRentalIncome"] = times(assets["lastRentalIncome"])
        object["assets"] = assets
        // Choices carry their resolved quote; preserve the IDs and never reroll an outstanding decision.
        func convertQuote(_ value: Any) -> Any {
            if var dict = value as? [String: Any] {
                for (key, item) in dict {
                    if ["cash", "cashDelta", "studentDebtDelta", "requestedDebtCharge"].contains(key) {
                        if let range = item as? [Int] { dict[key] = range.map { EconomyPolicy.dollars($0) } }
                        else if let number = item as? Int { dict[key] = EconomyPolicy.dollars(number) }
                        else { dict[key] = convertQuote(item) }
                    } else { dict[key] = convertQuote(item) }
                }
                return dict
            }
            if let list = value as? [Any] { return list.map(convertQuote) }
            return value
        }
        if let pending = object["pendingEvent"] { object["pendingEvent"] = convertQuote(pending) }
        object["saveVersion"] = 33
        return try JSONDecoder().decode(LifeState.self, from: JSONSerialization.data(withJSONObject: object))
    }
}


extension FinanceSystem {
    static func workoutEvent(_ state: LifeState) -> LifeEvent {
        let ids = Set(workoutAssets(state))
        let assets = state.assets.movableAssets.filter { ids.contains($0.id) }.map { "\($0.displayName): $\($0.resaleValue)" }
            + state.assets.properties.filter { ids.contains($0.id) }.map { "\($0.name): $\($0.saleProceeds) net" }
        var projected = state
        for id in workoutAssets(state) { _ = AssetSystem.sell(ownershipID: id, state: &projected) }
        let cashAfterSales = projected.cash
        startWorkout(state: &projected)
        let payment = cashAfterSales - projected.cash
        let detail = "Five years of payments; included interest freezes. Secondary property and nonessential assets are sold. Keep your primary home and one cheapest car. Purchases and retirement contributions pause. Remaining consumer/medical debt is forgiven after five years; student and mortgage debt remains. Sales: " + (assets.isEmpty ? "None." : assets.joined(separator: "; ")) + " Initial debt payment: \(MoneyText.exact(payment)). Cash kept: \(MoneyText.exact(projected.cash)). Included debt remaining: \(MoneyText.exact(projected.finance.consumerDebt + projected.finance.medicalDebt))."
        return LifeEvent(id: "economy-debt-workout", headline: "A Different Way Through The Debt", detail: detail, weight: { _ in 0 }, choices: [
            EventChoice(id: .accept, title: "Start five-year plan", detail: "Accept the listed sales and restrictions.", effects: EffectRange(), partnerEffect: PartnerEffect(), narrative: "You committed to rebuilding your finances over five years.", financeEffect: .startWorkout, financialPurpose: .debtPayment),
            EventChoice(id: .decline, title: "Keep current obligations", detail: "Make no changes to assets or debt.", effects: EffectRange(), partnerEffect: PartnerEffect(), narrative: "You kept the existing obligations and your options open.")
        ])
    }
}

enum MoneyText {
    static func exact(_ value: Int) -> String { value.formatted(.currency(code: "USD").precision(.fractionLength(0))) }
    static func compact(_ value: Int) -> String {
        let amount = Double(value)
        if abs(amount) >= 1_000_000 { return String(format: "$%.1fM", amount / 1_000_000) }
        if abs(amount) >= 10_000 { return String(format: "$%.1fK", amount / 1_000) }
        return exact(value)
    }
}


extension FinanceSystem {
    static func eventPurpose(_ eventID: String) -> FinancialPurpose {
        if eventID.hasPrefix("career-") || ["cash-opening", "promotion-or-plateau", "one-more-year-work", "financial-recovery"].contains(eventID) { return .workEarnings }
        if eventID == "finance-retirement" { return .retirementTransfer }
        if eventID == "finance-interest" { return .debtPayment }
        if ["school-trip-cost", "prom-cost", "school-date-invitation", "school-reunion", "senior-last-night"].contains(eventID) { return .optionalPurchase }
        if eventID.hasPrefix("health-") || ["midlife-health-scare", "finance-medical-bill", "public-health-care", "medical-bill"].contains(eventID) { return .medical }
        if eventID.hasPrefix("college-") || eventID.hasPrefix("education-") || eventID.hasPrefix("school-") { return .education }
        return .household
    }
}

extension FinanceSystem {
    static func choiceAvailability(_ choice: EventChoice, purpose: FinancialPurpose, state: LifeState) -> Availability {
        if purpose == .optionalPurchase && choice.effects.cash.lowerBound < -state.cash {
            return .locked("Requires \(MoneyText.exact(-choice.effects.cash.lowerBound)) available cash")
        }
        return .available
    }

    static func choiceAvailability(_ choice: EventChoice, eventID: String, state: LifeState) -> Availability {
        choiceAvailability(choice, purpose: eventPurpose(eventID), state: state)
    }
}


extension EconomyPolicy {
    /// Catalog quotes are authored here so save conversion and purchases share policy revision 1.
    private static let assetQuotes: [String: Int] = [
        "basketballCourt.annualUpkeep": 2_200,
        "basketballCourt.installationPrice": 22_000,
        "basketballCourt.valueContribution": 14_300,
        "bioluminescentLandscaping.annualUpkeep": 8_000,
        "bioluminescentLandscaping.installationPrice": 70_000,
        "bioluminescentLandscaping.valueContribution": 45_500,
        "boat-cabin-cruiser.price": 260_000,
        "boat-fishing.price": 16_000,
        "boat-luxury-yacht.price": 5_500_000,
        "boat-speedboat.price": 45_000,
        "car-efficient-hybrid.price": 32_500,
        "car-executive-sedan.price": 75_000,
        "car-family-minivan.price": 45_000,
        "car-full-size-suv.price": 70_000,
        "car-grand-tourer.price": 135_000,
        "car-limousine.price": 170_000,
        "car-luxury-coupe.price": 90_000,
        "car-luxury-suv.price": 110_000,
        "car-practical-wagon.price": 22_500,
        "car-reliable-sedan.price": 15_000,
        "car-sport-sedan.price": 65_000,
        "car-track-supercar.price": 150_000,
        "car-used-compact.price": 9_000,
        "car-used-roadster.price": 45_000,
        "car-utility-vehicle.price": 35_000,
        "car-work-pickup.price": 55_000,
        "conversionSwitch.price": 1_300,
        "extendedMagazine.price": 600,
        "flashlight.price": 250,
        "gun-altered-firearm.price": 2_600,
        "gun-automatic-contraband.price": 4_750,
        "gun-collector-firearm.price": 2_500,
        "gun-hunting-rifle.price": 1_000,
        "gun-sporting-handgun.price": 600,
        "gun-sporting-shotgun.price": 1_500,
        "gun-trafficked-collector.price": 3_400,
        "gun-unregistered-handgun.price": 1_200,
        "helicopter-executive.price": 1_020_000,
        "helicopter-luxury.price": 1_560_000,
        "helicopter-utility.price": 660_000,
        "homeGym.annualUpkeep": 1_800,
        "homeGym.installationPrice": 18_000,
        "homeGym.valueContribution": 11_700,
        "hotTub.annualUpkeep": 1_600,
        "hotTub.installationPrice": 14_000,
        "hotTub.valueContribution": 9_100,
        "jewelry-diamond-ring.price": 4_200,
        "jewelry-gold-watch.price": 1_800,
        "jewelry-silver-chain.price": 600,
        "jewelry-statement-piece.price": 8_000,
        "optic.price": 400,
        "landscaping.annualUpkeep": 1_200,
        "landscaping.installationPrice": 12_000,
        "landscaping.valueContribution": 7_800,
        "plane-light-sport.price": 120_000,
        "plane-private-jet.price": 7_500_000,
        "plane-twin-engine.price": 600_000,
        "sauna.annualUpkeep": 2_800,
        "sauna.installationPrice": 26_000,
        "sauna.valueContribution": 16_900,
        "swimmingPool.annualUpkeep": 4_500,
        "swimmingPool.installationPrice": 36_000,
        "swimmingPool.valueContribution": 23_400,
        "vehicle.engine.price": 18_000,
        "vehicle.engine.value": 11_700,
        "vehicle.nitrous.price": 6_000,
        "vehicle.nitrous.value": 3_900,
        "vehicle.rollCage.price": 8_000,
        "vehicle.rollCage.value": 5_200,
        "vehicle.supercharger.price": 15_000,
        "vehicle.supercharger.value": 9_750,
        "vehicle.tires.price": 12_000,
        "vehicle.tires.value": 7_800,
        "vehicle.wheels.price": 7_500,
        "vehicle.wheels.value": 4_875,
        "vehicle.windows.price": 22_000,
        "vehicle.windows.value": 14_300,
        "tennisCourt.annualUpkeep": 5_500,
        "tennisCourt.installationPrice": 45_000,
        "tennisCourt.valueContribution": 29_200,
    ]
    static func assetQuote(_ key: String) -> Int {
        guard let amount = assetQuotes[key] else { preconditionFailure("Missing authored asset quote: \(key)") }
        return amount
    }
    static func propertyTerms(_ id: String, minimumCareerLevel: CareerLevel) -> AssetPurchaseTerms {
        guard let value = propertyPrice(id) else { preconditionFailure("Missing authored property quote") }
        return .mortgage(value: value, downPayment: rate(value, 2_000), annualCost: rate(value, 250), minimumCareerLevel: minimumCareerLevel)
    }
}


extension EconomyPolicy {
    private static let actionQuotes: [ActionID: ClosedRange<Int>] = [
        .applyForBetterWork: 0 ... 0,
        .applyToCollege: -2_000 ... -1_000,
        .changeCareer: -3_500 ... -3_500,
        .familyDinner: -3_500 ... -2_000,
        .goOnDate: -3_000 ... -2_000,
        .helpAtHome: 3_500 ... 5_500,
        .networkContacts: -1_500 ... -500,
        .party: -4_500 ... -3_000,
        .returnToEducation: -1_500 ... -500,
        .sideHustle: 0 ... 0,
        .skillCourse: -4_500 ... -2_500,
        .workShift: 0 ... 0,
    ]
    static func actionQuote(_ id: ActionID) -> ClosedRange<Int> { actionQuotes[id] ?? 0 ... 0 }
}
