import Foundation

struct DomainActionContext: Equatable {
    let state: GameState
    let isTeenExperience: Bool
    let isStudentLifeExperience: Bool
    let canAccessInvesting: Bool
    let investmentEmergencyReserve: Int
}

struct SuggestedPlayerAction: Codable, Equatable {
    var domain: ActionDomain
    var choiceID: ActionChoiceID
    var headline: String
}

struct FinanceActionSection: Identifiable, Equatable {
    let id: String
    let title: String
    let choices: [ActionChoiceID]
}

struct DomainActionRegistry {
    let context: DomainActionContext

    private var state: GameState { context.state }

    // MARK: - Public API

    func availableCommitted(for domain: ActionDomain) -> [ActionChoiceID] {
        switch domain {
        case .education: return educationCommittedChoices()
        case .career: return careerCommittedChoices()
        case .military: return militaryCommittedChoices()
        case .crime: return crimeCommittedChoices()
        case .finance: return financeCommittedChoices()
        case .relationships: return relationshipCommittedChoices()
        case .health: return healthCommittedChoices()
        case .family: return familyPhaseCommittedChoices()
        case .identity: return []
        }
    }

    private func militaryCommittedChoices() -> [ActionChoiceID] {
        guard state.player.age >= 18 else { return [] }
        
        var choices: [ActionChoiceID] = []

        if state.military.track == .inactive {
            choices.append(contentsOf: [
                .enlistArmy, .enlistNavy, .enlistAirForce, .enlistMarines, .enlistCoastGuard, .enlistSpaceForce
            ])
            if state.education.credentials.contains("Degree") {
                choices.append(contentsOf: [
                    .commissionArmy, .commissionNavy, .commissionAirForce, .commissionMarines, .commissionCoastGuard, .commissionSpaceForce
                ])
            }
            choices.append(contentsOf: [
                .joinReservesArmy, .joinReservesNavy, .joinReservesAirForce, .joinReservesMarines, .joinReservesCoastGuard, .joinReservesSpaceForce
            ])
            
            if state.military.hasPension {
                choices.append(.claimPension)
            }
            if state.military.isVeteran && state.military.combatTrauma > 0 {
                choices.append(.seekVAHealthcare)
            }
            return choices
        } else {
            choices.append(contentsOf: [.militaryService, .goAWOL, .desert, .militaryRetirement, .deployTour])
            
            if state.military.specialty == nil {
                choices.append(contentsOf: [.selectCombatMOS, .selectMedicalMOS, .selectAviationMOS, .selectIntelMOS, .selectLogisticsMOS])
            }
            
            if state.military.deploymentStatus == .home || state.military.deploymentStatus == .stationed {
                choices.append(.deploy)
            }
            if state.military.combatTrauma > 0 {
                choices.append(.seekVAHealthcare)
            }
            // D1 static military instants also appear in committed for the subdomain
            choices.append(contentsOf: [.ptFocus, .seekCounsel, .studyTradition])
            return choices
        }
    }

    func isStaticCoreInstantAction(_ choiceID: ActionChoiceID, domain: ActionDomain) -> Bool {
        staticCoreInstantActions(for: domain).contains(choiceID)
    }

    func availableQuick(for domain: ActionDomain) -> [ActionChoiceID] {
        let committed = Set(availableCommitted(for: domain))
        // Always start with the static core for this domain/subdomain so they are reliably present
        // in the "Right Now" instant grids and can always be clicked for instant calc.
        var quick = staticCoreInstantActions(for: domain).filter {
            committed.contains($0) || resolutionTier(for: $0, domain: domain) == .instant
        }
        for choice in availableInstantPromotions(for: domain) {
            guard committed.contains(choice) || resolutionTier(for: choice, domain: domain) == .instant else { continue }
            if !quick.contains(choice) { quick.append(choice) }
        }
        if domain == .finance, state.finance.debtPressureBand == .crushing || state.finance.debtPressureBand == .heavy {
            for debtQuick in [ActionChoiceID.minimumPayments, .consolidateDebt, .payDownDebt] where committed.contains(debtQuick) {
                if !quick.contains(debtQuick) { quick.insert(debtQuick, at: 0) }
            }
        }
        return Array(quick.prefix(8))  // give a bit more room for static + extras
    }

    func resolutionTier(for choiceID: ActionChoiceID, domain: ActionDomain) -> ActionResolutionTier {
        if contextualInstantChoices(for: domain).contains(choiceID) {
            return .instant
        }
        return ActionChoiceCatalog.baseResolutionTier(for: choiceID)
    }

