import Foundation

// MARK: - ChildhoodGenerationEngine
//
// Produces a ChildhoodDossier from an OriginTemplateID + player traits + region.
// Called by OriginSystem during makePreview. The dossier:
//   1. Generates a full prose backstory (the "Life Before" block shown in Preview)
//   2. Seeds a CareerAptitude profile — the hidden Career DNA at age 14
//   3. Flags early interests and a formative event for narrative use
//
// Design rules (per Codex III & VI):
//   - Pure logic engine. No UI concerns. No side effects.
//   - Deterministic when `deterministic: true` (for template previews).
//   - Each template has distinct aptitude biases that feel earned, not random.
//   - Aptitudes are tuned so the player rarely starts with a dominant axis above ~75
//     unless their trait also reinforces it — preventing trivial career unlocks.

struct ChildhoodGenerationEngine {

    // MARK: - Public Entry Point

    /// Generate a ChildhoodDossier for the given origin context.
    /// - Parameters:
    ///   - templateID: The origin template (background archetype).
    ///   - traits: Player's chosen personality traits — cross-amplify aptitudes.
    ///   - deterministic: If true, uses midpoint values instead of random ranges.
    func generate(
        templateID: OriginTemplateID,
        traits: [PersonalityTrait],
        deterministic: Bool = false
    ) -> ChildhoodDossier {
        var aptitudes = baseAptitudes(for: templateID, deterministic: deterministic)
        applyTraitAmplifiers(traits: traits, aptitudes: &aptitudes, deterministic: deterministic)
        aptitudes.clamp()

        let interests = earlyInterests(for: templateID, aptitudes: aptitudes)
        let formative = formativeEvent(for: templateID, deterministic: deterministic)
        let narrative = buildNarrative(for: templateID, aptitudes: aptitudes, deterministic: deterministic)
        let hints = aptitudes.visibleHints

        return ChildhoodDossier(
            narrative: narrative,
            aptitudes: aptitudes,
            earlyInterests: interests,
            formativeEvent: formative,
            visibleHints: hints
        )
    }

    // MARK: - Base Aptitudes per Template

