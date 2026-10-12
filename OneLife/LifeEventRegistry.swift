import Foundation

/// Yearly storylets — Voice: second-person present, concrete (Codex IV).
/// Weights are stage- and state-gated so decades feel different (chapter content).
enum LifeEventRegistry {
    private static let compact: [LifeEvent] = [
        // MARK: High School
        LifeEvent(
            id: "hallway-rumor",
            headline: "A Small Rumor Starts Sticking",
            detail: "Something ordinary gets repeated until people look at you as if they already know the whole story.",
            weight: { $0.lifeStage == .adolescence && $0.education.schoolBelonging < 58 ? 7 : 0 },
            choices: [
                choice(.talk, "Name it directly", "Risk making the hallway tension explicit.", love: -1 ... 0, education: EducationChoiceEffect(schoolBelonging: 4, teacherSupport: 2, schoolReputation: 5, memoryKind: .reputation, memorySignificance: 3, flagsToAdd: [.rumorScar]), relationship: .friend, rapport: 2, text: "The conversation is ugly, but the rumor loses the safety of silence."),
                choice(.decline, "Wait it out", "Keep your head down and hope attention moves.", play: 1...2, education: EducationChoiceEffect(schoolBelonging: -6, schoolReputation: -4, memoryKind: .reputation, memorySignificance: 2, flagsToAdd: [.rumorScar]), relationship: .friend, rapport: -2, text: "The attention eventually moves. What it changed in the room takes longer.")
            ]
        ),
        LifeEvent(
            id: "teacher-stays-late",
            headline: "A Teacher Stays Late For You",
            detail: "They notice you slipping and offer help after school without making a scene out of it.",
            weight: { $0.lifeStage == .adolescence && $0.education.academicStanding < 68 && $0.education.teacherSupport < 62 ? 8 : 0 },
            choices: [
                choice(.focus, "Stay and work", "Let an adult see where you are stuck.", health: -1 ... 0, education: EducationChoiceEffect(academicStanding: 6, teacherSupport: 9, futureReadiness: 3, memoryKind: .mentor, memorySignificance: 4, flagsToAdd: [.mentorBacked]), relationship: .teacher, rapport: 3, text: "The room empties. For once, asking for help does not feel like failing."),
                choice(.decline, "Say you are fine", "Protect yourself from being seen struggling.", play: 1...2, education: EducationChoiceEffect(academicStanding: -2, teacherSupport: -5, memoryKind: .setback, memorySignificance: 1), relationship: .teacher, rapport: -1, text: "You leave before they can ask twice. The unfinished work comes with you.")
            ]
        ),
        LifeEvent(
            id: "school-trip-cost",
            headline: "The Affordable Trip Is Not Affordable",
            detail: "Everyone calls the cost small. On your side of life, it still lands heavy.",
            weight: { $0.lifeStage == .adolescence && $0.cash < 22000 && $0.education.schoolBelonging < 70 ? 6 : 0 },
            choices: [
                choice(.accept, "Find the money", "Pay for the memory and absorb the strain.", cash: -4500 ... -3000, play: 2...4, education: EducationChoiceEffect(schoolBelonging: 5, memoryKind: .belonging, memorySignificance: 3, flagsToAdd: [.financiallyExcluded]), text: "You go. Nobody there sees the arithmetic it took."),
                choice(.decline, "Stay home", "Protect the household and miss the shared story.", cash: 1000...2000, education: EducationChoiceEffect(schoolBelonging: -5, futureReadiness: -1, memoryKind: .setback, memorySignificance: 3, flagsToAdd: [.financiallyExcluded]), text: "The photos arrive before everyone gets back. You recognize every face.")
            ]
        ),
        LifeEvent(
            id: "activity-tryout",
            headline: "Your Activity Starts Seeing You",
            detail: "The work after school becomes visible enough that someone asks whether you want a larger role.",
            weight: { $0.lifeStage == .adolescence && $0.education.activityStage == .joined ? 6 : 0 },
            choices: [
                choice(.accept, "Step forward", "Take the role and the extra hours.", health: -2 ... -1, education: EducationChoiceEffect(academicStanding: -1, schoolBelonging: 6, teacherSupport: 2, futureReadiness: 6, schoolReputation: 5, activityStage: .committed, memoryKind: .activity, memorySignificance: 3, flagsToAdd: [.activityIdentity]), relationship: .friend, rapport: 2, text: "Your name starts meaning something in one corner of the building."),
                choice(.decline, "Keep it casual", "Protect your time without disappearing.", play: 1...2, education: EducationChoiceEffect(schoolBelonging: 1, memoryKind: .activity, memorySignificance: 1), relationship: .friend, rapport: 1, text: "You stay part of it without letting it own the week.")
            ]
        ),
        LifeEvent(
            id: "friend-group-fracture",
            headline: "Your Friend Group Picks A Side",
            detail: "A fight inside the circle becomes public, and neutrality starts looking like betrayal to everyone.",
            weight: { $0.lifeStage == .adolescence && $0.character.age >= 15 && $0.education.schoolBelonging >= 45 ? 5 : 0 },
            choices: [
                choice(.talk, "Refuse the sides", "Tell both people what this is doing to the group.", love: 1...3, education: EducationChoiceEffect(schoolBelonging: 2, schoolReputation: 2, memoryKind: .belonging, memorySignificance: 3), relationship: .friend, rapport: 2, text: "Nobody loves the answer. One person respects it enough to stay."),
                choice(.accept, "Choose your person", "Protect one friendship and let another break.", love: -1 ... 1, education: EducationChoiceEffect(schoolBelonging: -3, schoolReputation: 3, memoryKind: .reputation, memorySignificance: 3), relationship: .friend, rapport: -2, text: "The hallway becomes easier to navigate and smaller at the same time.")
            ]
        ),
        LifeEvent(
            id: "recommendation-window",
            headline: "A Recommendation Is Within Reach",
            detail: "A teacher says your work could become a real opportunity if you ask directly and follow through.",
            weight: { $0.lifeStage == .adolescence && $0.character.age >= 17 && $0.education.academicStanding >= 68 && $0.education.teacherSupport >= 52 ? 9 : 0 },
            choices: [
                choice(.focus, "Ask for it", "Make your ambition visible.", health: -1 ... 0, education: EducationChoiceEffect(teacherSupport: 5, futureReadiness: 10, memoryKind: .mentor, memorySignificance: 5, flagsToAdd: [.recommendationEarned]), relationship: .teacher, rapport: 3, text: "You ask without apologizing. They agree because the record is already there."),
                choice(.decline, "Do not push", "Avoid the vulnerable ask.", play: 1...2, education: EducationChoiceEffect(teacherSupport: -1, futureReadiness: -4, memoryKind: .setback, memorySignificance: 2), relationship: .teacher, rapport: -1, text: "The window does not slam. It simply gets harder to find again.")
            ]
        ),
        LifeEvent(
            id: "freshman-lunch-table",
            headline: "The Lunchroom Has Its Own Map",
            detail: "Every open seat seems to carry rules nobody bothered to explain.",
            weight: { $0.character.age == 14 ? 7 : 0 },
            choices: [
                choice(.accept, "Take the open seat", "Risk an awkward introduction.", love: 1...3, education: EducationChoiceEffect(schoolBelonging: 6, schoolReputation: 1, memoryKind: .belonging, memorySignificance: 3), relationship: .friend, rapport: 3, text: "The conversation stumbles, then makes room for tomorrow."),
                choice(.decline, "Eat somewhere quiet", "Protect yourself from the room.", play: 1...2, education: EducationChoiceEffect(schoolBelonging: -3, memoryKind: .belonging, memorySignificance: 2), relationship: .friend, rapport: -1, text: "The quiet helps today and makes the room feel larger next time.")
            ]
        ),
        LifeEvent(
            id: "bullying-line-crossed",
            headline: "A Joke Finally Crosses The Line",
            detail: "The laughter keeps going after everyone understands who is paying for it.",
            weight: { $0.character.age <= 16 && $0.education.schoolBelonging < 58 ? 6 : 0 },
            choices: [
                choice(.talk, "Call it what it is", "Make the cruelty visible.", health: -1...0, education: EducationChoiceEffect(schoolBelonging: 3, teacherSupport: 2, schoolReputation: 4, memoryKind: .reputation, memorySignificance: 4), relationship: .friend, rapport: 2, text: "The room goes cold. The joke does not survive being named."),
                choice(.decline, "Get through the day", "Spend no more energy there.", health: 1...2, education: EducationChoiceEffect(schoolBelonging: -4, schoolReputation: -2, memoryKind: .setback, memorySignificance: 3), relationship: .friend, rapport: -2, text: "You make it home. The words arrive there before you do.")
            ]
        ),
        LifeEvent(
            id: "sophomore-name-sticks",
            headline: "A Version Of You Starts Sticking",
            detail: "People repeat one story until it begins introducing you before you speak.",
            weight: { $0.character.age == 15 ? 7 : 0 },
            choices: [
                choice(.talk, "Complicate the story", "Let people see something else.", love: 1...2, education: EducationChoiceEffect(schoolBelonging: 2, schoolReputation: 4, memoryKind: .reputation, memorySignificance: 3), relationship: .friend, rapport: 2, text: "The old label survives, but it stops being the whole sentence."),
                choice(.accept, "Wear the label", "Use the attention while it helps.", play: 1...3, education: EducationChoiceEffect(futureReadiness: -1, schoolReputation: 6, memoryKind: .reputation, memorySignificance: 3), relationship: .friend, rapport: 1, text: "The role opens doors and starts deciding which doors you notice.")
            ]
        ),
        LifeEvent(
            id: "school-date-invitation",
            headline: "Someone Asks You Out After School",
            detail: "The invitation is casual enough to deny and serious enough to change Monday.",
            weight: { $0.character.age >= 15 && $0.education.schoolBelonging >= 42 ? 5 : 0 },
            choices: [
                choice(.accept, "Say yes", "Let the hallway become personal.", love: 2...4, play: 1...2, education: EducationChoiceEffect(schoolBelonging: 2, schoolReputation: 2, memoryKind: .belonging, memorySignificance: 3), relationship: .friend, rapport: 2, text: "It is awkward, brief, and real enough to remember."),
                choice(.decline, "Keep it friendly", "Protect the friendship and your attention.", love: 0...1, education: EducationChoiceEffect(schoolReputation: 1, memoryKind: .belonging, memorySignificance: 1), relationship: .friend, rapport: 1, text: "The answer lands gently. Monday remains recognizable.")
            ]
        ),
        LifeEvent(
            id: "discipline-office",
            headline: "The Office Wants Your Side Today",
            detail: "A hallway incident reaches the adults as a cleaner story than it really was.",
            weight: { $0.character.age >= 15 && $0.education.schoolReputation < 48 ? 5 : 0 },
            choices: [
                choice(.talk, "Tell the full version", "Risk sounding difficult to be accurate.", education: EducationChoiceEffect(teacherSupport: 3, schoolReputation: 2, memoryKind: .reputation, memorySignificance: 3), relationship: .teacher, rapport: 2, text: "The consequence stays smaller because somebody finally hears the missing half."),
                choice(.accept, "Take the consequence", "End the meeting without another fight.", play: -1...0, education: EducationChoiceEffect(teacherSupport: -2, schoolReputation: -4, memoryKind: .setback, memorySignificance: 3), relationship: .teacher, rapport: -2, text: "The file gets a simple answer. Your memory keeps the complicated one.")
            ]
        ),
        LifeEvent(
            id: "junior-future-pressure",
            headline: "Everyone Suddenly Asks What Comes Next",
            detail: "Adults turn every grade and interest into evidence about a life you have not lived.",
            weight: { $0.character.age == 16 ? 8 : 0 },
            choices: [
                choice(.focus, "Build one real plan", "Choose direction without pretending certainty.", health: -1...0, education: EducationChoiceEffect(teacherSupport: 3, futureReadiness: 8, memoryKind: .mentor, memorySignificance: 3), relationship: .teacher, rapport: 2, text: "The future stays large, but one next step becomes specific."),
                choice(.decline, "Refuse the script", "Protect room to change your mind.", play: 1...2, education: EducationChoiceEffect(schoolBelonging: 2, futureReadiness: -2, memoryKind: .reputation, memorySignificance: 2), text: "The questions keep coming. You stop treating every answer like a promise.")
            ]
        ),
        LifeEvent(
            id: "part-time-school-week",
            headline: "Your Shift Starts Owning School Nights",
            detail: "The paycheck matters. So do the assignments waiting after closing.",
            weight: { $0.character.age >= 16 && $0.cash < 26000 ? 6 : 0 },
            choices: [
                choice(.chooseWork, "Keep every shift", "Protect the money and absorb the fatigue.", cash: 3500...5500, health: -2 ... -1, education: EducationChoiceEffect(academicStanding: -4, futureReadiness: 2, memoryKind: .responsibility, memorySignificance: 4, flagsToAdd: [.carriedHomeLoad]), text: "The account improves. Your notes become something you read standing up."),
                choice(.negotiate, "Ask for one night", "Risk fewer hours to save some capacity.", cash: 1500...2500, education: EducationChoiceEffect(academicStanding: 2, teacherSupport: 1, memoryKind: .responsibility, memorySignificance: 3), text: "The schedule bends just enough to keep both lives possible.")
            ]
        ),
        LifeEvent(
            id: "family-needs-school-hours",
            headline: "Home Needs Hours School Already Claimed",
            detail: "A family need arrives during a week with no empty space left.",
            weight: { $0.education.commitmentYears[.home, default: 0] > 0 ? 6 : 0 },
            choices: [
                choice(.prioritizeFamily, "Carry it at home", "Let school see only the absence.", love: 1...3, health: -2 ... -1, education: EducationChoiceEffect(academicStanding: -4, schoolBelonging: -2, memoryKind: .responsibility, memorySignificance: 5, flagsToAdd: [.carriedHomeLoad]), text: "The household gets through the week because you did not get to be only a student."),
                choice(.negotiate, "Share the load", "Ask everyone to carry a visible piece.", love: -1...1, education: EducationChoiceEffect(teacherSupport: 2, futureReadiness: 2, memoryKind: .responsibility, memorySignificance: 3), text: "Nobody gets everything they wanted. You remain in the week.")
            ]
        ),
        LifeEvent(
            id: "activity-injury",
            headline: "An Injury Changes Your Activity Role",
            detail: "The thing that gave the week structure suddenly asks you to watch from the edge.",
            weight: { $0.character.age >= 16 && ($0.education.activityStage == .joined || $0.education.activityStage == .committed) ? 4 : 0 },
            choices: [
                choice(.recover, "Recover without disappearing", "Stay involved while your body catches up.", health: 1...2, education: EducationChoiceEffect(schoolBelonging: 3, teacherSupport: 2, memoryKind: .activity, memorySignificance: 4), relationship: .teacher, rapport: 2, text: "You learn that belonging can survive a changed role."),
                choice(.decline, "Step away", "End the activity before it defines the year.", health: 2...3, education: EducationChoiceEffect(schoolBelonging: -3, activityStage: .ended, memoryKind: .setback, memorySignificance: 4), relationship: .friend, rapport: -1, text: "The evenings open. The empty place in them takes longer.")
            ]
        ),
        LifeEvent(
            id: "academic-burnout-week",
            headline: "Your Good Grades Stop Feeling Good",
            detail: "The work is still getting done. You are less certain where you went inside it.",
            weight: { $0.education.commitmentYears[.academics, default: 0] >= 2 && $0.education.academicStanding >= 68 ? 5 : 0 },
            choices: [
                choice(.recover, "Lower the pressure", "Protect enough energy to remain yourself.", health: 2...3, education: EducationChoiceEffect(academicStanding: -2, schoolBelonging: 2, memoryKind: .setback, memorySignificance: 4, flagsToAdd: [.academicBurnout]), text: "One grade softens. The week starts belonging to you again."),
                choice(.focus, "Keep the standard", "Finish what the transcript expects.", health: -3 ... -2, education: EducationChoiceEffect(academicStanding: 4, futureReadiness: 2, memoryKind: .setback, memorySignificance: 5, flagsToAdd: [.academicBurnout]), text: "The result is excellent. You feel almost nothing when it arrives.")
            ]
        ),
        LifeEvent(
            id: "activity-leadership",
            headline: "The Activity Needs Someone To Lead",
            detail: "People already look toward you when plans become uncertain.",
            weight: { $0.character.age >= 16 && $0.education.activityStage == .committed ? 6 : 0 },
            choices: [
                choice(.accept, "Take the lead", "Carry the visibility and the extra work.", health: -2 ... -1, education: EducationChoiceEffect(schoolBelonging: 4, futureReadiness: 6, schoolReputation: 6, activityStage: .leader, memoryKind: .activity, memorySignificance: 5, flagsToAdd: [.activityIdentity]), relationship: .friend, rapport: 3, text: "The activity becomes part of how the school remembers your name."),
                choice(.decline, "Stay part of it", "Keep the activity without owning everyone else's week.", play: 1...2, education: EducationChoiceEffect(schoolBelonging: 2, memoryKind: .activity, memorySignificance: 2), relationship: .friend, rapport: 1, text: "You remain reliable without turning the whole thing into a test.")
            ]
        ),
        LifeEvent(
            id: "activity-pushed-out",
            headline: "Your Place In The Activity Narrows",
            detail: "A decision made elsewhere leaves you with fewer hours and no clean explanation.",
            weight: { ($0.education.activityStage == .joined || $0.education.activityStage == .committed) && $0.education.schoolBelonging < 44 ? 4 : 0 },
            choices: [
                choice(.talk, "Ask to stay", "Make them explain the decision directly.", education: EducationChoiceEffect(schoolBelonging: 2, schoolReputation: 2, memoryKind: .activity, memorySignificance: 3), relationship: .teacher, rapport: 2, text: "The role remains smaller, but it no longer disappears without a conversation."),
                choice(.decline, "Let it end", "Keep your dignity and leave the room.", play: 1...2, education: EducationChoiceEffect(schoolBelonging: -3, activityStage: .ended, memoryKind: .setback, memorySignificance: 4), relationship: .friend, rapport: -2, text: "You stop showing up. The building notices less than you hoped.")
            ]
        ),
        LifeEvent(
            id: "prom-cost",
            headline: "Prom Costs More Than The Ticket",
            detail: "The night everyone calls essential comes with clothes, transport, and money nobody mentions.",
            weight: { $0.character.age == 17 && $0.cash < 28000 ? 6 : 0 },
            choices: [
                choice(.accept, "Make the night happen", "Pay for one shared ending.", cash: -5500 ... -3500, play: 3...5, education: EducationChoiceEffect(schoolBelonging: 4, memoryKind: .ending, memorySignificance: 4, flagsToAdd: [.financiallyExcluded]), relationship: .friend, rapport: 2, text: "The night is imperfect, loud, and yours."),
                choice(.decline, "Skip the performance", "Keep the money and choose a quieter ending.", cash: 1000...2000, education: EducationChoiceEffect(schoolBelonging: -2, memoryKind: .ending, memorySignificance: 3, flagsToAdd: [.financiallyExcluded]), relationship: .friend, rapport: -1, text: "The pictures arrive before midnight. Your ending happens somewhere else.")
            ]
        ),
        LifeEvent(
            id: "senior-last-night",
            headline: "The Last School Night Arrives Quietly",
            detail: "The familiar building is about to become a place you can only return to.",
            weight: { $0.character.age == 17 ? 8 : 0 },
            choices: [
                choice(.accept, "Show up fully", "Let the ending matter while it is here.", love: 1...3, play: 2...3, education: EducationChoiceEffect(schoolBelonging: 4, futureReadiness: 2, memoryKind: .ending, memorySignificance: 5, flagsToAdd: [.sociallyRooted]), relationship: .friend, rapport: 3, text: "For one night, nobody has to pretend the ending is ordinary."),
                choice(.decline, "Leave without ceremony", "Protect what comes next from the goodbye.", health: 1...2, education: EducationChoiceEffect(futureReadiness: 3, memoryKind: .ending, memorySignificance: 4), text: "You walk out before the room turns sentimental. It follows anyway.")
            ]
        ),
        // MARK: Launch
        LifeEvent(
            id: "college-first-weeks",
            headline: "College Does Not Feel Like Home",
            detail: "The map is readable. The social rules and the pace are not yet yours.",
            weight: { $0.education.college.isEnrolled && $0.education.college.yearsEnrolled == 1 ? 7 : 0 },
            choices: [
                choice(.accept, "Stay after class", "Let repeated faces become familiar.", love: 1...3, education: EducationChoiceEffect(campusBelonging: 7), text: "One conversation becomes a place to sit next week."),
                choice(.focus, "Protect the coursework", "Keep the opening weeks narrow.", school: 1...3, play: -1...0, education: EducationChoiceEffect(collegeStanding: 3, campusBelonging: -2), text: "The work gets clearer before the campus does.")
            ]
        ),
        LifeEvent(
            id: "college-aid-gap",
            headline: "The Aid Package Leaves A Gap",
            detail: "A fee that looked covered reaches your account with a deadline attached.",
            weight: { $0.education.college.isEnrolled && $0.cash < 18000 ? 6 : 0 },
            choices: [
                choice(.accept, "Cover the gap", "Use cash to keep the schedule intact.", cash: -3500 ... -2500, health: -1...0, education: EducationChoiceEffect(collegeStanding: 2), text: "The balance clears. The rest of the month gets smaller."),
                choice(.negotiate, "Ask for emergency aid", "Make the need visible.", rep: -1...1, education: EducationChoiceEffect(campusBelonging: 2), text: "The answer is partial, but it keeps the door open."),
                choice(.focus, "Take work-study", "Trade free hours for a smaller gap.", cash: 1500...2500, health: -2 ... -1, education: EducationChoiceEffect(collegeStanding: -1, campusBelonging: 2), text: "The campus starts paying for hours it used to simply consume.")
            ]
        ),
        LifeEvent(
            id: "college-major-doubt",
            headline: "Your Major Stops Feeling Certain",
            detail: "The classes are passable. The future attached to them feels harder to picture.",
            weight: { $0.education.college.isEnrolled && $0.education.college.credits >= 4 && $0.education.college.campusBelonging < 50 ? 5 : 0 },
            choices: [
                choice(.talk, "Talk to an advisor", "Separate exhaustion from a real mismatch.", health: 1...2, education: EducationChoiceEffect(collegeStanding: 2, campusBelonging: 3), text: "The conversation does not choose for you. It makes the uncertainty specific."),
                choice(.decline, "Keep moving", "Protect the credits already earned.", school: 1...2, health: -1...0, text: "You stay on the track and leave the question running beside it.")
            ]
        ),
        LifeEvent(
            id: "college-internship-opening",
            headline: "A Real Workplace Notices You",
            detail: "A short placement could turn the field on your transcript into people who remember your work.",
            weight: { $0.education.college.isEnrolled && $0.education.college.credits >= 6 && $0.education.college.academicStanding >= 60 ? 7 : 0 },
            choices: [
                choice(.focus, "Take the placement", "Trade recovery time for experience.", cash: 1500...3000, health: -2 ... -1, rep: 2...4, education: EducationChoiceEffect(collegeStanding: 2), text: "The work is less tidy than class and more useful for being real."),
                choice(.decline, "Protect the semester", "Keep the load survivable.", play: 1...2, health: 1...2, text: "You keep the week intact. The opening belongs to someone else.")
            ]
        ),
        LifeEvent(
            id: "mentor-referral",
            headline: "A Teacher Remembers Your Work",
            detail: "An opening reaches you through someone who still remembers what you did when nobody was grading it.",
            weight: { $0.lifeStage == .launch ? EducationSystem.legacyModifiers(for: $0).mentorEventWeight + EducationSystem.legacyModifiers(for: $0).mentorAvailability : 0 },
            choices: [
                choice(.focus, "Follow the lead", "Use the introduction and prepare well.", rep: 2...4, text: "The name gets you a hearing. What happens next is yours."),
                choice(.decline, "Leave it alone", "Keep the old connection out of your adult life.", play: 1...2, text: "You let the message sit until it becomes history again.")
            ]
        ),
        LifeEvent(
            id: "second-chance-application",
            headline: "A Second Door Opens Quietly",
            detail: "A program weighs what you can do now instead of how cleanly school ended.",
            weight: { $0.lifeStage == .launch ? EducationSystem.legacyModifiers(for: $0).secondChanceEventWeight + EducationSystem.legacyModifiers(for: $0).recoveryResilience : 0 },
            choices: [
                choice(.focus, "Make the case", "Submit the imperfect record anyway.", school: 2...4, health: -1...0, text: "The application asks for the past. You answer with the present."),
                choice(.decline, "Wait for certainty", "Avoid another possible rejection.", play: 1...2, text: "The deadline passes without proving you wrong or right.")
            ]
        ),
        LifeEvent(
            id: "school-reunion",
            headline: "An Old Friend Finds You",
            detail: "A familiar name appears with an invitation that is warmer and stranger than memory.",
            weight: { $0.lifeStage == .launch && ($0.education.legacyFlags.contains(.sociallyRooted) || $0.education.legacyFlags.contains(.activityIdentity)) ? 5 : 0 },
            choices: [
                choice(.accept, "Show up", "Meet who both of you became.", love: 1...3, text: "The old shorthand returns, changed enough to breathe."),
                choice(.decline, "Keep moving", "Let that version of you stay finished.", play: 1...2, text: "You wish them well without reopening the room.")
            ]
        ),
        LifeEvent(
            id: "old-rumor-resurfaces",
            headline: "The Old Story Finds You",
            detail: "Someone repeats a school rumor as if time made it harmless.",
            weight: { $0.lifeStage == .launch && $0.education.legacyFlags.contains(.rumorScar) ? 5 : 0 },
            choices: [
                choice(.talk, "Correct the record", "Refuse to laugh along.", health: -1...0, rep: 1...2, text: "The room gets awkward. The story finally belongs to you."),
                choice(.decline, "Let it die there", "Spend no more life defending an old self.", health: 1...2, text: "You leave it without carrying it home.")
            ]
        ),
        LifeEvent(
            id: "family-obligation-follows",
            headline: "Home Still Needs Your Hands",
            detail: "The responsibility you practiced in school now arrives during an adult week already full.",
            weight: { $0.lifeStage == .launch ? EducationSystem.legacyModifiers(for: $0).familyObligationEventWeight + EducationSystem.legacyModifiers(for: $0).familyObligationPressure : 0 },
            choices: [
                choice(.prioritizeFamily, "Carry it again", "Protect the household at a cost to your week.", love: 1...3, health: -2 ... -1, text: "You know exactly how to hold the weight. That does not make it light."),
                choice(.negotiate, "Set a limit", "Help without becoming the entire plan.", love: -1...1, health: 1...2, text: "The boundary disappoints someone and preserves something in you.")
            ]
        ),
        LifeEvent(
            id: "application-insecurity",
            headline: "The Application Feels Like School",
            detail: "One blank box makes every old grade and empty lunch table feel current again.",
            weight: { $0.lifeStage == .launch && ($0.education.legacyFlags.contains(.academicBurnout) || $0.education.schoolBelonging < 40) ? 5 : 0 },
            choices: [
                choice(.focus, "Send it anyway", "Let adulthood judge the person here now.", health: -1...0, rep: 1...3, text: "You submit before confidence arrives."),
                choice(.decline, "Close the tab", "Protect yourself from being measured today.", play: 1...2, text: "Relief comes first. The doubt stays open.")
            ]
        ),
        LifeEvent(
            id: "school-pressure",
            headline: "The Midterm Stack Hits",
            detail: "Three deadlines land the same week. Your notes are a mess of half-underlined paragraphs.",
            weight: { $0.flags.attendsSchool && $0.stats.school < 48 ? 8 : 0 },
            choices: [
                choice(.focus, "Lock in", "Clear the calendar and grind.", school: 6...8, health: -3 ... -1, text: "You close the tabs. The stack shrinks."),
                choice(.decline, "Let two slide", "Save your body for now.", school: -5 ... -3, play: 2...3, text: "You sleep. The grades will say what you already know.")
            ]
        ),
        LifeEvent(
            id: "first-rent-scare",
            headline: "Rent Is Due Tomorrow",
            detail: "The portal shows $1,120. You have $640 and a text from your roommate that just says \"?\"",
            weight: { $0.lifeStage == .launch && $0.cash < 20000 ? 7 : ($0.lifeStage == .launch && $0.cash < 35000 ? 3 : 0) },
            choices: [
                choice(.accept, "Cover it now", "Drain what you have.", cash: -12000 ... -8000, health: -1 ... 0, text: "The payment clears. Your account looks hollow."),
                choice(.decline, "Ask for three days", "Trade pride for runway.", cash: 2000...4000, love: -2 ... -1, text: "They grant it. You feel the weight of the favor.")
            ]
        ),
        LifeEvent(
            id: "friend-group-split",
            headline: "Your Group Chat Goes Quiet",
            detail: "Two friends plan a trip without you. The screenshots land in your lap at 11:40 p.m.",
            weight: { $0.lifeStage == .launch && $0.stats.love < 55 ? 5 : 0 },
            choices: [
                choice(.talk, "Call it out", "Say the silence hurt.", love: 3...5, play: -1 ... 0, text: "The call is awkward. One of them actually apologizes."),
                choice(.decline, "Let it cool", "Do not make it a scene.", love: -4 ... -2, play: 1...2, text: "You leave the chat on mute. The distance hardens a little.")
            ]
        ),

        // MARK: Build
        LifeEvent(
            id: "cash-opening",
            headline: "A Better Shift Opens",
            detail: "Your lead texts: \"Need someone reliable on the better crew. You in?\" The hours are longer. The pay is real.",
            weight: { $0.lifeStage == .build && $0.education.credential && $0.stats.school >= 55 ? 6 : ($0.lifeStage == .build && $0.stats.school >= 60 ? 3 : 0) },
            choices: [
                choice(.accept, "Take it", "Commit to the heavier load.", cash: 12000...17000, health: -3 ... -1, text: "The extra responsibility buys breathing room and steals sleep."),
                choice(.decline, "Pass", "Keep your current pace.", play: 2...3, text: "You protect your nights. The opening closes behind someone else.")
            ]
        ),
        LifeEvent(
            id: "move-in-question",
            headline: "They Ask About Keys",
            detail: "Over leftovers, your partner says: \"We already live like this. Should we make it official?\"",
            weight: { $0.lifeStage == .build && $0.partner != nil && ($0.partner?.bond ?? 0) >= 60 ? 6 : 0 },
            choices: [
                choice(.accept, "Say yes", "Share the lease and the risk.", cash: -4000 ... -2000, love: 4...6, text: "You put both names on something that matters."),
                choice(.decline, "Not yet", "Keep separate doors for now.", love: -4 ... -2, play: 1...2, text: "Honesty keeps the air clear — and a little colder.")
            ]
        ),
        LifeEvent(
            id: "promotion-or-plateau",
            headline: "Your Name Is On The List",
            detail: "HR posts an internal role one rung up. The posting closes Friday. Your current desk already owns your evenings.",
            weight: { ($0.lifeStage == .build || $0.lifeStage == .pressure) && ($0.job.tier == .entry || $0.job.tier == .skilled) && $0.stats.school >= 50 ? 5 : 0 },
            choices: [
                choice(.focus, "Go for it", "Spend the week proving you.", school: 2...4, health: -3 ... -1, rep: 1...3, text: "You stay late. Someone notices. The interview is real."),
                choice(.decline, "Stay put", "Protect what already works.", play: 2...3, health: 1...2, text: "You keep the known load. Ambition waits in the hallway.")
            ]
        ),

        // MARK: Pressure
        LifeEvent(
            id: "burnout-weekend",
            headline: "Your Weekend Disappears",
            detail: "Saturday is already spoken for by errands, inbox, and a body that will not unclench.",
            weight: { ($0.lifeStage == .pressure || $0.stats.health < 50 || $0.stats.play < 42) ? ($0.lifeStage == .pressure ? 8 : 6) : 0 },
            choices: [
                choice(.recover, "Cancel everything", "Choose rest on purpose.", cash: -1500 ... -1000, play: 3...5, health: 8...11, text: "A quieter weekend gets you back under yourself."),
                choice(.focus, "Push through", "Keep the pace.", cash: 4000...6500, health: -7 ... -4, text: "You get more done. Monday still arrives angry.")
            ]
        ),
        LifeEvent(
            id: "skilled-work-setback",
            headline: "A Mistake Hits Your Name",
            detail: "The client email is polite and brutal. Your boss forwards it with one line: \"Walk me through this.\"",
            weight: { $0.job.tier == .skilled && ($0.lifeStage == .build || $0.lifeStage == .pressure) ? 6 : 0 },
            choices: [
                choice(.focus, "Own the fix", "Stay until it holds.", school: 2...4, health: -3 ... -1, text: "You stay with the problem until the patch is honest."),
                choice(.decline, "Deflect it", "Protect your pride for now.", cash: -9000 ... -4500, love: -2 ... 0, text: "The cost shows up later in quieter ways.")
            ]
        ),
        LifeEvent(
            id: "relationship-audit",
            headline: "They Want A Real Conversation",
            detail: "The dishes are done. The TV is off. \"We need to talk about what this life is actually becoming.\"",
            weight: { $0.lifeStage == .pressure && $0.partner != nil && (($0.partner?.resentment ?? 0) >= 35 || ($0.partner?.bond ?? 100) < 55) ? 7 : 0 },
            choices: [
                choice(.talk, "Stay in the room", "Tell the truth carefully.", love: 4...6, health: -1 ... 0, text: "You do not polish it. Something between you loosens."),
                choice(.decline, "Postpone it", "Claim you are too fried.", love: -5 ... -3, play: 1...2, text: "They nod. The silence afterward is thicker.")
            ]
        ),
        LifeEvent(
            id: "midlife-health-scare",
            headline: "The Clinic Leaves A Voicemail",
            detail: "\"Please call us back about your results.\" Your pulse is already answering.",
            weight: { $0.lifeStage == .pressure && $0.stats.health < 55 ? 6 : ($0.lifeStage == .legacy && $0.stats.health < 60 ? 4 : 0) },
            choices: [
                choice(.recover, "Book the follow-up", "Pay attention now.", cash: -7000 ... -4000, health: 8...12, text: "You sit in the plastic chair and deal with it."),
                choice(.decline, "Wait a week", "Tell yourself it is nothing.", play: -1 ... 0, health: -6 ... -3, text: "The week does not make it quieter.")
            ]
        ),

        // MARK: Legacy
        LifeEvent(
            id: "health-reset",
            headline: "A Small Warning Lands",
            detail: "The doctor does not raise their voice. They just slide the sheet across: numbers you cannot ignore.",
            weight: { $0.lifeStage == .legacy ? ($0.stats.health < 60 ? 8 : 3) : ($0.stats.health < 55 ? 5 : 0) },
            choices: [
                choice(.recover, "Take it seriously", "Book care and follow through.", cash: -5000 ... -3000, health: 9...12, text: "You deal with it before it becomes a crisis with a siren."),
                choice(.decline, "Wait it out", "Hope the numbers move alone.", health: -5 ... -2, text: "It lingers longer than you wanted.")
            ]
        ),
        LifeEvent(
            id: "who-you-still-call",
            headline: "Your Phone Feels Heavy",
            detail: "Sunday afternoon. You scroll names and realize how few of them would still pick up on the first ring.",
            weight: { $0.lifeStage == .legacy ? 6 : 0 },
            choices: [
                choice(.talk, "Call someone real", "Risk the awkward warmth.", love: 4...7, play: 1...2, text: "They pick up. The conversation is ordinary and necessary."),
                choice(.decline, "Put it down", "Keep the quiet intact.", love: -2 ... 0, health: -1 ... 0, text: "The silence is familiar. It does not comfort.")
            ]
        ),
        LifeEvent(
            id: "one-more-year-work",
            headline: "They Offer One More Year",
            detail: "A part-time contract. Familiar badge. Less money than before, more structure than retirement.",
            weight: { $0.lifeStage == .legacy && ($0.job.tier == .retired || $0.job.tier == .unemployed) ? 5 : 0 },
            choices: [
                choice(.accept, "Take the year", "Trade ease for a paycheck.", cash: 8000...13000, health: -3 ... -1, text: "You put the badge back on. Mondays return."),
                choice(.decline, "Protect the calendar", "Keep the open days.", play: 3...5, health: 2...4, text: "You leave the offer on the table. The week stays yours.")
            ]
        ),

        // MARK: Cross-domain collisions
        LifeEvent(
            id: "work-followed-home",
            headline: "Work Followed You Through The Door",
            detail: "Dinner is cooling beside an inbox you promised not to open. Your partner watches the screen light your face again.",
            weight: {
                guard $0.partner != nil, $0.job.tier.isEmployed else { return 0 }
                return $0.influenceLedger.current.work >= 3 || $0.aggregates.yearsWorked >= 8 ? 5 : 0
            },
            choices: [
                choice(.talk, "Put it away", "Give the evening back to both of you.", play: 1...2, bond: 3, resentment: -3, text: "You turn the phone face down. The room slowly becomes yours again."),
                choice(.focus, "Finish the work", "Buy tomorrow with tonight.", cash: 3500...6000, health: -3 ... -1, bond: -3, resentment: 4, text: "The task gets done. Your partner stops waiting for your attention.")
            ]
        ),
        LifeEvent(
            id: "money-between-you",
            headline: "Money Sat Down Between You",
            detail: "A routine bill becomes an argument about risk, trust, and who has been quietly carrying more.",
            weight: { $0.partner != nil && $0.cash < 9000 ? 6 : 0 },
            choices: [
                choice(.talk, "Open the books", "Make the problem shared and specific.", health: -1 ... 0, bond: 3, resentment: -4, text: "The numbers are uncomfortable. At least the silence is no longer hiding them."),
                choice(.decline, "Win the argument", "Defend your choices and end the conversation.", love: -3 ... -1, bond: -4, resentment: 5, text: "You get the last word. It costs more than the bill did.")
            ]
        ),
        LifeEvent(
            id: "body-collected-overtime",
            headline: "Your Body Collected The Overtime",
            detail: "A familiar ache stops leaving overnight. The schedule still expects the version of you who could ignore it.",
            weight: {
                let worked = $0.aggregates.yearsWorked
                return worked >= 10 && $0.stats.health < 50 ? ($0.lifeStage == .pressure ? 7 : 5) : 0
            },
            choices: [
                choice(.recover, "Take the leave", "Lose income before you lose capacity.", cash: -7000 ... -4000, play: 1...2, health: 7...10, text: "You step away before your body makes the decision for you."),
                choice(.focus, "Power through", "Keep the paycheck and absorb the warning.", cash: 6000...9000, health: -8 ... -5, text: "The deposit clears. The pain learns your schedule.")
            ]
        ),
        LifeEvent(
            id: "friendships-went-quiet",
            headline: "Your Friendships Went Quiet Slowly",
            detail: "You realize the last three conversations were calendar logistics, favors, or work. Nobody asked how you were.",
            weight: {
                let worked = $0.aggregates.yearsWorked
                return $0.partner == nil && worked >= 6 && ($0.stats.love < 45 || $0.stats.play < 35) ? 5 : 0
            },
            choices: [
                choice(.talk, "Call someone", "Risk being the one who reaches first.", love: 5...7, play: 1...3, text: "The first minute is awkward. Then it sounds like a friendship again."),
                choice(.decline, "Keep it transactional", "Stay efficient and leave the silence alone.", cash: 2000...3500, love: -4 ... -2, text: "The week stays productive. Your contact list feels even longer and emptier.")
            ]
        ),

        // MARK: Always-possible pressure valves
        LifeEvent(
            id: "financial-recovery",
            headline: "A Recovery Shift Appears",
            detail: "Someone needs a body for a brutal short stretch. The cash is ugly and useful.",
            weight: { $0.cash < 5000 ? 7 : 0 },
            choices: [
                choice(.accept, "Take the shift", "Trade a hard month for runway.", cash: 10000...15000, health: -3 ... -1, text: "The immediate pressure eases. Your back files a complaint."),
                choice(.decline, "Protect your health", "Pass on the extra strain.", health: 3...5, text: "You choose capacity over a quick fix.")
            ]
        )
    ]