    func suggestedChoice(for domain: ActionDomain) -> ActionChoiceID? {
        switch domain {
        case .education:
            if state.education.burnoutRisk >= 55 || state.healthProfile.mentalWellness < 45 { return .keepThePeace }
            if state.education.applicationReadiness >= 60 { return .buildPortfolio }
            if state.relationships.friends.isEmpty { return .joinClub }
            return .studyConsistently
        case .career:
            if state.career.status == .unemployed { return .jobHunt }
            if state.career.activeOpportunityDoor == .burnoutExit { return .protectYourEnergy }
            if state.career.activeOpportunityDoor == .credentialPivot { return .retrain }
            if state.career.activeOpportunityDoor == .lateralEscapeRoute { return .jobHunt }
            if state.career.activeOpportunityDoor == .internalPromotionTrack { return .network }
            if state.career.activeOpportunityDoor == .contractWindfall { return .takeOvertime }
            if state.career.burnout >= 68 || state.career.relationshipSpillover >= 58 { return .protectYourEnergy }
            if state.specialCareer.track == .recordLabelOwner {
                if state.specialCareer.recordLabel.artistTrust < 40 || state.specialCareer.recordLabel.industryHeat >= 55 { return .handleArtistDrama }
                if state.specialCareer.recordLabel.roster.count < 3 { return .signArtist }
                return .releaseRecord
            }
            if state.specialCareer.track == .movieProducer {
                if state.specialCareer.movieProducer.productionChaos >= 55 { return .handleProductionCrisis }
                if state.specialCareer.movieProducer.slateCount == 0 { return .optionScript }
                if state.specialCareer.movieProducer.distributionLeverage >= 45 { return .secureDistribution }
                return .shootFilm
            }
            if state.specialCareer.track == .movieActor {
                if state.specialCareer.movieActor.typecastRisk >= 55 || state.specialCareer.heat >= 45 { return .managePublicist }
                if state.specialCareer.movieActor.actingSkill < 55 { return .actingClass }
                return .auditionRole
            }
            if state.specialCareer.track == .coach {
                if state.specialCareer.coaching.boosterPressure >= 60 { return .handleBoosterPressure }
                if state.specialCareer.coaching.lockerRoom < 45 { return .manageLockerRoom }
                if state.specialCareer.coaching.rosterTalent < 55 { return .recruitTalent }
                return .callBigGame
            }
            if state.specialCareer.track == .musicProducer {
                if state.specialCareer.musicProducer.creditDisputes >= 45 { return .manageProducerCredits }
                if state.specialCareer.musicProducer.demand < 45 { return .shopBeats }
                return .produceTrack
            }
            if state.career.performance < 55 { return .workHard }
            if state.career.retrainingProgress == 0 && state.career.profile != .credentialedProfessional && state.career.yearsWorked >= 2 { return .retrain }
            if state.specialCareer.track == .entertainment && state.specialCareer.burnout < 70 { return .chaseSpotlight }
            if state.career.performance >= 74 { return .network }
            return .coast
        case .military:
            if state.military.track == .inactive { return .enlistArmy }
            if state.military.isAWOL { return .desert }
            if state.military.deploymentStatus == .activeCombat { return .militaryService }
            if state.military.contractYearsRemaining == 0 { return .militaryRetirement }
            return .militaryService
        case .crime:
            if state.crime.heat >= 65 { return .layLow }
            if state.finance.cashOnHand < 0 { return .cleanMoney }
            return .runScheme
        case .finance:
            if context.isStudentLifeExperience {
                if state.finance.studentDebt > 0 && state.finance.debtPressureBand == .heavy { return .deferStudentLoans }
                return state.finance.financialStress >= 40 ? .cutSpending : .takeExtraShifts
            }
            if state.finance.canUseDebtReset { return .declareBankruptcy }
            if state.finance.debtPressureBand == .crushing { return .consolidateDebt }
            if state.finance.debtPressureBand == .heavy { return .minimumPayments }
            if state.assets.ownsHome && state.assets.primaryResidence?.status == .delinquent { return .refinanceMortgage }
            if state.finance.lastYearBalanceDelta < 0 || state.finance.cashOnHand < 0 { return .cutSpending }
            if context.canAccessInvesting && !state.finance.hasInvestments { return .buyIndexFund }
            if state.assets.isSavingForHome || state.finance.homeDownPaymentSavings > 0 { return .saveForDownPayment }
            return context.canAccessInvesting ? .buildEmergencyFund : .takeSideWork
        case .relationships:
            let strained = (state.relationships.friends + state.relationships.romanticPartners).filter { $0.status == .strained }.count
            if strained > 0 { return .repairTension }
            if context.isTeenExperience && state.relationships.friends.isEmpty && !state.relationships.hasPartner { return .findYourCrowd }
            if state.relationships.hasPartner { return .strengthenBond }
            return .reachOut
        case .health:
            if !state.healthProfile.activeConditions.isEmpty { return context.isStudentLifeExperience ? .rest : .seeDoctor }
            if state.healthProfile.mentalWellness < 45 { return context.isStudentLifeExperience ? .protectSleep : .rest }
            return .rest
        case .family:
            return .spendTimeWithKids
        case .identity:
            return nil
        }
    }

    func isCrimeLaneActive() -> Bool {
        state.player.age >= 18 && (
            state.crime.status != .inactive ||
            state.pendingActions.contains(where: { $0.domain == .crime }) ||
            state.finance.cashOnHand < 600 ||
            state.specialCareer.track == .crime
        )
    }

    func financeActionSections() -> [FinanceActionSection] {
        let choices = financeCommittedChoices()
        var cash: [ActionChoiceID] = []
        var debt: [ActionChoiceID] = []
        var invest: [ActionChoiceID] = []
        var home: [ActionChoiceID] = []

        let debtIDs: Set<ActionChoiceID> = [.payDownDebt, .consolidateDebt, .minimumPayments, .deferStudentLoans, .declareBankruptcy]
        let investIDs: Set<ActionChoiceID> = [.buildEmergencyFund, .buyIndexFund, .speculateStocks, .holdPositions, .sellToCover, .dayTrade, .analyzeMarkets, .checkPortfolio, .rebalancePortfolio, .researchTip, .buyIndex, .sellPosition]
        let homeIDs: Set<ActionChoiceID> = [.saveForDownPayment, .depositToHouseFund, .buyStarterHome, .refinanceMortgage, .buildMaintenanceReserve, .topUpHouseReserve, .sellHome]
        // Econ4: New era-aware economic actions
        let econEraIDs: Set<ActionChoiceID> = [.panicSell, .aggressiveSideHustle, .bigLifestylePurchase, .rideTheWave, .quietFinancialQuit, .flexLuxuryAsset, .liquidateLuxury, .upgradeCollection, .hostAtSignatureEstate]

        for choice in choices {
            if debtIDs.contains(choice) { debt.append(choice) }
            else if investIDs.contains(choice) { invest.append(choice) }
            else if homeIDs.contains(choice) { home.append(choice) }
            else if econEraIDs.contains(choice) { invest.append(choice) } // treat as high-stakes investment decisions
            else { cash.append(choice) }
        }

        var sections: [FinanceActionSection] = []
        if !cash.isEmpty { sections.append(FinanceActionSection(id: "cash", title: "Cash Flow", choices: cash)) }
        if !debt.isEmpty { sections.append(FinanceActionSection(id: "debt", title: "Debt", choices: debt)) }
        if !invest.isEmpty { sections.append(FinanceActionSection(id: "invest", title: "Invest", choices: invest)) }
        if !home.isEmpty { sections.append(FinanceActionSection(id: "home", title: "Home", choices: home)) }
        return sections
    }

    func familyPhaseIsActive() -> Bool {
        state.family.isPregnant || state.family.childCount > 0 || state.family.postpartumYearsRemaining > 0
    }

    func familyPhaseCommittedChoices() -> [ActionChoiceID] {
        guard familyPhaseIsActive() else { return [] }
        var choices: [ActionChoiceID] = [.strengthenBond, .repairTension, .discussFuture, .spendTimeWithKids, .enforceRoutine, .encourageIndependence, .checkInOnChild]
        if state.family.isPregnant {
            choices.append(contentsOf: [.avoidPregnancy, .tryForBaby])
        }
        if !state.healthProfile.activeConditions.isEmpty {
            choices.append(.seeDoctor)
        }
        let relationshipDeck = Set(availableCommitted(for: .relationships))
        return dedupe(choices.filter { relationshipDeck.contains($0) || $0 == .seeDoctor })
    }

