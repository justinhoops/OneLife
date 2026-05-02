import Foundation

struct FinanceSystem {
    let policies: FinancePolicySet
    let balanceProfile: SimulationBalanceProfile

    init(
        policies: FinancePolicySet = .usBaseline,
        balanceProfile: SimulationBalanceProfile = .playableRealismV1
    ) {
        self.policies = policies
        self.balanceProfile = balanceProfile
    }

    func advanceYear(input: FinanceDomainSnapshot, finance: inout FinanceState) -> DomainYearResult {
        var result = advanceYear(
            context: FinanceYearContext(
                age: input.world.age,
                isSchoolAge: input.world.isSchoolAge,
                careerStatus: input.career.status,
                careerLevel: input.career.level,
                grossIncome: input.career.annualIncome,
                traits: input.player.traits,
                educationPathway: input.education.pathway,
                educationStage: input.education.stage,
                hasScholarship: input.education.hasScholarship,
                housingCostBand: input.housing.housingCostBand,
                housingArrangement: input.housing.livingArrangement,
                activeConditionCount: input.health.activeConditions.count,
                ownsHome: input.assets.ownsHome,
                hasPrimaryCare: input.health.hasPrimaryCare,
                friendCount: input.relationships.friends.count,
                partnerCount: input.relationships.hasPartner ? 1 : 0,
                hasSpouse: input.relationships.hasSpouse,
                hasCohabitingPartner: input.relationships.hasCohabitingPartner,
                isPregnant: input.family.isPregnant,
                pregnancyPhase: input.family.pregnancy?.phase,
                infantCount: input.family.infantCount,
                childCount: max(0, input.family.dependentChildCount - input.family.infantCount)
            ),
            finance: &finance,
            player: input.player
        )
        if input.world.age >= 18 {
            if input.finance.hasInvestments || input.assets.ownsHome || finance.hasInvestments || finance.homeEquity > 0 {
                finance.compoundingYears += 1
            } else if finance.compoundingYears > 0, finance.stabilityStreakYears == 0 {
                finance.compoundingYears = max(0, finance.compoundingYears - 1)
            }
        }
        if (input.relationships.activeTensionCount > 0 || input.relationships.futureAlignment.averageReadiness <= 42),
           (input.relationships.hasCohabitingPartner || input.relationships.hasSpouse) {
            finance.financialStress = (finance.financialStress + 2).clamped(to: 0...100)
            result.notes.append(
                DomainNote(
                    title: "Relationship Budget Drag",
                    text: "Unresolved tension inside the relationship made money feel tighter and less cooperative this year.",
                    tags: [.finance, .relationships]
                )
            )
        }
        return result
    }