    private func baseAptitudes(for templateID: OriginTemplateID, deterministic: Bool) -> CareerAptitude {
        var a = CareerAptitude()

        switch templateID {

        case .stableHomeAverageMeans:
            // Balanced baseline. Slight analytical and social boost — stable structure
            // produced a well-rounded but unremarkable childhood profile.
            a.analytical      = roll(50, range: 44...58, deterministic: deterministic)
            a.creative        = roll(48, range: 40...56, deterministic: deterministic)
            a.physical        = roll(48, range: 40...56, deterministic: deterministic)
            a.social          = roll(54, range: 48...62, deterministic: deterministic)
            a.entrepreneurial = roll(44, range: 36...52, deterministic: deterministic)
            a.technical       = roll(50, range: 42...58, deterministic: deterministic)

        case .financialStrainToughenedEarly:
            // High entrepreneurial — learned to hustle from necessity.
            // High social — charmed or navigated adults and peers to get by.
            // Low analytical — school came second to survival.
            a.analytical      = roll(42, range: 34...50, deterministic: deterministic)
            a.creative        = roll(46, range: 38...54, deterministic: deterministic)
            a.physical        = roll(52, range: 44...60, deterministic: deterministic)
            a.social          = roll(58, range: 50...66, deterministic: deterministic)
            a.entrepreneurial = roll(64, range: 56...72, deterministic: deterministic)
            a.technical       = roll(50, range: 42...58, deterministic: deterministic)

        case .academicPromise:
            // High analytical — school was identity.
            // High technical — logic-oriented environments compound this.
            // Low physical and entrepreneurial — life was study, not action.
            a.analytical      = roll(68, range: 60...76, deterministic: deterministic)
            a.creative        = roll(50, range: 42...58, deterministic: deterministic)
            a.physical        = roll(38, range: 30...46, deterministic: deterministic)
            a.social          = roll(48, range: 40...56, deterministic: deterministic)
            a.entrepreneurial = roll(38, range: 30...46, deterministic: deterministic)
            a.technical       = roll(62, range: 54...70, deterministic: deterministic)

        case .socialMagnet:
            // High social — people-reading was a superpower from day one.
            // High creative — expression followed natural magnetism.
            // Low analytical and technical — school was not the main stage.
            a.analytical      = roll(40, range: 32...48, deterministic: deterministic)
            a.creative        = roll(60, range: 52...68, deterministic: deterministic)
            a.physical        = roll(52, range: 44...60, deterministic: deterministic)
            a.social          = roll(70, range: 62...78, deterministic: deterministic)
            a.entrepreneurial = roll(54, range: 46...62, deterministic: deterministic)
            a.technical       = roll(38, range: 30...46, deterministic: deterministic)

        case .fragileHealthStart:
            // High creative — time alone during recovery fed imagination.
            // High analytical — learned to observe and research own condition.
            // Low physical — obvious. Low entrepreneurial — energy went to recovery.
            a.analytical      = roll(58, range: 50...66, deterministic: deterministic)
            a.creative        = roll(62, range: 54...70, deterministic: deterministic)
            a.physical        = roll(28, range: 20...36, deterministic: deterministic)
            a.social          = roll(50, range: 42...58, deterministic: deterministic)
            a.entrepreneurial = roll(38, range: 30...46, deterministic: deterministic)
            a.technical       = roll(54, range: 46...62, deterministic: deterministic)

        case .chaoticHomeSelfReliant:
            // High entrepreneurial — self-sufficiency was not a choice, it was survival.
            // High physical — did more adult physical tasks early.
            // High social — reading volatile adults became essential.
            // Low analytical — school was unstable. Low technical — no structured guidance.
            a.analytical      = roll(40, range: 32...48, deterministic: deterministic)
            a.creative        = roll(50, range: 42...58, deterministic: deterministic)
            a.physical        = roll(60, range: 52...68, deterministic: deterministic)
            a.social          = roll(62, range: 54...70, deterministic: deterministic)
            a.entrepreneurial = roll(68, range: 60...76, deterministic: deterministic)
            a.technical       = roll(44, range: 36...52, deterministic: deterministic)

        case .luckyBreak:
            // Broadly competent — things going right meant no single coping axis dominated.
            // One random axis gets a meaningful bonus: the "lucky gift."
            a.analytical      = roll(52, range: 44...60, deterministic: deterministic)
            a.creative        = roll(52, range: 44...60, deterministic: deterministic)
            a.physical        = roll(52, range: 44...60, deterministic: deterministic)
            a.social          = roll(54, range: 46...62, deterministic: deterministic)
            a.entrepreneurial = roll(52, range: 44...60, deterministic: deterministic)
            a.technical       = roll(52, range: 44...60, deterministic: deterministic)
            applyLuckyGift(to: &a, deterministic: deterministic)
        case .ruralEscapist:
            a.analytical      = roll(48, range: 40...56, deterministic: deterministic)
            a.creative        = roll(44, range: 36...52, deterministic: deterministic)
            a.physical        = roll(65, range: 58...72, deterministic: deterministic)
            a.social          = roll(45, range: 38...52, deterministic: deterministic)
            a.entrepreneurial = roll(50, range: 42...58, deterministic: deterministic)
            a.technical       = roll(58, range: 50...66, deterministic: deterministic)
        case .techProdigy:
            a.analytical      = roll(65, range: 58...72, deterministic: deterministic)
            a.creative        = roll(48, range: 40...56, deterministic: deterministic)
            a.physical        = roll(32, range: 24...40, deterministic: deterministic)
            a.social          = roll(35, range: 28...42, deterministic: deterministic)
            a.entrepreneurial = roll(55, range: 46...64, deterministic: deterministic)
            a.technical       = roll(72, range: 64...80, deterministic: deterministic)
        case .artisticDrifter:
            a.analytical      = roll(42, range: 34...50, deterministic: deterministic)
            a.creative        = roll(75, range: 68...82, deterministic: deterministic)
            a.physical        = roll(48, range: 40...56, deterministic: deterministic)
            a.social          = roll(60, range: 52...68, deterministic: deterministic)
            a.entrepreneurial = roll(40, range: 32...48, deterministic: deterministic)
            a.technical       = roll(38, range: 30...46, deterministic: deterministic)
        case .wealthyDynasty, .academicLegacy:
            a.analytical      = roll(58, range: 50...66, deterministic: deterministic)
            a.creative        = roll(52, range: 44...60, deterministic: deterministic)
            a.physical        = roll(40, range: 32...48, deterministic: deterministic)
            a.social          = roll(62, range: 54...70, deterministic: deterministic)
            a.entrepreneurial = roll(50, range: 42...58, deterministic: deterministic)
            a.technical       = roll(54, range: 46...62, deterministic: deterministic)
        }

        return a
    }

