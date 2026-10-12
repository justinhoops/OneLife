import Foundation

enum DomainActionRegistry {
    static let all: [DomainAction] = [
        action(.negotiateDebt, .cash, "Negotiate debt relief", "Review a five-year repayment plan before committing.",
            text: "A changed financial future is possible, with a real cost.",
            requirements: Requirement(minimumAge: 18, values: [.debtWorkoutEligible]),
            tags: ["5-year plan", "Review first"], category: .money, domainEffects: DomainActionEffects(finance: .openWorkout)),
        // High school — one defining commitment per year
        action(
            .focusGrades, .school, "Chase grades", "Make schoolwork the center of this year.",
            school: 4...6, health: -2 ... -1,
            influence: InfluenceVector(work: 2, stability: 1),
            text: "You decide the transcript will not happen by accident.",
            requirements: Requirement(requiresSchool: true, allowedStages: [.adolescence], values: [.schoolCommitmentOpen]),
            tags: ["Grades+", "Future+", "Health−"],
            beat: "The calendar fills. Your margin gets thinner.",
            npcRole: .teacher,
            category: .education,
            domainEffects: DomainActionEffects(education: .focusGrades)
        ),
        action(
            .findYourPeople, .school, "Find your people", "Risk being known instead of staying invisible.",
            love: 3...5, play: 2...4,
            influence: InfluenceVector(family: 2, risk: 1),
            text: "You stop waiting for the right people to discover you.",
            requirements: Requirement(requiresSchool: true, allowedStages: [.adolescence], values: [.schoolCommitmentOpen]),
            tags: ["Belonging+", "Social"],
            beat: "A seat opens. You take it.",
            npcRole: .friend,
            category: .education,
            domainEffects: DomainActionEffects(education: .findYourPeople)
        ),
        action(
            .commitActivity, .school, "Commit to an activity", "Let one thing after school become yours.",
            school: 1...2, love: 2...3, play: 2...4,
            influence: InfluenceVector(work: 1, family: 1),
            text: "The activity gives the week a place where your name means something.",
            requirements: Requirement(requiresSchool: true, allowedStages: [.adolescence], values: [.schoolCommitmentOpen, .schoolActivityOpen]),
            tags: ["Belonging+", "Future+"],
            beat: "Practice runs late. You stay anyway.",
            npcRole: .friend,
            category: .education,
            domainEffects: DomainActionEffects(education: .commitActivity)
        ),
        action(
            .helpAtHome, .school, "Help at home", "Carry what your household cannot ignore.",
            cash: EconomyPolicy.actionQuote(.helpAtHome), play: -3 ... -1, health: -2 ... -1,
            influence: InfluenceVector(family: 3, stability: 1),
            text: "You take on work nobody at school will put on your transcript.",
            requirements: Requirement(requiresSchool: true, allowedStages: [.adolescence], values: [.schoolCommitmentOpen]),
            tags: ["Cash+", "Family", "Grades−"],
            beat: "The house needs hours. You give it yours.",
            category: .education,
            domainEffects: DomainActionEffects(education: .helpAtHome)
        ),
        // School — static core
        action(
            .study, .school, "Study", "Build useful knowledge.",
            school: 5...8, health: -2 ... -1,
            influence: InfluenceVector(work: 2),
            text: "You made the hours count.",
            requirements: Requirement(requiresSchool: true, allowedStages: [.launch, .build, .pressure]),
            tags: ["Smart+", "Health−"],
            beat: "Pages stack. Something sticks.",
            npcRole: .teacher,
            npcBranches: [
                npcBranch("study-encouraging", .teacher, [.encouraging], school: 2, rapport: 1, headline: "Your Teacher Noticed The Work", narrative: "Their encouragement made the extra effort feel worth sustaining.", hint: "They reward visible effort."),
                npcBranch("study-critical", .teacher, [.critical], school: 1, rapport: -1, headline: "The Work Faced A Harder Eye", narrative: "They saw the effort, but held you to a sharper standard.", hint: "They expect precision.")
            ]
        ),
        action(
            .attendClass, .school, "Attend class", "Keep your footing at school.",
            school: 3...5, play: -1 ... 0, rep: 0...1,
            influence: InfluenceVector(work: 1, stability: 1),
            text: "You showed up and stayed engaged.",
            requirements: Requirement(requiresSchool: true, allowedStages: [.launch, .build, .pressure]),
            tags: ["Smart+", "Steady"],
            beat: "You were in the room when it mattered.",
            npcRole: .teacher,
            npcBranches: [
                npcBranch("class-fair", .teacher, [.fair], school: 1, rep: 1, rapport: 1, headline: "Your Teacher Saw You Show Up", narrative: "Consistency earned a little more trust in the room.", hint: "They value consistency."),
                npcBranch("class-critical", .teacher, [.critical], school: 1, rapport: -1, headline: "Attendance Was Only The Start", narrative: "Showing up counted, but they still expect you to do more with the hour.", hint: "They expect more than presence.")
            ]
        ),
        action(
            .joinClub, .school, "Join a club", "Meet people around an interest.",
            school: 1...3, love: 2...4, play: 2...4, rep: 1...2,
            text: "A shared interest made the week feel bigger.",
            requirements: Requirement(requiresSchool: true, allowedStages: [.launch, .build]),
            tags: ["Social", "Rep+"],
            beat: "Names stick. The hall feels less empty.",
            npcRole: .friend,
            npcBranches: [
                npcBranch("club-sociable", .friend, [.sociable], love: 2, play: 1, rapport: 1, headline: "Someone Made Room For You", narrative: "Their easy welcome turned an interest into a real opening.", hint: "They make connection easier."),
                npcBranch("club-dependable", .friend, [.dependable], rep: 1, rapport: 1, headline: "A Steady Connection Took Root", narrative: "They followed up after the meeting instead of letting the moment disappear.", hint: "They value follow-through.")
            ]
        ),
        // Skills track — after school (same tab; chapter swap)
        action(
            .networkContacts, .school, "Network", "Keep useful people in orbit.",
            school: 1...2, cash: EconomyPolicy.actionQuote(.networkContacts), love: 1...3, rep: 2...4,
            influence: InfluenceVector(work: 2, risk: 1),
            text: "You put your name in rooms that remember names.",
            requirements: Requirement(requiresLeftSchool: true, allowedStages: [.build, .pressure, .legacy]),
            tags: ["Rep+", "Career"],
            beat: "A coffee. A follow-up. A door that is not closed."
        ),
        action(
            .sideHustle, .school, "Side hustle", "Commit nights to side work this year; taxes are withheld.",
            cash: EconomyPolicy.actionQuote(.sideHustle), play: -2 ... -1, health: -3 ... -1, rep: 0...1,
            influence: InfluenceVector(work: 2, risk: 2),
            text: "You sell hours the day job does not own.",
            requirements: Requirement(requiresLeftSchool: true, allowedStages: [.launch, .build, .pressure]),
            tags: ["Cash+", "Health−"],
            beat: "Invoice sent. Sleep postponed.",
            domainEffects: DomainActionEffects(finance: .creditSideHustle)
        ),
        action(
            .applyToCollege, .school, "Apply to college", "Turn your diploma into another opening.",
            cash: EconomyPolicy.actionQuote(.applyToCollege), health: -1 ... 0, rep: 0...1,
            influence: InfluenceVector(work: 1, risk: 1),
            text: "You send the record you have instead of waiting to become certain.",
            requirements: Requirement(
                minimumAge: 18,
                requiresLeftSchool: true,
                allowedStages: [.launch],
                values: [.collegeApplicationEligible]
            ),
            tags: ["College", "Choice"],
            beat: "Forms sent. The answer is no longer imaginary.",
            personalityImpulse: PersonalityImpulse(drive: 1, riskTolerance: 1, adaptability: 2),
            domainEffects: DomainActionEffects(education: .openCollegeOffers)
        ),
        action(
            .returnToEducation, .school, "Return to education", "Recover a credential or resume work already started.",
            cash: EconomyPolicy.actionQuote(.returnToEducation), health: -1 ... 0, rep: 0...1,
            influence: InfluenceVector(work: 1, stability: 2),
            text: "You reopen the part of your record that never felt finished.",
            requirements: Requirement(
                minimumAge: 18,
                requiresLeftSchool: true,
                allowedStages: [.launch, .build, .pressure],
                values: [.educationRecoveryEligible]
            ),
            tags: ["Second chance", "Choice"],
            beat: "The old record opens. This time the terms are clearer.",
            personalityImpulse: PersonalityImpulse(drive: 1, riskTolerance: -1, adaptability: 2),
            domainEffects: DomainActionEffects(education: .openRecoveryOffers)
        ),
        action(
            .skillCourse, .school, "Skill course", "Learn something the market pays for.",
            school: 4...7, cash: EconomyPolicy.actionQuote(.skillCourse), play: -1 ... 0, rep: 1...2,
            influence: InfluenceVector(work: 2, stability: 1),
            text: "You put new tools in your hands on purpose.",
            requirements: Requirement(minimumCash: 2500, requiresLeftSchool: true, allowedStages: [.build, .pressure, .legacy]),
            tags: ["Smart+", "Cash−"],
            beat: "A certificate is paper. The practice is not."
        ),
        // Cash — static core
        action(
            .workShift, .cash, "Work extra hours", "Commit extra hours this year for 5% of annual base pay, before tax.",
            cash: EconomyPolicy.actionQuote(.workShift), health: -2 ... -1, rep: 0...1,
            influence: InfluenceVector(work: 3),
            text: "You sustained extra hours across the working year.",
            tags: ["Cash+", "Health−"],
            beat: "The extra hours add up across the year.",
            npcRole: .boss,
            npcBranches: [
                npcBranch("shift-fair", .boss, [.fair], cash: 200, rep: 1, rapport: 1, headline: "Your Boss Counted The Effort", narrative: "They noticed the shift was handled cleanly and gave you a little credit.", hint: "They reward reliable work."),
                npcBranch("shift-ambitious", .boss, [.ambitious], cash: 100, rapport: -1, headline: "The Shift Raised The Bar", narrative: "They saw what you could do and immediately expected more of it.", hint: "They reward results, then raise expectations.")
            ],
            domainEffects: DomainActionEffects(finance: .creditExtraWork)
        ),
        action(
            .budget, .cash, "Reduce spending", "Limit this year’s discretionary spending to $600.",
            influence: InfluenceVector(work: 1, stability: 2),
            text: "You made a plan and kept it.",
            tags: ["Lower spending", "Steady"],
            beat: "You say no to the easy spend.",
            category: .money,
            domainEffects: DomainActionEffects(finance: .budget)
        ),
        action(
            .applyForBetterWork, .cash, "Apply for better work", "Take a shot at more stability.",
            school: 1...2, cash: EconomyPolicy.actionQuote(.applyForBetterWork), rep: 1...2,
            influence: InfluenceVector(work: 3, risk: 1),
            text: "You sent out applications that could change your footing.",
            requirements: Requirement(minimumAge: 18, minimumStat: 55, statDomain: .school, requiresCredential: true, allowedStages: [.launch, .build, .pressure]),
            tags: ["Career", "Risk"],
            beat: "You put your name where better money lives.",
            npcRole: .boss,
            npcBranches: [
                npcBranch("apply-encouraging", .boss, [.encouraging], rep: 2, rapport: 1, headline: "Your Boss Backed The Move", narrative: "Their recommendation made your application carry more weight.", hint: "They will advocate for earned growth."),
                npcBranch("apply-critical", .boss, [.critical], rep: -1, rapport: -1, headline: "Your Boss Questioned The Leap", narrative: "They were not convinced you had proved enough yet.", hint: "They want a stronger record first.")
            ]
        ),
        // Love — static core
        action(
            .reachOut, .love, "Reach out", "Make time for your people.",
            love: 4...7, play: 1...2,
            influence: InfluenceVector(family: 2, stability: 1),
            partnerEffect: PartnerEffect(bond: 1, resentment: -1),
            text: "You made someone feel remembered.",
            tags: ["Happy+", "Bond"],
            beat: "A text lands. Someone answers.",
            personalityBranches: [
                branch("reach-reassurance", [.demanding, .cautious], bond: 2, resentment: -2, headline: "Reassurance Landed This Time", narrative: "Your concrete check-in gave them something dependable to hold onto.", hint: "Reassurance matters more to them."),
                branch("reach-space", [.independent, .supportive], bond: 1, resentment: -1, headline: "Space Did Not Mean Distance", narrative: "They read the message as care, not an attempt to manage them.", hint: "They value care without pressure."),
                branch("reach-steady", [.supportive, .loyal], bond: 1, resentment: -1, headline: "They Felt Remembered Again", narrative: "Your consistency mattered more than a grand gesture.", hint: "Steady contact builds trust."),
                learnedBranch("reach-secure", .secure, bond: 1, resentment: 0, headline: "Trust Made Contact Easier", narrative: "The security you built made the ordinary message land warmly.", hint: "Their trust amplifies care."),
                learnedBranch("reach-guarded", .guarded, bond: 0, resentment: -1, headline: "They Stayed Carefully Guarded", narrative: "They accepted the outreach, but are still waiting for a pattern.", hint: "Trust needs repeated proof.")
            ]
        ),
        action(
            .goOnDate, .love, "Go on a date", "See where a connection goes.",
            cash: EconomyPolicy.actionQuote(.goOnDate), love: 4...7, play: 2...4, looks: 0...1,
            influence: InfluenceVector(family: 3),
            partnerEffect: PartnerEffect(bond: 3, resentment: -1),
            text: "You gave the connection some room to grow.",
            tags: ["Happy+", "Cash−"],
            beat: "The table for two is not empty.",
            personalityBranches: [
                branch("date-novelty", [.adventurous, .loyal], bond: 2, resentment: -1, headline: "Shared Novelty Pulled You Closer", narrative: "A little spontaneity reminded them why the relationship still has momentum.", hint: "Shared novelty brings them closer."),
                branch("date-steady", [.cautious, .supportive], bond: 1, resentment: -1, headline: "A Quiet Date Felt Safe", narrative: "The care you put into the plan mattered more than spectacle.", hint: "Reliability makes dates land."),
                branch("date-reassurance", [.demanding, .cautious], bond: 1, resentment: -1, headline: "You Made Time Feel Real", narrative: "Showing up deliberately answered a question they had not stopped asking.", hint: "Visible effort reassures them."),
                learnedBranch("date-secure", .secure, bond: 1, resentment: 0, headline: "Trust Made The Date Easy", narrative: "They could relax into the time together because the relationship feels secure.", hint: "Their trust softens the moment."),
                learnedBranch("date-guarded", .guarded, bond: 0, resentment: 0, headline: "They Kept Some Distance", narrative: "The date was good, but they are not ready to treat one night as proof.", hint: "Trust needs repeated proof.")
            ]
        ),
        action(
            .repairConflict, .love, "Repair conflict", "Have the hard conversation.",
            love: 5...8, health: -1 ... 0,
            influence: InfluenceVector(family: 3, stability: 2),
            partnerEffect: PartnerEffect(bond: 4, resentment: -5),
            text: "You did not let the distance harden.",
            requirements: Requirement(requiresPartner: true),
            tags: ["Bond+", "Hard talk"],
            beat: "You stay in the room until it softens.",
            personalityBranches: [
                branch("repair-steady", [.supportive, .loyal], bond: 2, resentment: -2, headline: "The Hard Talk Held", narrative: "Their loyalty gave the conversation enough room to become repair.", hint: "They respond to honest repair."),
                branch("repair-proof", [.demanding, .cautious], bond: -1, resentment: 1, headline: "They Needed More Than Words", narrative: "The apology helped, but they need a concrete change before the tension lifts.", hint: "Promises need a visible plan."),
                branch("repair-practical", [.cautious, .supportive], bond: 1, resentment: -2, headline: "A Practical Repair Landed", narrative: "A clear plan made the conversation feel safer than a vague promise.", hint: "Specific plans build safety."),
                learnedBranch("repair-secure", .secure, bond: 1, resentment: -1, headline: "Trust Left Room For Repair", narrative: "The security between you kept the conflict from becoming a verdict.", hint: "Their trust helps repair land."),
                learnedBranch("repair-guarded", .guarded, bond: -2, resentment: 2, headline: "They Stayed Guarded Through It", narrative: "They heard you, but old distance made a quick repair feel unearned.", hint: "Trust needs repeated proof.")
            ]
        ),
        // Play — static core
        action(
            .seeFriends, .play, "See friends", "Make time for real company.",
            love: 2...4, play: 5...8, rep: 0...1,
            text: "You left with more energy than you brought.",
            tags: ["Fun+", "Happy+"],
            beat: "Laughter is not on the schedule — and that is the point.",
            npcRole: .friend,
            npcBranches: [
                npcBranch("friends-sociable", .friend, [.sociable], love: 2, play: 1, rapport: 1, headline: "Your Friend Pulled You Back In", narrative: "Their ease made the time together feel effortless.", hint: "They make social time restorative."),
                npcBranch("friends-dependable", .friend, [.dependable], love: 1, rapport: 2, headline: "A Reliable Friend Showed Up", narrative: "They made time because they said they would.", hint: "They value keeping plans.")
            ]
        ),
        action(
            .pursueHobby, .play, "Pursue a hobby", "Do something that is yours.",
            play: 5...8, health: 1...2, looks: 0...1,
            influence: InfluenceVector(stability: 1),
            text: "You made space for yourself.",
            tags: ["Fun+", "You"],
            beat: "An hour that belongs only to you."
        ),
        action(
            .quietNight, .play, "Quiet night", "Keep the evening small on purpose.",
            love: 0...2, play: 3...5, health: 1...3,
            influence: InfluenceVector(stability: 2),
            text: "You choose a soft night and mean it.",
            requirements: Requirement(allowedStages: [.pressure, .legacy]),
            tags: ["Steady", "Health+"],
            beat: "Lights low. Phone face-down."
        ),
        action(
            .familyDinner, .play, "Family dinner", "Put people around a table.",
            cash: EconomyPolicy.actionQuote(.familyDinner), love: 3...6, play: 2...4,
            influence: InfluenceVector(family: 3, stability: 1),
            partnerEffect: PartnerEffect(bond: 2, resentment: -2),
            text: "Food, noise, and the ordinary work of belonging.",
            requirements: Requirement(allowedStages: [.build, .pressure, .legacy]),
            tags: ["Happy+", "Bond"],
            beat: "Plates empty. Someone laughs too hard."
        ),
        action(
            .party, .play, "Party", "Take a loud night out.",
            cash: EconomyPolicy.actionQuote(.party), love: 1...4, play: 6...10, health: -5 ... -2, rep: 1...3,
            influence: InfluenceVector(risk: 3),
            partnerEffect: PartnerEffect(),
            text: "It was fun, and it cost you some recovery.",
            requirements: Requirement(allowedStages: [.launch, .build, .pressure]),
            tags: ["Fun++", "Health−", "Rep+"],
            beat: "The night is loud. Morning will be honest.",
            personalityBranches: [
                branch("party-novelty", [.adventurous, .loyal], bond: 2, resentment: -1, headline: "The Night Gave You Both Air", narrative: "They enjoyed the risk because it still felt shared.", hint: "They enjoy a little shared risk."),
                branch("party-caution", [.cautious, .supportive], bond: -2, resentment: 3, headline: "The Noise Cost More At Home", narrative: "They did not begrudge your fun, but the risk felt careless to them.", hint: "Risk can land badly with them."),
                branch("party-demand", [.demanding, .cautious], bond: -1, resentment: 2, headline: "They Felt Left Out Again", narrative: "The loud night looked like another choice made without them.", hint: "They need visible consideration."),
                learnedBranch("party-guarded", .guarded, bond: -1, resentment: 1, headline: "Distance Followed You Home", narrative: "They read the night through the distance that is already there.", hint: "Existing distance sharpens risk.")
            ],
            npcRole: .friend,
            npcBranches: [
                npcBranch("party-sociable", .friend, [.sociable], play: 2, rep: 1, rapport: 1, headline: "Your Friend Kept The Night Moving", narrative: "Their energy made the night feel shared instead of performative.", hint: "They thrive in a crowd."),
                npcBranch("party-dependable", .friend, [.dependable], health: 1, rapport: 1, headline: "Your Friend Got You Home", narrative: "They knew when the night had gone far enough and made sure you were safe.", hint: "They look out for people.")
            ]
        ),
        // Health — static core
        action(
            .exercise, .health, "Exercise", "Train your body.",
            play: 1...2, health: 5...8, looks: 1...3,
            influence: InfluenceVector(stability: 2),
            text: "You kept a promise to your body.",
            tags: ["Health+", "Looks+"],
            beat: "Breath hard. Legs honest."
        ),
        action(
            .rest, .health, "Rest", "Give yourself a quieter day.",
            play: 1...3, health: 4...7,
            influence: InfluenceVector(stability: 2),
            text: "You let your system settle.",
            tags: ["Health+", "Steady"],
            beat: "You stop performing recovery and actually recover."
        ),
        action(
            .seekCare, .health, "Seek care", "Get professional support.",
            influence: InfluenceVector(stability: 2),
            text: "You asked for help and followed through.",
            tags: ["Health++", "Cash−"],
            beat: "You pay the bill because the alternative costs more.",
            category: .health,
            domainEffects: DomainActionEffects(health: .seekCare)
        ),
        // Phase 1 — career paths and ordinary progression
        action(.chooseOffice, .cash, "Choose office work", "Build leverage inside organizations.", influence: InfluenceVector(work: 2), text: "You chose structured work and its quiet pressures.", requirements: Requirement(values: [.careerTrack(.undecided)]), tags: ["Career path"], category: .career, domainEffects: DomainActionEffects(career: .chooseOffice)),
        action(.chooseTrades, .cash, "Choose a trade", "Build security through practical skill.", influence: InfluenceVector(work: 2, stability: 1), text: "You chose work with visible results and physical cost.", requirements: Requirement(values: [.careerTrack(.undecided)]), tags: ["Career path"], category: .career, domainEffects: DomainActionEffects(career: .chooseTrades)),
        action(.chooseCareService, .cash, "Choose care work", "Earn modestly through human work.", influence: InfluenceVector(work: 1, family: 1), text: "You chose work that asks for emotional presence.", requirements: Requirement(values: [.careerTrack(.undecided)]), tags: ["Career path"], category: .career, domainEffects: DomainActionEffects(career: .chooseCareService)),
        action(.chooseFreelance, .cash, "Choose freelance", "Trade security for control of your time.", influence: InfluenceVector(work: 2, risk: 2), text: "You chose flexibility without a safety rail.", requirements: Requirement(values: [.careerTrack(.undecided)]), tags: ["Career path"], category: .career, domainEffects: DomainActionEffects(career: .chooseFreelance)),
        action(.chooseOfficeAdministrator, .cash, "Choose office administration", "Keep organizations moving from the inside.", influence: InfluenceVector(work: 2), text: "You chose the work that makes other work possible.", requirements: Requirement(values: [.careerTrack(.office), .careerOccupationNotChosen]), tags: ["Occupation", "Office"], category: .career, domainEffects: DomainActionEffects(career: .chooseOfficeAdministrator)),
        action(.chooseAccountant, .cash, "Choose accounting", "Build a career around precision, trust, and numbers.", influence: InfluenceVector(work: 2, stability: 1), text: "You chose a profession where small errors have long shadows.", requirements: Requirement(values: [.careerTrack(.office), .careerOccupationNotChosen]), tags: ["Occupation", "Office"], category: .career, domainEffects: DomainActionEffects(career: .chooseAccountant)),
        action(.chooseHumanResourcesSpecialist, .cash, "Choose human resources", "Manage the people inside the organization.", influence: InfluenceVector(work: 2, family: 1), text: "You chose work built around other people's working lives.", requirements: Requirement(values: [.careerTrack(.office), .careerOccupationNotChosen]), tags: ["Occupation", "Office"], category: .career, domainEffects: DomainActionEffects(career: .chooseHumanResourcesSpecialist)),
        action(.chooseSalesRepresentative, .cash, "Choose sales", "Turn relationships and persuasion into a living.", influence: InfluenceVector(work: 2, risk: 1), text: "You chose a career where every month asks you to begin again.", requirements: Requirement(values: [.careerTrack(.office), .careerOccupationNotChosen]), tags: ["Occupation", "Office"], category: .career, domainEffects: DomainActionEffects(career: .chooseSalesRepresentative)),
        action(.chooseElectrician, .cash, "Become an electrician", "Build practical skill people need to trust.", influence: InfluenceVector(work: 2, stability: 1), text: "You chose work where the answer has to hold when the power comes back on.", requirements: Requirement(values: [.careerTrack(.trades), .careerOccupationNotChosen]), tags: ["Occupation", "Trades"], category: .career, domainEffects: DomainActionEffects(career: .chooseElectrician)),
        action(.choosePlumber, .cash, "Become a plumber", "Solve urgent problems with durable skill.", influence: InfluenceVector(work: 2, stability: 1), text: "You chose work that rarely waits for a convenient day.", requirements: Requirement(values: [.careerTrack(.trades), .careerOccupationNotChosen]), tags: ["Occupation", "Trades"], category: .career, domainEffects: DomainActionEffects(career: .choosePlumber)),
        action(.chooseMechanic, .cash, "Become an automotive mechanic", "Keep other people's lives moving.", influence: InfluenceVector(work: 2), text: "You chose a trade where every strange sound means something.", requirements: Requirement(values: [.careerTrack(.trades), .careerOccupationNotChosen]), tags: ["Occupation", "Trades"], category: .career, domainEffects: DomainActionEffects(career: .chooseMechanic)),
        action(.chooseConstructionWorker, .cash, "Choose construction work", "Build something real with your body and time.", influence: InfluenceVector(work: 2, risk: 1), text: "You chose work that leaves a mark on the landscape and on you.", requirements: Requirement(values: [.careerTrack(.trades), .careerOccupationNotChosen]), tags: ["Occupation", "Trades"], category: .career, domainEffects: DomainActionEffects(career: .chooseConstructionWorker)),
        action(.chooseTeacher, .cash, "Become a teacher", "Make a living by helping the next person grow.", influence: InfluenceVector(work: 1, family: 2), text: "You chose a profession that follows you home in other people's questions.", requirements: Requirement(values: [.careerTrack(.careService), .careerOccupationNotChosen]), tags: ["Occupation", "Care / Service"], category: .career, domainEffects: DomainActionEffects(career: .chooseTeacher)),
        action(.chooseNurse, .cash, "Become a nurse", "Carry skill and steadiness into difficult rooms.", influence: InfluenceVector(work: 2, family: 1), text: "You chose work that asks for competence and presence at the same time.", requirements: Requirement(values: [.careerTrack(.careService), .careerOccupationNotChosen]), tags: ["Occupation", "Care / Service"], category: .career, domainEffects: DomainActionEffects(career: .chooseNurse)),
        action(.chooseCaregiver, .cash, "Become a caregiver", "Make practical care the center of your work.", influence: InfluenceVector(work: 1, family: 2), text: "You chose work whose victories are often quiet and necessary.", requirements: Requirement(values: [.careerTrack(.careService), .careerOccupationNotChosen]), tags: ["Occupation", "Care / Service"], category: .career, domainEffects: DomainActionEffects(career: .chooseCaregiver)),
        action(.chooseRestaurantManager, .cash, "Manage a restaurant", "Keep a demanding room fed, staffed, and moving.", influence: InfluenceVector(work: 2, risk: 1), text: "You chose a job where someone else's bad day still needs a table cleared.", requirements: Requirement(values: [.careerTrack(.careService), .careerOccupationNotChosen]), tags: ["Occupation", "Care / Service"], category: .career, domainEffects: DomainActionEffects(career: .chooseRestaurantManager)),
        action(.chooseDesigner, .cash, "Become a freelance designer", "Sell taste, judgment, and a point of view.", influence: InfluenceVector(work: 2, risk: 1), text: "You chose to make a living by turning a blank page into a client decision.", requirements: Requirement(values: [.careerTrack(.freelance), .careerOccupationNotChosen]), tags: ["Occupation", "Freelance"], category: .career, domainEffects: DomainActionEffects(career: .chooseDesigner)),
        action(.chooseDeveloper, .cash, "Become a freelance developer", "Build useful systems without a permanent desk.", influence: InfluenceVector(work: 2, risk: 1), text: "You chose to make a living wherever the next problem could be solved.", requirements: Requirement(values: [.careerTrack(.freelance), .careerOccupationNotChosen]), tags: ["Occupation", "Freelance"], category: .career, domainEffects: DomainActionEffects(career: .chooseDeveloper)),
        action(.chooseConsultant, .cash, "Become an independent consultant", "Turn experience into advice people will pay for.", influence: InfluenceVector(work: 2, risk: 2), text: "You chose a career where the product is what you notice before everyone else does.", requirements: Requirement(values: [.careerTrack(.freelance), .careerOccupationNotChosen]), tags: ["Occupation", "Freelance"], category: .career, domainEffects: DomainActionEffects(career: .chooseConsultant)),
        action(.chooseIndependentContractor, .cash, "Become an independent contractor", "Trade permanent structure for control over the next job.", influence: InfluenceVector(work: 2, risk: 2), text: "You chose independence with no promise that next month is booked.", requirements: Requirement(values: [.careerTrack(.freelance), .careerOccupationNotChosen]), tags: ["Occupation", "Freelance"], category: .career, domainEffects: DomainActionEffects(career: .chooseIndependentContractor)),
        action(.jobSearch, .cash, "Search for work", "Find a practical foothold.", influence: InfluenceVector(work: 2), text: "You made finding work the work.", requirements: Requirement(values: [.careerLevels([.unemployed]), .careerDirectionChosen]), tags: ["Career"], category: .career, personalityImpulse: PersonalityImpulse(drive: 2, adaptability: 2), domainEffects: DomainActionEffects(career: .search)),
        action(.changeCareer, .cash, "Change career", "Leave the known path and start again.", cash: EconomyPolicy.actionQuote(.changeCareer), influence: InfluenceVector(work: 2, risk: 2), text: "You traded seniority for another chance at fit.", requirements: Requirement(values: [.careerLevels([.entry, .established, .senior])]), tags: ["Pivot", "Risk"], category: .career, personalityImpulse: PersonalityImpulse(drive: 1, riskTolerance: 2, adaptability: 3), domainEffects: DomainActionEffects(career: .pivot)),
        action(.pursuePromotion, .cash, "Pursue promotion", "Ask your record to carry more weight.", influence: InfluenceVector(work: 3), text: "You made ambition visible.", requirements: Requirement(values: [.careerLevels([.entry, .established])]), tags: ["Performance+", "Burnout+"], category: .career, domainEffects: DomainActionEffects(career: .promote)),
        action(.developSkill, .cash, "Develop work skill", "Practice the part that raises your ceiling.", influence: InfluenceVector(work: 2, stability: 1), text: "You invested in competence nobody can fake for long.", requirements: Requirement(minimumCash: 2500, values: [.careerLevels([.entry, .established, .senior])]), tags: ["Skill+", "Cash−"], category: .career, domainEffects: DomainActionEffects(career: .skill)),
        action(.negotiateRaise, .cash, "Negotiate a raise", "Make your contribution and your next number explicit.", influence: InfluenceVector(work: 3, risk: 1), text: "You asked the job to admit what it was getting from you.", requirements: Requirement(values: [.employed, .careerClass(.normal)]), tags: ["Leverage+", "Burnout+"], category: .career, domainEffects: DomainActionEffects(career: .negotiateRaise)),
        action(.acceptOvertime, .cash, "Accept overtime", "Trade recovery time for immediate income and visible effort.", influence: InfluenceVector(work: 3, risk: 1), text: "You gave the job more of the week and took the money it offered back.", requirements: Requirement(values: [.employed]), tags: ["Cash+", "Burnout+", "Workload+"], category: .career, domainEffects: DomainActionEffects(career: .overtime)),
        action(.buildProfessionalNetwork, .cash, "Build your professional network", "Spend time and money making your next opportunity easier to see.", influence: InfluenceVector(work: 2, stability: 1), text: "You stayed after the formal conversation and learned who remembered names.", requirements: Requirement(minimumCash: 500, values: [.employed]), tags: ["Leverage+", "Reputation+", "Cash−"], category: .career, domainEffects: DomainActionEffects(career: .professionalNetwork)),
        action(.pursueCertification, .cash, "Pursue certification", "Turn focused study into a credential your career can use.", influence: InfluenceVector(work: 2, stability: 2), text: "You paid for proof that the next title could trust.", requirements: Requirement(minimumCash: 2500, values: [.employed]), tags: ["Skill+", "Credential+", "Cash−"], category: .career, domainEffects: DomainActionEffects(career: .certification)),
        action(.takeCareerLeave, .cash, "Take career leave", "Protect your capacity before work consumes it.", influence: InfluenceVector(family: 1, stability: 3), text: "You let the calendar stop asking for proof every day.", requirements: Requirement(values: [.employed, .careerClass(.normal)]), tags: ["Burnout−", "Workload−", "Performance−"], category: .career, domainEffects: DomainActionEffects(career: .careerLeave)),
        action(.changeEmployer, .cash, "Change employer", "Keep the occupation; change the workplace around it.", influence: InfluenceVector(work: 2, risk: 1), text: "The work stayed familiar. The manager, culture, and risks around it did not.", requirements: Requirement(values: [.employed]), tags: ["Workplace", "Reset tenure"], category: .career, domainEffects: DomainActionEffects(career: .changeEmployer)),
        action(.buildWorkplaceRelationship, .cash, "Build workplace relationships", "Become easier for managers and coworkers to trust.", influence: InfluenceVector(work: 2, family: 1), text: "You stayed after the formal conversation and learned who remembered names.", requirements: Requirement(values: [.employed]), tags: ["Manager+", "Coworkers+"], category: .career, domainEffects: DomainActionEffects(career: .workplaceRelationship)),
        action(.requestFlexibleSchedule, .cash, "Request flexible schedule", "Trade a little visibility for more room in the week.", influence: InfluenceVector(family: 1, risk: 0, stability: 2), text: "You negotiated a little more air into the workweek.", requirements: Requirement(values: [.employed]), tags: ["Flexibility+", "Workload−"], category: .career, domainEffects: DomainActionEffects(career: .flexibleSchedule)),
        action(.buildCareerPortfolio, .cash, "Build a career portfolio", "Make your best work visible beyond the current employer.", influence: InfluenceVector(work: 2, stability: 1), text: "You gathered proof that can travel with you.", requirements: Requirement(minimumCash: 250, values: [.employed]), tags: ["Reputation+", "Skill+", "Cash−"], category: .career, domainEffects: DomainActionEffects(career: .buildCareerPortfolio)),
        action(.requestReference, .cash, "Request a reference", "Turn a working relationship into future credibility.", influence: InfluenceVector(work: 2), text: "You asked someone to put their name behind your work.", requirements: Requirement(values: [.employed]), tags: ["References+", "Reputation+"], category: .career, domainEffects: DomainActionEffects(career: .requestReference)),
        action(.testJobMarket, .cash, "Test the job market", "Learn what your current experience is worth before you need to leave.", influence: InfluenceVector(work: 2, risk: 1), text: "You looked around without promising to walk away.", requirements: Requirement(values: [.employed]), tags: ["Leverage+", "Options+"], category: .career, domainEffects: DomainActionEffects(career: .testJobMarket)),
        action(.specializeTechnical, .cash, "Deepen technical expertise", "Become harder to replace through focused capability.", influence: InfluenceVector(work: 3, stability: 1), text: "You chose to go deeper instead of merely moving upward.", requirements: Requirement(values: [.employed]), tags: ["Skill+", "Focus"], category: .career, domainEffects: DomainActionEffects(career: .specializeTechnical)),
        action(.specializeLeadership, .cash, "Develop as a people leader", "Build influence by carrying more of the team.", influence: InfluenceVector(work: 3, family: 1), text: "You chose to make other people's work better too.", requirements: Requirement(values: [.careerLevels([.established, .senior])]), tags: ["Leadership+", "Workload+"], category: .career, domainEffects: DomainActionEffects(career: .specializeLeadership)),
        action(.specializeClientTrust, .cash, "Build client trust", "Make relationships and reliability part of your professional value.", influence: InfluenceVector(work: 2, risk: 1), text: "You made trust the product people remembered.", requirements: Requirement(values: [.employed]), tags: ["Reputation+", "Leverage+"], category: .career, domainEffects: DomainActionEffects(career: .specializeClientTrust)),
        action(.negotiateBenefits, .cash, "Negotiate benefits", "Improve the terms that protect your life outside the paycheck.", influence: InfluenceVector(stability: 3), text: "You negotiated the rest of the offer, not just the number on the check.", requirements: Requirement(values: [.employed]), tags: ["Benefits+", "Leave+", "Leverage−"], category: .career, domainEffects: DomainActionEffects(career: .negotiateBenefits)),
        action(.usePaidLeave, .cash, "Use paid leave", "Spend earned time before exhaustion spends it for you.", influence: InfluenceVector(family: 2, stability: 2), text: "You used the time you had earned.", requirements: Requirement(values: [.employed, .careerPaidLeave(5)]), tags: ["Burnout−", "Workload−", "Leave−"], category: .career, domainEffects: DomainActionEffects(career: .usePaidLeave)),
        action(.mentorCoworker, .cash, "Mentor a coworker", "Make your value visible through someone else's growth.", influence: InfluenceVector(work: 2, family: 1), text: "You left someone better equipped, even though it added to your week.", requirements: Requirement(values: [.careerLevels([.established, .senior])]), tags: ["Mentorship+", "Reputation+", "Workload+"], category: .career, domainEffects: DomainActionEffects(career: .mentorCoworker)),
        action(.prepareRetirement, .cash, "Prepare for retirement", "Lower the shock of eventually leaving full-time work.", influence: InfluenceVector(stability: 3), text: "Retirement became a transition to prepare for, not a cliff to fall off.", requirements: Requirement(minimumAge: 55, values: [.employed]), tags: ["Readiness+", "Workload−"], category: .career, domainEffects: DomainActionEffects(career: .prepareRetirement)),
        action(.protectBoundaries, .cash, "Protect boundaries", "Keep the job from taking the whole week.", influence: InfluenceVector(stability: 3), text: "You let good-enough work remain good enough.", requirements: Requirement(values: [.careerLevels([.entry, .established, .senior])]), tags: ["Burnout−", "Performance−"], category: .career, domainEffects: DomainActionEffects(career: .boundaries)),
        action(.takePartTimeWork, .cash, "Move to part-time", "Trade income and progression speed for room elsewhere in life.", influence: InfluenceVector(family: 1, stability: 2), text: "You made work smaller on purpose.", requirements: Requirement(minimumAge: 18, values: [.careerLevels([.entry, .established, .senior]), .careerClass(.normal)]), tags: ["Part-time", "Income−", "Burnout−"], category: .career, domainEffects: DomainActionEffects(career: .partTime)),
        action(.pursueSpecialCareer, .cash, "Enter a Special career", "Turn a proven record or rare talent into a higher-variance career.", influence: InfluenceVector(work: 3, risk: 2), text: "The opening existed because your earlier work made it plausible.", requirements: Requirement(values: [.specialCareerEligible]), tags: ["Special", "Earned gate", "Risk"], category: .career, domainEffects: DomainActionEffects(career: .enterSpecial)),
        action(.buildDiamondCareer, .cash, "Build a Diamond career", "Risk $100,000 and a proven public career to build something larger than a job.", cash: -CareerPolicy.diamondCapitalThreshold ... -CareerPolicy.diamondCapitalThreshold, health: -4 ... -2, influence: InfluenceVector(work: 4, risk: 4), text: "You put your name, money, and private life behind an institution.", requirements: Requirement(values: [.diamondCareerEligible]), tags: ["Diamond", "$100K", "Legacy"], category: .career, domainEffects: DomainActionEffects(career: .enterDiamond)),
        // Phase 2 — household finance and housing
        action(.payDebt, .cash, "Pay debt", "Move cash against the most urgent balance.", influence: InfluenceVector(stability: 3), text: "The balance got smaller; your margin did too.", requirements: Requirement(minimumCash: 1, values: [.hasDebt]), tags: ["Debt−"], category: .money, domainEffects: DomainActionEffects(finance: .payDebt)),
        action(.adjustRetirement, .cash, "Adjust retirement", "Cycle saving through 0%, 5%, 10%, and 15%.", influence: InfluenceVector(stability: 2), text: "You moved money from now toward later.", requirements: Requirement(values: [.employed]), tags: ["Retirement"], category: .money, domainEffects: DomainActionEffects(finance: .retirement)),
        action(.buyHome, .cash, "Buy a home", "Use a down payment for stable housing.", influence: InfluenceVector(risk: 2, stability: 3), text: "You bought a place and a long obligation.", requirements: Requirement(minimumCash: 30000, values: [.housing([.renting]), .careerLevels([.entry, .established, .senior])]), tags: ["Equity", "Mortgage"], category: .housing, domainEffects: DomainActionEffects(finance: .buyHome)),
        action(.sellOrDownsize, .cash, "Sell / downsize", "Trade space and equity for breathing room.", influence: InfluenceVector(stability: 3), text: "You chose margin over square footage.", requirements: Requirement(values: [.housing([.owning, .delinquent])]), tags: ["Housing"], category: .housing, personalityImpulse: PersonalityImpulse(riskTolerance: -1, adaptability: 2), domainEffects: DomainActionEffects(finance: .sellOrDownsize)),
        // Phase 3 — relationship and family lifecycle
        action(.deepenCommitment, .love, "Commit", "Name the relationship you are building.", influence: InfluenceVector(family: 3), text: "You made the future part of the conversation.", requirements: Requirement(values: [.partner, .relationshipStages([.dating])]), tags: ["Partner"], category: .relationship, domainEffects: DomainActionEffects(family: .commit)),
        action(.marry, .love, "Marry", "Make a durable public commitment.", influence: InfluenceVector(family: 3, stability: 2), text: "You joined two lives without pretending that makes them easy.", requirements: Requirement(minimumCash: 8000, values: [.partner, .relationshipStages([.committed])]), tags: ["Partner", "Cash−"], category: .relationship, domainEffects: DomainActionEffects(family: .marry)),
        action(.separate, .love, "Separate", "End a relationship that cannot keep holding.", influence: InfluenceVector(risk: 2), text: "You ended the shared version of the future.", requirements: Requirement(values: [.partner]), tags: ["Major"], category: .relationship, personalityImpulse: PersonalityImpulse(empathy: -1, riskTolerance: 2, adaptability: 3), domainEffects: DomainActionEffects(family: .separate)),
        action(.chooseChildfree, .love, "Choose childfree", "Build a full life without parenthood.", influence: InfluenceVector(family: 2, stability: 2), text: "You made the absence of parenthood an intentional future.", requirements: Requirement(values: [.partner, .relationshipStages([.committed, .married]), .familyIntention([.openToChildren, .buildingFamily]), .noChildren]), tags: ["Family path"], category: .family, domainEffects: DomainActionEffects(family: .chooseChildfree)),
        action(.familyPlanning, .love, "Family planning", "Choose or advance an inclusive family path.", influence: InfluenceVector(family: 3), text: "You made family intention explicit.", requirements: Requirement(values: [.partner, .relationshipStages([.committed, .married])]), tags: ["Family"], category: .family, domainEffects: DomainActionEffects(family: .planFamily)),
        action(.parentingPresence, .love, "Be present", "Give dependent children undivided time.", influence: InfluenceVector(family: 3), text: "You showed up in a way a child can remember.", requirements: Requirement(values: [.hasDependents]), tags: ["Bond+"], category: .family, domainEffects: DomainActionEffects(family: .parent)),
        action(.caregiving, .love, "Caregive", "Support family through a difficult season.", influence: InfluenceVector(family: 3, stability: 1), text: "You carried part of what someone else could not.", requirements: Requirement(allowedStages: [.build, .pressure, .legacy]), tags: ["Family", "Health−"], category: .family, domainEffects: DomainActionEffects(family: .caregive)),
        // Phase 4 — conditions and aging
        action(.therapySupport, .health, "Therapy / support", "Get help for the mind carrying the life.", influence: InfluenceVector(stability: 2), text: "You stopped treating support like a private failure.", tags: ["Mental+", "Cash−"], category: .health, domainEffects: DomainActionEffects(health: .therapy)),
        action(.manageCondition, .health, "Manage condition", "Follow through on active care.", influence: InfluenceVector(stability: 3), text: "Management did not erase the condition; it gave you room.", requirements: Requirement(values: [.hasCondition]), tags: ["Condition"], category: .health, domainEffects: DomainActionEffects(health: .manage)),
        action(.preventiveCare, .health, "Preventive care", "Spend before a problem becomes a crisis.", influence: InfluenceVector(stability: 2), text: "You paid attention before your body demanded it.", tags: ["Physical+"], category: .health, domainEffects: DomainActionEffects(health: .preventive)),
        action(.cutBack, .health, "Cut back", "Reduce the habits that keep raising pressure.", influence: InfluenceVector(stability: 3), text: "You made the next urge smaller than the last one.", requirements: Requirement(values: [.any([.hasCondition, .minimumStat(.health, 0)])]), tags: ["Pressure−"], category: .health, domainEffects: DomainActionEffects(health: .cutBack))
    ]