    func advanceYear(
        context: FinanceYearContext,
        finance: inout FinanceState,
        player: Player
    ) -> DomainYearResult {
        var result = DomainYearResult()
        let previousCash = finance.cashOnHand
        let previousTotalWealth = finance.totalWealth
        let previousLivingCost = finance.annualLivingCost
        let previousStress = finance.financialStress
        let previousDeficitYears = finance.consecutiveDeficitYears
        let statePolicy = finance.currentRegionPolicyID.flatMap { policies.states[$0] }
        finance.resetAnnualWealthVelocity()

        finance.annualGrossIncome = context.grossIncome
        finance.effectiveTaxRate = effectiveTaxRate(for: context.grossIncome, statePolicy: statePolicy)
        let taxes = context.grossIncome * finance.effectiveTaxRate / 100
        finance.annualNetIncome = context.grossIncome - taxes

        finance.annualLivingCost = adjustedCost(
            baselineLivingCost(for: context),
            multiplier: statePolicy?.costOfLivingMultiplier ?? 1.0
        )
        finance.annualEducationCost = adjustedCost(
            baselineEducationCost(for: context),
            multiplier: statePolicy?.educationCostMultiplier ?? 1.0
        )
        finance.annualDependentCost = adjustedCost(
            baselineDependentCost(for: context),
            multiplier: statePolicy?.dependentCostMultiplier ?? 1.0
        )
        let targetLifestyleCreep = resolvedLifestyleCreep(for: context)
        finance.lifestyleCreep = ((finance.lifestyleCreep * 2) + targetLifestyleCreep) / 3
        finance.annualDiscretionaryCost = discretionaryCost(for: player, traits: context.traits) + finance.lifestyleCreep
        finance.annualTotalExpenses =
            finance.annualLivingCost +
            finance.annualEducationCost +
            finance.annualDependentCost +
            finance.annualDiscretionaryCost

        let setback = resolvedSetback(for: context, finance: finance)
        if setback.cost > 0 {
            finance.annualTotalExpenses += setback.cost
            finance.majorSetbackCount += 1
            if let note = setback.note {
                result.notes.append(note)
            }
        }

        let debtResult = applyDebtLoad(context: context, finance: &finance)
        mergeDebtResult(debtResult, into: &result)

        finance.lastYearBalanceDelta = finance.annualNetIncome - finance.annualTotalExpenses
        finance.cashOnHand += finance.lastYearBalanceDelta
        if context.educationStage == .university && finance.cashOnHand < 0 {
            let debtCovered = abs(finance.cashOnHand)
            finance.studentDebt += debtCovered
            finance.cashOnHand += debtCovered
        } else if (context.educationStage == .tradeTraining || context.educationStage == .adultEd) && finance.cashOnHand < 0 {
            let debtCovered = abs(finance.cashOnHand)
            finance.studentDebt += debtCovered
            finance.cashOnHand += debtCovered
        } else {
            let rolloverResult = absorbDebtBackstop(context: context, finance: &finance)
            mergeDebtResult(rolloverResult, into: &result)
        }
        refreshDebtState(for: &finance)
        finance.consecutiveDeficitYears = updatedDeficitYears(
            previousDeficitYears: previousDeficitYears,
            balanceDelta: finance.lastYearBalanceDelta
        )

        finance.financialStress = recalculatedStress(
            currentCash: finance.cashOnHand,
            balanceDelta: finance.lastYearBalanceDelta,
            netIncome: finance.annualNetIncome,
            totalExpenses: finance.annualTotalExpenses,
            activeConditionCount: context.activeConditionCount,
            careerStatus: context.careerStatus,
            consecutiveDeficitYears: finance.consecutiveDeficitYears
        )
        finance.financialStress = adjustedStressForDebt(baseStress: finance.financialStress, finance: finance)
        finance.stabilityStreakYears = updatedStabilityStreak(
            previousStabilityStreak: finance.stabilityStreakYears,
            context: context,
            finance: finance
        )

        if (18...35).contains(context.age) {
            if finance.consecutiveDeficitYears >= 2 {
                finance.financialStress = (finance.financialStress + 4).clamped(to: 0...100)
            }
            if context.careerStatus == .unemployed && finance.cashOnHand < 0 {
                finance.financialStress = (finance.financialStress + 5).clamped(to: 0...100)
            }
            if context.hasCohabitingPartner && finance.financialStress >= 45 {
                finance.financialStress = (finance.financialStress + 2).clamped(to: 0...100)
                finance.annualDiscretionaryCost = max(0, finance.annualDiscretionaryCost + 600)
            }
            if context.childCount > 0 || context.infantCount > 0 {
                finance.financialStress = (finance.financialStress + max(1, context.childCount + context.infantCount)).clamped(to: 0...100)
            }
        }

        if finance.lastYearBalanceDelta < 0 {
            if finance.consecutiveDeficitYears >= 2 {
                result.notes.append(DomainNote(title: "Finance Pressure", text: "Another deficit year deepened the strain. You finished $\(abs(finance.lastYearBalanceDelta)) short."))
            } else {
                result.notes.append(DomainNote(title: "Finance", text: "Your yearly costs outpaced your income by $\(abs(finance.lastYearBalanceDelta))."))
            }
        } else if finance.lastYearBalanceDelta >= 5_000 {
            result.notes.append(DomainNote(title: "Finance", text: "A strong annual surplus of $\(finance.lastYearBalanceDelta) gave you room to breathe."))
        } else if previousDeficitYears > 0 {
            result.notes.append(DomainNote(title: "Finance Recovery", text: "A positive year steadied your budget and eased some of the pressure."))
        }

        if previousCash < 0, finance.cashOnHand >= 0 {
            result.notes.append(DomainNote(title: "Finance Recovery", text: "You climbed back out of negative cash this year."))
        }

        if context.educationStage == .university && finance.studentDebt > 0 {
            if finance.studentDebt >= 20_000 {
                result.notes.append(DomainNote(title: "Student Debt", text: "Debt is now a defining part of how your education is getting financed.", tags: [.finance, .education]))
            } else if finance.studentDebt >= 5_000 {
                result.notes.append(DomainNote(title: "Student Debt", text: "You had to lean on debt to keep school moving.", tags: [.finance, .education]))
            }
        }

        if finance.creditDebt > 0 || finance.medicalDebt > 0 {
            result.notes.append(
                DomainNote(
                    title: "Debt Balance",
                    text: "Debt is no longer just tuition. Revolving and medical balances are now carrying part of the year forward.",
                    tags: [.finance]
                )
            )
        }

        if previousLivingCost > 0, finance.annualLivingCost - previousLivingCost >= 3_000 {
            result.notes.append(DomainNote(title: "Finance", text: "Your cost of living took a noticeable jump this year."))
        }

        if finance.lifestyleCreep >= 1_500, finance.annualGrossIncome >= 45_000 {
            result.notes.append(
                DomainNote(
                    title: "Lifestyle Creep",
                    text: "Better income raised the standard of what felt normal, which quietly absorbed more of the year than you expected.",
                    tags: [.finance]
                )
            )
        }

        if previousStress < 45, finance.financialStress >= 45 {
            result.notes.append(DomainNote(title: "Financial Stress", text: "Money pressure is now bleeding into the rest of your life."))
        }

        if (18...35).contains(context.age), finance.consecutiveDeficitYears >= 2 {
            result.notes.append(
                DomainNote(
                    title: "Adult Finance Pressure",
                    text: "The shortfall is no longer a rough year. It is starting to reshape housing, relationships, and how much future you can afford to imagine.",
                    tags: [.finance, .housing, .relationships]
                )
            )
        }

        if (18...35).contains(context.age), context.hasCohabitingPartner, finance.financialStress >= 45 {
            result.notes.append(
                DomainNote(
                    title: "Shared Budget Strain",
                    text: "Money stress is landing inside the household now, not just inside your own head.",
                    tags: [.finance, .relationships]
                )
            )
        }

        let sideEffects = stressSideEffects(for: finance)
        result.coreEffects = sideEffects.coreEffects
        result.healthEffects = sideEffects.healthEffects
        result.relationshipEffects = sideEffects.relationshipEffects
        finance.accumulateWealthDelta(from: previousTotalWealth)

        return result
    }

    func apply(effect: FinanceEffects, finance: inout FinanceState, player: inout Player) {
        finance.cashOnHand += effect.cashDelta ?? 0
        finance.studentDebt = max(0, finance.studentDebt + (effect.studentDebtDelta ?? 0))
        finance.creditDebt = max(0, finance.creditDebt + (effect.creditDebtDelta ?? 0))
        finance.medicalDebt = max(0, finance.medicalDebt + (effect.medicalDebtDelta ?? 0))
        finance.annualLivingCost = max(0, finance.annualLivingCost + (effect.livingCostDelta ?? 0))
        finance.annualEducationCost = max(0, finance.annualEducationCost + (effect.educationCostDelta ?? 0))
        finance.annualDependentCost = max(0, finance.annualDependentCost + (effect.dependentCostDelta ?? 0))
        finance.annualDiscretionaryCost = max(0, finance.annualDiscretionaryCost + (effect.discretionaryCostDelta ?? 0))
        finance.financialStress = (finance.financialStress + (effect.financialStressDelta ?? 0)).clamped(to: 0...100)

        if let regionPolicyID = effect.setRegionPolicyID {
            finance.currentRegionPolicyID = regionPolicyID
        }

        finance.annualTotalExpenses =
            finance.annualLivingCost +
            finance.annualEducationCost +
            finance.annualDependentCost +
            finance.annualDiscretionaryCost
        refreshDebtState(for: &finance)
        finance.normalizeInvestmentBalances()
    }

