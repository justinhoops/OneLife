import Foundation

struct RelationshipSystem {
    private let friendNames = ["Maya", "Jordan", "Riley", "Sam", "Taylor", "Casey", "Quinn", "Avery", "Parker", "Skyler"]
    private let partnerNames = ["Alex", "Jamie", "Cameron", "Morgan", "Reese", "Emerson", "Harper", "Micah", "Rowan", "Sawyer"]

    func advanceYear(input: RelationshipDomainSnapshot, relationships: inout RelationshipState) -> DomainYearResult {
        advanceYear(
            player: input.player,
            relationships: &relationships,
            family: input.family,
            health: input.health,
            housing: input.housing,
            financialStress: input.financialStress
        )
    }

    func advanceYear(
        player: Player,
        relationships: inout RelationshipState,
        family: FamilyState,
        health: HealthState,
        housing: HousingState,
        financialStress: Int
    ) -> DomainYearResult {
        var result = DomainYearResult()
        relationships.friends = ageRelationships(
            relationships.friends,
            drift: ((player.happiness - 50) / 10) + ((health.mentalWellness - 50) / 12) + (housing.hasRoommate ? -1 : 0),
            breakThreshold: 12,
            strainedThreshold: 35,
            relationshipName: "friendship",
            result: &result
        )
        if let existingPartner = relationships.romanticPartner {
            var partner = existingPartner
            let childPressure = family.childCount > 0 ? max(1, family.childCount) : 0
            let cohabitationPressure = partner.isCohabiting ? max(0, (financialStress - 38) / 10) : 0
            let adultStressPenalty = player.age >= 18 ? max(0, (financialStress - 45) / 10) : 0
            let commitmentBonus: Int
            switch partner.stage {
            case .dating: commitmentBonus = 0
            case .committed: commitmentBonus = 1
            case .engaged: commitmentBonus = 2
            case .married: commitmentBonus = 3
            }
            let drift =
                ((player.happiness - 50) / 12) +
                ((health.mentalWellness - 50) / 10) +
                commitmentBonus +
                (partner.isCohabiting ? 1 : 0) -
                max(0, health.activeConditions.count - 1) -
                (housing.livingArrangement == .couchSurfing ? 2 : 0) -
                max(0, (financialStress - 40) / 12) -
                cohabitationPressure -
                adultStressPenalty -
                childPressure -
                (family.postpartumYearsRemaining > 0 ? 2 : 0)
            relationships.romanticPartner = agePartner(partner, drift: drift, result: &result)
        }

        if player.age >= 18,
           let partner = relationships.romanticPartner,
           partner.isCohabiting,
           financialStress >= 48,
           partner.status == .strained {
            result.notes.append(
                DomainNote(
                    title: "Relationship Strain",
                    text: "Shared bills and shared space turned background stress into visible tension between you.",
                    tags: [.relationships, .finance, .housing]
                )
            )
        }
        ageSocialStanding(
            player: player,
            relationships: &relationships,
            family: family,
            health: health,
            housing: housing,
            financialStress: financialStress,
            result: &result
        )
        relationships.clampSocialSignals()
        return result
    }

    func apply(effect: RelationshipEffects, to relationships: inout RelationshipState) {
        if effect.meetNewFriend == true {
            let name = nextName(from: friendNames, avoiding: relationships.friends.map(\.name))
            relationships.friends.append(Relationship(name: name, type: .friend, status: .active, bond: 58, personality: NPCPersonality.allCases.randomElement() ?? .loyal))
        }

        if let friendChange = effect.friendChange {
            adjustStrongestBond(in: &relationships.friends, delta: friendChange)
        }

        if effect.startDating == true, relationships.romanticPartner == nil {
            let name = nextName(from: partnerNames, avoiding: relationships.friends.map(\.name))
            relationships.romanticPartner = Relationship(name: name, type: .romantic, status: .active, bond: 55, yearsKnown: 0, stage: .dating, isCohabiting: false, commitmentAlignment: 50, personality: NPCPersonality.allCases.randomElement() ?? .loyal)
        }

        if let partnerChange = effect.partnerChange {
            adjustPartnerBond(in: &relationships, delta: partnerChange)
        }

        if let commitmentAlignmentChange = effect.commitmentAlignmentChange,
           var partner = relationships.romanticPartner {
            partner.commitmentAlignment = (partner.commitmentAlignment + commitmentAlignmentChange).clamped(to: 0...100)
            relationships.romanticPartner = partner
        }

        if let stage = effect.setPartnerStage,
           var partner = relationships.romanticPartner {
            partner.stage = stage
            relationships.romanticPartner = partner
        }

        if let setCohabiting = effect.setCohabiting,
           var partner = relationships.romanticPartner {
            partner.isCohabiting = setCohabiting
            relationships.romanticPartner = partner
        }

        if effect.loseFriend == true, !relationships.friends.isEmpty {
            relationships.friends.removeFirst()
        }

        if effect.breakup == true {
            if let formerPartner = relationships.romanticPartner {
                addOrMergeTension(
                    into: &relationships,
                    headline: "The breakup did not clear",
                    impactLine: "The relationship ended, but the emotional residue is still shaping the year.",
                    severity: 68,
                    source: .breakup,
                    target: .partner,
                    createdAge: max(18, formerPartner.yearsKnown),
                    targetName: formerPartner.name,
                    impactedDomains: [.relationships, .health]
                )
            }
            relationships.romanticPartner = nil
        }

        relationships.publicReputation = (relationships.publicReputation + (effect.publicReputationChange ?? 0)).clamped(to: 0...100)
        relationships.privateReputation = (relationships.privateReputation + (effect.privateReputationChange ?? 0)).clamped(to: 0...100)
        relationships.activeRumorHeat = (relationships.activeRumorHeat + (effect.rumorHeatChange ?? 0)).clamped(to: 0...100)
        if let addKnownTag = effect.addKnownTag, !addKnownTag.isEmpty {
            relationships.knownForTags.append(addKnownTag)
        }

        relationships.friends.indices.forEach { relationships.friends[$0].bond = relationships.friends[$0].bond.clamped(to: 0...100) }
        if var partner = relationships.romanticPartner {
            partner.bond = partner.bond.clamped(to: 0...100)
            partner.commitmentAlignment = partner.commitmentAlignment.clamped(to: 0...100)
            relationships.romanticPartner = partner
        }
        relationships.clampSocialSignals()
    }

