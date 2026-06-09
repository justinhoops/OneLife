import Foundation

struct ActionChoiceDefinition: Equatable {
    var choiceID: ActionChoiceID
    var title: String
    var subtitle: String
    var detail: String = ""
    var identityLine: String
    var previewTags: [String]
    var preferredEventTags: [String: Int] = [:]
    
    // Friction & Micro-Beats
    var microBeat: String = "You make your move."
    var baseFriction: ActionFrictionLevel = .none
}

enum ActionChoiceCatalog {
    static func definition(for choiceID: ActionChoiceID) -> ActionChoiceDefinition {
        switch choiceID {
        case .studyHard:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Bury Yourself In The Work", subtitle: "Trade ease for standing.", identityLine: "You decide effort matters more than comfort this year.", previewTags: ["Standing", "Support", "Mood cost"], preferredEventTags: ["school": 7, "routine": 4], microBeat: "The library lights are humming.", baseFriction: .resistance)
        case .studyConsistently:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Disappear Into Your Schoolwork", subtitle: "Build slow, reliable traction.", identityLine: "You choose discipline over drama and let consistency define the year.", previewTags: ["Standing", "Readiness", "Burnout down"], preferredEventTags: ["school": 8, "routine": 5], microBeat: "One page at a time.", baseFriction: .none)
        case .cramAndSurvive:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Hold It Together At The Last Minute", subtitle: "Results now, recovery later.", identityLine: "You decide to survive the pressure rather than solve it cleanly.", previewTags: ["Standing", "Burnout", "Recovery loss"], preferredEventTags: ["school": 6, "health": 2], microBeat: "Your eyes are stinging.", baseFriction: .resistance)
        case .lockInRoutine:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Lock Into A Routine", subtitle: "Make structure your shield.", identityLine: "You want the year to feel controlled, even if it gets smaller.", previewTags: ["Standing", "Pressure down", "Teacher support"], preferredEventTags: ["routine": 6, "school": 5, "health": 2], microBeat: "The clock is your only friend.", baseFriction: .none)
        case .joinActivity:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Step Into Something Bigger", subtitle: "Choose visibility and structure.", identityLine: "You decide belonging is worth the risk of being seen.", previewTags: ["Belonging", "Momentum", "+Friends"], preferredEventTags: ["school": 4, "social": 6], microBeat: "Deep breath. Walk in.", baseFriction: .none)
        case .joinClub:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Put Yourself Out There", subtitle: "Try belonging on purpose.", identityLine: "You make a deliberate move toward people instead of waiting to be chosen.", previewTags: ["Belonging", "Mentor shot", "Friends"], preferredEventTags: ["social": 7, "school": 4], microBeat: "Scanning the room.", baseFriction: .none)
        case .buildPortfolio:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Build Toward The Exit", subtitle: "Turn effort into options.", identityLine: "You treat this year like a proving ground for whatever comes next.", previewTags: ["Readiness", "Future fit", "Free time"], preferredEventTags: ["career": 5, "school": 5], microBeat: "Stacking the deck.", baseFriction: .none)
        case .layLow:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Keep Your Head Down", subtitle: "Reduce exposure, not tension.", identityLine: "You decide staying out of sight is safer than reaching for more.", previewTags: ["Pressure down", "Exposure down", "Momentum loss"], preferredEventTags: ["routine": 3, "health": 3], microBeat: "Stay invisible.", baseFriction: .none)
        case .skipClass:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Walk Away From The Day", subtitle: "Short relief, long memory.", identityLine: "You choose immediate breathing room and accept that school may remember it.", previewTags: ["Relief", "Rumor risk", "Support loss"], preferredEventTags: ["school": 5, "risk": 5, "social": 3], microBeat: "The door clicks shut behind you.", baseFriction: .none)
        case .skipAndDrift:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Let The Year Slide", subtitle: "Stop pushing and see what breaks.", identityLine: "You stop fighting the drift and let the consequences catch up later.", previewTags: ["Relief", "Standing down", "Momentum loss"], preferredEventTags: ["school": 5, "risk": 3, "health": 2], microBeat: "Watching the ceiling.", baseFriction: .none)
        case .keepThePeace:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Smooth The Edges", subtitle: "Stability over ambition.", identityLine: "You spend the year avoiding conflict instead of chasing momentum.", previewTags: ["Drama down", "Belonging down", "Stability"], preferredEventTags: ["social": 4, "routine": 3], microBeat: "Just nod and smile.", baseFriction: .none)
        // Teen 2 precursors
        case .teenAthleticDrill:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Athletic Drill", subtitle: "Push the body, build the future.", identityLine: "You treat after-school sweat like an investment in a version of yourself that performs.", previewTags: ["Momentum", "Body", "Athlete seed"], preferredEventTags: ["school": 4, "health": 6], microBeat: "Lungs burning in a good way.", baseFriction: .resistance)
        case .teenSideHustle:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Side Hustle", subtitle: "Turn spare time into edge.", identityLine: "You decide small money and small reputation now will compound into options later.", previewTags: ["Cash", "Readiness", "Founder seed"], preferredEventTags: ["finance": 5, "school": 3, "chance": 4], microBeat: "Counting small wins.", baseFriction: .none)
        case .teenCreativeProject:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Creative Project", subtitle: "Make something that is yours.", identityLine: "You spend real hours on work that might never be graded but feels like the real thing.", previewTags: ["Voice", "Belonging", "Creator seed"], preferredEventTags: ["school": 3, "social": 5, "creative": 6], microBeat: "The idea won't leave you alone.", baseFriction: .none)
        case .teenLeadInitiative:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Lead Initiative", subtitle: "Step up and be counted.", identityLine: "You organize something that requires other people to trust you. The taste of it is addictive.", previewTags: ["Presence", "Support", "Politics seed"], preferredEventTags: ["social": 7, "school": 4], microBeat: "People are looking at you.", baseFriction: .none)
        case .teenRiskyExperiment:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Risky Experiment", subtitle: "See what you can get away with.", identityLine: "You test a boundary because the safe version of the year feels too small.", previewTags: ["Heat", "Network", "Crime seed"], preferredEventTags: ["risk": 7, "money": 4, "school": 2], microBeat: "Adrenaline and second thoughts.", baseFriction: .warning)
        case .workHard:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Lean Into The Grind", subtitle: "Push for traction.", identityLine: "You decide this year should move forward even if your body complains.", previewTags: ["Performance", "Mental cost"], preferredEventTags: ["career": 8, "money": 3], microBeat: "The coffee is cold. Again.", baseFriction: .resistance)
        case .protectYourEnergy:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Protect Your Energy", subtitle: "Keep the job from eating the rest of you.", identityLine: "You decide your life has to remain livable, even if it slows your climb.", previewTags: ["Burnout down", "Health up", "Momentum softer"], preferredEventTags: ["health": 7, "routine": 5, "career": 2], microBeat: "Closing the laptop.", baseFriction: .none)
        case .network:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Work The Room", subtitle: "Visibility through people, not output alone.", identityLine: "You treat relationships as career infrastructure and accept the weirdness that comes with that.", previewTags: ["Promotion shot", "Contacts", "Authenticity cost"], preferredEventTags: ["career": 6, "social": 6, "chance": 3], microBeat: "Shake hands. Repeat.", baseFriction: .none)
        case .retrain:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Retrain For A Different Future", subtitle: "Pay now to stop repeating this version of work.", identityLine: "You decide this year should buy a new lane, not just survive the old one.", previewTags: ["Future fit", "Cash cost", "Short-term strain"], preferredEventTags: ["career": 7, "school": 4, "money": 3], microBeat: "Back to basics.", baseFriction: .resistance)
        case .takeOvertime:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Take Overtime", subtitle: "Push the margin harder.", identityLine: "You decide money needs to move now, even if the rest of life gets tighter.", previewTags: ["Cash up", "Burnout", "Relationship cost"], preferredEventTags: ["money": 8, "career": 5, "health": 3], microBeat: "One more hour. Then another.", baseFriction: .resistance)
        case .coast:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Phone It In", subtitle: "Stay employed, not invested.", identityLine: "You stop pretending work deserves your best energy this year.", previewTags: ["Ease", "Performance loss", "Drift"], preferredEventTags: ["routine": 3, "career": 2, "health": 2], microBeat: "Doing the minimum.", baseFriction: .none)
        case .jobHunt:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Go Looking For A Better Door", subtitle: "Trade certainty for possibility.", identityLine: "You decide your current setup is not enough and start reaching outward.", previewTags: ["Cash shot", "Work shot"], preferredEventTags: ["career": 7, "chance": 3], microBeat: "Refreshing the inbox.", baseFriction: .none)
        case .chaseSpotlight:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Step Into The Spotlight", subtitle: "Visibility with volatility.", identityLine: "You want this year to notice you, even if it gets unstable fast.", previewTags: ["Fame shot", "Audience", "Stability loss"], preferredEventTags: ["career": 5, "social": 4, "risk": 5], microBeat: "All eyes on you.", baseFriction: .warning)
        case .startMovieActor:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Become Movie Actor", subtitle: "Audition for screen work.", identityLine: "You decide the camera is the room you want to survive in.", previewTags: ["Acting", "Auditions", "Fame shot"], preferredEventTags: ["career": 8, "fame": 5], microBeat: "The reader starts the scene.", baseFriction: .resistance)
        case .auditionRole:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Audition For Role", subtitle: "Chase the part.", identityLine: "You decide rejection is the price of being seen by the right room.", previewTags: ["Role shot", "Fame", "Burnout"], preferredEventTags: ["career": 8, "chance": 5, "fame": 5], microBeat: "Slate. Breath. Line.", baseFriction: .resistance)
        case .actingClass:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Take Acting Class", subtitle: "Build craft before attention.", identityLine: "You decide the work has to get better before the world gets louder.", previewTags: ["Craft +", "Range +", "Cash cost"], preferredEventTags: ["career": 7, "routine": 4], microBeat: "Again, but honest this time.", baseFriction: .none)
        case .buildActingReel:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Build Acting Reel", subtitle: "Package the proof.", identityLine: "You decide talent needs evidence people can watch in two minutes.", previewTags: ["Auditions +", "Visibility", "Cash cost"], preferredEventTags: ["career": 7, "fame": 3], microBeat: "The best takes survive.", baseFriction: .none)
        case .takeIndieRole:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Take Indie Role", subtitle: "Trade money for credits.", identityLine: "You decide a strange little film might teach you more than waiting.", previewTags: ["Credits +", "Craft", "Low pay"], preferredEventTags: ["career": 7, "creative": 5], microBeat: "Tiny crew. Real work.", baseFriction: .none)
        case .managePublicist:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Manage Publicist", subtitle: "Shape the public story.", identityLine: "You decide the performance does not end when the camera cuts.", previewTags: ["Heat down", "Brand +", "Cash cost"], preferredEventTags: ["social": 6, "risk": 5, "fame": 4], microBeat: "The quote gets cleaned up.", baseFriction: .warning)
        case .startMusicProducer:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Become Music Producer", subtitle: "Build the sound behind the artist.", identityLine: "You decide your place in music is behind the board, shaping the record before anyone hears it.", previewTags: ["Credits", "Royalties", "Studio cost"], preferredEventTags: ["career": 8, "fame": 4, "money": 4], microBeat: "The session opens.", baseFriction: .resistance)
        case .produceTrack:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Produce Track", subtitle: "Turn a session into a credit.", identityLine: "You decide this beat, mix, and arrangement can carry your name further.", previewTags: ["Credit +", "Royalty shot", "Demand"], preferredEventTags: ["career": 8, "fame": 5, "money": 5], microBeat: "The drums finally hit.", baseFriction: .resistance)
        case .runStudioSession:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Run Studio Session", subtitle: "Keep the room productive.", identityLine: "You decide the vibe, the clock, and the take all need your hand on them.", previewTags: ["Network +", "Studio +", "Burnout"], preferredEventTags: ["career": 7, "social": 5], microBeat: "Take it from the top.", baseFriction: .none)
        case .shopBeats:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Shop Beats", subtitle: "Find the right ears.", identityLine: "You decide the hard drive is worthless unless the right artist hears what is on it.", previewTags: ["Demand +", "Cash shot", "Rejection"], preferredEventTags: ["career": 6, "money": 5, "chance": 4], microBeat: "The folder gets sent.", baseFriction: .none)
        case .collaborateWithArtist:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Collaborate With Artist", subtitle: "Borrow chemistry.", identityLine: "You decide the record needs another person's gravity, not just your control.", previewTags: ["Network", "Credit risk", "Hit chance"], preferredEventTags: ["social": 7, "career": 7], microBeat: "The room changes.", baseFriction: .resistance)
        case .polishSignatureSound:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Polish Signature Sound", subtitle: "Become recognizable.", identityLine: "You decide the sound needs to become yours before the industry can pay for it.", previewTags: ["Signature +", "Quality +", "Slow money"], preferredEventTags: ["routine": 6, "career": 6], microBeat: "You mute everything except the feeling.", baseFriction: .none)
        case .manageProducerCredits:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Manage Producer Credits", subtitle: "Protect the paperwork.", identityLine: "You decide the song is not done until the split sheet tells the truth.", previewTags: ["Disputes down", "Royalties", "Relationship risk"], preferredEventTags: ["money": 6, "risk": 7], microBeat: "The split sheet gets signed.", baseFriction: .warning)
        case .startMovieProducer:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Become Movie Producer", subtitle: "Diamond Tier — Build a studio empire (peak Special + capital + creative dossier required)", identityLine: "You decide the next chapter is not making movies. It is owning the machine that decides which movies get made — and who gets rich or ruined doing it.", previewTags: ["Diamond", "Empire", "Slate", "Cash risk", "Legacy"], preferredEventTags: ["career": 9, "money": 7, "risk": 6, "fame": 6], microBeat: "The script hits your desk. This one has real money behind it.", baseFriction: .warning)
        case .optionScript:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Option Script", subtitle: "Buy a story before it exists.", identityLine: "You decide this idea is worth locking up before someone braver does.", previewTags: ["Slate +", "IP", "Cash cost"], preferredEventTags: ["career": 8, "money": 4], microBeat: "The option agreement lands.", baseFriction: .resistance)
        case .castProject:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Cast Project", subtitle: "Attach people with gravity.", identityLine: "You decide the movie needs faces that make money answer the phone.", previewTags: ["Cast +", "Prestige", "Burn rate"], preferredEventTags: ["career": 8, "social": 6], microBeat: "Availability is everything.", baseFriction: .resistance)
        case .shootFilm:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Shoot Film", subtitle: "Turn the slate into footage.", identityLine: "You decide the only way out is through the production calendar.", previewTags: ["Film shot", "Overruns", "Prestige"], preferredEventTags: ["career": 8, "money": 6, "risk": 6], microBeat: "First day of principal.", baseFriction: .warning)
        case .handleProductionCrisis:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Handle Production Crisis", subtitle: "Stop chaos from becoming fatal.", identityLine: "You decide to solve the thing nobody wants to own.", previewTags: ["Chaos down", "Trust", "Cash cost"], preferredEventTags: ["risk": 8, "career": 6], microBeat: "Everyone is waiting.", baseFriction: .warning)
        case .secureDistribution:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Secure Distribution", subtitle: "Get the film seen and paid.", identityLine: "You decide a finished movie is still a liability until someone can sell it.", previewTags: ["Revenue shot", "Prestige", "Leverage"], preferredEventTags: ["money": 8, "career": 7], microBeat: "The offer letter opens.", baseFriction: .resistance)
        case .manageBackEndPoints:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Manage Backend Points", subtitle: "Protect payout math.", identityLine: "You decide the glamour can wait until the contracts make sense.", previewTags: ["Backend +", "Chaos down", "Relationship risk"], preferredEventTags: ["money": 7, "risk": 6], microBeat: "Every percentage has a lawyer.", baseFriction: .warning)
        case .startRecordLabel:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Start Record Label", subtitle: "Diamond Tier — Build a music empire (peak music/creator cred + capital + creative dossier required)", identityLine: "You decide the next chapter is not performing for the industry. It is owning the catalog, the roster, the tours, and the money — and deciding who gets to be heard.", previewTags: ["Diamond", "Empire", "Roster", "Catalog", "Cash risk", "Legacy"], preferredEventTags: ["career": 9, "money": 6, "fame": 6, "risk": 5], microBeat: "The label name goes on the contract. The risk is yours now.", baseFriction: .resistance)
        case .signArtist:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Sign New Artist", subtitle: "Bet on raw talent.", identityLine: "You decide someone else's voice is worth your money, time, and reputation.", previewTags: ["Roster +", "Cash cost", "Upside"], preferredEventTags: ["career": 8, "social": 5, "money": 4], microBeat: "The demo plays again.", baseFriction: .resistance)
        case .developArtist:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Develop Artist", subtitle: "Turn potential into work.", identityLine: "You decide the slow studio hours matter more than chasing a quick hit.", previewTags: ["Talent +", "Trust +", "Cash cost"], preferredEventTags: ["career": 7, "routine": 5], microBeat: "Another take from the top.", baseFriction: .none)
        case .releaseRecord:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Release Record", subtitle: "Add to the catalog.", identityLine: "You decide the song is ready to leave the room and face the world.", previewTags: ["Catalog", "Royalties", "Hit chance"], preferredEventTags: ["career": 8, "fame": 6, "money": 5], microBeat: "Upload scheduled.", baseFriction: .resistance)
        case .bookTour:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Book Tour", subtitle: "Put the roster on the road.", identityLine: "You decide the money is on stage, even if the road eats people alive.", previewTags: ["Tour upside", "Burnout", "Cancellation risk"], preferredEventTags: ["money": 8, "career": 6, "risk": 6], microBeat: "Dates go on sale.", baseFriction: .warning)
        case .payArtists:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Pay Artists Fairly", subtitle: "Protect trust over margin.", identityLine: "You decide the people making the music should feel the money, not just the label.", previewTags: ["Trust +", "Heat down", "Cash cost"], preferredEventTags: ["social": 8, "money": 5], microBeat: "The statements are clean.", baseFriction: .none)
        case .pushSingle:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Push The Single", subtitle: "Spend for attention.", identityLine: "You decide this record needs a real campaign, not hope and a post.", previewTags: ["Popularity +", "Prestige", "Cash cost"], preferredEventTags: ["fame": 8, "money": 5, "career": 5], microBeat: "The hook follows you home.", baseFriction: .resistance)
        case .handleArtistDrama:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Handle Artist Drama", subtitle: "Keep the roster from cracking.", identityLine: "You decide to get in the room before the rumor becomes the story.", previewTags: ["Heat down", "Trust risk", "Morale"], preferredEventTags: ["risk": 8, "social": 6], microBeat: "Phones face down.", baseFriction: .warning)
        case .startCoachingCareer:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Become Program Coach", subtitle: "Diamond Tier — Build a program legacy (peak athlete or leadership cred + capital required)", identityLine: "You decide the next game is not played with your body. It is played through the people you recruit, the system you install, and the boosters you manage — or survive.", previewTags: ["Diamond", "Empire", "Program", "Pressure", "Legacy"], preferredEventTags: ["career": 9, "social": 7, "risk": 7, "fame": 5], microBeat: "The whistle hangs differently. So does the weight of the program.", baseFriction: .warning)
        case .recruitTalent:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Recruit Talent", subtitle: "Win the living room.", identityLine: "You decide the season starts with convincing someone talented to believe you.", previewTags: ["Roster +", "Prestige", "Compliance risk"], preferredEventTags: ["career": 8, "social": 6], microBeat: "Family on one side. Future on the other.", baseFriction: .resistance)
        case .hireCoachingStaff:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Hire Coaching Staff", subtitle: "Build the room behind the team.", identityLine: "You decide the program cannot be smarter than the people helping you run it.", previewTags: ["Staff +", "Culture", "Budget"], preferredEventTags: ["career": 7, "money": 4], microBeat: "Another headset joins the sideline.", baseFriction: .none)
        case .installSystem:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Install System", subtitle: "Teach the identity.", identityLine: "You decide what your team is supposed to become before the scoreboard argues back.", previewTags: ["Scheme +", "Development", "Short pain"], preferredEventTags: ["career": 8, "routine": 5], microBeat: "Whiteboard. Repetition. Again.", baseFriction: .resistance)
        case .runTrainingCamp:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Run Training Camp", subtitle: "Sharpen the roster.", identityLine: "You decide the team needs hard reps now so the season costs less later.", previewTags: ["Readiness +", "Injury risk", "Morale"], preferredEventTags: ["career": 8, "health": 3, "risk": 4], microBeat: "Two whistles. One more rep.", baseFriction: .warning)
        case .manageLockerRoom:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Manage Locker Room", subtitle: "Keep belief from splitting.", identityLine: "You decide culture is not a poster. It is every hard conversation nobody wants.", previewTags: ["Culture +", "Morale", "Drama down"], preferredEventTags: ["social": 8, "career": 6], microBeat: "The room gets quiet.", baseFriction: .none)
        case .callBigGame:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Call The Big Game", subtitle: "Risk the scheme under pressure.", identityLine: "You decide the moment needs your nerve, not just the binder.", previewTags: ["Win shot", "Prestige", "Heat"], preferredEventTags: ["career": 8, "chance": 6, "fame": 4], microBeat: "Fourth quarter. No hiding.", baseFriction: .warning)
        case .handleBoosterPressure:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Handle Booster Pressure", subtitle: "Survive the money people.", identityLine: "You decide who gets access without letting them own the program.", previewTags: ["Pressure down", "Budget risk", "Integrity"], preferredEventTags: ["money": 5, "risk": 7, "career": 6], microBeat: "Dinner with strings attached.", baseFriction: .warning)
        case .runScheme:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Chase Fast Money", subtitle: "Speed over safety.", identityLine: "You decide the clean route is too slow for the pressure you are under.", previewTags: ["Fast cash", "Heat", "Stability loss"], preferredEventTags: ["money": 5, "risk": 8], microBeat: "You check over your shoulder.", baseFriction: .warning)
        case .buildCrew:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Build A Circle That Owes You", subtitle: "Power through people.", identityLine: "You choose influence and loyalty, knowing it will add pressure of its own.", previewTags: ["Loyalty", "Reach", "Pressure"], preferredEventTags: ["social": 5, "risk": 6], microBeat: "Making them an offer.", baseFriction: .warning)
        case .cleanMoney:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Make The Money Look Legit", subtitle: "Reduce heat at a cost.", identityLine: "You decide survival now depends on making your mess look stable.", previewTags: ["Heat down", "Cash cost", "Safety"], preferredEventTags: ["money": 4, "routine": 3], microBeat: "Scrubbing the trail.", baseFriction: .none)
        case .stepAway:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Back Away Before It Owns You", subtitle: "Choose air over pace.", identityLine: "You decide the year needs breathing room more than momentum.", previewTags: ["Exit risk", "Breathing room"], preferredEventTags: ["health": 5, "relationships": 2], microBeat: "Letting it go.", baseFriction: .none)
        case .retainCounsel:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Retain Counsel", subtitle: "Pay for a stronger defense.", identityLine: "You decide not to face the system alone.", previewTags: ["Defense up", "Cash cost", "Case control"], preferredEventTags: ["risk": 6, "money": 4], microBeat: "The retainer clears.", baseFriction: .resistance)
        case .cooperateWithInvestigation:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Cooperate", subtitle: "Lower the pressure by helping.", identityLine: "You decide candor may cost less than resistance.", previewTags: ["Evidence risk", "Sentence relief", "Reputation"], preferredEventTags: ["risk": 7, "social": 3], microBeat: "You answer carefully.", baseFriction: .warning)
        case .refuseInterview:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Refuse Interview", subtitle: "Say nothing without a deal.", identityLine: "You decide silence is the only leverage left.", previewTags: ["Evidence protected", "Scrutiny", "No relief"], preferredEventTags: ["risk": 7], microBeat: "The room stays quiet.", baseFriction: .warning)
        case .negotiatePlea:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Negotiate Plea", subtitle: "Trade certainty for leniency.", identityLine: "You decide to control the damage instead of gambling everything.", previewTags: ["Lower sentence", "Conviction", "Fine"], preferredEventTags: ["risk": 6, "money": 3], microBeat: "Terms move across the table.", baseFriction: .resistance)
        case .fightCharges:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Fight Charges", subtitle: "Take the case to judgment.", identityLine: "You decide the evidence should have to survive daylight.", previewTags: ["Acquittal chance", "Full exposure", "Legal cost"], preferredEventTags: ["risk": 9, "money": 4], microBeat: "The hearing begins.", baseFriction: .warning)
        case .postBail:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Post Bail", subtitle: "Stay outside while the case moves.", identityLine: "You decide freedom before trial is worth the cost.", previewTags: ["Cash cost", "Freedom", "Case pending"], preferredEventTags: ["money": 6, "risk": 4], microBeat: "The bond posts.", baseFriction: .resistance)
        case .complyWithSupervision:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Comply With Terms", subtitle: "Keep the record from getting heavier.", identityLine: "You decide boring discipline is the fastest way forward.", previewTags: ["Pressure down", "Clean year", "Restrictions"], preferredEventTags: ["routine": 7], microBeat: "Another check-in cleared.", baseFriction: .none)
        case .requestEarlyRelease:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Request Early Release", subtitle: "Ask the system to recognize compliance.", identityLine: "You decide the clean stretch should count for something.", previewTags: ["Release chance", "Review", "Record remains"], preferredEventTags: ["risk": 4, "routine": 5], microBeat: "The petition is filed.", baseFriction: .resistance)
        case .keepHeadDown:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Keep Your Head Down", subtitle: "Survive without making noise.", identityLine: "You decide the fastest way out is to give them nothing to write up.", previewTags: ["Conduct up", "Violence down", "Slow grind"], preferredEventTags: ["routine": 6, "health": 3], microBeat: "Eyes down. Mouth shut.", baseFriction: .none)
        case .standYourGround:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Stand Your Ground", subtitle: "Refuse to be easy prey.", identityLine: "You decide respect inside costs something — and you're willing to pay.", previewTags: ["Yard rep", "Violence risk", "Faction heat"], preferredEventTags: ["risk": 8, "crime": 4], microBeat: "The yard goes quiet.", baseFriction: .warning)
        case .alignWithFaction:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Pick A Side", subtitle: "Protection has a price tag.", identityLine: "You decide going alone is slower than owing someone.", previewTags: ["Faction loyalty", "Protection debt", "Target risk"], preferredEventTags: ["crime": 6, "social": 4], microBeat: "Someone vouches for you.", baseFriction: .warning)
        case .payProtection:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Pay Protection", subtitle: "Buy a little safety.", identityLine: "You decide debt inside beats a hospital bed.", previewTags: ["Violence down", "Cash cost", "More debt"], preferredEventTags: ["money": 5, "crime": 4], microBeat: "The favor is logged.", baseFriction: .resistance)
        case .refuseSnitchDeal:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Refuse The Deal", subtitle: "Guards want a name. You don't give one.", identityLine: "You decide your name stays off their paperwork.", previewTags: ["Snitch risk down", "Infraction risk", "Yard rep"], preferredEventTags: ["crime": 7, "risk": 5], microBeat: "You walk back to your cell.", baseFriction: .warning)
        case .cooperateWithGuards:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Cooperate With Guards", subtitle: "Trade information for time.", identityLine: "You decide getting out matters more than who trusts you inside.", previewTags: ["Sentence relief", "Snitch risk", "Faction betrayal"], preferredEventTags: ["crime": 8, "risk": 6], microBeat: "The recorder clicks on.", baseFriction: .warning)
        case .prisonWorkDetail:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Take Work Detail", subtitle: "Commissary money and good conduct.", identityLine: "You decide boring labor is a currency you can spend on freedom.", previewTags: ["Conduct up", "Cash", "Good time"], preferredEventTags: ["routine": 7, "money": 4], microBeat: "Another shift done.", baseFriction: .resistance)
        case .studyProgram:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Study Program", subtitle: "GED or trade cert behind the wall.", identityLine: "You decide the parole board reads paperwork too.", previewTags: ["Program progress", "Parole bonus", "Mental load"], preferredEventTags: ["education": 6, "routine": 4], microBeat: "The textbook is worn thin.", baseFriction: .none)
        case .callFamily:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Call Family", subtitle: "One call before the line goes dead.", identityLine: "You decide the people outside still need to know you're in here.", previewTags: ["Bond up", "Shame", "Limited use"], preferredEventTags: ["relationships": 7, "family": 5], microBeat: "The timer runs down.", baseFriction: .none)
        case .requestParoleHearing:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Request Parole Hearing", subtitle: "Ask the board to let you out early.", identityLine: "You decide you've done enough time to make the case.", previewTags: ["Release chance", "Conduct review", "Board risk"], preferredEventTags: ["crime": 6, "risk": 5], microBeat: "Your file hits the table.", baseFriction: .warning)
        case .fileAppeal:
            return ActionChoiceDefinition(choiceID: choiceID, title: "File Appeal", subtitle: "Long shot at shaving time.", identityLine: "You decide the sentence isn't the last word — if you can afford the fight.", previewTags: ["Time reduction", "Legal cost", "Low odds"], preferredEventTags: ["money": 6, "risk": 4], microBeat: "Paperwork leaves the cell block.", baseFriction: .resistance)
        case .delegateFromInside:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Delegate From Inside", subtitle: "Run the machine through a lieutenant.", identityLine: "You decide the empire doesn't pause just because you're locked up.", previewTags: ["Loyalty hold", "Betrayal risk", "Uses sentence choice"], preferredEventTags: ["crime": 7, "risk": 6], microBeat: "Orders leave the block on paper.", baseFriction: .warning)
        case .callLieutenant:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Call Lieutenant", subtitle: "Keep the network from forgetting you.", identityLine: "You decide distance shouldn't mean disposable.", previewTags: ["Network hold", "Notoriety leak", "Uses sentence choice"], preferredEventTags: ["crime": 6, "social": 4], microBeat: "The call was monitored. They listened anyway.", baseFriction: .warning)
        case .authorizeOutsideMove:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Authorize Outside Move", subtitle: "Green-light money from behind the wall.", identityLine: "You decide a small score outside is worth the exposure.", previewTags: ["Outside cash", "Infraction risk", "Uses sentence choice"], preferredEventTags: ["crime": 8, "finance": 5], microBeat: "The move happened without your face near it.", baseFriction: .warning)
        // CE2: Dedicated instant actions for Criminal Enterprise paths
        case .ghostProtocol:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Ghost Protocol", subtitle: "Disappear for a while.", identityLine: "You decide the best move is to become very hard to find right now.", previewTags: ["Heat down", "Opportunity cost", "Isolation"], preferredEventTags: ["risk": 4, "routine": 3], microBeat: "Going dark.", baseFriction: .none)
        case .burnEvidence:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Burn The Evidence", subtitle: "Destroy what can be used against you.", identityLine: "You choose to erase proof even if it costs you leverage or money.", previewTags: ["Heat down", "Irreversible", "Loss"], preferredEventTags: ["risk": 5, "money": 3], microBeat: "Watching it burn.", baseFriction: .warning)
        case .payTheFixer:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Pay The Fixer", subtitle: "Throw money at the problem.", identityLine: "You decide problems go away faster when the right person is well compensated.", previewTags: ["Heat down", "Cash cost", "Temporary"], preferredEventTags: ["money": 6, "risk": 4], microBeat: "Making the call.", baseFriction: .none)
        case .launderThroughShell:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Launder Through Shells", subtitle: "Make dirty money look clean.", identityLine: "You choose to spend time and resources making your cash harder to trace.", previewTags: ["Clean money up", "Time cost", "Complexity"], preferredEventTags: ["money": 5, "risk": 3], microBeat: "Paperwork and patience.", baseFriction: .none)
        case .hostStrategicGala:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Host The Strategic Gala", subtitle: "Use social cover.", identityLine: "You decide the best way to move right now is in plain sight, surrounded by the right people.", previewTags: ["Network up", "Social cost", "Cover"], preferredEventTags: ["social": 7, "risk": 3], microBeat: "Smiling for the room.", baseFriction: .none)
        case .aggressiveTakeover:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Aggressive Takeover", subtitle: "Move hard and fast.", identityLine: "You decide this is the moment to be ruthless. Win big or create enemies.", previewTags: ["Big swing", "Heat risk", "Reputation"], preferredEventTags: ["money": 7, "risk": 8], microBeat: "Going for the throat.", baseFriction: .warning)
        case .streetCornerHustle:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Work The Corner", subtitle: "Fast cash, naked exposure.", identityLine: "You decide the block is the only clock that matters tonight.", previewTags: ["Cash swing", "Heat", "Personal risk"], preferredEventTags: ["money": 6, "risk": 8], microBeat: "Eyes on every car.", baseFriction: .warning)
        case .dodgePatrol:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Dodge The Patrol", subtitle: "Disappear before they ask names.", identityLine: "You choose survival over momentum when the lights start spinning.", previewTags: ["Heat down", "Income pause"], preferredEventTags: ["risk": 5, "health": 2], microBeat: "Wrong turn on purpose.", baseFriction: .none)
        case .holdTerritory:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Hold The Block", subtitle: "Territory is the whole argument.", identityLine: "You decide the crew eats only if the corners stay yours.", previewTags: ["Territory", "Heat", "Loyalty"], preferredEventTags: ["risk": 7, "social": 4], microBeat: "Everyone knows why you're here.", baseFriction: .warning)
        case .disciplineCrew:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Discipline The Crew", subtitle: "Fear and respect in the same breath.", identityLine: "You remind them who runs the math when someone gets greedy.", previewTags: ["Loyalty up", "Burnout", "Risk"], preferredEventTags: ["crime": 6, "risk": 5], microBeat: "The room goes quiet.", baseFriction: .warning)
        case .delegateOperation:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Delegate The Operation", subtitle: "Violence at a distance.", identityLine: "You decide the move happens without your face anywhere near it.", previewTags: ["Heat buffer", "Betrayal risk", "Income"], preferredEventTags: ["crime": 5, "risk": 4], microBeat: "A call, not a visit.", baseFriction: .none)
        case .expandDomesticEmpire:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Expand Domestic Reach", subtitle: "Build the parallel economy at home.", identityLine: "You choose insulation over spectacle — fronts, favors, and quiet leverage.", previewTags: ["Clean money", "Network", "Federal heat"], preferredEventTags: ["money": 6, "crime": 5], microBeat: "Another shell, another door.", baseFriction: .none)
        case .connectCartelNetwork:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Connect Cartel Pipelines", subtitle: "Go transnational or stay local.", identityLine: "You decide the real money crosses borders — and so does the real exposure.", previewTags: ["Massive upside", "Extreme heat", "Legacy risk"], preferredEventTags: ["money": 8, "risk": 9], microBeat: "The call came from far away.", baseFriction: .warning)
        case .smallHustle:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Scrape Together Your Own Money", subtitle: "A little freedom, a little strain.", identityLine: "You decide even a small cash buffer is worth carrying a little more weight.", previewTags: ["Cash", "-Mental", "Recovery loss"], preferredEventTags: ["money": 7, "career": 2], microBeat: "Counting every cent.", baseFriction: .none)
        case .takeExtraShifts:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Trade Your Time For Breathing Room", subtitle: "Cash now, stamina later.", identityLine: "You decide the margin matters more than rest this year.", previewTags: ["Cash", "Recovery loss", "School hit"], preferredEventTags: ["money": 7, "career": 4, "health": 3], microBeat: "Your feet ache.", baseFriction: .resistance)
        case .saveForEscape:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Stack Money For A Way Out", subtitle: "Live tight now, move later.", identityLine: "You frame the year as temporary sacrifice for future movement.", previewTags: ["Cash buffer", "Comfort loss"], preferredEventTags: ["money": 7, "housing": 3], microBeat: "Eyes on the exit.", baseFriction: .none)
        case .cutSpending:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Clamp Down And Get Through It", subtitle: "Shrink the year on purpose.", identityLine: "You decide control matters more than comfort until the pressure eases.", previewTags: ["Stress down", "Comfort loss"], preferredEventTags: ["money": 8, "routine": 3], microBeat: "Tightening the belt.", baseFriction: .none)
        case .spendForRelief:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Buy Yourself A Little Relief", subtitle: "Mood first, margin second.", identityLine: "You choose a lighter day now and let the numbers worry about themselves later.", previewTags: ["Mood", "Cash down"], preferredEventTags: ["spend": 7, "social": 2], microBeat: "Just this once.", baseFriction: .none)
        case .spendToCope:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Numb It With Spending", subtitle: "Temporary relief with a tail.", identityLine: "You let the stress pick the purchase and deal with the aftershock later.", previewTags: ["Relief", "Cash down", "Stress later"], preferredEventTags: ["spend": 8, "health": 2], microBeat: "Buying the silence.", baseFriction: .none)
        case .takeSideWork:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Take Whatever Extra Work You Can Find", subtitle: "Stability through effort.", identityLine: "You choose labor over uncertainty and dare the year to keep up.", previewTags: ["Cash", "Mental cost", "Energy loss"], preferredEventTags: ["career": 5, "money": 6, "health": 2], microBeat: "Anything helps.", baseFriction: .resistance)
        case .payDownDebt:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Throw Real Money At The Balance", subtitle: "Trade comfort for future room.", identityLine: "You decide the debt should shrink this year even if your present gets tighter.", previewTags: ["Debt down", "Cash down", "Stress relief"], preferredEventTags: ["money": 8, "routine": 3], microBeat: "Watching the number fall.", baseFriction: .resistance)
        case .consolidateDebt:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Restructure The Damage", subtitle: "Buy breathing room at a price.", identityLine: "You decide the debt needs a different shape before it eats the whole year.", previewTags: ["Payments down", "Fees", "Relief cooldown"], preferredEventTags: ["money": 7, "chance": 2], microBeat: "Signing the paperwork.", baseFriction: .none)
        case .minimumPayments:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Keep The Accounts Barely Current", subtitle: "Survive this year first.", identityLine: "You decide staying afloat matters more than making a clean dent in the balance.", previewTags: ["Cash preserved", "Debt lingers", "Stress stays"], preferredEventTags: ["money": 7, "health": 2], microBeat: "Just enough to stay in the game.", baseFriction: .none)
        case .deferStudentLoans:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Push The Student Debt Forward", subtitle: "Relief now, interest later.", identityLine: "You decide the present is too fragile to carry the full student payment this year.", previewTags: ["Cash relief", "Debt up later", "Stress"], preferredEventTags: ["money": 7, "school": 2], microBeat: "Kicking the bill down the road.", baseFriction: .resistance)
        case .declareBankruptcy:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Let The Whole Thing Collapse On Paper", subtitle: "A brutal reset.", identityLine: "You decide surviving matters more than protecting the image of how this was supposed to go.", previewTags: ["Debt reset", "Wealth wiped", "Long shadow"], preferredEventTags: ["money": 8, "health": 3], microBeat: "Signing the surrender.", baseFriction: .warning)
        // Econ4: Rich instant economic actions with era + special career flavor
        case .panicSell:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Panic Sell And Get Out", subtitle: "Cut the bleeding now.", identityLine: "You decide the downside risk is no longer worth holding. Cash in hand feels safer than hope.", previewTags: ["Cash now", "Loss locked", "Relief"], preferredEventTags: ["money": 9, "risk": 4, "negative": 3], microBeat: "Selling at the bottom of your fear.", baseFriction: .warning)
        case .aggressiveSideHustle:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Go All In On Side Money", subtitle: "Grind when the main path is shaky.", identityLine: "You decide the official income isn't enough and you're willing to bleed for the gap.", previewTags: ["Extra cash", "Burnout risk", "Hidden hours"], preferredEventTags: ["money": 8, "career": 4, "health": 3], microBeat: "Another shift, another corner cut.", baseFriction: .resistance)
        case .bigLifestylePurchase:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Buy The Victory Lap", subtitle: "Spend like the good times are real.", identityLine: "You decide the numbers on the screen are permission to feel successful in public.", previewTags: ["Status up", "Cash down", "Lifestyle creep"], preferredEventTags: ["money": 6, "social": 5, "positive": 3], microBeat: "The keys feel heavy in the best way.", baseFriction: .none)
        case .rideTheWave:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Ride The Wave Hard", subtitle: "Lean all the way into the upswing.", identityLine: "You decide the economy is handing you a gift and you're not going to be the one who blinks first.", previewTags: ["Upside", "Risk on", "Momentum"], preferredEventTags: ["money": 7, "opportunity": 6, "career": 4], microBeat: "Saying yes to everything that feels hot.", baseFriction: .none)
        case .quietFinancialQuit:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Quiet Financial Quit", subtitle: "Protect what you still have.", identityLine: "You decide the game is rigged against you right now and the smartest move is to stop playing so loud.", previewTags: ["Risk down", "Growth paused", "Peace"], preferredEventTags: ["money": 5, "health": 4, "routine": 4], microBeat: "Choosing smaller to stay whole.", baseFriction: .none)
        // Assets3 instant actions
        case .flexLuxuryAsset:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Flex the Collection", subtitle: "Let people know what you own.", identityLine: "You decide the right move is to be seen with the toys.", previewTags: ["Status", "Social", "Fame risk"], preferredEventTags: ["social": 8, "opportunity": 4], microBeat: "Posting the keys.", baseFriction: .none)
        case .liquidateLuxury:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Liquidate the Toys", subtitle: "Cash out the lifestyle.", identityLine: "You decide the symbols of success are now liabilities.", previewTags: ["Cash now", "Prestige hit"], preferredEventTags: ["money": 9, "negative": 3], microBeat: "The garage is getting emptier.", baseFriction: .warning)
        case .upgradeCollection:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Level Up the Fleet", subtitle: "Make the toys even better.", identityLine: "You decide the current level of flex isn't enough.", previewTags: ["Prestige up", "Cash down"], preferredEventTags: ["money": 5, "social": 5], microBeat: "Bigger, faster, shinier.", baseFriction: .none)
        case .hostAtSignatureEstate:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Host at the Estate", subtitle: "Use the big house for influence.", identityLine: "You decide the property is a tool, not just a flex.", previewTags: ["Social", "Influence", "Cost"], preferredEventTags: ["social": 7, "career": 4], microBeat: "The guest list is strategic.", baseFriction: .none)
        case .buildEmergencyFund:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Build A Real Cushion", subtitle: "Protect the floor first.", identityLine: "You decide resilience matters more than flashy upside this year.", previewTags: ["Cash floor", "Risk down", "Resilience"], preferredEventTags: ["money": 8, "routine": 4], microBeat: "Securing the floor.", baseFriction: .none)
        case .buyIndexFund:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Bet On The Long Run", subtitle: "Slow compounding over noise.", identityLine: "You choose patience and trust time to do more than adrenaline can.", previewTags: ["Compounding", "Liquidity loss", "Low drama"], preferredEventTags: ["money": 5, "chance": 2], microBeat: "Planting the seed.", baseFriction: .none)
        case .speculateStocks:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Take A Swing", subtitle: "Accept volatility for upside.", identityLine: "You decide this year should feel alive enough to risk some instability.", previewTags: ["Upside", "Liquidity loss", "Volatility"], preferredEventTags: ["chance": 7, "money": 4, "risk": 4], microBeat: "Roll the dice.", baseFriction: .warning)
        case .holdPositions:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Hold Your Nerve", subtitle: "Let the year play out.", identityLine: "You decide not every year needs a new move to matter.", previewTags: ["No new risk", "Ride returns"], preferredEventTags: ["money": 3], microBeat: "Still hands.", baseFriction: .none)
        case .sellToCover:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Pull Money Back To Safety", subtitle: "Protect today from tomorrow.", identityLine: "You decide liquidity matters more than staying exposed to future upside.", previewTags: ["Cash", "Future growth loss", "Fees"], preferredEventTags: ["money": 5, "health": 1], microBeat: "Back to the bank.", baseFriction: .none)
        case .saveForDownPayment:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Start Building Toward A Place Of Your Own", subtitle: "Convert pressure into a target.", identityLine: "You turn this year into a long march toward stability you can point to.", previewTags: ["Home fund", "Flexible cash loss", "Stability goal"], preferredEventTags: ["housing": 6, "money": 6], microBeat: "Saving the keys.", baseFriction: .none)
        case .depositToHouseFund:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Deposit To House Fund", subtitle: "Move cash into a down-payment bucket now.", identityLine: "You earmark real money today instead of waiting for the year to decide.", previewTags: ["House fund up", "Cash down", "Ownership closer"], preferredEventTags: ["housing": 5, "money": 4], microBeat: "Saving the keys.", baseFriction: .none)
        case .buyStarterHome:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Make The Jump Into Ownership", subtitle: "Control with real weight attached.", identityLine: "You decide the next chapter should belong to you, even if the cost lingers.", previewTags: ["Equity", "Housing control", "Liquidity loss"], preferredEventTags: ["housing": 8, "money": 4], microBeat: "Signing the life away.", baseFriction: .resistance)
        case .refinanceMortgage:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Renegotiate The Weight", subtitle: "Buy breathing room.", identityLine: "You decide the year needs room to breathe more than pride about the original deal.", previewTags: ["Monthly cost down", "Breathing room", "Fees"], preferredEventTags: ["housing": 5, "money": 5], microBeat: "Changing the deal.", baseFriction: .none)
        case .buildMaintenanceReserve:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Prepare For The House To Ask Again", subtitle: "Plan for the next hit.", identityLine: "You decide stability means getting ahead of future problems before they arrive.", previewTags: ["Housing resilience", "Liquid cash down", "Surprise risk down"], preferredEventTags: ["housing": 7, "money": 4], microBeat: "Fortifying the walls.", baseFriction: .none)
        case .topUpHouseReserve:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Top Up Repair Reserve", subtitle: "Put cash aside before the house breaks something.", identityLine: "You fund the repair bucket now so the next leak does not become a crisis.", previewTags: ["Reserve up", "Cash down", "Repair risk down"], preferredEventTags: ["housing": 6, "money": 4], microBeat: "Fortifying the walls.", baseFriction: .none)
        case .sellHome:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Cash Out And Reset", subtitle: "Trade permanence for flexibility.", identityLine: "You decide the year needs margin more than it needs roots.", previewTags: ["Cash", "Housing stability loss", "Flexibility"], preferredEventTags: ["housing": 6, "money": 5], microBeat: "Handing over the keys.", baseFriction: .none)
        // Econ1 (Stock Market)
        case .checkPortfolio:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Review Portfolio", subtitle: "Glance at the wins and scars.", identityLine: "You take a cold look at your positions. The numbers don't lie.", previewTags: ["Knowledge", "Market Pulse"], microBeat: "Scrolling through the deltas.", baseFriction: .none)
        case .rebalancePortfolio:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Rebalance Risk", subtitle: "Shift weight to protect the future.", identityLine: "You decide to adjust your exposure before the market decides for you.", previewTags: ["Risk Shift", "Momentum", "Fee hit"], microBeat: "Moving the sliders.", baseFriction: .resistance)
        case .researchTip:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Research Hot Sector", subtitle: "Chase the whisper of an edge.", identityLine: "You spend the afternoon digging into the data everyone else is ignoring.", previewTags: ["Intel", "Confidence", "Time cost"], microBeat: "Reading between the lines.", baseFriction: .none)
        case .buyIndex:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Buy Market Index", subtitle: "Broad exposure, steady growth.", identityLine: "You decide the whole market is better than any one bet.", previewTags: ["Cash down", "Index Fund up"], microBeat: "Setting up the auto-buy.", baseFriction: .none)
        case .sellPosition:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Liquidate Position", subtitle: "Turn paper wins into real cash.", identityLine: "You decide the cash is better in your hand than on the screen.", previewTags: ["Cash up", "Portfolio down"], microBeat: "Executing the trade.", baseFriction: .none)
        // Luxury / Lifestyle (L1)
        case .hostLuxuryEvent:
            return ActionChoiceDefinition(
                choiceID: choiceID,
                title: "Host Grand Gala",
                subtitle: "A night the world will talk about.",
                identityLine: "You open your doors to the elite. The bill is astronomical; the prestige is eternal.",
                previewTags: ["Fame: +8%", "Cash: -$250k+", "Family Bond: -2%"],
                microBeat: "Raising a crystal glass.",
                baseFriction: .none
            )
        case .acquireLuxuryAsset:
            return ActionChoiceDefinition(
                choiceID: choiceID,
                title: "Acquire Statement Piece",
                subtitle: "Buy what others can only dream of.",
                identityLine: "You add another pillar to your legacy. It's not just an object; it's a signal.",
                previewTags: ["Prestige: +5%", "Cash: -$1.5M+", "Maintenance: Seeded"],
                microBeat: "Signing the deed.",
                baseFriction: .none
            )
        case .indulgeInExcess:
            return ActionChoiceDefinition(
                choiceID: choiceID,
                title: "Indulge in Excess",
                subtitle: "Burn cash for pure sensation.",
                identityLine: "You decide the best things in life are indeed very expensive.",
                previewTags: ["Happiness: +10", "Health: -3% to -5%", "Cash: -$50k"],
                microBeat: "Tasting perfection.",
                baseFriction: .none
            )
        case .displayWealth:
            return ActionChoiceDefinition(
                choiceID: choiceID,
                title: "Signal Status",
                subtitle: "Let them see how you live.",
                identityLine: "You make sure the right people know exactly where you stand in the hierarchy.",
                previewTags: ["Fame: +4%", "Notoriety: +3%", "Heat: +5 to +12"],
                microBeat: "Stepping out of the car.",
                baseFriction: .none
            )
        case .maintainLuxuryCollection:
            return ActionChoiceDefinition(
                choiceID: choiceID,
                title: "Servicing & Hangar Fees",
                subtitle: "Keep the dream polished.",
                identityLine: "You pay the price of admission for the high life. The machine must stay perfect.",
                previewTags: ["Preserve Value", "Finance Momentum", "Cash: -0.2% Net Worth"],
                microBeat: "Approving the invoice.",
                baseFriction: .none
            )
        case .findYourCrowd:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Find Your People", subtitle: "Belonging on purpose.", identityLine: "You decide this year should feel less lonely, even if it gets messy.", previewTags: ["Belonging", "School", "Support"], preferredEventTags: ["social": 8, "school": 3], microBeat: "Finally, someone laughs.", baseFriction: .none)
        case .dateCarefully:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Let Someone In Carefully", subtitle: "Connection with caution.", identityLine: "You open the door to closeness without pretending it cannot complicate the year.", previewTags: ["Bond", "Belonging", "Risk"], preferredEventTags: ["romance": 8, "social": 3], microBeat: "A tentative text.", baseFriction: .none)
        case .startAffair:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Start an Affair", subtitle: "Seek connection on the side", detail: "Start a secret relationship. High risk of discovery and reputation damage.", identityLine: "You are leading a double life.", previewTags: ["Secret", "Rumor Heat", "Risk"], preferredEventTags: ["risk": 9, "social": 5], microBeat: "A late night text.", baseFriction: .warning)
        case .endAffair:
            return ActionChoiceDefinition(choiceID: choiceID, title: "End the Affair", subtitle: "Close the secret door", detail: "Break off your secret relationship before you get caught.", identityLine: "You are trying to fix your mistakes.", previewTags: ["Relief", "Safety"], preferredEventTags: ["social": 4], microBeat: "The final goodbye.", baseFriction: .none)
        case .buyEngagementRing:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Buy Engagement Ring", subtitle: "Prepare for the big question", detail: "Spend significant cash to buy a ring. Higher quality rings improve proposal success.", identityLine: "You are ready to commit.", previewTags: ["Cash cost", "Commitment"], preferredEventTags: ["money": 8, "social": 5], microBeat: "The box feels heavy in your pocket.", baseFriction: .resistance)
        case .signPrenup:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Sign Prenup", subtitle: "Protect your assets", detail: "A legal agreement to keep your finances separate. Lowers bond but provides security.", identityLine: "You are looking out for yourself.", previewTags: ["Financial Safety", "Bond hit"], preferredEventTags: ["money": 7], microBeat: "The lawyers are in the room.", baseFriction: .resistance)
        case .proposeMarriage:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Propose Marriage", subtitle: "Pop the question", detail: "Ask your partner to marry you. Success depends on bond and alignment.", identityLine: "You are taking the ultimate leap.", previewTags: ["Milestone", "Bond"], preferredEventTags: ["social": 10], microBeat: "The world holds its breath.", baseFriction: .none)
        case .planWedding:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Plan Wedding", subtitle: "The big day", detail: "Host a wedding. Costs significant cash but provides massive social capital.", identityLine: "You are celebrating your union.", previewTags: ["Cash cost", "Reputation", "Social Capital"], preferredEventTags: ["money": 10, "social": 10], microBeat: "Flowers and music.", baseFriction: .resistance)
        case .fileForDivorce:
            return ActionChoiceDefinition(choiceID: choiceID, title: "File for Divorce", subtitle: "End the union", detail: "End your marriage. Assets will be split 50/50 unless a prenup is active.", identityLine: "You are walking away.", previewTags: ["Asset Split", "Freedom", "Stress"], preferredEventTags: ["money": 9, "health": 6], microBeat: "Signing the papers.", baseFriction: .warning)
        case .chaseStatus:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Play For Attention", subtitle: "Visibility with heat.", identityLine: "You decide being seen matters enough to risk the backlash that follows.", previewTags: ["Visibility", "Peer heat", "Risk"], preferredEventTags: ["social": 6, "risk": 5], microBeat: "The likes are climbing.", baseFriction: .warning)
        case .stayInvisible:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Stay Hard To Reach", subtitle: "Minimize exposure.", identityLine: "You spend the year trying not to give anyone new leverage over you.", previewTags: ["Drama down", "Belonging down"], preferredEventTags: ["health": 2, "social": 1], microBeat: "Ghosting the noise.", baseFriction: .none)
        case .leanOnMentor:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Let Someone Older Guide You", subtitle: "Borrow steadiness.", identityLine: "You decide the year needs perspective more than pride.", previewTags: ["Support", "Clarity", "Peer heat down"], preferredEventTags: ["school": 4, "career": 4, "social": 3], microBeat: "They've been here before.", baseFriction: .none)
        case .reachOut:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Reach Back Toward People", subtitle: "Repair the quiet distance.", identityLine: "You decide not every connection should be left to drift on its own.", previewTags: ["Bond", "Support"], preferredEventTags: ["social": 7, "relationships": 4], microBeat: "Breaking the silence.", baseFriction: .none)
        case .strengthenBond:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Invest In The Relationship You Already Have", subtitle: "Choose closeness on purpose.", identityLine: "You decide this year should feel more shared, not just survived side by side.", previewTags: ["Bond", "Security"], preferredEventTags: ["romance": 7, "family": 3], microBeat: "Holding on tight.", baseFriction: .none)
        case .discussFuture:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Force The Future Into The Room", subtitle: "Get clarity even if it stings.", identityLine: "You decide uncertainty is heavier than an honest conversation.", previewTags: ["Commitment", "Clarity"], preferredEventTags: ["romance": 6, "family": 3], microBeat: "The heavy question.", baseFriction: .resistance)
        case .moveInTogether:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Tie Your Daily Life Together", subtitle: "More intimacy, more exposure.", identityLine: "You decide closeness is worth letting housing, money, and tension touch the relationship.", previewTags: ["Commitment", "Housing risk"], preferredEventTags: ["housing": 4, "romance": 7], microBeat: "A shared key.", baseFriction: .resistance)
        case .tryForBaby:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Open The Door To A Family Shift", subtitle: "Hope and pressure together.", identityLine: "You decide the next chapter might be bigger than the one you can fully control.", previewTags: ["Pregnancy odds", "Pressure"], preferredEventTags: ["family": 8, "health": 2, "cost": 3], microBeat: "The quiet hope.", baseFriction: .resistance)
        case .avoidPregnancy:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Keep The Line Clear", subtitle: "Prioritize control.", identityLine: "You decide this year needs fewer irreversible turns, not more.", previewTags: ["Pregnancy risk down", "Control"], preferredEventTags: ["family": 4, "health": 2], microBeat: "Safety first.", baseFriction: .none)
        case .letChanceDecide:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Stop Trying To Control Every Outcome", subtitle: "Let uncertainty in.", identityLine: "You let the year decide whether it wants to deepen into something bigger.", previewTags: ["Risk on", "Future unclear"], preferredEventTags: ["chance": 5, "family": 4, "romance": 4], microBeat: "Whatever happens, happens.", baseFriction: .none)
        case .keepDistance:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Keep Some Distance", subtitle: "Protect yourself first.", identityLine: "You decide staying intact matters more than staying close right now.", previewTags: ["Tension down", "Bond down"], preferredEventTags: ["health": 2, "relationships": 2], microBeat: "Building the wall.", baseFriction: .none)
        case .repairTension:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Try To Repair What Is Fraying", subtitle: "Choose the harder conversation.", identityLine: "You decide this year should not end with something important quietly worse.", previewTags: ["Bond", "Stability"], preferredEventTags: ["relationships": 8, "family": 3], microBeat: "I'm sorry.", baseFriction: .resistance)
        // Phase 2.2 parenting actions — simple, high-texture, meaningful trade-offs
        case .spendTimeWithKids:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Carve Out Real Time With Them", subtitle: "Presence over perfection.", identityLine: "You decide the year will include deliberate hours that belong only to your kids, not the to-do list.", previewTags: ["Bond up", "Mental cost", "Other plans down"], preferredEventTags: ["family": 9, "health": 2], microBeat: "You put the phone down.", baseFriction: .none)
        case .enforceRoutine:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Hold The Line On Structure", subtitle: "Stability has a cost.", identityLine: "You decide some friction now is kinder than chaos later, even when it makes you the bad guy.", previewTags: ["Structure", "Some resentment", "Long-term calm"], preferredEventTags: ["family": 7, "routine": 5], microBeat: "Bedtime is bedtime.", baseFriction: .resistance)
        case .encourageIndependence:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Step Back So They Can Step Up", subtitle: "Growth through space.", identityLine: "You decide your job is to make yourself a little less necessary this year.", previewTags: ["Autonomy", "Bond risk", "Pride"], preferredEventTags: ["family": 6, "chance": 3], microBeat: "You let them try.", baseFriction: .none)
        case .checkInOnChild:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Ask The Real Questions", subtitle: "Emotional presence.", identityLine: "You decide to find out how they actually are, even if the answer is heavier than you wanted.", previewTags: ["Insight", "Bond", "Emotional load"], preferredEventTags: ["family": 8, "health": 3], microBeat: "The quiet conversation.", baseFriction: .resistance)
        // D1: Identity domain — light, always-available static self actions (dossier-flavored, instant)
        case .morningReflection:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Morning Reflection", subtitle: "Check in with yourself.", identityLine: "You decide the year needs at least one honest conversation with the person you are becoming.", previewTags: ["Clarity", "Mental", "Dossier echo"], preferredEventTags: ["health": 5, "identity": 4], microBeat: "The mirror is quiet.", baseFriction: .none)
        case .reconcileWithPast:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Reconcile With Where You Came From", subtitle: "Make peace with the dossier.", identityLine: "You decide the wiring from 14 still has something to teach you, even if it stings.", previewTags: ["Dossier tie", "Mental relief", "Legacy note"], preferredEventTags: ["health": 4, "family": 3, "identity": 5], microBeat: "The old story gets a footnote.", baseFriction: .resistance)
        case .tryNewPersona:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Try On A New Version Of You", subtitle: "Experiment with identity.", identityLine: "You decide this year is allowed to change what 'you' even means.", previewTags: ["Identity shift", "Rep risk", "Fresh start"], preferredEventTags: ["social": 5, "risk": 4, "identity": 6], microBeat: "New name in the mirror.", baseFriction: .warning)
        case .publicReset:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Public Reset", subtitle: "Change the story people tell.", identityLine: "You decide the version of you that the world has been carrying is due for an edit.", previewTags: ["Rep swing", "Fame cost/benefit"], preferredEventTags: ["social": 6, "career": 3, "identity": 4], microBeat: "The announcement lands.", baseFriction: .none)
        case .therapySession:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Therapy Session", subtitle: "Pay for perspective.", identityLine: "You decide some patterns are too expensive to keep carrying alone.", previewTags: ["Mental +", "Cash cost", "Insight"], preferredEventTags: ["health": 8, "money": 2], microBeat: "The hour that belongs only to you.", baseFriction: .none)
        case .processCrisis:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Process The Identity Crisis", subtitle: "Face the fracture.", identityLine: "You decide the version of you that has been running this life is due for a reckoning.", previewTags: ["Coherence", "Painful clarity", "Stance realign"], preferredEventTags: ["health": 6, "identity": 7, "risk": 3], microBeat: "The pieces on the table.", baseFriction: .resistance)
        // D1: Military depth statics + deploy
        case .ptFocus:
            return ActionChoiceDefinition(choiceID: choiceID, title: "PT Focus", subtitle: "Sharpen the machine.", identityLine: "You decide the body that serves is the one that survives.", previewTags: ["Fitness +", "Discipline +"], preferredEventTags: ["health": 6, "military": 5], microBeat: "Boots on the ground before dawn.", baseFriction: .resistance)
        case .seekCounsel:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Seek Counsel", subtitle: "Tend the invisible wounds.", identityLine: "You decide the things that don't bleed still need looking after.", previewTags: ["Trauma down", "Mental +"], preferredEventTags: ["health": 7, "military": 4], microBeat: "The quiet room.", baseFriction: .none)
        case .studyTradition:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Study The Tradition", subtitle: "Know why you wear the uniform.", identityLine: "You decide the history in the unit patch is part of the strength you carry.", previewTags: ["Discipline +", "Pride"], preferredEventTags: ["military": 6, "identity": 3], microBeat: "The stories that outlive the orders.", baseFriction: .none)
        case .deployTour:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Deploy On Tour", subtitle: "The real test.", identityLine: "You decide the only way to know what you are made of is to go where the year can take it from you.", previewTags: ["Medals", "Trauma risk", "Big payoff"], preferredEventTags: ["military": 9, "risk": 7, "health": 5], microBeat: "Wheels up.", baseFriction: .warning)
        // D1: Family light always statics
        case .familyMeal:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Family Meal", subtitle: "Anchor the day.", identityLine: "You decide the table is still the place where the year slows down and remembers who it belongs to.", previewTags: ["Bond +", "Dossier flavor"], preferredEventTags: ["family": 7, "health": 2], microBeat: "The chairs scrape back.", baseFriction: .none)
        case .storyTime:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Story Time", subtitle: "Pass the thread.", identityLine: "You decide the stories you tell them tonight are the dossier they will carry when you are not in the room.", previewTags: ["Child wiring", "Legacy"], preferredEventTags: ["family": 8, "identity": 4], microBeat: "The lamp clicks off.", baseFriction: .none)
        // D2: Finance/Assets collector & mastery statics (path-specific, era-reactive, fame/lifestyle boosts)
        case .curateCollection:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Curate Collection", subtitle: "Tend the assets that tell your story.", identityLine: "You decide the things you own say as much about you as the things you do.", previewTags: ["Lifestyle +", "Maintenance cost", "KnownFor"], preferredEventTags: ["assets": 8, "finance": 4, "fame": 3], microBeat: "Polishing the trophies.", baseFriction: .none)
        case .hostSignatureEvent:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Host at Signature", subtitle: "Use the house as stage.", identityLine: "You decide your home is the perfect backdrop for the deal, the deal, or the drama.", previewTags: ["Social leverage", "Era flex", "Rep swing"], preferredEventTags: ["social": 7, "assets": 6, "money": 3], microBeat: "The guests arrive.", baseFriction: .resistance)
        case .maintainAsset:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Maintain The Fleet", subtitle: "Keep the shine on the toys.", identityLine: "You decide neglect is more expensive than the upkeep in the long run.", previewTags: ["Asset health +", "Cash burn", "Era risk"], preferredEventTags: ["assets": 7, "finance": 5], microBeat: "The mechanic nods.", baseFriction: .none)
        // D2: Health mastery (condition loops, aging by resilience/lifestyle, body-as-asset)
        case .recurringTherapy:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Recurring Therapy", subtitle: "Scheduled maintenance for the mind.", identityLine: "You decide the patterns don't fix themselves; they need regular appointments.", previewTags: ["Mental +", "Condition management", "Cash tie"], preferredEventTags: ["health": 8, "money": 3], microBeat: "The couch again.", baseFriction: .none)
        case .manageMeds:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Manage The Meds", subtitle: "Trade symptoms for side effects.", identityLine: "You decide the chemical balance is worth the daily ritual and the monthly bill.", previewTags: ["Condition down", "Finance hit", "Health trade"], preferredEventTags: ["health": 7, "money": 4], microBeat: "Pill organizer clicks.", baseFriction: .resistance)
        case .bodyConditioning:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Body Conditioning", subtitle: "Treat the machine as career asset.", identityLine: "You decide your body is the one investment that pays in every other domain.", previewTags: ["Athlete/creator edge", "Aging slow", "Discipline"], preferredEventTags: ["health": 6, "career": 5], microBeat: "The reps that matter.", baseFriction: .none)
        // D2: Relationships depth (per-friend, rivalry, rep split)
        case .deepenSpecificBond:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Deepen One Bond", subtitle: "Pick the person, go all in.", identityLine: "You decide quantity of friends is less valuable than the one who actually knows you.", previewTags: ["Per-friend depth", "Time cost", "Support up"], preferredEventTags: ["relationships": 9, "health": 2], microBeat: "The long conversation.", baseFriction: .none)
        case .fuelRivalry:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Fuel The Rivalry", subtitle: "Let the competition sharpen you.", identityLine: "You decide a little enemy in the circle keeps everyone honest — including you.", previewTags: ["Rivalry heat", "Performance up", "Rep risk"], preferredEventTags: ["social": 5, "career": 4, "risk": 4], microBeat: "The side-eye across the room.", baseFriction: .warning)
        case .splitReputation:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Split Public & Private", subtitle: "Different faces for different rooms.", identityLine: "You decide the version the world sees doesn't have to be the one you go home to.", previewTags: ["Public rep", "Private bond", "Ethics risk"], preferredEventTags: ["social": 6, "risk": 5, "identity": 3], microBeat: "The mask slips back on.", baseFriction: .resistance)
        // D3: Education branches and regular career parity defs
        case .pursueTradeCert:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Pursue Trade Certification", subtitle: "Hands-on path, faster income.", identityLine: "You decide practical skills and quick earning power beat the long academic road.", previewTags: ["Income ramp", "Credential", "Trade bonus"], preferredEventTags: ["career": 7, "education": 5], microBeat: "The shop floor calls.", baseFriction: .none)
        case .honorsTrack:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Lock Into Honors", subtitle: "Prestige and pressure.", identityLine: "You decide the elite track is worth the extra grind for the doors it will open.", previewTags: ["Standing up", "Burnout risk", "Special entry"], preferredEventTags: ["education": 8, "career": 4], microBeat: "The seminar is small.", baseFriction: .resistance)
        case .uniApplication:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Apply to University", subtitle: "The long game.", identityLine: "You decide the degree is the key that unlocks the higher ceiling later.", previewTags: ["Readiness", "Debt risk", "Future fit"], preferredEventTags: ["education": 6, "finance": 3], microBeat: "The applications go out.", baseFriction: .none)
        case .lifelongLearning:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Lifelong Learning", subtitle: "Never stop stacking.", identityLine: "You decide the credential from 22 is just the start; the world rewards the curious forever.", previewTags: ["Skill up", "Standing", "Small cost"], preferredEventTags: ["education": 5, "career": 6], microBeat: "The online module completes.", baseFriction: .none)
        case .credentialRefresh:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Refresh The Credential", subtitle: "Stay current or fade.", identityLine: "You decide the old degree needs new polish or it loses its power in the market.", previewTags: ["Decay reversal", "Cost", "Market edge"], preferredEventTags: ["education": 4, "career": 7], microBeat: "The renewal certificate arrives.", baseFriction: .resistance)
        case .corporateClimb:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Climb The Corporate Ladder", subtitle: "Play the long internal game.", identityLine: "You decide steady promotion inside the machine is safer and more predictable than striking out.", previewTags: ["Rank up", "Politics", "Stability"], preferredEventTags: ["career": 8, "social": 4], microBeat: "The review goes well.", baseFriction: .none)
        case .freelanceHustle:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Go Full Freelance", subtitle: "Own your time and clients.", identityLine: "You decide the gig economy is freedom, even if the safety net is thinner.", previewTags: ["Flex income", "Uncertainty", "Brand"], preferredEventTags: ["career": 7, "finance": 5, "risk": 4], microBeat: "The next invoice lands.", baseFriction: .resistance)
        case .tradesMastery:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Master The Trade", subtitle: "Deep expertise, real value.", identityLine: "You decide becoming the best at a tangible skill beats chasing titles.", previewTags: ["Skill mastery", "Income stable", "Respect"], preferredEventTags: ["career": 8, "education": 3], microBeat: "The job is done right.", baseFriction: .none)
        case .pivotToGig:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Pivot To The Gig Economy", subtitle: "Multiple streams, no boss.", identityLine: "You decide the 9-5 is overrated and you're ready to juggle projects instead.", previewTags: ["Side to main", "Variety", "Income variance"], preferredEventTags: ["career": 6, "finance": 6], microBeat: "The calendar fills with gigs.", baseFriction: .none)
        case .publicServiceGrind:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Grind In Public Service", subtitle: "Steady mission, slower pay.", identityLine: "You decide impact and stability inside the system beat chasing private upside.", previewTags: ["Mission", "Security", "Pension path"], preferredEventTags: ["career": 7, "social": 5], microBeat: "The forms are endless, but the work matters.", baseFriction: .none)
        case .techDeepWork:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Deep Technical Work", subtitle: "Mastery through focus.", identityLine: "You decide the real edge is in the quiet hours solving hard problems others avoid.", previewTags: ["Skill spike", "Focus", "IP edge"], preferredEventTags: ["career": 8, "education": 4], microBeat: "The commit compiles at 2am.", baseFriction: .resistance)
        case .corporateStayLate:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Stay Late", subtitle: "Visibility through hours.", identityLine: "You decide being seen working matters more than leaving on time.", previewTags: ["Perf +", "Burnout +", "Politics"], preferredEventTags: ["career": 7], microBeat: "The building empties around you.", baseFriction: .resistance)
        case .corporatePolitick:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Politick Internally", subtitle: "Play the room.", identityLine: "You decide the ladder is climbed in conversations, not deliverables alone.", previewTags: ["Security +", "Friction +", "Social"], preferredEventTags: ["career": 6, "social": 5], microBeat: "You know who to sit beside.", baseFriction: .none)
        case .corporateDocumentWin:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Document A Win", subtitle: "Make the work legible.", identityLine: "You decide credit only sticks when it is written down in the right format.", previewTags: ["Perf +", "Review ammo"], preferredEventTags: ["career": 7], microBeat: "The slide deck lands.", baseFriction: .none)
        case .tradesExtraFocus:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Extra Job Focus", subtitle: "Push mastery on the tools.", identityLine: "You decide the craft improves when you stay on the work a little longer.", previewTags: ["Skill +", "Body wear"], preferredEventTags: ["career": 8], microBeat: "The hands know the motion.", baseFriction: .resistance)
        case .tradesMaintainTools:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Maintain The Tools", subtitle: "Reliability is the job.", identityLine: "You decide showing up with working gear is half the reputation.", previewTags: ["Security +", "Skill hold"], preferredEventTags: ["career": 6], microBeat: "Everything is squared away.", baseFriction: .none)
        case .tradesSafetyPush:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Push Safety Hard", subtitle: "Protect the body.", identityLine: "You decide no deadline is worth the injury that ends the trade.", previewTags: ["Burnout -", "Durability"], preferredEventTags: ["career": 5, "health": 4], microBeat: "Slow is smooth.", baseFriction: .none)
        case .salesClientOutreach:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Client Outreach", subtitle: "Fill the pipeline.", identityLine: "You decide the next commission lives in the next conversation.", previewTags: ["Pipeline +", "Social tax"], preferredEventTags: ["career": 7, "social": 5], microBeat: "Another dial tone.", baseFriction: .none)
        case .salesPipelineGrind:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Pipeline Grind", subtitle: "Work the numbers.", identityLine: "You decide consistency beats charisma on the slow weeks.", previewTags: ["Perf swing", "Variance"], preferredEventTags: ["career": 8, "finance": 4], microBeat: "The CRM lights up.", baseFriction: .resistance)
        case .salesRecoveryCall:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Recovery Call", subtitle: "Salvage the deal.", identityLine: "You decide one more follow-up is cheaper than starting over.", previewTags: ["Income swing", "Ego hit"], preferredEventTags: ["career": 6], microBeat: "They pick up on the third try.", baseFriction: .none)
        case .gigAcceptSurge:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Accept A Surge", subtitle: "Ride the demand spike.", identityLine: "You decide the algorithm is paying and you will answer while it does.", previewTags: ["Cash +", "Burnout +"], preferredEventTags: ["career": 7, "finance": 6], microBeat: "The phone won't stop.", baseFriction: .warning)
        case .gigMaintainRating:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Protect The Rating", subtitle: "Stars are the safety net.", identityLine: "You decide one bad review costs more than one bad night.", previewTags: ["Security +", "Pressure"], preferredEventTags: ["career": 6], microBeat: "Five stars or nothing.", baseFriction: .none)
        case .gigRestDay:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Take A Rest Day", subtitle: "Refuse the surge.", identityLine: "You decide the hustle can wait one day without collapsing the life.", previewTags: ["Burnout -", "Income dip"], preferredEventTags: ["career": 4, "health": 5], microBeat: "The app stays closed.", baseFriction: .none)
        case .protectSleep:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Protect Your Sleep Like It Matters", subtitle: "Recovery as a strategy.", identityLine: "You decide the year has to be survivable, not just productive.", previewTags: ["+Mental", "Recovery", "School pressure down"], preferredEventTags: ["health": 8, "routine": 4], microBeat: "The world goes dark.", baseFriction: .none)
        case .rest:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Pull Back And Recover", subtitle: "Stabilize before you push again.", identityLine: "You decide not every year needs to prove something.", previewTags: ["Recovery", "Energy"], preferredEventTags: ["health": 7, "routine": 3], microBeat: "Finally, a moment of silence.", baseFriction: .none)
        case .pushThrough:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Push Anyway", subtitle: "Output over recovery.", identityLine: "You decide getting through it matters more than what it costs you in the moment.", previewTags: ["Output", "Recovery loss"], preferredEventTags: ["career": 4, "school": 4, "health": 6], microBeat: "Just keep moving.", baseFriction: .resistance)
        case .seeDoctor:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Get It Checked Before It Gets Worse", subtitle: "Spend for stability.", identityLine: "You decide uncertainty about your body is more expensive than the appointment.", previewTags: ["Care", "Cash cost"], preferredEventTags: ["health": 7, "money": 2], microBeat: "The waiting room smell.", baseFriction: .none)
        case .callInFavor:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Call In A Favor", subtitle: "Spend social capital.", identityLine: "You decide to lean on your network to solve a problem that effort alone cannot reach.", previewTags: ["Favor", "Capital cost", "Door opening"], preferredEventTags: ["social": 6, "chance": 4], microBeat: "Dialing the direct line.", baseFriction: .none)
        case .startCompany:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Launch Your Own Venture", subtitle: "Trade capital for control.", identityLine: "You decide to stop building someone else's dream and start fighting for your own.", previewTags: ["Equity", "Burn rate", "Risk"], preferredEventTags: ["career": 6, "money": 4, "risk": 7], microBeat: "Your name is on the door.", baseFriction: .resistance)
        case .pitchDeck:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Present Pitch Deck", subtitle: "Define the sector & vision.", identityLine: "You step into the room to convince the world your idea is worth the risk.", previewTags: ["Sector selection", "Strategic vision"], preferredEventTags: ["career": 7, "social": 4], microBeat: "Next slide.", baseFriction: .none)
        case .manageFund:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Manage The Fund", subtitle: "Diamond Tier — Criminal Enterprise VC (peak founder/creator + capital required)", identityLine: "You decide that picking the winners (and the ones who disappear) is better than being one of them. The fund is a weapon.", previewTags: ["Diamond", "Empire", "Management fees", "Performance risk", "Notoriety"], preferredEventTags: ["money": 9, "career": 6, "risk": 7], microBeat: "Capital deployed. Lives too.", baseFriction: .resistance)
        case .acquireCompetitor:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Hostile Takeover", subtitle: "Diamond Tier — Criminal Raider (peak founder + capital required)", identityLine: "You decide that if you can't beat them, you'll simply buy them — and strip what you need. The empire grows by breaking others.", previewTags: ["Diamond", "Empire", "Valuation jump", "Heat spike", "Debt", "Legacy"], preferredEventTags: ["career": 8, "risk": 9, "money": 8], microBeat: "Papers signed. Bridges burned.", baseFriction: .warning)
        case .stripAssets:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Liquidate & Strip", subtitle: "Short-term gain, long-term ruin.", identityLine: "You decide the parts are worth more than the whole.", previewTags: ["Cash windfall", "Notoriety spike", "Board risk"], preferredEventTags: ["money": 10, "risk": 9], microBeat: "Everything must go.", baseFriction: .warning)
        case .pivotBusiness:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Pivot The Strategy", subtitle: "Adapt to survive.", identityLine: "You decide the current path is a dead end and force a hard turn.", previewTags: ["Burn down", "Insight", "Momentum loss"], preferredEventTags: ["career": 5, "routine": 4], microBeat: "Hard left.", baseFriction: .resistance)
        case .raiseCapital:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Raise Venture Capital", subtitle: "Trade equity for runway.", identityLine: "You decide that your own money isn't enough and look for outside fuel.", previewTags: ["Cash injection", "Equity loss", "Board pressure"], preferredEventTags: ["money": 7, "social": 5], microBeat: "The check clears.", baseFriction: .none)
        case .aggressiveExpansion:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Scale Aggressively", subtitle: "Growth at all costs.", identityLine: "You decide to capture the market before it captures you.", previewTags: ["Valuation spike", "Burn rate up", "Burnout risk"], preferredEventTags: ["career": 8, "risk": 7], microBeat: "Burn the boats.", baseFriction: .warning)
        case .ipoExit:
            return ActionChoiceDefinition(choiceID: choiceID, title: "The Liquidity Event", subtitle: "Take the company public.", identityLine: "You decide the journey as a founder is done and it's time to cash in.", previewTags: ["Massive wealth", "Legacy", "Exit"], preferredEventTags: ["money": 10, "social": 6], microBeat: "Ringing the bell.", baseFriction: .resistance)
        // E2: New dedicated founder quick actions
        case .closeMajorDeal:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Close Major Deal", subtitle: "Land the big one.", identityLine: "You decide this partnership or customer could change everything.", previewTags: ["Traction +", "Cash", "Pressure up"], preferredEventTags: ["career": 8, "money": 6], microBeat: "The signature hits the table.", baseFriction: .resistance)
        case .allHandsRally:
            return ActionChoiceDefinition(choiceID: choiceID, title: "All-Hands Rally", subtitle: "Re-energize the team.", identityLine: "You stand in front of everyone and remind them why they're here.", previewTags: ["Team health +", "Culture up", "Short-term productivity"], preferredEventTags: ["social": 7, "career": 4], microBeat: "The room feels different.", baseFriction: .none)
        case .fundraiseSprint:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Fundraise Sprint", subtitle: "Hit the road for capital.", identityLine: "You decide the runway is too short and it's time to sell the vision again.", previewTags: ["Cash injection", "Equity risk", "Mental load"], preferredEventTags: ["money": 8, "risk": 6], microBeat: "Another pitch deck at 2am.", baseFriction: .warning)
        case .takeRealBreak:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Take a Real Break", subtitle: "Step away from the machine.", identityLine: "You finally decide that burning out helps no one, least of all the company.", previewTags: ["Mental load down", "Execution dip", "Long-term health"], preferredEventTags: ["health": 8], microBeat: "The laptop stays closed.", baseFriction: .none)
        case .hireKeyTalent:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Hire Key Talent", subtitle: "Bring in someone who changes the game.", identityLine: "You decide the right person is worth whatever it takes.", previewTags: ["Team strength +", "Culture risk", "Burn rate"], preferredEventTags: ["career": 7, "social": 5], microBeat: "The offer goes out.", baseFriction: .resistance)
        // C2: New dedicated creator quick actions
        case .postDaily:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Post Daily", subtitle: "Feed the algorithm.", identityLine: "You decide consistency is the only thing that matters right now.", previewTags: ["Algorithm +", "Burnout risk", "Small audience gain"], preferredEventTags: ["career": 6, "social": 4], microBeat: "Another caption written.", baseFriction: .resistance)
        case .goLive:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Go Live", subtitle: "Raw connection.", identityLine: "You decide the unfiltered version of you is what people need tonight.", previewTags: ["Engagement spike", "Authenticity", "Risk of saying too much"], preferredEventTags: ["social": 8, "risk": 5], microBeat: "Stream is live.", baseFriction: .warning)
        case .filmBanger:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Film a Banger", subtitle: "Swing for the fences.", identityLine: "You decide this one piece of content could be the one that changes everything.", previewTags: ["Viral potential", "High effort", "All or nothing"], preferredEventTags: ["career": 9, "risk": 7], microBeat: "Lights, camera, obsession.", baseFriction: .resistance)
        case .collab:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Collab With Someone Big", subtitle: "Borrow their audience.", identityLine: "You decide the fastest way up is to stand next to someone already there.", previewTags: ["Audience cross-pollination", "Brand risk", "Relationship cost"], preferredEventTags: ["social": 7, "career": 6], microBeat: "The DM was sent.", baseFriction: .none)
        case .addressDrama:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Address The Drama", subtitle: "Control the narrative.", identityLine: "You decide silence is no longer an option.", previewTags: ["Damage control", "Authenticity hit", "Possible recovery"], preferredEventTags: ["social": 8, "risk": 6], microBeat: "The camera is on.", baseFriction: .warning)
        case .takeMentalBreak:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Take a Mental Health Break", subtitle: "Log off.", identityLine: "You finally decide that disappearing for a bit might be the only way to stay alive.", previewTags: ["Burnout relief", "Audience dip", "Long-term health"], preferredEventTags: ["health": 9], microBeat: "Status: offline.", baseFriction: .none)
        case .dropBrandDeal:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Drop a Brand Deal", subtitle: "Cash the bag.", identityLine: "You decide the money is worth whatever it does to your soul this month.", previewTags: ["Cash", "Authenticity cost", "Sponsorship"], preferredEventTags: ["money": 9, "career": 5], microBeat: "The integration is filmed.", baseFriction: .resistance)
        // P2: New dedicated politics quick actions
        case .townHall:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Hold a Town Hall", subtitle: "Face the people.", identityLine: "You decide to stand in front of actual voters and hear what they think of you.", previewTags: ["Approval swing", "Authenticity", "Risk of gaffes"], preferredEventTags: ["social": 8, "career": 5], microBeat: "The room is full of faces.", baseFriction: .warning)
        case .politicalFundraise:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Fundraise Hard", subtitle: "Dial for dollars.", identityLine: "You decide the war chest matters more than your dignity tonight.", previewTags: ["Donor base +", "Ethics risk", "Time sink"], preferredEventTags: ["money": 8, "risk": 5], microBeat: "Another call.", baseFriction: .resistance)
        case .scandalResponse:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Respond to the Scandal", subtitle: "Damage control.", identityLine: "You decide how you will face the latest story about you.", previewTags: ["Scandal management", "Approval risk", "Narrative control"], preferredEventTags: ["social": 7, "risk": 8], microBeat: "The cameras are waiting.", baseFriction: .warning)
        case .policyPush:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Push a Major Policy", subtitle: "Leave a mark.", identityLine: "You decide to bet political capital on something that actually matters.", previewTags: ["Policy legacy", "Approval cost", "Long game"], preferredEventTags: ["career": 9, "social": 4], microBeat: "The bill is introduced.", baseFriction: .resistance)
        case .backroomDeal:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Cut a Backroom Deal", subtitle: "Trade favors.", identityLine: "You decide that the right compromise today can unlock real power tomorrow.", previewTags: ["Power gain", "Ethics hit", "Future leverage"], preferredEventTags: ["career": 7, "risk": 6], microBeat: "The handshake happens.", baseFriction: .warning)
        case .mediaHit:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Do a Big Media Hit", subtitle: "Control the story.", identityLine: "You decide to go on the biggest stage and shape how the country sees you tonight.", previewTags: ["Approval swing", "Charisma test", "Scandal risk"], preferredEventTags: ["social": 9, "career": 5], microBeat: "The lights are hot.", baseFriction: .warning)
        case .takeAStand:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Take a Public Stand", subtitle: "Risk it for principle.", identityLine: "You decide that some lines are worth drawing even if it costs you.", previewTags: ["Ethics gain", "Approval risk", "Polarization"], preferredEventTags: ["social": 6, "career": 7], microBeat: "The statement is released.", baseFriction: .resistance)
        case .attackOpponent:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Attack Your Opponent", subtitle: "Go negative.", identityLine: "You decide that the other side needs to be destroyed before they destroy you.", previewTags: ["Approval swing", "Ethics cost", "Escalation"], preferredEventTags: ["social": 5, "risk": 8], microBeat: "The attack ad drops.", baseFriction: .warning)
        case .intenseTraining:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Push Your Physical Limits", subtitle: "Build the machine.", identityLine: "You decide your body is the only asset that matters this year.", previewTags: ["Peak up", "Burnout", "Injury risk"], preferredEventTags: ["health": 8, "routine": 5], microBeat: "The iron is heavy.", baseFriction: .resistance)
        case .compete:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Enter The Arena", subtitle: "Visibility through performance.", identityLine: "You step onto the stage where the only thing that matters is the result.", previewTags: ["Fame", "Fan base", "Injury risk"], preferredEventTags: ["career": 6, "social": 5, "risk": 4], microBeat: "Heartbeat in your ears.", baseFriction: .warning)
        case .startBoxingCareer:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Start Boxing Career", subtitle: "Enter the Ironline regional circuit.", identityLine: "You choose the ring, the gloves, and a career measured one opponent at a time.", previewTags: ["Boxing", "Record", "Purse", "Damage"], preferredEventTags: ["career": 8, "health": 6, "risk": 5], microBeat: "The gloves are laced.", baseFriction: .warning)
        case .startMMACareer:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Start MMA Career", subtitle: "Enter the Cagefront regional circuit.", identityLine: "You choose the cage and accept that every range of the fight must become yours.", previewTags: ["MMA", "Record", "Purse", "Damage"], preferredEventTags: ["career": 8, "health": 6, "risk": 5], microBeat: "The cage door closes.", baseFriction: .warning)
        case .acceptSafeFight:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Take Safer Opponent", subtitle: "Lower purse, controlled progression.", identityLine: "You choose a fight designed to build the record without gambling the career.", previewTags: ["Safer", "Modest purse", "Small rank gain"], preferredEventTags: ["career": 7], microBeat: "The contract feels manageable.", baseFriction: .none)
        case .acceptRankedFight:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Take Ranked Opponent", subtitle: "Balanced risk and movement.", identityLine: "You choose the opponent who can move your name if you solve the matchup.", previewTags: ["Ranked", "Better purse", "Real risk"], preferredEventTags: ["career": 8, "risk": 5], microBeat: "This one matters.", baseFriction: .warning)
        case .acceptDangerousFight:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Take Dangerous Opponent", subtitle: "High purse, title-level danger.", identityLine: "You choose the fight that can change everything or take years off the career.", previewTags: ["Danger", "High purse", "Title shot"], preferredEventTags: ["career": 9, "risk": 9, "money": 7], microBeat: "Nobody calls this smart.", baseFriction: .danger)
        case .boxingPowerCamp:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Power Camp", subtitle: "Build force and finishing threat.", identityLine: "You shape camp around making every clean punch matter.", previewTags: ["Power +", "Finish chance", "Wear"], preferredEventTags: ["career": 7, "health": 5], microBeat: "The heavy bag swings.", baseFriction: .resistance)
        case .boxingTechniqueCamp:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Technique Camp", subtitle: "Sharpen hands, feet, and defense.", identityLine: "You choose precision over spectacle and drill the mistakes out.", previewTags: ["Speed +", "Footwork +", "Defense +"], preferredEventTags: ["career": 8, "routine": 5], microBeat: "Again. Cleaner.", baseFriction: .resistance)
        case .mmaStrikingCamp:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Striking Camp", subtitle: "Own the fight at range.", identityLine: "You build the camp around damage, entries, and leaving before the return fire.", previewTags: ["Striking +", "Finish chance", "Takedown risk"], preferredEventTags: ["career": 8, "health": 5], microBeat: "Pads crack in rhythm.", baseFriction: .resistance)
        case .mmaGrapplingCamp:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Grappling Camp", subtitle: "Build control and submissions.", identityLine: "You choose the exhausting work of deciding where the fight happens.", previewTags: ["Wrestling +", "Submissions +", "Control"], preferredEventTags: ["career": 8, "routine": 5], microBeat: "Another round on the mat.", baseFriction: .resistance)
        case .combatConditioningCamp:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Conditioning Camp", subtitle: "Prepare to survive the late fight.", identityLine: "You choose lungs, pace, and the ability to think while exhausted.", previewTags: ["Conditioning +", "Late edge", "Burnout"], preferredEventTags: ["health": 7, "career": 6], microBeat: "The last round starts.", baseFriction: .resistance)
        case .combatRecoveryCamp:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Recovery Camp", subtitle: "Arrive healthy instead of overtrained.", identityLine: "You choose to protect the body and trust the skill already built.", previewTags: ["Readiness +", "Wear down", "Smaller gains"], preferredEventTags: ["health": 9], microBeat: "The body gets quiet.", baseFriction: .none)
        case .boxingPressureStrategy:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Pressure Fight", subtitle: "Take space and force exchanges.", identityLine: "You decide the opponent will not get comfortable for one second.", previewTags: ["Pressure", "Power", "Damage risk"], preferredEventTags: ["risk": 7, "career": 7], microBeat: "Walk them down.", baseFriction: .warning)
        case .boxingCounterStrategy:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Counter Fight", subtitle: "Make aggression expensive.", identityLine: "You decide patience and timing will turn their offense against them.", previewTags: ["Defense", "Timing", "Low volume"], preferredEventTags: ["career": 8], microBeat: "Wait for the opening.", baseFriction: .none)
        case .boxingOutsideStrategy:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Box Outside", subtitle: "Win with feet, speed, and distance.", identityLine: "You decide the cleanest fight is the one they cannot reach.", previewTags: ["Footwork", "Speed", "Decision edge"], preferredEventTags: ["career": 8], microBeat: "Touch and move.", baseFriction: .none)
        case .mmaStrikeStrategy:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Strike First", subtitle: "Keep the fight standing.", identityLine: "You decide the fastest route is damage before the grappling starts.", previewTags: ["Striking", "Finish", "Takedown risk"], preferredEventTags: ["risk": 6, "career": 7], microBeat: "Own the center.", baseFriction: .warning)
        case .mmaWrestleStrategy:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Wrestle First", subtitle: "Control position and pace.", identityLine: "You decide to remove chaos by putting the opponent where you want them.", previewTags: ["Wrestling", "Control", "Gas cost"], preferredEventTags: ["career": 8], microBeat: "Change levels.", baseFriction: .resistance)
        case .mmaMixedStrategy:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Mix Every Range", subtitle: "Stay unreadable.", identityLine: "You decide no single pattern will be available long enough to solve.", previewTags: ["Balanced", "Adaptation", "High skill"], preferredEventTags: ["career": 9], microBeat: "Nothing repeats.", baseFriction: .resistance)
        case .crossoverCombatDiscipline:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Cross Over", subtitle: "Switch disciplines once.", identityLine: "You risk your ranking to carry your name into the other combat world.", previewTags: ["Fame kept", "Ranking reset", "Skills convert"], preferredEventTags: ["career": 9, "risk": 6], microBeat: "A different rule set waits.", baseFriction: .warning)
        case .retireFromCombat:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Retire From Fighting", subtitle: "Leave before the sport decides.", identityLine: "You choose to stop trading pieces of the body for another result.", previewTags: ["Career ends", "Legacy", "Health protected"], preferredEventTags: ["career": 8, "health": 8], microBeat: "The gloves stay on the table.", baseFriction: .resistance)
        case .startFightEmpire:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Build Fight Empire", subtitle: "Diamond Tier — own the gym and the cards.", identityLine: "You decide the next legacy will be built through fighters, events, and the machine around them.", previewTags: ["Diamond", "Gym", "Promotion", "Legacy"], preferredEventTags: ["career": 9, "money": 7, "risk": 6], microBeat: "The doors open under your name.", baseFriction: .warning)
        case .recruitFightProspect:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Recruit Prospect", subtitle: "Bet on raw talent.", identityLine: "You put the gym's time and name behind someone who might become real.", previewTags: ["Roster +", "Cash cost", "Future upside"], preferredEventTags: ["career": 8, "social": 5], microBeat: "A new fighter signs.", baseFriction: .none)
        case .buildFightCamp:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Build The Camp", subtitle: "Improve the room around every fighter.", identityLine: "You invest in coaches, equipment, and standards that survive any one athlete.", previewTags: ["Gym +", "Trust +", "Cash cost"], preferredEventTags: ["career": 8, "money": 5], microBeat: "The room gets sharper.", baseFriction: .resistance)
        case .developFightProspect:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Develop Prospect", subtitle: "Turn talent into readiness.", identityLine: "You slow the hype down long enough to build a fighter who can last.", previewTags: ["Prospect +", "Trust +", "Time"], preferredEventTags: ["career": 8, "health": 4], microBeat: "Small corrections compound.", baseFriction: .none)
        case .bookFightEvent:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Book Fight Event", subtitle: "Put the promotion at risk.", identityLine: "You commit the venue, the card, and the money before knowing who will show up.", previewTags: ["Revenue", "Reach", "Risk"], preferredEventTags: ["career": 9, "money": 8, "risk": 6], microBeat: "The date is locked.", baseFriction: .warning)
        case .negotiateBroadcastDeal:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Negotiate Broadcast Deal", subtitle: "Trade control for reach.", identityLine: "You try to turn local attention into a machine that travels.", previewTags: ["Reach +", "Revenue +", "Pressure"], preferredEventTags: ["money": 8, "career": 8], microBeat: "The rights call begins.", baseFriction: .resistance)
        case .protectFighterHealth:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Protect Fighter Health", subtitle: "Cancel bad business before it becomes damage.", identityLine: "You choose the people in the gym over the easiest money on the calendar.", previewTags: ["Trust +", "Regulation down", "Revenue cost"], preferredEventTags: ["health": 9, "career": 4], microBeat: "The unsafe bout is off.", baseFriction: .none)
        case .promoteGrudgeMatch:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Promote Grudge Match", subtitle: "Sell conflict and accept the heat.", identityLine: "You decide attention is worth making the room uglier.", previewTags: ["Reach ++", "Revenue", "Trust risk"], preferredEventTags: ["social": 8, "risk": 8, "money": 7], microBeat: "The microphones are live.", baseFriction: .danger)
        // Phase S2: New dedicated athlete quick actions
        case .extraTrainingSession:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Extra Training Session", subtitle: "Push for marginal gains.", identityLine: "You decide one more rep today might be the difference.", previewTags: ["Peak +", "Injury risk", "Fatigue"], preferredEventTags: ["health": 7, "career": 5], microBeat: "The weights feel heavier tonight.", baseFriction: .resistance)
        case .mediaAppearance:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Media Appearance", subtitle: "Feed the spotlight.", identityLine: "You step in front of the cameras to keep your name relevant.", previewTags: ["Fame +", "Heat up", "Sponsor interest"], preferredEventTags: ["career": 6, "social": 4], microBeat: "The lights are hot.", baseFriction: .none)
        case .recoveryFocus:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Recovery Focus", subtitle: "Listen to the body.", identityLine: "You choose the ice bath and physio over another grind.", previewTags: ["Durability +", "Burnout down", "Short-term performance"], preferredEventTags: ["health": 9], microBeat: "The body finally gets a say.", baseFriction: .none)
        case .teamBonding:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Team Bonding", subtitle: "Invest in the locker room.", identityLine: "You spend time with the guys instead of chasing individual stats.", previewTags: ["Fan loyalty +", "Team chemistry", "Slight fatigue"], preferredEventTags: ["social": 5, "career": 3], microBeat: "Laughter in the weight room.", baseFriction: .none)
        // S3a: The Myth & The Machine — doping temptation (high risk, high reward)
        case .edgeProtocol:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Edge Protocol", subtitle: "Take the risk. Chase the ceiling.", identityLine: "You know exactly what this is. One more edge. One more year at the top.", previewTags: ["Peak ++", "Detection risk", "Health cost", "Legacy stain"], preferredEventTags: ["career": 9, "risk": 8, "health": 6], microBeat: "The needle or the pill. The line you said you'd never cross.", baseFriction: .danger)
        case .gatherIntelligence:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Infiltrate The Circle", subtitle: "Diamond Tier — Shadow Ops (peak special + capital + dossier required)", identityLine: "You decide that knowing what others are hiding is the fastest way up — and the only way to build an empire no one can touch.", previewTags: ["Diamond", "Empire", "Leverage", "Exposure", "Suspicion", "Legacy"], preferredEventTags: ["social": 6, "risk": 8, "career": 6], microBeat: "Watching. Listening. Owning.", baseFriction: .warning)
        case .exploitLeverage:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Play Your Hand", subtitle: "Diamond Tier — Shadow Play (peak special required)", identityLine: "You decide it's time to cash in the favors and fears you've collected. The empire remembers everything.", previewTags: ["Diamond", "Empire", "Promotion shot", "Cash", "Exposure"], preferredEventTags: ["career": 8, "money": 6, "risk": 7], microBeat: "Checkmate. The board is yours.", baseFriction: .warning)
        case .dayTrade:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Trade The Volatility", subtitle: "Diamond Tier — Gray Market Trader (peak founder/creator + capital required)", identityLine: "You decide to chase the noise of the market instead of its signal — because the real money is in the volatility only the connected can surf.", previewTags: ["Diamond", "Empire", "Cash", "Stress", "Market risk", "Notoriety"], preferredEventTags: ["money": 9, "risk": 7, "career": 5], microBeat: "The tape is moving fast today. So is your empire.", baseFriction: .warning)
        case .analyzeMarkets:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Study The Cycles", subtitle: "Trade activity for edge.", identityLine: "You decide patience and perspective are more profitable than adrenaline.", previewTags: ["Insight", "Capital access", "Patience"], preferredEventTags: ["money": 6, "routine": 5], microBeat: "The pattern emerges.", baseFriction: .none)
        
        // Military
        case .enlistArmy, .enlistNavy, .enlistAirForce, .enlistMarines, .enlistCoastGuard, .enlistSpaceForce:
            let branchName = MilitarySystem.branchName(for: choiceID)
            return ActionChoiceDefinition(choiceID: choiceID, title: "Enlist in the \(branchName)", subtitle: "Start your military career as a soldier", detail: "Sign a 4-year contract to serve. Provides discipline and fitness, but restricts freedom.", identityLine: "You are joining the \(branchName).", previewTags: ["Contract", "Discipline", "Fitness"], preferredEventTags: ["career": 8, "health": 4], microBeat: "Signing the papers.", baseFriction: .resistance)
        case .commissionArmy, .commissionNavy, .commissionAirForce, .commissionMarines, .commissionCoastGuard, .commissionSpaceForce:
            let branchName = MilitarySystem.branchName(for: choiceID)
            return ActionChoiceDefinition(choiceID: choiceID, title: "Commission in the \(branchName)", subtitle: "Leading from the front", detail: "Use your degree to start as an officer. Higher pay and responsibility.", identityLine: "You are taking a leadership role in the military.", previewTags: ["Officer", "Pay up", "Responsibility"], preferredEventTags: ["career": 9, "social": 5], microBeat: "Swearing the oath.", baseFriction: .resistance)
        case .joinReservesArmy, .joinReservesNavy, .joinReservesAirForce, .joinReservesMarines, .joinReservesCoastGuard, .joinReservesSpaceForce:
            let branchName = MilitarySystem.branchName(for: choiceID)
            return ActionChoiceDefinition(choiceID: choiceID, title: "Join \(branchName) Reserves", subtitle: "One weekend a month, two weeks a year", detail: "Balance civilian life with military service. Flexible, but always ready.", identityLine: "You are joining the \(branchName) Reserves.", previewTags: ["Reserve", "Balance", "Ready"], preferredEventTags: ["career": 6, "routine": 4], microBeat: "Reporting for drill.", baseFriction: .none)
        case .militaryService:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Standard Service", subtitle: "Perform your daily duties", detail: "Focus on excellence in your current role. Improves performance and discipline.", identityLine: "You are dedicated to your service.", previewTags: ["Performance", "Discipline", "Fitness"], preferredEventTags: ["career": 7, "routine": 5], microBeat: "Another day on duty.", baseFriction: .none)
        case .goAWOL:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Go AWOL", subtitle: "Walk away from your post", detail: "Abandon your duties temporarily. High risk of legal trouble.", identityLine: "You are running from your obligations.", previewTags: ["Freedom", "Heat", "Crime"], preferredEventTags: ["risk": 8, "social": 4], microBeat: "You don't look back.", baseFriction: .warning)
        case .desert:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Desert", subtitle: "Leave the military for good", detail: "Abandon your service entirely. You will be hunted by military police.", identityLine: "You are a deserter.", previewTags: ["Heat spike", "Dishonorable", "Risk"], preferredEventTags: ["risk": 10, "crime": 8], microBeat: "Disappearing into the night.", baseFriction: .warning)
        case .militaryRetirement:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Retire/Resign", subtitle: "Leave the service honorably", detail: "Complete your contract or retire after 20 years.", identityLine: "You are transitioning back to civilian life.", previewTags: ["Freedom", "Pension", "Transition"], preferredEventTags: ["career": 6, "money": 5], microBeat: "The final salute.", baseFriction: .resistance)
        case .deploy:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Volunteer for Deployment", subtitle: "Go where the action is", detail: "Seek an overseas mission. Higher risk, but higher reward.", identityLine: "You are stepping up for your country.", previewTags: ["Deployment", "Risk", "Valor"], preferredEventTags: ["career": 7, "risk": 7], microBeat: "Packing your gear.", baseFriction: .warning)
            
        case .joinROTC:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Join ROTC", subtitle: "Train while you study", detail: "Receive a stipend and specialized training. Requires a post-grad commission.", identityLine: "You are balancing books and boots.", previewTags: ["Stipend", "Discipline", "Commission"], preferredEventTags: ["education": 6, "career": 5], microBeat: "Marching on the quad.", baseFriction: .none)
        case .leaveROTC:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Leave ROTC", subtitle: "Focus solely on academics", detail: "Stop your military training. You lose your stipend and commission path.", identityLine: "You are returning to regular student life.", previewTags: ["Freedom", "No Stipend"], preferredEventTags: ["education": 4], microBeat: "Turning in your uniform.", baseFriction: .none)
        case .selectCombatMOS, .selectMedicalMOS, .selectAviationMOS, .selectIntelMOS, .selectLogisticsMOS:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Select Specialization", subtitle: "Define your role", detail: "Choose your primary Military Occupational Specialty (MOS).", identityLine: "You are choosing your path in the service.", previewTags: ["Specialty", "Stats"], preferredEventTags: ["career": 7], microBeat: "Filling out the preference sheet.", baseFriction: .none)
        case .useGIBill:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Use GI Bill", subtitle: "Fund your education", detail: "Apply your veteran benefits to cover tuition costs.", identityLine: "You are investing in your future after service.", previewTags: ["Free Tuition", "Smarts"], preferredEventTags: ["education": 9], microBeat: "Applying for benefits.", baseFriction: .none)
        case .seekVAHealthcare:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Seek VA Healthcare", subtitle: "Treat service-related issues", detail: "Access specialized care for physical and mental trauma.", identityLine: "You are taking care of your health.", previewTags: ["Recovery", "Wellness"], preferredEventTags: ["health": 8], microBeat: "Checking in at the clinic.", baseFriction: .none)
        case .claimPension:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Claim Pension", subtitle: "Receive retirement pay", detail: "Access the annual income you earned through 20+ years of service.", identityLine: "You are reaping the rewards of a long career.", previewTags: ["Passive Income", "Wealth"], preferredEventTags: ["money": 9], microBeat: "Verifying the direct deposit.", baseFriction: .none)
            
        case .applyForResidency:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Apply for Residency", subtitle: "Enter specialized training", detail: "The first step toward becoming an attending physician. Brutal hours, but high future upside.", identityLine: "You are entering the gauntlet of medical training.", previewTags: ["High Burnout", "MD Path"], preferredEventTags: ["career": 8, "health": 10], microBeat: "The match results are in.", baseFriction: .resistance)
        case .completeResidency:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Complete Residency", subtitle: "Become an Attending", detail: "Transition from training to a full professional role. Salary spikes and burnout stabilizes.", identityLine: "You are finally a fully licensed doctor.", previewTags: ["Salary Spike", "Reputation"], preferredEventTags: ["career": 10, "money": 8], microBeat: "Signing the contract.", baseFriction: .none)
        case .openPrivatePractice:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Open Private Practice", subtitle: "Be your own boss", detail: "Leave the hospital system to start your own clinic. High overhead, but highest income potential.", identityLine: "You are an independent medical professional.", previewTags: ["Entrepreneurial", "High Income"], preferredEventTags: ["career": 9, "money": 10], microBeat: "The keys are in your hand.", baseFriction: .resistance)
        case .passBarExam:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Pass the Bar", subtitle: "License to practice law", detail: "A critical milestone. Allows you to transition from Clerk to Associate.", identityLine: "You are a licensed attorney.", previewTags: ["License", "Associate Path"], preferredEventTags: ["career": 7, "smarts": 10], microBeat: "Your name is on the list.", baseFriction: .resistance)
        case .makePartner:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Make Partner", subtitle: "Peak legal achievement", detail: "Secure equity and leadership in the firm. Massive social capital and wealth.", identityLine: "You are at the top of the legal hierarchy.", previewTags: ["Equity", "Standing"], preferredEventTags: ["career": 10, "social": 10], microBeat: "The senior partners are waiting.", baseFriction: .resistance)
        case .becomeCTO:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Become CTO", subtitle: "Technological leadership", detail: "Take control of a company's technical direction. High fame and influence.", identityLine: "You are a technical leader.", previewTags: ["Fame", "Salary"], preferredEventTags: ["career": 9, "tech": 10], microBeat: "Leading the strategy.", baseFriction: .none)
        case .launchStartupSpinOff:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Launch Spin-off", subtitle: "Technical entrepreneurship", detail: "Use your industry expertise to launch a specialized startup.", identityLine: "You are technical visionary.", previewTags: ["Spec Career Path", "Risk"], preferredEventTags: ["career": 8, "money": 7], microBeat: "Drafting the whitepaper.", baseFriction: .resistance)

        default:
            return ActionChoiceDefinition(
                choiceID: choiceID,
                title: "Make Your Move",
                subtitle: "Carry the year forward.",
                identityLine: "You decide this year needs a deliberate push instead of drift.",
                previewTags: ["Momentum"],
                preferredEventTags: [:],
                microBeat: "You commit to the choice.",
                baseFriction: .none
            )
        }
    }