    func applyAction(_ choiceID: ActionChoiceID, finance: inout FinanceState, player: inout Player) -> DomainYearResult {
        var result = DomainYearResult()

        switch choiceID {
        case .cutSpending:
            finance.annualDiscretionaryCost = max(0, finance.annualDiscretionaryCost - 500)
            finance.financialStress = (finance.financialStress - 2).clamped(to: 0...100)
            result.coreEffects = CoreStatEffects(happiness: -1)
            result.notes.append(
                DomainNote(
                    title: "Finance Focus",
                    text: "You tightened spending this year to protect your budget.",
                    tags: [.finance]
                )
            )
        case .smallHustle:
            finance.cashOnHand += player.age < 16 ? 180 : 260
            result.healthEffects = HealthEffects(physical: nil, mental: -1, exercise: nil, nutrition: nil, stressManagement: -2, addCondition: nil, removeCondition: nil, hasPrimaryCare: nil)
            result.notes.append(
                DomainNote(
                    title: "Finance Focus",
                    text: "You found a little teen money, but it cost some recovery and breathing room.",
                    tags: [.finance, .health]
                )
            )
        case .takeExtraShifts:
            finance.cashOnHand += player.age < 18 ? 420 : 950
            result.educationEffects = EducationEffects(attendancePressure: 4, applicationReadiness: -2, burnoutRisk: 5)
            result.healthEffects = HealthEffects(physical: nil, mental: -2, exercise: nil, nutrition: nil, stressManagement: -2, addCondition: nil, removeCondition: nil, hasPrimaryCare: nil)
            result.notes.append(
                DomainNote(
                    title: "Finance Focus",
                    text: "Extra shifts brought in money, but school and recovery both took the hit.",
                    tags: [.finance, .education]
                )
            )
        case .saveForEscape:
            finance.cashOnHand += player.age < 18 ? 220 : 500
            finance.annualDiscretionaryCost = max(0, finance.annualDiscretionaryCost - 300)
            result.coreEffects = CoreStatEffects(happiness: -1)
            result.notes.append(
                DomainNote(
                    title: "Finance Focus",
                    text: "You saved with intent this year, giving yourself a little mobility at the cost of comfort.",
                    tags: [.finance]
                )
            )
        case .spendForRelief:
            finance.cashOnHand -= 250
            result.coreEffects = CoreStatEffects(happiness: 2)
            result.notes.append(
                DomainNote(
                    title: "Finance Focus",
                    text: "You spent for short-term relief, which helped emotionally but thinned your cash.",
                    tags: [.finance]
                )
            )
        case .spendToCope:
            finance.cashOnHand -= 320
            result.coreEffects = CoreStatEffects(happiness: 2)
            result.healthEffects = HealthEffects(physical: nil, mental: 1, exercise: nil, nutrition: nil, stressManagement: -2, addCondition: nil, removeCondition: nil, hasPrimaryCare: nil)
            result.notes.append(
                DomainNote(
                    title: "Finance Focus",
                    text: "You spent to numb the pressure. It helped for a minute and made the margin thinner.",
                    tags: [.finance, .health]
                )
            )
        case .takeSideWork:
            finance.cashOnHand += player.age < 18 ? 250 : 700
            result.healthEffects = HealthEffects(physical: nil, mental: -2, exercise: nil, nutrition: nil, stressManagement: nil, addCondition: nil, removeCondition: nil, hasPrimaryCare: nil)
            result.notes.append(
                DomainNote(
                    title: "Finance Focus",
                    text: "You picked up side work for extra cash, but it took a little out of you.",
                    tags: [.finance]
                )
            )
        case .payDownDebt:
            finance.debtStrategy = .aggressive
            finance.financialStress = (finance.financialStress - 2).clamped(to: 0...100)
            result.coreEffects = CoreStatEffects(happiness: -1)
            result.notes.append(
                DomainNote(
                    title: "Debt Focus",
                    text: "You aimed extra money at the balances this year, making the present tighter to buy more future room.",
                    tags: [.finance]
                )
            )
        case .consolidateDebt:
            guard finance.totalNonHousingDebt > 0 else {
                result.notes.append(DomainNote(title: "Debt Focus", text: "You looked for debt relief, but there was not enough non-housing debt to restructure yet.", tags: [.finance]))
                return result
            }
            finance.cashOnHand -= 850
            finance.recentDebtReliefYears = max(finance.recentDebtReliefYears, 3)
            finance.debtDelinquencyRisk = max(0, finance.debtDelinquencyRisk - 12)
            finance.financialStress = (finance.financialStress - 1).clamped(to: 0...100)
            result.notes.append(
                DomainNote(
                    title: "Debt Focus",
                    text: "You restructured the debt into something more survivable, but not cleaner.",
                    tags: [.finance]
                )
            )
        case .minimumPayments:
            finance.debtStrategy = .minimumOnly
            result.notes.append(
                DomainNote(
                    title: "Debt Focus",
                    text: "You kept the accounts barely current and protected cash at the expense of long-term progress.",
                    tags: [.finance]
                )
            )
        case .deferStudentLoans:
            guard finance.studentDebt > 0 else {
                result.notes.append(DomainNote(title: "Debt Focus", text: "You tried to defer student loans, but there is no education debt to push forward.", tags: [.finance]))
                return result
            }
            finance.debtStrategy = .deferStudentLoans
            finance.financialStress = (finance.financialStress + 1).clamped(to: 0...100)
            result.notes.append(
                DomainNote(
                    title: "Debt Focus",
                    text: "You pushed the student loan bill into the future so this year had a chance to stay standing.",
                    tags: [.finance, .education]
                )
            )
        case .declareBankruptcy:
            guard finance.canUseDebtReset else {
                result.notes.append(DomainNote(title: "Debt Focus", text: "The debt is painful, but not yet at the point where bankruptcy is available as a last resort.", tags: [.finance]))
                return result
            }
            finance.creditDebt = 0
            finance.medicalDebt = Int((Double(finance.medicalDebt) * 0.2).rounded())
            finance.indexFundBalance = 0
            finance.stockPortfolioBalance = 0
            finance.investedBalance = 0
            finance.costBasis = 0
            finance.cashOnHand = max(0, finance.cashOnHand - 500)
            finance.financialStress = (finance.financialStress + 10).clamped(to: 0...100)
            finance.debtDelinquencyRisk = 72
            finance.recentDebtReliefYears = max(finance.recentDebtReliefYears, 5)
            result.healthEffects = HealthEffects(physical: nil, mental: -4, exercise: nil, nutrition: nil, stressManagement: -4, addCondition: nil, removeCondition: nil, hasPrimaryCare: nil)
            result.relationshipEffects = RelationshipEffects(meetNewFriend: nil, friendChange: -1, startDating: nil, partnerChange: -1, loseFriend: nil, breakup: nil)
            result.notes.append(
                DomainNote(
                    title: "Bankruptcy",
                    text: "You let the debt collapse on paper. Some balances died, but the damage to confidence and future flexibility did not.",
                    tags: [.finance]
                )
            )
        default:
            return result
        }

        refreshDebtState(for: &finance)
        return result
    }