    func familyPhaseQuickChoices() -> [ActionChoiceID] {
        guard familyPhaseIsActive() else { return [] }
        return dedupe([.protectSleep, .rest, .repairTension, .seeDoctor, .spendTimeWithKids, .checkInOnChild].filter {
            resolutionTier(for: $0, domain: .health) == .instant || resolutionTier(for: $0, domain: .relationships) == .instant
                || availableQuick(for: .health).contains($0) || availableQuick(for: .relationships).contains($0)
        })
    }

    /// NPC / pressure callback surfaced on Home (max one).
    func suggestedCallbackAction() -> SuggestedPlayerAction? {
        if let stored = state.suggestedPlayerAction,
           storedMatchesPlayable(stored) {
            return stored
        }
        return deriveSuggestedCallbackAction()
    }

    static func refreshSuggestedAction(in state: inout GameState, isTeenExperience: Bool) {
        let registry = DomainActionRegistry(
            context: DomainActionContext(
                state: state,
                isTeenExperience: isTeenExperience,
                isStudentLifeExperience: state.player.age <= 22 && (state.education.pathway == .student || state.education.pathway == .training),
                canAccessInvesting: state.player.age >= 18 && state.finance.isEligibleToCompound(emergencyReserve: max(2_500, state.finance.annualNetIncome / 4)),
                investmentEmergencyReserve: max(2_500, state.finance.annualNetIncome / 4)
            )
        )
        state.suggestedPlayerAction = registry.deriveSuggestedCallbackAction()
    }

    static func quickActionTitle(for choiceID: ActionChoiceID) -> String {
        switch choiceID {
        case .studyConsistently: return "Study"
        case .joinClub: return "Join Club"
        case .buildPortfolio: return "Build Portfolio"
        case .skipClass: return "Skip Class"
        case .lockInRoutine: return "Routine"
        case .teenAthleticDrill: return "Athletic Drill"
        case .teenSideHustle: return "Side Hustle"
        case .teenCreativeProject: return "Creative Project"
        case .teenLeadInitiative: return "Lead Initiative"
        case .teenRiskyExperiment: return "Risky Experiment"
        case .workHard: return "Work Hard"
        case .network: return "Network"
        case .jobHunt: return "Job Hunt"
        case .protectYourEnergy: return "Protect Energy"
        case .takeOvertime: return "Overtime"
        case .cutSpending: return "Budget"
        case .takeSideWork: return "Side Work"
        case .payDownDebt: return "Pay Debt"
        case .buildEmergencyFund: return "Emergency Fund"
        case .depositToHouseFund: return "House Fund"
        case .topUpHouseReserve: return "Repair Reserve"
        case .saveForDownPayment: return "Save For Home"
        case .buyStarterHome: return "Buy Home"
        case .refinanceMortgage: return "Refinance"
        case .buildMaintenanceReserve: return "Build Reserve"
        case .sellHome: return "Sell Home"
        case .panicSell: return "Panic Sell"
        case .aggressiveSideHustle: return "Aggressive Hustle"
        case .bigLifestylePurchase: return "Victory Lap Spend"
        case .rideTheWave: return "Ride The Wave"
        case .quietFinancialQuit: return "Quiet Financial Quit"
        case .flexLuxuryAsset: return "Flex Collection"
        case .liquidateLuxury: return "Liquidate Toys"
        case .upgradeCollection: return "Upgrade Fleet"
        case .hostAtSignatureEstate: return "Host at Estate"
        case .spendForRelief: return "Spend For Relief"
        case .reachOut: return "Reach Out"
        case .findYourCrowd: return "Find Friends"
        case .dateCarefully: return "Date"
        case .strengthenBond: return "Strengthen Bond"
        case .repairTension: return "Repair"
        case .rest: return "Rest"
        case .protectSleep: return "Sleep"
        case .pushThrough: return "Push Through"
        case .seeDoctor: return "Doctor"
        case .layLow: return "Lay Low"
        case .stepAway: return "Step Away"
        case .cleanMoney: return "Clean Money"
        case .ghostProtocol: return "Ghost Protocol"
        case .burnEvidence: return "Burn Evidence"
        case .payTheFixer: return "Pay The Fixer"
        case .launderThroughShell: return "Launder Shells"
        case .hostStrategicGala: return "Strategic Gala"
        case .aggressiveTakeover: return "Aggressive Takeover"
        case .analyzeMarkets: return "Markets"
        case .checkPortfolio: return "Portfolio"
        case .rebalancePortfolio: return "Rebalance"
        case .researchTip: return "Research"
        case .buyIndex: return "Buy Index"
        case .sellPosition: return "Sell Pos"
        case .holdPositions: return "Hold"
        case .minimumPayments: return "Min Pay"
        case .consolidateDebt: return "Consolidate"
        case .stayInvisible: return "Lay Low Social"
        case .chaseStatus: return "Chase Status"
        // S2 athlete static short titles for BitLife grid
        case .extraTrainingSession: return "Extra Session"
        case .recoveryFocus: return "Recover"
        case .mediaAppearance: return "Media Spot"
        case .teamBonding: return "Team Bond"
        case .edgeProtocol: return "Edge Protocol"
        // E2/C2/P2 short for static always grids when subdomain active
        case .closeMajorDeal: return "Close Deal"
        case .allHandsRally: return "All Hands"
        case .fundraiseSprint: return "Fundraise"
        case .takeRealBreak: return "Real Break"
        case .hireKeyTalent: return "Hire Talent"
        case .startMovieActor: return "Actor Track"
        case .auditionRole: return "Audition"
        case .actingClass: return "Class"
        case .buildActingReel: return "Reel"
        case .takeIndieRole: return "Indie Role"
        case .managePublicist: return "Publicist"
        case .startMusicProducer: return "Music Producer"
        case .produceTrack: return "Produce"
        case .runStudioSession: return "Session"
        case .shopBeats: return "Shop Beats"
        case .collaborateWithArtist: return "Collaborate"
        case .polishSignatureSound: return "Signature"
        case .manageProducerCredits: return "Credits"
        case .startMovieProducer: return "Movie Producer"
        case .optionScript: return "Script"
        case .castProject: return "Cast"
        case .shootFilm: return "Shoot Film"
        case .handleProductionCrisis: return "Crisis"
        case .secureDistribution: return "Distribution"
        case .manageBackEndPoints: return "Backend"
        case .startRecordLabel: return "Label"
        case .signArtist: return "Sign Artist"
        case .developArtist: return "Develop"
        case .releaseRecord: return "Release"
        case .bookTour: return "Book Tour"
        case .payArtists: return "Pay Artists"
        case .pushSingle: return "Push Single"
        case .handleArtistDrama: return "Drama"
        case .startCoachingCareer: return "Coach"
        case .recruitTalent: return "Recruit"
        case .hireCoachingStaff: return "Staff"
        case .installSystem: return "System"
        case .runTrainingCamp: return "Camp"
        case .manageLockerRoom: return "Locker Room"
        case .callBigGame: return "Big Game"
        case .handleBoosterPressure: return "Boosters"
        case .postDaily: return "Post Daily"
        case .goLive: return "Go Live"
        case .filmBanger: return "Film Banger"
        case .collab: return "Collab"
        case .addressDrama: return "Drama"
        case .takeMentalBreak: return "Log Off"
        case .dropBrandDeal: return "Brand Deal"
        case .townHall: return "Town Hall"
        case .politicalFundraise: return "Fundraise"
        case .scandalResponse: return "Scandal"
        case .policyPush: return "Policy Push"
        case .backroomDeal: return "Backroom"
        case .mediaHit: return "Media Hit"
        case .takeAStand: return "Take Stand"
        case .attackOpponent: return "Attack"
        // D1 short titles for static always grids
        case .morningReflection: return "Reflect"
        case .reconcileWithPast: return "Reconcile"
        case .tryNewPersona: return "New Persona"
        case .publicReset: return "Public Reset"
        case .therapySession: return "Therapy"
        case .processCrisis: return "Process Crisis"
        case .ptFocus: return "PT Focus"
        case .seekCounsel: return "Counsel"
        case .studyTradition: return "Tradition"
        case .deployTour: return "Deploy Tour"
        case .familyMeal: return "Family Meal"
        case .storyTime: return "Story Time"
        // D2 short titles for mastery/collector grids
        case .curateCollection: return "Curate"
        case .hostSignatureEvent: return "Host Signature"
        case .maintainAsset: return "Maintain"
        case .recurringTherapy: return "Therapy Loop"
        case .manageMeds: return "Meds Mgmt"
        case .bodyConditioning: return "Body Work"
        case .deepenSpecificBond: return "Deepen Bond"
        case .fuelRivalry: return "Fuel Rivalry"
        case .splitReputation: return "Split Rep"
        // D3 short titles
        case .pursueTradeCert: return "Trade Cert"
        case .honorsTrack: return "Honors"
        case .uniApplication: return "Uni Apply"
        case .lifelongLearning: return "Lifelong Learn"
        case .credentialRefresh: return "Refresh Cred"
        case .corporateClimb: return "Corp Climb"
        case .freelanceHustle: return "Freelance"
        case .tradesMastery: return "Trades Mastery"
        case .pivotToGig: return "Gig Pivot"
        case .publicServiceGrind: return "Public Grind"
        case .techDeepWork: return "Tech Deep"
        default: return ActionChoiceCatalog.definition(for: choiceID).title
        }
    }

