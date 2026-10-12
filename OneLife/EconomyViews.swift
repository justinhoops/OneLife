import SwiftUI

struct EconomyHouseholdView: View {
    @ObservedObject var simulator: LifeSimulator
    @Environment(\.dismiss) private var dismiss
    private var state: LifeState { simulator.state }
    private var forecast: EconomyAnnualDetail { EconomyCalculator.forecast(state).detail }

    var body: some View {
        NavigationStack {
            List {
                Section("Expected next year") {
                    LabeledContent("Available cash", value: MoneyText.exact(state.cash))
                    LabeledContent("Monthly surplus / shortfall", value: MoneyText.exact(forecast.expectedNet / 12))
                        .foregroundStyle(forecast.expectedNet < 0 ? .red : .primary)
                    LabeledContent("Annual surplus / shortfall", value: MoneyText.exact(forecast.expectedNet))
                    if state.career.track == .freelance {
                        let range = EconomyCalculator.earningsRange(state)
                        LabeledContent("Expected work income range", value: "\(MoneyText.exact(range.lowerBound))–\(MoneyText.exact(range.upperBound))")
                    }
                    LabeledContent("Net worth", value: MoneyText.exact(state.netWorth))
                    Text("Age Up settles one year automatically. Income and rent are estimates; work, tenants, and world conditions can change them.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                if let actual = state.finance.annualLedger.economy {
                    Section("Last completed settlement") {
                        LabeledContent("Work earnings", value: MoneyText.exact(actual.earnings + (actual.extraEarnings ?? 0)))
                        LabeledContent("Partner earnings", value: MoneyText.exact(actual.partnerEarnings))
                        LabeledContent("Support and pension", value: MoneyText.exact(actual.support + actual.pension))
                        LabeledContent("Rental income", value: MoneyText.exact(actual.rentalIncome))
                        LabeledContent("Taxes for the year", value: MoneyText.exact(actual.totalTaxes))
                        LabeledContent("Tax paid / refund at settlement", value: MoneyText.exact(actual.taxReconciliation))
                        LabeledContent("Extra-work withholding already paid", value: MoneyText.exact(actual.withholdingPaid ?? 0))
                        LabeledContent("Essential costs paid", value: MoneyText.exact(actual.essentialPaid ?? actual.essentials))
                        LabeledContent("Property operating costs paid", value: MoneyText.exact(actual.operatingPaid ?? 0))
                        LabeledContent("Primary housing paid", value: MoneyText.exact(actual.primaryHousing))
                        LabeledContent("Other property payments", value: MoneyText.exact(actual.secondaryHousing))
                        LabeledContent("Debt principal paid", value: MoneyText.exact(actual.principal))
                        LabeledContent("Interest paid", value: MoneyText.exact(actual.interest))
                        Text("Principal and interest explain the payments above; they are not extra charges.").font(.caption)
                        LabeledContent("Unpaid obligations", value: MoneyText.exact(actual.unpaid))
                        LabeledContent("Retirement saved / drawn", value: "\(MoneyText.exact(actual.retirementContribution)) / \(MoneyText.exact(actual.retirementDraw))")
                        LabeledContent("Cash change", value: MoneyText.exact(actual.closingCash - actual.openingCash))
                    }
                }
                Section("Debt and future") {
                    LabeledContent("Student debt · 6%", value: MoneyText.exact(state.finance.studentDebt))
                    LabeledContent("Consumer debt · 18%", value: MoneyText.exact(state.finance.consumerDebt))
                    LabeledContent("Medical debt · 0%", value: MoneyText.exact(state.finance.medicalDebt))
                    LabeledContent("Mortgages", value: MoneyText.exact(state.assets.totalMortgageDebt))
                    LabeledContent("Retirement savings", value: MoneyText.exact(state.finance.retirementBalance))
                    LabeledContent("Contribution choice", value: "\(state.finance.retirementContributionPercent)%")
                    Text("Taxes, benefits, and debt relief use fictional game rules.").font(.caption).foregroundStyle(.secondary)
                }
                Section("Recovery choices") {
                    if state.finance.economy.temporaryHousing { Text("Temporary accommodation costs 60% of standard rent while you rebuild.") }
                    if state.finance.economy.workoutYearsRemaining > 0 {
                        Text("Debt workout: \(state.finance.economy.workoutYearsRemaining) years remaining. Included interest is frozen; purchases and retirement contributions are paused.")
                    }
                    recoveryButton(.budget)
                    if state.assets.primaryProperty != nil { recoveryButton(.sellOrDownsize) }
                    if FinanceSystem.workoutEligible(state) { recoveryButton(.negotiateDebt) }
                    Text("Money trouble does not end a life. Missed obligations remain recorded.").font(.caption)
                }
            }
            .navigationTitle("Household Ledger")
            .toolbar { Button("Done") { dismiss() } }
        }
    }
    private func recoveryButton(_ id: ActionID) -> some View {
        let action = DomainActionRegistry.action(for: id)
        return Button(action.name) {
            _ = simulator.execute(id)
            if id == .negotiateDebt { dismiss() }
        }
        .accessibilityIdentifier("Economy recovery \(id.rawValue)")
        .disabled(simulator.availability(for: action) != .available)
    }
}

struct EconomyConversionView: View {
    @ObservedObject var simulator: LifeSimulator
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            List {
                Section("Your life is preserved") {
                    Text("Money now uses recognizable dollars. Your character, relationships, progress, and possessions remain. A backup of the previous save was preserved.")
                    LabeledContent("Cash", value: MoneyText.exact(simulator.state.cash))
                    LabeledContent("Debt", value: MoneyText.exact(simulator.state.totalDebt))
                    LabeledContent("Property equity", value: MoneyText.exact(simulator.state.assets.propertyEquity))
                    LabeledContent("Expected annual balance", value: MoneyText.exact(EconomyCalculator.forecast(simulator.state).detail.expectedNet))
                    Text("Mortgage payments were recalculated over 30 years. Old journal entries retain their original amounts and are labelled Before economy update.")
                }
            }
            .navigationTitle("Economy Updated")
            .toolbar { Button("Continue") { simulator.acknowledgeEconomyConversion(); dismiss() } }
        }
        .interactiveDismissDisabled()
    }
}