    /// Adds a meaningful aptitude spike to one random axis — the "Lucky Break" signature gift.
    private func applyLuckyGift(to a: inout CareerAptitude, deterministic: Bool) {
        let bonus = roll(18, range: 14...22, deterministic: deterministic)
        if deterministic {
            a.analytical += bonus
            return
        }
        let pick = Int.random(in: 0...5)
        switch pick {
        case 0: a.analytical      += bonus
        case 1: a.creative        += bonus
        case 2: a.physical        += bonus
        case 3: a.social          += bonus
        case 4: a.entrepreneurial += bonus
        default: a.technical      += bonus
        }
    }

    // MARK: - Trait Amplifiers

    /// Personality traits cross-amplify certain aptitude axes.
    /// A trait adds a small-to-moderate bonus; it can push an axis from decent to strong
    /// but can't single-handedly create a dominant axis from a weak template base.
    private func applyTraitAmplifiers(
        traits: [PersonalityTrait],
        aptitudes: inout CareerAptitude,
        deterministic: Bool
    ) {
        for trait in traits {
            let bump = roll(8, range: 6...12, deterministic: deterministic)
            switch trait {
            case .disciplined:
                // Discipline feeds analytical and technical — sustained attention compounds.
                aptitudes.analytical += bump
                aptitudes.technical  += bump / 2
            case .impulsive:
                // Impulsivity feeds entrepreneurial and physical — action-first instinct.
                aptitudes.entrepreneurial += bump
                aptitudes.physical        += bump / 2
            case .charismatic:
                // Charisma feeds social and creative — expression and connection.
                aptitudes.social    += bump
                aptitudes.creative  += bump / 2
            case .anxious:
                // Anxiety feeds analytical — constant risk modelling.
                // Small creative lift — anxiety often channels into art.
                aptitudes.analytical += bump
                aptitudes.creative   += bump / 3
            case .lucky:
                // Lucky doesn't amplify any specific aptitude — but slightly lifts
                // entrepreneurial because lucky people take more swings.
                aptitudes.entrepreneurial += bump / 2
            case .manipulative:
                aptitudes.social += bump
                aptitudes.entrepreneurial += bump / 2
            case .coldBlooded:
                aptitudes.analytical += bump / 2
                aptitudes.entrepreneurial += bump
            case .visionary:
                aptitudes.creative += bump
                aptitudes.technical += bump / 2
            case .burnoutProne:
                aptitudes.creative += bump / 2
                aptitudes.analytical += bump / 2
            }
        }
    }

    // MARK: - Early Interests

    private func earlyInterests(for templateID: OriginTemplateID, aptitudes: CareerAptitude) -> [String] {
        // Base interests from template
        var interests: [String]
        switch templateID {
        case .stableHomeAverageMeans:     interests = ["reading", "sports", "school clubs"]
        case .financialStrainToughenedEarly: interests = ["side hustles", "street smarts", "community"]
        case .academicPromise:            interests = ["science", "math", "problem solving"]
        case .socialMagnet:               interests = ["people", "performance", "social dynamics"]
        case .fragileHealthStart:         interests = ["reading", "music", "creative writing"]
        case .chaoticHomeSelfReliant:     interests = ["independence", "survival skills", "self-reliance"]
        case .luckyBreak:                 interests = ["exploration", "chance", "trying new things"]
        case .wealthyDynasty:             interests = ["finance", "leadership", "golf"]
        case .academicLegacy:             interests = ["research", "debating", "philosophy"]
        case .ruralEscapist:              interests = ["nature", "handiwork", "survivalism"]
        case .techProdigy:                interests = ["coding", "gaming", "robotics"]
        case .artisticDrifter:            interests = ["sketching", "busking", "photography"]
        }

        // Append aptitude-driven secondary interests
        if aptitudes.physical >= 62  { interests.append("sport") }
        if aptitudes.creative >= 62  { interests.append("art or music") }
        if aptitudes.technical >= 62 { interests.append("tinkering and building") }
        if aptitudes.social >= 65    { interests.append("leadership") }

        return interests
    }