    static let all: [LifeEvent] = compact + EssentialStoryletRegistry.all

    private static func choice(
        _ id: EventChoiceID,
        _ title: String,
        _ detail: String,
        school: ClosedRange<Int> = 0...0,
        cash: ClosedRange<Int> = 0...0,
        love: ClosedRange<Int> = 0...0,
        play: ClosedRange<Int> = 0...0,
        health: ClosedRange<Int> = 0...0,
        rep: ClosedRange<Int> = 0...0,
        bond: Int = 0,
        resentment: Int = 0,
        education: EducationChoiceEffect? = nil,
        relationship: SimulationRole? = nil,
        rapport: Int? = nil,
        text: String
    ) -> EventChoice {
        EventChoice(
            id: id,
            title: title,
            detail: detail,
            effects: EffectRange(school: school, cash: cash, love: love, play: play, health: health, rep: rep),
            partnerEffect: PartnerEffect(bond: bond, resentment: resentment),
            narrative: text,
            educationEffect: education,
            relationshipRole: relationship,
            npcRapportDelta: rapport
        )
    }
}

// MARK: - Narrative selection and flavor

/// Owns seeded storylet selection, anti-repeat weighting, social context, Echo,
/// and state-derived vibe. The simulator only asks for the next narrative beat.
enum NarrativeEventSystem {
    static func select(state: inout LifeState) -> LifeEvent? {
        let bundled = BundledLifeContentRegistry.pack.events.map { $0.lifeEvent(for: state) }
        let candidates = (LifeEventRegistry.all + bundled)
            .filter { SituationStoryletPolicy.allows(eventID: $0.id, state: state) }
            .map { event -> (LifeEvent, Int) in
                var weight = max(0, event.weight(state))
                if BundledLifeContentRegistry.eventIDs.contains(event.id) {
                    let count = state.aggregates.personalityPivotalEvents
                    let lastAge = state.aggregates.lastPersonalityPivotalAge
                    if count >= 6 || state.character.age - lastAge < 3 {
                        weight = 0
                    } else if count < 3, weight > 0 {
                        weight = min(100, weight + 3)
                    }
                }
                weight = TalentSystem.eventWeight(eventID: event.id, baseWeight: weight, state: state)
                switch state.lifeStage {
                case .adolescence:
                    weight = EducationSystem.schoolEventWeight(eventID: event.id, baseWeight: weight, state: state)
                case .launch:
                    if ["school-pressure", "first-rent-scare", "friend-group-split", "mentor-referral", "second-chance-application", "school-reunion", "old-rumor-resurfaces", "family-obligation-follows", "application-insecurity", "college-first-weeks", "college-aid-gap", "college-major-doubt", "college-internship-opening"].contains(event.id) { weight += 2 }
                case .build:
                    if ["cash-opening", "move-in-question", "promotion-or-plateau"].contains(event.id) { weight += 2 }
                case .pressure:
                    if ["burnout-weekend", "skilled-work-setback", "relationship-audit", "midlife-health-scare"].contains(event.id) { weight += 2 }
                case .legacy:
                    if ["health-reset", "who-you-still-call", "one-more-year-work"].contains(event.id) { weight += 3 }
                    if event.id == "school-pressure" || event.id == "first-rent-scare" { weight = 0 }
                }
                if state.recentEventIDs.first(where: { id in LifeEventRegistry.all.contains { $0.id == id } }) == event.id {
                    weight = 0
                } else if state.recentEventIDs.contains(event.id) {
                    weight = max(1, weight / 4)
                }
                return (event, weight)
            }
            .filter { $0.1 > 0 }

        let total = candidates.reduce(0) { $0 + $1.1 }
        guard total > 0 else { return nil }
        let quietBias = state.momentum.shape == .careful
            || state.momentum.intensity == 0
            || (state.lifeStage == .legacy && state.mortalityPressure == .stable)
        if quietBias, state.randomStreams.event.next(in: 1...100) > 50 {
            return nil
        }

        var roll = state.randomStreams.event.next(in: 1...total)
        for (event, weight) in candidates {
            roll -= weight
            if roll <= 0 { return flavor(event, state: &state) }
        }
        return candidates.last.map { flavor($0.0, state: &state) }
    }