    // MARK: - Instant tier

    private func contextualInstantChoices(for domain: ActionDomain) -> Set<ActionChoiceID> {
        var instant = Set<ActionChoiceID>()
        for choice in ActionChoiceID.allCases where ActionChoiceCatalog.baseResolutionTier(for: choice) == .instant {
            instant.insert(choice)
        }
        instant.formUnion(availableInstantPromotions(for: domain))
        return instant
    }

    private func availableInstantPromotions(for domain: ActionDomain) -> [ActionChoiceID] {
        switch domain {
        case .education:
            var choices: [ActionChoiceID] = [.studyConsistently, .joinClub, .lockInRoutine]
            if state.education.attendancePressure >= 50 || state.education.burnoutRisk >= 45 {
                choices.append(.layLow)
            }
            if context.isTeenExperience, let d = state.childhoodDossier {
                if d.aptitudes.physical >= 50 { choices.append(.teenAthleticDrill) }
                if d.aptitudes.creative >= 50 { choices.append(.teenCreativeProject) }
            }
            // D3: branch and lifelong statics promoted
            choices.append(contentsOf: [.pursueTradeCert, .honorsTrack, .uniApplication, .lifelongLearning, .credentialRefresh])
            return choices
        case .career:
            var choices: [ActionChoiceID] = [.protectYourEnergy, .network]
            if state.career.status == .unemployed { choices.insert(.jobHunt, at: 0) }
            // Promote special career dedicated static actions to instant tier when the subdomain is active.
            // These are the BitLife-style always-clickable taps for the deep path.
            if state.specialCareer.track == .athlete {
                choices.append(contentsOf: [.intenseTraining, .compete, .extraTrainingSession, .recoveryFocus, .mediaAppearance, .teamBonding, .edgeProtocol])
            } else if state.specialCareer.track == .founder {
                choices.append(contentsOf: [.pivotBusiness, .raiseCapital, .aggressiveExpansion, .allHandsRally, .fundraiseSprint, .takeRealBreak, .hireKeyTalent, .closeMajorDeal])
            } else if state.specialCareer.track == .contentCreator {
                choices.append(contentsOf: [.postDaily, .goLive, .filmBanger, .collab, .addressDrama, .takeMentalBreak, .dropBrandDeal])
            } else if state.specialCareer.track == .politics {
                choices.append(contentsOf: [.townHall, .politicalFundraise, .scandalResponse, .policyPush, .backroomDeal, .mediaHit, .takeAStand, .attackOpponent])
            } else if state.specialCareer.track == .crime || state.specialCareer.track == .shadowOperative || state.specialCareer.track == .trader || state.specialCareer.track == .ventureCapitalist || state.specialCareer.track == .corporateRaider {
                // Already covered in crime domain promotions, but surface here too for career tab when crime track
                choices.append(contentsOf: [.ghostProtocol, .burnEvidence, .payTheFixer, .launderThroughShell, .hostStrategicGala, .aggressiveTakeover])
            } else {
                // D3: regular (non-special) career archetype instants promoted to frictionless always-click
                choices.append(contentsOf: [.corporateClimb, .freelanceHustle, .tradesMastery, .pivotToGig, .publicServiceGrind, .techDeepWork])
            }
            return choices
        case .finance:
            var choices: [ActionChoiceID] = [.cutSpending, .takeSideWork, .spendForRelief]
            if state.player.age >= 18 && !state.assets.ownsHome {
                choices.insert(.depositToHouseFund, at: 0)
            }
            if state.assets.ownsHome {
                choices.insert(.topUpHouseReserve, at: 0)
            }
            if investmentsActive { choices.append(contentsOf: [.analyzeMarkets, .holdPositions]) }
            // D2 collector statics promoted to instant
            choices.append(contentsOf: [.curateCollection, .hostSignatureEvent, .maintainAsset])
            return choices
        case .relationships:
            var choices: [ActionChoiceID] = [.reachOut, .repairTension, .keepDistance]
            if context.isTeenExperience { choices.append(contentsOf: [.stayInvisible, .chaseStatus]) }
            // D2 rel depth statics
            choices.append(contentsOf: [.deepenSpecificBond, .fuelRivalry, .splitReputation])
            return choices
        case .health:
            var choices: [ActionChoiceID] = [.rest, .protectSleep, .seeDoctor]
            if state.career.burnout >= 58 || state.education.burnoutRisk >= 50 {
                choices.insert(.protectSleep, at: 0)
            }
            // D2 health mastery instants
            choices.append(contentsOf: [.recurringTherapy, .manageMeds, .bodyConditioning])
            return choices
        case .crime:
            var choices: [ActionChoiceID] = [.layLow, .cleanMoney, .ghostProtocol, .payTheFixer]
            if state.crime.heat >= 50 { choices.insert(.stepAway, at: 0) }
            if state.specialCareer.track == .shadowOperative || state.specialCareer.track == .crime {
                choices.append(.burnEvidence)
            }
            if state.specialCareer.track == .ventureCapitalist || state.specialCareer.track == .corporateRaider || state.specialCareer.track == .trader {
                choices.append(contentsOf: [.launderThroughShell, .hostStrategicGala, .aggressiveTakeover])
            }
            return choices
        case .military:
            return [.militaryService]
        case .family:
            return [.checkInOnChild]
        case .identity:
            // D1: Identity actions are always instant (cheap self-work)
            return [.morningReflection, .reconcileWithPast, .tryNewPersona, .publicReset, .therapySession, .processCrisis]
        case .military:
            // D1: New military statics promoted to instant when military subdomain active
            return [.militaryService, .ptFocus, .seekCounsel, .studyTradition]
        }
    }