    // MARK: - Formative Events

    private func formativeEvent(for templateID: OriginTemplateID, deterministic: Bool) -> String {
        let pool: [String]
        switch templateID {
        case .stableHomeAverageMeans:
            pool = [
                "A camping trip your family took when you were nine is the memory you keep coming back to — nothing special happened, but you remember being content.",
                "You won a small school award in fifth grade. Adults made a bigger deal of it than you expected, and something quietly shifted in how you saw yourself.",
                "A summer with nothing to do and nowhere to be taught you more about yourself than any school year did."
            ]
        case .financialStrainToughenedEarly:
            pool = [
                "You found $40 on the street when you were ten and didn't tell anyone. You bought groceries. That was the first time money felt real and yours.",
                "You watched your parent get turned away for a loan once. You didn't fully understand it then, but you understood enough.",
                "At twelve you got a neighbor to pay you to mow their lawn. That feeling — making something from nothing — stuck."
            ]
        case .academicPromise:
            pool = [
                "You got a perfect score on a math test in fourth grade and a teacher said 'you should be a doctor someday.' You never forgot it, for better and worse.",
                "Winning a school science fair at eleven made adults treat you differently. You started performing for that version of yourself before you understood that's what you were doing.",
                "You read a book in sixth grade that answered a question you'd been carrying for years. You've been chasing that feeling since."
            ]
        case .socialMagnet:
            pool = [
                "You talked a group of kids into a scheme in third grade and it actually worked. Everyone listened without you asking them to. That was the moment.",
                "You realized at ten that you could read whether adults were lying to each other before they finished talking. It wasn't a skill you practiced. It was just there.",
                "You got invited to a birthday party you barely deserved to be at and ended up knowing everyone by the end of the night."
            ]
        case .fragileHealthStart:
            pool = [
                "A hospital stay at age eight — three nights, a bad diagnosis that turned out to be manageable — was when you first understood your body as something separate from your will.",
                "You missed your school's big event because of an episode you couldn't control. You lay in bed and read the whole weekend instead. You still remember what the book smelled like.",
                "A doctor explained your condition to you like you were smart enough to handle it. That respect shaped how you expected to be treated for years after."
            ]
        case .chaoticHomeSelfReliant:
            pool = [
                "There was a week at eleven when the adults in your house just weren't functioning. You fed yourself, got to school, and didn't fall apart. That week changed something.",
                "You packed a bag once at age nine, ready to leave — not that you had anywhere to go. You unpacked it after an hour. But you remembered knowing you could.",
                "You learned to read a room before you could read chapter books. It was how you stayed safe."
            ]
        case .luckyBreak:
            pool = [
                "You applied to a competitive summer program as a joke and got in. Everything that followed from that summer happened because of something that started as a dare.",
                "A stranger said something to you at eleven that you didn't fully understand until years later. When it clicked, it changed your entire frame.",
                "Something that should have hurt you didn't. You didn't know then that near misses build a different kind of confidence than wins do."
            ]
        case .wealthyDynasty:
            pool = [
                "You overheard a private conversation about a massive acquisition when you were twelve. That was the first time you realized that the world is just a series of negotiated deals.",
                "Your family took a private jet to a remote island. Looking down at the clouds, you felt a strange, quiet distance from the rest of the world that never quite went away.",
                "You saw your parent handle a crisis with a single phone call. It taught you that power isn't about being loud; it's about being connected."
            ]
        case .academicLegacy:
            pool = [
                "You spent your Saturdays in the university library while your parents worked. The smell of old paper and the quiet of deep focus felt more like home than your actual house.",
                "A Nobel laureate came to dinner when you were ten and asked for your opinion on a problem. That respect for your mind set the bar for everything after.",
                "You realized at eleven that you could learn anything if you just found the right source. That realization made the world feel small and manageable."
            ]
        case .ruralEscapist:
            pool = [
                "You spent a whole day tracking a fox through the snow when you were nine. You didn't catch it, but the patience you learned that day became your most reliable tool.",
                "Helping your neighbor rebuild their barn after a storm showed you that anything can be fixed if you have enough hands and enough time.",
                "The first time you climbed the highest ridge near your house and saw how far the world went, you realized that your town was just one small piece of something much bigger."
            ]
        case .techProdigy:
            pool = [
                "You built your first simple script at age ten to automate a repetitive task. Seeing the machine do the work for you felt like a secret superpower.",
                "An older mentor in an online forum treated you like a peer when they saw your code. That digital belonging mattered more than anything happening at school.",
                "You stayed up all night fixing a bug that had everyone else stumped. The moment it finally ran clean was the most alive you'd ever felt."
            ]
        case .artisticDrifter:
            pool = [
                "You saw a street performer in a city you were visiting and realized that you could make a living just by being yourself and being loud about it.",
                "A teacher told you your sketches were 'distracting,' so you started a secret mural in an abandoned lot. That defiance felt like the start of your real life.",
                "You heard a song that perfectly matched a feeling you didn't have a word for yet. You've been trying to recreate that resonance in everything you make since."
            ]
        }

        if deterministic { return pool[0] }
        return pool.randomElement() ?? pool[0]
    }

