import Foundation

struct EducationSystem {
    func advanceYear(input: EducationDomainSnapshot, player: inout Player, education: inout EducationState, career: inout CareerState) -> DomainYearResult {
        advanceYear(
            player: &player,
            education: &education,
            career: &career,
            finance: input.finance,
            relationships: input.relationships,
            health: input.health,
            policySupport: input.policySupport
        )
    }

    func advanceYear(
        player: inout Player,
        education: inout EducationState,
        career: inout CareerState,
        finance: FinanceState,
        relationships: RelationshipState,
        health: HealthState,
        policySupport: Int
    ) -> DomainYearResult {
        var result = DomainYearResult()

        guard player.age <= 22 else {
            if education.stage != .inactive {
                education.stage = .inactive
            }
            education.clamp()
            return result
        }

        education.yearsInStage += 1

        if player.age <= 17, education.stage != .secondary {
            education.stage = .secondary
            education.yearsInStage = 0
        }

        let socialStrain = (relationships.friends + relationships.romanticPartners)
            .filter { $0.status == .strained }
            .count
        let strongestBond = max(relationships.friends.strongestBond, relationships.romanticPartners.strongestBond)
        let friendshipLift = min(18, relationships.friends.count * 4)
        let publicReputationLift = max(0, relationships.publicReputation - 55) / 10
        let rumorPenalty = max(0, relationships.activeRumorHeat - 45) / 8
        let wellnessDrag = max(0, 55 - health.mentalWellness)
        let workLoad = career.status == .partTime ? 4 : (career.status == .fullTime ? 8 : 0)

        let belongingShift =
            ((education.activityMomentum - 40) / 8) +
            (friendshipLift / 6) +
            ((strongestBond - 50) / 14) -
            (socialStrain * 4) -
            rumorPenalty +
            publicReputationLift -
            (max(0, education.reputationRisk - 45) / 15) -
            (max(0, education.peerPressure - 45) / 18)
        education.schoolBelonging = (education.schoolBelonging + belongingShift).clamped(to: 0...100)

        let reputationShift =
            (socialStrain * 5) +
            (wellnessDrag / 10) +
            rumorPenalty +
            (max(0, education.attendancePressure - 45) / 12) -
            (max(0, education.schoolBelonging - 55) / 15) -
            (max(0, education.teacherSupport - 55) / 18) +
            (max(0, education.peerPressure - 50) / 10)
        education.reputationRisk = (education.reputationRisk + reputationShift).clamped(to: 0...100)

        let teacherShift =
            ((education.schoolStanding - 55) / 10) +
            ((education.engagement - 50) / 12) +
            ((education.activityMomentum - 35) / 20) -
            (max(0, education.attendancePressure - 50) / 16) -
            (max(0, education.reputationRisk - 45) / 18) +
            policySupport
        education.teacherSupport = (education.teacherSupport + teacherShift).clamped(to: 0...100)
        education.mentorSupport = (
            education.mentorSupport +
            ((education.teacherSupport - 50) / 10) +
            ((education.disciplineRecord - 60) / 16) -
            (max(0, education.peerPressure - 45) / 16)
        ).clamped(to: 0...100)

        let pressureShift =
            (finance.financialStress >= 35 ? 6 : (finance.financialStress <= 15 ? -2 : 1)) +
            (max(0, education.reputationRisk - 40) / 12) -
            (max(0, education.teacherSupport - 45) / 14) -
            policySupport
        education.attendancePressure = (education.attendancePressure + pressureShift).clamped(to: 0...100)
        education.peerPressure = (
            education.peerPressure +
            (socialStrain * 4) +
            (max(0, education.reputationRisk - 45) / 14) -
            (max(0, education.schoolBelonging - 55) / 16) -
            (max(0, education.mentorSupport - 55) / 18)
        ).clamped(to: 0...100)

        if player.age <= 17 {
            let momentumShift = (education.engagement - 52) / 10
            education.activityMomentum = (education.activityMomentum + momentumShift).clamped(to: 0...100)
        }

        let standingShift =
            ((player.smarts - 50) / 8) +
            ((education.engagement - 50) / 7) -
            ((education.attendancePressure - 30) / 12) +
            ((education.teacherSupport - 50) / 14) -
            (max(0, 42 - education.schoolBelonging) / 12) -
            (max(0, education.reputationRisk - 48) / 16) +
            policySupport
        education.schoolStanding = (education.schoolStanding + standingShift).clamped(to: 0...100)

        education.applicationReadiness = (
            education.applicationReadiness +
            ((education.schoolStanding - 55) / 7) +
            ((education.teacherSupport - 50) / 10) +
            ((education.activityMomentum - 35) / 15) +
            ((education.mentorSupport - 40) / 14) -
            workLoad
        ).clamped(to: 0...100)
        education.burnoutRisk = (
            education.burnoutRisk +
            (max(0, education.attendancePressure - 40) / 8) +
            (max(0, finance.financialStress - 30) / 9) +
            (max(0, 52 - health.mentalWellness) / 6) +
            workLoad -
            (max(0, education.schoolBelonging - 50) / 12) -
            (max(0, education.mentorSupport - 45) / 14)
        ).clamped(to: 0...100)
        education.disciplineRecord = (
            education.disciplineRecord +
            ((education.teacherSupport - 50) / 14) -
            (max(0, education.attendancePressure - 45) / 10) -
            (max(0, education.reputationRisk - 50) / 11)
        ).clamped(to: 0...100)
        education.campusFit = (
            education.campusFit +
            ((education.schoolBelonging - 48) / 10) +
            ((education.mentorSupport - 40) / 12) -
            (max(0, education.peerPressure - 45) / 14)
        ).clamped(to: 0...100)

        education.academicTrack = resolvedAcademicTrack(for: education)

        if player.age <= 17 {
            let scholarshipReady = education.schoolStanding >= 78 && (education.activityMomentum >= 42 || education.teacherSupport >= 68)
            let recommendationRoute = education.schoolStanding >= 72 && education.teacherSupport >= 74 && education.schoolBelonging >= 48
            if (scholarshipReady || recommendationRoute) && !education.hasScholarship {
                education.hasScholarship = true
                result.notes.append(DomainNote(title: "Education", text: "Strong school performance earned you scholarship support."))
            }

            if education.pathway == .dropout && player.age >= 17 && education.engagement >= 58 {
                education.pathway = .training
                education.stage = .tradeTraining
                education.academicTrack = .vocational
                education.yearsInStage = 0
                if !education.credentials.contains("Certificate Track") {
                    education.credentials.append("Certificate Track")
                }
                result.notes.append(DomainNote(title: "Education", text: "You found a practical training path that could stabilize your future."))
            }
        }

        if player.age == 18 {
            resolveAgeEighteenTransition(player: &player, education: &education, career: &career, finance: finance, result: &result)
        } else if player.age >= 19 {
            advancePostSecondaryStage(player: player, education: &education, career: &career, finance: finance, health: health, result: &result)
        }

        education.clamp()
        return result
    }

    func apply(effect: EducationEffects, education: inout EducationState) {
        if let schoolStanding = effect.schoolStanding {
            education.schoolStanding = (education.schoolStanding + schoolStanding).clamped(to: 0...100)
        }
        if let engagement = effect.engagement {
            education.engagement = (education.engagement + engagement).clamped(to: 0...100)
        }
        if let attendancePressure = effect.attendancePressure {
            education.attendancePressure = (education.attendancePressure + attendancePressure).clamped(to: 0...100)
        }
        if let activityMomentum = effect.activityMomentum {
            education.activityMomentum = (education.activityMomentum + activityMomentum).clamped(to: 0...100)
        }
        if let schoolBelonging = effect.schoolBelonging {
            education.schoolBelonging = (education.schoolBelonging + schoolBelonging).clamped(to: 0...100)
        }
        if let reputationRisk = effect.reputationRisk {
            education.reputationRisk = (education.reputationRisk + reputationRisk).clamped(to: 0...100)
        }
        if let teacherSupport = effect.teacherSupport {
            education.teacherSupport = (education.teacherSupport + teacherSupport).clamped(to: 0...100)
        }
        if let applicationReadiness = effect.applicationReadiness {
            education.applicationReadiness = (education.applicationReadiness + applicationReadiness).clamped(to: 0...100)
        }
        if let campusFit = effect.campusFit {
            education.campusFit = (education.campusFit + campusFit).clamped(to: 0...100)
        }
        if let burnoutRisk = effect.burnoutRisk {
            education.burnoutRisk = (education.burnoutRisk + burnoutRisk).clamped(to: 0...100)
        }
        if let disciplineRecord = effect.disciplineRecord {
            education.disciplineRecord = (education.disciplineRecord + disciplineRecord).clamped(to: 0...100)
        }
        if let mentorSupport = effect.mentorSupport {
            education.mentorSupport = (education.mentorSupport + mentorSupport).clamped(to: 0...100)
        }
        if let peerPressure = effect.peerPressure {
            education.peerPressure = (education.peerPressure + peerPressure).clamped(to: 0...100)
        }
        if let setPathway = effect.setPathway {
            education.pathway = setPathway
        }
        if let setStage = effect.setStage {
            education.stage = setStage
        }
        if let setAcademicTrack = effect.setAcademicTrack {
            education.academicTrack = setAcademicTrack
        }
        if let yearsInStage = effect.yearsInStage {
            education.yearsInStage = max(0, education.yearsInStage + yearsInStage)
        }
        if let setStudyFocus = effect.setStudyFocus {
            education.studyFocus = setStudyFocus
        }
        if let addCredential = effect.addCredential, !education.credentials.contains(addCredential) {
            education.credentials.append(addCredential)
        }
        if let hasScholarship = effect.hasScholarship {
            education.hasScholarship = hasScholarship
        }
        education.clamp()
    }