    func applyAction(_ choiceID: ActionChoiceID, player: inout Player, relationships: inout RelationshipState, family: inout FamilyState) -> DomainYearResult {
        var result = DomainYearResult()

        switch choiceID {
        case .reachOut:
            if relationships.friends.isEmpty {
                relationships.friends.append(Relationship(name: "New Friend", type: .friend, status: .active, bond: 55, personality: NPCPersonality.allCases.randomElement() ?? .loyal))
            } else if let index = relationships.friends.indices.max(by: { relationships.friends[$0].bond < relationships.friends[$1].bond }) {
                relationships.friends[index].bond = (relationships.friends[index].bond + 6).clamped(to: 0...100)
            }
            relationships.publicReputation += 3
            relationships.privateReputation += 4
            relationships.activeRumorHeat = max(0, relationships.activeRumorHeat - 3)
            relationships.recentSocialLift = "People started taking your side."
            resolveTension(in: &relationships, matching: [.socialCircle, .future], relief: 16)
            result.notes.append(
                DomainNote(
                    title: "Relationships Focus",
                    text: "You made time to reach out and keep your connections alive.",
                    tags: [.relationships]
                )
            )
        case .strengthenBond:
            if var partner = relationships.romanticPartner {
                partner.bond = (partner.bond + 7).clamped(to: 0...100)
                partner.commitmentAlignment = (partner.commitmentAlignment + 4).clamped(to: 0...100)
                partner.status = .active
                relationships.romanticPartner = partner
                relationships.privateReputation += 4
                relationships.recentSocialLift = "The relationship felt steadier."
                resolveTension(in: &relationships, matching: [.partner, .future, .household], relief: 18)
                result.notes.append(
                    DomainNote(
                        title: "Relationship Focus",
                        text: "You invested in closeness instead of coasting. The relationship felt warmer and more secure.",
                        tags: [.relationships]
                    )
                )
            }
        case .discussFuture:
            guard var partner = relationships.romanticPartner else { return result }
            partner.commitmentAlignment = (partner.commitmentAlignment + 10).clamped(to: 0...100)
            partner.bond = (partner.bond + 4).clamped(to: 0...100)
            let previousStage = partner.stage
            if partner.stage == .dating, partner.bond >= 68, partner.yearsKnown >= 1 {
                partner.stage = .committed
            } else if partner.stage == .committed, player.age >= 21, partner.bond >= 82, partner.yearsKnown >= 3, partner.commitmentAlignment >= 68 {
                partner.stage = .engaged
            } else if partner.stage == .engaged, player.age >= 22, partner.bond >= 88, partner.yearsKnown >= 4, partner.commitmentAlignment >= 74 {
                partner.stage = .married
            }
            relationships.romanticPartner = partner
            relationships.privateReputation += 2
            relationships.futureAlignment.activeConflictHeadline = nil
            resolveTension(in: &relationships, matching: [.future], relief: 14)
            let noteText: String
            if previousStage != partner.stage {
                switch partner.stage {
                case .committed:
                    noteText = "A real future together is starting to feel mutual now."
                case .engaged:
                    noteText = "The relationship crossed into engagement after an honest conversation about the future."
                case .married:
                    noteText = "The relationship became a marriage this year after a long build of trust and alignment."
                case .dating:
                    noteText = "You had the conversation, but it was more clarifying than transformative."
                }
            } else {
                noteText = "You put the future on the table. Even without a milestone, the relationship got clearer."
            }
            result.notes.append(DomainNote(title: "Relationship Focus", text: noteText, tags: [.relationships, .lifeEvent]))
        case .moveInTogether:
            guard var partner = relationships.romanticPartner else { return result }
            if player.age >= 20, partner.bond >= 74, partner.commitmentAlignment >= 62 {
                partner.isCohabiting = true
                partner.bond = (partner.bond + 3).clamped(to: 0...100)
                relationships.romanticPartner = partner
                relationships.futureAlignment.cohabitationReadiness = min(100, relationships.futureAlignment.cohabitationReadiness + 10)
                relationships.futureAlignment.activeConflictHeadline = nil
                resolveTension(in: &relationships, matching: [.household, .future], relief: 20)
                result.housingEffects = HousingEffects(costBandDelta: 6, stabilityDelta: 4, setArrangement: .roommates, hasRoommate: false)
                result.notes.append(DomainNote(title: "Relationship Focus", text: "You moved in together, trading privacy and friction for a more serious shared life.", tags: [.relationships, .housing]))
            } else {
                addOrMergeTension(
                    into: &relationships,
                    headline: "The move-in question turned tense",
                    impactLine: "You pushed the relationship toward shared life before the foundation was ready.",
                    severity: 58,
                    source: .milestoneConflict,
                    target: .future,
                    createdAge: player.age,
                    targetName: partner.name,
                    impactedDomains: [.relationships, .housing]
                )
                result.notes.append(DomainNote(title: "Relationship Focus", text: "You pushed for cohabitation before the relationship was ready, and it created some tension.", tags: [.relationships]))
                result.relationshipEffects = RelationshipEffects(partnerChange: -3, commitmentAlignmentChange: -4, privateReputationChange: -2)
            }
        case .tryForBaby:
            family.pregnancyIntent = .trying
            if relationships.romanticPartner != nil {
                addOrMergeTension(
                    into: &relationships,
                    headline: "The family question got heavier",
                    impactLine: "Trying for a baby raised the emotional stakes around the relationship and the future.",
                    severity: 34,
                    source: .familyPlanning,
                    target: .future,
                    createdAge: player.age,
                    targetName: relationships.partnerName,
                    impactedDomains: [.relationships, .lifeEvent, .finance]
                )
            }
            result.notes.append(DomainNote(title: "Family Planning", text: "You and your partner stopped leaving pregnancy to chance and started trying on purpose.", tags: [.relationships, .lifeEvent]))
        case .avoidPregnancy:
            family.pregnancyIntent = .avoid
            relationships.futureAlignment.familyReadiness = max(0, relationships.futureAlignment.familyReadiness - 3)
            result.notes.append(DomainNote(title: "Family Planning", text: "You made avoiding pregnancy a clear priority this year.", tags: [.relationships]))
        case .letChanceDecide:
            family.pregnancyIntent = .chance
            addOrMergeTension(
                into: &relationships,
                headline: "The future stayed unresolved",
                impactLine: "Avoiding a decision let uncertainty keep its leverage over the relationship.",
                severity: 38,
                source: .familyPlanning,
                target: .future,
                createdAge: player.age,
                targetName: relationships.partnerName,
                impactedDomains: [.relationships, .lifeEvent]
            )
            result.notes.append(DomainNote(title: "Family Planning", text: "You left family planning unresolved and let the year carry its own risk.", tags: [.relationships]))
        case .callInFavor:
            guard relationships.socialCapital >= 50 else {
                result.notes.append(DomainNote(title: "Favor Failed", text: "You tried to lean on your network, but you don't have enough capital to make it happen yet."))
                break
            }
            
            relationships.socialCapital -= 50
            // Benefit: Boost career performance or reduce heat
            result.careerEffects = CareerEffects(performance: 15)
            result.notes.append(DomainNote(title: "Favor Called", text: "A few phone calls in the right places cleared the way. Doors that were stuck are now open.", tags: [.relationships, .career]))
            
            // Randomly reduce heat if crime is active
            result.notes.append(DomainNote(title: "Social Capital", text: "You spent a significant portion of your influence to secure this advantage."))
            
        case .findYourCrowd:
            if relationships.friends.count < 2 {
                let existing = relationships.friends.map(\.name)
                let name = nextName(from: friendNames, avoiding: existing)
                relationships.friends.append(Relationship(name: name, type: .friend, status: .active, bond: 57, personality: NPCPersonality.allCases.randomElement() ?? .loyal))
            } else if let index = relationships.friends.indices.max(by: { relationships.friends[$0].bond < relationships.friends[$1].bond }) {

                relationships.friends[index].bond = (relationships.friends[index].bond + 5).clamped(to: 0...100)
            }
            relationships.publicReputation += 5
            relationships.privateReputation += 3
            relationships.activeRumorHeat = max(0, relationships.activeRumorHeat - 2)
            relationships.knownForTags.append("connected")
            relationships.recentSocialLift = "You looked easier to belong with."
            result.educationEffects = EducationEffects(engagement: 2)
            result.notes.append(
                DomainNote(
                    title: "Relationships Focus",
                    text: "You put effort into finding your crowd and feeling less socially adrift.",
                    tags: [.relationships, .education]
                )
            )
        case .dateCarefully:
            if relationships.romanticPartner == nil, player.age >= 15 {
                let name = nextName(from: partnerNames, avoiding: relationships.friends.map(\.name))
                relationships.romanticPartner = Relationship(name: name, type: .romantic, bond: 54, stage: .dating, isCohabiting: false, commitmentAlignment: 52)
            } else if var partner = relationships.romanticPartner {
                partner.bond = (partner.bond + 4).clamped(to: 0...100)
                partner.commitmentAlignment = (partner.commitmentAlignment + 3).clamped(to: 0...100)
                relationships.romanticPartner = partner
            }
            relationships.publicReputation += 2
            relationships.privateReputation += 3
            relationships.activeRumorHeat += 4
            relationships.knownForTags.append("romantic")
            result.educationEffects = EducationEffects(schoolBelonging: 2, peerPressure: 2)
            result.notes.append(
                DomainNote(
                    title: "Relationships Focus",
                    text: "You let romance in carefully, adding closeness without fully losing the rest of your footing.",
                    tags: [.relationships, .education]
                )
            )
        case .chaseStatus:
            if let index = relationships.friends.indices.max(by: { relationships.friends[$0].bond < relationships.friends[$1].bond }) {
                relationships.friends[index].bond = (relationships.friends[index].bond + 2).clamped(to: 0...100)
            }
            relationships.publicReputation += 6
            relationships.privateReputation = max(0, relationships.privateReputation - 2)
            relationships.activeRumorHeat += 12
            relationships.knownForTags.append("visible")
            relationships.recentSocialHit = "Rumor followed your visibility."
            result.educationEffects = EducationEffects(schoolBelonging: 3, reputationRisk: 7, peerPressure: 8)
            result.notes.append(
                DomainNote(
                    title: "Relationships Focus",
                    text: "You chased visibility this year. It raised your profile, but also the social volatility around you.",
                    tags: [.relationships, .education]
                )
            )
        case .stayInvisible:
            relationships.publicReputation = max(0, relationships.publicReputation - 3)
            relationships.privateReputation = max(0, relationships.privateReputation - 1)
            relationships.activeRumorHeat = max(0, relationships.activeRumorHeat - 6)
            addOrMergeTension(
                into: &relationships,
                headline: "Distance started becoming the pattern",
                impactLine: "Lower drama came with a quieter kind of relational drift.",
                severity: 32,
                source: .ignoredConnection,
                target: .socialCircle,
                createdAge: player.age,
                targetName: nil,
                impactedDomains: [.relationships]
            )
            result.coreEffects = CoreStatEffects(happiness: -1)
            result.educationEffects = EducationEffects(schoolBelonging: -4, reputationRisk: -4, peerPressure: -5)
            result.notes.append(
                DomainNote(
                    title: "Relationships Focus",
                    text: "You stayed socially invisible. The drama eased, but so did your sense of belonging.",
                    tags: [.relationships, .education]
                )
            )
        case .leanOnMentor:
            result.educationEffects = EducationEffects(teacherSupport: 4, applicationReadiness: 4, mentorSupport: 8, peerPressure: -4)
            result.notes.append(
                DomainNote(
                    title: "Relationships Focus",
                    text: "You leaned on an adult ally and got a little more cover, clarity, and direction.",
                    tags: [.relationships, .education]
                )
            )
        case .keepDistance:
            result.coreEffects = CoreStatEffects(happiness: -1)
            if var partner = relationships.romanticPartner {
                partner.bond = (partner.bond - 5).clamped(to: 0...100)
                partner.commitmentAlignment = (partner.commitmentAlignment - 4).clamped(to: 0...100)
                relationships.romanticPartner = partner
                addOrMergeTension(
                    into: &relationships,
                    headline: "The relationship cooled instead of healing",
                    impactLine: "Creating distance made the bond feel safer in the moment and shakier underneath.",
                    severity: 48,
                    source: .ignoredConnection,
                    target: .partner,
                    createdAge: player.age,
                    targetName: partner.name,
                    impactedDomains: [.relationships, .health]
                )
            } else if let index = relationships.friends.indices.max(by: { relationships.friends[$0].bond < relationships.friends[$1].bond }) {
                relationships.friends[index].bond = (relationships.friends[index].bond - 4).clamped(to: 0...100)
                addOrMergeTension(
                    into: &relationships,
                    headline: "A friendship started drifting on purpose",
                    impactLine: "Protecting yourself came at the cost of one more loose end.",
                    severity: 36,
                    source: .ignoredConnection,
                    target: .friend,
                    createdAge: player.age,
                    targetName: relationships.friends[index].name,
                    impactedDomains: [.relationships]
                )
            }
            result.notes.append(
                DomainNote(
                    title: "Relationships Focus",
                    text: "You kept your distance this year, and your closest friendship felt it.",
                    tags: [.relationships]
                )
            )
        case .repairTension:
            if var partner = relationships.romanticPartner, partner.status == .strained {
                partner.bond = (partner.bond + 9).clamped(to: 0...100)
                partner.commitmentAlignment = (partner.commitmentAlignment + 6).clamped(to: 0...100)
                partner.status = .active
                relationships.romanticPartner = partner
            } else if let index = relationships.friends.indices.first(where: { relationships.friends[$0].status == .strained }) {
                relationships.friends[index].bond = (relationships.friends[index].bond + 8).clamped(to: 0...100)
                relationships.friends[index].status = .active
            }
            relationships.privateReputation += 4
            relationships.activeRumorHeat = max(0, relationships.activeRumorHeat - 4)
            relationships.recentSocialLift = "You stopped letting it calcify."
            resolveTension(in: &relationships, matching: [.partner, .friend, .future, .household], relief: 24)
            result.notes.append(
                DomainNote(
                    title: "Relationships Focus",
                    text: "You put effort into repairing tension instead of letting it calcify.",
                    tags: [.relationships]
                )
            )
        default:
            return result
        }

        relationships.clampSocialSignals()
        return result
    }