    // MARK: - Narrative Builder

    private func buildNarrative(
        for templateID: OriginTemplateID,
        aptitudes: CareerAptitude,
        deterministic: Bool
    ) -> String {
        let opening = narrativeOpening(for: templateID, deterministic: deterministic)
        let middle  = narrativeMiddle(for: templateID, aptitudes: aptitudes, deterministic: deterministic)
        let closing = narrativeClosing(for: templateID, deterministic: deterministic)
        return "\(opening) \(middle) \(closing)"
    }

    private func narrativeOpening(for templateID: OriginTemplateID, deterministic: Bool) -> String {
        let pool: [String]
        switch templateID {
        case .stableHomeAverageMeans:
            pool = [
                "Your childhood was the kind that doesn't make for a great story — which is its own kind of luck.",
                "You grew up in a home where the lights stayed on, dinner happened, and no one screamed too often.",
                "Nothing dramatic defined your early years. That absence of drama was itself a kind of inheritance."
            ]
        case .financialStrainToughenedEarly:
            pool = [
                "Money was the background noise of your entire childhood — not always loud, but always there.",
                "You learned the language of tight budgets before you learned cursive.",
                "Your household ran on improvisation and quiet sacrifice, and you absorbed both without being asked to."
            ]
        case .academicPromise:
            pool = [
                "School came easily to you, and adults decided early that meant something about your future.",
                "You were the kind of child teachers mentioned by name at parent meetings — a reputation that followed you whether you wanted it to or not.",
                "Your academic ability showed up early enough that it became part of how everyone around you saw you."
            ]
        case .socialMagnet:
            pool = [
                "People have always been drawn to you. Even as a child, you were the one kids told things to.",
                "You grew up in the middle of whatever was happening — not because you forced it, but because you naturally ended up there.",
                "Social dynamics were your native language. You were reading the room before you knew that's what you were doing."
            ]
        case .fragileHealthStart:
            pool = [
                "Your body was the first complicated thing you ever had to manage.",
                "Health has always been a variable in your life, not a given.",
                "You came up knowing something most kids your age didn't — that your body has its own agenda."
            ]
        case .chaoticHomeSelfReliant:
            pool = [
                "Your childhood didn't give you stability. It gave you adaptability, which turned out to be worth more in the long run.",
                "You grew up fast — not because you wanted to, but because the environment required it.",
                "Home was unpredictable enough that you learned self-reliance the way most kids learn to ride a bike: out of necessity."
            ]
        case .luckyBreak:
            pool = [
                "A few things in your early life broke your way when they easily could have gone the other direction.",
                "Your childhood wasn't perfect, but a handful of small lucky turns gave you runway most people don't get.",
                "You've been in situations that should have left you worse off. Somehow they didn't. That pattern started early."
            ]
        case .wealthyDynasty:
            pool = [
                "You grew up in a world of soft lighting and high walls, where 'no' was a word you mostly heard about other people.",
                "Your family name was a heavy piece of furniture you were expected to polish every day.",
                "Everything was provided for, which meant your only real job was to not embarrass the people providing it."
            ]
        case .academicLegacy:
            pool = [
                "The house was full of books and the assumption that you would read them all.",
                "Standardized tests weren't a challenge in your house; they were a baseline.",
                "You learned early that curiosity was good, but achievement was the only thing that actually counted."
            ]
        case .ruralEscapist:
            pool = [
                "You grew up where the sky was bigger than the town, and the trees knew more about you than your neighbors did.",
                "The world was made of tangible things — wood, dirt, cold water — and you learned to trust them before you trusted people.",
                "Life moved at the speed of the seasons, and you learned early how to wait for the right moment."
            ]
        case .techProdigy:
            pool = [
                "The first language you really understood was one that humans didn't speak to each other.",
                "You spent your childhood in a series of glowing rooms, building worlds that were cleaner and more logical than the real one.",
                "While other kids were playing outside, you were figuring out how to make the machine do exactly what you wanted."
            ]
        case .artisticDrifter:
            pool = [
                "You grew up in the gaps between the rules, always looking for a way to make the world look the way it felt.",
                "Your home was a series of temporary moods and half-finished projects, and you loved the mess of it.",
                "Structure always felt like an ill-fitting coat, and you spent your childhood trying to find a way to take it off."
            ]
        }
        if deterministic { return pool[0] }
        return pool.randomElement() ?? pool[0]
    }