    func applyAction(_ choiceID: ActionChoiceID, player: inout Player, education: inout EducationState) -> DomainYearResult {
        var result = DomainYearResult()

        switch choiceID {
        case .studyHard:
            education.engagement += 10
            education.schoolStanding += 6
            education.activityMomentum += 2
            education.teacherSupport += 4
            education.applicationReadiness += 5
            education.reputationRisk -= 2
            result.coreEffects = CoreStatEffects(happiness: -2)
            result.notes.append(
                DomainNote(
                    title: "Education Focus",
                    text: "You put real effort into school this year.",
                    tags: [.education]
                )
            )
        case .studyConsistently:
            education.engagement += 10
            education.schoolStanding += 8
            education.activityMomentum += 4
            education.teacherSupport += 6
            education.applicationReadiness += 8
            education.burnoutRisk -= 3
            education.reputationRisk -= 2
            result.coreEffects = CoreStatEffects(happiness: -2)
            result.notes.append(
                DomainNote(
                    title: "Education Focus",
                    text: "You studied consistently and built a steadier academic floor under the year.",
                    tags: [.education]
                )
            )
        case .cramAndSurvive:
            education.schoolStanding += 5
            education.attendancePressure -= 2
            education.applicationReadiness += 3
            education.burnoutRisk += 8
            result.healthEffects = HealthEffects(mental: -2, stressManagement: -2)
            result.notes.append(
                DomainNote(
                    title: "Education Focus",
                    text: "You survived school by cramming. The grades held, but your recovery did not.",
                    tags: [.education, .health]
                )
            )
        case .lockInRoutine:
            education.schoolStanding += 5
            education.engagement += 3
            education.attendancePressure -= 6
            education.activityMomentum += 2
            education.teacherSupport += 8
            education.applicationReadiness += 4
            education.reputationRisk -= 2
            result.coreEffects = CoreStatEffects(happiness: -2)
            result.notes.append(
                DomainNote(
                    title: "Education Focus",
                    text: "You locked into a steadier routine and school stopped slipping as easily.",
                    tags: [.education]
                )
            )
        case .joinActivity:
            education.engagement += 6
            education.activityMomentum += 10
            education.schoolBelonging += 10
            education.applicationReadiness += 3
            education.reputationRisk -= 3
            result.relationshipEffects = RelationshipEffects(meetNewFriend: true, friendChange: 3, startDating: nil, partnerChange: nil, loseFriend: nil, breakup: nil)
            result.notes.append(
                DomainNote(
                    title: "Education Focus",
                    text: "Joining an activity gave you more identity, structure, and people around you.",
                    tags: [.education, .relationships]
                )
            )
        case .joinClub:
            education.engagement += 6
            education.activityMomentum += 10
            education.schoolBelonging += 10
            education.applicationReadiness += 5
            education.mentorSupport += 4
            education.reputationRisk -= 3
            result.relationshipEffects = RelationshipEffects(meetNewFriend: true, friendChange: 3, startDating: nil, partnerChange: nil, loseFriend: nil, breakup: nil)
            result.notes.append(
                DomainNote(
                    title: "Education Focus",
                    text: "A club gave you social footing, adult visibility, and one more reason not to drift.",
                    tags: [.education, .relationships]
                )
            )
        case .buildPortfolio:
            education.schoolStanding += 4
            education.applicationReadiness += 10
            education.teacherSupport += 4
            education.mentorSupport += 6
            education.studyFocus = resolvedStudyFocus(for: education)
            result.coreEffects = CoreStatEffects(happiness: -1, smarts: 1)
            result.notes.append(
                DomainNote(
                    title: "Education Focus",
                    text: "You built real proof of direction this year, which helps with applications and future fit.",
                    tags: [.education]
                )
            )
        case .layLow:
            education.engagement -= 5
            education.schoolStanding -= 1
            education.activityMomentum -= 4
            education.schoolBelonging -= 5
            education.attendancePressure -= 4
            education.reputationRisk -= 3
            result.notes.append(
                DomainNote(
                    title: "Education Focus",
                    text: "You kept your head down and lowered the heat, but school stopped building you forward.",
                    tags: [.education]
                )
            )
        case .skipClass:
            education.attendancePressure += 14
            education.schoolStanding -= 8
            education.activityMomentum -= 6
            education.reputationRisk += 10
            education.disciplineRecord -= 10
            education.teacherSupport -= 8
            result.coreEffects = CoreStatEffects(happiness: 1)
            result.notes.append(
                DomainNote(
                    title: "Education Focus",
                    text: "Skipping class gave you short-term relief but raised real school pressure.",
                    tags: [.education]
                )
            )
        case .skipAndDrift:
            education.attendancePressure += 14
            education.schoolStanding -= 8
            education.applicationReadiness -= 8
            education.burnoutRisk += 3
            education.activityMomentum -= 6
            education.reputationRisk += 10
            education.disciplineRecord -= 10
            education.teacherSupport -= 8
            result.coreEffects = CoreStatEffects(happiness: 1)
            result.notes.append(
                DomainNote(
                    title: "Education Focus",
                    text: "You let school drift and the future got blurrier along with your standing.",
                    tags: [.education]
                )
            )
        case .keepThePeace:
            education.schoolBelonging += 2
            education.peerPressure += 5
            education.disciplineRecord += 4
            education.attendancePressure -= 3
            education.applicationReadiness -= 2
            result.notes.append(
                DomainNote(
                    title: "Education Focus",
                    text: "You focused on avoiding conflict and staying out of trouble, even if it did not move your future much.",
                    tags: [.education]
                )
            )
        default:
            return result
        }

        education.clamp()
        return result
    }

    private func resolvedAcademicTrack(for education: EducationState) -> AcademicTrack {
        if education.stage == .tradeTraining { return .vocational }
        if education.schoolStanding >= 78 && education.applicationReadiness >= 60 { return .honors }
        if education.schoolStanding <= 42 || education.attendancePressure >= 62 { return .struggling }
        if education.activityMomentum >= 48 && education.studyFocus == .trades { return .vocational }
        return .general
    }

    private func resolvedStudyFocus(for education: EducationState) -> StudyFocus {
        if education.academicTrack == .vocational { return .trades }
        if education.schoolStanding >= 74 && education.teacherSupport >= 60 { return .technology }
        if education.schoolBelonging >= 60 && education.mentorSupport >= 45 { return .business }
        if education.schoolStanding >= 68 { return .health }
        return .generalStudies
    }

    private func resolveAgeEighteenTransition(
        player: inout Player,
        education: inout EducationState,
        career: inout CareerState,
        finance: FinanceState,
        result: inout DomainYearResult
    ) {
        let graduationBuffer = education.teacherSupport >= 64 ? 6 : 0
        let dropoutExposure = education.schoolBelonging < 36 || education.reputationRisk >= 66 || education.disciplineRecord < 35

        if education.pathway == .student && education.schoolStanding + graduationBuffer >= 62 {
            education.pathway = .graduate
            if !education.credentials.contains("Diploma") {
                education.credentials.append("Diploma")
            }
        } else if education.pathway == .student && education.attendancePressure >= 68 && dropoutExposure {
            education.pathway = .dropout
            education.stage = .inactive
            career.status = .unemployed
            result.notes.append(DomainNote(title: "Education", text: "School slipped out of reach and you dropped out under pressure."))
            return
        }

        if education.pathway == .training || education.academicTrack == .vocational {
            education.stage = .tradeTraining
            education.pathway = .training
            education.academicTrack = .vocational
            education.yearsInStage = 0
            if !education.credentials.contains("Certificate Track") {
                education.credentials.append("Certificate Track")
            }
            career.status = .student
            result.notes.append(DomainNote(title: "Education", text: "You moved into practical training, choosing steadier skills over prestige."))
            return
        }

        let universityReady =
            education.pathway == .graduate &&
            education.schoolStanding >= 70 &&
            education.applicationReadiness >= 58 &&
            education.disciplineRecord >= 45

        if universityReady {
            education.stage = .university
            education.yearsInStage = 0
            education.campusFit = (
                education.campusFit +
                ((education.schoolBelonging - 45) / 8) +
                ((education.mentorSupport - 35) / 10)
            ).clamped(to: 0...100)
            education.studyFocus = education.studyFocus ?? resolvedStudyFocus(for: education)
            career.status = .student
            let routeText: String
            if education.hasScholarship && education.schoolStanding >= 84 {
                routeText = "You entered a high-pressure university track with strong academics but real performance pressure."
            } else if education.hasScholarship {
                routeText = "You entered university with scholarship help, trading money pressure for a heavier expectations game."
            } else if finance.financialStress >= 35 {
                routeText = "You made it into a lower-cost commuter university route. It is viable, but the margin is thin."
            } else {
                routeText = "You entered university, opening more doors but also inviting debt and burnout risk."
            }
            result.notes.append(DomainNote(title: "Education", text: routeText, tags: [.education, .finance]))
            return
        }

        if education.pathway == .graduate && education.applicationReadiness >= 42 {
            education.stage = .adultEd
            education.yearsInStage = 0
            education.studyFocus = education.studyFocus ?? .generalStudies
            career.status = .partTime
            result.notes.append(DomainNote(title: "Education", text: "You left school without a clean university launch and moved into a slower adult-ed route."))
            return
        }

        education.stage = .inactive
        career.status = .unemployed
        result.notes.append(DomainNote(title: "Education", text: "Adulthood arrived without a stable education path. Work and drift now compete for the same space."))
    }

