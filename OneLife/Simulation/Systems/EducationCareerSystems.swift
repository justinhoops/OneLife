import Foundation

struct EducationSystem {
    func advanceYear(input: EducationDomainSnapshot, player: inout Player, education: inout EducationState, military: inout MilitaryState, career: inout CareerState) -> DomainYearResult {
        advanceYear(
            player: &player,
            education: &education,
            military: &military,
            career: &career,
            finance: input.finance,
            relationships: input.relationships,
            health: input.health,
            policySupport: input.policySupport,
            childhoodDossier: input.childhoodDossier
        )
    }

    func advanceYear(
        player: inout Player,
        education: inout EducationState,
        military: inout MilitaryState,
        career: inout CareerState,
        finance: FinanceState,
        relationships: RelationshipState,
        health: HealthState,
        policySupport: Int,
        childhoodDossier: ChildhoodDossier? = nil
    ) -> DomainYearResult {
        var result = DomainYearResult()
        let dossier = childhoodDossier

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
            accumulateHighSchoolResidue(
                player: player,
                education: &education,
                finance: finance,
                relationships: relationships,
                health: health,
                childhoodDossier: dossier
            )
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

            // Teen immersion (dossier payoff): your childhood aptitudes show up in school life 14-17
            if let d = dossier, player.age <= 17 {
                if d.aptitudes.physical >= 55 {
                    education.activityMomentum = min(100, education.activityMomentum + 3)
                    education.schoolBelonging = min(100, education.schoolBelonging + 2)
                    if player.age % 2 == 0 {
                        result.notes.append(DomainNote(title: "Body in Motion", text: "Your natural physical edge makes gym, sports, or just moving through the day feel easier than for most. Coaches notice.", tags: [.education, .health]))
                    }
                }
                if d.aptitudes.entrepreneurial >= 55 {
                    education.applicationReadiness = min(100, education.applicationReadiness + 2)
                    if player.age % 3 == 0 {
                        result.notes.append(DomainNote(title: "Hustle Instinct", text: "You spot little ways to turn small efforts into small advantages — side opportunities, trades, or favors that add up.", tags: [.education, .finance]))
                    }
                }
                if d.aptitudes.creative >= 55 {
                    education.engagement = min(100, education.engagement + 2)
                    education.activityMomentum = min(100, education.activityMomentum + 2)
                    if player.age % 2 == 1 {
                        result.notes.append(DomainNote(title: "Creative Spark", text: "Projects, art, writing, or performances pull you in. The work feels less like school and more like something that's yours.", tags: [.education]))
                    }
                }
                if d.aptitudes.social >= 55 {
                    education.schoolBelonging = min(100, education.schoolBelonging + 3)
                    education.teacherSupport = min(100, education.teacherSupport + 1)
                    if player.age % 3 == 1 {
                        result.notes.append(DomainNote(title: "Social Current", text: "You read the room and the people faster than most. Groups form around you or you slide into them easily.", tags: [.education, .relationships]))
                    }
                }
                if d.aptitudes.analytical >= 55 || d.aptitudes.technical >= 55 {
                    education.schoolStanding = min(100, education.schoolStanding + 1)
                    education.applicationReadiness = min(100, education.applicationReadiness + 2)
                    if player.age % 2 == 0 {
                        result.notes.append(DomainNote(title: "Sharp Edge", text: "The analytical or technical wiring from early on makes certain classes click. Teachers start treating you like someone who 'gets it'.", tags: [.education]))
                    }
                }
                // Use the actual early interests from dossier for personal texture
                if !d.earlyInterests.isEmpty, player.age % 4 == 0 {
                    let interest = d.earlyInterests.first!
                    result.notes.append(DomainNote(title: "Old Thread", text: "That early interest in \(interest) from before 14 is still quietly steering what grabs you in the hallways and classrooms.", tags: [.education]))
                }
            }
        }

        if player.age == 18 {
            resolveAgeEighteenTransition(player: &player, education: &education, career: &career, finance: finance, result: &result)
            // Early adulthood immersion: at the exact moment paths open, your dossier wiring gets called out
            if let d = dossier {
                var wiringNotes: [String] = []
                if d.aptitudes.physical >= 58 { wiringNotes.append("body") }
                if d.aptitudes.entrepreneurial >= 58 { wiringNotes.append("hustle") }
                if d.aptitudes.creative >= 58 { wiringNotes.append("voice") }
                if d.aptitudes.social >= 58 { wiringNotes.append("presence") }
                if !wiringNotes.isEmpty {
                    result.notes.append(DomainNote(title: "The Shape You Brought", text: "At 18 the doors are real. The ones that match the wiring you carried at 14 feel a little more open, a little more like they were waiting for you.", tags: [.education, .progress]))
                }
            }
        } else if player.age >= 19 {
            advancePostSecondaryStage(player: player, education: &education, military: &military, career: &career, finance: finance, health: health, result: &result, childhoodDossier: dossier)
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

    func applyAction(_ choiceID: ActionChoiceID, player: inout Player, education: inout EducationState, childhoodDossier: ChildhoodDossier? = nil, specialCareer: inout SpecialCareerState) -> DomainYearResult {
        var result = DomainYearResult()
        let dossier = childhoodDossier

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
        case .joinROTC:
            education.pathway = .rotc
            education.engagement += 10
            education.activityMomentum += 15
            result.notes.append(DomainNote(title: "ROTC", text: "You joined the Reserve Officers' Training Corps. You now have a stipend and mandatory training.", tags: [.education, .career]))
        case .leaveROTC:
            education.pathway = .student
            education.activityMomentum -= 10
            result.notes.append(DomainNote(title: "ROTC", text: "You left ROTC and returned to regular student life.", tags: [.education]))
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
        // D3: Education branch actions - set track and give immediate buffs, with long-term handoff effects
        case .pursueTradeCert:
            education.academicTrack = .vocational
            education.applicationReadiness += 10
            education.activityMomentum += 8
            education.credentialStrength = max(education.credentialStrength, 72)
            education.yearsSinceCredential = 0
            result.notes.append(DomainNote(title: "Trade Path", text: "You chose the hands-on route. Faster income, real skills, and a different kind of respect. (Trade creds hold value through practice, slower decay.)", tags: [.education, .career]))
        case .honorsTrack:
            education.academicTrack = .honors
            education.schoolStanding += 8
            education.engagement += 6
            education.burnoutRisk += 5
            education.credentialStrength = max(education.credentialStrength, 85)
            education.yearsSinceCredential = 0
            result.notes.append(DomainNote(title: "Honors Lock-In", text: "The elite track. Standing soars, but the pressure is real and the special doors start opening early. (High prestige creds with strong longevity.)", tags: [.education]))
        case .uniApplication:
            education.applicationReadiness += 12
            education.burnoutRisk += 3
            education.credentialStrength = max(education.credentialStrength, 68)
            result.notes.append(DomainNote(title: "University Bound", text: "The applications are in. The long academic road begins, with debt and delayed earnings but higher ceiling.", tags: [.education, .finance]))
        case .lifelongLearning:
            education.engagement += 5
            education.applicationReadiness += 4
            education.credentialStrength = min(100, education.credentialStrength + 4)
            result.notes.append(DomainNote(title: "Lifelong Learner", text: "You keep the mind sharp beyond the diploma. Small consistent edge that compounds.", tags: [.education, .career]))
        case .credentialRefresh:
            education.applicationReadiness += 6
            education.credentialStrength = min(100, education.credentialStrength + 18)
            education.yearsSinceCredential = 0
            result.financeEffects = FinanceEffects(cashDelta: -800)
            result.notes.append(DomainNote(title: "Credential Refresh", text: "You updated the old paper. It still opens doors, but only if you keep it current.", tags: [.education, .finance]))
        // Teen 2: Dossier-driven precursors - only meaningful in teen years, give school immersion + early seed to special substates
        case .teenAthleticDrill:
            education.activityMomentum += 12
            education.schoolBelonging += 6
            education.engagement += 4
            bumpHighSchoolTag("athlete_seed", by: 12, education: &education)
            bumpHighSchoolTag("identity_reps", by: 5, education: &education)
            addHighSchoolIdentityForce(
                HighSchoolIdentityForce(id: "activity-signal", name: "Coach Hale", role: .activityCoachForce, tone: .demanding, storyLine: "Practice is turning into a place where your future feels physical.", strength: 64),
                education: &education
            )
            if specialCareer.athlete.naturalPotential < 80 {
                specialCareer.athlete.naturalPotential = min(100, specialCareer.athlete.naturalPotential + 5)
            }
            specialCareer.athlete.durability = min(100, specialCareer.athlete.durability + 3)
            result.notes.append(DomainNote(title: "Athletic Drill", text: "You pushed your body hard after school. The reps build more than muscle — your future athletic ceiling just rose a notch.", tags: [.education, .health]))
        case .teenSideHustle:
            education.applicationReadiness += 8
            education.activityMomentum += 8
            bumpHighSchoolTag("founder_seed", by: 12, education: &education)
            bumpHighSchoolTag("money_pressure", by: 3, education: &education)
            addHighSchoolIdentityForce(
                HighSchoolIdentityForce(id: "home-pressure", name: "Money pressure", role: .homePressure, tone: .demanding, storyLine: "Cash starts feeling like identity before adulthood officially begins.", strength: 58),
                education: &education
            )
            specialCareer.founder.execution = min(100, specialCareer.founder.execution + 4)
            if specialCareer.track == .inactive {
                specialCareer.audience = max(specialCareer.audience, 8)
            }
            result.notes.append(DomainNote(title: "Side Hustle", text: "You found a small way to turn time into cash or connections. The entrepreneurial muscle memory is forming early.", tags: [.education, .finance]))
        case .teenCreativeProject:
            education.engagement += 10
            education.activityMomentum += 6
            education.schoolBelonging += 4
            bumpHighSchoolTag("creator_seed", by: 12, education: &education)
            bumpHighSchoolTag("identity_reps", by: 5, education: &education)
            addHighSchoolIdentityForce(
                HighSchoolIdentityForce(id: "activity-signal", name: "The project room", role: .activityCoachForce, tone: .neutral, storyLine: "The work you make after class is becoming a private compass.", strength: 62),
                education: &education
            )
            specialCareer.creator.contentQuality = min(100, specialCareer.creator.contentQuality + 5)
            specialCareer.creator.personalBrand = min(100, specialCareer.creator.personalBrand + 3)
            result.notes.append(DomainNote(title: "Creative Project", text: "You poured yourself into something original. The work is amateur but the voice is already yours — this is the seed of a platform.", tags: [.education]))
        case .teenLeadInitiative:
            education.schoolBelonging += 10
            education.teacherSupport += 6
            education.mentorSupport += 5
            bumpHighSchoolTag("politics_seed", by: 12, education: &education)
            bumpHighSchoolTag("mentor_support", by: 5, education: &education)
            addHighSchoolIdentityForce(
                HighSchoolIdentityForce(id: "mentor-anchor", name: "Ms. Rivera", role: .mentorAdult, tone: .supportive, storyLine: "An adult notices that people already look to you.", strength: 64),
                education: &education
            )
            specialCareer.politics.charisma = min(100, specialCareer.politics.charisma + 5)
            specialCareer.politics.approvalRating = min(100, specialCareer.politics.approvalRating + 4)
            result.notes.append(DomainNote(title: "Lead Initiative", text: "You stepped up and organized something. People listened. The social and leadership wiring from childhood is getting real reps.", tags: [.education, .relationships]))
        case .teenRiskyExperiment:
            education.reputationRisk += 8
            education.activityMomentum += 5
            bumpHighSchoolTag("risk_seed", by: 12, education: &education)
            bumpHighSchoolTag("volatile_social", by: 6, education: &education)
            addHighSchoolIdentityForce(
                HighSchoolIdentityForce(id: "rival-heat", name: "Hallway heat", role: .rivalHeatSource, tone: .volatile, storyLine: "The thrill comes with attention you cannot fully steer.", strength: 62),
                education: &education
            )
            specialCareer.enterprise.riskTolerance = min(100, specialCareer.enterprise.riskTolerance + 6)
            specialCareer.enterprise.networkStrength = min(100, specialCareer.enterprise.networkStrength + 3)
            result.notes.append(DomainNote(title: "Risky Experiment", text: "You tried something that could have gone sideways. The thrill and the lesson both stick — this is how certain paths start in the shadows.", tags: [.education, .risk]))
        default:
            return result
        }

        // Teen immersion via actions: dossier makes school moves feel personal and seeds the special career "shape" early
        if player.age <= 17, let d = dossier {
            switch choiceID {
            case .joinActivity, .joinClub:
                if d.aptitudes.physical >= 55 {
                    education.activityMomentum = min(100, education.activityMomentum + 4)
                    result.notes.append(DomainNote(title: "Athletic Lean", text: "The physical wiring from your early years made this click. Your body responds fast — this is practice for something bigger.", tags: [.education, .health]))
                } else if d.aptitudes.social >= 55 || d.aptitudes.creative >= 55 {
                    education.schoolBelonging = min(100, education.schoolBelonging + 3)
                    result.notes.append(DomainNote(title: "Fitting the Scene", text: "Whether it's the people or the expression, this activity feels like an extension of who you already were at 14.", tags: [.education, .relationships]))
                }
            case .buildPortfolio:
                if d.aptitudes.entrepreneurial >= 55 || d.aptitudes.creative >= 55 {
                    education.applicationReadiness = min(100, education.applicationReadiness + 5)
                    education.activityMomentum = min(100, education.activityMomentum + 3)
                    result.notes.append(DomainNote(title: "Early Proof", text: "Building something tangible plays to the edge you brought from childhood. This folder is going to matter later.", tags: [.education]))
                }
            case .studyHard, .studyConsistently:
                if d.aptitudes.analytical >= 55 || d.aptitudes.technical >= 55 {
                    education.schoolStanding = min(100, education.schoolStanding + 2)
                    result.notes.append(DomainNote(title: "The Mind Likes This", text: "The analytical or technical shape from your early years makes focused study feel almost natural. The edge is quiet but real.", tags: [.education]))
                }
            default:
                break
            }
        }

        education.clamp()
        refreshHighSchoolProfile(for: &education)
        return result
    }