    private func ageRelationships(
        _ relationships: [Relationship],
        drift: Int,
        breakThreshold: Int,
        strainedThreshold: Int,
        relationshipName: String,
        result: inout DomainYearResult
    ) -> [Relationship] {
        relationships.compactMap { original in
            var relationship = original
            relationship.yearsKnown += 1
            relationship.bond = (relationship.bond + drift).clamped(to: 0...100)

            if relationship.bond <= breakThreshold {
                result.notes.append(DomainNote(title: "Relationships", text: "Your \(relationshipName) with \(relationship.name) faded away."))
                return nil
            }

            relationship.status = relationship.bond < strainedThreshold ? .strained : .active
            return relationship
        }
    }

    private func agePartner(_ original: Relationship, drift: Int, result: inout DomainYearResult) -> Relationship? {
        var partner = original
        partner.yearsKnown += 1
        partner.bond = (partner.bond + drift).clamped(to: 0...100)
        partner.commitmentAlignment = (partner.commitmentAlignment + drift / 2).clamped(to: 0...100)

        if partner.bond <= 22 {
            result.notes.append(DomainNote(title: "Relationships", text: "Your relationship with \(partner.name) collapsed under accumulated strain."))
            return nil
        }

        partner.status = partner.bond < 45 ? .strained : .active
        return partner
    }

    private func adjustPartnerBond(in relationships: inout RelationshipState, delta: Int) {
        guard var partner = relationships.romanticPartner else { return }
        partner.bond = (partner.bond + delta).clamped(to: 0...100)
        partner.status = partner.bond < 45 ? .strained : .active
        relationships.romanticPartner = partner
    }

    private func adjustStrongestBond(in relationships: inout [Relationship], delta: Int) {
        guard let strongestIndex = relationships.indices.max(by: { relationships[$0].bond < relationships[$1].bond }) else { return }
        relationships[strongestIndex].bond = (relationships[strongestIndex].bond + delta).clamped(to: 0...100)
        relationships[strongestIndex].status = relationships[strongestIndex].bond < 35 ? .strained : .active
    }

    private func nextName(from pool: [String], avoiding existing: [String]) -> String {
        pool.first(where: { !existing.contains($0) }) ?? "New Connection"
    }