    private func effectiveTaxRate(for grossIncome: Int, statePolicy: StateFinancePolicy?) -> Int {
        let federalRate = policies.federal.taxBands
            .sorted { $0.minimumIncome < $1.minimumIncome }
            .last(where: { grossIncome >= $0.minimumIncome })?
            .ratePercent ?? 8
        return (federalRate + (statePolicy?.incomeTaxRateDelta ?? 0)).clamped(to: 0...35)
    }

    private func baselineLivingCost(for context: FinanceYearContext) -> Int {
        var cost: Int

        switch (context.age, context.careerStatus) {
        case (...17, .student):
            cost = 1_800
        case (...17, .partTime), (...17, .fullTime):
            cost = 3_400
        case (18...22, .student):
            cost = 11_800
        case (18..., .unemployed):
            cost = 10_500
        case (18..., .partTime):
            cost = 13_200
        case (18...25, .fullTime):
            cost = 19_800
        case (26..., .fullTime):
            cost = 22_000
        default:
            cost = 3_000
        }

        if context.ownsHome {
            cost = max(4_500, cost - 2_400)
        }

        if !(context.age <= 17 && context.careerStatus == .student && context.housingArrangement == .familyHome) {
            cost += context.housingCostBand * 80
        }

        if context.housingArrangement == .roommates {
            cost -= 1_500
        } else if context.housingArrangement == .soloRenting {
            cost += 2_200
        } else if context.housingArrangement == .couchSurfing {
            cost -= 2_400
        }

        if context.hasPrimaryCare {
            cost += 700 + max(0, context.housingCostBand - 40) * 8
        }

        if context.educationStage == .university {
            cost += context.hasScholarship ? 1_000 : 2_400
        } else if context.educationStage == .adultEd {
            cost += 600
        }

        return max(0, cost)
    }

    private func baselineEducationCost(for context: FinanceYearContext) -> Int {
        switch context.educationStage {
        case .university:
            return context.hasScholarship ? 3_600 : (context.housingArrangement == .familyHome ? 7_500 : 10_800)
        case .tradeTraining:
            return 2_200
        case .adultEd:
            return 1_400
        case .secondary, .inactive:
            break
        }

        if context.educationPathway == .student && context.isSchoolAge {
            return 600
        }

        if context.educationPathway == .training {
            return 1_500
        }

        if context.age <= 22 && context.careerStatus == .student {
            return 2_400
        }

        return 0
    }

    private func baselineDependentCost(for context: FinanceYearContext) -> Int {
        var cost = 0

        if context.hasCohabitingPartner {
            cost += context.hasSpouse ? 2_400 : 1_400
        }

        if context.isPregnant {
            switch context.pregnancyPhase {
            case .firstTrimester:
                cost += 900
            case .secondTrimester:
                cost += 1_600
            case .thirdTrimester:
                cost += 2_400
            case nil:
                cost += 1_200
            }
        }

        cost += context.infantCount * 4_800
        cost += context.childCount * 3_100

        return cost
    }

    private func discretionaryCost(for player: Player, traits: [PersonalityTrait]) -> Int {
        var cost = max(250, 900 + ((player.happiness - 50) * 28))
        if traits.contains(.impulsive) { cost += 1_200 }
        if traits.contains(.charismatic) { cost += 400 }
        if traits.contains(.disciplined) { cost -= 700 }
        if traits.contains(.anxious) { cost -= 200 }
        if player.age < 18 {
            cost = max(150, cost - 350)
        }
        return cost.clamped(to: 150...4_800)
    }

    private func resolvedLifestyleCreep(for context: FinanceYearContext) -> Int {
        guard context.age >= 18 else { return 0 }

        var creep = 0
        switch context.grossIncome {
        case 140_000...:
            creep += 4_200
        case 90_000...139_999:
            creep += 2_600
        case 60_000...89_999:
            creep += 1_500
        case 35_000...59_999:
            creep += 700
        default:
            break
        }

        creep += max(0, context.careerLevel - 2) * 250
        if context.housingArrangement == .soloRenting { creep += 350 }
        if context.ownsHome { creep += 450 }
        if context.hasCohabitingPartner { creep += context.hasSpouse ? 800 : 450 }
        creep += context.childCount * 250
        creep += context.infantCount * 350

        if context.traits.contains(.impulsive) { creep += 1_000 }
        if context.traits.contains(.charismatic) { creep += 300 }
        if context.traits.contains(.disciplined) { creep -= 600 }
        if context.traits.contains(.anxious) { creep -= 150 }

        return creep.clamped(to: 0...9_500)
    }

    private func adjustedCost(_ amount: Int, multiplier: Double) -> Int {
        Int((Double(amount) * multiplier).rounded())
    }

    private func recalculatedStress(
        currentCash: Int,
        balanceDelta: Int,
        netIncome: Int,
        totalExpenses: Int,
        activeConditionCount: Int,
        careerStatus: CareerStatus,
        consecutiveDeficitYears: Int
    ) -> Int {
        var stress = 12
        if currentCash < 0 { stress += min(28, abs(currentCash) / 450) }
        if balanceDelta < 0 { stress += min(24, abs(balanceDelta) / 650) }
        if totalExpenses > netIncome { stress += min(12, (totalExpenses - netIncome) / 900) }
        if careerStatus == .unemployed { stress += 9 }
        stress += min(15, max(0, consecutiveDeficitYears - 1) * 5)
        stress += activeConditionCount * 5
        if balanceDelta > 0 {
            stress -= min(6, balanceDelta / 2_000)
        }
        if currentCash > 20_000 {
            stress -= min(6, currentCash / 10_000)
        }
        return stress.clamped(to: 0...100)
    }