    private var investmentsActive: Bool {
        state.player.age >= 18 && (
            state.finance.hasInvestments ||
            (state.finance.lastYearBalanceDelta >= 0 && state.finance.cashOnHand >= 6_000)
        )
    }

    // MARK: - Quick catalog

    // Static core instant actions for domains and subdomains.
    // These are the reliable, always-present "BitLife-style" quick taps that instantly calculate
    // and can always be clicked (bypass normal quick memory limits for core feel).
    // Subdomains (teen education, special career tracks, crime lane, etc.) get their dedicated static set.
    private func staticCoreInstantActions(for domain: ActionDomain) -> [ActionChoiceID] {
        switch domain {
        case .education:
            if context.isTeenExperience {
                var core: [ActionChoiceID] = [.studyConsistently, .joinClub, .buildPortfolio, .lockInRoutine, .layLow]
                if let d = state.childhoodDossier {
                    if d.aptitudes.physical >= 50 { core.append(.teenAthleticDrill) }
                    if d.aptitudes.entrepreneurial >= 50 { core.append(.teenSideHustle) }
                    if d.aptitudes.creative >= 50 { core.append(.teenCreativeProject) }
                    if d.aptitudes.social >= 50 { core.append(.teenLeadInitiative) }
                    if d.aptitudes.entrepreneurial >= 55 || d.aptitudes.physical >= 55 { core.append(.teenRiskyExperiment) }
                }
                return core
            }
            if context.isStudentLifeExperience {
                return [.studyConsistently, .joinClub, .buildPortfolio, .lockInRoutine, .cramAndSurvive]
            }
            // D3: education statics now include branch choices for trade/uni/honors and lifelong
            var eduCore: [ActionChoiceID] = [.studyConsistently, .joinClub, .buildPortfolio, .lockInRoutine]
            eduCore.append(contentsOf: [.pursueTradeCert, .honorsTrack, .uniApplication, .lifelongLearning, .credentialRefresh])
            return eduCore
        case .career:
            var core: [ActionChoiceID] = [.workHard, .network, .protectYourEnergy, .takeOvertime]
            if state.career.status == .unemployed || state.career.status == .partTime {
                core.insert(.jobHunt, at: 0)
            }
            // Subdomain statics when special career active (always clickable instant for that path)
            if state.specialCareer.track == .athlete {
                core.append(contentsOf: [.intenseTraining, .compete, .extraTrainingSession, .recoveryFocus, .mediaAppearance, .teamBonding])
            } else if state.specialCareer.track == .founder {
                core.append(contentsOf: [.pivotBusiness, .raiseCapital, .aggressiveExpansion, .allHandsRally, .fundraiseSprint, .takeRealBreak, .hireKeyTalent])
            } else if state.specialCareer.track == .contentCreator {
                core.append(contentsOf: [.postDaily, .goLive, .filmBanger, .collab, .addressDrama, .takeMentalBreak, .dropBrandDeal])
            } else if state.specialCareer.track == .politics {
                core.append(contentsOf: [.townHall, .workHard, .chaseSpotlight, .reachOut])
            } else {
                // D3: regular career archetype statics for parity (6 archetypes)
                core.append(contentsOf: [.corporateClimb, .freelanceHustle, .tradesMastery, .pivotToGig, .publicServiceGrind, .techDeepWork])
            }
            return core
        case .finance:
            var core: [ActionChoiceID] = [.cutSpending, .takeSideWork, .buildEmergencyFund, .spendForRelief]
            if state.player.age >= 18 && !state.assets.ownsHome {
                core.insert(.depositToHouseFund, at: 0)
            }
            if state.assets.ownsHome {
                core.insert(.topUpHouseReserve, at: 0)
            }
            if state.finance.totalNonHousingDebt > 0 {
                core.append(.payDownDebt)
            }
            if investmentsActive {
                core.append(contentsOf: [.analyzeMarkets, .holdPositions, .checkPortfolio, .rebalancePortfolio, .researchTip, .buyIndex, .sellPosition])
            }
            // D2: Collector loops always available in money tab (path/era flavor in apply)
            core.append(contentsOf: [.curateCollection, .hostSignatureEvent, .maintainAsset])
            return core
        case .relationships:
            if state.relationships.hasPartner {
                var relCore: [ActionChoiceID] = [.reachOut, .strengthenBond, .repairTension, .dateCarefully, .discussFuture]
                // D2: per-friend deepen + rivalry statics always in people tab
                relCore.append(contentsOf: [.deepenSpecificBond, .fuelRivalry, .splitReputation])
                return relCore
            }
            var relCore: [ActionChoiceID] = [.reachOut, .findYourCrowd, .dateCarefully, .repairTension, .keepDistance]
            relCore.append(contentsOf: [.deepenSpecificBond, .fuelRivalry, .splitReputation])
            return relCore
        case .health:
            var healthCore: [ActionChoiceID] = [.rest, .protectSleep, .seeDoctor, .pushThrough, .protectYourEnergy]
            // D2: condition management + body conditioning statics
            healthCore.append(contentsOf: [.recurringTherapy, .manageMeds, .bodyConditioning])
            return healthCore
        case .crime:
            // Crime subdomain: these static actions are always the "Right Now" core for the risk lane
            return [.layLow, .stepAway, .cleanMoney, .runScheme, .ghostProtocol, .burnEvidence, .payTheFixer, .launderThroughShell, .hostStrategicGala, .aggressiveTakeover]
        case .military:
            // D1: Military static core now includes the new always-click instants
            return [.militaryService, .goAWOL, .deploy, .ptFocus, .seekCounsel, .studyTradition]
        case .family:
            // D1: Light family anchors are always in the quick core (even outside heavy phase)
            var f = familyPhaseQuickChoices()
            f.append(contentsOf: [.familyMeal, .storyTime])
            return dedupe(f)
        case .identity:
            // D1: Identity is always lightly available — self work is never "off"
            return [.morningReflection, .reconcileWithPast, .tryNewPersona, .publicReset, .therapySession, .processCrisis]
        }
    }