    private func ageSocialStanding(
        player: Player,
        relationships: inout RelationshipState,
        family: FamilyState,
        health: HealthState,
        housing: HousingState,
        financialStress: Int,
        result: inout DomainYearResult
    ) {
        // Generate Social Capital
        var capitalGained = 0
        let allRelationships = relationships.friends + relationships.romanticPartners
        for person in allRelationships {
            if person.bond >= 60 {
                // Stronger bonds with influential people yield more capital
                let contribution = (person.bond / 20) * (1 + (person.influence / 25))
                capitalGained += contribution
            }
        }
        
        if capitalGained > 0 {
            relationships.socialCapital += capitalGained
            // result.notes.append(DomainNote(title: "Social Capital", text: "Your network provided some new leverage this year.", tags: [.relationships]))
        }

        let strainedCount = (relationships.friends + relationships.romanticPartners).filter { $0.status == .strained }.count
        let strongestBond = max(relationships.friends.strongestBond, relationships.partnerBond)
        let connectionCount = relationships.friends.count + (relationships.hasPartner ? 1 : 0)

        relationships.publicReputation = (
            relationships.publicReputation +
            ((strongestBond - 50) / 10) +
            min(3, connectionCount) -
            strainedCount * 2 -
            max(0, relationships.activeRumorHeat - 45) / 8
        ).clamped(to: 0...100)
        relationships.privateReputation = (
            relationships.privateReputation +
            ((health.mentalWellness - 50) / 10) +
            ((player.happiness - 50) / 12) -
            strainedCount * 2 -
            max(0, financialStress - 45) / 12
        ).clamped(to: 0...100)
        relationships.activeRumorHeat = (
            relationships.activeRumorHeat -
            4 +
            strainedCount * 2 +
            (connectionCount >= 4 ? 1 : 0)
        ).clamped(to: 0...100)

        ageTensions(in: &relationships, playerAge: player.age, financialStress: financialStress, result: &result)
        refreshFutureAlignment(
            in: &relationships,
            family: family,
            housing: housing,
            financialStress: financialStress,
            result: &result
        )

        if relationships.activeRumorHeat >= 55 {
            relationships.recentSocialHit = "Rumor followed you into other rooms."
            result.careerEffects = mergeCareerEffects(
                result.careerEffects,
                with: CareerEffects(
                    performance: nil,
                    yearsWorked: nil,
                    setStatus: nil,
                    setProfile: nil,
                    setRoleID: nil,
                    incomeBonus: nil,
                    promote: nil,
                    loseJob: nil,
                    burnout: nil,
                    schedulePressure: nil,
                    relationshipSpillover: 2,
                    jobSecurity: -2,
                    managerFriction: 2,
                    scheduleControl: nil,
                    retrainingProgress: nil,
                    setRetrainingTargetProfile: nil,
                    setOpenDoor: nil,
                    clearOpenDoor: nil
                )
            )
            result.notes.append(
                DomainNote(
                    title: "Social Fallout",
                    text: "Rumor stayed hot enough to spill beyond your social life and change how other people handled you.",
                    tags: [.relationships, .career]
                )
            )
        }

        if relationships.activeTensionCount > 0 {
            let strongestTension = relationships.strongestTension?.severity ?? 0
            result.coreEffects = mergeCoreEffects(
                result.coreEffects,
                with: CoreStatEffects(happiness: strongestTension >= 55 ? -2 : -1)
            )
            result.healthEffects = mergeHealthEffects(
                result.healthEffects,
                with: HealthEffects(mental: strongestTension >= 55 ? -2 : -1)
            )
            if let headline = relationships.strongestTension?.headline {
                result.notes.append(
                    DomainNote(
                        title: "Loose Ends",
                        text: "\(headline) stayed unresolved and kept draining emotional room from the year.",
                        tags: [.relationships, .health]
                    )
                )
            }
        }
    }

    private func ageTensions(
        in relationships: inout RelationshipState,
        playerAge: Int,
        financialStress: Int,
        result: inout DomainYearResult
    ) {
        relationships.tensions = relationships.tensions.compactMap { tension in
            var updated = tension
            let stressGain = financialStress >= 48 ? 3 : 0
            updated.severity = (updated.severity - 6 + stressGain).clamped(to: 0...100)
            updated.createdAge = min(updated.createdAge, playerAge)
            return updated.severity <= 8 ? nil : updated
        }

        if relationships.hasCohabitingPartner && financialStress >= 45 {
            addOrMergeTension(
                into: &relationships,
                headline: "Shared bills became shared tension",
                impactLine: "Money strain is now living inside the relationship, not just beside it.",
                severity: 52,
                source: .moneyStress,
                target: .household,
                createdAge: playerAge,
                targetName: relationships.partnerName,
                impactedDomains: [.relationships, .finance, .housing]
            )
        }
    }

    private func refreshFutureAlignment(
        in relationships: inout RelationshipState,
        family: FamilyState,
        housing: HousingState,
        financialStress: Int,
        result: inout DomainYearResult
    ) {
        guard let partner = relationships.romanticPartner else {
            relationships.futureAlignment = FutureAlignmentState()
            return
        }

        relationships.futureAlignment.cohabitationReadiness = (
            partner.bond +
            partner.commitmentAlignment -
            max(0, financialStress - 40) -
            max(0, 45 - housing.housingStability)
        ) / 2
        relationships.futureAlignment.familyReadiness = (
            partner.bond +
            partner.commitmentAlignment -
            max(0, financialStress - 35) -
            family.childCount * 6 -
            (family.postpartumYearsRemaining > 0 ? 8 : 0)
        ) / 2
        relationships.futureAlignment.retrainingReadiness = (
            partner.commitmentAlignment +
            relationships.privateReputation -
            max(0, financialStress - 35)
        ) / 2
        relationships.futureAlignment.homeReadiness = (
            partner.commitmentAlignment +
            housing.housingStability -
            max(0, financialStress - 30)
        ) / 2
        relationships.futureAlignment.activeConflictHeadline = nil

        if partner.bond >= 70, !partner.isCohabiting, relationships.futureAlignment.cohabitationReadiness <= 45 {
            relationships.futureAlignment.activeConflictHeadline = "The move-in future is split"
            addOrMergeTension(
                into: &relationships,
                headline: "The move-in future stayed split",
                impactLine: "The relationship feels real, but shared life still does not feel equally safe to both of you.",
                severity: 54,
                source: .milestoneConflict,
                target: .future,
                createdAge: family.childCount + family.postpartumYearsRemaining + 18,
                targetName: partner.name,
                impactedDomains: [.relationships, .housing, .finance]
            )
        }

        if family.pregnancyIntent == .trying, relationships.futureAlignment.familyReadiness <= 46 {
            relationships.futureAlignment.activeConflictHeadline = "Family timing feels mismatched"
            addOrMergeTension(
                into: &relationships,
                headline: "Family timing started hurting the bond",
                impactLine: "Wanting a bigger future did not mean both of you felt equally ready for it.",
                severity: 56,
                source: .familyPlanning,
                target: .future,
                createdAge: family.childCount + 18,
                targetName: partner.name,
                impactedDomains: [.relationships, .lifeEvent, .finance]
            )
            result.financeEffects = FinanceEffects(financialStressDelta: 2)
        }

        if partner.isCohabiting, housing.housingStability < 45, financialStress >= 45 {
            relationships.futureAlignment.activeConflictHeadline = "Home pressure is testing the future"
            result.housingEffects = HousingEffects(stabilityDelta: -2)
            result.notes.append(
                DomainNote(
                    title: "Milestone Conflict",
                    text: "Living together made future decisions feel more urgent, not more settled.",
                    tags: [.relationships, .housing, .finance]
                )
            )
        }
    }

    private func addOrMergeTension(
        into relationships: inout RelationshipState,
        headline: String,
        impactLine: String,
        severity: Int,
        source: RelationshipTensionSource,
        target: RelationshipTensionTarget,
        createdAge: Int,
        targetName: String?,
        impactedDomains: [HistoryDomainTag]
    ) {
        if let index = relationships.tensions.firstIndex(where: { $0.source == source && $0.target == target && $0.targetName == targetName }) {
            relationships.tensions[index].severity = (relationships.tensions[index].severity + severity / 2).clamped(to: 0...100)
            relationships.tensions[index].headline = headline
            relationships.tensions[index].impactLine = impactLine
            relationships.tensions[index].impactedDomains = impactedDomains
        } else {
            relationships.tensions.append(
                RelationshipTension(
                    headline: headline,
                    impactLine: impactLine,
                    severity: severity,
                    source: source,
                    target: target,
                    createdAge: createdAge,
                    targetName: targetName,
                    impactedDomains: impactedDomains
                )
            )
        }
    }

    private func resolveTension(in relationships: inout RelationshipState, matching targets: [RelationshipTensionTarget], relief: Int) {
        guard !targets.isEmpty else { return }
        relationships.tensions = relationships.tensions.compactMap { tension in
            guard targets.contains(tension.target) else { return tension }
            var updated = tension
            updated.severity = max(0, updated.severity - relief)
            return updated.severity <= 8 ? nil : updated
        }
    }