    private func updatedDeficitYears(previousDeficitYears: Int, balanceDelta: Int) -> Int {
        if balanceDelta < 0 {
            return previousDeficitYears + 1
        }
        if balanceDelta > 0 {
            return 0
        }
        return max(0, previousDeficitYears - 1)
    }

    private func updatedStabilityStreak(
        previousStabilityStreak: Int,
        context: FinanceYearContext,
        finance: FinanceState
    ) -> Int {
        guard context.age >= 18 else { return 0 }
        let isStableAdultYear =
            finance.lastYearBalanceDelta >= balanceProfile.wealth.adultStableSurplusThreshold &&
            finance.cashOnHand >= 0 &&
            finance.financialStress <= balanceProfile.wealth.adultStableStressCeiling

        if isStableAdultYear {
            return previousStabilityStreak + 1
        }
        if finance.lastYearBalanceDelta < 0 || finance.cashOnHand < 0 {
            return 0
        }
        return max(0, previousStabilityStreak - 1)
    }

    private func adjustedStressForDebt(baseStress: Int, finance: FinanceState) -> Int {
        var stress = baseStress
        stress += finance.debtDelinquencyRisk / 12
        switch finance.debtPressureBand {
        case .clear:
            break
        case .manageable:
            stress += 1
        case .heavy:
            stress += 6
        case .crushing:
            stress += 12
        }
        if finance.recentDebtReliefYears > 0 {
            stress += 2
        }
        return stress.clamped(to: 0...100)
    }

    private func applyDebtLoad(
        context: FinanceYearContext,
        finance: inout FinanceState
    ) -> DomainYearResult {
        var result = DomainYearResult()
        guard context.age >= 18 else {
            finance.annualDebtPayments = 0
            refreshDebtState(for: &finance)
            finance.debtStrategy = .standard
            return result
        }

        if finance.recentDebtReliefYears > 0 {
            finance.recentDebtReliefYears -= 1
        }

        let strategy = finance.debtStrategy
        let hasRestructureProtection = finance.recentDebtReliefYears > 0

        finance.studentDebt += accruedInterest(
            for: finance.studentDebt,
            ratePercent: strategy == .deferStudentLoans
                ? balanceProfile.debt.deferredStudentInterestRatePercent
                : balanceProfile.debt.studentInterestRatePercent
        )
        finance.creditDebt += accruedInterest(
            for: finance.creditDebt,
            ratePercent: hasRestructureProtection
                ? balanceProfile.debt.restructuredCreditInterestRatePercent
                : balanceProfile.debt.creditInterestRatePercent
        )
        finance.medicalDebt += accruedInterest(
            for: finance.medicalDebt,
            ratePercent: hasRestructureProtection
                ? balanceProfile.debt.restructuredMedicalInterestRatePercent
                : balanceProfile.debt.medicalInterestRatePercent
        )

        let studentRequired = strategy == .deferStudentLoans ? 0 : requiredPayment(
            for: finance.studentDebt,
            minimum: balanceProfile.debt.studentMinimumPayment,
            ratePercent: balanceProfile.debt.studentPaymentRatePercent
        )
        let creditBase = requiredPayment(
            for: finance.creditDebt,
            minimum: balanceProfile.debt.creditMinimumPayment,
            ratePercent: balanceProfile.debt.creditPaymentRatePercent
        )
        let medicalBase = requiredPayment(
            for: finance.medicalDebt,
            minimum: balanceProfile.debt.medicalMinimumPayment,
            ratePercent: balanceProfile.debt.medicalPaymentRatePercent
        )
        let creditRequired = hasRestructureProtection ? Int((Double(creditBase) * 0.8).rounded()) : creditBase
        let medicalRequired = hasRestructureProtection ? Int((Double(medicalBase) * 0.85).rounded()) : medicalBase
        let requiredTotal = studentRequired + creditRequired + medicalRequired

        let surplusCapacity = max(0, finance.annualNetIncome - finance.annualTotalExpenses)
        let liquidCapacity = max(0, finance.cashOnHand)
        let availableCapacity = surplusCapacity + liquidCapacity

        var targetPayment = requiredTotal
        switch strategy {
        case .aggressive:
            targetPayment += min(max(1_200, availableCapacity / 3), max(0, finance.totalNonHousingDebt / 5))
        case .minimumOnly, .deferStudentLoans:
            targetPayment = requiredTotal
        case .standard:
            targetPayment += min(1_800, max(0, (availableCapacity - requiredTotal) / 4))
        }

        let actualPayment = min(max(0, targetPayment), min(availableCapacity, finance.totalNonHousingDebt))
        finance.annualDebtPayments = actualPayment
        finance.annualTotalExpenses += actualPayment

        var remainingPayment = actualPayment
        remainingPayment = payDown(&finance.creditDebt, with: remainingPayment)
        remainingPayment = payDown(&finance.medicalDebt, with: remainingPayment)
        _ = payDown(&finance.studentDebt, with: remainingPayment)

        let unpaidRequired = max(0, requiredTotal - actualPayment)
        if unpaidRequired > 0 {
            let lateFee = max(250, unpaidRequired / 6)
            if finance.creditDebt > 0 || strategy == .deferStudentLoans {
                let creditShare = Int((Double(lateFee) * 0.65).rounded())
                finance.creditDebt += creditShare
                finance.medicalDebt += (lateFee - creditShare)
            } else {
                finance.studentDebt += lateFee
            }
            finance.debtDelinquencyRisk = (finance.debtDelinquencyRisk + min(22, unpaidRequired / 220)).clamped(to: 0...100)
            finance.financialStress = (finance.financialStress + min(10, unpaidRequired / 350)).clamped(to: 0...100)
            result.notes.append(
                DomainNote(
                    title: "Debt Pressure",
                    text: "You could not cover the required debt payments this year, so the balances stayed sharp and the risk got worse.",
                    tags: [.finance]
                )
            )
        } else {
            finance.debtDelinquencyRisk = max(0, finance.debtDelinquencyRisk - 8)
        }

        refreshDebtState(for: &finance)

        switch finance.debtPressureBand {
        case .clear:
            break
        case .manageable:
            result.notes.append(DomainNote(title: "Debt Load", text: "Debt is present, but still contained enough that it has not taken over the whole year.", tags: [.finance]))
        case .heavy:
            result.healthEffects = HealthEffects(physical: nil, mental: -2, exercise: nil, nutrition: nil, stressManagement: -2, addCondition: nil, removeCondition: nil, hasPrimaryCare: nil)
            result.relationshipEffects = RelationshipEffects(meetNewFriend: nil, friendChange: -1, startDating: nil, partnerChange: -1, loseFriend: nil, breakup: nil)
            result.notes.append(DomainNote(title: "Heavy Debt", text: "The debt is now shaping housing, relationships, and what kinds of risks you can afford to take.", tags: [.finance, .relationships]))
        case .crushing:
            result.healthEffects = HealthEffects(physical: nil, mental: -4, exercise: nil, nutrition: nil, stressManagement: -4, addCondition: nil, removeCondition: nil, hasPrimaryCare: nil)
            result.relationshipEffects = RelationshipEffects(meetNewFriend: nil, friendChange: -2, startDating: nil, partnerChange: -2, loseFriend: nil, breakup: nil)
            result.careerEffects = CareerEffects(burnout: 4, schedulePressure: 2, jobSecurity: -2)
            result.notes.append(DomainNote(title: "Crushing Debt", text: "Debt is no longer background pressure. It is actively rearranging what your adult life can hold.", tags: [.finance, .health, .relationships]))
        }

        finance.debtStrategy = .standard
        return result
    }