    private func narrativeMiddle(
        for templateID: OriginTemplateID,
        aptitudes: CareerAptitude,
        deterministic: Bool
    ) -> String {
        // Middle section is aptitude-reactive: what was noticed about them
        let dominantAxis = findDominantAxis(in: aptitudes)
        let pool: [String]

        switch dominantAxis {
        case "analytical":
            pool = [
                "Teachers noticed your attention to detail and the way you'd sit with a problem longer than other kids.",
                "You were the one who actually read the instructions. Not because you were told to — it just made sense to you.",
                "Patterns came naturally. You'd notice things in a situation that others walked right past."
            ]
        case "creative":
            pool = [
                "You filled notebooks before you knew what to do with them.",
                "You were the one who always had a different way of seeing the same thing everyone else saw.",
                "Expression — in whatever form you found it — was where you felt most like yourself."
            ]
        case "physical":
            pool = [
                "Your body was your most reliable resource — you used it constantly and it rarely let you down.",
                "You were always moving. Sport, work, play — you didn't sit still by choice.",
                "Physical confidence came early, and it shaped how you carried yourself around everyone else."
            ]
        case "social":
            pool = [
                "You learned early that the right word at the right moment could change the temperature of a room.",
                "You were the one who noticed when someone was off before they said anything. That skill became part of how you moved through the world.",
                "People came to you with their problems. You didn't ask them to. It just happened."
            ]
        case "entrepreneurial":
            pool = [
                "You were always finding angles — ways to make things work when the obvious route was blocked.",
                "You had side schemes before you had a job. Some worked. All of them taught you something.",
                "You understood early that rules are a framework, not a ceiling."
            ]
        default: // technical
            pool = [
                "You were drawn to how things worked — taking apart, rebuilding, figuring out the mechanism behind the surface.",
                "If something broke near you, you were the one who tried to fix it. Sometimes you could.",
                "You had a natural patience for systems — the kind of focus that lets you stay with a problem until you crack it."
            ]
        }

        if deterministic { return pool[0] }
        return pool.randomElement() ?? pool[0]
    }