    private func bumpHighSchoolTag(_ tag: String, by amount: Int, education: inout EducationState) {
        guard amount != 0 else { return }
        education.formativeSchoolTags[tag, default: 0] = (education.formativeSchoolTags[tag, default: 0] + amount).clamped(to: 0...100)
    }

    private func addHighSchoolIdentityForce(_ force: HighSchoolIdentityForce, education: inout EducationState) {
        var copy = force
        copy.clamp()
        if let index = education.highSchoolIdentityForces.firstIndex(where: { $0.id == copy.id }) {
            education.highSchoolIdentityForces[index].strength = max(education.highSchoolIdentityForces[index].strength, copy.strength)
            education.highSchoolIdentityForces[index].storyLine = copy.storyLine
            education.highSchoolIdentityForces[index].tone = copy.tone
        } else {
            education.highSchoolIdentityForces.append(copy)
        }
        education.clamp()
    }

    private func accumulateHighSchoolResidue(
        player: Player,
        education: inout EducationState,
        finance: FinanceState,
        relationships: RelationshipState,
        health: HealthState,
        childhoodDossier: ChildhoodDossier?
    ) {
        if education.schoolStanding >= 76 { bumpHighSchoolTag("academic_strength", by: 5, education: &education) }
        if education.schoolStanding <= 44 { bumpHighSchoolTag("academic_strain", by: 6, education: &education) }
        if education.academicTrack == .vocational || education.studyFocus == .trades { bumpHighSchoolTag("trade_seed", by: 6, education: &education) }
        if education.schoolBelonging >= 62 || relationships.friends.strongestBond >= 65 {
            bumpHighSchoolTag("belonging", by: 5, education: &education)
        }
        if education.schoolBelonging <= 34 || relationships.friends.isEmpty {
            bumpHighSchoolTag("isolation", by: 6, education: &education)
        }
        if education.reputationRisk >= 58 || education.peerPressure >= 58 {
            bumpHighSchoolTag("volatile_social", by: 5, education: &education)
        }
        if education.disciplineRecord <= 42 {
            bumpHighSchoolTag("discipline_scar", by: 5, education: &education)
        }
        if education.teacherSupport >= 64 || education.mentorSupport >= 58 {
            bumpHighSchoolTag("mentor_support", by: 6, education: &education)
        }
        if education.teacherSupport <= 32 {
            bumpHighSchoolTag("adult_friction", by: 5, education: &education)
        }
        if education.burnoutRisk >= 58 {
            bumpHighSchoolTag("burnout", by: 6, education: &education)
        }
        if education.attendancePressure >= 58 || finance.financialStress >= 45 || health.mentalWellness <= 42 {
            bumpHighSchoolTag("survival_pressure", by: 5, education: &education)
        }
        if player.smarts >= 68 || education.applicationReadiness >= 62 {
            bumpHighSchoolTag("academic_seed", by: 4, education: &education)
        }
        if let d = childhoodDossier {
            if d.aptitudes.physical >= 58 { bumpHighSchoolTag("athlete_seed", by: 2, education: &education) }
            if d.aptitudes.entrepreneurial >= 58 { bumpHighSchoolTag("founder_seed", by: 2, education: &education) }
            if d.aptitudes.creative >= 58 { bumpHighSchoolTag("creator_seed", by: 2, education: &education) }
            if d.aptitudes.social >= 58 { bumpHighSchoolTag("politics_seed", by: 2, education: &education) }
        }
        refreshHighSchoolProfile(for: &education)
        refreshHighSchoolIdentityForces(
            player: player,
            education: &education,
            finance: finance,
            relationships: relationships,
            health: health,
            childhoodDossier: childhoodDossier
        )
    }

    func refreshHighSchoolIdentityForces(
        player: Player,
        education: inout EducationState,
        finance: FinanceState,
        relationships: RelationshipState,
        health: HealthState,
        childhoodDossier: ChildhoodDossier?
    ) {
        guard (14...18).contains(player.age) else { return }

        var candidates: [HighSchoolIdentityForce] = []

        if education.teacherSupport >= 62 || education.mentorSupport >= 54 || education.highSchoolProfile.adultSupportShape == .mentored {
            candidates.append(HighSchoolIdentityForce(
                id: "mentor-anchor",
                name: "Ms. Rivera",
                role: .mentorAdult,
                tone: .supportive,
                storyLine: "An adult at school is starting to treat your future as real.",
                strength: max(education.teacherSupport, education.mentorSupport)
            ))
            bumpHighSchoolTag("mentor_anchor", by: 5, education: &education)
        }

        if education.schoolBelonging >= 60 || relationships.friends.strongestBond >= 62 {
            candidates.append(HighSchoolIdentityForce(
                id: "peer-anchor",
                name: relationships.friends.max { $0.bond < $1.bond }?.name ?? "A steady friend",
                role: .peerAlly,
                tone: .supportive,
                storyLine: "Someone your age makes school feel less like a solo project.",
                strength: max(education.schoolBelonging, relationships.friends.strongestBond)
            ))
            bumpHighSchoolTag("peer_anchor", by: 4, education: &education)
        }

        if education.reputationRisk >= 56 || education.peerPressure >= 58 || education.highSchoolProfile.socialShape == .volatile {
            candidates.append(HighSchoolIdentityForce(
                id: "rival-heat",
                name: "Hallway heat",
                role: .rivalHeatSource,
                tone: education.reputationRisk >= 68 ? .volatile : .tense,
                storyLine: "Reputation, rumors, or a rival crowd keep pulling focus from the future.",
                strength: max(education.reputationRisk, education.peerPressure)
            ))
            bumpHighSchoolTag("rival_heat", by: 5, education: &education)
        }

        if education.activityMomentum >= 58 || [.athlete, .creator, .politics, .trade].contains(education.highSchoolProfile.futureSeed) {
            let name: String
            switch education.highSchoolProfile.futureSeed {
            case .athlete: name = "Coach Hale"
            case .creator: name = "The project room"
            case .politics: name = "The organizer circle"
            case .trade: name = "The shop teacher"
            default: name = "After-school momentum"
            }
            candidates.append(HighSchoolIdentityForce(
                id: "activity-signal",
                name: name,
                role: .activityCoachForce,
                tone: .demanding,
                storyLine: "The work outside ordinary class is becoming part of your identity.",
                strength: max(education.activityMomentum, education.formativeSchoolTags["identity_reps", default: 0])
            ))
            bumpHighSchoolTag("coach_signal", by: 4, education: &education)
        }

        if finance.financialStress >= 42 || health.mentalWellness <= 42 || education.attendancePressure >= 58 || education.highSchoolProfile.pressureShape == .survivalMode {
            candidates.append(HighSchoolIdentityForce(
                id: "home-pressure",
                name: "Home pressure",
                role: .homePressure,
                tone: .demanding,
                storyLine: "Money, health, or family strain is following you into school.",
                strength: max(finance.financialStress, max(100 - health.mentalWellness, education.attendancePressure))
            ))
            bumpHighSchoolTag("home_pressure", by: 5, education: &education)
        }

        if let d = childhoodDossier {
            if d.aptitudes.physical >= 65 && !candidates.contains(where: { $0.role == .activityCoachForce }) {
                candidates.append(HighSchoolIdentityForce(id: "body-signal", name: "Physical edge", role: .activityCoachForce, tone: .demanding, storyLine: "Your body keeps giving you a louder path than the classroom does.", strength: d.aptitudes.physical))
            } else if d.aptitudes.creative >= 65 && !candidates.contains(where: { $0.role == .activityCoachForce }) {
                candidates.append(HighSchoolIdentityForce(id: "creative-signal", name: "Creative current", role: .activityCoachForce, tone: .neutral, storyLine: "The thing you make after class feels more honest than the assignments.", strength: d.aptitudes.creative))
            }
        }

        var merged: [String: HighSchoolIdentityForce] = [:]
        for force in education.highSchoolIdentityForces + candidates {
            var copy = force
            copy.clamp()
            let existing = merged[copy.id]
            copy.strength = min(100, max(copy.strength, existing?.strength ?? 0))
            merged[copy.id] = copy
        }
        education.highSchoolIdentityForces = Array(merged.values.sorted { $0.strength > $1.strength }.prefix(3))
        education.clamp()
    }

    func prepareHighSchoolIdentityBeat(playerAge: Int, education: inout EducationState) -> GameEvent? {
        guard (14...17).contains(playerAge), education.lastHighSchoolIdentityBeatAge != playerAge else { return nil }
        guard let force = education.highSchoolIdentityForces.first(where: { $0.strength >= 58 }) else { return nil }
        education.lastHighSchoolIdentityBeatAge = playerAge

        let event = highSchoolIdentityEvent(for: force, age: playerAge, profile: education.highSchoolProfile)
        return event
    }

