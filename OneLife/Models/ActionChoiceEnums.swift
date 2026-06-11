import Foundation

// MARK: - Action Choice Enums

enum ActionDomain: String, Codable, CaseIterable, Identifiable {
    case education
    case career
    case military
    case finance
    case relationships
    case health
    case crime
    case legal
    case family
    case identity

    var id: String { rawValue }
}
enum ActionChoiceID: String, Codable, CaseIterable, Identifiable {
    case studyHard
    case studyConsistently
    case cramAndSurvive
    case lockInRoutine
    case joinActivity
    case joinClub
    case buildPortfolio
    case layLow
    case skipClass
    case skipAndDrift
    case keepThePeace
    // Teen precursors (dossier-driven early sparks for special careers - available 14-17, seed substates + school buffs)
    case teenAthleticDrill      // physical -> athlete path
    case teenSideHustle         // entrepreneurial -> founder/crime trader
    case teenCreativeProject    // creative -> creator
    case teenLeadInitiative     // social -> politics
    case teenRiskyExperiment    // high risk tolerance lean -> criminal enterprise
    case workHard
    case protectYourEnergy
    case network
    case pivotCareer
    case trainNewSkill
    case retire
    case retrain
    case takeOvertime
    case coast
    case jobHunt
    case chaseSpotlight
    case startMovieActor
    case auditionRole
    case actingClass
    case buildActingReel
    case takeIndieRole
    case managePublicist
    case startMusicProducer
    case produceTrack
    case runStudioSession
    case shopBeats
    case collaborateWithArtist
    case polishSignatureSound
    case manageProducerCredits
    case startMovieProducer
    case optionScript
    case castProject
    case shootFilm
    case handleProductionCrisis
    case secureDistribution
    case manageBackEndPoints
    case startRecordLabel
    case signArtist
    case developArtist
    case releaseRecord
    case bookTour
    case payArtists
    case pushSingle
    case handleArtistDrama
    case startCoachingCareer
    case recruitTalent
    case hireCoachingStaff
    case installSystem
    case runTrainingCamp
    case manageLockerRoom
    case callBigGame
    case handleBoosterPressure
    case startSportsOwnership
    case acquireFranchise
    case hireGeneralManager
    case negotiateMediaDeal
    case investInBrand
    case expandPortfolio
    case sellFranchise
    case intenseTraining
    case compete
    case startBoxingCareer
    case startMMACareer
    case acceptSafeFight
    case acceptRankedFight
    case acceptDangerousFight
    case boxingPowerCamp
    case boxingTechniqueCamp
    case mmaStrikingCamp
    case mmaGrapplingCamp
    case combatConditioningCamp
    case combatRecoveryCamp
    case boxingPressureStrategy
    case boxingCounterStrategy
    case boxingOutsideStrategy
    case mmaStrikeStrategy
    case mmaWrestleStrategy
    case mmaMixedStrategy
    case crossoverCombatDiscipline
    case retireFromCombat
    case startFightEmpire
    case recruitFightProspect
    case buildFightCamp
    case developFightProspect
    case bookFightEvent
    case negotiateBroadcastDeal
    case protectFighterHealth
    case promoteGrudgeMatch
    // Phase S2: Dedicated athlete quick actions for frictionless sports pipeline
    case extraTrainingSession
    case mediaAppearance
    case recoveryFocus
    case teamBonding
    // S3a: The Myth & The Machine — doping / edge temptation
    case edgeProtocol
    // E2: Dedicated founder quick actions for frictionless entrepreneur experience
    case closeMajorDeal
    case allHandsRally
    case fundraiseSprint
    case takeRealBreak
    case hireKeyTalent
    // C2: Dedicated creator quick actions for frictionless content creator experience
    case postDaily
    case goLive
    case filmBanger
    case collab
    case addressDrama
    case takeMentalBreak
    case dropBrandDeal
    // P2: Dedicated politics quick actions
    case townHall
    case politicalFundraise
    case scandalResponse
    case policyPush
    case backroomDeal
    case mediaHit
    case takeAStand
    case attackOpponent
    case gatherIntelligence
    case exploitLeverage
    // CE2: Dedicated crime quick actions for Dark Fame Web parity
    case crimeLayLow
    case crimeRecruitAssociate
    case crimeLaunderFunds
    case crimeCutTies
    case dayTrade
    case analyzeMarkets
    case runScheme
    case buildCrew
    case cleanMoney
    case stepAway
    case retainCounsel
    case cooperateWithInvestigation
    case refuseInterview
    case negotiatePlea
    case fightCharges
    case postBail
    case complyWithSupervision
    case requestEarlyRelease
    // PC1: Custody instant actions — get-out focus + inside violence
    case keepHeadDown
    case standYourGround
    case alignWithFaction
    case payProtection
    case refuseSnitchDeal
    case cooperateWithGuards
    case prisonWorkDetail
    case studyProgram
    case callFamily
    case requestParoleHearing
    case fileAppeal
    // PC2: Enterprise proxy actions — moderate inside influence
    case delegateFromInside
    case callLieutenant
    case authorizeOutsideMove
    // CE2: Dedicated instant actions for Criminal Enterprise paths
    case ghostProtocol
    case burnEvidence
    case payTheFixer
    case launderThroughShell
    case hostStrategicGala
    case aggressiveTakeover
    // CT5: Tier-differentiated crime instant actions
    case streetCornerHustle
    case dodgePatrol
    case holdTerritory
    case disciplineCrew
    case delegateOperation
    case expandDomesticEmpire
    case connectCartelNetwork
    case smallHustle
    case takeExtraShifts
    case saveForEscape
    case cutSpending
    case spendForRelief
    case spendToCope
    case takeSideWork
    case payDownDebt
    case consolidateDebt
    case minimumPayments
    case deferStudentLoans
    case declareBankruptcy
    case buildEmergencyFund
    case buyIndexFund
    case speculateStocks
    case holdPositions
    case sellToCover
    case saveForDownPayment
    case depositToHouseFund
    case buyStarterHome
    case refinanceMortgage
    case buildMaintenanceReserve
    case topUpHouseReserve
    // Econ4: Dedicated economic quick actions with strong era + special career flavor
    case panicSell
    case aggressiveSideHustle
    case bigLifestylePurchase
    case rideTheWave
    case quietFinancialQuit
    case sellHome
    // Econ1 (Stock Market)
    case checkPortfolio
    case rebalancePortfolio
    case researchTip
    case buyIndex
    case sellPosition
    // Assets3: Instant layer for luxury and signature assets
    case flexLuxuryAsset
    case liquidateLuxury
    case upgradeCollection
    case hostAtSignatureEstate
    case findYourCrowd
    case dateCarefully
    case startAffair
    case endAffair
    case buyEngagementRing
    case signPrenup
    case proposeMarriage
    case planWedding
    case fileForDivorce
    case chaseStatus
    case stayInvisible
    case leanOnMentor
    case reachOut
    case strengthenBond
    case discussFuture
    case moveInTogether
    case tryForBaby
    case avoidPregnancy
    case letChanceDecide
    case keepDistance
    case repairTension
    // Phase 2.2: Simple parenting mechanics with trade-offs
    case spendTimeWithKids
    case enforceRoutine
    case encourageIndependence
    case checkInOnChild
    case protectSleep
    case rest
    case pushThrough
    case seeDoctor
    case callInFavor
    case startCompany
    case pitchDeck
    case pivotBusiness
    case raiseCapital
    case aggressiveExpansion
    case manageFund
    case acquireCompetitor
    case stripAssets
    case ipoExit
    case hireAdvisor
    