    private func mergeCareerEffects(_ lhs: CareerEffects?, with rhs: CareerEffects) -> CareerEffects {
        var merged = CareerEffects()
        merged.performance = (lhs?.performance ?? 0) + (rhs.performance ?? 0)
        merged.yearsWorked = (lhs?.yearsWorked ?? 0) + (rhs.yearsWorked ?? 0)
        merged.setStatus = rhs.setStatus ?? lhs?.setStatus
        merged.setProfile = rhs.setProfile ?? lhs?.setProfile
        merged.setRoleID = rhs.setRoleID ?? lhs?.setRoleID
        merged.incomeBonus = (lhs?.incomeBonus ?? 0) + (rhs.incomeBonus ?? 0)
        merged.promote = rhs.promote ?? lhs?.promote
        merged.loseJob = rhs.loseJob ?? lhs?.loseJob
        merged.burnout = (lhs?.burnout ?? 0) + (rhs.burnout ?? 0)
        merged.schedulePressure = (lhs?.schedulePressure ?? 0) + (rhs.schedulePressure ?? 0)
        merged.relationshipSpillover = (lhs?.relationshipSpillover ?? 0) + (rhs.relationshipSpillover ?? 0)
        merged.jobSecurity = (lhs?.jobSecurity ?? 0) + (rhs.jobSecurity ?? 0)
        merged.managerFriction = (lhs?.managerFriction ?? 0) + (rhs.managerFriction ?? 0)
        merged.scheduleControl = (lhs?.scheduleControl ?? 0) + (rhs.scheduleControl ?? 0)
        merged.retrainingProgress = (lhs?.retrainingProgress ?? 0) + (rhs.retrainingProgress ?? 0)
        merged.setRetrainingTargetProfile = rhs.setRetrainingTargetProfile ?? lhs?.setRetrainingTargetProfile
        merged.setOpenDoor = rhs.setOpenDoor ?? lhs?.setOpenDoor
        merged.clearOpenDoor = rhs.clearOpenDoor ?? lhs?.clearOpenDoor
        return merged
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

    private func mergeCoreEffects(_ lhs: CoreStatEffects?, with rhs: CoreStatEffects) -> CoreStatEffects {
        CoreStatEffects(
            happiness: (lhs?.happiness ?? 0) + (rhs.happiness ?? 0),
            smarts: (lhs?.smarts ?? 0) + (rhs.smarts ?? 0),
            looks: (lhs?.looks ?? 0) + (rhs.looks ?? 0),
            health: (lhs?.health ?? 0) + (rhs.health ?? 0)
        )
    }
}

struct FamilySystem {
    private let childNames = ["Noah", "Emma", "Liam", "Mia", "Leo", "Ava", "Eli", "Nora", "Mason", "Ivy"]

    func advanceYear(input: FamilyDomainSnapshot, family: inout FamilyState) -> DomainYearResult {
        advanceYear(
            player: input.player,
            relationships: input.relationships,
            family: &family,
            health: input.health,
            finance: input.finance
        )
    }

    func advanceYear(
        player: Player,
        relationships: RelationshipState,
        family: inout FamilyState,
        health: HealthState,
        finance: FinanceState
    ) -> DomainYearResult {
        var result = DomainYearResult()

        ageChildren(family: &family, result: &result)
        family.postpartumYearsRemaining = max(0, family.postpartumYearsRemaining - 1)

        guard player.age >= 18 else { return result }

        if var pregnancy = family.pregnancy {
            pregnancy.yearsActive += 1
            if pregnancy.phase != .thirdTrimester {
                let lossRisk = pregnancyLossRisk(player: player, health: health, finance: finance, pregnancy: pregnancy)
                if Int.random(in: 1...100) <= lossRisk {
                    family.pregnancy = nil
                    result.healthEffects = HealthEffects(physical: -3, mental: -8, exercise: nil, nutrition: nil, stressManagement: -6, addCondition: nil, removeCondition: nil, hasPrimaryCare: nil)
                    result.relationshipEffects = RelationshipEffects(partnerChange: pregnancy.isPlanned ? -4 : -6, commitmentAlignmentChange: -5)
                    result.notes.append(DomainNote(title: "Family", text: "The pregnancy ended this year, leaving emotional strain that lingered well beyond the moment itself.", tags: [.lifeEvent, .health, .relationships]))
                    return result
                }
            }

            switch pregnancy.phase {
            case .firstTrimester:
                pregnancy.phase = .secondTrimester
                result.healthEffects = HealthEffects(physical: -2, mental: -2, exercise: nil, nutrition: 1, stressManagement: -2, addCondition: nil, removeCondition: nil, hasPrimaryCare: nil)
                result.notes.append(DomainNote(title: "Family", text: "Pregnancy settled in as the year moved forward, bringing more fatigue and more planning.", tags: [.lifeEvent, .health]))
                family.pregnancy = pregnancy
            case .secondTrimester:
                pregnancy.phase = .thirdTrimester
                result.healthEffects = HealthEffects(physical: -3, mental: -1, exercise: nil, nutrition: 1, stressManagement: -2, addCondition: nil, removeCondition: nil, hasPrimaryCare: nil)
                result.notes.append(DomainNote(title: "Family", text: "Pregnancy became impossible to ignore. Your routines and budget both had to adapt.", tags: [.lifeEvent, .health, .finance]))
                family.pregnancy = pregnancy
            case .thirdTrimester:
                let childName = nextChildName(avoiding: family.children.map(\.name))
                family.children.append(ChildRecord(name: childName, age: 0, livesAtHome: true, otherParentName: pregnancy.otherParentName, supportLoad: pregnancy.isPlanned ? 58 : 64))
                family.pregnancy = nil
                family.postpartumYearsRemaining = 2
                result.financeEffects = FinanceEffects(cashDelta: -1_400, livingCostDelta: nil, educationCostDelta: nil, dependentCostDelta: 2_400, discretionaryCostDelta: nil, financialStressDelta: 5, setRegionPolicyID: nil)
                result.healthEffects = HealthEffects(physical: -5, mental: pregnancy.isPlanned ? -2 : -4, exercise: nil, nutrition: nil, stressManagement: -4, addCondition: nil, removeCondition: nil, hasPrimaryCare: nil)
                result.relationshipEffects = RelationshipEffects(partnerChange: pregnancy.isPlanned ? 3 : -2, commitmentAlignmentChange: pregnancy.isPlanned ? 2 : -3)
                result.notes.append(DomainNote(title: "Birth", text: "You welcomed \(childName) this year, and life immediately became more expensive, more fragile, and more real.", tags: [.lifeEvent, .finance, .health, .relationships]))
            }
            return result
        }

        guard let partner = relationships.romanticPartner,
              partner.status == .active else { return result }

        let conceptionChance = conceptionChance(player: player, relationships: relationships, family: family, health: health, finance: finance)
        guard conceptionChance > 0 else { return result }
        if Int.random(in: 1...100) <= conceptionChance {
            let isPlanned = family.pregnancyIntent == .trying
            let highRisk = pregnancyLossRisk(
                player: player,
                health: health,
                finance: finance,
                pregnancy: PregnancyState(otherParentName: partner.name, isPlanned: isPlanned)
            ) >= 18
            family.pregnancy = PregnancyState(otherParentName: partner.name, isPlanned: isPlanned, isHighRisk: highRisk)
            result.relationshipEffects = RelationshipEffects(partnerChange: isPlanned ? 2 : -3, commitmentAlignmentChange: isPlanned ? 3 : -4)
            result.healthEffects = HealthEffects(physical: -1, mental: isPlanned ? -1 : -3, exercise: nil, nutrition: nil, stressManagement: -2, addCondition: nil, removeCondition: nil, hasPrimaryCare: nil)
            let text = isPlanned
                ? "Your plans turned into a pregnancy this year. Relief and pressure arrived together."
                : "A pregnancy changed the trajectory of the year before the rest of life had fully caught up."
            result.notes.append(DomainNote(title: "Family", text: text, tags: [.lifeEvent, .relationships, .health]))
        }

        return result
    }

    private func ageChildren(family: inout FamilyState, result: inout DomainYearResult) {
        guard !family.children.isEmpty else { return }
        family.children.indices.forEach { family.children[$0].age += 1 }
        for index in family.children.indices where family.children[index].age >= 19 && family.children[index].livesAtHome {
            family.children[index].livesAtHome = false
            result.notes.append(DomainNote(title: "Family", text: "\(family.children[index].name) became old enough to stop depending on your household full-time.", tags: [.lifeEvent, .finance]))
        }
    }

    func conceptionChance(
        player: Player,
        relationships: RelationshipState,
        family: FamilyState,
        health: HealthState,
        finance: FinanceState
    ) -> Int {
        guard let partner = relationships.romanticPartner else { return 0 }
        if player.age < 18 || player.age > 45 { return 0 }
        var chance: Int
        switch family.pregnancyIntent {
        case .avoid:
            chance = 1
        case .chance:
            chance = 8
        case .trying:
            chance = 26
        }

        if player.age >= 35 { chance -= 5 }
        if player.age >= 40 { chance -= 8 }
        if partner.stage == .married { chance += 4 }
        else if partner.stage == .engaged || partner.stage == .committed { chance += 2 }
        if partner.isCohabiting { chance += 4 }
        if partner.bond >= 80 { chance += 3 }
        if partner.commitmentAlignment < 45 { chance -= 4 }
        chance += (health.physicalWellness - 50) / 12
        chance += (health.mentalWellness - 50) / 18
        chance -= health.activeConditions.count * 3
        chance -= max(0, finance.financialStress - 45) / 10
        chance -= family.childCount
        return chance.clamped(to: 0...55)
    }