    private static func flavor(_ event: LifeEvent, state: inout LifeState) -> LifeEvent {
        var socialSystem = SocialReactivitySystem()
        var flavored = socialSystem.contextualize(event, state: &state)
        if let echo = EchoFlavorResolver.line(state: state) {
            flavored = LifeEvent(
                id: flavored.id,
                headline: flavored.headline,
                detail: "\(echo) \(flavored.detail)",
                weight: flavored.weight,
                choices: flavored.choices
            )
        }
        return LifeEvent(
            id: flavored.id,
            headline: flavored.headline,
            detail: NarrativeVibeResolver.flavor(flavored.detail, state: state),
            weight: flavored.weight,
            choices: flavored.choices
        )
    }
}

// MARK: - Echo (Codex IV)

enum EchoFlavorResolver {
    /// One-line memory of recent focus — prepended to yearly beats when present.
    static func line(state: LifeState) -> String? {
        if let actionID = state.influenceLedger.recentYears.first?.influentialAction {
            let name = DomainActionRegistry.action(for: actionID).name.lowercased()
            return "You're still living with how hard you pushed to \(name)."
        }
        if state.character.age >= 18, let memory = state.education.frozenDefiningMemory {
            return "School still echoes: \(memory.headline.lowercased())."
        }
        if state.character.age >= 18, let flag = [
            SchoolLegacyFlag.recommendationEarned, .mentorBacked, .carriedHomeLoad,
            .rumorScar, .financiallyExcluded, .activityIdentity, .academicBurnout, .sociallyRooted
        ].first(where: state.education.legacyFlags.contains) {
            switch flag {
            case .recommendationEarned, .mentorBacked:
                return "Someone from school still remembers what you could become."
            case .carriedHomeLoad:
                return "You learned to carry a household before anyone called you grown."
            case .rumorScar:
                return "An old hallway story still sharpens your sense of the room."
            case .financiallyExcluded:
                return "You still notice the price hidden inside every invitation."
            case .activityIdentity, .sociallyRooted:
                return "One place you belonged at school still follows you."
            case .academicBurnout:
                return "Old achievement pressure still knows how to sound urgent."
            }
        }
        if state.aggregates.yearsWorked >= 12 {
            return "Years of showing up for work still sit in your posture."
        }
        if let partner = state.partner, partner.neglectStreak >= 2 {
            return "Home has been counting your absences."
        }
        return nil
    }
}