    private func narrativeClosing(for templateID: OriginTemplateID, deterministic: Bool) -> String {
        let pool: [String]
        switch templateID {
        case .stableHomeAverageMeans:
            pool = [
                "You're starting at 14 with no dramatic backstory — just a solid enough foundation to build something, or waste, on your own terms.",
                "The advantage is you start steady. The risk is you start comfortable.",
                "You arrive at 14 with no particular wounds and no particular advantages beyond the ones you've earned."
            ]
        case .financialStrainToughenedEarly:
            pool = [
                "You start at 14 already knowing what it feels like to want something and wait for it. That's not nothing.",
                "You arrive at 14 with grit that hasn't been tested yet the way it's about to be.",
                "You're starting from behind financially. You're starting ahead in ways the money doesn't measure."
            ]
        case .academicPromise:
            pool = [
                "You arrive at 14 carrying both a head start and an expectation. Which one matters more is still being decided.",
                "You've got the tools. Whether you use them or coast on them is the first real question.",
                "You're smarter than average and you know it. Knowing what to do with that is the harder part."
            ]
        case .socialMagnet:
            pool = [
                "You start at 14 with more social capital than most — and less certainty about what to spend it on.",
                "The connections are real. Whether they become something lasting or just noise depends on what you do next.",
                "You arrive knowing how to work a room. You're still learning what a room is actually for."
            ]
        case .fragileHealthStart:
            pool = [
                "At 14, your body is still the variable it's always been. You've just gotten better at reading it.",
                "You start with fewer physical reserves but a sharpness about your own limits that most people take decades to develop.",
                "You arrive knowing more about resilience than most 14-year-olds. You didn't ask to learn it that way."
            ]
        case .chaoticHomeSelfReliant:
            pool = [
                "You start at 14 tougher than you should have needed to be. That toughness is real. So is the cost of it.",
                "You're self-sufficient in ways that will matter. You're also carrying weight that's not yours to carry.",
                "You arrive at 14 independent and a little tired of it. The next chapter is the first one where independence is a choice."
            ]
        case .luckyBreak:
            pool = [
                "You arrive at 14 with momentum you didn't entirely earn — which means you owe it to yourself to use it.",
                "The runway is real. What you build on it is still entirely open.",
                "You start with wind at your back. It won't last forever. The question is how far you get while it's there."
            ]
        case .wealthyDynasty:
            pool = [
                "You start at 14 with a safety net that most people can't even imagine. Use it well.",
                "The resources are yours, but the reputation is still on loan. The next chapter is where you make it your own.",
                "You arrive at 14 with every door already open. Your only job is to figure out which one to walk through."
            ]
        case .academicLegacy:
            pool = [
                "You start at 14 with the best tools money and discipline can provide. The expectation is now your baseline.",
                "The head start is massive. Whether you use it to lead or just to hide is up to you.",
                "You arrive at 14 already knowing how to learn. Now you just have to figure out what's worth knowing."
            ]
        case .ruralEscapist:
            pool = [
                "You start at 14 with a perspective that city kids don't have. It's your quiet advantage.",
                "The connection to the land is real. Whether it keeps you there or gives you a base to leave from is the question.",
                "You arrive at 14 with grit and a sense of scale. The world is big, but you know your place in it."
            ]
        case .techProdigy:
            pool = [
                "You start at 14 with a technical edge that puts you years ahead of your peers. Use the head start.",
                "The machine is your tool. The world is just the environment you run it in.",
                "You arrive at 14 already building the future. Now you just have to live in it."
            ]
        case .artisticDrifter:
            pool = [
                "You start at 14 with a restlessness that will either build something beautiful or burn everything down.",
                "The creative spark is lit. Keeping it alive is the work of the next decade.",
                "You arrive at 14 untethered and ready to move. The map is empty, and that's exactly how you like it."
            ]
        }
        if deterministic { return pool[0] }
        return pool.randomElement() ?? pool[0]
    }

    // MARK: - Helpers

    private func roll(_ midpoint: Int, range: ClosedRange<Int>, deterministic: Bool) -> Int {
        deterministic ? midpoint : Int.random(in: range)
    }

    private func findDominantAxis(in aptitudes: CareerAptitude) -> String {
        let axes: [(String, Int)] = [
            ("analytical",      aptitudes.analytical),
            ("creative",        aptitudes.creative),
            ("physical",        aptitudes.physical),
            ("social",          aptitudes.social),
            ("entrepreneurial", aptitudes.entrepreneurial),
            ("technical",       aptitudes.technical)
        ]
        return axes.max(by: { $0.1 < $1.1 })?.0 ?? "analytical"
    }
}