    private func absorbDebtBackstop(
        context: FinanceYearContext,
        finance: inout FinanceState
    ) -> DomainYearResult {
        var result = DomainYearResult()
        guard context.age >= 18, finance.cashOnHand < 0 else { return result }

        let shortfall = abs(finance.cashOnHand)
        var medicalShare = 0
        if context.activeConditionCount > 0 {
            medicalShare = context.hasPrimaryCare ? shortfall / 3 : shortfall / 2
        }
        medicalShare = medicalShare.clamped(to: 0...shortfall)
        let creditShare = shortfall - medicalShare

        finance.medicalDebt += medicalShare
        finance.creditDebt += creditShare
        finance.cashOnHand = 0
        finance.debtDelinquencyRisk = (finance.debtDelinquencyRisk + min(18, shortfall / 280)).clamped(to: 0...100)
        refreshDebtState(for: &finance)

        let title = medicalShare > 0 ? "Debt Rollover" : "Credit Rollover"
        let text = medicalShare > 0
            ? "You could not carry the year in cash, so part of the shortfall hardened into medical debt and the rest into revolving debt."
            : "You could not carry the year in cash, so the shortfall rolled into revolving debt instead of disappearing."
        result.notes.append(DomainNote(title: title, text: text, tags: [.finance, .health]))
        return result
    }

    private func refreshDebtState(for finance: inout FinanceState) {
        let band = resolvedDebtPressureBand(for: finance)
        finance.debtPressureBand = band
        if finance.totalNonHousingDebt == 0 {
            finance.debtDelinquencyRisk = 0
        } else if band == .clear {
            finance.debtPressureBand = .manageable
        }
    }

    private func resolvedDebtPressureBand(for finance: FinanceState) -> DebtPressureBand {
        guard finance.totalNonHousingDebt > 0 else { return .clear }

        var score = finance.debtToIncomeBurden
        score += min(24, finance.totalNonHousingDebt / 4_000)
        score += finance.debtDelinquencyRisk / 4
        if finance.cashOnHand < 0 { score += 12 }
        if finance.lastYearBalanceDelta < 0 { score += 8 }

        switch score {
        case ..<24:
            return .manageable
        case ..<52:
            return .heavy
        default:
            return .crushing
        }
    }

    private func accruedInterest(for balance: Int, ratePercent: Int) -> Int {
        guard balance > 0 else { return 0 }
        return Int((Double(balance) * Double(ratePercent) / 100.0).rounded())
    }

    private func requiredPayment(for balance: Int, minimum: Int, ratePercent: Int) -> Int {
        guard balance > 0 else { return 0 }
        return max(minimum, Int((Double(balance) * Double(ratePercent) / 100.0).rounded()))
    }

    private func payDown(_ balance: inout Int, with payment: Int) -> Int {
        guard payment > 0, balance > 0 else { return payment }
        let applied = min(balance, payment)
        balance -= applied
        return payment - applied
    }

    private func mergeDebtResult(_ source: DomainYearResult, into target: inout DomainYearResult) {
        target.notes.append(contentsOf: source.notes)
        if let core = source.coreEffects { target.coreEffects = core }
        if let career = source.careerEffects { target.careerEffects = career }
        if let health = source.healthEffects { target.healthEffects = health }
        if let relationships = source.relationshipEffects { target.relationshipEffects = relationships }
    }

    private func resolvedSetback(for context: FinanceYearContext, finance: FinanceState) -> (cost: Int, note: DomainNote?) {
        guard context.age >= 18 else { return (0, nil) }

        let baseSeed =
            (context.age * 31) +
            (finance.consecutiveDeficitYears * 17) +
            (finance.financialStress * 7) +
            (context.childCount * 13) +
            (context.infantCount * 19) +
            (context.activeConditionCount * 23) +
            (context.ownsHome ? 29 : 0) +
            max(0, context.grossIncome / 1_000)
        let roll = abs(baseSeed) % 100

        if context.ownsHome, roll < min(26, 8 + finance.financialStress / 6) {
            let cost = (1_600 + max(0, finance.homeEquity / 60)).clamped(to: 1_600...7_800)
            return (
                cost,
                DomainNote(
                    title: "Housing Shock",
                    text: "Owning the place came with a real bill this year, and the repair hit before the rest of life was ready for it.",
                    tags: [.finance, .housing]
                )
            )
        }

        if (context.activeConditionCount > 0 || (!context.hasPrimaryCare && context.age >= 30)),
           roll < min(24, 4 + context.activeConditionCount * 6 + (context.hasPrimaryCare ? 0 : 5)) {
            let cost = (1_200 + context.activeConditionCount * 900 + max(0, context.age - 25) * 45).clamped(to: 1_200...9_500)
            return (
                cost,
                DomainNote(
                    title: "Health Bill",
                    text: "Health costs landed hard this year and turned a manageable budget into a more fragile one.",
                    tags: [.finance, .health]
                )
            )
        }

        if (context.hasCohabitingPartner || context.hasSpouse || context.childCount > 0 || context.infantCount > 0),
           finance.financialStress >= 34,
           roll < min(24, 6 + context.childCount * 4 + context.infantCount * 5 + finance.financialStress / 12) {
            let cost = (1_400 + context.childCount * 700 + context.infantCount * 1_100).clamped(to: 1_400...8_400)
            return (
                cost,
                DomainNote(
                    title: "Household Shock",
                    text: "Family logistics and shared-life obligations cost more than usual this year, squeezing the margin you thought you had.",
                    tags: [.finance, .relationships]
                )
            )
        }

        if context.careerStatus != .unemployed,
           finance.financialStress >= 45,
           roll < min(22, 5 + finance.consecutiveDeficitYears * 5 + finance.financialStress / 10) {
            let cost = max(1_500, context.grossIncome / 14)
            return (
                cost.clamped(to: 1_500...9_000),
                DomainNote(
                    title: "Income Shock",
                    text: "Work did not fully collapse, but the year still took an income hit through reduced hours, stalled momentum, or instability.",
                    tags: [.finance, .career]
                )
            )
        }

        return (0, nil)
    }