    private func advancePostSecondaryStage(
        player: Player,
        education: inout EducationState,
        career: inout CareerState,
        finance: FinanceState,
        health: HealthState,
        result: inout DomainYearResult
    ) {
        switch education.stage {
        case .university:
            let standingShift =
                ((education.applicationReadiness - 55) / 10) +
                ((education.campusFit - 50) / 12) +
                ((education.mentorSupport - 45) / 14) -
                (max(0, education.burnoutRisk - 45) / 10) -
                (finance.financialStress >= 45 ? 3 : 0)
            education.schoolStanding = (education.schoolStanding + standingShift).clamped(to: 0...100)
            education.campusFit = (
                education.campusFit +
                ((education.schoolBelonging - 48) / 14) -
                (max(0, education.burnoutRisk - 40) / 16) -
                (health.mentalWellness < 50 ? 2 : 0)
            ).clamped(to: 0...100)
            education.burnoutRisk = (
                education.burnoutRisk +
                (finance.financialStress >= 40 ? 4 : 1) +
                (career.status == .partTime ? 4 : 0) -
                (education.hasScholarship ? 1 : 0)
            ).clamped(to: 0...100)

            if education.burnoutRisk >= 78 && education.schoolStanding < 62 {
                education.stage = .adultEd
                education.campusFit = max(35, education.campusFit - 8)
                career.status = .partTime
                result.notes.append(DomainNote(title: "Education", text: "University buckled under cost and burnout, pushing you into a slower recovery path.", tags: [.education, .health, .finance]))
                return
            }

            if education.yearsInStage >= 3 && education.schoolStanding >= 68 {
                education.stage = .inactive
                education.pathway = .graduate
                if !education.credentials.contains("Degree") {
                    education.credentials.append("Degree")
                }
                result.notes.append(DomainNote(title: "Education", text: "You completed university. The degree helps, but it did not erase the pressure it took to get there.", tags: [.education, .career]))
            }
        case .tradeTraining:
            education.schoolStanding = (education.schoolStanding + 3 + ((education.disciplineRecord - 60) / 18)).clamped(to: 0...100)
            education.burnoutRisk = (education.burnoutRisk + (career.status == .partTime ? 3 : 0) - 2).clamped(to: 0...100)
            if education.yearsInStage >= 2 && !education.credentials.contains("Trade Certificate") {
                education.credentials.append("Trade Certificate")
                education.pathway = .training
                result.notes.append(DomainNote(title: "Education", text: "You earned a trade certificate that improves your work prospects."))
            }
            if education.yearsInStage >= 2 {
                education.stage = .inactive
            }
        case .adultEd:
            education.applicationReadiness = (education.applicationReadiness + 6).clamped(to: 0...100)
            education.schoolStanding = (education.schoolStanding + 2).clamped(to: 0...100)
            education.burnoutRisk = (education.burnoutRisk - 2).clamped(to: 0...100)
            if education.applicationReadiness >= 62 && education.schoolStanding >= 64 && player.age <= 22 {
                education.stage = .university
                education.yearsInStage = 0
                career.status = .student
                result.notes.append(DomainNote(title: "Education", text: "A slower rebuild paid off and reopened a viable college path.", tags: [.education, .career]))
            }
        case .secondary, .inactive:
            break
        }
    }
}

struct HousingSystem {
    func advanceYear(input: HousingDomainSnapshot, housing: inout HousingState) -> DomainYearResult {
        advanceYear(housing: &housing, player: input.player, finance: input.finance, assets: input.assets)
    }

    func advanceYear(housing: inout HousingState, player: Player, finance: FinanceState, assets: AssetState) -> DomainYearResult {
        var result = DomainYearResult()
        if assets.ownsHome {
            housing.livingArrangement = .ownerOccupied
            housing.hasRoommate = false
            housing.housingStability = (housing.housingStability + (finance.financialStress >= 55 ? -4 : 2)).clamped(to: 0...100)
            housing.housingCostBand = baselineCostBand(for: .ownerOccupied, ownsHome: true)
            housing.clamp()
            return result
        }

        if player.age >= 18 && housing.livingArrangement == .familyHome && finance.lastYearBalanceDelta < 0 {
            housing.livingArrangement = .roommates
            housing.hasRoommate = true
            housing.housingStability = max(housing.housingStability - 4, 0)
            result.notes.append(DomainNote(title: "Housing", text: "Money pressure pushed you into a shared living setup."))
        }

        if finance.financialStress >= 55 {
            housing.housingStability = (housing.housingStability - 6).clamped(to: 0...100)
        } else if finance.lastYearBalanceDelta > 0 {
            housing.housingStability = (housing.housingStability + 3).clamped(to: 0...100)
        }

        if housing.housingStability < 30 && housing.livingArrangement != .couchSurfing {
            housing.livingArrangement = .couchSurfing
            housing.hasRoommate = false
            result.notes.append(DomainNote(title: "Housing", text: "Housing instability left you bouncing between temporary places."))
        }

        housing.housingCostBand = baselineCostBand(for: housing.livingArrangement, ownsHome: false)
        housing.clamp()
        return result
    }

    func apply(effect: HousingEffects, housing: inout HousingState) {
        if let setArrangement = effect.setArrangement {
            housing.livingArrangement = setArrangement
        }
        if let hasRoommate = effect.hasRoommate {
            housing.hasRoommate = hasRoommate
        }
        if let costBandDelta = effect.costBandDelta {
            housing.housingCostBand = (housing.housingCostBand + costBandDelta).clamped(to: 0...100)
        }
        if let stabilityDelta = effect.stabilityDelta {
            housing.housingStability = (housing.housingStability + stabilityDelta).clamped(to: 0...100)
        }
        housing.clamp()
    }

    private func baselineCostBand(for arrangement: LivingArrangement, ownsHome: Bool) -> Int {
        if ownsHome { return 20 }
        switch arrangement {
        case .familyHome: return 18
        case .roommates: return 36
        case .soloRenting: return 55
        case .ownerOccupied: return 22
        case .couchSurfing: return 8
        }
    }
}

struct ActionSystem {
    private let educationSystem: EducationSystem
    private let careerSystem: CareerSystem
    private let specialCareerSystem: SpecialCareerSystem
    private let crimeSystem: CrimeSystem
    private let relationshipSystem: RelationshipSystem
    private let familySystem: FamilySystem
    private let financeSystem: FinanceSystem
    private let healthSystem: HealthSystem
    private let effectApplier: DomainEffectApplier

    init(
        educationSystem: EducationSystem = EducationSystem(),
        careerSystem: CareerSystem = CareerSystem(),
        specialCareerSystem: SpecialCareerSystem = SpecialCareerSystem(),
        crimeSystem: CrimeSystem = CrimeSystem(),
        familySystem: FamilySystem = FamilySystem(),
        financeSystem: FinanceSystem = FinanceSystem(),
        relationshipSystem: RelationshipSystem = RelationshipSystem(),
        healthSystem: HealthSystem = HealthSystem(),
        effectApplier: DomainEffectApplier = DomainEffectApplier()
    ) {
        self.educationSystem = educationSystem
        self.careerSystem = careerSystem
        self.specialCareerSystem = specialCareerSystem
        self.crimeSystem = crimeSystem
        self.familySystem = familySystem
        self.financeSystem = financeSystem
        self.relationshipSystem = relationshipSystem
        self.healthSystem = healthSystem
        self.effectApplier = effectApplier
    }

    func apply(
        actions: [PlayerYearAction],
        state: inout GameState,
        world: WorldSnapshot? = nil,
        clearsPendingActions: Bool = true
    ) -> DomainYearResult {
        var result = DomainYearResult()
        for action in actions {
            let actionResult: DomainYearResult

            switch action.domain {
            case .education:
                actionResult = educationSystem.applyAction(action.choiceID, player: &state.player, education: &state.education)
            case .career:
                if specialCareerSystem.handles(action.choiceID) {
                    actionResult = specialCareerSystem.applyAction(action.choiceID, player: &state.player, career: &state.career, specialCareer: &state.specialCareer)
                } else {
                    actionResult = careerSystem.applyAction(action.choiceID, player: &state.player, career: &state.career)
                }
            case .crime:
                actionResult = crimeSystem.applyAction(action.choiceID, player: &state.player, career: &state.career, crime: &state.crime)
            case .finance:
                actionResult = financeSystem.applyAction(action.choiceID, finance: &state.finance, player: &state.player)
            case .relationships:
                actionResult = relationshipSystem.applyAction(action.choiceID, player: &state.player, relationships: &state.relationships, family: &state.family)
            case .health:
                actionResult = healthSystem.applyAction(action.choiceID, player: &state.player, health: &state.healthProfile)
            }

            effectApplier.apply(
                result: actionResult,
                to: &state,
                trajectorySystem: TrajectorySystem(),
                educationSystem: educationSystem,
                careerSystem: careerSystem,
                specialCareerSystem: specialCareerSystem,
                crimeSystem: crimeSystem,
                financeSystem: financeSystem,
                relationshipSystem: relationshipSystem,
                healthSystem: healthSystem,
                housingSystem: HousingSystem()
            )
            merge(actionResult, into: &result)
        }

        state.education.clamp()
        state.career.clamp()
        state.specialCareer.clamp()
        state.crime.clamp()
        state.healthProfile.clamp()
        state.housing.clamp()
        state.player.clampStats()
        if clearsPendingActions {
            state.pendingActions = []
        }
        return result
    }

    private func merge(_ source: DomainYearResult, into target: inout DomainYearResult) {
        target.notes.append(contentsOf: source.notes)
        target.events.append(contentsOf: source.events)
    }
}