    func pregnancyLossRisk(player: Player, health: HealthState, finance: FinanceState, pregnancy: PregnancyState) -> Int {
        var risk = 6
        if player.age < 20 { risk += 3 }
        if player.age >= 35 { risk += 5 }
        if player.age >= 40 { risk += 8 }
        if health.physicalWellness < 50 { risk += (50 - health.physicalWellness) / 5 }
        if health.mentalWellness < 45 { risk += (45 - health.mentalWellness) / 8 }
        risk += health.activeConditions.count * 2
        risk += max(0, finance.financialStress - 55) / 8
        if pregnancy.isHighRisk { risk += 4 }
        return risk.clamped(to: 3...35)
    }

    private func nextChildName(avoiding existing: [String]) -> String {
        childNames.first(where: { !existing.contains($0) }) ?? "New Baby"
    }
}

struct HealthSystem {
    func advanceYear(input: HealthDomainSnapshot, player: inout Player, health: inout HealthState) -> DomainYearResult {
        advanceYear(
            player: &player,
            career: input.career,
            relationships: input.relationships,
            housing: input.housing,
            healthcarePressure: input.healthcarePressure,
            health: &health
        )
    }

    func advanceYear(player: inout Player, career: CareerState, relationships: RelationshipState, housing: HousingState, healthcarePressure: Int, health: inout HealthState) -> DomainYearResult {
        var result = DomainYearResult()

        let workStress: Int
        switch career.status {
        case .student: workStress = -1
        case .partTime: workStress = 1
        case .fullTime: workStress = 3
        case .unemployed: workStress = 2
        }

        let socialSupport = relationships.friends.count + (relationships.hasPartner ? 1 : 0)
        let physicalShift =
            ((health.habits.exercise - 50) / 8) +
            ((health.habits.nutrition - 50) / 8) -
            (health.activeConditions.reduce(0) { $0 + max(1, $1.severity / 20) }) -
            workStress
        let mentalShift =
            ((health.habits.stressManagement - 45) / 6) +
            ((player.happiness - 50) / 10) +
            socialSupport -
            workStress -
            healthcarePressure -
            (housing.livingArrangement == .couchSurfing ? 4 : 0) +
            (housing.housingStability >= 70 ? 1 : 0)

        health.physicalWellness = (health.physicalWellness + physicalShift).clamped(to: 0...100)
        health.mentalWellness = (health.mentalWellness + mentalShift).clamped(to: 0...100)

        if health.activeConditions.isEmpty, health.physicalWellness < 42 {
            health.activeConditions.append(HealthCondition(name: "Chronic Fatigue", severity: 32))
            result.notes.append(DomainNote(title: "Health", text: "Persistent fatigue started affecting your day-to-day life."))
        }

        if health.mentalWellness < 35, !health.activeConditions.contains(where: { $0.name == "Burnout" }) {
            health.activeConditions.append(HealthCondition(name: "Burnout", severity: 28))
            result.notes.append(DomainNote(title: "Health", text: "Stress built up enough to leave you burned out."))
        }

        health.activeConditions.indices.forEach { index in
            let careModifier = health.hasPrimaryCare ? -5 : 5
            health.activeConditions[index].severity = (health.activeConditions[index].severity + careModifier).clamped(to: 1...100)
        }

        let seriousConditions = health.activeConditions.filter { $0.severity >= 70 }
        if !seriousConditions.isEmpty {
            result.notes.append(DomainNote(title: "Health Warning", text: "Serious health conditions are putting visible strain on your life."))
        }

        if player.age >= 18,
           !health.activeConditions.isEmpty,
           (career.status == .fullTime || career.status == .partTime),
           (career.jobSecurity < 55 || healthcarePressure >= 3) {
            result.notes.append(
                DomainNote(
                    title: "Recovery Bottleneck",
                    text: "Your recovery limits are now shaping how durable work and money feel, not just how tired you are.",
                    tags: [.health, .career, .finance]
                )
            )
        }

        health.activeConditions.removeAll {
            $0.severity <= 10 && health.hasPrimaryCare
        }

        player.health = ((health.physicalWellness * 2) + health.mentalWellness) / 3
        player.happiness = (player.happiness + (health.mentalWellness - 50) / 10).clamped(to: 0...100)
        player.clampStats()
        health.clamp()

        return result
    }

    func apply(effect: HealthEffects, player: inout Player, health: inout HealthState) {
        if let physical = effect.physical {
            health.physicalWellness = (health.physicalWellness + physical).clamped(to: 0...100)
        }

        if let mental = effect.mental {
            health.mentalWellness = (health.mentalWellness + mental).clamped(to: 0...100)
        }

        if let exercise = effect.exercise {
            health.habits.exercise = (health.habits.exercise + exercise).clamped(to: 0...100)
        }

        if let nutrition = effect.nutrition {
            health.habits.nutrition = (health.habits.nutrition + nutrition).clamped(to: 0...100)
        }

        if let stressManagement = effect.stressManagement {
            health.habits.stressManagement = (health.habits.stressManagement + stressManagement).clamped(to: 0...100)
        }

        if let condition = effect.addCondition, !health.activeConditions.contains(where: { $0.name == condition }) {
            health.activeConditions.append(HealthCondition(name: condition, severity: 30))
        }

        if let removeCondition = effect.removeCondition {
            health.activeConditions.removeAll { $0.name == removeCondition }
        }

        if let hasPrimaryCare = effect.hasPrimaryCare {
            health.hasPrimaryCare = hasPrimaryCare
        }

        player.health = ((health.physicalWellness * 2) + health.mentalWellness) / 3
        player.clampStats()
        health.clamp()
    }

    func applyAction(_ choiceID: ActionChoiceID, player: inout Player, health: inout HealthState) -> DomainYearResult {
        var result = DomainYearResult()

        switch choiceID {
        case .protectSleep:
            health.mentalWellness += 5
            health.physicalWellness += 2
            health.habits.stressManagement += 4
            result.educationEffects = EducationEffects(attendancePressure: -4)
            result.notes.append(
                DomainNote(
                    title: "Health Focus",
                    text: "You protected your sleep and felt a little more stable under the year.",
                    tags: [.health, .education]
                )
            )
        case .rest:
            health.mentalWellness += 4
            health.physicalWellness += 2
            result.notes.append(
                DomainNote(
                    title: "Health Focus",
                    text: "You chose recovery over grind and gave yourself some room to heal.",
                    tags: [.health]
                )
            )
        case .pushThrough:
            health.mentalWellness -= 4
            health.physicalWellness -= 2
            result.notes.append(
                DomainNote(
                    title: "Health Focus",
                    text: "You pushed through exhaustion this year and your body kept score.",
                    tags: [.health]
                )
            )
        case .seeDoctor:
            health.hasPrimaryCare = true
            health.mentalWellness += 2
            result.financeEffects = FinanceEffects(cashDelta: -300, livingCostDelta: nil, educationCostDelta: nil, dependentCostDelta: nil, discretionaryCostDelta: nil, financialStressDelta: nil, setRegionPolicyID: nil)
            result.notes.append(
                DomainNote(
                    title: "Health Focus",
                    text: "You spent money on care this year, trading cash for a little stability.",
                    tags: [.health, .finance]
                )
            )
        default:
            return result
        }

        player.health = ((health.physicalWellness * 2) + health.mentalWellness) / 3
        player.clampStats()
        health.clamp()
        return result
    }
}

struct HomeOwnershipSystem {
    let balanceProfile: SimulationBalanceProfile
    let minimumLiquidReserve: Int
    let downPaymentRatePercent: Int
    let closingCostRatePercent: Int
    let saleFeeRatePercent: Int
    let yearlyValueRoll: (ClosedRange<Int>) -> Int
    let repairRoll: (ClosedRange<Int>) -> Int

