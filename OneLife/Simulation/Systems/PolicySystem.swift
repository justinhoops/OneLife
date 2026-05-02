import Foundation

struct PolicySystem {
    let policies: FinancePolicySet

    init(policies: FinancePolicySet = .usBaseline) {
        self.policies = policies
    }

    func ensureDefaultPolicy(finance: inout FinanceState) {
        if finance.currentRegionPolicyID == nil {
            finance.currentRegionPolicyID = "mountain_standard"
        }
    }

    func currentPolicy(for finance: FinanceState) -> StateFinancePolicy {
        policies.states[finance.currentRegionPolicyID ?? "mountain_standard"] ??
        policies.states["mountain_standard"] ??
        StateFinancePolicy(id: "mountain_standard")
    }

    func educationSupport(for finance: FinanceState) -> Int {
        currentPolicy(for: finance).schoolSupportLevel
    }

    func healthcarePressure(for finance: FinanceState) -> Int {
        let policy = currentPolicy(for: finance)
        return Int(((policy.healthcareCostMultiplier - 1.0) * 20).rounded())
    }
}
