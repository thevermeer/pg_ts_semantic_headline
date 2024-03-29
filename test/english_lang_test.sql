
-- Test the add_numbers function
BEGIN;

    CREATE EXTENSION IF NOT EXISTS pgtap;
    CREATE EXTENSION IF NOT EXISTS unaccent;
    CREATE EXTENSION IF NOT EXISTS tsp_semantic_headline;

    SELECT plan(6);

    -- Test Case 1: 2 + 3 should equal 5

    CREATE TEMP TABLE _files(content text) ON COMMIT DROP;

    INSERT INTO _files VALUES ('It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way—in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.LARGE_TEXT_TO_TSVECTOR_CHUNKSThere were a king with a large jaw and a queen with a plain face, on the throne of England; there were a king with a large jaw and a queen with a fair face, on the throne of France. In both countries it was clearer than crystal to the lords of the State preserves of loaves and fishes, that things in general were settled for ever.LARGE_TEXT_TO_TSVECTOR_CHUNKSIt was the year of Our Lord one thousand seven hundred and seventy-five. Spiritual revelations were conceded to England at that favoured period, as at this. Mrs. Southcott had recently attained her five-and-twentieth blessed birthday, of whom a prophetic private in the Life Guards had heralded the sublime appearance by announcing that arrangements were made for the swallowing up of London and Westminster. Even the Cock-lane ghost had been laid only a round dozen of years, after rapping out its messages, as the spirits of this very year last past (supernaturally deficient in originality) rapped out theirs. Mere messages in the earthly order of events had lately come to the English Crown and People, from a congress of British subjects in America: which, strange to relate, have proved more important to the human race than any communications yet received through any of the chickens of the Cock-lane brood.LARGE_TEXT_TO_TSVECTOR_CHUNKSFrance, less favoured on the whole as to matters spiritual than her sister of the shield and trident, rolled with exceeding smoothness down hill, making paper money and spending it. Under the guidance of her Christian pastors, she entertained herself, besides, with such humane achievements as sentencing a youth to have his hands cut off, his tongue torn out with pincers, and his body burned alive, because he had not kneeled down in the rain to do honour to a dirty procession of monks which passed within his view, at a distance of some fifty or sixty yards. It is likely enough that, rooted in the woods of France and Norway, there were growing trees, when that sufferer was put to death, already marked by the Woodman, Fate, to come down and be sawn into boards, to make a certain movable framework with a sack and a knife in it, terrible in history. It is likely enough that in the rough outhouses of some tillers of the heavy lands adjacent to Paris, there were sheltered from the weather that very day, rude carts, bespattered with rustic mire, snuffed about by pigs, and roosted in by poultry, which the Farmer, Death, had already set apart to be his tumbrils of the Revolution. But that Woodman and that Farmer, though they work unceasingly, work silently, and no one heard them as they went about with muffled tread: the rather, forasmuch as to entertain any suspicion that they were awake, was to be atheistical and traitorous.LARGE_TEXT_TO_TSVECTOR_CHUNKSIn England, there was scarcely an amount of order and protection to justify much national boasting. Daring burglaries by armed men, and highway robberies, took place in the capital itself every night; families were publicly cautioned not to go out of town without removing their furniture to upholsterers’ warehouses for security; the highwayman in the dark was a City tradesman in the light, and, being recognised and challenged by his fellow-tradesman whom he stopped in his character of “the Captain,” gallantly shot him through the head and rode away; the mail was waylaid by seven robbers, and the guard shot three dead, and then got shot dead himself by the other four, “in consequence of the failure of his ammunition:” after which the mail was robbed in peace; that magnificent potentate, the Lord Mayor of London, was made to stand and deliver on Turnham Green, by one highwayman, who despoiled the illustrious creature in sight of all his retinue; prisoners in London gaols fought battles with their turnkeys, and the majesty of the law fired blunderbusses in among them, loaded with rounds of shot and ball; thieves snipped off diamond crosses from the necks of noble lords at Court drawing-rooms; musketeers went into St. Giles’s, to search for contraband goods, and the mob fired on the musketeers, and the musketeers fired on the mob, and nobody thought any of these occurrences much out of the common way. In the midst of them, the hangman, ever busy and ever worse than useless, was in constant requisition; now, stringing up long rows of miscellaneous criminals; now, hanging a housebreaker on Saturday who had been taken on Tuesday; now, burning people in the hand at Newgate by the dozen, and now burning pamphlets at the door of Westminster Hall; to-day, taking the life of an atrocious murderer, and to-morrow of a wretched pilferer who had robbed a farmer’s boy of sixpence.LARGE_TEXT_TO_TSVECTOR_CHUNKSAll these things, and a thousand like them, came to pass in and close upon the dear old year one thousand seven hundred and seventy-five. Environed by them, while the Woodman and the Farmer worked unheeded, those two of the large jaws, and those other two of the plain and the fair faces, trod with stir enough, and carried their divine rights with a high hand. Thus did the year one thousand seven hundred and seventy-five conduct their Greatnesses, and 
myriads of small creatures—the creatures of this chronicle among the rest—along the roads that lay before them. ----- CHAPTER 2
It was the Dover road that lay, on a Friday night late in November, before the first of the persons with whom this history has business. The Dover road lay, as to him, beyond the Dover mail, as it lumbered up Shooter’s Hill. He walked up hill in the mire by the side of the mail, as the rest of the passengers did; not because they had the least relish for walking exercise, under the circumstances, but because the hill, and the harness, and the mud, and the mail, were all so heavy, that the horses had three times already come to a stop, besides once drawing the coach across the road, with the mutinous intent of taking it back to Blackheath. Reins and whip and coachman and guard, however, in combination, had read that article of war which forbade a purpose otherwise strongly in favour of the argument, that some brute animals are endued with Reason; and the team had capitulated and returned to their duty.
With drooping heads and tremulous tails, they mashed their way through the thick mud, floundering and stumbling between whiles, as if they were falling to pieces at the larger joints. As often as the driver rested them and brought them to a stand, with a wary “Wo-ho! so-ho-then!” the near leader violently shook his head and everything upon it—like an unusually emphatic horse, denying that the coach could be got up the hill. Whenever the leader made this rattle, the passenger started, as a nervous passenger might, and was disturbed in mind.
There was a steaming mist in all the hollows, and it had roamed in its forlornness up the hill, like an evil spirit, seeking rest and finding none. A clammy and intensely cold mist, it made its slow way through the air in ripples that visibly followed and overspread one another, as the waves of an unwholesome sea might do. It was dense enough to shut out everything from the light of the coach-lamps but these its own workings, and a few yards of road; and the reek of the labouring horses steamed into it, as if they had made it all.
Two other passengers, besides the one, were plodding up the hill by the side of the mail. All three were wrapped to the cheekbones and over the ears, and wore jack-boots. Not one of the three could have said, from anything he saw, what either of the other two was like; and each was hidden under almost as many wrappers from the eyes of the mind, as from the eyes of the body, of his two companions. In those days, travellers were very shy of being confidential on a short notice, for anybody on the road might be a robber or in league with robbers. As to the latter, when every posting-house and ale-house could produce somebody in “the Captain’s” pay, ranging from the landlord to the lowest stable non-descript, it was the likeliest thing upon the cards. So the guard of the Dover mail thought to himself, that Friday night in November, one thousand seven hundred and seventy-five, lumbering up Shooter’s Hill, as he stood on his own particular perch behind the mail, beating his feet, and keeping an eye and a hand on the arm-chest before him, where a loaded blunderbuss lay at the top of six or eight loaded horse-pistols, deposited on a substratum of cutlass.
The Dover mail was in its usual genial position that the guard suspected the passengers, the passengers suspected one another and the guard, they all suspected everybody else, and the coachman was sure of nothing but the horses; as to which cattle he could with a clear conscience have taken his oath on the two Testaments that they were not fit for the journey.
“Wo-ho!” said the coachman. “So, then! One more pull and you’re at the top and be damned to you, for I have had trouble enough to get you to it!—Joe!”
“Halloa!” the guard replied.
The emphatic horse, cut short by the whip in a most decided negative, made a decided scramble for it, and the three other horses followed suit. Once more, the Dover mail struggled on, with the jack-boots of its passengers squashing along by its side. They had stopped when the coach stopped, and they kept close company with it. If any one of the three had had the hardihood to propose to another to walk on a little ahead into the mist and darkness, he would have put himself in a fair way of getting shot instantly as a highwayman.
“What do you say, Tom?”
They both listened.
“I say a horse at a canter coming up, Joe.”
“I say a horse at a gallop, Tom,” returned the guard, leaving his hold of the door, and mounting nimbly to his place. “Gentlemen! In the king’s name, all of you!”
With this hurried adjuration, he cocked his blunderbuss, and stood on the offensive.
The stillness consequent on the cessation of the rumbling and labouring of the coach, added to the stillness of the night, made it very quiet indeed. The panting of the horses communicated a tremulous motion to the coach, as if it were in a state of agitation. The hearts of the passengers beat loud enough perhaps to be heard; but at any rate, the quiet pause was audibly expressive of people out of breath, and holding the breath, and having the pulses quickened by expectati
The sound of a horse at a gallop came fast and furiously up the hill.');

SELECT
        UNNEST(ARRAY[
        IS(ts_semantic_headline(content, TO_TSQUERY('best<2>time|worst<2>time')), 
        '<b>best of times,</b> it was the <b>worst of times,</b> it was the age of wisdom',        
        'English Test 1: Seeking Query: best<2>time|worst<2>time'), 
        
        IS(ts_semantic_headline(content, PHRASETO_TSQUERY('decide negatively')), 
        '<b>decided negative,</b> made a decided scramble for it, and the three other horses followed suit', 
        'English Test 2: Seeking Phrase `decide negatively`'),

        IS(ts_semantic_headline(content, PHRASETO_TSQUERY('hurried adjuration, he cocked his blunderbuss')), 
        '<b>hurried adjuration, he cocked his blunderbuss,</b> and stood on the offensive. The stillness consequent on the cessation', 
        'English Test 3; Seeking Phrase: hurried adjuration, he cocked his blunderbuss`'),

        IS(ts_semantic_headline(content, PHRASETO_TSQUERY('gallop came fast and furiously up the hill')), 
        'expectati The sound of a horse at a <b>gallop came fast and furiously up the hill.</b>', 
        'English Test 4; Seeking: horse at a gallop`'),
        
        IS(ts_semantic_headline(content, PHRASETO_TSQUERY('time')), 
        '<b>times,</b> it was the worst of <b>times,</b> it was the age of wisdom, it was the age of foolishness', 
        'English Test 5; Seeking: Time`'),

        -- FAST HEADLINE
        IS(ts_fast_headline(TO_TSP_TEXT_ARRAY(content), TO_TSPVECTOR(content), TO_TSQUERY('best<2>time|worst<2>time')), 
        'It was the <b>best of times,</b> it was the <b>worst of times,</b> it was the age of wisdom, it was the age',        
        'English Test 6: Seeking Query: best<2>time|worst<2>time'), 
        
        IS(ts_semantic_headline(content, PHRASETO_TSQUERY('decide negatively')), 
        '<b>decided negative,</b> made a decided scramble for it, and the three other horses followed suit', 
        'English Test 7: Seeking Phrase `decide negatively`'),

        IS(ts_semantic_headline(content, PHRASETO_TSQUERY('hurried adjuration, he cocked his blunderbuss')), 
        '<b>hurried adjuration, he cocked his blunderbuss,</b> and stood on the offensive. The stillness consequent on the cessation', 
        'English Test 8; Seeking Phrase: hurried adjuration, he cocked his blunderbuss`'),

        IS(ts_semantic_headline(content, PHRASETO_TSQUERY('gallop came fast and furiously up the hill')), 
        'expectati The sound of a horse at a <b>gallop came fast and furiously up the hill.</b>', 
        'English Test 9; Seeking: horse at a gallop`'),
        
        IS(ts_semantic_headline(content, PHRASETO_TSQUERY('time')), 
        '<b>times,</b> it was the worst of <b>times,</b> it was the age of wisdom, it was the age of foolishness', 
        'English Test 10; Seeking: Time`'),

        -- Simple Parsing
        IS(ts_semantic_headline(content, TO_TSQUERY('best<2>time|worst<2>time')), 
        '<b>best of times,</b> it was the <b>worst of times,</b> it was the age of wisdom',        
        'English Test 11: Seeking Query: best<2>time|worst<2>time'), 
        
        IS(ts_semantic_headline(content, PHRASETO_TSQUERY('decide negatively')), 
        '<b>decided negative,</b> made a decided scramble for it, and the three other horses followed suit', 
        'English Test 12: Seeking Phrase `decide negatively`'),

        IS(ts_semantic_headline(content, PHRASETO_TSQUERY('hurried adjuration, he cocked his blunderbuss')), 
        '<b>hurried adjuration, he cocked his blunderbuss,</b> and stood on the offensive. The stillness consequent on the cessation', 
        'English Test 13; Seeking Phrase: hurried adjuration, he cocked his blunderbuss`'),

        IS(ts_semantic_headline(content, PHRASETO_TSQUERY('gallop came fast and furiously up the hill')), 
        'expectati The sound of a horse at a <b>gallop came fast and furiously up the hill.</b>', 
        'English Test 14; Seeking: horse at a gallop`'),
        
        IS(ts_semantic_headline(content, PHRASETO_TSQUERY('time')), 
        '<b>times,</b> it was the worst of <b>times,</b> it was the age of wisdom, it was the age of foolishness', 
        'English Test 15; Seeking: Time`')

        ]) AS ts_semantic_headline_assertions

    FROM _files;

-- End the test
ROLLBACK;