    private func baseQuickChoices(for domain: ActionDomain) -> [ActionChoiceID] {
        // Base is now the reliable static core for the domain/subdomain.
        // Always-present instant actions that you can always click.
        var choices = staticCoreInstantActions(for: domain)

        // Add light conditional extras on top (without duplicating)
        switch domain {
        case .education:
            if !context.isTeenExperience && !context.isStudentLifeExperience {
                if state.education.attendancePressure >= 50 || state.education.burnoutRisk >= 45 {
                    if !choices.contains(.layLow) { choices.append(.layLow) }
                }
            }
            return choices
        case .career:
            if state.career.status == .unemployed { 
                if !choices.contains(.jobHunt) { choices.insert(.jobHunt, at: 0) }
            }
            return choices
        case .finance:
            if state.finance.totalNonHousingDebt > 0 && !choices.contains(.payDownDebt) {
                choices.append(.payDownDebt)
            }
            return choices
        default:
            return choices
        }
    }

    // MARK: - Committed decks

    private func educationCommittedChoices() -> [ActionChoiceID] {
        if context.isTeenExperience {
            var choices: [ActionChoiceID] = [.studyConsistently, .cramAndSurvive, .joinClub, .buildPortfolio, .skipAndDrift, .keepThePeace]
            // Teen 2: dossier-aware precursors only appear if your childhood wiring matches (makes teen feel personalized to origin)
            if let d = state.childhoodDossier {
                if d.aptitudes.physical >= 50 { choices.append(.teenAthleticDrill) }
                if d.aptitudes.entrepreneurial >= 50 { choices.append(.teenSideHustle) }
                if d.aptitudes.creative >= 50 { choices.append(.teenCreativeProject) }
                if d.aptitudes.social >= 50 { choices.append(.teenLeadInitiative) }
                if d.aptitudes.entrepreneurial >= 55 || d.aptitudes.physical >= 55 { choices.append(.teenRiskyExperiment) }
            } else {
                // fallback: show a couple generically
                choices.append(contentsOf: [.teenAthleticDrill, .teenCreativeProject])
            }
            return choices
        }
        if context.isStudentLifeExperience {
            var choices: [ActionChoiceID] = [.studyConsistently, .cramAndSurvive, .buildPortfolio, .keepThePeace, .skipAndDrift, .lockInRoutine]
            if state.education.pathway != .rotc {
                choices.append(.joinROTC)
            } else {
                choices.append(.leaveROTC)
            }
            if state.military.isVeteran && !state.military.hasGIBill {
                choices.append(.useGIBill)
            }
            // D3: student committed branches (trade/honors/uni + lifelong always via static)
            choices.append(contentsOf: [.pursueTradeCert, .honorsTrack, .uniApplication, .lifelongLearning, .credentialRefresh])
            return choices
        }
        return [.studyHard, .layLow, .skipClass]
    }