enum CareerCatalog {
    static let roles: [CareerRoleDefinition] = [
        CareerRoleDefinition(id: "market_runner", title: "Market Runner", profile: .serviceFrontline, status: .partTime, level: 1, annualIncome: 1_800, minAge: 14, nextRoleID: "shop_clerk", primaryExperienceTag: .service),
        CareerRoleDefinition(id: "shop_clerk", title: "Shop Clerk", profile: .serviceFrontline, status: .partTime, level: 2, annualIncome: 4_200, minAge: 16, nextRoleID: "cashier", primaryExperienceTag: .service),
        CareerRoleDefinition(id: "cashier", title: "Cashier", profile: .serviceFrontline, status: .fullTime, level: 3, annualIncome: 22_000, minAge: 18, nextRoleID: "server", requiredCredentials: ["Diploma"], primaryExperienceTag: .service, secondaryExperienceTags: [.sales]),
        CareerRoleDefinition(id: "server", title: "Server", profile: .serviceFrontline, status: .fullTime, level: 3, annualIncome: 24_000, minAge: 18, nextRoleID: "shift_lead", minimumYearsWorked: 1, primaryExperienceTag: .service, secondaryExperienceTags: [.sales]),
        CareerRoleDefinition(id: "front_desk_associate", title: "Front Desk Associate", profile: .serviceFrontline, status: .fullTime, level: 3, annualIncome: 23_000, minAge: 18, nextRoleID: "guest_services_supervisor", primaryExperienceTag: .service, secondaryExperienceTags: [.admin]),
        CareerRoleDefinition(id: "shift_lead", title: "Shift Lead", profile: .serviceFrontline, status: .fullTime, level: 4, annualIncome: 31_000, minAge: 20, nextRoleID: "store_manager", minimumYearsWorked: 2, primaryExperienceTag: .service, secondaryExperienceTags: [.management], isManagementRole: true),
        CareerRoleDefinition(id: "guest_services_supervisor", title: "Guest Services Supervisor", profile: .serviceFrontline, status: .fullTime, level: 4, annualIncome: 33_000, minAge: 20, nextRoleID: "service_manager", minimumYearsWorked: 2, primaryExperienceTag: .service, secondaryExperienceTags: [.management], isManagementRole: true),
        CareerRoleDefinition(id: "store_manager", title: "Store Manager", profile: .serviceFrontline, status: .fullTime, level: 5, annualIncome: 43_000, minAge: 23, nextRoleID: nil, minimumYearsWorked: 4, primaryExperienceTag: .service, secondaryExperienceTags: [.management, .sales], bridgeTags: [.management, .sales], isManagementRole: true),
        CareerRoleDefinition(id: "service_manager", title: "Service Manager", profile: .serviceFrontline, status: .fullTime, level: 5, annualIncome: 44_000, minAge: 23, nextRoleID: nil, minimumYearsWorked: 4, primaryExperienceTag: .service, secondaryExperienceTags: [.management], bridgeTags: [.management], isManagementRole: true),

        CareerRoleDefinition(id: "warehouse_loader", title: "Warehouse Loader", profile: .physicalLabor, status: .fullTime, level: 3, annualIncome: 25_000, minAge: 18, nextRoleID: "delivery_driver", primaryExperienceTag: .labor),
        CareerRoleDefinition(id: "delivery_driver", title: "Delivery Driver", profile: .physicalLabor, status: .fullTime, level: 3, annualIncome: 30_000, minAge: 19, nextRoleID: "site_operator", minimumYearsWorked: 1, primaryExperienceTag: .labor, secondaryExperienceTags: [.service]),
        CareerRoleDefinition(id: "site_operator", title: "Site Operator", profile: .physicalLabor, status: .fullTime, level: 4, annualIncome: 38_000, minAge: 20, nextRoleID: "equipment_operator", minimumYearsWorked: 2, primaryExperienceTag: .labor, secondaryExperienceTags: [.technical]),
        CareerRoleDefinition(id: "equipment_operator", title: "Equipment Operator", profile: .physicalLabor, status: .fullTime, level: 4, annualIncome: 43_000, minAge: 21, nextRoleID: "shift_foreman", requiredCredentials: ["Trade Certificate"], minimumYearsWorked: 2, primaryExperienceTag: .labor, secondaryExperienceTags: [.technical]),
        CareerRoleDefinition(id: "shift_foreman", title: "Shift Foreman", profile: .physicalLabor, status: .fullTime, level: 5, annualIncome: 50_000, minAge: 23, nextRoleID: nil, minimumYearsWorked: 4, primaryExperienceTag: .labor, secondaryExperienceTags: [.management], bridgeTags: [.management], isManagementRole: true),

        CareerRoleDefinition(id: "receptionist", title: "Receptionist", profile: .stableAdmin, status: .fullTime, level: 3, annualIncome: 23_000, minAge: 18, nextRoleID: "office_assistant", primaryExperienceTag: .admin, secondaryExperienceTags: [.service]),
        CareerRoleDefinition(id: "office_assistant", title: "Office Assistant", profile: .stableAdmin, status: .fullTime, level: 3, annualIncome: 24_000, minAge: 18, nextRoleID: "operations_coordinator", primaryExperienceTag: .admin),
        CareerRoleDefinition(id: "operations_coordinator", title: "Operations Coordinator", profile: .stableAdmin, status: .fullTime, level: 4, annualIncome: 36_000, minAge: 20, nextRoleID: "team_lead", minimumYearsWorked: 2, primaryExperienceTag: .admin, secondaryExperienceTags: [.management]),
        CareerRoleDefinition(id: "team_lead", title: "Team Lead", profile: .stableAdmin, status: .fullTime, level: 5, annualIncome: 51_000, minAge: 23, nextRoleID: "operations_manager", minimumYearsWorked: 4, primaryExperienceTag: .admin, secondaryExperienceTags: [.management], bridgeTags: [.management], isManagementRole: true),
        CareerRoleDefinition(id: "operations_manager", title: "Operations Manager", profile: .stableAdmin, status: .fullTime, level: 6, annualIncome: 62_000, minAge: 26, nextRoleID: nil, requiredCredentials: ["Diploma"], minimumYearsWorked: 6, primaryExperienceTag: .admin, secondaryExperienceTags: [.management], bridgeTags: [.management], isManagementRole: true),

        CareerRoleDefinition(id: "trade_apprentice", title: "Trade Apprentice", profile: .physicalLabor, status: .fullTime, level: 3, annualIncome: 29_000, minAge: 18, nextRoleID: "field_technician", requiredCredentials: ["Certificate Track"], primaryExperienceTag: .technical, secondaryExperienceTags: [.labor]),
        CareerRoleDefinition(id: "field_technician", title: "Field Technician", profile: .physicalLabor, status: .fullTime, level: 4, annualIncome: 42_000, minAge: 20, nextRoleID: "journeyman", requiredCredentials: ["Trade Certificate"], minimumYearsWorked: 2, primaryExperienceTag: .technical, secondaryExperienceTags: [.labor]),
        CareerRoleDefinition(id: "journeyman", title: "Journeyman", profile: .physicalLabor, status: .fullTime, level: 5, annualIncome: 58_000, minAge: 23, nextRoleID: "contractor", requiredCredentials: ["Trade Certificate"], minimumYearsWorked: 4, primaryExperienceTag: .technical, secondaryExperienceTags: [.labor], bridgeTags: [.technical]),
        CareerRoleDefinition(id: "contractor", title: "Contractor", profile: .physicalLabor, status: .fullTime, level: 6, annualIncome: 72_000, minAge: 27, nextRoleID: nil, requiredCredentials: ["Trade Certificate"], minimumYearsWorked: 7, primaryExperienceTag: .technical, secondaryExperienceTags: [.management, .sales], bridgeTags: [.technical, .management, .sales], isManagementRole: true),

        CareerRoleDefinition(id: "care_aide", title: "Care Aide", profile: .serviceFrontline, status: .fullTime, level: 3, annualIncome: 27_000, minAge: 18, nextRoleID: "medical_assistant", requiredCredentials: ["Diploma"], primaryExperienceTag: .healthcare, secondaryExperienceTags: [.service]),
        CareerRoleDefinition(id: "medical_assistant", title: "Medical Assistant", profile: .stableAdmin, status: .fullTime, level: 4, annualIncome: 38_000, minAge: 20, nextRoleID: "nurse_track", requiredCredentials: ["Certificate Track"], minimumYearsWorked: 2, primaryExperienceTag: .healthcare, secondaryExperienceTags: [.admin]),
        CareerRoleDefinition(id: "nurse_track", title: "Nurse Track", profile: .credentialedProfessional, status: .fullTime, level: 5, annualIncome: 64_000, minAge: 23, nextRoleID: nil, requiredCredentials: ["Degree"], minimumYearsWorked: 3, primaryExperienceTag: .healthcare, secondaryExperienceTags: [.technical], bridgeTags: [.healthcare]),

        CareerRoleDefinition(id: "help_desk", title: "Help Desk Technician", profile: .credentialedProfessional, status: .fullTime, level: 3, annualIncome: 34_000, minAge: 18, nextRoleID: "junior_analyst", requiredCredentials: ["Diploma"], primaryExperienceTag: .technical, secondaryExperienceTags: [.service]),
        CareerRoleDefinition(id: "junior_analyst", title: "Junior Analyst", profile: .credentialedProfessional, status: .fullTime, level: 3, annualIncome: 32_000, minAge: 18, nextRoleID: "systems_specialist", requiredCredentials: ["Degree"], primaryExperienceTag: .technical, secondaryExperienceTags: [.admin], bridgeTags: [.technical]),
        CareerRoleDefinition(id: "systems_specialist", title: "Systems Specialist", profile: .credentialedProfessional, status: .fullTime, level: 4, annualIncome: 48_000, minAge: 21, nextRoleID: "practice_lead", requiredCredentials: ["Degree"], minimumYearsWorked: 2, primaryExperienceTag: .technical, secondaryExperienceTags: [.admin], bridgeTags: [.technical]),
        CareerRoleDefinition(id: "practice_lead", title: "Practice Lead", profile: .credentialedProfessional, status: .fullTime, level: 5, annualIncome: 68_000, minAge: 24, nextRoleID: nil, requiredCredentials: ["Degree"], minimumYearsWorked: 5, primaryExperienceTag: .technical, secondaryExperienceTags: [.management], bridgeTags: [.technical, .management], isManagementRole: true),

        CareerRoleDefinition(id: "content_assistant", title: "Content Assistant", profile: .creativeFreelance, status: .partTime, level: 3, annualIncome: 19_000, minAge: 18, nextRoleID: "freelance_creator", primaryExperienceTag: .creative, secondaryExperienceTags: [.admin]),
        CareerRoleDefinition(id: "freelance_creator", title: "Freelance Creator", profile: .creativeFreelance, status: .fullTime, level: 4, annualIncome: 28_000, minAge: 20, nextRoleID: "producer", minimumYearsWorked: 2, primaryExperienceTag: .creative, secondaryExperienceTags: [.sales], bridgeTags: [.creative]),
        CareerRoleDefinition(id: "producer", title: "Producer", profile: .creativeFreelance, status: .fullTime, level: 5, annualIncome: 38_000, minAge: 23, nextRoleID: "creative_consultant", minimumYearsWorked: 4, primaryExperienceTag: .creative, secondaryExperienceTags: [.management, .sales], bridgeTags: [.creative, .management], isManagementRole: true),
        CareerRoleDefinition(id: "creative_consultant", title: "Creative Consultant", profile: .creativeFreelance, status: .fullTime, level: 5, annualIncome: 44_000, minAge: 24, nextRoleID: nil, minimumYearsWorked: 5, primaryExperienceTag: .creative, secondaryExperienceTags: [.sales], bridgeTags: [.creative, .sales]),

        CareerRoleDefinition(id: "sales_associate", title: "Sales Associate", profile: .serviceFrontline, status: .fullTime, level: 3, annualIncome: 26_000, minAge: 18, nextRoleID: "account_rep", primaryExperienceTag: .sales, secondaryExperienceTags: [.service]),
        CareerRoleDefinition(id: "account_rep", title: "Account Rep", profile: .stableAdmin, status: .fullTime, level: 4, annualIncome: 42_000, minAge: 21, nextRoleID: "sales_manager", minimumYearsWorked: 2, primaryExperienceTag: .sales, secondaryExperienceTags: [.admin], bridgeTags: [.sales]),
        CareerRoleDefinition(id: "sales_manager", title: "Sales Manager", profile: .stableAdmin, status: .fullTime, level: 5, annualIncome: 66_000, minAge: 25, nextRoleID: nil, minimumYearsWorked: 5, primaryExperienceTag: .sales, secondaryExperienceTags: [.management], bridgeTags: [.sales, .management], isManagementRole: true)
    ]