    init(
        balanceProfile: SimulationBalanceProfile = .playableRealismV1,
        minimumLiquidReserve: Int = SimulationBalanceProfile.playableRealismV1.homeownership.minimumLiquidReserve,
        downPaymentRatePercent: Int = SimulationBalanceProfile.playableRealismV1.homeownership.downPaymentRatePercent,
        closingCostRatePercent: Int = SimulationBalanceProfile.playableRealismV1.homeownership.closingCostRatePercent,
        saleFeeRatePercent: Int = 6,
        yearlyValueRoll: @escaping (ClosedRange<Int>) -> Int = { Int.random(in: $0) },
        repairRoll: @escaping (ClosedRange<Int>) -> Int = { Int.random(in: $0) }
    ) {
        self.balanceProfile = balanceProfile
        self.minimumLiquidReserve = minimumLiquidReserve
        self.downPaymentRatePercent = downPaymentRatePercent
        self.closingCostRatePercent = closingCostRatePercent
        self.saleFeeRatePercent = saleFeeRatePercent
        self.yearlyValueRoll = yearlyValueRoll
        self.repairRoll = repairRoll
    }

    func isHomeAction(_ choiceID: ActionChoiceID?) -> Bool {
        switch choiceID {
        case .saveForDownPayment, .buyStarterHome, .refinanceMortgage, .buildMaintenanceReserve, .sellHome:
            return true
        default:
            return false
        }
    }

    func advanceYear(
        input: AssetDomainSnapshot,
        plannedAction: ActionChoiceID?,
        finance: inout FinanceState,
        assets: inout AssetState,
        housing: inout HousingState
    ) -> DomainYearResult {
        var result = DomainYearResult()
        let previousTotalWealth = finance.totalWealth
        assets.normalize()
        finance.lastYearHomeValueDelta = 0
        finance.lastYearMortgagePrincipalPaid = 0
        finance.housingDebtBurden = 0
        syncHomeWealth(finance: &finance, assets: assets)

        guard input.player.age >= 18 else { return result }
        let action = isHomeAction(plannedAction) ? plannedAction : nil

        if !assets.ownsHome {
            if finance.cashOnHand < 0, finance.homeDownPaymentSavings > 0 {
                let release = min(finance.homeDownPaymentSavings, abs(finance.cashOnHand))
                finance.homeDownPaymentSavings -= release
                finance.cashOnHand += release
                result.notes.append(DomainNote(title: "House Fund", text: "You had to pull from the future house fund just to steady this year.", tags: [.finance, .housing]))
            }

            switch action {
            case .saveForDownPayment:
                let targetValue = recommendedHomeValue(for: input, finance: finance)
                let availableCash = max(0, finance.cashOnHand - minimumLiquidReserve)
                let contribution = min(max(1_500, finance.lastYearBalanceDelta / 4), availableCash)
                assets.homeownershipTrackActive = true
                assets.targetHomeValue = targetValue
                if contribution > 0 {
                    finance.cashOnHand -= contribution
                    finance.homeDownPaymentSavings += contribution
                    result.notes.append(DomainNote(title: "House Fund", text: "You earmarked real money toward a down payment, which made ownership feel closer and the year tighter.", tags: [.finance, .housing]))
                } else {
                    result.notes.append(DomainNote(title: "House Fund", text: "You wanted to save for a home, but your cash floor was still too thin to move money safely.", tags: [.finance, .housing]))
                }
            case .buyStarterHome:
                let purchaseNotes = attemptPurchase(input: input, finance: &finance, assets: &assets, housing: &housing)
                result.notes.append(contentsOf: purchaseNotes)
            default:
                break
            }

            syncHomeWealth(finance: &finance, assets: assets)
            finance.accumulateWealthDelta(from: previousTotalWealth)
            assets.normalize()
            return result
        }

        guard var home = assets.primaryResidence else {
            syncHomeWealth(finance: &finance, assets: assets)
            return result
        }

        assets.homeownershipTrackActive = true
        assets.targetHomeValue = max(assets.targetHomeValue, home.homeValue)

        switch action {
        case .buildMaintenanceReserve:
            let availableCash = max(0, finance.cashOnHand - minimumLiquidReserve)
            let reserveContribution = min(max(1_500, finance.lastYearBalanceDelta / 5), availableCash)
            if reserveContribution > 0 {
                finance.cashOnHand -= reserveContribution
                home.maintenanceReserve += reserveContribution
                result.notes.append(DomainNote(title: "House Reserve", text: "You built a repair reserve instead of pretending the house would stay quiet forever.", tags: [.finance, .housing]))
            } else {
                result.notes.append(DomainNote(title: "House Reserve", text: "You tried to build repair cushion, but the liquid margin was not there this year.", tags: [.finance, .housing]))
            }
        case .refinanceMortgage:
            let refinanceCost = 1_500
            if home.mortgagePrincipal > 0, home.mortgageRatePercent >= 6, finance.cashOnHand - refinanceCost >= minimumLiquidReserve / 2 {
                finance.cashOnHand -= refinanceCost
                home.mortgageRatePercent -= 1
                home.monthlyMortgageCost = monthlyMortgagePayment(principal: home.mortgagePrincipal, ratePercent: home.mortgageRatePercent, years: max(1, home.remainingMortgageYears))
                result.notes.append(DomainNote(title: "Refinance", text: "You refinanced the mortgage and bought yourself a little more room in the budget.", tags: [.finance, .housing]))
            } else {
                result.notes.append(DomainNote(title: "Refinance", text: "You wanted refinance relief, but the numbers never got strong enough to make it land cleanly.", tags: [.finance, .housing]))
            }
        case .sellHome:
            let notes = sellPrimaryHome(home: home, finance: &finance, assets: &assets, housing: &housing, distressSale: false)
            result.notes.append(contentsOf: notes)
            syncHomeWealth(finance: &finance, assets: assets)
            finance.accumulateWealthDelta(from: previousTotalWealth)
            assets.normalize()
            return result
        default:
            break
        }

        let annualMortgageCost = home.mortgagePrincipal > 0 ? home.monthlyMortgageCost * 12 : 0
        let annualUpkeep = max(1_200, Int((Double(home.homeValue) * 0.006).rounded()))
        finance.cashOnHand -= annualMortgageCost
        finance.housingDebtBurden = annualMortgageCost + annualUpkeep

        let interestPaid = home.mortgagePrincipal > 0 ? Int((Double(home.mortgagePrincipal) * Double(home.mortgageRatePercent) / 100.0).rounded()) : 0
        let principalPaid = min(home.mortgagePrincipal, max(0, annualMortgageCost - interestPaid))
        home.mortgagePrincipal -= principalPaid
        home.remainingMortgageYears = max(0, home.remainingMortgageYears - (principalPaid > 0 ? 1 : 0))
        finance.lastYearMortgagePrincipalPaid = principalPaid

        let valueRate = homeValueRate(for: finance.currentRegionPolicyID, traits: input.player.traits, currentStatus: home.status, upgrades: home.upgrades)
        let valueDelta = Int((Double(home.homeValue) * Double(valueRate) / 100.0).rounded())
        home.homeValue = max(90_000, home.homeValue + valueDelta)
        finance.lastYearHomeValueDelta = valueDelta

        let repairCost = repairCostForYear(home: home, financialStress: finance.financialStress)
        if repairCost > 0 {
            let reserveUsed = min(home.maintenanceReserve, repairCost)
            home.maintenanceReserve -= reserveUsed
            let outOfPocket = repairCost - reserveUsed
            finance.cashOnHand -= outOfPocket
            finance.housingDebtBurden += repairCost
            result.notes.append(DomainNote(title: "Home Repair", text: "The house demanded money this year. Some was covered by reserve, and the rest came straight from cash.", tags: [.finance, .housing]))
        }

        home.yearsOwned += 1
        home.equity = max(0, home.homeValue - home.mortgagePrincipal)
        home.normalize()

        if finance.cashOnHand < 0 || (home.maintenanceReserve < 1_000 && finance.financialStress >= 58) {
            if home.status == .delinquent || finance.cashOnHand < -12_000 {
                let notes = sellPrimaryHome(home: home, finance: &finance, assets: &assets, housing: &housing, distressSale: true)
                result.notes.append(contentsOf: notes)
                syncHomeWealth(finance: &finance, assets: assets)
                finance.accumulateWealthDelta(from: previousTotalWealth)
                assets.normalize()
                return result
            }

            home.status = .delinquent
            finance.financialStress = (finance.financialStress + 8).clamped(to: 0...100)
            housing.housingStability = (housing.housingStability - 10).clamped(to: 0...100)
            result.notes.append(DomainNote(title: "Mortgage Pressure", text: "The house stopped feeling like security and started feeling like a bill you might not be able to carry.", tags: [.finance, .housing]))
        } else if home.status == .delinquent && finance.cashOnHand >= minimumLiquidReserve / 2 {
            home.status = .current
            housing.housingStability = (housing.housingStability + 5).clamped(to: 0...100)
            result.notes.append(DomainNote(title: "Mortgage Recovery", text: "You caught back up and kept the mortgage from turning into a full collapse.", tags: [.finance, .housing]))
        }

        if finance.housingDebtBurden > max(9_000, finance.annualNetIncome / 3) {
            finance.financialStress = (finance.financialStress + 4).clamped(to: 0...100)
        } else if home.equity > home.downPaymentPaid {
            finance.financialStress = (finance.financialStress - 2).clamped(to: 0...100)
        }

        if home.mortgagePrincipal == 0 {
            result.notes.append(DomainNote(title: "Mortgage Cleared", text: "You finally owned the place free and clear. It is still a responsibility, but less of it is debt now.", tags: [.finance, .housing, .assets]))
        }

        housing.livingArrangement = .ownerOccupied
        housing.hasRoommate = false
        housing.housingCostBand = 20
        housing.housingStability = (housing.housingStability + (home.status == .current ? 2 : -4)).clamped(to: 0...100)
        assets.primaryResidence = home
        syncHomeWealth(finance: &finance, assets: assets)
        finance.accumulateWealthDelta(from: previousTotalWealth)
        assets.normalize()
        return result
    }

