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
        
        // Discovery Logic for Affairs
        let discoveryRoll = Int.random(in: 0...100)
        let foundAffair = relationships.romanticPartners.contains { $0.isSecret } && discoveryRoll < (relationships.activeRumorHeat / 4)
        
        if foundAffair {
            result.notes.append(DomainNote(title: "Affair Discovered", text: "Your secret relationship was exposed. The fallout was immediate and devastating.", tags: [.relationships, .lifeEvent]))
            relationships.activeRumorHeat += 40
            relationships.publicReputation -= 30
            relationships.privateReputation -= 40
            
            // Mark all secrets as public
            for i in relationships.romanticPartners.indices {
                relationships.romanticPartners[i].isSecret = false
            }
            
            // Severe bond hit to primary partner
            if let primaryIndex = relationships.romanticPartners.firstIndex(where: { $0.stage == .married || $0.stage == .engaged || $0.stage == .committed }) {
                relationships.romanticPartners[primaryIndex].bond -= 50
                relationships.romanticPartners[primaryIndex].status = .strained
                addOrMergeTension(
                    into: &relationships,
                    headline: "Trust is shattered",
                    impactLine: "The discovery of your infidelity has left the relationship in ruins.",
                    severity: 85,
                    source: .rumor,
                    target: .partner,
                    createdAge: player.age,
                    targetName: relationships.romanticPartners[primaryIndex].name,
                    impactedDomains: [.relationships, .health]
                )
            }
        }

        var agedPartners: [Relationship] = []
        for partner in relationships.romanticPartners {
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
            
            var drift =
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
            
            if partner.isSecret {
                drift -= 2 // Stress of keeping it secret
            }

            if let aged = agePartner(partner, drift: drift, result: &result) {
                agedPartners.append(aged)
            }
        }
        relationships.romanticPartners = agedPartners

        if player.age >= 18,
           let partner = relationships.primaryPartner,
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

        if effect.startDating == true, relationships.primaryPartner == nil {
            let name = nextName(from: partnerNames, avoiding: (relationships.friends.map(\.name) + relationships.romanticPartners.map(\.name)))
            relationships.romanticPartners.append(Relationship(name: name, type: .romantic, status: .active, bond: 55, yearsKnown: 0, stage: .dating, isCohabiting: false, commitmentAlignment: 50, personality: NPCPersonality.allCases.randomElement() ?? .loyal))
        }

        if let partnerChange = effect.partnerChange {
            adjustPartnerBond(in: &relationships, delta: partnerChange)
        }

        if let index = relationships.romanticPartners.firstIndex(where: { !$0.isSecret }) {
            var partner = relationships.romanticPartners[index]
            
            if let commitmentAlignmentChange = effect.commitmentAlignmentChange {
                partner.commitmentAlignment = (partner.commitmentAlignment + commitmentAlignmentChange).clamped(to: 0...100)
            }

            if let stage = effect.setPartnerStage {
                partner.stage = stage
            }

            if let setCohabiting = effect.setCohabiting {
                partner.isCohabiting = setCohabiting
            }
            
            relationships.romanticPartners[index] = partner
        }

        if effect.loseFriend == true, !relationships.friends.isEmpty {
            relationships.friends.removeFirst()
        }

        if effect.breakup == true {
            if let index = relationships.romanticPartners.firstIndex(where: { !$0.isSecret }) {
                let formerPartner = relationships.romanticPartners[index]
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
                relationships.romanticPartners.remove(at: index)
            }
        }

        relationships.publicReputation = (relationships.publicReputation + (effect.publicReputationChange ?? 0)).clamped(to: 0...100)
        relationships.privateReputation = (relationships.privateReputation + (effect.privateReputationChange ?? 0)).clamped(to: 0...100)
        relationships.activeRumorHeat = (relationships.activeRumorHeat + (effect.rumorHeatChange ?? 0)).clamped(to: 0...100)
        if let addKnownTag = effect.addKnownTag, !addKnownTag.isEmpty {
            relationships.knownForTags.append(addKnownTag)
        }

        relationships.friends.indices.forEach { relationships.friends[$0].bond = relationships.friends[$0].bond.clamped(to: 0...100) }
        relationships.romanticPartners.indices.forEach { 
            relationships.romanticPartners[$0].bond = relationships.romanticPartners[$0].bond.clamped(to: 0...100)
            relationships.romanticPartners[$0].commitmentAlignment = relationships.romanticPartners[$0].commitmentAlignment.clamped(to: 0...100)
        }
        relationships.clampSocialSignals()
    }

    func applyAction(_ choiceID: ActionChoiceID, state: inout GameState) -> DomainYearResult {
        var result = DomainYearResult()
        let player = state.player
        var relationships = state.relationships
        var finance = state.finance
        var assets = state.assets

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
            if let index = relationships.romanticPartners.firstIndex(where: { !$0.isSecret }) {
                relationships.romanticPartners[index].bond = (relationships.romanticPartners[index].bond + 7).clamped(to: 0...100)
                relationships.romanticPartners[index].commitmentAlignment = (relationships.romanticPartners[index].commitmentAlignment + 4).clamped(to: 0...100)
                relationships.romanticPartners[index].status = .active
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
            guard let index = relationships.romanticPartners.firstIndex(where: { !$0.isSecret }) else { return result }
            var partner = relationships.romanticPartners[index]
            partner.commitmentAlignment = (partner.commitmentAlignment + 10).clamped(to: 0...100)
            partner.bond = (partner.bond + 4).clamped(to: 0...100)
            let previousStage = partner.stage
            if partner.stage == .dating, partner.bond >= 68, partner.yearsKnown >= 1 {
                partner.stage = .committed
            } else if partner.stage == .committed, player.age >= 21, partner.bond >= 82, partner.yearsKnown >= 3, partner.commitmentAlignment >= 68 {
                partner.stage = .engaged
            }
            relationships.romanticPartners[index] = partner
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

        case .startAffair:
            let name = nextName(from: partnerNames, avoiding: (relationships.friends.map(\.name) + relationships.romanticPartners.map(\.name)))
            let affair = Relationship(name: name, type: .romantic, bond: 45, isSecret: true)
            relationships.romanticPartners.append(affair)
            relationships.activeRumorHeat += 15
            result.notes.append(DomainNote(title: "New Secret", text: "You started seeing someone on the side. The thrill is real, and so is the risk.", tags: [.relationships, .risk]))
            
        case .endAffair:
            relationships.romanticPartners.removeAll { $0.isSecret }
            result.notes.append(DomainNote(title: "Secret Ended", text: "You broke off your secret connection. The weight of the double life lifted immediately.", tags: [.relationships]))

        case .buyEngagementRing:
            let cost = 5000 + (finance.cashOnHand / 10).clamped(to: 0...20000)
            if finance.cashOnHand >= cost {
                finance.cashOnHand -= cost
                result.notes.append(DomainNote(title: "Engagement Ring", text: "You bought a ring that represents a real commitment. The year got tighter, but the future felt closer.", tags: [.finance, .relationships]))
                // Hidden flag or just trust the player to propose next
            } else {
                result.notes.append(DomainNote(title: "Engagement Ring", text: "You looked at rings, but the cash margin just was not there yet."))
            }

        case .signPrenup:
            guard let index = relationships.romanticPartners.firstIndex(where: { !$0.isSecret }) else { return result }
            if relationships.romanticPartners[index].commitmentAlignment >= 60 {
                relationships.romanticPartners[index].hasPrenup = true
                relationships.romanticPartners[index].bond -= 15
                result.notes.append(DomainNote(title: "Prenuptial Agreement", text: "You secured a legal agreement to keep finances separate. It protected your assets, but the conversation left a visible mark on the bond.", tags: [.finance, .relationships]))
            } else {
                relationships.romanticPartners[index].bond -= 25
                result.notes.append(DomainNote(title: "Prenup Rejected", text: "Your partner refused to sign the agreement. The suggestion created a deep rift of distrust.", tags: [.relationships]))
            }

        case .proposeMarriage:
            guard let index = relationships.romanticPartners.firstIndex(where: { !$0.isSecret }) else { return result }
            var partner = relationships.romanticPartners[index]
            if partner.stage == .engaged && partner.bond >= 75 {
                result.notes.append(DomainNote(title: "Wedding Planned", text: "They said yes! Now comes the actual event.", tags: [.relationships, .lifeEvent]))
            } else {
                partner.bond -= 10
                relationships.romanticPartners[index] = partner
                result.notes.append(DomainNote(title: "Proposal Failed", text: "The timing was off. They are not ready for that kind of permanence yet.", tags: [.relationships]))
            }

        case .planWedding:
            guard let index = relationships.romanticPartners.firstIndex(where: { !$0.isSecret }) else { return result }
            let cost = 15000 + (finance.cashOnHand / 5).clamped(to: 0...50000)
            if finance.cashOnHand >= cost {
                finance.cashOnHand -= cost
                relationships.romanticPartners[index].stage = .married
                relationships.romanticPartners[index].bond += 15
                relationships.publicReputation += 10
                relationships.socialCapital += 30
                result.notes.append(DomainNote(title: "The Wedding", text: "You hosted a celebration of your union. It was a massive financial hit, but the social lift was undeniable.", tags: [.finance, .relationships, .lifeEvent]))
            } else {
                result.notes.append(DomainNote(title: "Wedding Delayed", text: "You wanted to plan the big day, but the cash floor was too thin."))
            }

        case .fileForDivorce:
            guard let index = relationships.romanticPartners.firstIndex(where: { !$0.isSecret && $0.stage == .married }) else { return result }
            let partner = relationships.romanticPartners[index]
            
            if !partner.hasPrenup {
                // Asset Splitting logic
                let halfCash = finance.cashOnHand / 2
                finance.cashOnHand -= halfCash
                
                if assets.ownsHome {
                    let homeEquity = assets.primaryResidence?.equity ?? 0
                    let buyoutCost = homeEquity / 2
                    if finance.cashOnHand >= buyoutCost {
                        finance.cashOnHand -= buyoutCost
                        result.notes.append(DomainNote(title: "Divorce: Buyout", text: "You paid out half the home's equity to keep the property.", tags: [.finance, .housing]))
                    } else {
                        // Force sale
                        let homeNotes = HomeOwnershipSystem().sellPrimaryHome(home: assets.primaryResidence!, finance: &finance, assets: &assets, housing: &state.housing, distressSale: true)
                        result.notes.append(contentsOf: homeNotes)
                        finance.cashOnHand /= 2 // Split the recovered cash too
                        result.notes.append(DomainNote(title: "Divorce: Forced Sale", text: "You could not afford the buyout, forcing a sale of the home and a split of the remains.", tags: [.finance, .housing]))
                    }
                }
            }
            
            if state.family.childCount > 0 {
                result.financeEffects = FinanceEffects(dependentCostDelta: 5000) // Child support
                result.notes.append(DomainNote(title: "Child Support", text: "The divorce added a permanent child support obligation to your annual costs.", tags: [.finance]))
            }
            
            relationships.romanticPartners.remove(at: index)
            relationships.publicReputation -= 15
            result.notes.append(DomainNote(title: "Divorce Finalized", text: "The marriage is over. You are navigating the emotional and financial remains.", tags: [.relationships, .finance, .lifeEvent]))

        case .moveInTogether:
            guard let index = relationships.romanticPartners.firstIndex(where: { !$0.isSecret }) else { return result }
            var partner = relationships.romanticPartners[index]
            if player.age >= 20, partner.bond >= 74, partner.commitmentAlignment >= 62 {
                partner.isCohabiting = true
                partner.bond = (partner.bond + 3).clamped(to: 0...100)
                relationships.romanticPartners[index] = partner
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
                let existing = (relationships.friends.map(\.name) + relationships.romanticPartners.map(\.name))
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
            if relationships.primaryPartner == nil, player.age >= 15 {
                let existing = (relationships.friends.map(\.name) + relationships.romanticPartners.map(\.name))
                let name = nextName(from: partnerNames, avoiding: existing)
                relationships.romanticPartners.append(Relationship(name: name, type: .romantic, bond: 54, stage: .dating, isCohabiting: false, commitmentAlignment: 52))
            } else if let index = relationships.romanticPartners.firstIndex(where: { !$0.isSecret }) {
                relationships.romanticPartners[index].bond = (relationships.romanticPartners[index].bond + 4).clamped(to: 0...100)
                relationships.romanticPartners[index].commitmentAlignment = (relationships.romanticPartners[index].commitmentAlignment + 3).clamped(to: 0...100)
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
            if let index = relationships.romanticPartners.firstIndex(where: { !$0.isSecret }) {
                let partner = relationships.romanticPartners[index]
                relationships.romanticPartners[index].bond = (partner.bond - 5).clamped(to: 0...100)
                relationships.romanticPartners[index].commitmentAlignment = (partner.commitmentAlignment - 4).clamped(to: 0...100)
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
            if let index = relationships.romanticPartners.firstIndex(where: { !$0.isSecret && $0.status == .strained }) {
                relationships.romanticPartners[index].bond = (relationships.romanticPartners[index].bond + 9).clamped(to: 0...100)
                relationships.romanticPartners[index].commitmentAlignment = (relationships.romanticPartners[index].commitmentAlignment + 6).clamped(to: 0...100)
                relationships.romanticPartners[index].status = .active
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
        // D2: Relationships depth statics (per-friend, rivalry, rep split)
        case .deepenSpecificBond:
            if !relationships.friends.isEmpty {
                let idx = 0
                relationships.friends[idx].bond = (relationships.friends[idx].bond + 8).clamped(to: 0...100)
                var text = "You poured real time into one person. That friendship now carries more weight than the rest combined."
                if StaticInstantActionFlavor.dossierSocial(state) {
                    text = "Your social wiring from 14 made the conversation land deeper than usual."
                }
                StaticInstantActionFlavor.publishPulse(&state, domain: "relationships", strength: 16)
                result.notes.append(DomainNote(title: "Deep Bond", text: text, tags: [.relationships]))
            } else if relationships.hasPartner {
                if var partner = relationships.romanticPartner {
                    partner.bond = (partner.bond + 8).clamped(to: 0...100)
                    relationships.romanticPartner = partner
                    result.notes.append(DomainNote(title: "Deep Bond", text: "You made room for a real conversation. The relationship feels less automatic now.", tags: [.relationships]))
                }
            }
        case .fuelRivalry:
            relationships.activeRumorHeat = min(100, relationships.activeRumorHeat + 6)
            result.coreEffects = CoreStatEffects(happiness: -1)
            if state.fame.culturalFame >= 50 {
                state.fame.culturalFame = min(100, state.fame.culturalFame + 2)
            }
            if state.fame.notoriety >= 45 {
                state.fame.notoriety = min(100, state.fame.notoriety + 3)
            }
            var rivalryText = "You turned a peer into competition. The heat is motivating — and dangerous."
            rivalryText += StaticInstantActionFlavor.fameGravitySuffix(state, highFame: " The rivalry went public faster than you planned.")
            StaticInstantActionFlavor.publishPulse(&state, domain: "relationships", strength: 14)
            result.notes.append(DomainNote(title: "Rivalry Fueled", text: rivalryText, tags: [.relationships, .risk]))
        case .splitReputation:
            relationships.publicReputation = (relationships.publicReputation + 5).clamped(to: 0...100)
            relationships.privateReputation = max(0, relationships.privateReputation - 4)
            var splitText = "Public you is polished. Private you paid a small price in authenticity."
            if state.fame.culturalFame >= 55 {
                splitText = "The split got easier because the public version of you already had practice performing."
            }
            StaticInstantActionFlavor.publishPulse(&state, domain: "relationships", strength: 15)
            result.notes.append(DomainNote(title: "Rep Split", text: splitText, tags: [.relationships, .identity]))
        case .setBoundary:
            relationships.activeRumorHeat = max(0, relationships.activeRumorHeat - 5)
            resolveTension(in: &relationships, matching: [.friend, .partner, .future, .household], relief: 12)
            result.coreEffects = CoreStatEffects(happiness: 2)
            let boundaryText = StaticInstantActionFlavor.isGrounded(state)
                ? "You said no and the air actually cleared. That rarely happens on the first try."
                : (StaticInstantActionFlavor.isResilient(state)
                    ? "You held the line. Relief came, but some of the tension stayed under the surface."
                    : "You drew a line someone needed to see. Not everyone liked it, but the pressure eased.")
            result.notes.append(DomainNote(title: "Boundary Set", text: boundaryText, tags: [.relationships, .health]))
            StaticInstantActionFlavor.publishPulse(&state, domain: "relationships", strength: 17)
        case .joinActivity:
            if !relationships.friends.isEmpty {
                relationships.friends[0].bond = (relationships.friends[0].bond + 5).clamped(to: 0...100)
            }
            relationships.publicReputation = (relationships.publicReputation + 3).clamped(to: 0...100)
            result.notes.append(DomainNote(title: "Joined In", text: "You stepped into something bigger than your couch. Belonging showed up fast.", tags: [.relationships, .social]))
        case .realConversation:
            state.healthProfile.mentalWellness = (state.healthProfile.mentalWellness + 5).clamped(to: 0...100)
            if relationships.hasPartner, var partner = relationships.romanticPartner {
                partner.bond = (partner.bond + 7).clamped(to: 0...100)
                relationships.romanticPartner = partner
            } else if !relationships.friends.isEmpty {
                relationships.friends[0].bond = (relationships.friends[0].bond + 6).clamped(to: 0...100)
            }
            for index in state.family.children.indices where state.family.children[index].livesAtHome || state.family.children[index].age <= 22 {
                state.family.children[index].bondWithPlayer = (state.family.children[index].bondWithPlayer + 4).clamped(to: 5...95)
                if state.family.children[index].developmentNotes.count < 5 {
                    state.family.children[index].developmentNotes.append("Parent showed up without the performance mask.")
                }
            }
            let convoText = StaticInstantActionFlavor.isGrounded(state)
                ? "You had the conversation without armor. It was warmer than you expected."
                : "You skipped the script and asked what was actually true."
            result.notes.append(DomainNote(title: "Real Talk", text: convoText, tags: [.relationships, .family, .health]))
            StaticInstantActionFlavor.publishPulse(&state, domain: "relationships", strength: 18)
        case .networkWithoutMask:
            relationships.publicReputation = (relationships.publicReputation + 5).clamped(to: 0...100)
            state.fame.culturalFame = min(100, state.fame.culturalFame + 3)
            if state.fame.notoriety >= 45 {
                state.fame.notoriety = min(100, state.fame.notoriety + 2)
                result.notes.append(DomainNote(title: "Unmasked Network", text: "Honesty landed with the right room — but the wrong headline almost wrote itself.", tags: [.relationships, .social, .risk]))
            } else {
                result.notes.append(DomainNote(title: "Unmasked Network", text: "You connected without the act. People remembered the version that felt real.", tags: [.relationships, .social, .career]))
            }
            StaticInstantActionFlavor.publishPulse(&state, domain: "relationships", strength: 16)
        case .checkInOnChild:
            guard !state.family.children.isEmpty else {
                result.notes.append(DomainNote(title: "Check In", text: "No kids in the picture yet — but you still took a minute to think about who you'd show up for.", tags: [.relationships]))
                break
            }
            for index in state.family.children.indices {
                let gain = state.family.children[index].temperament == .sensitive ? 7 : 5
                state.family.children[index].bondWithPlayer = (state.family.children[index].bondWithPlayer + gain).clamped(to: 5...95)
                if state.family.children[index].developmentNotes.count < 5 {
                    state.family.children[index].developmentNotes.append("You asked the real questions this year.")
                }
            }
            state.healthProfile.mentalWellness = (state.healthProfile.mentalWellness + 2).clamped(to: 0...100)
            result.notes.append(DomainNote(title: "Kids Check-In", text: "You asked how they actually were and stayed for the answer.", tags: [.family, .relationships, .health]))
            StaticInstantActionFlavor.publishPulse(&state, domain: "relationships", strength: 16)

        default:
            break
        }
        
        state.player = player
        state.relationships = relationships
        state.finance = finance
        state.assets = assets

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
        guard let index = relationships.romanticPartners.firstIndex(where: { !$0.isSecret }) else { return }
        var partner = relationships.romanticPartners[index]
        partner.bond = (partner.bond + delta).clamped(to: 0...100)
        partner.status = partner.bond < 45 ? .strained : .active
        relationships.romanticPartners[index] = partner
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
        guard let partner = relationships.primaryPartner else {
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
            finance: input.finance,
            worldEra: input.worldEra,
            resilience: input.player._resilience,
            parentRegularArchetype: input.parentRegularArchetype,
            parentCareerBurnout: input.parentCareerBurnout,
            parentCrimeTier: input.parentCrimeTier,
            parentCrimeHeat: input.parentCrimeHeat,
            parentInCustody: input.parentInCustody,
            parentCustodyFacility: input.parentCustodyFacility
        )
    }

    func applyAction(_ choiceID: ActionChoiceID, state: inout GameState) -> DomainYearResult {
        var result = DomainYearResult()

        switch choiceID {
        case .tryForBaby:
            state.family.pregnancyIntent = .trying
            result.notes.append(DomainNote(
                title: "Family Planning",
                text: "You and your partner stopped leaving pregnancy to chance and started trying on purpose.",
                tags: [.relationships, .lifeEvent]
            ))
        case .avoidPregnancy:
            state.family.pregnancyIntent = .avoid
            state.relationships.futureAlignment.familyReadiness = max(
                0,
                state.relationships.futureAlignment.familyReadiness - 3
            )
            result.notes.append(DomainNote(
                title: "Family Planning",
                text: "You made avoiding pregnancy a clear priority this year.",
                tags: [.relationships]
            ))
        case .letChanceDecide:
            state.family.pregnancyIntent = .chance
            result.notes.append(DomainNote(
                title: "Family Planning",
                text: "You left family planning unresolved and let the year carry its own risk.",
                tags: [.relationships]
            ))
        case .spendTimeWithKids:
            guard state.family.children.contains(where: \.livesAtHome) else { return result }
            for index in state.family.children.indices where state.family.children[index].livesAtHome {
                var gain = Int.random(in: 4...8)
                if state.family.children[index].temperament == .sensitive {
                    gain += 2
                }
                state.family.children[index].bondWithPlayer =
                    (state.family.children[index].bondWithPlayer + gain).clamped(to: 5...95)
            }
            result.healthEffects = HealthEffects(mental: -2)
            result.notes.append(DomainNote(
                title: "Parenting",
                text: "You gave them hours that actually belonged to them. The house felt warmer, and you felt the cost of being present.",
                tags: [.family, .relationships]
            ))
        case .enforceRoutine:
            guard state.family.children.contains(where: \.livesAtHome) else { return result }
            for index in state.family.children.indices where state.family.children[index].livesAtHome {
                let child = state.family.children[index]
                let bondDelta: Int
                let sensitivityDelta: Int
                if child.temperament == .spirited || child.temperament == .intense {
                    bondDelta = 3
                    sensitivityDelta = -4
                } else if child.temperament == .independent {
                    bondDelta = -4
                    sensitivityDelta = -2
                } else {
                    bondDelta = -1
                    sensitivityDelta = -2
                }
                state.family.children[index].bondWithPlayer =
                    (child.bondWithPlayer + bondDelta).clamped(to: 5...95)
                state.family.children[index].emotionalSensitivity =
                    (child.emotionalSensitivity + sensitivityDelta).clamped(to: 10...90)
            }
            result.healthEffects = HealthEffects(mental: -1, stressManagement: 2)
            result.notes.append(DomainNote(
                title: "Parenting",
                text: "You held the line on structure. It landed as safety for some of them and a fight for others.",
                tags: [.family, .relationships]
            ))
        case .encourageIndependence:
            guard state.family.children.contains(where: \.livesAtHome) else { return result }
            for index in state.family.children.indices where state.family.children[index].livesAtHome {
                let child = state.family.children[index]
                let bondDelta = child.temperament == .independent || child.temperament == .spirited ? 3 :
                    (child.temperament == .sensitive ? -2 : 1)
                let curiosityDelta = child.temperament == .independent || child.temperament == .spirited ? 6 : 4
                state.family.children[index].bondWithPlayer =
                    (child.bondWithPlayer + bondDelta).clamped(to: 5...95)
                state.family.children[index].curiosity =
                    (child.curiosity + curiosityDelta).clamped(to: 15...90)
            }
            result.notes.append(DomainNote(
                title: "Parenting",
                text: "You stepped back on purpose. They gained room to become more themselves.",
                tags: [.family, .relationships]
            ))
        case .checkInOnChild:
            guard state.family.children.contains(where: \.livesAtHome) else { return result }
            for index in state.family.children.indices where state.family.children[index].livesAtHome {
                let temperament = state.family.children[index].temperament
                let gain = temperament == .sensitive || temperament == .intense ? 8 : 5
                state.family.children[index].bondWithPlayer =
                    (state.family.children[index].bondWithPlayer + gain).clamped(to: 5...95)
            }
            result.healthEffects = HealthEffects(mental: -3)
            result.notes.append(DomainNote(
                title: "Parenting",
                text: "You asked how they were doing and stayed for the real answer.",
                tags: [.family, .relationships, .health]
            ))
        case .familyMeal:
            guard !state.family.children.isEmpty else { return result }
            for index in state.family.children.indices {
                state.family.children[index].bondWithPlayer =
                    (state.family.children[index].bondWithPlayer + 3).clamped(to: 5...95)
            }
            result.healthEffects = HealthEffects(mental: 3)
            result.notes.append(DomainNote(
                title: "Family Meal",
                text: "The table was loud in the good way. The year remembered it belonged to all of you.",
                tags: [.family, .relationships]
            ))
        case .storyTime:
            guard !state.family.children.isEmpty else { return result }
            for index in state.family.children.indices {
                let socialBonus = (state.childhoodDossier?.aptitudes.social ?? 0) >= 55 ? 2 : 0
                state.family.children[index].bondWithPlayer =
                    (state.family.children[index].bondWithPlayer + 4 + socialBonus).clamped(to: 5...95)
                state.family.children[index].developmentNotes.append("Heard stories about where you came from.")
            }
            result.notes.append(DomainNote(
                title: "Story Time",
                text: "You told them something true about before they were here. The thread got longer.",
                tags: [.family, .identity]
            ))
        default:
            break
        }

        return result
    }

    func advanceYear(
        player: Player,
        relationships: RelationshipState,
        family: inout FamilyState,
        health: HealthState,
        finance: FinanceState,
        worldEra: WorldEra = .stable,
        resilience: LifeResilience = .resilient,
        parentRegularArchetype: CareerArchetype? = nil,
        parentCareerBurnout: Int = 0,
        parentCrimeTier: CrimeTier? = nil,
        parentCrimeHeat: Int = 0,
        parentInCustody: Bool = false,
        parentCustodyFacility: CustodyFacility? = nil
    ) -> DomainYearResult {
        var result = DomainYearResult()

        // Econ3: Pass era + resilience so children feel the macro economy + parent's life path differently
        let parentStress = max(0, finance.financialStress + (health.mentalWellness < 40 ? 15 : 0))
        ageChildren(
            family: &family,
            result: &result,
            worldEra: worldEra,
            resilience: resilience,
            parentFinancialStress: parentStress,
            parentIsSpecialCareer: finance.annualTotalExpenses > 45000,
            parentRegularArchetype: parentRegularArchetype,
            parentCareerBurnout: parentCareerBurnout,
            parentCrimeTier: parentCrimeTier,
            parentCrimeHeat: parentCrimeHeat,
            parentInCustody: parentInCustody,
            parentCustodyFacility: parentCustodyFacility
        )
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
                let newborn = makeNewborn(
                    name: childName,
                    pregnancy: pregnancy,
                    player: player,
                    relationships: relationships,
                    health: health,
                    finance: finance
                )
                family.children.append(newborn)
                family.pregnancy = nil
                family.postpartumYearsRemaining = 2
                result.financeEffects = FinanceEffects(cashDelta: -1_400, livingCostDelta: nil, educationCostDelta: nil, dependentCostDelta: 2_400, discretionaryCostDelta: nil, financialStressDelta: 5, setRegionPolicyID: nil)
                result.healthEffects = HealthEffects(physical: -5, mental: pregnancy.isPlanned ? -2 : -4, exercise: nil, nutrition: nil, stressManagement: -4, addCondition: nil, removeCondition: nil, hasPrimaryCare: nil)
                result.relationshipEffects = RelationshipEffects(partnerChange: pregnancy.isPlanned ? 3 : -2, commitmentAlignmentChange: pregnancy.isPlanned ? 2 : -3)

                let arrivalFlavor = birthArrivalFlavor(for: newborn, wasPlanned: pregnancy.isPlanned)
                result.notes.append(DomainNote(title: "Birth", text: arrivalFlavor, tags: [.lifeEvent, .finance, .health, .relationships]))
            }
            return result
        }

        guard let partner = relationships.primaryPartner,
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

    private func ageChildren(
        family: inout FamilyState,
        result: inout DomainYearResult,
        worldEra: WorldEra = .stable,
        resilience: LifeResilience = .resilient,
        parentFinancialStress: Int = 0,
        parentIsSpecialCareer: Bool = false,
        parentRegularArchetype: CareerArchetype? = nil,
        parentCareerBurnout: Int = 0,
        parentCrimeTier: CrimeTier? = nil,
        parentCrimeHeat: Int = 0,
        parentInCustody: Bool = false,
        parentCustodyFacility: CustodyFacility? = nil
    ) {
        guard !family.children.isEmpty else { return }

        let isBadEconomy = (worldEra == .recession || worldEra == .highInflation)
        let isBoomEconomy = (worldEra == .bullMarket || worldEra == .techBoom)
        let isCrisis = (worldEra == .wartime || worldEra == .pandemic)
        let isGrounded = (resilience == .grounded)

        for index in family.children.indices {
            var child = family.children[index]
            child.age += 1

            // Econ3: Economic era + resilience dramatically shape child development
            var householdStress = max(0, (result.financeEffects?.financialStressDelta ?? 0) + 12 + parentFinancialStress / 3)
            if isBadEconomy {
                householdStress = Int(Double(householdStress) * (isGrounded ? 1.45 : 1.15))
            } else if isBoomEconomy {
                householdStress = Int(Double(householdStress) * 0.75)
            }
            if isCrisis {
                householdStress += (isGrounded ? 18 : 10)
            }
            if parentIsSpecialCareer && isBadEconomy {
                householdStress += (isGrounded ? 22 : 12) // high-variance parent careers amplify economic pain for kids in grounded mode
            }

            let stability = 50 - householdStress / 2

            // Bond drifts with stability + random life texture. Sensitive/intense kids swing more.
            // Econ3: Grounded mode in bad economies creates much harsher bond damage
            let baseBondSwing = (stability - 50) / 9
            let econBondPenalty = isBadEconomy ? (isGrounded ? -6 : -2) : (isBoomEconomy ? 2 : 0)
            let bondSwing = baseBondSwing + econBondPenalty
            let sensitivityMultiplier: Double = (child.temperament == .sensitive || child.temperament == .intense) ? 1.35 : 0.85
            let newBond = (Double(child.bondWithPlayer) + Double(bondSwing) * sensitivityMultiplier + Double.random(in: -3.5...3.5)).clamped(to: 5...95)
            child.bondWithPlayer = Int(newBond)

            // Curiosity grows with lower stress and higher existing curiosity (spirited/independent bias).
            let curiosityDrift = Int.random(in: -2...4) + (stability > 55 ? 2 : -1)
            child.curiosity = (child.curiosity + curiosityDrift).clamped(to: 15...90)

            // Sensitivity slowly moderates toward the mean unless the year was rough.
            // Econ3: Bad economies + grounded mode make sensitive kids carry more lasting emotional load
            let sensDrift = (stability > 60 ? -1 : 1) + Int.random(in: -2...2)
            let econSensExtra = (isBadEconomy && isGrounded) ? 2 : 0
            child.emotionalSensitivity = (child.emotionalSensitivity + sensDrift + econSensExtra).clamped(to: 10...95)

            // Support load slowly eases as kids get older / more independent, but spikes with household stress.
            let ageRelief = child.age >= 6 ? 2 : 1
            child.supportLoad = (child.supportLoad - ageRelief + max(0, householdStress - 40) / 7).clamped(to: 25...85)

            // Econ3: "Raised in recession / boom / crisis" development notes + special career parent flavor
            if Int.random(in: 0...100) < 32 || (child.age == 5 || child.age == 13 || child.age == 18) {
                var note = developmentNote(for: child, stability: stability)

                // Major economic origin story notes (permanent narrative texture)
                if isBadEconomy && child.age <= 6 && !child.developmentNotes.contains(where: { $0.contains("recession") || $0.contains("hard years") }) {
                    let econNote = isGrounded ?
                        "\(child.name) was born into hard years. The house felt tighter, the adults quieter." :
                        "\(child.name) grew up while the world was tight with money. They learned early what 'making do' meant."
                    note = econNote
                } else if isBoomEconomy && child.age <= 8 && !child.developmentNotes.contains(where: { $0.contains("boom") || $0.contains("plenty") }) {
                    note = "\(child.name) was a child of the good years. The house felt lighter, opportunities felt normal."
                } else if isCrisis && child.age <= 10 {
                    note = "\(child.name) was a child during the national crisis. The news was always on. The adults were always worried or angry."
                }

                // Special career parent flavor during economic stress (the "my parent was fighting the economy" stories)
                if parentIsSpecialCareer && isBadEconomy && Int.random(in: 0...100) < 35 {
                    let parentNote = "My parent was fighting to keep everything together that year."
                    if !child.developmentNotes.contains(parentNote) {
                        child.developmentNotes.append(parentNote)
                    }
                }

                if let arch = parentRegularArchetype, child.age >= 12, Int.random(in: 0...100) < 24 {
                    let parentNote = regularCareerParentNote(
                        archetype: arch,
                        burnout: parentCareerBurnout,
                        childName: child.name
                    )
                    if !child.developmentNotes.contains(parentNote) {
                        child.developmentNotes.append(parentNote)
                    }
                }

                if let crimeTier = parentCrimeTier, child.age >= 10, Int.random(in: 0...100) < 26 {
                    let crimeNote = crimeParentNote(tier: crimeTier, heat: parentCrimeHeat, childName: child.name, grounded: isGrounded)
                    if !child.developmentNotes.contains(crimeNote) {
                        child.developmentNotes.append(crimeNote)
                    }
                }

                if parentInCustody, child.age >= 6, Int.random(in: 0...100) < 30 {
                    let custodyNote = custodyParentNote(
                        facility: parentCustodyFacility ?? .statePrison,
                        childName: child.name,
                        grounded: isGrounded
                    )
                    if !child.developmentNotes.contains(custodyNote) {
                        child.developmentNotes.append(custodyNote)
                    }
                }

                // CE3 criminal family spillover temporarily disabled for build stability (references top-level GameState not available in this helper scope).
                // The feature can be properly threaded via additional parameters if needed.

                if !note.isEmpty {
                    child.developmentNotes.append(note)
                    if child.developmentNotes.count > 5 { child.developmentNotes.removeFirst() }
                }
            }

            family.children[index] = child

            // Emancipation at 19 + Phase 2.3 adult outcome seeding
            if child.age >= 19 && child.livesAtHome {
                family.children[index].livesAtHome = false
                family.children[index].leftHomeAtAge = child.age

                // Seed long-term adult profile based on childhood investment (bond + temperament + some history)
                let profile = seedAdultProfile(from: child)
                family.children[index].adultProfile = profile

                let leavingNote = adultLeavingNote(for: child, profile: profile)
                result.notes.append(DomainNote(title: "Family", text: leavingNote, tags: [.lifeEvent, .relationships]))
            }

            // Phase 2.3: Adult child milestones and texture (for those who have left home)
            if !child.livesAtHome, let profile = child.adultProfile, child.age >= 22 {
                if let updated = advanceAdultMilestone(child: child, currentProfile: profile, resilience: resilience) {
                    family.children[index].adultProfile = updated.profile
                    if let noteText = updated.note {
                        result.notes.append(DomainNote(title: "Family", text: noteText, tags: [.lifeEvent, .relationships]))
                    }
                    // Small late-game emotional ripples
                    if child.age >= 40 {
                        let ripple = adultRippleMental(for: updated.profile.outcome, relQuality: updated.profile.relationshipQuality)
                        if ripple != 0 {
                            let existing = result.healthEffects
                            result.healthEffects = HealthEffects(
                                physical: existing?.physical,
                                mental: (existing?.mental ?? 0) + ripple,
                                exercise: existing?.exercise,
                                nutrition: existing?.nutrition,
                                stressManagement: existing?.stressManagement,
                                addCondition: existing?.addCondition,
                                removeCondition: existing?.removeCondition,
                                hasPrimaryCare: existing?.hasPrimaryCare
                            )
                        }
                    }
                }
            }
        }

        // Small player-facing ripples from having children this year (the "visible development impact").
        // These are intentionally modest so they feel like texture, not punishment/reward.
        let dependentCount = family.children.filter(\.livesAtHome).count
        if dependentCount > 0 {
            let avgBond = family.children.filter(\.livesAtHome).map(\.bondWithPlayer).reduce(0, +) / max(1, dependentCount)
            let avgSensitivity = family.children.filter(\.livesAtHome).map(\.emotionalSensitivity).reduce(0, +) / max(1, dependentCount)

            // High bond in a chaotic house can still be emotionally taxing; low bond hurts more.
            var mentalDelta = 0
            if avgBond >= 70 { mentalDelta += 1 }
            if avgBond <= 40 { mentalDelta -= 2 }
            if avgSensitivity >= 68 && dependentCount >= 2 { mentalDelta -= 1 }

            if mentalDelta != 0 {
                let existing = result.healthEffects
                result.healthEffects = HealthEffects(
                    physical: existing?.physical,
                    mental: (existing?.mental ?? 0) + mentalDelta,
                    exercise: existing?.exercise,
                    nutrition: existing?.nutrition,
                    stressManagement: existing?.stressManagement,
                    addCondition: existing?.addCondition,
                    removeCondition: existing?.removeCondition,
                    hasPrimaryCare: existing?.hasPrimaryCare
                )
            }

            // Very high support load or many dependents adds quiet financial pressure.
            let highLoadCount = family.children.filter { $0.livesAtHome && $0.supportLoad >= 68 }.count
            if highLoadCount >= 2 || dependentCount >= 3 {
                // Use existing pattern: create a small effect and let the caller / later merge handle it.
                // For now we directly adjust the stress delta if one exists, otherwise set a modest one.
                if var fin = result.financeEffects {
                    fin.financialStressDelta = (fin.financialStressDelta ?? 0) + 2
                    result.financeEffects = fin
                } else {
                    result.financeEffects = FinanceEffects(financialStressDelta: 2)
                }
            }
        }
    }

    private func custodyParentNote(facility: CustodyFacility, childName: String, grounded: Bool) -> String {
        switch facility {
        case .countyJail:
            return grounded
                ? "\(childName) learned that visits were short and goodbyes were harder than the drive home."
                : "\(childName) watched the county jail visits eat weekends before homework did."
        case .statePrison:
            return grounded
                ? "\(childName) grew up counting years between phone calls and birthdays."
                : "\(childName) understood early that one parent was somewhere the family could not follow."
        case .federalPen:
            return grounded
                ? "\(childName) learned not to ask how far away the facility was — the answer always hurt."
                : "\(childName) carried the quiet shame of a parent locked far from home for a long bid."
        }
    }

    private func crimeParentNote(tier: CrimeTier, heat: Int, childName: String, grounded: Bool) -> String {
        switch tier {
        case .street:
            return grounded
                ? "\(childName) learned early that danger lived in the same rooms as dinner."
                : "\(childName) saw how fast the street could turn on the people in it."
        case .organization:
            return heat >= 60
                ? "\(childName) heard phones ring at odd hours and knew the crew was in trouble."
                : "\(childName) watched you run something bigger than yourself — and felt the weight of it."
        case .enterprise:
            return grounded
                ? "\(childName) grew up in the shadow of a name people whispered, not said aloud."
                : "\(childName) understood that your power kept the house comfortable and the world nervous."
        }
    }

    private func regularCareerParentNote(archetype: CareerArchetype, burnout: Int, childName: String) -> String {
        let drained = burnout >= 65
        switch archetype {
        case .careLabor:
            return drained
                ? "\(childName) watched you come home drained from the hospital every night."
                : "\(childName) saw how much of yourself you gave at work — and how rarely you got it back."
        case .corporateClimber:
            return drained
                ? "\(childName) saw you grind the ladder and wondered if it was worth it."
                : "\(childName) noticed the office followed you home in your voice and your timing."
        case .skilledTrades:
            return "\(childName) noticed how your hands showed the work before you ever said a word."
        case .salesNetworker:
            return "\(childName) heard you on late calls — wins and rejections in the same tired tone."
        case .gigFreelancer:
            return "\(childName) learned early that your schedule belonged to everyone else's urgency."
        case .techEngineer:
            return "\(childName) saw the glow of a screen at odd hours and knew the work wasn't finished."
        case .creativeProfessional:
            return "\(childName) watched you chase the next project like it might finally be the one that sticks."
        case .publicService:
            return "\(childName) heard you talk about the system like it was personal — because for you, it was."
        }
    }

    private func developmentNote(for child: ChildRecord, stability: Int) -> String {
        let name = child.name
        let age = child.age
        switch child.temperament {
        case .easygoing:
            if age <= 4 { return stability > 55 ? "\(name) was an easy little kid this year." : "\(name) took the chaos in stride." }
            return stability > 55 ? "\(name) rolled with the year without much drama." : "\(name) stayed steady even when things felt unsettled."
        case .spirited:
            if age <= 6 { return "\(name) turned every day into an adventure (and sometimes a negotiation)." }
            return stability > 60 ? "\(name) brought a lot of life and noise into the house this year." : "\(name) had some big feelings; the house felt louder."
        case .sensitive:
            if stability < 45 { return "\(name) seemed to absorb every tense moment this year." }
            if age >= 10 { return "\(name) was carrying more of the emotional weather than usual." }
            return "\(name) was especially tuned in to how everyone else was doing."
        case .independent:
            if age >= 8 { return "\(name) wanted more space and handled more on their own." }
            return "\(name) was quietly figuring things out in their own corner."
        case .intense:
            if stability > 55 { return "\(name) threw themselves into everything with full force." }
            return "\(name) had a hard year — the highs were high and the lows were heavy."
        }
    }

    // MARK: - Phase 2.3 Adult Child Long-term Outcomes

    private func seedAdultProfile(from child: ChildRecord) -> AdultChildProfile {
        let finalBond = child.bondWithPlayer
        let temp = child.temperament

        var outcome: AdultChildOutcome
        let relQuality = finalBond

        // Temperament + investment bias the long-term path
        let investmentScore = finalBond + (child.developmentNotes.count * 3)

        switch investmentScore {
        case 95...: outcome = .thriving
        case 70..<95: outcome = (temp == .intense || temp == .sensitive) ? .stable : .thriving
        case 50..<70: outcome = .stable
        case 35..<50: outcome = (temp == .easygoing) ? .stable : .struggling
        default:      outcome = .distant
        }

        // Independent kids often do "fine but distant"
        if temp == .independent && outcome == .thriving { outcome = .stable }
        if temp == .intense && outcome == .distant { outcome = .struggling }

        var lifeVibe: String
        switch outcome {
        case .thriving:
            lifeVibe = ["solid career", "doing really well", "building something meaningful"].randomElement()!
        case .stable:
            lifeVibe = ["steady job", "making it work", "quietly getting by"].randomElement()!
        case .struggling:
            lifeVibe = ["hit some rough patches", "still figuring it out", "carrying more than their share"].randomElement()!
        case .distant:
            lifeVibe = ["lives far away now", "keeps to themselves", "the calls got shorter over the years"].randomElement()!
        }

        if temp == .sensitive { lifeVibe += ", sensitive like always" }
        if temp == .spirited { lifeVibe += ", still full of energy" }

        // Econ3: Intergenerational economic origin stories + starting modifiers
        // Children carry the economic weather of their childhood into adulthood as permanent texture and slight starting bias.
        var keyStories = ["Left home at \(child.age)."]
        let econNotes = child.developmentNotes.filter { $0.contains("recession") || $0.contains("hard years") || $0.contains("boom") || $0.contains("crisis") || $0.contains("good years") || $0.contains("national crisis") }
        if !econNotes.isEmpty {
            keyStories.append(econNotes.first!)
            // Small but real starting bias in adult lifeVibe based on childhood economy
            if econNotes.contains(where: { $0.contains("recession") || $0.contains("hard years") }) {
                if outcome == .thriving { lifeVibe += " — the hard years made them tougher and more resourceful" }
                else if outcome == .struggling { lifeVibe += " — some of the old tightness never fully left" }
            } else if econNotes.contains(where: { $0.contains("boom") || $0.contains("good years") }) {
                if outcome == .thriving { lifeVibe += " — grew up expecting the world to be generous" }
                else { lifeVibe += " — the good times set a high bar that later reality had to meet" }
            }
        }

        return AdultChildProfile(
            outcome: outcome,
            relationshipQuality: relQuality,
            lifeVibe: lifeVibe,
            keyStories: keyStories
        )
    }

    private func adultLeavingNote(for child: ChildRecord, profile: AdultChildProfile) -> String {
        let name = child.name
        let temp = child.temperament.shortDescription
        let outcomeWord = profile.outcome == .thriving ? "with real promise" : profile.outcome == .struggling ? "with some visible weight" : "ready to find their own shape"

        // P3 D4: player focus history flavors the leaving (stance residue, life shape echo in child's view of "normal")
        let driftEcho = child.developmentNotes.contains(where: { $0.lowercased().contains("drift") || $0.lowercased().contains("loose") }) ? " (They swore this would look different than what they grew up watching.)" : ""

        // CT3-4: Diamond parent flavor — empire over family or empire as family
        var diamondEcho = ""
        if child.developmentNotes.contains(where: { $0.lowercased().contains("diamond") || $0.lowercased().contains("empire") || $0.lowercased().contains("studio") || $0.lowercased().contains("program") }) {
            diamondEcho = " The distance they chose looks a lot like the one you modeled when the empire was everything."
        }
        return "\(name) (\(temp)) moved out \(outcomeWord). The house felt different that night.\(driftEcho)\(diamondEcho)"
    }

    private func advanceAdultMilestone(child: ChildRecord, currentProfile: AdultChildProfile, resilience: LifeResilience) -> (profile: AdultChildProfile, note: String?)? {
        // Only trigger occasionally for texture
        guard Int.random(in: 0...100) < 22 else { return nil }

        var profile = currentProfile
        let name = child.name
        var note: String? = nil

        let age = child.age
        let temp = child.temperament

        // Milestone windows
        if age == 23 || (age % 5 == 0 && age > 25 && age < 55) {
            switch profile.outcome {
            case .thriving:
                profile.relationshipQuality = (profile.relationshipQuality + 4).clamped(to: 20...95)
                profile.keyStories.append(age == 23 ? "\(name) landed a good job and sounded proud on the phone." : "\(name) is doing well — called with real news.")
                note = "\(name) is thriving. The updates lately have had a warmth to them."
            case .stable:
                profile.keyStories.append("\(name) is hanging in there, steady as ever.")
                if temp == .sensitive { profile.relationshipQuality = (profile.relationshipQuality + 2).clamped(to: 10...90) }
            case .struggling:
                profile.relationshipQuality = (profile.relationshipQuality - 3).clamped(to: 5...80)
                profile.keyStories.append(age == 30 ? "\(name) hit a rough patch and reached out for the first time in a while." : "\(name) is going through it again.")
                note = "You got a call from \(name). It was heavier than you hoped."
            case .distant:
                if Int.random(in: 0...10) < 3 {
                    profile.relationshipQuality = (profile.relationshipQuality + 5).clamped(to: 5...70)
                    profile.keyStories.append("\(name) called out of the blue. It was brief, but it happened.")
                    note = "\(name) reached out. The silence had been long."
                }
            }
        }

        // Occasional major life events (marriage, own kids, big setback)
        if age == 28 || age == 35 || (age % 7 == 0 && age > 30) {
            if profile.outcome != .distant && Int.random(in: 0...100) < 35 {
                if profile.outcome == .thriving || (profile.outcome == .stable && temp != .sensitive) {
                    profile.keyStories.append("\(name) has a kid of their own now.")
                    profile.relationshipQuality = (profile.relationshipQuality + 6).clamped(to: 20...95)
                    // Phase 5: Long-term resonance of the parent's Life Feel choice
                    var circleNote = "\(name) became a parent. The circle turned in a way that felt both obvious and impossible."
                    // Note: resilience context from caller; defaulting for scope in this slice
                    circleNote += " The parent's Life Feel still echoes here."
                    note = circleNote
                } else if profile.outcome == .struggling {
                    profile.keyStories.append("\(name) is dealing with a lot — asked if you were okay too.")
                    note = "Hearing \(name) struggle made something in your chest tighten."
                }
            }
        }

        if note != nil || !profile.keyStories.isEmpty {
            if profile.keyStories.count > 5 { profile.keyStories.removeFirst() }
            return (profile, note)
        }

        return nil
    }

    private func adultRippleMental(for outcome: AdultChildOutcome, relQuality: Int) -> Int {
        var delta = 0
        switch outcome {
        case .thriving: delta += 2
        case .stable: delta += 0
        case .struggling: delta -= 2
        case .distant: delta -= 1
        }
        if relQuality < 30 { delta -= 2 }
        if relQuality > 75 { delta += 1 }
        return delta
    }

    func conceptionChance(
        player: Player,
        relationships: RelationshipState,
        family: FamilyState,
        health: HealthState,
        finance: FinanceState
    ) -> Int {
        guard let partner = relationships.primaryPartner else { return 0 }
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

    // MARK: - Phase 2 (Family 2.1): Context-aware newborn creation

    private func makeNewborn(
        name: String,
        pregnancy: PregnancyState,
        player: Player,
        relationships: RelationshipState,
        health: HealthState,
        finance: FinanceState
    ) -> ChildRecord {
        // Base personality influenced by pregnancy story + parental context.
        // This is the moment the child starts feeling like *their* kid, not a generic number.

        var temperament: ChildTemperament
        let plannedBonus = pregnancy.isPlanned ? 8 : 0
        let relationshipQuality = relationships.primaryPartner?.bond ?? 50
        let stress = finance.financialStress + (health.activeConditions.count * 8)
        let parentalAgeFactor = (player.age < 23 || player.age > 37) ? -6 : 4

        let temperamentRoll = Int.random(in: 0...100) + plannedBonus + (relationshipQuality - 55) / 3 - stress / 12 + parentalAgeFactor

        switch temperamentRoll {
        case ...35:  temperament = .intense
        case 36...48: temperament = .sensitive
        case 49...62: temperament = .spirited
        case 63...78: temperament = .independent
        default:      temperament = .easygoing
        }

        // Bond starts higher for planned / stable situations, lower for chaotic ones.
        var bond = 48 + (pregnancy.isPlanned ? 14 : -6)
        bond += (relationshipQuality - 50) / 4
        bond -= max(0, finance.financialStress - 40) / 6
        bond += (health.mentalWellness - 50) / 10
        bond = bond.clamped(to: 28...78)

        // Curiosity and sensitivity have natural variation but are nudged by context.
        var curiosity = 45 + Int.random(in: -12...18) + (plannedBonus / 2)
        curiosity = curiosity.clamped(to: 22...82)

        var sensitivity = 48 + Int.random(in: -14...14)
        if temperament == .sensitive || temperament == .intense { sensitivity += 12 }
        if temperament == .easygoing { sensitivity -= 10 }
        sensitivity = sensitivity.clamped(to: 18...85)

        var supportLoad = pregnancy.isPlanned ? 56 : 66
        supportLoad += max(0, stress - 45) / 5
        supportLoad = supportLoad.clamped(to: 45...78)

        return ChildRecord(
            name: name,
            age: 0,
            livesAtHome: true,
            otherParentName: pregnancy.otherParentName,
            supportLoad: supportLoad,
            temperament: temperament,
            bondWithPlayer: bond,
            curiosity: curiosity,
            emotionalSensitivity: sensitivity,
            developmentNotes: ["Arrived in a \(pregnancy.isPlanned ? "planned" : "surprising") moment."]
        )
    }

    private func birthArrivalFlavor(for child: ChildRecord, wasPlanned: Bool) -> String {
        let temp = child.temperament.shortDescription
        let bondWord = child.bondWithPlayer >= 68 ? "already felt like a deep attachment" : child.bondWithPlayer <= 42 ? "arrived with some distance in the room" : "landed as a complicated new gravity"
        let stressWord = child.supportLoad >= 70 ? " and the practical weight was immediate" : ""

        if wasPlanned {
            return "You welcomed \(child.name) — a \(temp) baby who \(bondWord)\(stressWord)."
        } else {
            return "\(child.name) arrived — a \(temp) baby who \(bondWord)\(stressWord). The surprise rearranged more than just the calendar."
        }
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
        case .military: workStress = 4
        case .unemployed: workStress = 2
        }

        let socialSupport = relationships.friends.count + (relationships.hasPartner ? 1 : 0)
        // Use player's mirrored resilience dampener (synced from GameState at key points).
        let effectiveDampener = player.healthDeclineDampener
        let conditionDrag = Int(Double(health.activeConditions.reduce(0) { $0 + max(1, $1.severity / 20) }) * effectiveDampener)
        let workStressDrag = Int(Double(workStress) * effectiveDampener)

        let physicalShift =
            ((health.habits.exercise - 50) / 8) +
            ((health.habits.nutrition - 50) / 8) -
            conditionDrag -
            workStressDrag
        let mentalShift =
            ((health.habits.stressManagement - 45) / 6) +
            ((player.happiness - 50) / 10) +
            socialSupport -
            workStressDrag -
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

    /// Reduce severity on active conditions; remove when fully eased.
    private func relieveActiveConditions(in health: inout HealthState, amount: Int) {
        guard !health.activeConditions.isEmpty else { return }
        health.activeConditions = health.activeConditions.compactMap { condition in
            var updated = condition
            updated.severity = max(0, updated.severity - amount)
            return updated.severity > 0 ? updated : nil
        }
    }

    func applyAction(_ choiceID: ActionChoiceID, state: inout GameState) -> DomainYearResult {
        var result = DomainYearResult()
        var player = state.player
        var health = state.healthProfile
        let grounded = StaticInstantActionFlavor.isGrounded(state)

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
            let phys = StaticInstantActionFlavor.resilienceScaled(state, grounded: 6, resilient: 4)
            health.physicalWellness = (health.physicalWellness + phys).clamped(to: 0...100)
            health.mentalWellness = (health.mentalWellness + phys - 1).clamped(to: 0...100)
            relieveActiveConditions(in: &health, amount: grounded ? 8 : 6)
            result.financeEffects = FinanceEffects(cashDelta: -150)
            let doctorText: String = {
                if grounded { return "You reached for care and it felt like claiming ground back. The future got a little less sharp." }
                if StaticInstantActionFlavor.isResilient(state) { return "You patched it and kept moving. Not elegant, but effective." }
                return health.activeConditions.isEmpty
                    ? "A light visit, real reassurance. The body feels a little less mysterious."
                    : "You got something looked at before it grew teeth. One weight eased."
            }()
            result.notes.append(DomainNote(title: "Quick Checkup", text: doctorText, tags: [.health, .finance]))
            StaticInstantActionFlavor.publishPulse(&state, domain: "health", strength: 17)
        case .recurringTherapy:
            let mental = StaticInstantActionFlavor.resilienceScaled(state, grounded: 9, resilient: 7)
            health.mentalWellness = (health.mentalWellness + mental).clamped(to: 0...100)
            health.habits.stressManagement = (health.habits.stressManagement + 5).clamped(to: 0...100)
            state.identityCoherence = (state.identityCoherence + 4).clamped(to: 0...100)
            relieveActiveConditions(in: &health, amount: 4)
            result.financeEffects = FinanceEffects(cashDelta: -120)
            var therapyText = "The regular appointment rewired something small but real."
            if StaticInstantActionFlavor.dossierSocial(state) || StaticInstantActionFlavor.dossierAnalytical(state) {
                therapyText = "Your dossier made the session land differently — you heard yourself faster."
            }
            therapyText += StaticInstantActionFlavor.fameGravitySuffix(state, highFame: " Public pressure made honesty cost more — and matter more.")
            StaticInstantActionFlavor.publishPulse(&state, domain: "health", strength: 16)
            result.notes.append(DomainNote(title: "Therapy Loop", text: therapyText, tags: [.health, .finance, .identity]))
        case .manageMeds:
            health.physicalWellness = (health.physicalWellness + 5).clamped(to: 0...100)
            health.mentalWellness = (health.mentalWellness + 4).clamped(to: 0...100)
            relieveActiveConditions(in: &health, amount: grounded ? 10 : 8)
            result.financeEffects = FinanceEffects(cashDelta: -65)
            let medsText = grounded
                ? "You kept the regimen when it would've been easier to skip. Long-term stability got a real deposit."
                : (health.activeConditions.isEmpty
                    ? "The routine clicked. Prevention beats panic."
                    : "Symptoms dialed down a notch. The pill organizer earned its keep.")
            result.notes.append(DomainNote(title: "Meds On Schedule", text: medsText, tags: [.health, .finance]))
            StaticInstantActionFlavor.publishPulse(&state, domain: "health", strength: 15)
        case .bodyConditioning:
            health.physicalWellness = (health.physicalWellness + 7).clamped(to: 0...100)
            health.mentalWellness = (health.mentalWellness + 2).clamped(to: 0...100)
            health.habits.exercise = (health.habits.exercise + 6).clamped(to: 0...100)
            if state.specialCareer.track == .athlete {
                state.specialCareer.athlete.peakPerformance = min(100, state.specialCareer.athlete.peakPerformance + 3)
            }
            result.coreEffects = CoreStatEffects(happiness: 2)
            result.careerEffects = CareerEffects(performance: 2)
            var bodyText = grounded
                ? "You pushed through the fatigue and it mattered. The body answered back."
                : "Reps, breath, sweat — the machine remembers what it's for."
            if StaticInstantActionFlavor.dossierPhysical(state) {
                bodyText = "The physical wiring from 14 made the work feel native, not forced."
            }
            result.notes.append(DomainNote(title: "Body Work", text: bodyText, tags: [.health, .career]))
            StaticInstantActionFlavor.publishPulse(&state, domain: "health", strength: 16)
        case .sleepLikeItMatters, .improveSleep:
            let mental = StaticInstantActionFlavor.resilienceScaled(state, grounded: 9, resilient: 7)
            health.mentalWellness = (health.mentalWellness + mental).clamped(to: 0...100)
            health.physicalWellness = (health.physicalWellness + 4).clamped(to: 0...100)
            health.habits.stressManagement = (health.habits.stressManagement + 6).clamped(to: 0...100)
            result.careerEffects = CareerEffects(
                burnout: -StaticInstantActionFlavor.resilienceScaled(state, grounded: 6, resilient: 4),
                schedulePressure: -4,
                relationshipSpillover: -2
            )
            result.educationEffects = EducationEffects(attendancePressure: -3)
            state.consequences.adjustPressure(domain: "health", delta: grounded ? -3 : -2)
            StaticInstantActionFlavor.publishPulse(&state, domain: "health", strength: 20)
            let sleepText = grounded
                ? "The years of actually protecting sleep are still paying off. You felt it tonight."
                : "You protected the night like strategy. Morning feels less like an ambush."
            result.notes.append(DomainNote(title: "Sleep Reset", text: sleepText, tags: [.health, .education]))
        case .coldExposureDrill:
            health.physicalWellness = (health.physicalWellness + 5).clamped(to: 0...100)
            health.mentalWellness = (health.mentalWellness + 4).clamped(to: 0...100)
            health.habits.exercise = (health.habits.exercise + 4).clamped(to: 0...100)
            health.habits.stressManagement = (health.habits.stressManagement + 3).clamped(to: 0...100)
            var drillText = "The cold hit. You stayed. Something hardening in you felt useful."
            if StaticInstantActionFlavor.dossierPhysical(state) {
                drillText = "Your body remembered how to take punishment and translate it into edge."
            }
            if LifeShapeResolver.resolveOrPragmatic(from: state) == .drivenCurrent {
                drillText += " The driven current you're riding made this feel almost automatic."
            }
            result.notes.append(DomainNote(title: "Discipline Drill", text: drillText, tags: [.health, .career]))
            StaticInstantActionFlavor.publishPulse(&state, domain: "health", strength: 15)
        default:
            state.player = player
            state.healthProfile = health
            return result
        }

        player.health = ((health.physicalWellness * 2) + health.mentalWellness) / 3
        player.clampStats()
        health.clamp()
        state.player = player
        state.healthProfile = health
        return result
    }

    // MARK: - Frictionless Instant Reaction (Health Autonomy)

    /// Lightweight synchronous reaction when player takes a health instant action.
    /// Makes "Protect Sleep", "Rest", etc. feel like the body/world immediately responds.
    mutating func reactToPlayerHealthAction(
        _ choiceID: ActionChoiceID,
        state: inout GameState
    ) -> [DomainNote] {
        var notes: [DomainNote] = []

        switch choiceID {
        case .protectSleep, .rest:
            // Phase 5: Stronger "fighting back" texture, especially in Grounded when already low
            let isGrounded = state.resilience == .grounded
            let lowHealth = state.player.health < 42 || state.healthProfile.mentalWellness < 42
            let recoveryBonus: Int = {
                if isGrounded { return lowHealth ? 8 : 5 }
                return lowHealth ? 5 : 3
            }()

            if state.healthProfile.activeConditions.isEmpty {
                state.healthProfile.mentalWellness = (state.healthProfile.mentalWellness + recoveryBonus).clamped(to: 0...100)
                state.healthProfile.physicalWellness = (state.healthProfile.physicalWellness + max(1, recoveryBonus / 2)).clamped(to: 0...100)
                state.player.health = ((state.healthProfile.physicalWellness * 2) + state.healthProfile.mentalWellness) / 3
                state.player.clampStats()
                let text = isGrounded
                    ? "In a Grounded life, choosing rest felt like a real act of defiance. The body noticed."
                    : "Your choice to rest registered. A little more clarity returned faster than expected."
                notes.append(
                    DomainNote(
                        title: "Body Responded",
                        text: text,
                        tags: [.health, .progress]
                    )
                )
            } else {
                for i in state.healthProfile.activeConditions.indices {
                    let relief = isGrounded ? 6 : 4
                    state.healthProfile.activeConditions[i].severity = max(1, state.healthProfile.activeConditions[i].severity - relief)
                }
                let text = isGrounded
                    ? "Protecting your energy in a Grounded run eased one of the weights. It mattered more because the margins are thinner."
                    : "Protecting your energy eased one of the weights you've been carrying."
                notes.append(
                    DomainNote(
                        title: "Recovery Momentum",
                        text: text,
                        tags: [.health]
                    )
                )
            }

        case .seeDoctor:
            if !state.healthProfile.hasPrimaryCare {
                let isGrounded = state.resilience == .grounded
                let text = isGrounded
                    ? "In a Grounded life, reaching for care felt like claiming ground back. The future just got a little less sharp."
                    : "Scheduling care shifted how future health events might land. The system noticed the intention."
                notes.append(
                    DomainNote(
                        title: "Proactive Step",
                        text: text,
                        tags: [.health]
                    )
                )
            }

        case .recurringTherapy, .improveSleep, .protectYourEnergy:
            let lowMental = state.healthProfile.mentalWellness < 45
            let bonus = lowMental ? 3 : 1
            state.healthProfile.mentalWellness = (state.healthProfile.mentalWellness + bonus).clamped(to: 0...100)
            state.player.health = ((state.healthProfile.physicalWellness * 2) + state.healthProfile.mentalWellness) / 3
            notes.append(
                DomainNote(
                    title: "Recovery Ripple",
                    text: lowMental
                        ? "The body registered the care immediately. You feel slightly less underwater."
                        : "Maintenance mode still counts. The nervous system exhaled a little.",
                    tags: [.health, .progress]
                )
            )

        case .manageMeds:
            if !state.healthProfile.activeConditions.isEmpty {
                for i in state.healthProfile.activeConditions.indices {
                    state.healthProfile.activeConditions[i].severity = max(1, state.healthProfile.activeConditions[i].severity - 3)
                }
                notes.append(
                    DomainNote(
                        title: "Symptoms Eased",
                        text: "The regimen caught up with you. One flare feels a size smaller.",
                        tags: [.health]
                    )
                )
            }

        case .bodyConditioning:
            state.career.burnout = max(0, state.career.burnout - 2)
            if state.specialCareer.track == .athlete {
                state.specialCareer.athlete.durability = min(95, state.specialCareer.athlete.durability + 3)
                notes.append(
                    DomainNote(
                        title: "Athlete Edge",
                        text: "The extra work showed up in how the body moves. Performance paths feel sharper.",
                        tags: [.health, .career]
                    )
                )
            }

        default:
            break
        }

        return notes
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
        case .saveForDownPayment, .depositToHouseFund, .buyStarterHome, .refinanceMortgage, .buildMaintenanceReserve, .topUpHouseReserve, .sellHome:
            return true
        default:
            return false
        }
    }

    func isInstantHomeAction(_ choiceID: ActionChoiceID) -> Bool {
        switch choiceID {
        case .depositToHouseFund, .topUpHouseReserve:
            return true
        default:
            return false
        }
    }

    func applyInstantAction(_ choiceID: ActionChoiceID, state: inout GameState) -> DomainYearResult {
        switch choiceID {
        case .depositToHouseFund:
            return applyInstantHouseFundDeposit(state: &state)
        case .topUpHouseReserve:
            return applyInstantReserveTopUp(state: &state)
        default:
            return DomainYearResult()
        }
    }

    func applyInstantHouseFundDeposit(state: inout GameState) -> DomainYearResult {
        var result = DomainYearResult()
        guard state.player.age >= 18, !state.assets.ownsHome else {
            result.notes.append(DomainNote(title: "House Fund", text: "You are not in a buying lane right now.", tags: [.finance, .housing]))
            return result
        }

        let snapshot = AssetDomainSnapshot(
            world: WorldCache(),
            player: state.player,
            military: state.military,
            career: state.career,
            finance: state.finance,
            assets: state.assets,
            housing: state.housing
        )
        let targetValue = recommendedHomeValue(for: snapshot, finance: state.finance)
        state.assets.homeownershipTrackActive = true
        state.assets.targetHomeValue = targetValue

        let availableCash = max(0, state.finance.cashOnHand - minimumLiquidReserve)
        let amount = min(max(500, availableCash / 4), 2_500)
        guard amount >= 500 else {
            result.notes.append(DomainNote(title: "House Fund", text: "You wanted to move money toward a home, but your cash floor is too thin to do it safely.", tags: [.finance, .housing]))
            return result
        }

        state.finance.cashOnHand -= amount
        state.finance.homeDownPaymentSavings += amount
        state.housing.housingStability = (state.housing.housingStability + 1).clamped(to: 0...100)
        syncHomeWealth(finance: &state.finance, assets: state.assets)
        result.notes.append(
            DomainNote(
                title: "House Fund",
                text: "You moved $\(amount) into the house fund. Ownership feels \(state.finance.homeDownPaymentSavings >= downPaymentNeeded(for: targetValue, isVeteran: state.military.isVeteran) ? "within reach" : "closer").",
                tags: [.finance, .housing]
            )
        )
        return result
    }

    func applyInstantReserveTopUp(state: inout GameState) -> DomainYearResult {
        var result = DomainYearResult()
        guard state.assets.ownsHome, var home = state.assets.primaryResidence else {
            result.notes.append(DomainNote(title: "House Reserve", text: "There is no owned home to fortify yet.", tags: [.finance, .housing]))
            return result
        }

        let availableCash = max(0, state.finance.cashOnHand - minimumLiquidReserve / 2)
        let amount = min(max(750, availableCash / 5), 2_000)
        guard amount >= 750 else {
            result.notes.append(DomainNote(title: "House Reserve", text: "You tried to build repair cushion, but liquid cash was too thin.", tags: [.finance, .housing]))
            return result
        }

        state.finance.cashOnHand -= amount
        home.maintenanceReserve += amount
        home.normalize()
        state.assets.primaryResidence = home
        syncHomeWealth(finance: &state.finance, assets: state.assets)
        result.notes.append(
            DomainNote(
                title: "House Reserve",
                text: "You added $\(amount) to the repair reserve. The house has more slack before the next surprise bill.",
                tags: [.finance, .housing]
            )
        )
        return result
    }

    func downPaymentNeeded(for targetValue: Int, isVeteran: Bool) -> Int {
        let down = isVeteran ? 0 : (targetValue * downPaymentRatePercent / 100)
        let closing = targetValue * closingCostRatePercent / 100
        return down + closing
    }

    func projectedInstantDepositAmount(cashOnHand: Int) -> Int {
        let availableCash = max(0, cashOnHand - minimumLiquidReserve)
        return min(max(500, availableCash / 4), 2_500)
    }

    func projectedInstantReserveAmount(cashOnHand: Int) -> Int {
        let availableCash = max(0, cashOnHand - minimumLiquidReserve / 2)
        return min(max(750, availableCash / 5), 2_000)
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

        let valueRate = homeValueRate(for: finance.currentRegionPolicyID, traits: input.player.traits, currentStatus: home.status, upgrades: home.upgrades) // worldEra default used (AssetDomainSnapshot does not directly expose it)
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

        let isVeteran = input.military.isVeteran
        
        guard input.career.status == .fullTime || (isVeteran && input.career.status != .unemployed),
              input.career.yearsWorked >= balanceProfile.homeownership.minimumYearsWorked || isVeteran,
              finance.lastYearBalanceDelta >= balanceProfile.homeownership.minimumPositiveBalanceDelta,
              finance.debtPressureBand != .heavy,
              finance.debtPressureBand != .crushing,
              finance.recentDebtReliefYears == 0 else {
            return [DomainNote(title: "Home Search", text: "You were not stable enough yet to carry ownership without it becoming immediate danger.", tags: [.finance, .housing])]
        }

        let downPayment = isVeteran ? 0 : (targetValue * downPaymentRatePercent / 100)
        let closingCost = targetValue * closingCostRatePercent / 100
        let upfrontTotal = downPayment + closingCost
        guard finance.homeDownPaymentSavings + finance.cashOnHand - upfrontTotal >= (isVeteran ? minimumLiquidReserve / 2 : minimumLiquidReserve) else {
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
            mortgageRatePercent: isVeteran ? mortgageRate - 1 : mortgageRate, // Slightly better rate for VA
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
        
        let noteText = isVeteran ? "You bought a starter home using a VA loan with 0% down. Your veteran status paved the way to ownership." : "You bought a starter home. The stability signal is real, and so is the debt now sitting underneath the rest of your life."
        return [DomainNote(title: "Bought A Home", text: noteText, tags: [.finance, .housing, .assets])]
    }

    func sellPrimaryHome(home: PrimaryResidenceState, finance: inout FinanceState, assets: inout AssetState, housing: inout HousingState, distressSale: Bool) -> [DomainNote] {
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

    private func homeValueRate(for policyID: String?, traits: [PersonalityTrait], currentStatus: PrimaryResidenceStatus, upgrades: [HouseUpgrade], worldEra: WorldEra = .stable) -> Int {
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

        // Assets3: Strong WorldEra reactivity on luxury/real estate assets
        switch worldEra {
        case .recession:
            rate -= 6  // Luxury homes suffer hard in downturns
        case .highInflation:
            rate -= 3
            if upgrades.count > 2 { rate -= 2 } // High-end homes hit harder by inflation on maintenance
        case .bullMarket, .techBoom:
            rate += 5  // Luxury real estate booms
            if upgrades.count > 1 { rate += 2 }
        case .pandemic, .wartime:
            rate -= 2
        default:
            break
        }

        return rate.clamped(to: -12...14)
    }

    func recommendedHomeValuePublic(for input: AssetDomainSnapshot, finance: FinanceState) -> Int {
        recommendedHomeValue(for: input, finance: finance)
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