    // Military
    case enlistArmy
    case enlistNavy
    case enlistAirForce
    case enlistMarines
    case enlistCoastGuard
    case enlistSpaceForce
    case commissionArmy
    case commissionNavy
    case commissionAirForce
    case commissionMarines
    case commissionCoastGuard
    case commissionSpaceForce
    case joinReservesArmy
    case joinReservesNavy
    case joinReservesAirForce
    case joinReservesMarines
    case joinReservesCoastGuard
    case joinReservesSpaceForce
    case militaryService
    case deploy
    case goAWOL
    case desert
    case militaryRetirement
    
    // Military V2
    case joinROTC
    case leaveROTC
    case selectCombatMOS
    case selectMedicalMOS
    case selectAviationMOS
    case selectIntelMOS
    case selectLogisticsMOS
    case useGIBill
    case seekVAHealthcare
    case claimPension
    
    // Investment Portfolios
    case buyStocks
    case sellStocks
    case buyCrypto
    case sellCrypto
    case buyRentalProperty
    case sellRentalProperty
    case manageRentals
    
    // Legacy
    case switchToChild
    
    // Specialized Civilian Careers
    case applyForResidency
    case completeResidency
    // Luxury / Lifestyle (L1)
    case hostLuxuryEvent
    case acquireLuxuryAsset
    case indulgeInExcess
    case displayWealth
    case maintainLuxuryCollection
    case openPrivatePractice
    case passBarExam
    case makePartner
    case becomeCTO
    case launchStartupSpinOff