    private func highSchoolIdentityEvent(for force: HighSchoolIdentityForce, age: Int, profile: HighSchoolProfile) -> GameEvent {
        let headline: String
        let text: String
        let choices: [EventChoice]

        switch force.role {
        case .mentorAdult:
            headline = "A Mentor Notices Your Direction"
            text = "\(force.name) sees the shape forming before you fully trust it."
            choices = [
                EventChoice(text: "Take the guidance", effects: ChoiceEffects(education: EducationEffects(schoolStanding: 2, applicationReadiness: 4, mentorSupport: 5)), microBeat: "You write down what they said."),
                EventChoice(text: "Keep it casual", effects: ChoiceEffects(education: EducationEffects(schoolBelonging: 1, mentorSupport: 1)), microBeat: "You nod, but keep distance."),
                EventChoice(text: "Reject the pressure", effects: ChoiceEffects(education: EducationEffects(teacherSupport: -3, peerPressure: 2)), microBeat: "Being seen feels too expensive.", baseFriction: .resistance)
            ]
        case .peerAlly:
            headline = "A Friend Makes School Bearable"
            text = "\(force.name) turns the year from something endured into something witnessed."
            choices = [
                EventChoice(text: "Lean into the bond", effects: ChoiceEffects(education: EducationEffects(schoolBelonging: 5, burnoutRisk: -2)), microBeat: "You stop eating alone."),
                EventChoice(text: "Keep your routine first", effects: ChoiceEffects(education: EducationEffects(schoolStanding: 2, schoolBelonging: 1)), microBeat: "You stay kind, but focused."),
                EventChoice(text: "Follow the crowd", effects: ChoiceEffects(education: EducationEffects(schoolBelonging: 2, reputationRisk: 3, peerPressure: 4)), microBeat: "It feels good to be included.", baseFriction: .warning)
            ]
        case .rivalHeatSource:
            headline = "Hallway Heat Finds Your Name"
            text = "Reputation is starting to move faster than your actual choices."
            choices = [
                EventChoice(text: "De-escalate it", effects: ChoiceEffects(education: EducationEffects(reputationRisk: -5, disciplineRecord: 2)), microBeat: "You let silence do work."),
                EventChoice(text: "Stand your ground", effects: ChoiceEffects(education: EducationEffects(schoolBelonging: 2, reputationRisk: 2, peerPressure: 3)), microBeat: "People notice the edge.", baseFriction: .resistance),
                EventChoice(text: "Make it louder", effects: ChoiceEffects(education: EducationEffects(reputationRisk: 6, disciplineRecord: -4, peerPressure: 4)), microBeat: "The room reacts before you think.", baseFriction: .warning)
            ]
        case .activityCoachForce:
            headline = "The After-School Thing Gets Real"
            text = "\(force.name) is becoming a place where your future has a texture."
            choices = [
                EventChoice(text: "Commit to the reps", effects: ChoiceEffects(education: EducationEffects(activityMomentum: 5, applicationReadiness: 2, burnoutRisk: 2)), microBeat: "Practice runs late."),
                EventChoice(text: "Use it for balance", effects: ChoiceEffects(education: EducationEffects(schoolBelonging: 3, burnoutRisk: -2)), microBeat: "It gives the week shape."),
                EventChoice(text: "Chase the shortcut", effects: ChoiceEffects(education: EducationEffects(activityMomentum: 2, reputationRisk: 3)), microBeat: "You want proof now.", baseFriction: profile.futureSeed == .riskLane ? .warning : .none)
            ]
        case .homePressure:
            headline = "Home Pressure Enters The Classroom"
            text = "The year is asking you to be a student while carrying more than school."
            choices = [
                EventChoice(text: "Ask for help", effects: ChoiceEffects(education: EducationEffects(attendancePressure: -3, burnoutRisk: -2, mentorSupport: 4)), microBeat: "The ask is smaller than the silence."),
                EventChoice(text: "Compartmentalize it", effects: ChoiceEffects(education: EducationEffects(schoolStanding: 2, burnoutRisk: 3)), microBeat: "You put the worry in a box."),
                EventChoice(text: "Disappear for air", effects: ChoiceEffects(education: EducationEffects(attendancePressure: 4, schoolBelonging: -2, burnoutRisk: -1)), microBeat: "One absent day becomes tempting.", baseFriction: .resistance)
            ]
        }

        return GameEvent(
            id: "high-school-identity-\(force.id)-\(age)",
            category: .education,
            tags: ["school", "teen", "identity"],
            severity: force.tone == .volatile ? .consequential : .routine,
            title: headline,
            text: text,
            minAge: age,
            maxAge: age,
            weight: 100,
            cooldownYears: 99,
            triggerOnce: true,
            requirements: [],
            choices: Array(choices.prefix(3))
        )
    }

    private func refreshHighSchoolProfile(for education: inout EducationState) {
        let tags = education.formativeSchoolTags
        let academicShape: HighSchoolAcademicShape
        if education.pathway == .dropout || tags["discipline_scar", default: 0] >= 45 || (education.attendancePressure >= 66 && education.schoolStanding < 52) {
            academicShape = .dropoutRisk
        } else if education.academicTrack == .vocational || tags["trade_seed", default: 0] >= 28 {
            academicShape = .vocational
        } else if education.academicTrack == .honors || tags["academic_strength", default: 0] >= 30 || education.schoolStanding >= 78 {
            academicShape = .honors
        } else if tags["academic_strain", default: 0] >= 28 || education.schoolStanding <= 44 {
            academicShape = .struggling
        } else {
            academicShape = .steady
        }

        let socialShape: HighSchoolSocialShape
        if tags["volatile_social", default: 0] >= 30 || education.reputationRisk >= 62 {
            socialShape = .volatile
        } else if tags["isolation", default: 0] >= 30 || education.schoolBelonging <= 32 {
            socialShape = .isolated
        } else if tags["mentor_support", default: 0] >= 28 && education.schoolBelonging >= 55 {
            socialShape = .respected
        } else if tags["belonging", default: 0] >= 24 || education.schoolBelonging >= 60 {
            socialShape = .connected
        } else {
            socialShape = .invisible
        }

        let supportShape: HighSchoolAdultSupportShape
        if tags["adult_friction", default: 0] >= 24 || education.teacherSupport <= 30 {
            supportShape = .adversarial
        } else if tags["mentor_support", default: 0] >= 32 || education.mentorSupport >= 62 {
            supportShape = .mentored
        } else if education.teacherSupport >= 58 || education.disciplineRecord >= 78 {
            supportShape = .protected
        } else {
            supportShape = .overlooked
        }

        let pressureShape: HighSchoolPressureShape
        if tags["risk_seed", default: 0] >= 28 || education.reputationRisk >= 68 {
            pressureShape = .reckless
        } else if tags["burnout", default: 0] >= 28 || education.burnoutRisk >= 64 {
            pressureShape = .burnedOut
        } else if tags["survival_pressure", default: 0] >= 28 || education.attendancePressure >= 64 {
            pressureShape = .survivalMode
        } else {
            pressureShape = .balanced
        }

        education.highSchoolProfile = HighSchoolProfile(
            academicShape: academicShape,
            socialShape: socialShape,
            adultSupportShape: supportShape,
            pressureShape: pressureShape,
            futureSeed: resolvedFutureSeed(for: education)
        )
        education.highSchoolLegacyLine = highSchoolLegacyLine(for: education.highSchoolProfile)
    }

    private func resolvedFutureSeed(for education: EducationState) -> HighSchoolFutureSeed {
        let tags = education.formativeSchoolTags
        let candidates: [(HighSchoolFutureSeed, Int)] = [
            (.athlete, tags["athlete_seed", default: 0]),
            (.founder, tags["founder_seed", default: 0]),
            (.creator, tags["creator_seed", default: 0]),
            (.politics, tags["politics_seed", default: 0]),
            (.riskLane, tags["risk_seed", default: 0]),
            (.trade, max(tags["trade_seed", default: 0], education.academicTrack == .vocational ? 35 : 0)),
            (.academic, max(tags["academic_seed", default: 0], education.schoolStanding >= 74 ? 28 : 0))
        ]
        let winner = candidates.max { $0.1 < $1.1 }
        guard let winner, winner.1 >= 18 else { return .undecided }
        return winner.0
    }

