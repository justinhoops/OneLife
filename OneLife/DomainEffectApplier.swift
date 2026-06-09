import Foundation

struct DomainEffectApplier {
    func apply(
        result: DomainYearResult,
        to state: inout GameState,
        trajectorySystem: TrajectorySystem,
        educationSystem: EducationSystem,
        careerSystem: CareerSystem,
        specialCareerSystem: SpecialCareerSystem,
        militarySystem: MilitarySystem,
        crimeSystem: CrimeSystem,
        financeSystem: FinanceSystem,
        relationshipSystem: RelationshipSystem,
        healthSystem: HealthSystem,
        housingSystem: HousingSystem
    ) {
        applyCoreEffects(result.coreEffects, to: &state.player)

        if let trajectoryEffects = result.trajectoryEffects {
            trajectorySystem.apply(effect: trajectoryEffects, trajectory: &state.trajectory)
        }

        if let educationEffects = result.educationEffects {
            educationSystem.apply(effect: educationEffects, education: &state.education)
        }

        if let careerEffects = result.careerEffects {
            careerSystem.apply(effect: careerEffects, player: &state.player, career: &state.career, finance: &state.finance)
        }

        if let specialCareerEffects = result.specialCareerEffects {
            if let track = specialCareerEffects.setTrack {
                state.specialCareer.track = track
                // Dossier integration: event-granted special careers still get childhood-biased starting state
                SpecialCareerSystem.biasSeedingForTrack(track, into: &state.specialCareer, dossier: state.childhoodDossier)
            }
            if let tier = specialCareerEffects.tier {
                state.specialCareer.tier = tier
            }
            if let fame = specialCareerEffects.fame {
                state.specialCareer.fame += fame
            }
            if let audience = specialCareerEffects.audience {
                state.specialCareer.audience += audience
            }
            if let heat = specialCareerEffects.heat {
                state.specialCareer.heat += heat
            }
            if let notoriety = specialCareerEffects.notoriety {
                state.specialCareer.notoriety += notoriety
            }
            if let burnout = specialCareerEffects.burnout {
                state.specialCareer.burnout += burnout
            }
            if let yearsActive = specialCareerEffects.yearsActive {
                state.specialCareer.yearsActive += yearsActive
            }
            if let lastPayout = specialCareerEffects.lastPayout {
                state.specialCareer.lastPayout = lastPayout
            }
            if specialCareerEffects.exitTrack == true {
                state.specialCareer = SpecialCareerState()
            }
            state.specialCareer.clamp()
        }

        // Fame Web F1
        if let fameEffects = result.fameEffects {
            if let cf = fameEffects.culturalFame {
                state.fame.culturalFame = (state.fame.culturalFame + cf).clamped(to: 0...100)
            }
            if let noto = fameEffects.notoriety {
                state.fame.notoriety = (state.fame.notoriety + noto).clamped(to: 0...100)
            }
            if let tag = fameEffects.addKnownFor, !tag.isEmpty, !state.fame.knownFor.contains(tag) {
                state.fame.knownFor.append(tag)
            }
            state.fame.clamp()
        }

        if let militaryEffects = result.militaryEffects {
            if let fitness = militaryEffects.fitness {
                state.military.fitness += fitness
            }
            if let discipline = militaryEffects.discipline {
                state.military.discipline += discipline
            }
            if let heat = militaryEffects.heat {
                state.military.heat += heat
            }
            if let rankLevel = militaryEffects.rankLevel {
                state.military.rankLevel = rankLevel
            }
            if let contractYearsRemaining = militaryEffects.contractYearsRemaining {
                state.military.contractYearsRemaining = contractYearsRemaining
            }
            if let setDeploymentStatus = militaryEffects.setDeploymentStatus {
                state.military.deploymentStatus = setDeploymentStatus
            }
            if let isAWOL = militaryEffects.isAWOL {
                state.military.isAWOL = isAWOL
            }
            if let addMedal = militaryEffects.addMedal {
                state.military.medals.append(addMedal)
            }
            state.military.clamp()
        }

        if let crimeEffects = result.crimeEffects {
            if let status = crimeEffects.setStatus {
                state.crime.status = status
            }
            if let roleTier = crimeEffects.roleTier {
                state.crime.roleTier = roleTier
            }
            if let heat = crimeEffects.heat {
                state.crime.heat += heat
            }
            if let notoriety = crimeEffects.notoriety {
                state.crime.notoriety += notoriety
            }
            if let burnout = crimeEffects.burnout {
                state.crime.burnout += burnout
            }
            if let crewID = crimeEffects.crewID {
                state.crime.crewID = crewID
            }
            if let loyalty = crimeEffects.loyalty {
                state.crime.loyalty += loyalty
            }
            if let territoryPressure = crimeEffects.territoryPressure {
                state.crime.territoryPressure += territoryPressure
            }
            if let yearsActive = crimeEffects.yearsActive {
                state.crime.yearsActive += yearsActive
            }
            if let lastPayout = crimeEffects.lastPayout {
                state.crime.lastPayout = lastPayout
            }
            if crimeEffects.exitCrime == true {
                state.crime = CrimeState()
            }
            state.crime.clamp()
        }

        if let legalEffects = result.legalEffects {
            LegalSystem().apply(effect: legalEffects, legal: &state.legal)
        }

        if let financeEffects = result.financeEffects {
            financeSystem.apply(effect: financeEffects, finance: &state.finance, player: &state.player)
        }

        if let relationshipEffects = result.relationshipEffects {
            relationshipSystem.apply(effect: relationshipEffects, to: &state.relationships)
        }

        if let familyEffects = result.familyEffects {
            if let intent = familyEffects.pregnancyIntent {
                state.family.pregnancyIntent = intent
            }
            if let delta = familyEffects.atHomeBondDelta {
                for index in state.family.children.indices where state.family.children[index].livesAtHome {
                    state.family.children[index].bondWithPlayer =
                        (state.family.children[index].bondWithPlayer + delta).clamped(to: 5...95)
                }
            }
            if let delta = familyEffects.allChildrenBondDelta {
                for index in state.family.children.indices {
                    state.family.children[index].bondWithPlayer =
                        (state.family.children[index].bondWithPlayer + delta).clamped(to: 5...95)
                }
            }
            if let deltas = familyEffects.childBondDeltaByID {
                for index in state.family.children.indices {
                    guard let delta = deltas[state.family.children[index].id] else { continue }
                    state.family.children[index].bondWithPlayer =
                        (state.family.children[index].bondWithPlayer + delta).clamped(to: 5...95)
                }
            }
        }

        if let healthEffects = result.healthEffects {
            healthSystem.apply(effect: healthEffects, player: &state.player, health: &state.healthProfile)
        }

        if let housingEffects = result.housingEffects {
            housingSystem.apply(effect: housingEffects, housing: &state.housing)
        }

        if let assetEffects = result.assetEffects {
            applyAssetEffects(assetEffects, to: &state.assets)
        }
    }