    // D1: Identity domain activation — light self actions, always-available static instants
    case morningReflection
    case reconcileWithPast
    case tryNewPersona
    case publicReset
    case therapySession
    case processCrisis

    // D1: Military depth — new static instants + deploy tour
    case ptFocus
    case seekCounsel
    case studyTradition
    case deployTour

    // D1: Family light always — persistent low-commitment family statics
    case familyMeal
    case storyTime

    // D2: Finance/Assets mastery & collector loops (per-path unique assets, maintenance, era costs, fame/lifestyle/knownFor)
    case curateCollection
    case hostSignatureEvent
    case maintainAsset

    // D2: Health depth (condition management, aging curves by resilience/lifestyle, body-as-asset)
    case recurringTherapy
    case manageMeds
    case bodyConditioning

    // D2: Relationships depth (per-friend, rivalry, private vs public rep split)
    case deepenSpecificBond
    case fuelRivalry
    case splitReputation

    // D3: Education-to-everything branches (trade/uni/honors mechanical differences, lifelong learning, credential handoff)
    case pursueTradeCert
    case honorsTrack
    case uniApplication
    case lifelongLearning
    case credentialRefresh

    // D3: Regular career archetype parity (non-special deep paths, aging curves, side-hustle overlap)
    case corporateClimb
    case freelanceHustle
    case tradesMastery
    case pivotToGig
    // D3: additional regular archetypes for 6-way parity (public service, tech/engineering)
    case publicServiceGrind
    case techDeepWork
    // D5: Regular archetype instant toolkit (native Right Now actions per path)
    case corporateStayLate
    case corporatePolitick
    case corporateDocumentWin
    case tradesExtraFocus
    case tradesMaintainTools
    case tradesSafetyPush
    case salesClientOutreach
    case salesPipelineGrind
    case salesRecoveryCall
    case gigAcceptSurge
    case gigMaintainRating
    case gigRestDay

    var id: String { rawValue }
    