    static func baseResolutionTier(for choiceID: ActionChoiceID) -> ActionResolutionTier {
        // Global shift: All actions are now instant to eliminate "saved this year" state.
        return .instant
    }

    static func resolutionTier(for choiceID: ActionChoiceID) -> ActionResolutionTier {
        baseResolutionTier(for: choiceID)
    }

    static func preferredEventWeights(for actions: [PlayerYearAction]) -> [String: Int] {
        var weights: [String: Int] = [:]
        for action in actions {
            for (tag, weight) in definition(for: action.choiceID).preferredEventTags {
                weights[tag, default: 0] += weight
            }
        }
        return weights
    }
}

enum QuickActionCatalog {
    static func choices(for domain: ActionDomain, state: GameState) -> [ActionChoiceID] {
        registry(for: state).availableQuick(for: domain)
    }

    static func title(for choiceID: ActionChoiceID) -> String {
        DomainActionRegistry.quickActionTitle(for: choiceID)
    }

    private static func registry(for state: GameState) -> DomainActionRegistry {
        let isTeen = state.player.age <= 17
        let isStudent = state.player.age <= 22 && (state.education.pathway == .student || state.education.pathway == .training)
        let reserve = max(2_500, state.finance.annualNetIncome / 4)
        return DomainActionRegistry(
            context: DomainActionContext(
                state: state,
                isTeenExperience: isTeen,
                isStudentLifeExperience: isStudent,
                canAccessInvesting: state.player.age >= 18 && state.finance.isEligibleToCompound(emergencyReserve: reserve),
                investmentEmergencyReserve: reserve
            )
        )
    }
}

extension ActionChoiceDefinition {
    var resolutionTier: ActionResolutionTier {
        ActionChoiceCatalog.resolutionTier(for: choiceID)
    }
}