    private func careerCommittedChoices() -> [ActionChoiceID] {
        if state.player.age < 16 { return [] }
        if state.military.track != .inactive && state.military.track != .reserve { return [] }
        
        var options: [ActionChoiceID] = []

        // Phase 5: Specialized Transitions
        if state.career.status == .unemployed || state.career.status == .partTime {
            if state.education.credentials.contains("MD") && state.career.specializedTrack == nil {
                options.append(.applyForResidency)
            }
            if state.education.credentials.contains("JD") && state.career.specializedTrack == nil {
                options.append(.passBarExam)
            }
        }
        
        if state.career.professionalRank == "Senior Developer" {
            options.append(.becomeCTO)
        }

        if state.specialCareer.track == .founder {
            var founder: [ActionChoiceID] = [.pivotBusiness, .raiseCapital, .aggressiveExpansion, .closeMajorDeal, .allHandsRally, .fundraiseSprint, .takeRealBreak, .hireKeyTalent, .protectYourEnergy, .network]
            if state.specialCareer.audience >= 75 { founder.append(.ipoExit) }
            if SpecialCareerSystem.qualificationIssue(for: .startCompany, state: state) == nil {
                founder.insert(.startCompany, at: 0)
            }
            return founder
        }
        if state.specialCareer.track == .entertainment {
            var entertainment: [ActionChoiceID] = [.chaseSpotlight, .compete, .intenseTraining, .protectYourEnergy, .network, .coast]
            if SpecialCareerSystem.qualificationIssue(for: .startMovieActor, state: state) == nil {
                entertainment.insert(.startMovieActor, at: 1)
            }
            if SpecialCareerSystem.qualificationIssue(for: .startMusicProducer, state: state) == nil {
                entertainment.insert(.startMusicProducer, at: 1)
            }
            if SpecialCareerSystem.qualificationIssue(for: .startMovieProducer, state: state) == nil {
                entertainment.insert(.startMovieProducer, at: 1)
            }
            if SpecialCareerSystem.qualificationIssue(for: .startRecordLabel, state: state) == nil {
                entertainment.insert(.startRecordLabel, at: 1)
            }
            return entertainment
        }
        if state.specialCareer.track == .movieActor {
            var actor: [ActionChoiceID] = [.auditionRole, .actingClass, .buildActingReel, .takeIndieRole, .managePublicist, .protectYourEnergy, .network]
            if SpecialCareerSystem.qualificationIssue(for: .startMovieProducer, state: state) == nil {
                actor.append(.startMovieProducer)
            }
            return actor
        }
        if state.specialCareer.track == .musicProducer {
            var producer: [ActionChoiceID] = [.produceTrack, .runStudioSession, .shopBeats, .collaborateWithArtist, .polishSignatureSound, .manageProducerCredits, .protectYourEnergy, .network]
            if SpecialCareerSystem.qualificationIssue(for: .startRecordLabel, state: state) == nil {
                producer.append(.startRecordLabel)
            }
            return producer
        }
        if state.specialCareer.track == .movieProducer {
            return [.optionScript, .castProject, .shootFilm, .secureDistribution, .handleProductionCrisis, .manageBackEndPoints, .protectYourEnergy, .network]
        }
        if state.specialCareer.track == .recordLabelOwner {
            return [.signArtist, .developArtist, .releaseRecord, .pushSingle, .bookTour, .payArtists, .handleArtistDrama, .protectYourEnergy, .network]
        }
        if state.specialCareer.track == .coach {
            return [.recruitTalent, .hireCoachingStaff, .installSystem, .runTrainingCamp, .manageLockerRoom, .callBigGame, .handleBoosterPressure, .protectYourEnergy, .network]
        }
        if state.specialCareer.track == .contentCreator {
            // C2: Full set of dedicated creator quick actions
            return [.postDaily, .goLive, .filmBanger, .collab, .addressDrama, .takeMentalBreak, .dropBrandDeal, .protectYourEnergy, .network, .chaseSpotlight]
        }
        if state.specialCareer.track == .politics {
            // P2: Full set of dedicated politics quick actions
            return [.townHall, .politicalFundraise, .scandalResponse, .policyPush, .backroomDeal, .mediaHit, .takeAStand, .attackOpponent, .protectYourEnergy, .network, .chaseSpotlight]
        }
        if state.specialCareer.track == .crime {
            return [.runScheme, .layLow, .buildCrew, .cleanMoney, .stepAway, .ghostProtocol, .burnEvidence, .payTheFixer, .launderThroughShell, .hostStrategicGala, .aggressiveTakeover]
        }
        if state.specialCareer.track == .athlete {
            // Phase S2 + S3a: Athlete actions + edge temptation (doping)
            var athlete: [ActionChoiceID] = [.extraTrainingSession, .mediaAppearance, .recoveryFocus, .teamBonding, .edgeProtocol, .protectYourEnergy, .network]
            if SpecialCareerSystem.qualificationIssue(for: .startCoachingCareer, state: state) == nil {
                athlete.append(.startCoachingCareer)
            }
            return athlete
        }

        if state.player.age >= 18 {
            options.append(contentsOf: [ActionChoiceID.workHard, .protectYourEnergy, .network, .retrain, .takeOvertime, .coast, .jobHunt, .chaseSpotlight])
            // D3: regular career archetype committed options for depth (6-way parity)
            options.append(contentsOf: [.corporateClimb, .freelanceHustle, .tradesMastery, .pivotToGig, .publicServiceGrind, .techDeepWork])
            if SpecialCareerSystem.qualificationIssue(for: .startCompany, state: state) == nil {
                options.append(.startCompany)
            }
            if SpecialCareerSystem.qualificationIssue(for: .startMovieActor, state: state) == nil {
                options.append(.startMovieActor)
            }
            if SpecialCareerSystem.qualificationIssue(for: .startMusicProducer, state: state) == nil {
                options.append(.startMusicProducer)
            }
            if SpecialCareerSystem.qualificationIssue(for: .startMovieProducer, state: state) == nil {
                options.append(.startMovieProducer)
            }
            if SpecialCareerSystem.qualificationIssue(for: .startRecordLabel, state: state) == nil {
                options.append(.startRecordLabel)
            }
            if SpecialCareerSystem.qualificationIssue(for: .startCoachingCareer, state: state) == nil {
                options.append(.startCoachingCareer)
            }
            if SpecialCareerSystem.qualificationIssue(for: .manageFund, state: state) == nil {
                options.append(.manageFund)
            }
            if SpecialCareerSystem.qualificationIssue(for: .acquireCompetitor, state: state) == nil {
                options.append(.acquireCompetitor)
            }
            if SpecialCareerSystem.qualificationIssue(for: .intenseTraining, state: state) == nil {
                options.append(.intenseTraining)
            }
            if SpecialCareerSystem.qualificationIssue(for: .compete, state: state) == nil {
                options.append(.compete)
            }
            if SpecialCareerSystem.qualificationIssue(for: .gatherIntelligence, state: state) == nil {
                options.append(contentsOf: [.gatherIntelligence, .exploitLeverage])
            }
        } else {
            options.append(contentsOf: [.workHard, .coast, .jobHunt])
        }

        return options
    }

    private func crimeCommittedChoices() -> [ActionChoiceID] {
        guard isCrimeLaneActive() else { return [] }
        return [.runScheme, .layLow, .buildCrew, .cleanMoney, .stepAway]
    }