    private func attemptPurchase(input: AssetDomainSnapshot, finance: inout FinanceState, assets: inout AssetState, housing: inout HousingState) -> [DomainNote] {
        let targetValue = recommendedHomeValue(for: input, finance: finance)
        assets.homeownershipTrackActive = true
        assets.targetHomeValue = targetValue

        guard input.career.status == .fullTime,
              input.career.yearsWorked >= balanceProfile.homeownership.minimumYearsWorked,
              finance.lastYearBalanceDelta >= balanceProfile.homeownership.minimumPositiveBalanceDelta,
              finance.debtPressureBand != .heavy,
              finance.debtPressureBand != .crushing,
              finance.recentDebtReliefYears == 0 else {
            return [DomainNote(title: "Home Search", text: "You were not stable enough yet to carry ownership without it becoming immediate danger.", tags: [.finance, .housing])]
        }

        let downPayment = targetValue * downPaymentRatePercent / 100
        let closingCost = targetValue * closingCostRatePercent / 100
        let upfrontTotal = downPayment + closingCost
        guard finance.homeDownPaymentSavings + finance.cashOnHand - upfrontTotal >= minimumLiquidReserve else {
            return [DomainNote(title: "Home Search", text: "You found a starter-home lane, but the down payment, closing costs, and reserve floor still did not line up together.", tags: [.finance, .housing])]
        }

        let fromSavings = min(finance.homeDownPaymentSavings, upfrontTotal)
        finance.homeDownPaymentSavings -= fromSavings
        finance.cashOnHand -= (upfrontTotal - fromSavings)

        let mortgagePrincipal = max(0, targetValue - downPayment)
        let mortgageRate = finance.currentRegionPolicyID == "expensive_coastal" ? 7 : 6
        var home = PrimaryResidenceState(
            homeValue: targetValue,
            mortgagePrincipal: mortgagePrincipal,
            monthlyMortgageCost: monthlyMortgagePayment(principal: mortgagePrincipal, ratePercent: mortgageRate, years: 30),
            mortgageRatePercent: mortgageRate,
            remainingMortgageYears: 30,
            equity: downPayment,
            downPaymentPaid: downPayment,
            maintenanceReserve: 0
        )
        home.normalize()

        assets.primaryResidence = home
        housing.livingArrangement = .ownerOccupied
        housing.hasRoommate = false
        housing.housingCostBand = 20
        housing.housingStability = max(housing.housingStability, 78)
        return [DomainNote(title: "Bought A Home", text: "You bought a starter home. The stability signal is real, and so is the debt now sitting underneath the rest of your life.", tags: [.finance, .housing, .assets])]
    }

    private func sellPrimaryHome(home: PrimaryResidenceState, finance: inout FinanceState, assets: inout AssetState, housing: inout HousingState, distressSale: Bool) -> [DomainNote] {
        let feeRate = distressSale ? saleFeeRatePercent + 10 : saleFeeRatePercent
        let grossAfterFees = home.homeValue * (100 - feeRate) / 100
        let recoveredEquity = max(0, grossAfterFees - home.mortgagePrincipal)
        finance.cashOnHand += recoveredEquity + home.maintenanceReserve
        finance.homeEquity = 0
        finance.housingDebtBurden = 0
        assets.primaryResidence = nil
        assets.homeownershipTrackActive = false
        assets.targetHomeValue = 0
        housing.hasRoommate = finance.cashOnHand < minimumLiquidReserve * 2
        housing.livingArrangement = finance.cashOnHand < minimumLiquidReserve ? .roommates : .soloRenting
        if distressSale && finance.cashOnHand < 0 {
            housing.livingArrangement = .couchSurfing
        }
        switch housing.livingArrangement {
        case .soloRenting:
            housing.housingCostBand = 55
        case .roommates:
            housing.housingCostBand = 36
        case .couchSurfing:
            housing.housingCostBand = 8
        case .familyHome:
            housing.housingCostBand = 18
        case .ownerOccupied:
            housing.housingCostBand = 20
        }
        housing.housingStability = distressSale ? 28 : 48
        let text = distressSale
            ? "You lost the house under pressure. Some value survived, but ownership ended as a setback instead of a platform."
            : "You sold the house and turned equity back into cash, giving up stability to regain room."
        return [DomainNote(title: distressSale ? "Foreclosure" : "Sold Home", text: text, tags: [.finance, .housing, .assets])]
    }

    private func recommendedHomeValue(for input: AssetDomainSnapshot, finance: FinanceState) -> Int {
        var value = (input.career.annualIncome * 4) + 24_000 + (input.housing.housingCostBand * 900)
        switch finance.currentRegionPolicyID {
        case "expensive_coastal":
            value += 25_000
        case "factory_town":
            value -= 20_000
        default:
            break
        }
        return value.clamped(to: 145_000...265_000)
    }

    private func monthlyMortgagePayment(principal: Int, ratePercent: Int, years: Int) -> Int {
        guard principal > 0 else { return 0 }
        let months = max(1, years * 12)
        let monthlyRate = Double(ratePercent) / 100.0 / 12.0
        if monthlyRate == 0 {
            return Int((Double(principal) / Double(months)).rounded())
        }
        let factor = pow(1 + monthlyRate, Double(months))
        let payment = Double(principal) * ((monthlyRate * factor) / (factor - 1))
        return Int(payment.rounded())
    }

    private func homeValueRate(for policyID: String?, traits: [PersonalityTrait], currentStatus: PrimaryResidenceStatus, upgrades: [HouseUpgrade]) -> Int {
        var rate = 2 + yearlyValueRoll(-4...5)
        if traits.contains(.lucky) { rate += 1 }
        if currentStatus == .delinquent { rate -= 1 }
        
        // Upgrades boost appreciation
        if !upgrades.isEmpty {
            rate += max(1, upgrades.count / 2)
        }
        
        switch policyID {
        case "expensive_coastal":
            rate += 1
        case "factory_town":
            rate -= 1
        default:
            break
        }
        return rate.clamped(to: -5...8)
    }

    private func repairCostForYear(home: PrimaryResidenceState, financialStress: Int) -> Int {
        let roll = repairRoll(0...100)
        if roll < 58 { return 0 }
        let base = max(900, Int((Double(home.homeValue) * 0.01).rounded()))
        if roll > 92 || financialStress >= 70 {
            return min(7_500, base + 2_800)
        }
        return min(4_800, base)
    }

    private func syncHomeWealth(finance: inout FinanceState, assets: AssetState) {
        finance.homeEquity = assets.primaryResidence?.equity ?? 0
    }
}