    struct ProfileDefinition: Equatable {
        var profile: CareerProfile
        var firstRoleID: String
        var burnoutGain: Int
        var schedulePressureGain: Int
        var relationshipSpilloverGain: Int
        var incomeSwingRange: ClosedRange<Int>
        var mentalTilt: Int
        var physicalTilt: Int
        var promotionThresholdDelta: Int
        var baseJobSecurity: Int
        var baseManagerFriction: Int
        var baseScheduleControl: Int
    }

    static let profileDefinitions: [CareerProfile: ProfileDefinition] = [
        .stableAdmin: ProfileDefinition(profile: .stableAdmin, firstRoleID: "office_assistant", burnoutGain: 4, schedulePressureGain: 5, relationshipSpilloverGain: 3, incomeSwingRange: -600...1_000, mentalTilt: -2, physicalTilt: 0, promotionThresholdDelta: 0, baseJobSecurity: 68, baseManagerFriction: 38, baseScheduleControl: 56),
        .physicalLabor: ProfileDefinition(profile: .physicalLabor, firstRoleID: "warehouse_loader", burnoutGain: 6, schedulePressureGain: 4, relationshipSpilloverGain: 3, incomeSwingRange: -400...1_400, mentalTilt: -1, physicalTilt: -4, promotionThresholdDelta: 2, baseJobSecurity: 52, baseManagerFriction: 30, baseScheduleControl: 34),
        .serviceFrontline: ProfileDefinition(profile: .serviceFrontline, firstRoleID: "front_desk_associate", burnoutGain: 5, schedulePressureGain: 6, relationshipSpilloverGain: 5, incomeSwingRange: -800...1_100, mentalTilt: -3, physicalTilt: -1, promotionThresholdDelta: 1, baseJobSecurity: 46, baseManagerFriction: 42, baseScheduleControl: 28),
        .creativeFreelance: ProfileDefinition(profile: .creativeFreelance, firstRoleID: "content_assistant", burnoutGain: 5, schedulePressureGain: 4, relationshipSpilloverGain: 4, incomeSwingRange: -2_400...3_200, mentalTilt: -2, physicalTilt: 0, promotionThresholdDelta: 3, baseJobSecurity: 36, baseManagerFriction: 34, baseScheduleControl: 52),
        .credentialedProfessional: ProfileDefinition(profile: .credentialedProfessional, firstRoleID: "junior_analyst", burnoutGain: 4, schedulePressureGain: 6, relationshipSpilloverGain: 4, incomeSwingRange: -500...1_600, mentalTilt: -3, physicalTilt: 0, promotionThresholdDelta: -2, baseJobSecurity: 72, baseManagerFriction: 54, baseScheduleControl: 42)
    ]

    static func definition(for roleID: String?) -> CareerRoleDefinition? {
        guard let roleID else { return nil }
        return roles.first { $0.id == roleID }
    }

    static func definition(for profile: CareerProfile) -> ProfileDefinition {
        profileDefinitions[profile] ?? profileDefinitions[.stableAdmin]!
    }

    static func firstRole(for profile: CareerProfile) -> CareerRoleDefinition? {
        definition(for: definition(for: profile).firstRoleID)
    }

    static func qualifiedRoles(
        for player: Player,
        career: CareerState,
        education: EducationState,
        childhoodDossier: ChildhoodDossier? = nil
    ) -> [CareerRoleDefinition] {
        roles.filter { qualificationIssue(for: $0, player: player, career: career, education: education, childhoodDossier: childhoodDossier) == nil }
    }

    static func lockedRoles(
        for player: Player,
        career: CareerState,
        education: EducationState,
        childhoodDossier: ChildhoodDossier? = nil
    ) -> [(CareerRoleDefinition, String)] {
        roles.compactMap { role in
            qualificationIssue(for: role, player: player, career: career, education: education, childhoodDossier: childhoodDossier).map { (role, $0) }
        }
    }

    static func qualificationIssue(
        for role: CareerRoleDefinition,
        player: Player,
        career: CareerState,
        education: EducationState,
        childhoodDossier: ChildhoodDossier? = nil
    ) -> String? {
        if player.age < role.minAge {
            return "Age \(role.minAge)+"
        }
        if career.yearsWorked < role.minimumYearsWorked {
            return "\(role.minimumYearsWorked) work years"
        }
        if let missingCredential = role.requiredCredentials.first(where: { !education.credentials.contains($0) }) {
            return missingCredential
        }
        if role.level >= 5 {
            let laneExperience = career.experience(for: role.primaryExperienceTag)
            let adjacentExperience = role.secondaryExperienceTags.map { career.experience(for: $0) }.max() ?? 0
            if max(laneExperience, adjacentExperience) < max(2, role.level - 3) {
                return "\(role.primaryExperienceTag.shortLabel) experience"
            }
        }
        if role.profile == .credentialedProfessional,
           role.requiredCredentials.isEmpty == false,
           (childhoodDossier?.aptitudes.technical ?? player.smarts) < 42,
           player.smarts < 54 {
            return "Technical aptitude"
        }
        return nil
    }

    static func bestQualifiedRole(
        for player: Player,
        career: CareerState,
        education: EducationState,
        preferredProfile: CareerProfile,
        childhoodDossier: ChildhoodDossier? = nil
    ) -> CareerRoleDefinition? {
        qualifiedRoles(for: player, career: career, education: education, childhoodDossier: childhoodDossier)
            .sorted {
                roleScore($0, player: player, career: career, education: education, preferredProfile: preferredProfile, childhoodDossier: childhoodDossier) >
                roleScore($1, player: player, career: career, education: education, preferredProfile: preferredProfile, childhoodDossier: childhoodDossier)
            }
            .first
    }

    private static func roleScore(
        _ role: CareerRoleDefinition,
        player: Player,
        career: CareerState,
        education: EducationState,
        preferredProfile: CareerProfile,
        childhoodDossier: ChildhoodDossier?
    ) -> Int {
        var score = role.level * 12 + role.annualIncome / 4_000
        if role.profile == preferredProfile { score += 18 }
        score += min(12, career.experience(for: role.primaryExperienceTag) * 3)
        score += role.secondaryExperienceTags.map { min(6, career.experience(for: $0) * 2) }.reduce(0, +)
        if education.credentials.contains("Degree"), role.profile == .credentialedProfessional { score += 10 }
        if education.credentials.contains("Trade Certificate"), role.primaryExperienceTag == .technical { score += 10 }
        if player.traits.contains(.disciplined), role.profile == .stableAdmin || role.profile == .credentialedProfessional { score += 6 }
        if player.traits.contains(.charismatic), role.primaryExperienceTag == .sales || role.primaryExperienceTag == .creative { score += 6 }
        score += aptitudeScore(for: role, player: player, childhoodDossier: childhoodDossier) / 12
        return score
    }

    private static func aptitudeScore(for role: CareerRoleDefinition, player: Player, childhoodDossier: ChildhoodDossier?) -> Int {
        guard let aptitudes = childhoodDossier?.aptitudes else {
            switch role.primaryExperienceTag {
            case .technical, .healthcare: return player.smarts
            case .creative, .sales, .service, .admin: return player.happiness
            case .labor: return player.health
            case .management: return max(player.smarts, player.happiness)
            }
        }
        switch role.primaryExperienceTag {
        case .service, .sales, .admin, .management:
            return aptitudes.social
        case .labor:
            return aptitudes.physical
        case .technical:
            return max(aptitudes.technical, aptitudes.analytical)
        case .healthcare:
            return max(aptitudes.social, aptitudes.analytical)
        case .creative:
            return aptitudes.creative
        }
    }
}

// CareerSystem continues below exactly as before; kept in this extracted systems file to preserve behavior.
struct CareerSystem {
    let balanceProfile: SimulationBalanceProfile

    init(balanceProfile: SimulationBalanceProfile = .playableRealismV1) {
        self.balanceProfile = balanceProfile
    }

    func advanceYear(input: CareerDomainSnapshot, player: inout Player, career: inout CareerState) -> DomainYearResult {
        advanceYear(
            player: &player,
            career: &career,
            education: input.education,
            health: input.health,
            relationships: input.relationships,
            childhoodDossier: input.childhoodDossier
        )
    }