    private func highSchoolLegacyLine(for profile: HighSchoolProfile) -> String {
        if profile.pressureShape == .burnedOut && profile.academicShape == .honors {
            return "Burned-out achiever: doors opened, but recovery became part of the bill."
        }
        if profile.socialShape == .isolated {
            return "Invisible survivor: you learned to move alone, and adulthood remembers it."
        }
        if profile.socialShape == .respected || profile.adultSupportShape == .mentored {
            return "Respected organizer: people and adults started treating your presence as real."
        }
        if profile.futureSeed == .riskLane || profile.pressureShape == .reckless {
            return "Risky hustler: the shortcut impulse became part of your adult shape."
        }
        if profile.academicShape == .vocational || profile.futureSeed == .trade {
            return "Trade-ready: practical momentum gave adulthood a sturdier first rung."
        }
        if profile.academicShape == .dropoutRisk {
            return "Drifting dropout: school pressure narrowed the launch before adulthood began."
        }
        if profile.futureSeed == .academic || profile.academicShape == .honors {
            return "Late bloomer: school started turning effort into visible future doors."
        }
        return "Steady launch: high school left options open without deciding the whole story."
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
        refreshHighSchoolProfile(for: &education)
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
            education.seniorYearOutcome = .dropoutDrift
            applyHighSchoolCarryForward(education: education, career: &career, result: &result)
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
            education.seniorYearOutcome = education.highSchoolProfile.futureSeed == .athlete || education.highSchoolProfile.futureSeed == .founder || education.highSchoolProfile.futureSeed == .creator || education.highSchoolProfile.futureSeed == .politics || education.highSchoolProfile.futureSeed == .riskLane ? .specialCareerSeed : .tradeTrack
            applyHighSchoolCarryForward(education: education, career: &career, result: &result)
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
                education.seniorYearOutcome = .scholarshipRoute
            } else if education.hasScholarship {
                routeText = "You entered university with scholarship help, trading money pressure for a heavier expectations game."
                education.seniorYearOutcome = .scholarshipRoute
            } else if finance.financialStress >= 35 {
                routeText = "You made it into a lower-cost commuter university route. It is viable, but the margin is thin."
                education.seniorYearOutcome = .commuterCollege
            } else {
                routeText = "You entered university, opening more doors but also inviting debt and burnout risk."
                education.seniorYearOutcome = education.highSchoolProfile.futureSeed == .athlete || education.highSchoolProfile.futureSeed == .founder || education.highSchoolProfile.futureSeed == .creator || education.highSchoolProfile.futureSeed == .politics || education.highSchoolProfile.futureSeed == .riskLane ? .specialCareerSeed : .universityTrack
            }
            result.notes.append(DomainNote(title: "Education", text: routeText, tags: [.education, .finance]))
            // D3: Honors/uni handoff bonus to career starting (prestige/longevity + special entry bias seed)
            if education.academicTrack == .honors {
                career.performance += 10
                career.jobSecurity += 6
                career.annualIncome += 1200 // honors starts with slight premium
                // Honors track gives lasting credential strength carry
                education.credentialStrength = max(education.credentialStrength, 80)
            } else {
                // Standard uni balanced ramp
                career.annualIncome += 400
            }
            applyHighSchoolCarryForward(education: education, career: &career, result: &result)
            return
        }

        if education.pathway == .graduate && education.applicationReadiness >= 42 {
            education.stage = .adultEd
            education.yearsInStage = 0
            // D3: Trade/vocational handoff - faster income ramp, stable start, but credential decays if not maintained
            if education.academicTrack == .vocational {
                career.performance += 7
                career.annualIncome += 3800
                career.jobSecurity += 10
                education.credentialStrength = max(education.credentialStrength, 70)
            } else {
                career.annualIncome += 800
            }
            education.studyFocus = education.studyFocus ?? .generalStudies
            career.status = .partTime
            education.seniorYearOutcome = .adultEdRebuild
            applyHighSchoolCarryForward(education: education, career: &career, result: &result)
            result.notes.append(DomainNote(title: "Education", text: "You left school without a clean university launch and moved into a slower adult-ed route."))
            return
        }

        education.stage = .inactive
        career.status = .unemployed
        education.seniorYearOutcome = education.pathway == .graduate ? .earlyWorkRoute : .dropoutDrift
        applyHighSchoolCarryForward(education: education, career: &career, result: &result)
        result.notes.append(DomainNote(title: "Education", text: "Adulthood arrived without a stable education path. Work and drift now compete for the same space."))
    }

    private func applyHighSchoolCarryForward(
        education: EducationState,
        career: inout CareerState,
        result: inout DomainYearResult
    ) {
        let profile = education.highSchoolProfile
        var publicReputation = 0
        var privateReputation = 0
        var rumorHeat = 0
        var healthMental = 0
        var healthStress = 0
        var fame: FameEffects?

        switch profile.academicShape {
        case .honors:
            career.performance = (career.performance + 4).clamped(to: 0...100)
            career.jobSecurity = (career.jobSecurity + 2).clamped(to: 0...100)
        case .steady:
            career.performance = (career.performance + 1).clamped(to: 0...100)
        case .struggling:
            career.performance = (career.performance - 2).clamped(to: 0...100)
        case .vocational:
            career.jobSecurity = (career.jobSecurity + 4).clamped(to: 0...100)
            career.annualIncome += 500
        case .dropoutRisk:
            career.jobSecurity = (career.jobSecurity - 4).clamped(to: 0...100)
            career.performance = (career.performance - 3).clamped(to: 0...100)
        }

        switch profile.socialShape {
        case .connected:
            privateReputation += 3
        case .respected:
            publicReputation += 4
            privateReputation += 2
        case .invisible:
            privateReputation -= 1
        case .isolated:
            privateReputation -= 4
            healthMental -= 1
        case .volatile:
            publicReputation -= 3
            rumorHeat += 5
        }

        switch profile.adultSupportShape {
        case .mentored:
            career.jobSecurity = (career.jobSecurity + 3).clamped(to: 0...100)
            privateReputation += 2
        case .protected:
            career.jobSecurity = (career.jobSecurity + 1).clamped(to: 0...100)
        case .overlooked:
            break
        case .adversarial:
            publicReputation -= 2
            rumorHeat += 3
        }

        switch profile.pressureShape {
        case .balanced:
            healthStress += 1
        case .burnedOut:
            healthMental -= 2
            healthStress -= 3
            career.burnout = (career.burnout + 3).clamped(to: 0...100)
        case .survivalMode:
            healthMental -= 1
            healthStress -= 2
        case .reckless:
            rumorHeat += 4
            publicReputation -= 1
        }

        switch profile.futureSeed {
        case .creator:
            fame = FameEffects(culturalFame: 2, addKnownFor: "High-school creator")
        case .athlete:
            fame = FameEffects(culturalFame: 1, addKnownFor: "High-school athlete")
        case .politics:
            fame = FameEffects(culturalFame: 1, addKnownFor: "Student leader")
        case .riskLane:
            fame = FameEffects(notoriety: 2, addKnownFor: "Risky youth")
        case .founder:
            career.performance = (career.performance + 2).clamped(to: 0...100)
        case .academic, .trade, .undecided:
            break
        }

        if publicReputation != 0 || privateReputation != 0 || rumorHeat != 0 {
            result.relationshipEffects = RelationshipEffects(
                publicReputationChange: publicReputation == 0 ? nil : publicReputation,
                privateReputationChange: privateReputation == 0 ? nil : privateReputation,
                rumorHeatChange: rumorHeat == 0 ? nil : rumorHeat
            )
        }
        if healthMental != 0 || healthStress != 0 {
            result.healthEffects = HealthEffects(
                mental: healthMental == 0 ? nil : healthMental,
                stressManagement: healthStress == 0 ? nil : healthStress
            )
        }
        if let fame {
            result.fameEffects = fame
        }

        result.notes.append(
            DomainNote(
                title: seniorHeadline(for: education),
                text: education.highSchoolLegacyLine,
                tags: [.education, .progress]
            )
        )
    }

    private func seniorHeadline(for education: EducationState) -> String {
        switch education.seniorYearOutcome {
        case .scholarshipRoute: return "Scholarship Route Opened"
        case .commuterCollege: return "Commuter College Launch"
        case .universityTrack: return "University Track Opened"
        case .tradeTrack: return "Trade Track Took Shape"
        case .adultEdRebuild: return "Adult Rebuild Begins"
        case .dropoutDrift: return "School Drift Became Real"
        case .earlyWorkRoute: return "Early Work Route Begins"
        case .specialCareerSeed: return "A Future Seed Carried"
        case .unresolved: return "High School Shape Set"
        }
    }

    private func advancePostSecondaryStage(
        player: Player,
        education: inout EducationState,
        military: inout MilitaryState,
        career: inout CareerState,
        finance: FinanceState,
        health: HealthState,
        result: inout DomainYearResult,
        childhoodDossier: ChildhoodDossier? = nil  // D3 for branch flavor
    ) {
        // GI Bill Benefit
        if military.hasGIBill && (education.stage == .university || education.stage == .tradeTraining) {
            result.financeEffects = FinanceEffects(educationCostDelta: -10000) // Cover tuition
            result.notes.append(DomainNote(title: "GI Bill", text: "Your GI Bill benefits covered your tuition costs this year.", tags: [.education, .finance]))
        }

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

            // ROTC Stipend and Discipline
            if education.pathway == .rotc {
                var fin = result.financeEffects ?? FinanceEffects()
                fin.annualIncomeDelta = (fin.annualIncomeDelta ?? 0) + 4000
                result.financeEffects = fin
                military.discipline += 5
                military.fitness += 3
            }

            // D3: Education branch mechanical effects (trade fast income ramp + slow decay, honors longevity/prestige + special bias, standard balanced with faster fade)
            education.yearsSinceCredential += 1
            if education.academicTrack == .vocational {
                education.activityMomentum += 4
                education.applicationReadiness += 3
                // Trade: practice maintains credential; slow decay
                if education.yearsSinceCredential > 6 && education.credentialStrength > 40 {
                    education.credentialStrength -= 1
                }
            } else if education.academicTrack == .honors {
                education.schoolStanding += 3
                education.burnoutRisk += 2
                // Honors: high starting strength, slow decay, prestige lingers
                if education.yearsSinceCredential > 10 && education.credentialStrength > 50 {
                    education.credentialStrength -= 1
                }
            } else {
                // Standard/general: balanced but credential fades faster without maintenance
                if education.yearsSinceCredential > 4 && education.credentialStrength > 30 {
                    education.credentialStrength -= 2
                }
            }

            // P4: D4 life-shape tuning for credential value (driven stances slow decay, loose accelerates; ties education to later career shape)
            if let d = childhoodDossier, d.aptitudes.analytical >= 60 || d.aptitudes.entrepreneurial >= 60 {
                if education.yearsSinceCredential > 5 {
                    education.credentialStrength = max(20, education.credentialStrength - 1) // "driven" origin resists fade less? wait, actually amplify D4
                }
            }
            // Light dossier flavor in branch drift (side effect only)
            if let d = childhoodDossier {
                if d.aptitudes.technical >= 60 && education.academicTrack == .vocational {
                    education.credentialStrength = min(100, education.credentialStrength + 1)
                }
                if d.aptitudes.analytical >= 65 && education.academicTrack == .honors {
                    education.schoolStanding = min(100, education.schoolStanding + 1)
                }
            }

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
                
                // Specialized Degree Logic
                if education.studyFocus == .medicine {
                    education.credentials.append("MD")
                } else if education.studyFocus == .law {
                    education.credentials.append("JD")
                } else if education.studyFocus == .computerScience {
                    education.credentials.append("CS Degree")
                }
                
                if education.pathway == .rotc {
                    result.notes.append(DomainNote(title: "ROTC Commission", text: "You graduated and received your commission as an officer!", tags: [.education, .career]))
                    // We'll let MilitarySystem handle the actual track change if it detects this state
                } else {
                    result.notes.append(DomainNote(title: "Education", text: "You completed university. The degree helps, but it did not erase the pressure it took to get there. (Credential value now set by track: honors lingers, standard fades without refresh. Era swings income ramps in finance layer.)", tags: [.education, .career]))
                }
            }
        case .tradeTraining:
            education.schoolStanding = (education.schoolStanding + 3 + ((education.disciplineRecord - 60) / 18)).clamped(to: 0...100)
            education.burnoutRisk = (education.burnoutRisk + (career.status == .partTime ? 3 : 0) - 2).clamped(to: 0...100)
            if education.yearsInStage >= 2 && !education.credentials.contains("Trade Certificate") {
                education.credentials.append("Trade Certificate")
                education.pathway = .training
                education.credentialStrength = max(education.credentialStrength, 68)
                education.yearsSinceCredential = 0
                result.notes.append(DomainNote(title: "Education", text: "You earned a trade certificate that improves your work prospects. (Fast ramp; holds via hands-on use.)"))
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
        advanceYear(
            housing: &housing,
            player: input.player,
            finance: input.finance,
            assets: input.assets,
            reentryFrictionYears: input.reentryFrictionYears,
            recordPressure: input.recordPressure
        )
    }

    func advanceYear(
        housing: inout HousingState,
        player: Player,
        finance: FinanceState,
        assets: AssetState,
        reentryFrictionYears: Int = 0,
        recordPressure: Int = 0
    ) -> DomainYearResult {
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

        if reentryFrictionYears > 0 || recordPressure >= 45 {
            housing.housingStability = (housing.housingStability - (reentryFrictionYears > 0 ? 5 : 3)).clamped(to: 0...100)
            if reentryFrictionYears >= 2, !assets.ownsHome, result.notes.isEmpty {
                result.notes.append(DomainNote(title: "Reentry Housing", text: "Landlords read your record before they read your application.", tags: [.legal, .housing]))
            }
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

// D1+: Identity static instants — dossier, resilience, shape, fame depth
private func applyIdentityAction(_ choiceID: ActionChoiceID, state: inout GameState) -> DomainYearResult {
    var result = DomainYearResult()
    let grounded = StaticInstantActionFlavor.isGrounded(state)
    let resilient = StaticInstantActionFlavor.isResilient(state)

    switch choiceID {
    case .morningReflection:
        let mental = StaticInstantActionFlavor.resilienceScaled(state, grounded: 6, resilient: 4)
        state.identityCoherence = (state.identityCoherence + mental).clamped(to: 0...100)
        state.healthProfile.mentalWellness = (state.healthProfile.mentalWellness + mental).clamped(to: 0...100)
        StaticInstantActionFlavor.publishPulse(&state, domain: "identity", strength: 18)
        var note = "You sat with the quiet version of yourself. The year felt a fraction more yours."
        if StaticInstantActionFlavor.dossierAnalytical(state) {
            note = "The analytical wiring from before 14 made the reflection sharper — you named the pattern, not just the feeling."
        }
        result.notes.append(DomainNote(title: "Reflection", text: note, tags: [.health, .identity]))

    case .reconcileWithPast:
        state.identityCoherence = (state.identityCoherence + 8).clamped(to: 0...100)
        state.healthProfile.mentalWellness = (state.healthProfile.mentalWellness + 5).clamped(to: 0...100)
        var text = "You made a little peace with the shape you were given at 14."
        if let streak = StaticInstantActionFlavor.stanceStreakLine(state) {
            text += " \(streak)"
        }
        StaticInstantActionFlavor.publishPulse(&state, domain: "identity", strength: 17)
        result.notes.append(DomainNote(title: "Reconciled", text: text, tags: [.family, .identity]))

    case .protectYourEnergy:
        let mental = StaticInstantActionFlavor.resilienceScaled(state, grounded: 8, resilient: 5)
        state.healthProfile.mentalWellness = (state.healthProfile.mentalWellness + mental).clamped(to: 0...100)
        state.consequences.adjustPressure(domain: "health", delta: grounded ? -4 : -2)
        state.consequences.adjustPressure(domain: "career", delta: -2)
        state.career.burnout = max(0, state.career.burnout - StaticInstantActionFlavor.resilienceScaled(state, grounded: 6, resilient: 3))
        let energyNote = grounded
            ? "You drew a hard line and it actually worked. The air cleared faster than you expected."
            : "You stopped letting everything drain you at once. Recovery became deliberate."
        StaticInstantActionFlavor.publishPulse(&state, domain: "identity", strength: 16)
        result.notes.append(DomainNote(title: "Energy Guard", text: energyNote, tags: [.health, .identity, .career]))

    case .tryNewPersona:
        state.identityCoherence = (state.identityCoherence + 4).clamped(to: 0...100)
        state.relationships.publicReputation = (state.relationships.publicReputation + 5).clamped(to: 0...100)
        state.specialCareer.audience = min(100, state.specialCareer.audience + 3)
        var personaText = "You tried on a different version of yourself in public."
        personaText += StaticInstantActionFlavor.fameGravitySuffix(
            state,
            highFame: " People noticed the shift — some liked it, some miss the old story.",
            lowFame: " Some people liked it. Some people miss the old one."
        )
        StaticInstantActionFlavor.publishPulse(&state, domain: "identity", strength: 15)
        result.notes.append(DomainNote(title: "New Persona", text: personaText, tags: [.social, .identity, .risk]))

    case .publicReset:
        state.identityCoherence = (state.identityCoherence + 5).clamped(to: 0...100)
        state.relationships.publicReputation = (state.relationships.publicReputation + 7).clamped(to: 0...100)
        state.specialCareer.fame = max(0, state.specialCareer.fame - 3)
        result.notes.append(DomainNote(title: "Public Reset", text: "You told the world a cleaner version of the story. The old one still exists in the comments.", tags: [.social, .career]))

    case .therapySession:
        state.identityCoherence = (state.identityCoherence + 9).clamped(to: 0...100)
        state.healthProfile.mentalWellness = (state.healthProfile.mentalWellness + 7).clamped(to: 0...100)
        result.financeEffects = FinanceEffects(cashDelta: -120)
        result.notes.append(DomainNote(title: "Therapy", text: "You paid someone to help you hear yourself.", tags: [.health, .finance]))

    case .processCrisis:
        state.identityCoherence = (state.identityCoherence + 12).clamped(to: 0...100)
        if grounded {
            state.healthProfile.mentalWellness = (state.healthProfile.mentalWellness + 4).clamped(to: 0...100)
            result.notes.append(DomainNote(title: "Identity Work", text: "You stopped running from the fracture. In a Grounded life, facing it felt like fighting back — and winning a round.", tags: [.health, .identity, .risk]))
        } else if resilient {
            state.healthProfile.mentalWellness = (state.healthProfile.mentalWellness - 1).clamped(to: 0...100)
            result.notes.append(DomainNote(title: "Identity Work", text: "You absorbed the hit and kept moving. The clarity is real, but the scar stayed visible.", tags: [.health, .identity, .risk]))
        } else {
            state.healthProfile.mentalWellness = (state.healthProfile.mentalWellness - 2).clamped(to: 0...100)
            result.notes.append(DomainNote(title: "Identity Work", text: "You stopped running from the fracture. The pieces are still sharp, but they are on the table now.", tags: [.health, .identity, .risk]))
        }
        state.consequences.adjustPressure(domain: "health", delta: 3)
        StaticInstantActionFlavor.publishPulse(&state, domain: "identity", strength: 20)

    case .journalTheShape:
        state.identityCoherence = (state.identityCoherence + 5).clamped(to: 0...100)
        state.healthProfile.mentalWellness = (state.healthProfile.mentalWellness + 4).clamped(to: 0...100)
        StaticInstantActionFlavor.publishPulse(&state, domain: "identity", strength: 22)
        let shapeLine = StaticInstantActionFlavor.shapeResidueLine(state) ?? "You wrote down who you've been lately before the year could decide for you."
        result.notes.append(DomainNote(title: "Shape Named", text: shapeLine, tags: [.identity, .progress]))

    case .quietTheNoise:
        state.healthProfile.mentalWellness = (state.healthProfile.mentalWellness + 5).clamped(to: 0...100)
        state.relationships.activeRumorHeat = max(0, state.relationships.activeRumorHeat - StaticInstantActionFlavor.resilienceScaled(state, grounded: 10, resilient: 6))
        if state.fame.notoriety >= 40 {
            state.fame.notoriety = max(0, state.fame.notoriety - 2)
        }
        StaticInstantActionFlavor.publishPulse(&state, domain: "identity", strength: 16)
        result.notes.append(DomainNote(
            title: "Noise Down",
            text: "You stepped away from the story other people were telling about you." + StaticInstantActionFlavor.fameGravitySuffix(state, highFame: " Even the loud version of your name got quieter for a night."),
            tags: [.identity, .social]
        ))

    default:
        break
    }
    state.identityCoherence = state.identityCoherence.clamped(to: 0...100)
    state.player.clampStats()
    return result
}

// Static play / hobby instant actions — recovery, dossier, resilience depth
private func applyPlayAction(_ choiceID: ActionChoiceID, state: inout GameState) -> DomainYearResult {
    var result = DomainYearResult()
    let grounded = StaticInstantActionFlavor.isGrounded(state)
    switch choiceID {
    case .hobbySession:
        state.activities.recoveryBalance = (state.activities.recoveryBalance + 6).clamped(to: 0...100)
        state.healthProfile.mentalWellness = (state.healthProfile.mentalWellness + 4).clamped(to: 0...100)
        state.player.happiness = (state.player.happiness + 3).clamped(to: 0...100)
        var hobbyText = "You lost an hour to something that exists only because you like it. The year feels lighter."
        if StaticInstantActionFlavor.dossierSocial(state) {
            hobbyText = "The social wiring from 14 made the hobby feel like belonging, not escape."
        }
        StaticInstantActionFlavor.publishPulse(&state, domain: "play", strength: 14)
        result.notes.append(DomainNote(title: "Hobby Time", text: hobbyText, tags: [.health, .identity]))
    case .socialOuting:
        state.activities.recoveryBalance = (state.activities.recoveryBalance + 4).clamped(to: 0...100)
        state.player.happiness = (state.player.happiness + 5).clamped(to: 0...100)
        if !state.relationships.friends.isEmpty {
            state.relationships.friends[0].bond = (state.relationships.friends[0].bond + 4).clamped(to: 0...100)
        }
        result.financeEffects = FinanceEffects(cashDelta: -40)
        var outingText = "You showed up in person. The group chat energy finally matched real life."
        outingText += StaticInstantActionFlavor.fameGravitySuffix(state, highFame: " A few phones came out anyway.")
        StaticInstantActionFlavor.publishPulse(&state, domain: "play", strength: 15)
        result.notes.append(DomainNote(title: "Out With People", text: outingText, tags: [.relationships, .social]))
    case .creativeOutlet:
        state.identityCoherence = (state.identityCoherence + 5).clamped(to: 0...100)
        state.healthProfile.mentalWellness = (state.healthProfile.mentalWellness + 5).clamped(to: 0...100)
        state.activities.recoveryBalance = (state.activities.recoveryBalance + 3).clamped(to: 0...100)
        if state.specialCareer.track == .contentCreator {
            state.specialCareer.audience = min(100, state.specialCareer.audience + 2)
        }
        StaticInstantActionFlavor.publishPulse(&state, domain: "play", strength: 16)
        result.notes.append(DomainNote(title: "Creative Hour", text: "You made something that nobody assigned. It reminded you who you are outside the grind.", tags: [.identity, .health]))
    case .adventure:
        state.activities.riskLoad = (state.activities.riskLoad + 3).clamped(to: 0...100)
        state.player.happiness = (state.player.happiness + 6).clamped(to: 0...100)
        state.healthProfile.mentalWellness = (state.healthProfile.mentalWellness + 2).clamped(to: 0...100)
        result.financeEffects = FinanceEffects(cashDelta: -120)
        var adventureText = grounded
            ? "You chased a little chaos on purpose — but you picked the version you could survive."
            : "You chased a little chaos on purpose. The story is worth more than the cost."
        if state.fame.notoriety >= 40 {
            adventureText += " Someone almost turned it into content."
        }
        StaticInstantActionFlavor.publishPulse(&state, domain: "play", strength: 17)
        result.notes.append(DomainNote(title: "Adventure", text: adventureText, tags: [.risk, .health]))
    case .relaxRoutine:
        let mental = StaticInstantActionFlavor.resilienceScaled(state, grounded: 8, resilient: 5)
        state.activities.recoveryBalance = (state.activities.recoveryBalance + 8).clamped(to: 0...100)
        state.activities.riskLoad = max(0, state.activities.riskLoad - 2)
        state.healthProfile.mentalWellness = (state.healthProfile.mentalWellness + mental).clamped(to: 0...100)
        state.career.burnout = max(0, state.career.burnout - StaticInstantActionFlavor.resilienceScaled(state, grounded: 4, resilient: 2))
        StaticInstantActionFlavor.publishPulse(&state, domain: "play", strength: 18)
        result.notes.append(DomainNote(title: "Downshift", text: grounded ? "You built a deliberate slow patch into the year. Recovery is finally audible — and earned." : "You built a deliberate slow patch into the year. Recovery is finally audible.", tags: [.health, .career]))
    default:
        break
    }
    state.player.clampStats()
    return result
}

struct ActionSystem {
    private let educationSystem: EducationSystem
    private let careerSystem: CareerSystem
    private let specialCareerSystem: SpecialCareerSystem
    private let militarySystem: MilitarySystem
    private let crimeSystem: CrimeSystem
    private let legalSystem: LegalSystem
    private let relationshipSystem: RelationshipSystem
    private let familySystem: FamilySystem
    private let luxurySystem: LuxurySystem
    private let financeSystem: FinanceSystem
    private let healthSystem: HealthSystem
    private let effectApplier: DomainEffectApplier

    init(
        educationSystem: EducationSystem = EducationSystem(),
        careerSystem: CareerSystem = CareerSystem(),
        specialCareerSystem: SpecialCareerSystem = SpecialCareerSystem(),
        militarySystem: MilitarySystem = MilitarySystem(),
        crimeSystem: CrimeSystem = CrimeSystem(),
        legalSystem: LegalSystem = LegalSystem(),
        familySystem: FamilySystem = FamilySystem(),
        luxurySystem: LuxurySystem = LuxurySystem(),
        financeSystem: FinanceSystem = FinanceSystem(),
        relationshipSystem: RelationshipSystem = RelationshipSystem(),
        healthSystem: HealthSystem = HealthSystem(),
        effectApplier: DomainEffectApplier = DomainEffectApplier()
    ) {
        self.educationSystem = educationSystem
        self.careerSystem = careerSystem
        self.specialCareerSystem = specialCareerSystem
        self.militarySystem = militarySystem
        self.crimeSystem = crimeSystem
        self.legalSystem = legalSystem
        self.familySystem = familySystem
        self.luxurySystem = luxurySystem
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
                actionResult = educationSystem.applyAction(action.choiceID, player: &state.player, education: &state.education, childhoodDossier: state.childhoodDossier, specialCareer: &state.specialCareer)
            case .career:
                if specialCareerSystem.handles(action.choiceID) {
                    actionResult = specialCareerSystem.applyAction(action.choiceID, player: &state.player, career: &state.career, specialCareer: &state.specialCareer, childhoodDossier: state.childhoodDossier, finance: &state.finance)
                } else {
                    actionResult = careerSystem.applyAction(action.choiceID, state: &state)
                }
            case .military:
                actionResult = militarySystem.applyAction(action.choiceID, player: &state.player, military: &state.military, career: &state.career, education: state.education)
            case .crime:
                actionResult = crimeSystem.applyAction(action.choiceID, player: &state.player, career: &state.career, crime: &state.crime)
            case .legal:
                actionResult = legalSystem.applyAction(action.choiceID, legal: &state.legal, finance: &state.finance, fame: &state.fame)
            case .finance:
                let homeOwnershipSystem = HomeOwnershipSystem()
                if homeOwnershipSystem.isInstantHomeAction(action.choiceID) {
                    actionResult = homeOwnershipSystem.applyInstantAction(action.choiceID, state: &state)
                } else if [.hostLuxuryEvent, .acquireLuxuryAsset, .indulgeInExcess, .displayWealth, .maintainLuxuryCollection].contains(action.choiceID) {
                    actionResult = luxurySystem.applyAction(action.choiceID, state: state)
                } else {
                    actionResult = financeSystem.applyAction(action.choiceID, state: &state)
                }
            case .relationships:
                actionResult = relationshipSystem.applyAction(action.choiceID, state: &state)
            case .health:
                actionResult = healthSystem.applyAction(action.choiceID, state: &state)
            case .family:
                actionResult = familySystem.applyAction(action.choiceID, state: &state)
            case .identity:
                // D1: Light identity apply — always instant self-work with dossier/ledger flavor
                actionResult = applyIdentityAction(action.choiceID, state: &state)
            case .play:
                actionResult = applyPlayAction(action.choiceID, state: &state)
            }

            effectApplier.apply(
                result: actionResult,
                to: &state,
                trajectorySystem: TrajectorySystem(),
                educationSystem: educationSystem,
                careerSystem: careerSystem,
                specialCareerSystem: specialCareerSystem,
                militarySystem: militarySystem,
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
        state.military.clamp()
        state.crime.clamp()
        state.legal.clamp()
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
        if let combatFightSummary = source.combatFightSummary {
            target.combatFightSummary = combatFightSummary
        }
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
        CareerRoleDefinition(id: "sales_manager", title: "Sales Manager", profile: .stableAdmin, status: .fullTime, level: 5, annualIncome: 66_000, minAge: 25, nextRoleID: nil, minimumYearsWorked: 5, primaryExperienceTag: .sales, secondaryExperienceTags: [.management], bridgeTags: [.sales, .management], isManagementRole: true),

        CareerRoleDefinition(id: "middle_school_coach", title: "Middle School Coach", profile: .serviceFrontline, status: .partTime, level: 2, annualIncome: 8_000, minAge: 18, nextRoleID: "high_school_assistant_coach", requiredCredentials: ["Diploma"], primaryExperienceTag: .coaching, secondaryExperienceTags: [.service]),
        CareerRoleDefinition(id: "high_school_assistant_coach", title: "High School Assistant Coach", profile: .serviceFrontline, status: .fullTime, level: 3, annualIncome: 28_000, minAge: 21, nextRoleID: "high_school_head_coach", minimumYearsWorked: 2, primaryExperienceTag: .coaching, secondaryExperienceTags: [.management, .service], bridgeTags: [.coaching]),
        CareerRoleDefinition(id: "high_school_head_coach", title: "High School Head Coach", profile: .stableAdmin, status: .fullTime, level: 4, annualIncome: 46_000, minAge: 24, nextRoleID: "juco_assistant_coach", minimumYearsWorked: 4, primaryExperienceTag: .coaching, secondaryExperienceTags: [.management], bridgeTags: [.coaching, .management], isManagementRole: true),
        CareerRoleDefinition(id: "juco_assistant_coach", title: "JUCO Assistant Coach", profile: .stableAdmin, status: .fullTime, level: 5, annualIncome: 58_000, minAge: 27, nextRoleID: "university_assistant_coach", requiredCredentials: ["Degree"], minimumYearsWorked: 5, primaryExperienceTag: .coaching, secondaryExperienceTags: [.management, .sales], bridgeTags: [.coaching, .management], isManagementRole: true),
        CareerRoleDefinition(id: "university_assistant_coach", title: "University Assistant Coach", profile: .credentialedProfessional, status: .fullTime, level: 6, annualIncome: 86_000, minAge: 30, nextRoleID: nil, requiredCredentials: ["Degree"], minimumYearsWorked: 7, primaryExperienceTag: .coaching, secondaryExperienceTags: [.management, .sales], bridgeTags: [.coaching, .management], isManagementRole: true)
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
        if player.traits.contains(.charismatic), role.primaryExperienceTag == .sales || role.primaryExperienceTag == .creative || role.primaryExperienceTag == .coaching { score += 6 }
        if player.traits.contains(.disciplined), role.primaryExperienceTag == .coaching { score += 5 }
        score += aptitudeScore(for: role, player: player, childhoodDossier: childhoodDossier) / 12
        return score
    }

    private static func aptitudeScore(for role: CareerRoleDefinition, player: Player, childhoodDossier: ChildhoodDossier?) -> Int {
        guard let aptitudes = childhoodDossier?.aptitudes else {
            switch role.primaryExperienceTag {
            case .technical, .healthcare: return player.smarts
            case .creative, .sales, .service, .admin: return player.happiness
            case .coaching: return max(player.smarts, player.health)
            case .labor: return player.health
            case .management: return max(player.smarts, player.happiness)
            }
        }
        switch role.primaryExperienceTag {
        case .service, .sales, .admin, .management:
            return aptitudes.social
        case .coaching:
            return max(aptitudes.physical, aptitudes.social, aptitudes.analytical)
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
        if input.reentryFrictionYears > 0, career.status == .fullTime {
            let cap = input.custodyProgramCompleted ? 58 : 48
            career.jobSecurity = min(career.jobSecurity, cap)
        }
        if input.recordPressure >= 50 || input.reentryFrictionYears > 0 {
            if career.regularArchetype == .corporateClimber {
                career.jobSecurity = min(career.jobSecurity, input.custodyProgramCompleted ? 52 : 42)
            }
            if career.regularArchetype == .skilledTrades, input.recordPressure >= 60 {
                career.jobSecurity = min(career.jobSecurity, 50)
            }
        }
        if input.prisonResidueTags.contains("hardened"), career.regularArchetype == .salesNetworker {
            career.performance = min(100, career.performance + 1)
        }
        if input.prisonResidueTags.contains("institutionalized") {
            career.jobSecurity = min(career.jobSecurity, 38)
            career.burnout = min(100, career.burnout + 3)
        }
        if input.prisonResidueTags.contains("straightPath") {
            career.performance = min(100, career.performance + 2)
            career.jobSecurity = min(100, career.jobSecurity + 2)
        }
        if input.prisonResidueTags.contains("insideContactOutside") {
            career.performance = min(100, career.performance + 1)
            career.jobSecurity = min(100, career.jobSecurity + 1)
        }
        if input.prisonResidueTags.contains("unfinishedInsideConflict") {
            career.burnout = min(100, career.burnout + 2)
            career.jobSecurity = max(0, career.jobSecurity - 1)
        }
        return advanceYear(
            player: &player,
            career: &career,
            education: input.education,
            health: input.health,
            relationships: input.relationships,
            childhoodDossier: input.childhoodDossier,
            recentStances: input.recentStances,
            resilience: input.resilience
        )
    }

    func advanceYear(
        player: inout Player,
        career: inout CareerState,
        education: EducationState,
        health: HealthState,
        relationships: RelationshipState,
        childhoodDossier: ChildhoodDossier? = nil,
        recentStances: [YearlyStanceID] = [],
        resilience: LifeResilience = .resilient
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

        // Specialized Career Logic (Phase 5)
        if let track = career.specializedTrack {
            switch track {
            case .medical:
                if career.professionalRank == "Resident" {
                    career.burnout += 15
                    career.performance += 5
                    if career.yearsWorked >= 4 && career.performance >= 75 {
                        career.professionalRank = "Attending"
                        career.annualIncome = 220000
                        result.notes.append(DomainNote(title: "Board Certified", text: "You completed your residency and are now an Attending Physician. Your salary has increased dramatically.", tags: [.career, .finance, .lifeEvent]))
                    }
                } else if career.professionalRank == "Attending" {
                    if career.performance >= 85 && career.yearsWorked >= 10 {
                        career.professionalRank = "Surgeon"
                        career.annualIncome = 450000
                        result.notes.append(DomainNote(title: "Peak Medicine", text: "You have reached the rank of Surgeon. You are a leader in your field.", tags: [.career, .fame]))
                    }
                }
            case .law:
                if career.professionalRank == "Law Clerk" {
                    if education.credentials.contains("JD") && player.smarts >= 75 {
                        career.professionalRank = "Associate"
                        career.annualIncome = 160000
                        result.notes.append(DomainNote(title: "Bar Passed", text: "You passed the Bar and joined the firm as an Associate.", tags: [.career, .finance]))
                    }
                } else if career.professionalRank == "Associate" {
                    if career.performance >= 80 && relationships.socialCapital >= 60 {
                        career.professionalRank = "Partner"
                        career.annualIncome = 350000
                        result.notes.append(DomainNote(title: "Partnered", text: "You have been made Partner. You now own a piece of the firm.", tags: [.career, .finance, .social]))
                    }
                }
            case .tech:
                if career.professionalRank == "Junior Developer" && career.yearsWorked >= 2 {
                    career.professionalRank = "Senior Developer"
                    career.annualIncome = 140000
                } else if career.professionalRank == "Senior Developer" && player.smarts >= 80 && career.performance >= 80 {
                    career.professionalRank = "CTO"
                    career.annualIncome = 280000
                    result.notes.append(DomainNote(title: "Executive", text: "You have been appointed CTO. The technical direction of the company is in your hands.", tags: [.career, .fame]))
                }
            case .corporateFinance:
                if career.professionalRank == "Analyst" && career.yearsWorked >= 3 {
                    career.professionalRank = "Associate"
                    career.annualIncome = 150000
                } else if career.professionalRank == "Associate" && career.performance >= 85 {
                    career.professionalRank = "VP"
                    career.annualIncome = 300000
                }
            }
        }

        if let role = CareerCatalog.definition(for: career.roleID) {
            career.profile = role.profile
            career.status = role.status
            career.level = role.level
            career.annualIncome = adjustedIncome(for: role, career: career, player: player)
            career.yearsWorked += 1
            accrueExperience(from: role, on: &career)
            career.unemployedYears = 0
            result.notes.append(DomainNote(title: "Career", text: "Your \(role.title) role is still carrying the year, but the way it presses on your life is getting harder to ignore.", tags: [.career]))
            if role.primaryExperienceTag == .coaching {
                let seasonScore = career.performance + career.experience(for: .coaching) * 4 + (childhoodDossier?.aptitudes.social ?? player.happiness) / 5 + (player.smarts - 50) / 4
                let wins = (seasonScore / 12).clamped(to: 1...11)
                let losses = max(1, 12 - wins)
                let seasonLine: String
                if wins >= 9 {
                    seasonLine = "Your team went \(wins)-\(losses). Parents are talking, players are buying in, and better programs may eventually notice."
                    career.performance = min(100, career.performance + 4)
                } else if wins <= 3 {
                    seasonLine = "Your team went \(wins)-\(losses). The season exposed roster gaps, thin staff, and how lonely the sideline can get."
                    career.performance = max(0, career.performance - 3)
                } else {
                    seasonLine = "Your team went \(wins)-\(losses). Not a miracle, not a collapse. Just another year of teaching people how to compete."
                }
                result.notes.append(DomainNote(title: "Season Summary", text: seasonLine, tags: [.career, .progress]))
            }

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

        // D3: Regular career archetype-differentiated curves + aging + education credential carry (parity with deep specials)
        if career.specializedTrack == nil {
            let credBonus = (education.credentialStrength - 55) / 14   // from D3 edu track strength/decay
            career.performance = (career.performance + credBonus).clamped(to: 0...100)

            // P3: richer regular career "End of the Road" notes when burnout or age claims the shape
            if career.burnout >= 80 || (player.age >= 60 && career.performance < 40) {
                let shapeNote = career.regularArchetype.map { " The \( $0.displayName.lowercased()) life you chose left its mark." } ?? ""
                result.notes.append(DomainNote(title: "The End of the Road", text: "The work that defined the years is no longer the thing that defines you.\(shapeNote)", tags: [.career, .progress]))
            }

            switch career.regularArchetype {
            case .corporateClimber:
                // Steady climber: high security, slow burnout, political drag, ages gracefully until late
                career.jobSecurity = (career.jobSecurity + 2).clamped(to: 0...100)
                if player.age > 50 { career.performance = (career.performance - 1).clamped(to: 0...100) }
            case .gigFreelancer:
                // High variance: income swings, burnout higher, security lower, ages faster but can pivot
                career.jobSecurity = (career.jobSecurity - 1).clamped(to: 0...100)
                career.burnout = (career.burnout + 1).clamped(to: 0...100)
                if player.age > 42 { career.performance = (career.performance - 2).clamped(to: 0...100) }
            case .skilledTrades:
                // Durable: low burnout, strong security from demand, physical aging but skill holds
                career.burnout = (career.burnout - 1).clamped(to: 0...100)
                career.jobSecurity = (career.jobSecurity + 1).clamped(to: 0...100)
                if player.age > 55 { career.performance = (career.performance - 1).clamped(to: 0...100) }
            case .publicService:
                // Mission security: very high security, pension drag on income, ages very slowly
                career.jobSecurity = (career.jobSecurity + 3).clamped(to: 0...100)
                career.annualIncome = Int(Double(career.annualIncome) * 0.98)
                if player.age > 60 { career.performance = (career.performance - 1).clamped(to: 0...100) }
            case .techEngineer:
                // High ceiling: perf grows with skill, burnout from intensity, security from scarcity but ages on obsolescence
                career.performance = (career.performance + 1).clamped(to: 0...100)
                career.burnout = (career.burnout + 2).clamped(to: 0...100)
                if player.age > 48 { career.performance = (career.performance - 2).clamped(to: 0...100) }
            case .salesNetworker:
                let commissionSwing = Int.random(in: -12...18)
                career.performance = (career.performance + commissionSwing / 4).clamped(to: 0...100)
                career.burnout = (career.burnout + (commissionSwing < 0 ? 2 : 1)).clamped(to: 0...100)
                if commissionSwing > 10 {
                    career.annualIncome = Int(Double(career.annualIncome) * 1.06)
                } else if commissionSwing < -8 {
                    career.annualIncome = Int(Double(career.annualIncome) * 0.94)
                }
            case .creativeProfessional:
                career.burnout = (career.burnout + 1).clamped(to: 0...100)
                if career.performance > 65 { career.annualIncome = Int(Double(career.annualIncome) * 1.04) }
                if player.age > 50 { career.jobSecurity = max(0, career.jobSecurity - 1) }
            case .careLabor:
                career.burnout = (career.burnout + 2).clamped(to: 0...100)
                career.jobSecurity = (career.jobSecurity + 1).clamped(to: 0...100)
                career.relationshipSpillover = (career.relationshipSpillover + 1).clamped(to: 0...100)
            case nil:
                if player.age > 45 {
                    career.performance = (career.performance - 1).clamped(to: 0...100)
                }
            }

            // D5 + P4: D4 life-shape tuning on regular archetypes (driven vs loose feel different per path)
            if career.specializedTrack == nil, let arch = career.regularArchetype {
                let shape = LifeShapeResolver.resolve(recentStances: recentStances) ?? .pragmatic
                applyRegularArchetypeShapeTuning(
                    archetype: arch,
                    shape: shape,
                    resilience: resilience,
                    player: &player,
                    career: &career,
                    result: &result
                )
            }

            // P4-2: Regular career safety nets + ramps (so "normal" lives have visible agency and don't grind into dead-ends before mid-life).
            if career.specializedTrack == nil, let arch = career.regularArchetype {
                let shape = LifeShapeResolver.resolve(recentStances: recentStances) ?? .pragmatic
                let steadyTrait = player.traits.contains(.disciplined) || player.traits.contains(.resilient)
                let resBonus = (steadyTrait && (arch == .skilledTrades || arch == .publicService || arch == .careLabor)) ? 2 : 0

                switch arch {
                case .corporateClimber:
                    // High-sec but political: safety net against manager friction death spiral
                    if career.managerFriction >= 70 && career.jobSecurity < 45 {
                        career.jobSecurity = (career.jobSecurity + 6 + resBonus).clamped(to: 0...100)
                        if player.age % 4 == 0 {
                            result.notes.append(DomainNote(title: "Internal Safety", text: "The ladder has politics, but your track record bought one more rung.", tags: [.career]))
                        }
                    }
                    if shape == .drivenCurrent { career.performance = (career.performance + 1).clamped(to: 0...100) }
                case .gigFreelancer:
                    // Variance + fast recovery ramp: when low, a good pivot year can spike income temporarily
                    if career.jobSecurity < 35 && career.performance > 55 {
                        career.annualIncome = Int(Double(career.annualIncome) * 1.08)
                        career.jobSecurity = (career.jobSecurity + 4 + resBonus).clamped(to: 0...100)
                        if Int.random(in: 0...100) < 18 {
                            result.notes.append(DomainNote(title: "Gig Pivot Paid", text: "One client or contract turned the variance into a real step up this year.", tags: [.career, .finance]))
                        }
                    }
                    if shape == .looseEdges { career.burnout = (career.burnout + 1).clamped(to: 0...100) }
                case .skilledTrades:
                    // Durable: safety floor on burnout + physical aging slower ramp
                    career.burnout = max(5, career.burnout - (1 + resBonus))
                    if player.age > 50 && career.performance < 50 {
                        career.performance = (career.performance + 2).clamped(to: 0...100)
                    }
                    if shape == .drivenCurrent && career.performance > 70 { career.jobSecurity = (career.jobSecurity + 2).clamped(to: 0...100) }
                case .publicService:
                    career.jobSecurity = (career.jobSecurity + 1 + resBonus).clamped(to: 0...100)
                    if career.burnout > 60 {
                        career.burnout = (career.burnout - 2).clamped(to: 0...100)
                    }
                case .techEngineer:
                    if career.burnout > 70 && career.performance > 50 {
                        // Tech safety: skill can still save you even if burned
                        career.performance = (career.performance + 2).clamped(to: 0...100)
                    }
                case .salesNetworker:
                    if career.performance < 40 && career.jobSecurity < 40 {
                        career.jobSecurity = (career.jobSecurity + 3).clamped(to: 0...100)
                    }
                    if shape == .drivenCurrent, Int.random(in: 0...100) < 22 {
                        career.annualIncome = Int(Double(career.annualIncome) * 1.1)
                        result.notes.append(DomainNote(title: "Commission Spike", text: "A quarter of hustle turned into a number that actually showed up.", tags: [.career, .finance]))
                    }
                case .creativeProfessional:
                    if shape == .drivenCurrent { career.performance = min(100, career.performance + 2) }
                    if shape == .looseEdges { career.jobSecurity = max(0, career.jobSecurity - 2) }
                case .careLabor:
                    if resilience == .grounded && career.burnout > 60 {
                        career.burnout = max(0, career.burnout - 2)
                        if player.age % 4 == 0 {
                            result.notes.append(DomainNote(title: "Fighting Back", text: "You set one boundary that held. The year still hurt, but it bent.", tags: [.career, .health]))
                        }
                    }
                }
            }

            // D3 side hustle overlap note (from D2 finance collectors)
            if career.regularArchetype == .gigFreelancer && career.burnout >= 45 {
                result.notes.append(DomainNote(title: "Side Streams", text: "The gig life keeps multiple plates spinning. Some months sing, others scrape.", tags: [.career, .finance]))
            }
        }

        // D3: light dossier + era-tinged flavor for regular (non-special) paths (side immersion, no core cost)
        if career.specializedTrack == nil, let d = childhoodDossier {
            if d.aptitudes.entrepreneurial >= 58 && (career.regularArchetype == .gigFreelancer || career.regularArchetype == .salesNetworker) {
                if player.age % 3 == 1 {
                    result.notes.append(DomainNote(title: "Wiring from 14", text: "That early side-hustle spark still colors how you spot the next angle.", tags: [.career]))
                }
            }
            if d.aptitudes.social >= 62 && career.regularArchetype == .publicService {
                result.notes.append(DomainNote(title: "Presence in the System", text: "People remember your face from the early days. It opens quiet doors in the bureaucracy.", tags: [.career, .social]))
            }
        }

        // P3: narrative voice for regular archetypes (uniform treatment with specials) — 6 flavors, D4/stance ties
        if career.specializedTrack == nil, let arch = career.regularArchetype {
            if Int.random(in: 0...100) < 15 {
                let voice: String
                switch arch {
                case .corporateClimber:
                    voice = "The ladder is real. So is the view from the rung you just left behind."
                case .gigFreelancer:
                    voice = "Freedom is a calendar full of other people's deadlines. You still choose it every invoice."
                case .skilledTrades:
                    voice = "The work is honest. The respect is quiet. The body keeps the receipt."
                case .publicService:
                    voice = "The system is broken in the same ways it was last year. You are still inside it, still trying."
                case .techEngineer:
                    voice = "The code compiles. The version of you that wrote it at 2 a.m. is harder to find these days."
                case .salesNetworker:
                    voice = "Every relationship is a bet. Some of them are still paying out. Some of them are just good stories."
                case .creativeProfessional:
                    voice = "The portfolio grows in the quiet. The rent still comes due whether the muse shows up or not."
                case .careLabor:
                    voice = "You carried other people's weight again. The meaning is real. So is the exhaustion."
                }
                result.notes.append(DomainNote(title: "Regular Life Voice", text: voice, tags: [.career]))
            }
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

    func applyAction(_ choiceID: ActionChoiceID, state: inout GameState) -> DomainYearResult {
        var player = state.player
        var career = state.career
        var fame = state.fame
        let result = applyActionImpl(choiceID, player: &player, career: &career, fame: &fame, state: &state)
        state.player = player
        state.career = career
        state.fame = fame
        return result
    }

    func applyAction(_ choiceID: ActionChoiceID, player: inout Player, career: inout CareerState, fame: inout FameProfile) -> DomainYearResult {
        var state = GameState()
        state.player = player
        state.career = career
        state.fame = fame
        let result = applyAction(choiceID, state: &state)
        player = state.player
        career = state.career
        fame = state.fame
        return result
    }

    private func applyActionImpl(_ choiceID: ActionChoiceID, player: inout Player, career: inout CareerState, fame: inout FameProfile, state: inout GameState) -> DomainYearResult {
        var result = DomainYearResult()

        switch choiceID {
        case .applyForResidency:
            career.specializedTrack = .medical
            career.professionalRank = "Resident"
            career.status = .fullTime
            career.profile = .medicalProfessional
            career.annualIncome = 55000
            result.notes.append(DomainNote(title: "Residency Match", text: "You matched with a hospital and began your residency. Prepare for years of intense labor.", tags: [.career]))
            
        case .passBarExam:
            career.specializedTrack = .law
            career.professionalRank = "Law Clerk"
            career.status = .fullTime
            career.profile = .legalProfessional
            career.annualIncome = 65000
            result.notes.append(DomainNote(title: "The Bar", text: "You took the Bar exam. If your smarts are high enough, you will be sworn in next year.", tags: [.career]))

        case .becomeCTO:
            if career.specializedTrack == .tech && career.professionalRank == "Senior Developer" {
                career.professionalRank = "CTO"
                career.annualIncome = 280000
                result.notes.append(DomainNote(title: "New Role", text: "You accepted the CTO position.", tags: [.career]))
            }
            
        case .workHard, .extraEffort, .putYourHeadDown:
            career.performance += 8
            career.burnout += max(4, 10 - career.scheduleControl / 20)
            career.schedulePressure += 6
            career.relationshipSpillover += 4
            career.managerFriction += 1
            career.ambitionYears += 1
            result.healthEffects = HealthEffects(physical: nil, mental: -3, exercise: nil, nutrition: nil, stressManagement: -2, addCondition: nil, removeCondition: nil, hasPrimaryCare: nil)
            result.relationshipEffects = RelationshipEffects(meetNewFriend: nil, friendChange: -1, startDating: nil, partnerChange: -1, setPartnerStage: nil, setCohabiting: nil, commitmentAlignmentChange: -2, loseFriend: nil, breakup: nil)
            var grindText: String = {
                switch choiceID {
                case .putYourHeadDown: return "You put your head down and the work moved. Performance answered — everything else paid the tax."
                case .extraEffort: return "You pushed harder than the job strictly required. Performance moved, but so did the exhaustion tax."
                default: return "You leaned into work hard enough to move performance, but the pace bled into recovery and the people around you."
                }
            }()
            if choiceID == .putYourHeadDown {
                if LifeShapeResolver.resolveOrPragmatic(from: state) == .drivenCurrent {
                    grindText = "The driven current made this feel almost automatic. You put your head down and the work moved."
                }
                if let streak = StaticInstantActionFlavor.stanceStreakLine(state) {
                    grindText += " \(streak)"
                }
                StaticInstantActionFlavor.publishPulse(&state, domain: "career", strength: 16)
            }
            result.notes.append(DomainNote(title: "Career Focus", text: grindText, tags: [.career, .health, .relationships]))
        case .protectWorkLifeLine:
            career.performance += 1
            career.burnout = max(0, career.burnout - 8)
            career.schedulePressure = max(0, career.schedulePressure - 6)
            career.relationshipSpillover = max(0, career.relationshipSpillover - 5)
            career.scheduleControl += 5
            career.protectiveYears += 1
            result.healthEffects = HealthEffects(physical: 2, mental: 6, exercise: nil, nutrition: nil, stressManagement: 5, addCondition: nil, removeCondition: nil, hasPrimaryCare: nil)
            let workLifeText = StaticInstantActionFlavor.isGrounded(state)
                ? "You closed the laptop on purpose. The relief wasn't theoretical — you felt it in your chest."
                : "You closed the laptop on purpose. The job didn't get to eat the whole person tonight."
            StaticInstantActionFlavor.publishPulse(&state, domain: "career", strength: 18)
            result.notes.append(DomainNote(title: "Work-Life Line", text: workLifeText, tags: [.career, .health, .relationships]))
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
        case .seekMentor:
            career.performance += 3
            career.jobSecurity += 3
            career.schedulePressure += 1
            result.relationshipEffects = RelationshipEffects(meetNewFriend: true, friendChange: 1, startDating: nil, partnerChange: nil, setPartnerStage: nil, setCohabiting: nil, commitmentAlignmentChange: nil, loseFriend: nil, breakup: nil)
            result.notes.append(DomainNote(title: "Mentorship", text: "Someone ahead of you shared the map. It cost humility and bought clarity.", tags: [.career, .relationships]))
        case .documentWins:
            career.performance += 4
            career.jobSecurity += 2
            result.notes.append(DomainNote(title: "Documented Win", text: "You wrote the work down where people actually look. Credit has a better chance of sticking.", tags: [.career]))
        case .improveSkill:
            career.performance += 3
            career.burnout += 2
            career.schedulePressure += 2
            player.smarts = (player.smarts + 2).clamped(to: 0...100)
            result.notes.append(DomainNote(title: "Skill Stack", text: "You invested deliberate hours in getting sharper. The job feels slightly less like guesswork.", tags: [.career, .education]))
        case .managePolitics:
            career.jobSecurity += 4
            career.managerFriction += 2
            career.performance += 2
            result.notes.append(DomainNote(title: "Office Politics", text: "You played the room instead of only the deliverables. Security improved; authenticity got thinner.", tags: [.career, .relationships]))
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
            // D1 veteran bonus lives in the full state path (military top-level); small always-on flavor here
        // D3: Regular career archetype actions for parity (non-special deep runs) - set persistent archetype + richer curves
        case .corporateStayLate:
            career.regularArchetype = .corporateClimber
            career.performance += 5
            career.burnout += 6
            career.managerFriction += 2
            result.notes.append(DomainNote(title: "Office Lights On", text: "You were still there when the floor went quiet. Someone noticed.", tags: [.career, .autonomousReaction]))
        case .corporatePolitick:
            career.regularArchetype = .corporateClimber
            career.jobSecurity += 5
            career.managerFriction += 5
            career.performance += 2
            result.notes.append(DomainNote(title: "Room Read", text: "You spent the afternoon learning who actually decides things around here.", tags: [.career, .autonomousReaction]))
        case .corporateDocumentWin:
            career.regularArchetype = .corporateClimber
            career.performance += 6
            career.jobSecurity += 3
            applyRegularArchetypeFame(archetype: .corporateClimber, career: career, fame: &fame, performanceBump: 4)
            result.notes.append(DomainNote(title: "Win On Record", text: "The work is real now — on paper, in a deck, where reviews live.", tags: [.career, .autonomousReaction]))
        case .tradesExtraFocus:
            career.regularArchetype = .skilledTrades
            career.performance += 6
            career.burnout += 3
            result.healthEffects = HealthEffects(physical: -2, mental: nil, exercise: 2, nutrition: nil, stressManagement: -1)
            result.notes.append(DomainNote(title: "Hands On The Work", text: "The craft moved forward. The body felt it immediately.", tags: [.career, .health, .autonomousReaction]))
        case .tradesMaintainTools:
            career.regularArchetype = .skilledTrades
            career.jobSecurity += 4
            career.performance += 2
            result.notes.append(DomainNote(title: "Tools Ready", text: "Reliability is its own reputation. Yours held today.", tags: [.career, .autonomousReaction]))
        case .tradesSafetyPush:
            career.regularArchetype = .skilledTrades
            career.burnout = max(0, career.burnout - 4)
            career.jobSecurity += 2
            result.notes.append(DomainNote(title: "Safety First", text: "You slowed down on purpose. The job will still be there tomorrow.", tags: [.career, .health, .autonomousReaction]))
        case .salesClientOutreach:
            career.regularArchetype = .salesNetworker
            career.performance += 4
            career.burnout += 2
            career.relationshipSpillover += 2
            result.notes.append(DomainNote(title: "Pipeline Touched", text: "You reached out again. The numbers might move next week — or they might not.", tags: [.career, .relationships, .autonomousReaction]))
            applyRegularArchetypeFame(archetype: .salesNetworker, career: career, fame: &fame, performanceBump: 3)
        case .salesPipelineGrind:
            career.regularArchetype = .salesNetworker
            let swing = Int.random(in: -6...10)
            career.performance = (career.performance + swing).clamped(to: 0...100)
            career.burnout += 4
            if swing > 4 {
                result.financeEffects = FinanceEffects(cashDelta: 900 + swing * 120)
            }
            result.notes.append(DomainNote(title: "Pipeline Grind", text: swing > 0 ? "A lead warmed up. The grind is paying something." : "Another week of numbers that didn't move.", tags: [.career, .finance, .autonomousReaction]))
            applyRegularArchetypeFame(archetype: .salesNetworker, career: career, fame: &fame, performanceBump: max(0, swing))
        case .salesRecoveryCall:
            career.regularArchetype = .salesNetworker
            career.performance += 3
            career.jobSecurity += 2
            result.notes.append(DomainNote(title: "Deal Salvaged", text: "You made the awkward call. It didn't close everything, but it kept the door cracked.", tags: [.career, .autonomousReaction]))
        case .gigAcceptSurge:
            career.regularArchetype = .gigFreelancer
            career.burnout += 5
            career.performance += 4
            result.financeEffects = FinanceEffects(cashDelta: Int.random(in: 600...2200))
            result.notes.append(DomainNote(title: "Surge Accepted", text: "Demand spiked and you answered. Cash landed fast; so did the fatigue.", tags: [.career, .finance, .autonomousReaction]))
        case .gigMaintainRating:
            career.regularArchetype = .gigFreelancer
            career.jobSecurity += 5
            career.schedulePressure += 3
            result.notes.append(DomainNote(title: "Rating Protected", text: "You did the extra little things clients remember when they tap the stars.", tags: [.career, .autonomousReaction]))
        case .gigRestDay:
            career.regularArchetype = .gigFreelancer
            career.burnout = max(0, career.burnout - 6)
            career.jobSecurity = max(0, career.jobSecurity - 2)
            result.healthEffects = HealthEffects(physical: 2, mental: 4, exercise: nil, nutrition: nil, stressManagement: 4)
            result.notes.append(DomainNote(title: "Rest Day", text: "You let the surge pass without you. The algorithm moved on; your nervous system didn't.", tags: [.career, .health, .autonomousReaction]))
        case .corporateClimb:
            career.regularArchetype = .corporateClimber
            career.performance += 6
            career.jobSecurity += 7
            career.burnout += 5
            career.managerFriction += 4
            result.notes.append(DomainNote(title: "Corporate Path", text: "You committed to the ladder — steady security, political drag, slow climbs.", tags: [.career, .autonomousReaction]))
        case .freelanceHustle:
            career.regularArchetype = .gigFreelancer
            career.performance += 4
            career.annualIncome = Int(Double(career.annualIncome) * 1.12)
            career.burnout += 6
            career.scheduleControl -= 5
            result.notes.append(DomainNote(title: "Gig Path", text: "You committed to the hustle — flexible income, thin safety net, your own calendar.", tags: [.career, .finance, .autonomousReaction]))
        case .tradesMastery:
            career.regularArchetype = .skilledTrades
            career.performance += 7
            career.jobSecurity += 9
            career.burnout -= 3
            result.notes.append(DomainNote(title: "Trades Path", text: "You committed to tangible mastery — steady demand, honest work, the body keeps score.", tags: [.career, .autonomousReaction]))
        case .pivotToGig:
            career.regularArchetype = .gigFreelancer
            career.status = .partTime
            career.performance += 3
            career.annualIncome = Int(Double(career.annualIncome) * 0.82)
            result.notes.append(DomainNote(title: "Gig Pivot", text: "You left the single employer for multiple streams. Flexibility up, predictability down.", tags: [.career, .finance]))
        case .publicServiceGrind:
            career.regularArchetype = .publicService
            career.performance += 4
            career.jobSecurity += 10
            career.burnout += 2
            career.annualIncome = Int(Double(career.annualIncome) * 0.95)
            result.notes.append(DomainNote(title: "Public Service Grind", text: "Mission-driven stability. Pension path and respect, slower private upside. (Public: security king, mission flavor.)", tags: [.career]))
        case .techDeepWork:
            career.regularArchetype = .techEngineer
            career.performance += 8
            career.jobSecurity += 4
            career.burnout += 3
            result.notes.append(DomainNote(title: "Tech Deep Work", text: "Mastery through focused craft. IP edge and leverage, but isolation and intensity. (Tech: high perf ceiling, skill compounds fast.)", tags: [.career, .education]))
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
        case .militaryService:
            return .militaryService
        case .medicalProfessional:
            return .medicalProfessional
        case .legalProfessional:
            return .legalProfessional
        case .techSpecialist:
            return .techSpecialist
        case .financialExpert:
            return .financialExpert
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
        case .military: return "Military Service"
        case .unemployed: return "Looking for work"
        }
    }

    /// D4 stance × archetype yearly texture — driven/loose feel different per regular path.
    private func applyRegularArchetypeShapeTuning(
        archetype: CareerArchetype,
        shape: LifeShape,
        resilience: LifeResilience,
        player: inout Player,
        career: inout CareerState,
        result: inout DomainYearResult
    ) {
        switch (archetype, shape) {
        case (.corporateClimber, .drivenCurrent):
            career.performance = (career.performance + 1).clamped(to: 0...100)
            career.burnout = (career.burnout + 2).clamped(to: 0...100)
            career.managerFriction = (career.managerFriction + 1).clamped(to: 0...100)
        case (.corporateClimber, .looseEdges):
            career.jobSecurity = max(0, career.jobSecurity - 1)
        case (.skilledTrades, .drivenCurrent):
            career.performance = (career.performance + 2).clamped(to: 0...100)
            career.burnout = (career.burnout + 2).clamped(to: 0...100)
            result.healthEffects = mergeHealthEffects(
                result.healthEffects,
                with: HealthEffects(physical: -2, mental: nil, exercise: nil, nutrition: nil, stressManagement: nil)
            )
        case (.skilledTrades, .carefulShape):
            career.burnout = max(0, career.burnout - 1)
        case (.salesNetworker, .drivenCurrent):
            if Int.random(in: 0...100) < 28 {
                career.annualIncome = Int(Double(career.annualIncome) * 1.07)
            } else if Int.random(in: 0...100) < 18 {
                career.burnout = (career.burnout + 3).clamped(to: 0...100)
            }
            career.relationshipSpillover = (career.relationshipSpillover + 1).clamped(to: 0...100)
        case (.salesNetworker, .looseEdges):
            career.jobSecurity = max(0, career.jobSecurity - 2)
        case (.gigFreelancer, .drivenCurrent):
            career.performance = (career.performance + 1).clamped(to: 0...100)
            career.burnout = (career.burnout + 2).clamped(to: 0...100)
        case (.gigFreelancer, .looseEdges):
            career.jobSecurity = max(0, career.jobSecurity - 2)
            career.burnout = max(0, career.burnout - 1)
        case (.techEngineer, .drivenCurrent):
            career.performance = (career.performance + 2).clamped(to: 0...100)
            career.burnout = (career.burnout + 3).clamped(to: 0...100)
        case (.techEngineer, .carefulShape):
            career.burnout = max(0, career.burnout - 1)
        case (.careLabor, .drivenCurrent):
            career.performance = (career.performance + 1).clamped(to: 0...100)
            career.burnout = (career.burnout + 2).clamped(to: 0...100)
            if resilience == .grounded {
                career.burnout = (career.burnout + 1).clamped(to: 0...100)
            }
        case (.creativeProfessional, .drivenCurrent):
            career.performance = (career.performance + 2).clamped(to: 0...100)
            career.burnout = (career.burnout + 2).clamped(to: 0...100)
        case (.publicService, .carefulShape):
            career.jobSecurity = (career.jobSecurity + 1).clamped(to: 0...100)
        default:
            break
        }
        _ = player
    }

    /// Instant + yearly fame leak for visible regular-career performance.
    private func applyRegularArchetypeFame(
        archetype: CareerArchetype,
        career: CareerState,
        fame: inout FameProfile,
        performanceBump: Int = 0
    ) {
        let tier = archetype.fameLeakTier
        guard tier > 0 else { return }
        let effectivePerf = min(100, career.performance + performanceBump)
        guard effectivePerf >= 52 else { return }

        let leak = max(1, (effectivePerf - 48) / max(4, 14 - tier * 2))
        fame.culturalFame = min(100, fame.culturalFame + leak)

        let tag: String?
        switch archetype {
        case .salesNetworker where effectivePerf >= 68:
            tag = "Closer"
        case .corporateClimber where effectivePerf >= 72 && career.jobSecurity >= 58:
            tag = "Rising Executive"
        case .creativeProfessional where effectivePerf >= 65:
            tag = "Working Artist"
        case .techEngineer where effectivePerf >= 70:
            tag = "Tech Specialist"
        case .gigFreelancer where effectivePerf >= 62:
            tag = "Relentless Hustler"
        case .careLabor where effectivePerf >= 60:
            tag = "Dedicated Caregiver"
        case .skilledTrades where effectivePerf >= 75:
            tag = "Master Craftsman"
        case .publicService where career.yearsWorked >= 12 && career.jobSecurity >= 65:
            tag = "Public Servant"
        default:
            tag = nil
        }
        if let tag, !fame.knownFor.contains(tag) {
            fame.knownFor.append(tag)
        }
        fame.clamp()
    }
}