    func applyAssetEffects(_ effects: AssetEffects, to assets: inout AssetState) {
        if let firearm = effects.addFirearm {
            assets.firearms.append(firearm)
        }
        if let removeID = effects.removeFirearmID {
            assets.firearms.removeAll { $0.id == removeID }
        }
        if let upgradeID = effects.upgradeFirearmID, let upgrade = effects.addUpgrade {
            if let index = assets.firearms.firstIndex(where: { $0.id == upgradeID }) {
                assets.firearms[index].upgrades.append(upgrade)
            }
        }
        
        if let vehicle = effects.addVehicle {
            assets.vehicles.append(vehicle)
        }
        if let removeVID = effects.removeVehicleID {
            assets.vehicles.removeAll { $0.id == removeVID }
        }
        if let upgradeVID = effects.upgradeVehicleID, let vUpgrade = effects.addVehicleUpgrade {
            if let vIndex = assets.vehicles.firstIndex(where: { $0.id == upgradeVID }) {
                assets.vehicles[vIndex].upgrades.append(vUpgrade)
            }
        }

        if let houseUpgrade = effects.addHouseUpgrade {
            assets.primaryResidence?.upgrades.append(houseUpgrade)
        }

        if let jewelry = effects.addJewelry {
            assets.jewelry.append(jewelry)
        }
        if let removeJID = effects.removeJewelryID {
            assets.jewelry.removeAll { $0.id == removeJID }
        }

        if let aviation = effects.addAviation {
            assets.aviation.append(aviation)
        }
        if let removeAID = effects.removeAviationID {
            assets.aviation.removeAll { $0.id == removeAID }
        }

        if let marine = effects.addMarine {
            assets.marine.append(marine)
        }
        if let removeMID = effects.removeMarineID {
            assets.marine.removeAll { $0.id == removeMID }
        }
    }

    func applyCoreEffects(_ effects: CoreStatEffects?, to player: inout Player) {
        guard let effects else { return }
        player.happiness += effects.happiness ?? 0
        player.smarts += effects.smarts ?? 0
        player.looks += effects.looks ?? 0
        player.health += effects.health ?? 0
    }
}