    private static let byID: [ActionID: DomainAction] = {
        let indexed = Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })
        precondition(indexed.count == all.count, "DomainActionRegistry contains duplicate action IDs")
        precondition(Set(indexed.keys) == Set(ActionID.allCases), "DomainActionRegistry does not cover every ActionID")
        return indexed
    }()

    private static let byDomain: [Domain: [DomainAction]] =
        Dictionary(grouping: all, by: \.domain)

    static func action(for id: ActionID) -> DomainAction {
        guard let action = byID[id] else {
            preconditionFailure("Missing registered action: \(id.rawValue)")
        }
        return action
    }

    static func actions(in domain: Domain) -> [DomainAction] {
        byDomain[domain] ?? []
    }

    static func visibleActions(in domain: Domain, state: LifeState) -> [DomainAction] {
        actions(in: domain).filter {
            $0.id != .buyHome && $0.id != .sellOrDownsize
                && $0.requirements.isRelevant(in: state)
                && (state.lifeStage != .adolescence || isAdolescenceRelevant($0))
        }
    }

    static func isAdolescenceRelevant(_ action: DomainAction) -> Bool {
        [
            .focusGrades, .findYourPeople, .commitActivity, .helpAtHome,
            .reachOut, .seeFriends, .pursueHobby, .quietNight, .exercise, .rest
        ].contains(action.id)
    }

    static func staticCore(in domain: Domain) -> [DomainAction] {
        actions(in: domain).filter(\.isStaticCore)
    }

    private static func action(
        _ id: ActionID,
        _ domain: Domain,
        _ name: String,
        _ description: String,
        school: ClosedRange<Int> = 0...0,
        cash: ClosedRange<Int> = 0...0,
        love: ClosedRange<Int> = 0...0,
        play: ClosedRange<Int> = 0...0,
        health: ClosedRange<Int> = 0...0,
        looks: ClosedRange<Int> = 0...0,
        rep: ClosedRange<Int> = 0...0,
        influence: InfluenceVector = InfluenceVector(),
        partnerEffect: PartnerEffect = PartnerEffect(),
        text: String,
        requirements: Requirement = Requirement(),
        tags: [String] = [],
        beat: String = "",
        personalityBranches: [PersonalityBranch] = [],
        npcRole: NPCRole? = nil,
        npcBranches: [NPCPersonalityBranch] = [],
        isStaticCore: Bool = true,
        category: ActionCategory? = nil,
        personalityImpulse: PersonalityImpulse? = nil,
        domainEffects: DomainActionEffects? = nil
    ) -> DomainAction {
        DomainAction(
            id: id,
            domain: domain,
            category: category ?? defaultCategory(for: domain),
            name: name,
            shortDescription: description,
            requirements: requirements,
            effects: EffectRange(
                school: school,
                cash: cash,
                love: love,
                play: play,
                health: health,
                looks: looks,
                rep: rep,
                gainsPartner: id == .goOnDate,
                gainsJob: id == .applyForBetterWork || id == .sideHustle
            ),
            influence: influence,
            partnerEffect: partnerEffect,
            narrative: text,
            isStaticCore: isStaticCore,
            previewTags: tags,
            microBeat: beat.isEmpty ? text : beat,
            personalityBranches: personalityBranches,
            npcRole: npcRole,
            npcPersonalityBranches: npcBranches,
            personalityImpulse: personalityImpulse,
            domainEffects: domainEffects
        )
    }

    private static func defaultCategory(for domain: Domain) -> ActionCategory {
        switch domain {
        case .school: .career
        case .cash: .money
        case .love: .relationship
        case .play: .leisure
        case .health: .health
        }
    }

    private static func branch(_ id: String, _ flags: [PartnerFlag], bond: Int, resentment: Int, headline: String, narrative: String, hint: String) -> PersonalityBranch {
        PersonalityBranch(id: id, requiredFlags: flags, modifier: PartnerEffect(bond: bond, resentment: resentment), headline: headline, narrative: narrative, previewHint: hint, isLearned: false)
    }

    private static func learnedBranch(_ id: String, _ flag: PartnerFlag, bond: Int, resentment: Int, headline: String, narrative: String, hint: String) -> PersonalityBranch {
        PersonalityBranch(id: id, requiredFlags: [flag], modifier: PartnerEffect(bond: bond, resentment: resentment), headline: headline, narrative: narrative, previewHint: hint, isLearned: true)
    }

    private static func npcBranch(_ id: String, _ role: NPCRole, _ flags: [NPCFlag], school: Int = 0, cash: Int = 0, love: Int = 0, play: Int = 0, health: Int = 0, rep: Int = 0, rapport: Int, headline: String, narrative: String, hint: String) -> NPCPersonalityBranch {
        NPCPersonalityBranch(id: id, role: role, requiredFlags: flags, modifier: EffectRange(school: school...school, cash: cash...cash, love: love...love, play: play...play, health: health...health, rep: rep...rep), rapportDelta: rapport, headline: headline, narrative: narrative, previewHint: hint)
    }
}