    var domain: ActionDomain {
        switch self {
        case .studyHard, .studyConsistently, .cramAndSurvive, .lockInRoutine, .joinClub, .buildPortfolio, .skipClass, .skipAndDrift, .joinROTC, .leaveROTC:
            return .education
        case .workHard, .network, .pivotCareer, .trainNewSkill, .retire, .jobHunt, .takeOvertime, .takeExtraShifts, .chaseSpotlight, .startMovieActor, .auditionRole, .actingClass, .buildActingReel, .takeIndieRole, .managePublicist, .startMusicProducer, .produceTrack, .runStudioSession, .shopBeats, .collaborateWithArtist, .polishSignatureSound, .manageProducerCredits, .startMovieProducer, .optionScript, .castProject, .shootFilm, .handleProductionCrisis, .secureDistribution, .manageBackEndPoints, .startRecordLabel, .signArtist, .developArtist, .releaseRecord, .bookTour, .payArtists, .pushSingle, .handleArtistDrama, .startCoachingCareer, .recruitTalent, .hireCoachingStaff, .installSystem, .runTrainingCamp, .manageLockerRoom, .callBigGame, .handleBoosterPressure, .startSportsOwnership, .acquireFranchise, .hireGeneralManager, .negotiateMediaDeal, .investInBrand, .expandPortfolio, .sellFranchise, .startCompany, .pitchDeck, .pivotBusiness, .raiseCapital, .aggressiveExpansion, .ipoExit, .hireAdvisor, .compete, .intenseTraining, .recoveryFocus, .mediaAppearance, .teamBonding, .extraTrainingSession, .edgeProtocol, .gatherIntelligence, .exploitLeverage, .applyForResidency, .completeResidency, .openPrivatePractice, .passBarExam, .makePartner, .becomeCTO, .launchStartupSpinOff,
             .closeMajorDeal, .allHandsRally, .fundraiseSprint, .takeRealBreak, .hireKeyTalent,
             .postDaily, .goLive, .filmBanger, .collab, .addressDrama, .takeMentalBreak, .dropBrandDeal,
             .townHall, .politicalFundraise, .scandalResponse, .policyPush, .backroomDeal, .mediaHit, .takeAStand, .attackOpponent:
            return .career
        case .enlistArmy, .enlistNavy, .enlistAirForce, .enlistMarines, .enlistCoastGuard, .enlistSpaceForce, .commissionArmy, .commissionNavy, .commissionAirForce, .commissionMarines, .commissionCoastGuard, .commissionSpaceForce, .joinReservesArmy, .joinReservesNavy, .joinReservesAirForce, .joinReservesMarines, .joinReservesCoastGuard, .joinReservesSpaceForce, .militaryService, .deploy, .goAWOL, .desert, .militaryRetirement, .selectCombatMOS, .selectMedicalMOS, .selectAviationMOS, .selectIntelMOS, .selectLogisticsMOS, .ptFocus, .seekCounsel, .studyTradition, .deployTour:
            return .military
        case .runScheme, .layLow, .buildCrew, .cleanMoney, .stepAway,
             .ghostProtocol, .burnEvidence, .payTheFixer, .launderThroughShell, .hostStrategicGala, .aggressiveTakeover,
             .streetCornerHustle, .dodgePatrol, .holdTerritory, .disciplineCrew, .delegateOperation,
             .expandDomesticEmpire, .connectCartelNetwork:
            return .crime
        case .retainCounsel, .cooperateWithInvestigation, .refuseInterview,
             .negotiatePlea, .fightCharges, .postBail,
             .complyWithSupervision, .requestEarlyRelease,
             .keepHeadDown, .standYourGround, .alignWithFaction, .payProtection,
             .refuseSnitchDeal, .cooperateWithGuards, .prisonWorkDetail, .studyProgram,
             .callFamily, .requestParoleHearing, .fileAppeal,
             .delegateFromInside, .callLieutenant, .authorizeOutsideMove:
            return .legal
        case .cutSpending, .spendForRelief, .spendToCope, .saveForEscape, .payDownDebt, .consolidateDebt, .minimumPayments, .deferStudentLoans, .declareBankruptcy, .dayTrade, .analyzeMarkets, .buyStocks, .sellStocks, .buyCrypto, .sellCrypto, .buyRentalProperty, .sellRentalProperty, .manageRentals, .claimPension,
             .saveForDownPayment, .depositToHouseFund, .buyStarterHome, .refinanceMortgage, .buildMaintenanceReserve, .topUpHouseReserve, .sellHome,
             .buildEmergencyFund, .buyIndexFund, .speculateStocks, .holdPositions, .sellToCover, .takeSideWork, .smallHustle,
             .panicSell, .aggressiveSideHustle, .bigLifestylePurchase, .rideTheWave, .quietFinancialQuit:
            return .finance
        case .reachOut, .repairTension, .keepDistance, .discussFuture, .moveInTogether, .callInFavor, .startAffair, .endAffair, .buyEngagementRing, .signPrenup, .proposeMarriage, .planWedding, .fileForDivorce:
            return .relationships
        case .seeDoctor, .rest, .protectSleep, .pushThrough, .seekVAHealthcare:
            return .health
        case .tryForBaby, .avoidPregnancy, .letChanceDecide, .checkInOnChild, .spendTimeWithKids, .enforceRoutine, .encourageIndependence:
            return .family
        // D1 new actions
        case .morningReflection, .reconcileWithPast, .tryNewPersona, .publicReset, .therapySession, .processCrisis:
            return .identity
        case .familyMeal, .storyTime:
            return .family
        // D2 new actions
        case .curateCollection, .hostSignatureEvent, .maintainAsset:
            return .finance
        case .recurringTherapy, .manageMeds, .bodyConditioning:
            return .health
        case .deepenSpecificBond, .fuelRivalry, .splitReputation:
            return .relationships
        // D3 education
        case .pursueTradeCert, .honorsTrack, .uniApplication, .lifelongLearning, .credentialRefresh:
            return .education
        // D3 regular career
        case .corporateClimb, .freelanceHustle, .tradesMastery, .pivotToGig, .publicServiceGrind, .techDeepWork,
             .corporateStayLate, .corporatePolitick, .corporateDocumentWin,
             .tradesExtraFocus, .tradesMaintainTools, .tradesSafetyPush,
             .salesClientOutreach, .salesPipelineGrind, .salesRecoveryCall,
             .gigAcceptSurge, .gigMaintainRating, .gigRestDay:
            return .career
        default:
            return .career
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        switch rawValue {
        case "phoneItIn":
            self = .layLow
        default:
            guard let value = ActionChoiceID(rawValue: rawValue) else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid ActionChoiceID: \(rawValue)")
            }
            self = value
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
enum ActionFrictionLevel: String, Codable, Equatable {
    case none
    case resistance // Harder to press, visual jitter
    case warning // Red pulse, heavy haptics
    case danger // Severe warning
    case locked // Cannot be selected due to state
}
enum ActionResolutionTier: String, Codable, Equatable, CaseIterable {
    /// BitLife-style tap: resolves immediately via `applyImmediateAction`.
    case instant
    /// Macro intent: queued in `pendingActions` and applied when the year resolves on Age Up.
    case committed
}