    private func stressSideEffects(for finance: FinanceState) -> DomainYearResult {
        var result = DomainYearResult()

        if finance.financialStress >= 82 {
            result.coreEffects = CoreStatEffects(happiness: -6)
            result.healthEffects = HealthEffects(physical: nil, mental: -7, exercise: nil, nutrition: nil, stressManagement: nil, addCondition: nil, removeCondition: nil, hasPrimaryCare: nil)
            result.relationshipEffects = RelationshipEffects(meetNewFriend: nil, friendChange: -4, startDating: nil, partnerChange: nil, loseFriend: nil, breakup: nil)
        } else if finance.financialStress >= 58 {
            result.coreEffects = CoreStatEffects(happiness: -4)
            result.healthEffects = HealthEffects(physical: nil, mental: -4, exercise: nil, nutrition: nil, stressManagement: nil, addCondition: nil, removeCondition: nil, hasPrimaryCare: nil)
            result.relationshipEffects = RelationshipEffects(meetNewFriend: nil, friendChange: -2, startDating: nil, partnerChange: nil, loseFriend: nil, breakup: nil)
        } else if finance.financialStress >= 42 {
            result.coreEffects = CoreStatEffects(happiness: -2)
            result.healthEffects = HealthEffects(physical: nil, mental: -2, exercise: nil, nutrition: nil, stressManagement: nil, addCondition: nil, removeCondition: nil, hasPrimaryCare: nil)
        } else if finance.lastYearBalanceDelta > 0 {
            result.coreEffects = CoreStatEffects(happiness: 1)
        }

        return result
    }
}

struct InvestmentSystem {
    let emergencyReserve: Int
    let sellFeeRatePercent: Int
    let indexRoll: (ClosedRange<Int>) -> Int
    let stockRoll: (ClosedRange<Int>) -> Int
    let balanceProfile: SimulationBalanceProfile

    init(
        emergencyReserve: Int = SimulationBalanceProfile.playableRealismV1.wealth.compoundingEmergencyReserve,
        sellFeeRatePercent: Int = 5,
        balanceProfile: SimulationBalanceProfile = .playableRealismV1,
        indexRoll: @escaping (ClosedRange<Int>) -> Int = { Int.random(in: $0) },
        stockRoll: @escaping (ClosedRange<Int>) -> Int = { Int.random(in: $0) }
    ) {
        self.emergencyReserve = emergencyReserve
        self.sellFeeRatePercent = sellFeeRatePercent
        self.balanceProfile = balanceProfile
        self.indexRoll = indexRoll
        self.stockRoll = stockRoll
    }

    func isInvestmentAction(_ choiceID: ActionChoiceID?) -> Bool {
        switch choiceID {
        case .buildEmergencyFund, .buyIndexFund, .speculateStocks, .holdPositions, .sellToCover:
            return true
        default:
            return false
        }
    }

    func canAccessInvestments(input: InvestmentDomainSnapshot) -> Bool {
        input.player.age >= 18 && (
            input.finance.hasInvestments ||
            input.finance.isEligibleToCompound(emergencyReserve: emergencyReserve, profile: balanceProfile)
        )
    }