    func advanceYear(
        player: inout Player,
        career: inout CareerState,
        education: EducationState,
        health: HealthState,
        relationships: RelationshipState,
        childhoodDossier: ChildhoodDossier? = nil
    ) -> DomainYearResult {
        var result = DomainYearResult()
        normalizeStatus(for: &career, age: player.age)
        refreshWorkConditions(for: &career)
        decayOpportunityDoor(on: &career)

        let reputationLift = max(0, relationships.publicReputation - 55) / 12
        let rumorDrag = max(0, relationships.activeRumorHeat - 40) / 9
        let tensionDrag = relationships.activeTensionCount * 2
        let performanceShift =
            ((player.smarts - 50) / 8) +
            ((player.happiness - 50) / 14) +
            ((health.physicalWellness - 50) / 14) +
            ((education.schoolStanding - 50) / 18) +
            reputationLift -
            rumorDrag -
            tensionDrag
        career.performance = (career.performance + performanceShift).clamped(to: 0...100)

        if relationships.publicReputation >= 68 {
            career.jobSecurity = (career.jobSecurity + 1).clamped(to: 0...100)
        }
        if relationships.activeRumorHeat >= 55 {
            career.managerFriction = (career.managerFriction + 3).clamped(to: 0...100)
            career.jobSecurity = (career.jobSecurity - 2).clamped(to: 0...100)
            result.notes.append(
                DomainNote(
                    title: "Rumor Pressure",
                    text: "Social noise followed you into work and made professional interactions feel more fragile than usual.",
                    tags: [.career, .relationships]
                )
            )
        }
        if relationships.activeTensionCount > 0 {
            career.relationshipSpillover = (career.relationshipSpillover + relationships.activeTensionCount * 2).clamped(to: 0...100)
        }
        applyProfileDrift(to: &career, result: &result)

        if let role = CareerCatalog.definition(for: career.roleID) {
            career.profile = role.profile
            career.status = role.status
            career.level = role.level
            career.annualIncome = adjustedIncome(for: role, career: career, player: player)
            career.yearsWorked += 1
            accrueExperience(from: role, on: &career)
            career.unemployedYears = 0
            result.notes.append(DomainNote(title: "Career", text: "Your \(role.title) role is still carrying the year, but the way it presses on your life is getting harder to ignore.", tags: [.career]))

            let promotionThreshold = adjustedPromotionThreshold(for: career)
            if career.performance >= promotionThreshold,
               career.yearsWorked >= 2,
               let nextRole = CareerCatalog.definition(for: role.nextRoleID),
               CareerCatalog.qualificationIssue(for: nextRole, player: player, career: career, education: education, childhoodDossier: childhoodDossier) == nil {
                career.roleID = nextRole.id
                career.profile = nextRole.profile
                career.status = nextRole.status
                career.level = nextRole.level
                career.annualIncome = adjustedIncome(for: nextRole, career: career, player: player)
                career.performance = 70
                career.retrainingProgress = max(0, career.retrainingProgress - 1)
                career.burnout += max(2, nextRole.level - role.level + 1)
                career.schedulePressure += max(2, nextRole.level)
                career.relationshipSpillover += max(1, nextRole.level - 1)
                career.managerFriction += 2
                career.scheduleControl = max(0, career.scheduleControl - 2)
                if career.activeOpportunityDoor == .internalPromotionTrack {
                    clearOpportunityDoor(on: &career)
                }
                result.notes.append(DomainNote(title: "Promotion", text: "Your strong year converted into a promotion to \(nextRole.title), but it also raises the standard the rest of your life has to absorb.", tags: [.career]))
            } else if career.performance <= max(20, 28 - career.jobSecurity / 8) {
                result.notes.append(DomainNote(title: "Career Setback", text: "Poor performance and accumulated strain finally cost you your \(role.title) role.", tags: [.career, .health]))
                career.roleID = nil
                career.annualIncome = 0
                career.level = 0
                career.status = player.age < 18 ? .student : .unemployed
                career.unemployedYears = player.age >= 18 ? 1 : 0
                career.schedulePressure = max(8, career.schedulePressure - 8)
                career.relationshipSpillover = max(6, career.relationshipSpillover - 6)
                career.jobSecurity = max(0, career.jobSecurity - 18)
                clearOpportunityDoor(on: &career)
            }
        } else if player.age >= 18 {
            if education.stage == .university || education.stage == .adultEd || education.stage == .tradeTraining {
                career.status = education.stage == .adultEd ? .partTime : .student
                career.annualIncome = 0
                career.level = 0
            } else if education.pathway == .graduate || education.pathway == .training {
                let preferredProfile = startingProfile(for: player, career: career, education: education)
                career.profile = preferredProfile
                if let role = CareerCatalog.bestQualifiedRole(for: player, career: career, education: education, preferredProfile: preferredProfile, childhoodDossier: childhoodDossier) {
                    assign(role, to: &career, minimumPerformance: education.pathway == .training ? 58 : 60)
                    result.notes.append(DomainNote(title: "Career", text: "Your background converted into \(role.title), a regular role that now passively carries income through the year.", tags: [.career, .finance]))
                } else {
                    career.status = .partTime
                }
            } else {
                let fallbackProfile = player.health >= 62 ? CareerProfile.physicalLabor : CareerProfile.serviceFrontline
                if let role = CareerCatalog.bestQualifiedRole(for: player, career: career, education: education, preferredProfile: fallbackProfile, childhoodDossier: childhoodDossier) {
                    assign(role, to: &career, minimumPerformance: 52)
                    result.notes.append(DomainNote(title: "Career", text: "No clean launch arrived, but \(role.title) became the income floor for the year.", tags: [.career, .finance]))
                } else {
                    career.status = .unemployed
                    career.annualIncome = 0
                    career.level = 0
                    career.unemployedYears += 1
                    career.jobSecurity = max(20, career.jobSecurity - 4)
                    if career.unemployedYears == 1 {
                        result.notes.append(DomainNote(title: "Career", text: "You entered adulthood without a stable job and are currently unemployed."))
                    }
                }
            }
        } else {
            career.status = .student
            career.annualIncome = 0
            career.level = 0
        }

        refreshIdentity(on: &career)
        updateOpportunityDoor(on: &career, player: player, education: education)
        career.clamp()
        return result
    }

    func apply(effect: CareerEffects, player: inout Player, career: inout CareerState, finance: inout FinanceState) {
        if let setStatus = effect.setStatus {
            career.status = setStatus
        }

        if let setProfile = effect.setProfile {
            career.profile = setProfile
            if let firstRole = CareerCatalog.bestQualifiedRole(for: player, career: career, education: EducationState(), preferredProfile: setProfile) {
                assign(firstRole, to: &career, minimumPerformance: 55)
            }
            refreshWorkConditions(for: &career, force: true)
        }

        if let roleID = effect.setRoleID, let role = CareerCatalog.definition(for: roleID), player.age >= role.minAge {
            assign(role, to: &career, minimumPerformance: 55)
            career.unemployedYears = 0
        }

        if effect.promote == true, let current = CareerCatalog.definition(for: career.roleID), let nextRole = CareerCatalog.definition(for: current.nextRoleID), player.age >= nextRole.minAge {
            career.roleID = nextRole.id
            career.profile = nextRole.profile
            career.status = nextRole.status
            career.level = nextRole.level
            career.annualIncome = nextRole.annualIncome
            career.performance = max(career.performance, 68)
        }

        if let performance = effect.performance {
            career.performance = (career.performance + performance).clamped(to: 0...100)
        }

        if let yearsWorked = effect.yearsWorked {
            career.yearsWorked = max(0, career.yearsWorked + yearsWorked)
        }

        if let burnout = effect.burnout {
            career.burnout += burnout
        }
        if let schedulePressure = effect.schedulePressure {
            career.schedulePressure += schedulePressure
        }
        if let relationshipSpillover = effect.relationshipSpillover {
            career.relationshipSpillover += relationshipSpillover
        }
        if let jobSecurity = effect.jobSecurity {
            career.jobSecurity += jobSecurity
        }
        if let managerFriction = effect.managerFriction {
            career.managerFriction += managerFriction
        }
        if let scheduleControl = effect.scheduleControl {
            career.scheduleControl += scheduleControl
        }
        if let retrainingProgress = effect.retrainingProgress {
            career.retrainingProgress += retrainingProgress
        }
        if let target = effect.setRetrainingTargetProfile {
            career.retrainingTargetProfile = target
        }
        if let door = effect.setOpenDoor {
            setOpportunityDoor(door, on: &career)
        }
        if effect.clearOpenDoor == true {
            clearOpportunityDoor(on: &career)
        }

        finance.cashOnHand += effect.incomeBonus ?? 0

        if effect.loseJob == true {
            career.roleID = nil
            career.level = 0
            career.annualIncome = 0
            career.status = player.age < 18 ? .student : .unemployed
            career.unemployedYears = player.age < 18 ? 0 : 1
            career.jobSecurity = max(0, career.jobSecurity - 16)
            clearOpportunityDoor(on: &career)
        }

        normalizeStatus(for: &career, age: player.age)
        refreshIdentity(on: &career)
        career.clamp()
    }