    private func financeCommittedChoices() -> [ActionChoiceID] {
        if context.isStudentLifeExperience {
            var studentOptions: [ActionChoiceID] = [.takeExtraShifts, .saveForEscape, .cutSpending, .spendToCope]
            if state.finance.studentDebt > 0 { studentOptions.append(.deferStudentLoans) }
            return studentOptions
        }
        var financeOptions: [ActionChoiceID] = []
        if (14...15).contains(state.player.age) {
            financeOptions = [.smallHustle, .cutSpending, .spendForRelief]
        } else if state.player.age >= 18 {
            financeOptions = [.cutSpending, .spendForRelief, .takeSideWork]
            if state.finance.totalNonHousingDebt > 0 {
                financeOptions.append(contentsOf: [.payDownDebt, .consolidateDebt, .minimumPayments])
                if state.finance.studentDebt > 0 { financeOptions.append(.deferStudentLoans) }
                if state.finance.canUseDebtReset { financeOptions.append(.declareBankruptcy) }
            }
            
            // Phase 2 Investments
            if state.finance.cashOnHand >= 5000 { financeOptions.append(.buyStocks) }
            if state.finance.cashOnHand >= 2000 { financeOptions.append(.buyCrypto) }
            if state.finance.cashOnHand >= 50000 { financeOptions.append(.buyRentalProperty) }
            
            if !state.finance.portfolio.stocks.isEmpty { financeOptions.append(.sellStocks) }
            if !state.finance.portfolio.crypto.isEmpty { financeOptions.append(.sellCrypto) }
            if !state.finance.portfolio.rentals.isEmpty { 
                financeOptions.append(contentsOf: [.manageRentals, .sellRentalProperty]) 
            }

            if state.finance.cashOnHand >= 2_000 {
                financeOptions.append(contentsOf: [.dayTrade, .analyzeMarkets, .checkPortfolio, .rebalancePortfolio, .researchTip, .buyIndex, .sellPosition])
            }
        }

        if state.assets.ownsHome {
            financeOptions.append(contentsOf: [.buildMaintenanceReserve, .refinanceMortgage, .sellHome])
        }

        if state.player.age >= 18 && state.career.status == .fullTime {
            let canBuyStarterHome =
                state.career.yearsWorked >= 2 &&
                state.finance.lastYearBalanceDelta >= 0 &&
                state.finance.homeDownPaymentSavings + state.finance.cashOnHand >= 35_000 &&
                state.finance.debtPressureBand != .heavy &&
                state.finance.debtPressureBand != .crushing &&
                state.finance.recentDebtReliefYears == 0
            if canBuyStarterHome || state.assets.isSavingForHome || state.finance.homeDownPaymentSavings > 0 {
                financeOptions.append(contentsOf: canBuyStarterHome
                    ? [.saveForDownPayment, .buyStarterHome, .buyIndexFund]
                    : [.saveForDownPayment, .cutSpending, .takeSideWork])
            }
        }

        if context.canAccessInvesting {
            let isUnderPressure = state.finance.lastYearBalanceDelta < 0 || state.finance.cashOnHand < context.investmentEmergencyReserve
            if isUnderPressure, state.finance.hasInvestments {
                financeOptions.append(contentsOf: [.buildEmergencyFund, .holdPositions, .sellToCover])
            } else if state.finance.hasInvestments {
                financeOptions.append(contentsOf: [.buyIndexFund, .speculateStocks, .holdPositions])
            } else {
                financeOptions.append(contentsOf: [.buildEmergencyFund, .buyIndexFund, .speculateStocks])
            }
        }
        return Array(Set(financeOptions))
    }

    private func relationshipCommittedChoices() -> [ActionChoiceID] {
        if context.isTeenExperience {
            return [.findYourCrowd, .dateCarefully, .chaseStatus, .stayInvisible, .leanOnMentor]
        }
        
        var options: [ActionChoiceID] = [.reachOut, .keepDistance, .repairTension]
        if state.player.age >= 18 { options.append(.callInFavor) }

        if let partner = state.relationships.primaryPartner {
            options.append(contentsOf: [.strengthenBond, .discussFuture])
            if !partner.isCohabiting { options.append(.moveInTogether) }
            
            if partner.stage == .engaged {
                options.append(.planWedding)
            } else if partner.stage == .married {
                options.append(contentsOf: [.tryForBaby, .avoidPregnancy, .letChanceDecide, .fileForDivorce])
            } else if partner.stage == .committed {
                if !partner.hasPrenup { options.append(.signPrenup) }
                options.append(.proposeMarriage)
                options.append(.buyEngagementRing)
            }
        } else {
            options.append(.dateCarefully)
        }
        
        if state.relationships.romanticPartners.contains(where: { $0.isSecret }) {
            options.append(.endAffair)
        } else if state.relationships.hasPartner {
            options.append(.startAffair)
        }
        
        return options
    }

    private func healthCommittedChoices() -> [ActionChoiceID] {
        context.isStudentLifeExperience ? [.protectSleep, .pushThrough, .rest, .seeDoctor] : [.rest, .pushThrough, .seeDoctor]
    }

    // MARK: - Suggested callback

    private func deriveSuggestedCallbackAction() -> SuggestedPlayerAction? {
        if let strainedFriend = state.relationships.friends.first(where: { $0.status == .strained }) {
            return SuggestedPlayerAction(
                domain: .relationships,
                choiceID: .repairTension,
                headline: "Repair things with \(strainedFriend.name)"
            )
        }
        if state.relationships.hasPartner, state.relationships.partnerBond < 50, let partner = state.relationships.primaryPartner {
            return SuggestedPlayerAction(
                domain: .relationships,
                choiceID: .strengthenBond,
                headline: "Invest in \(partner.name)"
            )
        }
        if state.consequences.narrativeFlags["npc_autonomy_pulse", default: 0] > 0,
           let friend = state.relationships.friends.first {
            return SuggestedPlayerAction(
                domain: .relationships,
                choiceID: .reachOut,
                headline: "Check in with \(friend.name)"
            )
        }
        let topPressure = state.consequences.pressureByDomain.max(by: { $0.value < $1.value })
        if let topPressure, topPressure.value >= 28, let domain = ActionDomain(rawValue: topPressure.key),
           let choice = suggestedChoice(for: domain) {
            return SuggestedPlayerAction(
                domain: domain,
                choiceID: choice,
                headline: "Respond to \(topPressure.key) pressure"
            )
        }
        return nil
    }

    private func storedMatchesPlayable(_ suggested: SuggestedPlayerAction) -> Bool {
        availableCommitted(for: suggested.domain).contains(suggested.choiceID)
            || availableQuick(for: suggested.domain).contains(suggested.choiceID)
            || resolutionTier(for: suggested.choiceID, domain: suggested.domain) == .instant
    }

    private func dedupe(_ choices: [ActionChoiceID]) -> [ActionChoiceID] {
        var seen: Set<ActionChoiceID> = []
        return choices.filter { seen.insert($0).inserted }
    }
}

extension GameViewModel {
    func makeActionRegistry() -> DomainActionRegistry {
        DomainActionRegistry(
            context: DomainActionContext(
                state: state,
                isTeenExperience: isTeenExperience,
                isStudentLifeExperience: isStudentLifeExperience,
                canAccessInvesting: canAccessInvesting,
                investmentEmergencyReserve: investmentEmergencyReserve
            )
        )
    }
}