    func advanceYear(
        input: InvestmentDomainSnapshot,
        plannedAction: ActionChoiceID?,
        finance: inout FinanceState
    ) -> DomainYearResult {
        var result = DomainYearResult()
        let previousTotalWealth = finance.totalWealth
        finance.normalizeInvestmentBalances()
        finance.lastYearInvestmentDelta = 0

        guard input.player.age >= 18 else {
            finance.investmentRiskProfile = .defensive
            return result
        }

        let availableCash = max(0, finance.cashOnHand - emergencyReserve)
        let isStable = finance.isEligibleToCompound(emergencyReserve: emergencyReserve, profile: balanceProfile)
        let action = isInvestmentAction(plannedAction) ? plannedAction : nil

        switch action {
        case .buyIndexFund:
            guard isStable, availableCash >= 1_500 else {
                result.notes.append(DomainNote(title: "Investing", text: "You looked at index investing, but your cash reserve was still too thin to commit safely.", tags: [.finance]))
                finance.investmentRiskProfile = resolvedRiskProfile(for: finance, fallback: .defensive)
                return result
            }
            let contribution = min(max(1_200, finance.lastYearBalanceDelta / 4), max(0, availableCash / 3))
            if contribution > 0 {
                finance.cashOnHand -= contribution
                finance.indexFundBalance += contribution
                finance.costBasis += contribution
                finance.investmentRiskProfile = .conservative
                result.notes.append(DomainNote(title: "Investing", text: "You moved some surplus into index funds, trading easy cash access for slower compounding.", tags: [.finance]))
            }
        case .speculateStocks:
            guard finance.stabilityStreakYears >= 4, isStable, availableCash >= 5_000 else {
                result.notes.append(DomainNote(title: "Investing", text: "You wanted to speculate, but the year never got stable enough to risk real money.", tags: [.finance]))
                finance.investmentRiskProfile = resolvedRiskProfile(for: finance, fallback: .defensive)
                return result
            }
            let contributionCap = input.player.traits.contains(.impulsive) ? availableCash / 3 : availableCash / 5
            let contribution = min(max(1_500, finance.lastYearBalanceDelta / 5), max(0, contributionCap))
            if contribution > 0 {
                finance.cashOnHand -= contribution
                finance.stockPortfolioBalance += contribution
                finance.costBasis += contribution
                finance.investmentRiskProfile = .speculative
                result.notes.append(DomainNote(title: "Investing", text: "You took a stock-market swing this year. The upside is real, and so is the risk.", tags: [.finance]))
            }
        case .sellToCover:
            let shortfall = max(0, emergencyReserve - finance.cashOnHand) + max(0, -finance.lastYearBalanceDelta)
            if finance.hasInvestments {
                let targetSale = max(1_500, shortfall)
                let sold = sellInvestments(targetGross: targetSale, finance: &finance)
                if sold.gross > 0 {
                    finance.lastYearInvestmentDelta -= sold.fee
                    finance.financialStress = (finance.financialStress + min(6, sold.fee / 250)).clamped(to: 0...100)
                    result.notes.append(DomainNote(title: "Investing", text: "You sold part of the portfolio to rebuild cash, sacrificing some future upside to protect the floor under the year.", tags: [.finance]))
                }
            }
            finance.investmentRiskProfile = resolvedRiskProfile(for: finance, fallback: .defensive)
        case .buildEmergencyFund:
            finance.investmentRiskProfile = .defensive
            if finance.hasInvestments {
                result.notes.append(DomainNote(title: "Investing", text: "You left investing alone and focused on keeping your emergency buffer solid.", tags: [.finance]))
            }
        case .holdPositions:
            finance.investmentRiskProfile = resolvedRiskProfile(for: finance, fallback: .balanced)
        default:
            finance.investmentRiskProfile = resolvedRiskProfile(for: finance, fallback: .defensive)
        }

        let indexDelta = applyReturn(ratePercent: indexReturnRate(for: input.player.traits), to: &finance.indexFundBalance)
        let stockDelta = applyReturn(ratePercent: stockReturnRate(for: input.player.traits, plannedAction: action), to: &finance.stockPortfolioBalance)
        finance.lastYearInvestmentDelta += indexDelta + stockDelta
        finance.normalizeInvestmentBalances()

        if finance.lastYearInvestmentDelta < 0 {
            finance.financialStress = (finance.financialStress + min(8, abs(finance.lastYearInvestmentDelta) / 1_200)).clamped(to: 0...100)
            if abs(finance.lastYearInvestmentDelta) >= 1_200 {
                result.notes.append(DomainNote(title: "Market Loss", text: "Your investments took a real hit this year, reminding you that compounding cuts both ways.", tags: [.finance]))
            }
        } else if finance.lastYearInvestmentDelta > 0 {
            finance.financialStress = (finance.financialStress - min(3, finance.lastYearInvestmentDelta / 2_500)).clamped(to: 0...100)
            if finance.lastYearInvestmentDelta >= 1_200 {
                result.notes.append(DomainNote(title: "Market Gain", text: "Your investments compounded upward this year and gave your long-term money some real traction.", tags: [.finance]))
            }
        }

        if !finance.hasInvestments {
            finance.investmentRiskProfile = .defensive
        } else {
            finance.investmentRiskProfile = resolvedRiskProfile(for: finance, fallback: finance.investmentRiskProfile)
        }
        finance.accumulateWealthDelta(from: previousTotalWealth)

        return result
    }

    private func sellInvestments(targetGross: Int, finance: inout FinanceState) -> (gross: Int, fee: Int) {
        finance.normalizeInvestmentBalances()
        guard targetGross > 0, finance.investedBalance > 0 else { return (0, 0) }

        let gross = min(targetGross, finance.investedBalance)
        let totalBefore = finance.investedBalance
        var indexSold = Int((Double(finance.indexFundBalance) / Double(totalBefore) * Double(gross)).rounded())
        indexSold = min(indexSold, finance.indexFundBalance)
        var stockSold = gross - indexSold
        stockSold = min(stockSold, finance.stockPortfolioBalance)

        if indexSold + stockSold < gross {
            let remainder = gross - indexSold - stockSold
            if finance.stockPortfolioBalance - stockSold >= remainder {
                stockSold += remainder
            } else {
                indexSold += remainder
            }
        }

        finance.indexFundBalance -= indexSold
        finance.stockPortfolioBalance -= stockSold

        let basisReduction = totalBefore > 0 ? Int((Double(finance.costBasis) * Double(gross) / Double(totalBefore)).rounded()) : 0
        finance.costBasis = max(0, finance.costBasis - basisReduction)

        let fee = gross * sellFeeRatePercent / 100
        finance.cashOnHand += gross - fee
        finance.normalizeInvestmentBalances()
        return (gross, fee)
    }

    private func applyReturn(ratePercent: Int, to balance: inout Int) -> Int {
        guard balance > 0 else { return 0 }
        let delta = Int((Double(balance) * Double(ratePercent) / 100.0).rounded())
        balance = max(0, balance + delta)
        return delta
    }

    private func indexReturnRate(for traits: [PersonalityTrait]) -> Int {
        var rate = 4 + indexRoll(-6...7)
        if traits.contains(.lucky) { rate += 2 }
        if traits.contains(.anxious) { rate -= 1 }
        return rate.clamped(to: -6...11)
    }

    private func stockReturnRate(for traits: [PersonalityTrait], plannedAction: ActionChoiceID?) -> Int {
        var low = -24
        var high = 20
        if traits.contains(.lucky) {
            low += 2
            high += 4
        }
        if traits.contains(.impulsive) {
            low -= 4
            high += 5
        }
        if plannedAction == .speculateStocks {
            low -= 3
            high += 3
        }
        let rate = 3 + stockRoll(low...high)
        return rate.clamped(to: -30...24)
    }

    private func resolvedRiskProfile(for finance: FinanceState, fallback: InvestmentRiskProfile) -> InvestmentRiskProfile {
        if finance.stockPortfolioBalance > finance.indexFundBalance && finance.stockPortfolioBalance > 0 {
            return .speculative
        }
        if finance.stockPortfolioBalance > 0 && finance.indexFundBalance > 0 {
            return .balanced
        }
        if finance.indexFundBalance > 0 {
            return .conservative
        }
        return fallback
    }
}