    func applyAction(_ choiceID: ActionChoiceID, player: inout Player, career: inout CareerState) -> DomainYearResult {
        var result = DomainYearResult()

        switch choiceID {
        case .workHard:
            career.performance += 8
            career.burnout += max(4, 10 - career.scheduleControl / 20)
            career.schedulePressure += 6
            career.relationshipSpillover += 4
            career.managerFriction += 1
            career.ambitionYears += 1
            result.healthEffects = HealthEffects(physical: nil, mental: -3, exercise: nil, nutrition: nil, stressManagement: -2, addCondition: nil, removeCondition: nil, hasPrimaryCare: nil)
            result.relationshipEffects = RelationshipEffects(meetNewFriend: nil, friendChange: -1, startDating: nil, partnerChange: -1, setPartnerStage: nil, setCohabiting: nil, commitmentAlignmentChange: -2, loseFriend: nil, breakup: nil)
            result.notes.append(
                DomainNote(
                    title: "Career Focus",
                    text: "You leaned into work hard enough to move performance, but the pace bled into recovery and the people around you.",
                    tags: [.career, .health, .relationships]
                )
            )
        case .protectYourEnergy:
            career.performance += 1
            career.burnout = max(0, career.burnout - (career.workIdentity == .caretaker ? 10 : 8))
            career.schedulePressure = max(0, career.schedulePressure - 6)
            career.relationshipSpillover = max(0, career.relationshipSpillover - 5)
            career.scheduleControl += 5
            career.managerFriction = max(0, career.managerFriction - 1)
            career.protectiveYears += 1
            result.healthEffects = HealthEffects(physical: 2, mental: 5, exercise: 2, nutrition: nil, stressManagement: 4, addCondition: nil, removeCondition: nil, hasPrimaryCare: nil)
            result.relationshipEffects = RelationshipEffects(meetNewFriend: nil, friendChange: 1, startDating: nil, partnerChange: 1, setPartnerStage: nil, setCohabiting: nil, commitmentAlignmentChange: 2, loseFriend: nil, breakup: nil)
            result.notes.append(DomainNote(title: "Career Focus", text: "You protected your energy on purpose, which steadied health and relationships even if work moved more slowly.", tags: [.career, .health, .relationships]))
        case .network:
            career.performance += 4
            career.schedulePressure += 3
            career.relationshipSpillover += 2
            career.managerFriction += career.workIdentity == .climber ? 2 : 1
            career.jobSecurity += 2
            career.ambitionYears += 1
            result.relationshipEffects = RelationshipEffects(meetNewFriend: true, friendChange: 1, startDating: nil, partnerChange: nil, setPartnerStage: nil, setCohabiting: nil, commitmentAlignmentChange: nil, loseFriend: nil, breakup: nil)
            result.coreEffects = CoreStatEffects(happiness: player.traits.contains(.anxious) ? -1 : 1, smarts: nil, looks: nil, health: nil)
            result.notes.append(DomainNote(title: "Career Focus", text: "You spent the year converting conversations into leverage. The upside is real, but it can make the rest of life feel transactional.", tags: [.career, .relationships]))
        case .retrain:
            career.performance += 2
            if career.retrainingTargetProfile == nil {
                career.retrainingTargetProfile = reskilledProfile(for: player, current: career.profile, education: nil)
            }
            career.retrainingProgress = min(3, career.retrainingProgress + 1)
            career.schedulePressure += 4
            career.burnout += 3
            career.scheduleControl = max(0, career.scheduleControl - 2)
            career.ambitionYears += 1
            if career.retrainingProgress >= 3, career.profile != .credentialedProfessional {
                setOpportunityDoor(.credentialPivot, on: &career)
            }
            result.financeEffects = FinanceEffects(cashDelta: -1_200, studentDebtDelta: nil, livingCostDelta: nil, educationCostDelta: 700, dependentCostDelta: nil, discretionaryCostDelta: nil, financialStressDelta: 4, setRegionPolicyID: nil)
            result.healthEffects = HealthEffects(physical: nil, mental: -1, exercise: nil, nutrition: nil, stressManagement: -1, addCondition: nil, removeCondition: nil, hasPrimaryCare: nil)
            result.notes.append(DomainNote(title: "Career Focus", text: "You spent money and mental bandwidth retraining, buying a better future at the cost of a harder present.", tags: [.career, .finance, .health]))
        case .takeOvertime:
            career.performance += 5
            career.burnout += max(6, 13 - career.scheduleControl / 15) + (career.workIdentity == .hustler ? 2 : 0)
            career.schedulePressure += max(5, 11 - career.scheduleControl / 20)
            career.relationshipSpillover += max(4, 10 - career.scheduleControl / 20)
            career.jobSecurity += 2
            career.scheduleControl = max(0, career.scheduleControl - 4)
            career.hustleYears += 1
            result.financeEffects = FinanceEffects(cashDelta: 2_800, studentDebtDelta: nil, livingCostDelta: nil, educationCostDelta: nil, dependentCostDelta: nil, discretionaryCostDelta: nil, financialStressDelta: -3, setRegionPolicyID: nil)
            result.healthEffects = HealthEffects(physical: -2, mental: -4, exercise: -2, nutrition: nil, stressManagement: -3, addCondition: nil, removeCondition: nil, hasPrimaryCare: nil)
            result.relationshipEffects = RelationshipEffects(meetNewFriend: nil, friendChange: -2, startDating: nil, partnerChange: -2, setPartnerStage: nil, setCohabiting: nil, commitmentAlignmentChange: -2, loseFriend: nil, breakup: nil)
            result.notes.append(DomainNote(title: "Career Focus", text: "The overtime money landed, but it tightened the year everywhere else.", tags: [.career, .finance, .health, .relationships]))
        case .coast:
            career.performance -= 4
            career.burnout = max(0, career.burnout - 2)
            career.schedulePressure = max(0, career.schedulePressure - 1)
            career.jobSecurity = max(0, career.jobSecurity - 4)
            career.managerFriction = max(0, career.managerFriction - 1)
            career.driftYears += 1
            result.coreEffects = CoreStatEffects(happiness: 1)
            result.notes.append(
                DomainNote(
                    title: "Career Focus",
                    text: "You phoned it in this year. It felt easier, but your work identity drifted further away from commitment.",
                    tags: [.career]
                )
            )
        case .jobHunt:
            if player.age >= 16 && career.roleID == nil {
                career.performance += career.jobSecurity < 45 ? 5 : 3
                career.schedulePressure += 2
                career.jobSecurity += 5
                career.ambitionYears += 1
                let education = EducationState()
                if let role = CareerCatalog.bestQualifiedRole(for: player, career: career, education: education, preferredProfile: career.profile) {
                    assign(role, to: &career, minimumPerformance: 58)
                }
                result.financeEffects = FinanceEffects(cashDelta: 200, studentDebtDelta: nil, livingCostDelta: nil, educationCostDelta: nil, dependentCostDelta: nil, discretionaryCostDelta: nil, financialStressDelta: nil, setRegionPolicyID: nil)
                result.notes.append(
                    DomainNote(
                        title: "Career Focus",
                        text: "You put time into looking for work and found a little short-term income along the way.",
                        tags: [.career, .finance]
                    )
                )
            }
        default:
            return result
        }

        refreshIdentity(on: &career)
        updateOpportunityDoor(on: &career, player: player, education: EducationState())
        career.clamp()
        return result
    }

    func roleTitle(for state: CareerState) -> String {
        CareerCatalog.definition(for: state.roleID)?.title ?? defaultLabel(for: state.status)
    }

    private func normalizeStatus(for career: inout CareerState, age: Int) {
        if let role = CareerCatalog.definition(for: career.roleID) {
            career.profile = role.profile
            career.status = role.status
            if career.annualIncome == 0 {
                career.annualIncome = role.annualIncome
            }
            career.level = role.level
            refreshWorkConditions(for: &career, force: true)
            return
        }

        if age < 18 {
            career.status = .student
            career.unemployedYears = 0
        } else if career.status == .student {
            career.status = .unemployed
        }
    }

    private func startingProfile(for player: Player, career: CareerState, education: EducationState) -> CareerProfile {
        if career.retrainingProgress >= 3 || education.stage == .university {
            return .credentialedProfessional
        }
        if player.traits.contains(.charismatic) {
            return .creativeFreelance
        }
        if player.traits.contains(.disciplined) || education.pathway == .graduate {
            return .stableAdmin
        }
        if player.health >= 65 {
            return .physicalLabor
        }
        return .serviceFrontline
    }

    private func reskilledProfile(for player: Player, current: CareerProfile, education: EducationState?) -> CareerProfile {
        switch current {
        case .serviceFrontline:
            if education?.stage == .university || player.traits.contains(.disciplined) {
                return .credentialedProfessional
            }
            return .stableAdmin
        case .physicalLabor:
            return .stableAdmin
        case .creativeFreelance:
            return player.traits.contains(.charismatic) ? .creativeFreelance : .stableAdmin
        case .stableAdmin:
            return .credentialedProfessional
        case .credentialedProfessional:
            return .credentialedProfessional
        }
    }

    private func adjustedIncome(for role: CareerRoleDefinition, career: CareerState, player: Player) -> Int {
        let definition = CareerCatalog.definition(for: role.profile)
        let spread = definition.incomeSwingRange.upperBound - definition.incomeSwingRange.lowerBound
        let seed = player.age * 19 + career.yearsWorked * 23 + career.retrainingProgress * 17 + career.schedulePressure + career.burnout
        let swing = definition.incomeSwingRange.lowerBound + (abs(seed) % max(1, spread + 1))
        return max(0, role.annualIncome + swing)
    }

    private func assign(_ role: CareerRoleDefinition, to career: inout CareerState, minimumPerformance: Int) {
        career.roleID = role.id
        career.profile = role.profile
        career.status = role.status
        career.level = role.level
        career.annualIncome = role.annualIncome
        career.performance = max(career.performance, minimumPerformance)
        career.unemployedYears = 0
        refreshWorkConditions(for: &career, force: true)
    }

    private func accrueExperience(from role: CareerRoleDefinition, on career: inout CareerState) {
        career.careerExperience[role.primaryExperienceTag, default: 0] += 1
        for tag in role.secondaryExperienceTags {
            career.careerExperience[tag, default: 0] += 1
        }
        for tag in role.bridgeTags {
            career.careerExperience[tag, default: 0] += 1
        }
        if role.isManagementRole || role.level >= 5 {
            career.careerExperience[.management, default: 0] += 1
        }
    }

    private func applyProfileDrift(to career: inout CareerState, result: inout DomainYearResult) {
        let definition = CareerCatalog.definition(for: career.profile)
        career.burnout += definition.burnoutGain + burnoutModifier(for: career)
        career.schedulePressure += definition.schedulePressureGain
        career.relationshipSpillover += definition.relationshipSpilloverGain
        career.jobSecurity += (definition.baseJobSecurity - career.jobSecurity) / 5
        career.managerFriction += (definition.baseManagerFriction - career.managerFriction) / 5
        career.scheduleControl += (definition.baseScheduleControl - career.scheduleControl) / 5
        if career.scheduleControl < 40 {
            career.schedulePressure += 2
            career.relationshipSpillover += 2
        }
        if career.managerFriction >= 60 {
            result.healthEffects = mergeHealthEffects(
                result.healthEffects,
                with: HealthEffects(physical: nil, mental: -2, exercise: nil, nutrition: nil, stressManagement: -1, addCondition: nil, removeCondition: nil, hasPrimaryCare: nil)
            )
        }
        if career.jobSecurity < 42 {
            result.financeEffects = mergeFinanceEffects(
                result.financeEffects,
                with: FinanceEffects(cashDelta: nil, studentDebtDelta: nil, livingCostDelta: nil, educationCostDelta: nil, dependentCostDelta: nil, discretionaryCostDelta: nil, financialStressDelta: 2, setRegionPolicyID: nil)
            )
        }
        result.healthEffects = mergeHealthEffects(
            result.healthEffects,
            with: HealthEffects(physical: definition.physicalTilt, mental: definition.mentalTilt, exercise: nil, nutrition: nil, stressManagement: -1, addCondition: nil, removeCondition: nil, hasPrimaryCare: nil)
        )

        if career.relationshipSpillover >= 55 {
            result.relationshipEffects = mergeRelationshipEffects(
                result.relationshipEffects,
                with: RelationshipEffects(meetNewFriend: nil, friendChange: -1, startDating: nil, partnerChange: -1, setPartnerStage: nil, setCohabiting: nil, commitmentAlignmentChange: -1, loseFriend: nil, breakup: nil)
            )
        }

        if career.burnout >= 68 {
            result.notes.append(DomainNote(title: "Work Strain", text: "The job is no longer staying inside work hours. It is shaping your body, your patience, and how available you feel to other people.", tags: [.career, .health, .relationships]))
        }
    }

    private func refreshIdentity(on career: inout CareerState) {
        if career.burnout >= 72 && career.hustleYears >= 2 {
            career.workIdentity = .burnedOutProvider
        } else if career.hustleYears >= max(2, career.ambitionYears) {
            career.workIdentity = .hustler
        } else if career.ambitionYears >= max(2, career.protectiveYears + 1) {
            career.workIdentity = .climber
        } else if career.protectiveYears >= max(2, career.driftYears + 1) {
            career.workIdentity = .caretaker
        } else if career.driftYears >= 2 {
            career.workIdentity = .drifter
        } else {
            career.workIdentity = .unsettled
        }
    }

    private func refreshWorkConditions(for career: inout CareerState, force: Bool = false) {
        let definition = CareerCatalog.definition(for: career.profile)
        if force || (career.jobSecurity == 52 && career.managerFriction == 34 && career.scheduleControl == 50) {
            career.jobSecurity = definition.baseJobSecurity
            career.managerFriction = definition.baseManagerFriction
            career.scheduleControl = definition.baseScheduleControl
        }
    }

    private func adjustedPromotionThreshold(for career: CareerState) -> Int {
        var threshold = balanceProfile.career.promotionBaseThreshold + CareerCatalog.definition(for: career.profile).promotionThresholdDelta - min(4, career.retrainingProgress * 2)
        switch career.workIdentity {
        case .climber:
            threshold -= 4
        case .caretaker:
            threshold += 3
        case .drifter:
            threshold += 5
        case .hustler:
            threshold -= 1
        case .burnedOutProvider:
            threshold += 2
        case .unsettled:
            break
        }
        threshold += max(0, career.managerFriction - 50) / 8
        return max(66, threshold)
    }

    private func burnoutModifier(for career: CareerState) -> Int {
        switch career.workIdentity {
        case .climber:
            return 1
        case .caretaker:
            return -2
        case .drifter:
            return 0
        case .hustler:
            return 2
        case .burnedOutProvider:
            return 3
        case .unsettled:
            return 0
        }
    }

    private func decayOpportunityDoor(on career: inout CareerState) {
        guard career.opportunityDoorYearsRemaining > 0 else { return }
        career.opportunityDoorYearsRemaining -= 1
        if career.opportunityDoorYearsRemaining <= 0 {
            career.activeOpportunityDoor = nil
            career.opportunityDoorYearsRemaining = 0
        }
    }

    private func setOpportunityDoor(_ door: CareerOpportunityDoor, on career: inout CareerState) {
        career.activeOpportunityDoor = door
        career.opportunityDoorYearsRemaining = 2
    }

    private func clearOpportunityDoor(on career: inout CareerState) {
        career.activeOpportunityDoor = nil
        career.opportunityDoorYearsRemaining = 0
    }

    private func updateOpportunityDoor(on career: inout CareerState, player: Player, education: EducationState) {
        if career.activeOpportunityDoor != nil && career.opportunityDoorYearsRemaining > 0 {
            return
        }

        if career.workIdentity == .burnedOutProvider && career.burnout >= 74 {
            setOpportunityDoor(.burnoutExit, on: &career)
        } else if career.profile == .physicalLabor && career.jobSecurity <= 42 && career.burnout >= 52 {
            setOpportunityDoor(.unionStability, on: &career)
        } else if career.profile == .creativeFreelance && career.workIdentity == .hustler && career.annualIncome >= 30_000 {
            setOpportunityDoor(.contractWindfall, on: &career)
        } else if career.retrainingProgress >= 3 && career.profile != .credentialedProfessional {
            setOpportunityDoor(.credentialPivot, on: &career)
        } else if career.workIdentity == .drifter && career.jobSecurity <= 44 {
            setOpportunityDoor(.lateralEscapeRoute, on: &career)
        } else if career.workIdentity == .climber && career.performance >= 74 && career.managerFriction >= 40 {
            setOpportunityDoor(.internalPromotionTrack, on: &career)
        } else if education.stage == .university && career.profile == .serviceFrontline && player.age >= 20 {
            setOpportunityDoor(.credentialPivot, on: &career)
        }
    }

    private func mergeFinanceEffects(_ lhs: FinanceEffects?, with rhs: FinanceEffects) -> FinanceEffects {
        FinanceEffects(
            cashDelta: (lhs?.cashDelta ?? 0) + (rhs.cashDelta ?? 0),
            studentDebtDelta: (lhs?.studentDebtDelta ?? 0) + (rhs.studentDebtDelta ?? 0),
            livingCostDelta: (lhs?.livingCostDelta ?? 0) + (rhs.livingCostDelta ?? 0),
            educationCostDelta: (lhs?.educationCostDelta ?? 0) + (rhs.educationCostDelta ?? 0),
            dependentCostDelta: (lhs?.dependentCostDelta ?? 0) + (rhs.dependentCostDelta ?? 0),
            discretionaryCostDelta: (lhs?.discretionaryCostDelta ?? 0) + (rhs.discretionaryCostDelta ?? 0),
            financialStressDelta: (lhs?.financialStressDelta ?? 0) + (rhs.financialStressDelta ?? 0),
            setRegionPolicyID: rhs.setRegionPolicyID ?? lhs?.setRegionPolicyID
        )
    }

    private func mergeRelationshipEffects(_ lhs: RelationshipEffects?, with rhs: RelationshipEffects) -> RelationshipEffects {
        RelationshipEffects(
            meetNewFriend: rhs.meetNewFriend ?? lhs?.meetNewFriend,
            friendChange: (lhs?.friendChange ?? 0) + (rhs.friendChange ?? 0),
            startDating: rhs.startDating ?? lhs?.startDating,
            partnerChange: (lhs?.partnerChange ?? 0) + (rhs.partnerChange ?? 0),
            setPartnerStage: rhs.setPartnerStage ?? lhs?.setPartnerStage,
            setCohabiting: rhs.setCohabiting ?? lhs?.setCohabiting,
            commitmentAlignmentChange: (lhs?.commitmentAlignmentChange ?? 0) + (rhs.commitmentAlignmentChange ?? 0),
            loseFriend: rhs.loseFriend ?? lhs?.loseFriend,
            breakup: rhs.breakup ?? lhs?.breakup,
            publicReputationChange: (lhs?.publicReputationChange ?? 0) + (rhs.publicReputationChange ?? 0),
            privateReputationChange: (lhs?.privateReputationChange ?? 0) + (rhs.privateReputationChange ?? 0),
            rumorHeatChange: (lhs?.rumorHeatChange ?? 0) + (rhs.rumorHeatChange ?? 0),
            addKnownTag: rhs.addKnownTag ?? lhs?.addKnownTag
        )
    }

    private func mergeHealthEffects(_ lhs: HealthEffects?, with rhs: HealthEffects) -> HealthEffects {
        HealthEffects(
            physical: (lhs?.physical ?? 0) + (rhs.physical ?? 0),
            mental: (lhs?.mental ?? 0) + (rhs.mental ?? 0),
            exercise: (lhs?.exercise ?? 0) + (rhs.exercise ?? 0),
            nutrition: (lhs?.nutrition ?? 0) + (rhs.nutrition ?? 0),
            stressManagement: (lhs?.stressManagement ?? 0) + (rhs.stressManagement ?? 0),
            addCondition: rhs.addCondition ?? lhs?.addCondition,
            removeCondition: rhs.removeCondition ?? lhs?.removeCondition,
            hasPrimaryCare: rhs.hasPrimaryCare ?? lhs?.hasPrimaryCare
        )
    }

    private func defaultLabel(for status: CareerStatus) -> String {
        switch status {
        case .student: return "Student"
        case .partTime: return "Part-Time Work"
        case .fullTime: return "Full-Time Work"
        case .unemployed: return "Looking for work"
        }
    }
}
