CREATE TABLE files (
    id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    content text,
    content_tsv tsvector,
    content_exact_tsv tsvector,
    indexed_content text,
    content_arr text[]
);

-- Indices -------------------------------------------------------

CREATE UNIQUE INDEX files_pkey ON files(id int4_ops);
CREATE INDEX files_content_tsv_gin_idx ON files USING GIN (content_tsv tsvector_ops);

-- Trigger

-- Create or replace the trigger function
CREATE OR REPLACE FUNCTION trg_update_content_tsv()
RETURNS TRIGGER AS $$
DECLARE result_string TEXT;
BEGIN
	NEW.indexed_content   := tsp_indexable_text(NEW.content);
    NEW.content_tsv       := to_tsvector(NEW.indexed_content);
    NEW.content_exact_tsv := to_tsvector('simple', NEW.indexed_content);    
    NEW.content_arr       := regexp_split_to_array(NEW.indexed_content, '[\s]+');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create the trigger on the files table
CREATE TRIGGER update_content_tsv_trigger
BEFORE INSERT OR UPDATE OF content ON files
FOR EACH ROW
EXECUTE FUNCTION trg_update_content_tsv();


INSERT INTO files (content)
SELECT CONCAT(REPEAT('It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way—in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.

There were a king with a large jaw and a queen with a plain face, on the throne of England; there were a king with a large jaw and a queen with a fair face, on the throne of France. In both countries it was clearer than crystal to the lords of the State preserves of loaves and fishes, that things in general were settled for ever.

It was the year of Our Lord one thousand seven hundred and seventy-five. Spiritual revelations were conceded to England at that favoured period, as at this. Mrs. Southcott had recently attained her five-and-twentieth blessed birthday, of whom a prophetic private in the Life Guards had heralded the sublime appearance by announcing that arrangements were made for the swallowing up of London and Westminster. Even the Cock-lane ghost had been laid only a round dozen of years, after rapping out its messages, as the spirits of this very year last past (supernaturally deficient in originality) rapped out theirs. Mere messages in the earthly order of events had lately come to the English Crown and People, from a congress of British subjects in America: which, strange to relate, have proved more important to the human race than any communications yet received through any of the chickens of the Cock-lane brood.

France, less favoured on the whole as to matters spiritual than her sister of the shield and trident, rolled with exceeding smoothness down hill, making paper money and spending it. Under the guidance of her Christian pastors, she entertained herself, besides, with such humane achievements as sentencing a youth to have his hands cut off, his tongue torn out with pincers, and his body burned alive, because he had not kneeled down in the rain to do honour to a dirty procession of monks which passed within his view, at a distance of some fifty or sixty yards. It is likely enough that, rooted in the woods of France and Norway, there were growing trees, when that sufferer was put to death, already marked by the Woodman, Fate, to come down and be sawn into boards, to make a certain movable framework with a sack and a knife in it, terrible in history. It is likely enough that in the rough outhouses of some tillers of the heavy lands adjacent to Paris, there were sheltered from the weather that very day, rude carts, bespattered with rustic mire, snuffed about by pigs, and roosted in by poultry, which the Farmer, Death, had already set apart to be his tumbrils of the Revolution. But that Woodman and that Farmer, though they work unceasingly, work silently, and no one heard them as they went about with muffled tread: the rather, forasmuch as to entertain any suspicion that they were awake, was to be atheistical and traitorous.

In England, there was scarcely an amount of order and protection to justify much national boasting. Daring burglaries by armed men, and highway robberies, took place in the capital itself every night; families were publicly cautioned not to go out of town without removing their furniture to upholsterers’ warehouses for security; the highwayman in the dark was a City tradesman in the light, and, being recognised and challenged by his fellow-tradesman whom he stopped in his character of “the Captain,” gallantly shot him through the head and rode away; the mail was waylaid by seven robbers, and the guard shot three dead, and then got shot dead himself by the other four, “in consequence of the failure of his ammunition:” after which the mail was robbed in peace; that magnificent potentate, the Lord Mayor of London, was made to stand and deliver on Turnham Green, by one highwayman, who despoiled the illustrious creature in sight of all his retinue; prisoners in London gaols fought battles with their turnkeys, and the majesty of the law fired blunderbusses in among them, loaded with rounds of shot and ball; thieves snipped off diamond crosses from the necks of noble lords at Court drawing-rooms; musketeers went into St. Giles’s, to search for contraband goods, and the mob fired on the musketeers, and the musketeers fired on the mob, and nobody thought any of these occurrences much out of the common way. In the midst of them, the hangman, ever busy and ever worse than useless, was in constant requisition; now, stringing up long rows of miscellaneous criminals; now, hanging a housebreaker on Saturday who had been taken on Tuesday; now, burning people in the hand at Newgate by the dozen, and now burning pamphlets at the door of Westminster Hall; to-day, taking the life of an atrocious murderer, and to-morrow of a wretched pilferer who had robbed a farmer’s boy of sixpence.

All these things, and a thousand like them, came to pass in and close upon the dear old year one thousand seven hundred and seventy-five. Environed by them, while the Woodman and the Farmer worked unheeded, those two of the large jaws, and those other two of the plain and the fair faces, trod with stir enough, and carried their divine rights with a high hand. Thus did the year one thousand seven hundred and seventy-five conduct their Greatnesses, and 
myriads of small creatures—the creatures of this chronicle among the rest—along the roads that lay before them. 

----- CHAPTER 2

It was the Dover road that lay, on a Friday night late in November, before the first of the persons with whom this history has business. The Dover road lay, as to him, beyond the Dover mail, as it lumbered up Shooter’s Hill. He walked up hill in the mire by the side of the mail, as the rest of the passengers did; not because they had the least relish for walking exercise, under the circumstances, but because the hill, and the harness, and the mud, and the mail, were all so heavy, that the horses had three times already come to a stop, besides once drawing the coach across the road, with the mutinous intent of taking it back to Blackheath. Reins and whip and coachman and guard, however, in combination, had read that article of war which forbade a purpose otherwise strongly in favour of the argument, that some brute animals are endued with Reason; and the team had capitulated and returned to their duty.

With drooping heads and tremulous tails, they mashed their way through the thick mud, floundering and stumbling between whiles, as if they were falling to pieces at the larger joints. As often as the driver rested them and brought them to a stand, with a wary “Wo-ho! so-ho-then!” the near leader violently shook his head and everything upon it—like an unusually emphatic horse, denying that the coach could be got up the hill. Whenever the leader made this rattle, the passenger started, as a nervous passenger might, and was disturbed in mind.

There was a steaming mist in all the hollows, and it had roamed in its forlornness up the hill, like an evil spirit, seeking rest and finding none. A clammy and intensely cold mist, it made its slow way through the air in ripples that visibly followed and overspread one another, as the waves of an unwholesome sea might do. It was dense enough to shut out everything from the light of the coach-lamps but these its own workings, and a few yards of road; and the reek of the labouring horses steamed into it, as if they had made it all.

Two other passengers, besides the one, were plodding up the hill by the side of the mail. All three were wrapped to the cheekbones and over the ears, and wore jack-boots. Not one of the three could have said, from anything he saw, what either of the other two was like; and each was hidden under almost as many wrappers from the eyes of the mind, as from the eyes of the body, of his two companions. In those days, travellers were very shy of being confidential on a short notice, for anybody on the road might be a robber or in league with robbers. As to the latter, when every posting-house and ale-house could produce somebody in “the Captain’s” pay, ranging from the landlord to the lowest stable non-descript, it was the likeliest thing upon the cards. So the guard of the Dover mail thought to himself, that Friday night in November, one thousand seven hundred and seventy-five, lumbering up Shooter’s Hill, as he stood on his own particular perch behind the mail, beating his feet, and keeping an eye and a hand on the arm-chest before him, where a loaded blunderbuss lay at the top of six or eight loaded horse-pistols, deposited on a substratum of cutlass.

The Dover mail was in its usual genial position that the guard suspected the passengers, the passengers suspected one another and the guard, they all suspected everybody else, and the coachman was sure of nothing but the horses; as to which cattle he could with a clear conscience have taken his oath on the two Testaments that they were not fit for the journey.

“Wo-ho!” said the coachman. “So, then! One more pull and you’re at the top and be damned to you, for I have had trouble enough to get you to it!—Joe!”

“Halloa!” the guard replied.

“What o’clock do you make it, Joe?”

“Ten minutes, good, past eleven.”

“My blood!” ejaculated the vexed coachman, “and not atop of Shooter’s yet! Tst! Yah! Get on with you!”

The emphatic horse, cut short by the whip in a most decided negative, made a decided scramble for it, and the three other horses followed suit. Once more, the Dover mail struggled on, with the jack-boots of its passengers squashing along by its side. They had stopped when the coach stopped, and they kept close company with it. If any one of the three had had the hardihood to propose to another to walk on a little ahead into the mist and darkness, he would have put himself in a fair way of getting shot instantly as a highwayman.

The last burst carried the mail to the summit of the hill. The horses stopped to breathe again, and the guard got down to skid the wheel for the descent, and open the coach-door to let the passengers in.

“Tst! Joe!” cried the coachman in a warning voice, looking down from his box.

“What do you say, Tom?”

They both listened.

“I say a horse at a canter coming up, Joe.”

“I say a horse at a gallop, Tom,” returned the guard, leaving his hold of the door, and mounting nimbly to his place. “Gentlemen! In the king’s name, all of you!”

With this hurried adjuration, he cocked his blunderbuss, and stood on the offensive.

The passenger booked by this history, was on the coach-step, getting in; the two other passengers were close behind him, and about to follow. He remained on the step, half in the coach and half out of; they remained in the road below him. They all looked from the coachman to the guard, and from the guard to the coachman, and listened. The coachman looked back and the guard looked back, and even the emphatic leader pricked up his ears and looked back, without contradicting.

The stillness consequent on the cessation of the rumbling and labouring of the coach, added to the stillness of the night, made it very quiet indeed. The panting of the horses communicated a tremulous motion to the coach, as if it were in a state of agitation. The hearts of the passengers beat loud enough perhaps to be heard; but at any rate, the quiet pause was audibly expressive of people out of breath, and holding the breath, and having the pulses quickened by expectation.

The sound of a horse at a gallop came fast and furiously up the hill.

“So-ho!” the guard sang out, as loud as he could roar. “Yo there! Stand! I shall fire!”

The pace was suddenly checked, and, with much splashing and floundering, a man’s voice called from the mist, “Is that the Dover mail?”

“Never you mind what it is!” the guard retorted. “What are you?”

“Is that the Dover mail?”

“Why do you want to know?”

“I want a passenger, if it is.”

“What passenger?”

“Mr. Jarvis Lorry.”

Our booked passenger showed in a moment that it was his name. The guard, the coachman, and the two other passengers eyed him distrustfully.

“Keep where you are,” the guard called to the voice in the mist, “because, if I should make a mistake, it could never be set right in your lifetime. Gentleman of the name of Lorry answer straight.”

“What is the matter?” asked the passenger, then, with mildly quavering speech. “Who wants me? Is it Jerry?”

(“I don’t like Jerry’s voice, if it is Jerry,” growled the guard to himself. “He’s hoarser than suits me, is Jerry.”)

“Yes, Mr. Lorry.”

“What is the matter?”

“A despatch sent after you from over yonder. T. and Co.”

“I know this messenger, guard,” said Mr. Lorry, getting down into the road—assisted from behind more swiftly than politely by the other two passengers, who immediately scrambled into the coach, shut the door, and pulled up the window. “He may come close; there’s nothing wrong.”
“I hope there ain’t, but I can’t make so ’Nation sure of that,” said the guard, in gruff soliloquy. “Hallo you!”
“Well! And hallo you!” said Jerry, more hoarsely than before.
“Come on at a footpace! d’ye mind me? And if you’ve got holsters to that saddle o’ yourn, don’t let me see your hand go nigh ’em. For I’m a devil at a quick mistake, and when I make one it takes the form of Lead. So now let’s look at you.”

The figures of a horse and rider came slowly through the eddying mist, and came to the side of the mail, where the passenger stood. The rider stooped, and, casting up his eyes at the guard, handed the passenger a small folded paper. The rider’s horse was blown, and both horse and rider were covered with mud, from the hoofs of the horse to the hat of the man.

“Guard!” said the passenger, in a tone of quiet business confidence.

The watchful guard, with his right hand at the stock of his raised blunderbuss, his left at the barrel, and his eye on the horseman, answered curtly, “Sir.”

“There is nothing to apprehend. I belong to Tellson’s Bank. You must know Tellson’s Bank in London. I am going to Paris on business. A crown to drink. I may read this?”

“If so be as you’re quick, sir.”

He opened it in the light of the coach-lamp on that side, and read—first to himself and then aloud: “‘Wait at Dover for Mam’selle.’ It’s not long, you see, guard. Jerry, say that my answer was, Recalled to life.”

Jerry started in his saddle. “That’s a Blazing strange answer, too,” said he, at his hoarsest.

“Take that message back, and they will know that I received this, as well as if I wrote. Make the best of your way. Good night.”

With those words the passenger opened the coach-door and got in; not at all assisted by his fellow-passengers, who had expeditiously secreted their watches and purses in their boots, and were now making a general pretence of being asleep. With no more definite purpose than to escape the hazard of originating any other kind of action.

The coach lumbered on again, with heavier wreaths of mist closing round it as it began the descent. The guard soon replaced his blunderbuss in his arm-chest, and, having looked to the rest of its contents, and having looked to the supplementary pistols that he wore in his belt, looked to a smaller chest beneath his seat, in which there were a few smith’s tools, a couple of torches, and a tinder-box. For he was furnished with that completeness that if the coach-lamps had been blown and stormed out, which did occasionally happen, he had only to shut himself up inside, keep the flint and steel sparks well off the straw, and get a light with tolerable safety and ease (if he were lucky) in five minutes.

“Tom!” softly over the coach roof.

“Hallo, Joe.”

“Did you hear the message?”

“I did, Joe.”

“What did you make of it, Tom?”

“Nothing at all, Joe.”

“That’s a coincidence, too,” the guard mused, “for I made the same of it myself.”

Jerry, left alone in the mist and darkness, dismounted meanwhile, not only to ease his spent horse, but to wipe the mud from his face, and shake the wet out of his hat-brim, which might be capable of holding about half a gallon. After standing with the bridle over his heavily-splashed arm, until the wheels of the mail were no longer within hearing and the night was quite still again, he turned to walk down the hill.

“After that there gallop from Temple Bar, old lady, I won’t trust your fore-legs till I get you on the level,” said this hoarse messenger, glancing at his mare. “‘Recalled to life.’ That’s a Blazing strange message. Much of that wouldn’t do for you, Jerry! I say, Jerry! You’d be in a Blazing bad way, if recalling to life was to come into fashion, Jerry!

CHAPTER III.
The Night Shadows
Awonderful fact to reflect upon, that every human creature is constituted to be that profound secret and mystery to every other. A solemn consideration, when I enter a great city by night, that every one of those darkly clustered houses encloses its own secret; that every room in every one of them encloses its own secret; that every beating heart in the hundreds of thousands of breasts there, is, in some of its imaginings, a secret to the heart nearest it! Something of the awfulness, even of Death itself, is referable to this. No more can I turn the leaves of this dear book that I loved, and vainly hope in time to read it all. No more can I look into the depths of this unfathomable water, wherein, as momentary lights glanced into it, I have had glimpses of buried treasure and other things submerged. It was appointed that the book should shut with a spring, for ever and for ever, when I had read but a page. It was appointed that the water should be locked in an eternal frost, when the light was playing on its surface, and I stood in ignorance on the shore. My friend is dead, my neighbour is dead, my love, the darling of my soul, is dead; it is the inexorable consolidation and perpetuation of the secret that was always in that individuality, and which I shall carry in mine to my life’s end. In any of the burial-places of this city through which I pass, is there a sleeper more inscrutable than its busy inhabitants are, in their innermost personality, to me, or than I am to them?

As to this, his natural and not to be alienated inheritance, the messenger on horseback had exactly the same possessions as the King, the first Minister of State, or the richest merchant in London. So with the three passengers shut up in the narrow compass of one lumbering old mail coach; they were mysteries to one another, as complete as if each had been in his own coach and six, or his own coach and sixty, with the breadth of a county between him and the next.

The messenger rode back at an easy trot, stopping pretty often at ale-houses by the way to drink, but evincing a tendency to keep his own counsel, and to keep his hat cocked over his eyes. He had eyes that assorted very well with that decoration, being of a surface black, with no depth in the colour or form, and much too near together—as if they were afraid of being found out in something, singly, if they kept too far apart. They had a sinister expression, under an old cocked-hat like a three-cornered spittoon, and over a great muffler for the chin and throat, which descended nearly to the wearer’s knees. When he stopped for drink, he moved this muffler with his left hand, only while he poured his liquor in with his right; as soon as that was done, he muffled again.

“No, Jerry, no!” said the messenger, harping on one theme as he rode. “It wouldn’t do for you, Jerry. Jerry, you honest tradesman, it wouldn’t suit your line of business! Recalled—! Bust me if I don’t think he’d been a drinking!”

His message perplexed his mind to that degree that he was fain, several times, to take off his hat to scratch his head. Except on the crown, which was raggedly bald, he had stiff, black hair, standing jaggedly all over it, and growing down hill almost to his broad, blunt nose. It was so like Smith’s work, so much more like the top of a strongly spiked wall than a head of hair, that the best of players at leap-frog might have declined him, as the most dangerous man in the world to go over.

While he trotted back with the message he was to deliver to the night watchman in his box at the door of Tellson’s Bank, by Temple Bar, who was to deliver it to greater authorities within, the shadows of the night took such shapes to him as arose out of the message, and took such shapes to the mare as arose out of her private topics of uneasiness. They seemed to be numerous, for she shied at every shadow on the road.

What time, the mail-coach lumbered, jolted, rattled, and bumped upon its tedious way, with its three fellow-inscrutables inside. To whom, likewise, the shadows of the night revealed themselves, in the forms their dozing eyes and wandering thoughts suggested.

Tellson’s Bank had a run upon it in the mail. As the bank passenger—with an arm drawn through the leathern strap, which did what lay in it to keep him from pounding against the next passenger, and driving him into his corner, whenever the coach got a special jolt—nodded in his place, with half-shut eyes, the little coach-windows, and the coach-lamp dimly gleaming through them, and the bulky bundle of opposite passenger, became the bank, and did a great stroke of business. The rattle of the harness was the chink of money, and more drafts were honoured in five minutes than even Tellson’s, with all its foreign and home connection, ever paid in thrice the time. Then the strong-rooms underground, at Tellson’s, with such of their valuable stores and secrets as were known to the passenger (and it was not a little that he knew about them), opened before him, and he went in among them with the great keys and the feebly-burning candle, and found them safe, and strong, and sound, and still, just as he had last seen them.

But, though the bank was almost always with him, and though the coach (in a confused way, like the presence of pain under an opiate) was always with him, there was another current of impression that never ceased to run, all through the night. He was on his way to dig some one out of a grave.

Now, which of the multitude of faces that showed themselves before him was the true face of the buried person, the shadows of the night did not indicate; but they were all the faces of a man of five-and-forty by years, and they differed principally in the passions they expressed, and in the ghastliness of their worn and wasted state. Pride, contempt, defiance, stubbornness, submission, lamentation, succeeded one another; so did varieties of sunken cheek, cadaverous colour, emaciated hands and figures. But the face was in the main one face, and every head was prematurely white. A hundred times the dozing passenger inquired of this spectre:

“Buried how long?”

The answer was always the same: “Almost eighteen years.”

“You had abandoned all hope of being dug out?”

“Long ago.”

“You know that you are recalled to life?”

“They tell me so.”

“I hope you care to live?”

“I can’t say.”

“Shall I show her to you? Will you come and see her?”

The answers to this question were various and contradictory. Sometimes the broken reply was, “Wait! It would kill me if I saw her too soon.” Sometimes, it was given in a tender rain of tears, and then it was, “Take me to her.” Sometimes it was staring and bewildered, and then it was, “I don’t know her. I don’t understand.”

After such imaginary discourse, the passenger in his fancy would dig, and dig, dig—now with a spade, now with a great key, now with his hands—to dig this wretched creature out. Got out at last, with earth hanging about his face and hair, he would suddenly fan away to dust. The passenger would then start to himself, and lower the window, to get the reality of mist and rain on his cheek.

Yet even when his eyes were opened on the mist and rain, on the moving patch of light from the lamps, and the hedge at the roadside retreating by jerks, the night shadows outside the coach would fall into the train of the night shadows within. The real Banking-house by Temple Bar, the real business of the past day, the real strong rooms, the real express sent after him, and the real message returned, would all be there. Out of the midst of them, the ghostly face would rise, and he would accost it again.

“Buried how long?”

“Almost eighteen years.”

“I hope you care to live?”

“I can’t say.”

Dig—dig—dig—until an impatient movement from one of the two passengers would admonish him to pull up the window, draw his arm securely through the leathern strap, and speculate upon the two slumbering forms, until his mind lost its hold of them, and they again slid away into the bank and the grave.

“Buried how long?”

“Almost eighteen years.”

“You had abandoned all hope of being dug out?”

“Long ago.”

The words were still in his hearing as just spoken—distinctly in his hearing as ever spoken words had been in his life—when the weary passenger started to the consciousness of daylight, and found that the shadows of the night were gone.

He lowered the window, and looked out at the rising sun. There was a ridge of ploughed land, with a plough upon it where it had been left last night when the horses were unyoked; beyond, a quiet coppice-wood, in which many leaves of burning red and golden yellow still remained upon the trees. Though the earth was cold and wet, the sky was clear, and the sun rose bright, placid, and beautiful.

“Eighteen years!” said the passenger, looking at the sun. “Gracious Creator of day! To be buried alive for eighteen years!””

CHAPTER IV.
The Preparation
When the mail got successfully to Dover, in the course of the forenoon, the head drawer at the Royal George Hotel opened the coach-door as his custom was. He did it with some flourish of ceremony, for a mail journey from London in winter was an achievement to congratulate an adventurous traveller upon.

By that time, there was only one adventurous traveller left be congratulated: for the two others had been set down at their respective roadside destinations. The mildewy inside of the coach, with its damp and dirty straw, its disagreeable smell, and its obscurity, was rather like a larger dog-kennel. Mr. Lorry, the passenger, shaking himself out of it in chains of straw, a tangle of shaggy wrapper, flapping hat, and muddy legs, was rather like a larger sort of dog.

“There will be a packet to Calais, tomorrow, drawer?”

“Yes, sir, if the weather holds and the wind sets tolerable fair. The tide will serve pretty nicely at about two in the afternoon, sir. Bed, sir?”

“I shall not go to bed till night; but I want a bedroom, and a barber.”

“And then breakfast, sir? Yes, sir. That way, sir, if you please. Show Concord! Gentleman’s valise and hot water to Concord. Pull off gentleman’s boots in Concord. (You will find a fine sea-coal fire, sir.) Fetch barber to Concord. Stir about there, now, for Concord!”

The Concord bed-chamber being always assigned to a passenger by the mail, and passengers by the mail being always heavily wrapped up from head to foot, the room had the odd interest for the establishment of the Royal George, that although but one kind of man was seen to go into it, all kinds and varieties of men came out of it. Consequently, another drawer, and two porters, and several maids and the landlady, were all loitering by accident at various points of the road between the Concord and the coffee-room, when a gentleman of sixty, formally dressed in a brown suit of clothes, pretty well worn, but very well kept, with large square cuffs and large flaps to the pockets, passed along on his way to his breakfast.

The coffee-room had no other occupant, that forenoon, than the gentleman in brown. His breakfast-table was drawn before the fire, and as he sat, with its light shining on him, waiting for the meal, he sat so still, that he might have been sitting for his portrait.

Very orderly and methodical he looked, with a hand on each knee, and a loud watch ticking a sonorous sermon under his flapped waist-coat, as though it pitted its gravity and longevity against the levity and evanescence of the brisk fire. He had a good leg, and was a little vain of it, for his brown stockings fitted sleek and close, and were of a fine texture; his shoes and buckles, too, though plain, were trim. He wore an odd little sleek crisp flaxen wig, setting very close to his head: which wig, it is to be presumed, was made of hair, but which looked far more as though it were spun from filaments of silk or glass. His linen, though not of a fineness in accordance with his stockings, was as white as the tops of the waves that broke upon the neighbouring beach, or the specks of sail that glinted in the sunlight far at sea. A face habitually suppressed and quieted, was still lighted up under the quaint wig by a pair of moist bright eyes that it must have cost their owner, in years gone by, some pains to drill to the composed and reserved expression of Tellson’s Bank. He had a healthy colour in his cheeks, and his face, though lined, bore few traces of anxiety. But, perhaps the confidential bachelor clerks in Tellson’s Bank were principally occupied with the cares of other people; and perhaps second-hand cares, like second-hand clothes, come easily off and on.

Completing his resemblance to a man who was sitting for his portrait, Mr. Lorry dropped off to sleep. The arrival of his breakfast roused him, and he said to the drawer, as he moved his chair to it:

“I wish accommodation prepared for a young lady who may come here at any time to-day. She may ask for Mr. Jarvis Lorry, or she may only ask for a gentleman from Tellson’s Bank. Please to let me know.”

“Yes, sir. Tellson’s Bank in London, sir?”

“Yes.”

“Yes, sir. We have oftentimes the honour to entertain your gentlemen in their travelling backwards and forwards betwixt London and Paris, sir. A vast deal of travelling, sir, in Tellson and Company’s House.”

“Yes. We are quite a French House, as well as an English one.”

“Yes, sir. Not much in the habit of such travelling yourself, I think, sir?”

“Not of late years. It is fifteen years since we—since I—came last from France.”

“Indeed, sir? That was before my time here, sir. Before our people’s time here, sir. The George was in other hands at that time, sir.”

“I believe so.”

“But I would hold a pretty wager, sir, that a House like Tellson and Company was flourishing, a matter of fifty, not to speak of fifteen years ago?”

“You might treble that, and say a hundred and fifty, yet not be far from the truth.”

“Indeed, sir!”

Rounding his mouth and both his eyes, as he stepped backward from the table, the waiter shifted his napkin from his right arm to his left, dropped into a comfortable attitude, and stood surveying the guest while he ate and drank, as from an observatory or watchtower. According to the immemorial usage of waiters in all ages.

When Mr. Lorry had finished his breakfast, he went out for a stroll on the beach. The little narrow, crooked town of Dover hid itself away from the beach, and ran its head into the chalk cliffs, like a marine ostrich. The beach was a desert of heaps of sea and stones tumbling wildly about, and the sea did what it liked, and what it liked was destruction. It thundered at the town, and thundered at the cliffs, and brought the coast down, madly. The air among the houses was of so strong a piscatory flavour that one might have supposed sick fish went up to be dipped in it, as sick people went down to be dipped in the sea. A little fishing was done in the port, and a quantity of strolling about by night, and looking seaward: particularly at those times when the tide made, and was near flood. Small tradesmen, who did no business whatever, sometimes unaccountably realised large fortunes, and it was remarkable that nobody in the neighbourhood could endure a lamplighter.

As the day declined into the afternoon, and the air, which had been at intervals clear enough to allow the French coast to be seen, became again charged with mist and vapour, Mr. Lorry’s thoughts seemed to cloud too. When it was dark, and he sat before the coffee-room fire, awaiting his dinner as he had awaited his breakfast, his mind was busily digging, digging, digging, in the live red coals.

A bottle of good claret after dinner does a digger in the red coals no harm, otherwise than as it has a tendency to throw him out of work. Mr. Lorry had been idle a long time, and had just poured out his last glassful of wine with as complete an appearance of satisfaction as is ever to be found in an elderly gentleman of a fresh complexion who has got to the end of a bottle, when a rattling of wheels came up the narrow street, and rumbled into the inn-yard.

He set down his glass untouched. “This is Mam’selle!” said he.

In a very few minutes the waiter came in to announce that Miss Manette had arrived from London, and would be happy to see the gentleman from Tellson’s.

“So soon?”

Miss Manette had taken some refreshment on the road, and required none then, and was extremely anxious to see the gentleman from Tellson’s immediately, if it suited his pleasure and convenience.

The gentleman from Tellson’s had nothing left for it but to empty his glass with an air of stolid desperation, settle his odd little flaxen wig at the ears, and follow the waiter to Miss Manette’s apartment. It was a large, dark room, furnished in a funereal manner with black horsehair, and loaded with heavy dark tables. These had been oiled and oiled, until the two tall candles on the table in the middle of the room were gloomily reflected on every leaf; as if they were buried, in deep graves of black mahogany, and no light to speak of could be expected from them until they were dug out.

The obscurity was so difficult to penetrate that Mr. Lorry, picking his way over the well-worn Turkey carpet, supposed Miss Manette to be, for the moment, in some adjacent room, until, having got past the two tall candles, he saw standing to receive him by the table between them and the fire, a young lady of not more than seventeen, in a riding-cloak, and still holding her straw travelling-hat by its ribbon in her hand. As his eyes rested on a short, slight, pretty figure, a quantity of golden hair, a pair of blue eyes that met his own with an inquiring look, and a forehead with a singular capacity (remembering how young and smooth it was), of rifting and knitting itself into an expression that was not quite one of perplexity, or wonder, or alarm, or merely of a bright fixed attention, though it included all the four expressions—as his eyes rested on these things, a sudden vivid likeness passed before him, of a child whom he had held in his arms on the passage across that very Channel, one cold time, when the hail drifted heavily and the sea ran high. The likeness passed away, like a breath along the surface of the gaunt pier-glass behind her, on the frame of which, a hospital procession of negro cupids, several headless and all cripples, were offering black baskets of Dead Sea fruit to black divinities of the feminine gender—and he made his formal bow to Miss Manette.

“Pray take a seat, sir.” In a very clear and pleasant young voice; a little foreign in its accent, but a very little indeed.

“I kiss your hand, miss,” said Mr. Lorry, with the manners of an earlier date, as he made his formal bow again, and took his seat.

“I received a letter from the Bank, sir, yesterday, informing me that some intelligence—or discovery—”

“The word is not material, miss; either word will do.”

“—respecting the small property of my poor father, whom I never saw—so long dead—”

Mr. Lorry moved in his chair, and cast a troubled look towards the hospital procession of negro cupids. As if they had any help for anybody in their absurd baskets!

“—rendered it necessary that I should go to Paris, there to communicate with a gentleman of the Bank, so good as to be despatched to Paris for the purpose.”

“Myself.”

“As I was prepared to hear, sir.”

She curtseyed to him (young ladies made curtseys in those days), with a pretty desire to convey to him that she felt how much older and wiser he was than she. He made her another bow.

“I replied to the Bank, sir, that as it was considered necessary, by those who know, and who are so kind as to advise me, that I should go to France, and that as I am an orphan and have no friend who could go with me, I should esteem it highly if I might be permitted to place myself, during the journey, under that worthy gentleman’s protection. The gentleman had left London, but I think a messenger was sent after him to beg the favour of his waiting for me here.”

“I was happy,” said Mr. Lorry, “to be entrusted with the charge. I shall be more happy to execute it.”

“Sir, I thank you indeed. I thank you very gratefully. It was told me by the Bank that the gentleman would explain to me the details of the business, and that I must prepare myself to find them of a surprising nature. I have done my best to prepare myself, and I naturally have a strong and eager interest to know what they are.”

“Naturally,” said Mr. Lorry. “Yes—I—”

After a pause, he added, again settling the crisp flaxen wig at the ears, “It is very difficult to begin.”

He did not begin, but, in his indecision, met her glance. The young forehead lifted itself into that singular expression—but it was pretty and characteristic, besides being singular—and she raised her hand, as if with an involuntary action she caught at, or stayed some passing shadow.

“Are you quite a stranger to me, sir?”

“Am I not?” Mr. Lorry opened his hands, and extended them outwards with an argumentative smile.

Between the eyebrows and just over the little feminine nose, the line of which was as delicate and fine as it was possible to be, the expression deepened itself as she took her seat thoughtfully in the chair by which she had hitherto remained standing. He watched her as she mused, and the moment she raised her eyes again, went on:

“In your adopted country, I presume, I cannot do better than address you as a young English lady, Miss Manette?”

“If you please, sir.”

“Miss Manette, I am a man of business. I have a business charge to acquit myself of. In your reception of it, don’t heed me any more than if I was a speaking machine—truly, I am not much else. I will, with your leave, relate to you, miss, the story of one of our customers.”

“Story!”

He seemed wilfully to mistake the word she had repeated, when he added, in a hurry, “Yes, customers; in the banking business we usually call our connection our customers. He was a French gentleman; a scientific gentleman; a man of great acquirements—a Doctor.”

“Not of Beauvais?”

“Why, yes, of Beauvais. Like Monsieur Manette, your father, the gentleman was of Beauvais. Like Monsieur Manette, your father, the gentleman was of repute in Paris. I had the honour of knowing him there. Our relations were business relations, but confidential. I was at that time in our French House, and had been—oh! twenty years.”

“At that time—I may ask, at what time, sir?”

“I speak, miss, of twenty years ago. He married—an English lady—and I was one of the trustees. His affairs, like the affairs of many other French gentlemen and French families, were entirely in Tellson’s hands. In a similar way I am, or I have been, trustee of one kind or other for scores of our customers. These are mere business relations, miss; there is no friendship in them, no particular interest, nothing like sentiment. I have passed from one to another, in the course of my business life, just as I pass from one of our customers to another in the course of my business day; in short, I have no feelings; I am a mere machine. To go on—”

“But this is my father’s story, sir; and I begin to think”—the curiously roughened forehead was very intent upon him—“that when I was left an orphan through my mother’s surviving my father only two years, it was you who brought me to England. I am almost sure it was you.”

Mr. Lorry took the hesitating little hand that confidingly advanced to take his, and he put it with some ceremony to his lips. He then conducted the young lady straightway to her chair again, and, holding the chair-back with his left hand, and using his right by turns to rub his chin, pull his wig at the ears, or point what he said, stood looking down into her face while she sat looking up into his.

“Miss Manette, it was I. And you will see how truly I spoke of myself just now, in saying I had no feelings, and that all the relations I hold with my fellow-creatures are mere business relations, when you reflect that I have never seen you since. No; you have been the ward of Tellson’s House since, and I have been busy with the other business of Tellson’s House since. Feelings! I have no time for them, no chance of them. I pass my whole life, miss, in turning an immense pecuniary Mangle.”

After this odd description of his daily routine of employment, Mr. Lorry flattened his flaxen wig upon his head with both hands (which was most unnecessary, for nothing could be flatter than its shining surface was before), and resumed his former attitude.

“So far, miss (as you have remarked), this is the story of your regretted father. Now comes the difference. If your father had not died when he did—Don’t be frightened! How you start!”

She did, indeed, start. And she caught his wrist with both her hands.

“Pray,” said Mr. Lorry, in a soothing tone, bringing his left hand from the back of the chair to lay it on the supplicatory fingers that clasped him in so violent a tremble: “pray control your agitation—a matter of business. As I was saying—”

Her look so discomposed him that he stopped, wandered, and began anew:

“As I was saying; if Monsieur Manette had not died; if he had suddenly and silently disappeared; if he had been spirited away; if it had not been difficult to guess to what dreadful place, though no art could trace him; if he had an enemy in some compatriot who could exercise a privilege that I in my own time have known the boldest people afraid to speak of in a whisper, across the water there; for instance, the privilege of filling up blank forms for the consignment of any one to the oblivion of a prison for any length of time; if his wife had implored the king, the queen, the court, the clergy, for any tidings of him, and all quite in vain;—then the history of your father would have been the history of this unfortunate gentleman, the Doctor of Beauvais.”

“I entreat you to tell me more, sir.”

“I will. I am going to. You can bear it?”

“I can bear anything but the uncertainty you leave me in at this moment.”

“You speak collectedly, and you—are collected. That’s good!” (Though his manner was less satisfied than his words.) “A matter of business. Regard it as a matter of business—business that must be done. Now if this doctor’s wife, though a lady of great courage and spirit, had suffered so intensely from this cause before her little child was born—”

“The little child was a daughter, sir.”

“A daughter. A-a-matter of business—don’t be distressed. Miss, if the poor lady had suffered so intensely before her little child was born, that she came to the determination of sparing the poor child the inheritance of any part of the agony she had known the pains of, by rearing her in the belief that her father was dead—No, don’t kneel! In Heaven’s name why should you kneel to me!”

“For the truth. O dear, good, compassionate sir, for the truth!”

“A—a matter of business. You confuse me, and how can I transact business if I am confused? Let us be clear-headed. If you could kindly mention now, for instance, what nine times ninepence are, or how many shillings in twenty guineas, it would be so encouraging. I should be so much more at my ease about your state of mind.”

Without directly answering to this appeal, she sat so still when he had very gently raised her, and the hands that had not ceased to clasp his wrists were so much more steady than they had been, that she communicated some reassurance to Mr. Jarvis Lorry.

“That’s right, that’s right. Courage! Business! You have business before you; useful business. Miss Manette, your mother took this course with you. And when she died—I believe broken-hearted—having never slackened her unavailing search for your father, she left you, at two years old, to grow to be blooming, beautiful, and happy, without the dark cloud upon you of living in uncertainty whether your father soon wore his heart out in prison, or wasted there through many lingering years.”

As he said the words he looked down, with an admiring pity, on the flowing golden hair; as if he pictured to himself that it might have been already tinged with grey.

“You know that your parents had no great possession, and that what they had was secured to your mother and to you. There has been no new discovery, of money, or of any other property; but—”

He felt his wrist held closer, and he stopped. The expression in the forehead, which had so particularly attracted his notice, and which was now immovable, had deepened into one of pain and horror.

“But he has been—been found. He is alive. Greatly changed, it is too probable; almost a wreck, it is possible; though we will hope the best. Still, alive. Your father has been taken to the house of an old servant in Paris, and we are going there: I, to identify him if I can: you, to restore him to life, love, duty, rest, comfort.”

A shiver ran through her frame, and from it through his. She said, in a low, distinct, awe-stricken voice, as if she were saying it in a dream,

“I am going to see his Ghost! It will be his Ghost—not him!”

Mr. Lorry quietly chafed the hands that held his arm. “There, there, there! See now, see now! The best and the worst are known to you, now. You are well on your way to the poor wronged gentleman, and, with a fair sea voyage, and a fair land journey, you will be soon at his dear side.”

She repeated in the same tone, sunk to a whisper, “I have been free, I have been happy, yet his Ghost has never haunted me!”

“Only one thing more,” said Mr. Lorry, laying stress upon it as a wholesome means of enforcing her attention: “he has been found under another name; his own, long forgotten or long concealed. It would be worse than useless now to inquire which; worse than useless to seek to know whether he has been for years overlooked, or always designedly held prisoner. It would be worse than useless now to make any inquiries, because it would be dangerous. Better not to mention the subject, anywhere or in any way, and to remove him—for a while at all events—out of France. Even I, safe as an Englishman, and even Tellson’s, important as they are to French credit, avoid all naming of the matter. I carry about me, not a scrap of writing openly referring to it. This is a secret service altogether. My credentials, entries, and memoranda, are all comprehended in the one line, ‘Recalled to Life;’ which may mean anything. But what is the matter! She doesn’t notice a word! Miss Manette!”

Perfectly still and silent, and not even fallen back in her chair, she sat under his hand, utterly insensible; with her eyes open and fixed upon him, and with that last expression looking as if it were carved or branded into her forehead. So close was her hold upon his arm, that he feared to detach himself lest he should hurt her; therefore he called out loudly for assistance without moving.

A wild-looking woman, whom even in his agitation, Mr. Lorry observed to be all of a red colour, and to have red hair, and to be dressed in some extraordinary tight-fitting fashion, and to have on her head a most wonderful bonnet like a Grenadier wooden measure, and good measure too, or a great Stilton cheese, came running into the room in advance of the inn servants, and soon settled the question of his detachment from the poor young lady, by laying a brawny hand upon his chest, and sending him flying back against the nearest wall.

(“I really think this must be a man!” was Mr. Lorry’s breathless reflection, simultaneously with his coming against the wall.)

“Why, look at you all!” bawled this figure, addressing the inn servants. “Why don’t you go and fetch things, instead of standing there staring at me? I am not so much to look at, am I? Why don’t you go and fetch things? I’ll let you know, if you don’t bring smelling-salts, cold water, and vinegar, quick, I will.”

There was an immediate dispersal for these restoratives, and she softly laid the patient on a sofa, and tended her with great skill and gentleness: calling her “my precious!” and “my bird!” and spreading her golden hair aside over her shoulders with great pride and care.

“And you in brown!” she said, indignantly turning to Mr. Lorry; “couldn’t you tell her what you had to tell her, without frightening her to death? Look at her, with her pretty pale face and her cold hands. Do you call that being a Banker?”

Mr. Lorry was so exceedingly disconcerted by a question so hard to answer, that he could only look on, at a distance, with much feebler sympathy and humility, while the strong woman, having banished the inn servants under the mysterious penalty of “letting them know” something not mentioned if they stayed there, staring, recovered her charge by a regular series of gradations, and coaxed her to lay her drooping head upon her shoulder.

“I hope she will do well now,” said Mr. Lorry.

“No thanks to you in brown, if she does. My darling pretty!”

“I hope,” said Mr. Lorry, after another pause of feeble sympathy and humility, “that you accompany Miss Manette to France?”

“A likely thing, too!” replied the strong woman. “If it was ever intended that I should go across salt water, do you suppose Providence would have cast my lot in an island?”

This being another question hard to answer, Mr. Jarvis Lorry withdrew to consider it.

CHAPTER V.
The Wine-shop
Alarge cask of wine had been dropped and broken, in the street. The accident had happened in getting it out of a cart; the cask had tumbled out with a run, the hoops had burst, and it lay on the stones just outside the door of the wine-shop, shattered like a walnut-shell.

All the people within reach had suspended their business, or their idleness, to run to the spot and drink the wine. The rough, irregular stones of the street, pointing every way, and designed, one might have thought, expressly to lame all living creatures that approached them, had dammed it into little pools; these were surrounded, each by its own jostling group or crowd, according to its size. Some men kneeled down, made scoops of their two hands joined, and sipped, or tried to help women, who bent over their shoulders, to sip, before the wine had all run out between their fingers. Others, men and women, dipped in the puddles with little mugs of mutilated earthenware, or even with handkerchiefs from women’s heads, which were squeezed dry into infants’ mouths; others made small mud-embankments, to stem the wine as it ran; others, directed by lookers-on up at high windows, darted here and there, to cut off little streams of wine that started away in new directions; others devoted themselves to the sodden and lee-dyed pieces of the cask, licking, and even champing the moister wine-rotted fragments with eager relish. There was no drainage to carry off the wine, and not only did it all get taken up, but so much mud got taken up along with it, that there might have been a scavenger in the street, if anybody acquainted with it could have believed in such a miraculous presence.

A shrill sound of laughter and of amused voices—voices of men, women, and children—resounded in the street while this wine game lasted. There was little roughness in the sport, and much playfulness. There was a special companionship in it, an observable inclination on the part of every one to join some other one, which led, especially among the luckier or lighter-hearted, to frolicsome embraces, drinking of healths, shaking of hands, and even joining of hands and dancing, a dozen together. When the wine was gone, and the places where it had been most abundant were raked into a gridiron-pattern by fingers, these demonstrations ceased, as suddenly as they had broken out. The man who had left his saw sticking in the firewood he was cutting, set it in motion again; the women who had left on a door-step the little pot of hot ashes, at which she had been trying to soften the pain in her own starved fingers and toes, or in those of her child, returned to it; men with bare arms, matted locks, and cadaverous faces, who had emerged into the winter light from cellars, moved away, to descend again; and a gloom gathered on the scene that appeared more natural to it than sunshine.

The wine was red wine, and had stained the ground of the narrow street in the suburb of Saint Antoine, in Paris, where it was spilled. It had stained many hands, too, and many faces, and many naked feet, and many wooden shoes. The hands of the man who sawed the wood, left red marks on the billets; and the forehead of the woman who nursed her baby, was stained with the stain of the old rag she wound about her head again. Those who had been greedy with the staves of the cask, had acquired a tigerish smear about the mouth; and one tall joker so besmirched, his head more out of a long squalid bag of a nightcap than in it, scrawled upon a wall with his finger dipped in muddy wine-lees—blood.

The time was to come, when that wine too would be spilled on the street-stones, and when the stain of it would be red upon many there.

And now that the cloud settled on Saint Antoine, which a momentary gleam had driven from his sacred countenance, the darkness of it was heavy—cold, dirt, sickness, ignorance, and want, were the lords in waiting on the saintly presence—nobles of great power all of them; but, most especially the last. Samples of a people that had undergone a terrible grinding and regrinding in the mill, and certainly not in the fabulous mill which ground old people young, shivered at every corner, passed in and out at every doorway, looked from every window, fluttered in every vestige of a garment that the wind shook. The mill which had worked them down, was the mill that grinds young people old; the children had ancient faces and grave voices; and upon them, and upon the grown faces, and ploughed into every furrow of age and coming up afresh, was the sigh, Hunger. It was prevalent everywhere. Hunger was pushed out of the tall houses, in the wretched clothing that hung upon poles and lines; Hunger was patched into them with straw and rag and wood and paper; Hunger was repeated in every fragment of the small modicum of firewood that the man sawed off; Hunger stared down from the smokeless chimneys, and started up from the filthy street that had no offal, among its refuse, of anything to eat. Hunger was the inscription on the baker’s shelves, written in every small loaf of his scanty stock of bad bread; at the sausage-shop, in every dead-dog preparation that was offered for sale. Hunger rattled its dry bones among the roasting chestnuts in the turned cylinder; Hunger was shred into atomics in every farthing porringer of husky chips of potato, fried with some reluctant drops of oil.

Its abiding place was in all things fitted to it. A narrow winding street, full of offence and stench, with other narrow winding streets diverging, all peopled by rags and nightcaps, and all smelling of rags and nightcaps, and all visible things with a brooding look upon them that looked ill. In the hunted air of the people there was yet some wild-beast thought of the possibility of turning at bay. Depressed and slinking though they were, eyes of fire were not wanting among them; nor compressed lips, white with what they suppressed; nor foreheads knitted into the likeness of the gallows-rope they mused about enduring, or inflicting. The trade signs (and they were almost as many as the shops) were, all, grim illustrations of Want. The butcher and the porkman painted up, only the leanest scrags of meat; the baker, the coarsest of meagre loaves. The people rudely pictured as drinking in the wine-shops, croaked over their scanty measures of thin wine and beer, and were gloweringly confidential together. Nothing was represented in a flourishing condition, save tools and weapons; but, the cutler’s knives and axes were sharp and bright, the smith’s hammers were heavy, and the gunmaker’s stock was murderous. The crippling stones of the pavement, with their many little reservoirs of mud and water, had no footways, but broke off abruptly at the doors. The kennel, to make amends, ran down the middle of the street—when it ran at all: which was only after heavy rains, and then it ran, by many eccentric fits, into the houses. Across the streets, at wide intervals, one clumsy lamp was slung by a rope and pulley; at night, when the lamplighter had let these down, and lighted, and hoisted them again, a feeble grove of dim wicks swung in a sickly manner overhead, as if they were at sea. Indeed they were at sea, and the ship and crew were in peril of tempest.

For, the time was to come, when the gaunt scarecrows of that region should have watched the lamplighter, in their idleness and hunger, so long, as to conceive the idea of improving on his method, and hauling up men by those ropes and pulleys, to flare upon the darkness of their condition. But, the time was not come yet; and every wind that blew over France shook the rags of the scarecrows in vain, for the birds, fine of song and feather, took no warning.

The wine-shop was a corner shop, better than most others in its appearance and degree, and the master of the wine-shop had stood outside it, in a yellow waistcoat and green breeches, looking on at the struggle for the lost wine. “It’s not my affair,” said he, with a final shrug of the shoulders. “The people from the market did it. Let them bring another.”

There, his eyes happening to catch the tall joker writing up his joke, he called to him across the way:

“Say, then, my Gaspard, what do you do there?”

The fellow pointed to his joke with immense significance, as is often the way with his tribe. It missed its mark, and completely failed, as is often the way with his tribe too.

“What now? Are you a subject for the mad hospital?” said the wine-shop keeper, crossing the road, and obliterating the jest with a handful of mud, picked up for the purpose, and smeared over it. “Why do you write in the public streets? Is there—tell me thou—is there no other place to write such words in?”

In his expostulation he dropped his cleaner hand (perhaps accidentally, perhaps not) upon the joker’s heart. The joker rapped it with his own, took a nimble spring upward, and came down in a fantastic dancing attitude, with one of his stained shoes jerked off his foot into his hand, and held out. A joker of an extremely, not to say wolfishly practical character, he looked, under those circumstances.

“Put it on, put it on,” said the other. “Call wine, wine; and finish there.” With that advice, he wiped his soiled hand upon the joker’s dress, such as it was—quite deliberately, as having dirtied the hand on his account; and then recrossed the road and entered the wine-shop.

This wine-shop keeper was a bull-necked, martial-looking man of thirty, and he should have been of a hot temperament, for, although it was a bitter day, he wore no coat, but carried one slung over his shoulder. His shirt-sleeves were rolled up, too, and his brown arms were bare to the elbows. Neither did he wear anything more on his head than his own crisply-curling short dark hair. He was a dark man altogether, with good eyes and a good bold breadth between them. Good-humoured looking on the whole, but implacable-looking, too; evidently a man of a strong resolution and a set purpose; a man not desirable to be met, rushing down a narrow pass with a gulf on either side, for nothing would turn the man.

Madame Defarge, his wife, sat in the shop behind the counter as he came in. Madame Defarge was a stout woman of about his own age, with a watchful eye that seldom seemed to look at anything, a large hand heavily ringed, a steady face, strong features, and great composure of manner. There was a character about Madame Defarge, from which one might have predicated that she did not often make mistakes against herself in any of the reckonings over which she presided. Madame Defarge being sensitive to cold, was wrapped in fur, and had a quantity of bright shawl twined about her head, though not to the concealment of her large earrings. Her knitting was before her, but she had laid it down to pick her teeth with a toothpick. Thus engaged, with her right elbow supported by her left hand, Madame Defarge said nothing when her lord came in, but coughed just one grain of cough. This, in combination with the lifting of her darkly defined eyebrows over her toothpick by the breadth of a line, suggested to her husband that he would do well to look round the shop among the customers, for any new customer who had dropped in while he stepped over the way.

The wine-shop keeper accordingly rolled his eyes about, until they rested upon an elderly gentleman and a young lady, who were seated in a corner. Other company were there: two playing cards, two playing dominoes, three standing by the counter lengthening out a short supply of wine. As he passed behind the counter, he took notice that the elderly gentleman said in a look to the young lady, “This is our man.”

“What the devil do you do in that galley there?” said Monsieur Defarge to himself; “I don’t know you.”

But, he feigned not to notice the two strangers, and fell into discourse with the triumvirate of customers who were drinking at the counter.

“How goes it, Jacques?” said one of these three to Monsieur Defarge. “Is all the spilt wine swallowed?”

“Every drop, Jacques,” answered Monsieur Defarge.

When this interchange of Christian name was effected, Madame Defarge, picking her teeth with her toothpick, coughed another grain of cough, and raised her eyebrows by the breadth of another line.

“It is not often,” said the second of the three, addressing Monsieur Defarge, “that many of these miserable beasts know the taste of wine, or of anything but black bread and death. Is it not so, Jacques?”

“It is so, Jacques,” Monsieur Defarge returned.

At this second interchange of the Christian name, Madame Defarge, still using her toothpick with profound composure, coughed another grain of cough, and raised her eyebrows by the breadth of another line.

The last of the three now said his say, as he put down his empty drinking vessel and smacked his lips.

“Ah! So much the worse! A bitter taste it is that such poor cattle always have in their mouths, and hard lives they live, Jacques. Am I right, Jacques?”

“You are right, Jacques,” was the response of Monsieur Defarge.

This third interchange of the Christian name was completed at the moment when Madame Defarge put her toothpick by, kept her eyebrows up, and slightly rustled in her seat.

“Hold then! True!” muttered her husband. “Gentlemen—my wife!”

The three customers pulled off their hats to Madame Defarge, with three flourishes. She acknowledged their homage by bending her head, and giving them a quick look. Then she glanced in a casual manner round the wine-shop, took up her knitting with great apparent calmness and repose of spirit, and became absorbed in it.

“Gentlemen,” said her husband, who had kept his bright eye observantly upon her, “good day. The chamber, furnished bachelor-fashion, that you wished to see, and were inquiring for when I stepped out, is on the fifth floor. The doorway of the staircase gives on the little courtyard close to the left here,” pointing with his hand, “near to the window of my establishment. But, now that I remember, one of you has already been there, and can show the way. Gentlemen, adieu!”

They paid for their wine, and left the place. The eyes of Monsieur Defarge were studying his wife at her knitting when the elderly gentleman advanced from his corner, and begged the favour of a word.

“Willingly, sir,” said Monsieur Defarge, and quietly stepped with him to the door.

Their conference was very short, but very decided. Almost at the first word, Monsieur Defarge started and became deeply attentive. It had not lasted a minute, when he nodded and went out. The gentleman then beckoned to the young lady, and they, too, went out. Madame Defarge knitted with nimble fingers and steady eyebrows, and saw nothing.

Mr. Jarvis Lorry and Miss Manette, emerging from the wine-shop thus, joined Monsieur Defarge in the doorway to which he had directed his own company just before. It opened from a stinking little black courtyard, and was the general public entrance to a great pile of houses, inhabited by a great number of people. In the gloomy tile-paved entry to the gloomy tile-paved staircase, Monsieur Defarge bent down on one knee to the child of his old master, and put her hand to his lips. It was a gentle action, but not at all gently done; a very remarkable transformation had come over him in a few seconds. He had no good-humour in his face, nor any openness of aspect left, but had become a secret, angry, dangerous man.

“It is very high; it is a little difficult. Better to begin slowly.” Thus, Monsieur Defarge, in a stern voice, to Mr. Lorry, as they began ascending the stairs.

“Is he alone?” the latter whispered.

“Alone! God help him, who should be with him!” said the other, in the same low voice.

“Is he always alone, then?”

“Yes.”

“Of his own desire?”

“Of his own necessity. As he was, when I first saw him after they found me and demanded to know if I would take him, and, at my peril be discreet—as he was then, so he is now.”

“He is greatly changed?”

“Changed!”

The keeper of the wine-shop stopped to strike the wall with his hand, and mutter a tremendous curse. No direct answer could have been half so forcible. Mr. Lorry’s spirits grew heavier and heavier, as he and his two companions ascended higher and higher.

Such a staircase, with its accessories, in the older and more crowded parts of Paris, would be bad enough now; but, at that time, it was vile indeed to unaccustomed and unhardened senses. Every little habitation within the great foul nest of one high building—that is to say, the room or rooms within every door that opened on the general staircase—left its own heap of refuse on its own landing, besides flinging other refuse from its own windows. The uncontrollable and hopeless mass of decomposition so engendered, would have polluted the air, even if poverty and deprivation had not loaded it with their intangible impurities; the two bad sources combined made it almost insupportable. Through such an atmosphere, by a steep dark shaft of dirt and poison, the way lay. Yielding to his own disturbance of mind, and to his young companion’s agitation, which became greater every instant, Mr. Jarvis Lorry twice stopped to rest. Each of these stoppages was made at a doleful grating, by which any languishing good airs that were left uncorrupted, seemed to escape, and all spoilt and sickly vapours seemed to crawl in. Through the rusted bars, tastes, rather than glimpses, were caught of the jumbled neighbourhood; and nothing within range, nearer or lower than the summits of the two great towers of Notre-Dame, had any promise on it of healthy life or wholesome aspirations.

At last, the top of the staircase was gained, and they stopped for the third time. There was yet an upper staircase, of a steeper inclination and of contracted dimensions, to be ascended, before the garret story was reached. The keeper of the wine-shop, always going a little in advance, and always going on the side which Mr. Lorry took, as though he dreaded to be asked any question by the young lady, turned himself about here, and, carefully feeling in the pockets of the coat he carried over his shoulder, took out a key.

“The door is locked then, my friend?” said Mr. Lorry, surprised.

“Ay. Yes,” was the grim reply of Monsieur Defarge.

“You think it necessary to keep the unfortunate gentleman so retired?”

“I think it necessary to turn the key.” Monsieur Defarge whispered it closer in his ear, and frowned heavily.

“Why?”

“Why! Because he has lived so long, locked up, that he would be frightened—rave—tear himself to pieces—die—come to I know not what harm—if his door was left open.”

“Is it possible!” exclaimed Mr. Lorry.

“Is it possible!” repeated Defarge, bitterly. “Yes. And a beautiful world we live in, when it is possible, and when many other such things are possible, and not only possible, but done—done, see you!—under that sky there, every day. Long live the Devil. Let us go on.”

This dialogue had been held in so very low a whisper, that not a word of it had reached the young lady’s ears. But, by this time she trembled under such strong emotion, and her face expressed such deep anxiety, and, above all, such dread and terror, that Mr. Lorry felt it incumbent on him to speak a word or two of reassurance.

“Courage, dear miss! Courage! Business! The worst will be over in a moment; it is but passing the room-door, and the worst is over. Then, all the good you bring to him, all the relief, all the happiness you bring to him, begin. Let our good friend here, assist you on that side. That’s well, friend Defarge. Come, now. Business, business!”

They went up slowly and softly. The staircase was short, and they were soon at the top. There, as it had an abrupt turn in it, they came all at once in sight of three men, whose heads were bent down close together at the side of a door, and who were intently looking into the room to which the door belonged, through some chinks or holes in the wall. On hearing footsteps close at hand, these three turned, and rose, and showed themselves to be the three of one name who had been drinking in the wine-shop.

“I forgot them in the surprise of your visit,” explained Monsieur Defarge. “Leave us, good boys; we have business here.”

The three glided by, and went silently down.

There appearing to be no other door on that floor, and the keeper of the wine-shop going straight to this one when they were left alone, Mr. Lorry asked him in a whisper, with a little anger:

“Do you make a show of Monsieur Manette?”

“I show him, in the way you have seen, to a chosen few.”

“Is that well?”

“I think it is well.”

“Who are the few? How do you choose them?”

“I choose them as real men, of my name—Jacques is my name—to whom the sight is likely to do good. Enough; you are English; that is another thing. Stay there, if you please, a little moment.”

With an admonitory gesture to keep them back, he stooped, and looked in through the crevice in the wall. Soon raising his head again, he struck twice or thrice upon the door—evidently with no other object than to make a noise there. With the same intention, he drew the key across it, three or four times, before he put it clumsily into the lock, and turned it as heavily as he could.

The door slowly opened inward under his hand, and he looked into the room and said something. A faint voice answered something. Little more than a single syllable could have been spoken on either side.

He looked back over his shoulder, and beckoned them to enter. Mr. Lorry got his arm securely round the daughter’s waist, and held her; for he felt that she was sinking.

“A-a-a-business, business!” he urged, with a moisture that was not of business shining on his cheek. “Come in, come in!”

“I am afraid of it,” she answered, shuddering.

“Of it? What?”

“I mean of him. Of my father.”

Rendered in a manner desperate, by her state and by the beckoning of their conductor, he drew over his neck the arm that shook upon his shoulder, lifted her a little, and hurried her into the room. He sat her down just within the door, and held her, clinging to him.

Defarge drew out the key, closed the door, locked it on the inside, took out the key again, and held it in his hand. All this he did, methodically, and with as loud and harsh an accompaniment of noise as he could make. Finally, he walked across the room with a measured tread to where the window was. He stopped there, and faced round.

The garret, built to be a depository for firewood and the like, was dim and dark: for, the window of dormer shape, was in truth a door in the roof, with a little crane over it for the hoisting up of stores from the street: unglazed, and closing up the middle in two pieces, like any other door of French construction. To exclude the cold, one half of this door was fast closed, and the other was opened but a very little way. Such a scanty portion of light was admitted through these means, that it was difficult, on first coming in, to see anything; and long habit alone could have slowly formed in any one, the ability to do any work requiring nicety in such obscurity. Yet, work of that kind was being done in the garret; for, with his back towards the door, and his face towards the window where the keeper of the wine-shop stood looking at him, a white-haired man sat on a low bench, stooping forward and very busy, making shoes.

CHAPTER VI.
The Shoemaker
Good day!” said Monsieur Defarge, looking down at the white head that bent low over the shoemaking.

It was raised for a moment, and a very faint voice responded to the salutation, as if it were at a distance:

“Good day!”

“You are still hard at work, I see?”

After a long silence, the head was lifted for another moment, and the voice replied, “Yes—I am working.” This time, a pair of haggard eyes had looked at the questioner, before the face had dropped again.

The faintness of the voice was pitiable and dreadful. It was not the faintness of physical weakness, though confinement and hard fare no doubt had their part in it. Its deplorable peculiarity was, that it was the faintness of solitude and disuse. It was like the last feeble echo of a sound made long and long ago. So entirely had it lost the life and resonance of the human voice, that it affected the senses like a once beautiful colour faded away into a poor weak stain. So sunken and suppressed it was, that it was like a voice underground. So expressive it was, of a hopeless and lost creature, that a famished traveller, wearied out by lonely wandering in a wilderness, would have remembered home and friends in such a tone before lying down to die.

Some minutes of silent work had passed: and the haggard eyes had looked up again: not with any interest or curiosity, but with a dull mechanical perception, beforehand, that the spot where the only visitor they were aware of had stood, was not yet empty.

“I want,” said Defarge, who had not removed his gaze from the shoemaker, “to let in a little more light here. You can bear a little more?”

The shoemaker stopped his work; looked with a vacant air of listening, at the floor on one side of him; then similarly, at the floor on the other side of him; then, upward at the speaker.

“What did you say?”

“You can bear a little more light?”

“I must bear it, if you let it in.” (Laying the palest shadow of a stress upon the second word.)

The opened half-door was opened a little further, and secured at that angle for the time. A broad ray of light fell into the garret, and showed the workman with an unfinished shoe upon his lap, pausing in his labour. His few common tools and various scraps of leather were at his feet and on his bench. He had a white beard, raggedly cut, but not very long, a hollow face, and exceedingly bright eyes. The hollowness and thinness of his face would have caused them to look large, under his yet dark eyebrows and his confused white hair, though they had been really otherwise; but, they were naturally large, and looked unnaturally so. His yellow rags of shirt lay open at the throat, and showed his body to be withered and worn. He, and his old canvas frock, and his loose stockings, and all his poor tatters of clothes, had, in a long seclusion from direct light and air, faded down to such a dull uniformity of parchment-yellow, that it would have been hard to say which was which.

He had put up a hand between his eyes and the light, and the very bones of it seemed transparent. So he sat, with a steadfastly vacant gaze, pausing in his work. He never looked at the figure before him, without first looking down on this side of himself, then on that, as if he had lost the habit of associating place with sound; he never spoke, without first wandering in this manner, and forgetting to speak.

“Are you going to finish that pair of shoes to-day?” asked Defarge, motioning to Mr. Lorry to come forward.

“What did you say?”

“Do you mean to finish that pair of shoes to-day?”

“I can’t say that I mean to. I suppose so. I don’t know.”

But, the question reminded him of his work, and he bent over it again.

Mr. Lorry came silently forward, leaving the daughter by the door. When he had stood, for a minute or two, by the side of Defarge, the shoemaker looked up. He showed no surprise at seeing another figure, but the unsteady fingers of one of his hands strayed to his lips as he looked at it (his lips and his nails were of the same pale lead-colour), and then the hand dropped to his work, and he once more bent over the shoe. The look and the action had occupied but an instant.

“You have a visitor, you see,” said Monsieur Defarge.

“What did you say?”

“Here is a visitor.”

The shoemaker looked up as before, but without removing a hand from his work.

“Come!” said Defarge. “Here is monsieur, who knows a well-made shoe when he sees one. Show him that shoe you are working at. Take it, monsieur.”

Mr. Lorry took it in his hand.

“Tell monsieur what kind of shoe it is, and the maker’s name.”

There was a longer pause than usual, before the shoemaker replied:

“I forget what it was you asked me. What did you say?”

“I said, couldn’t you describe the kind of shoe, for monsieur’s information?”

“It is a lady’s shoe. It is a young lady’s walking-shoe. It is in the present mode. I never saw the mode. I have had a pattern in my hand.” He glanced at the shoe with some little passing touch of pride.

“And the maker’s name?” said Defarge.

Now that he had no work to hold, he laid the knuckles of the right hand in the hollow of the left, and then the knuckles of the left hand in the hollow of the right, and then passed a hand across his bearded chin, and so on in regular changes, without a moment’s intermission. The task of recalling him from the vagrancy into which he always sank when he had spoken, was like recalling some very weak person from a swoon, or endeavouring, in the hope of some disclosure, to stay the spirit of a fast-dying man.

“Did you ask me for my name?”

“Assuredly I did.”

“One Hundred and Five, North Tower.”

“Is that all?”

“One Hundred and Five, North Tower.”

With a weary sound that was not a sigh, nor a groan, he bent to work again, until the silence was again broken.

“You are not a shoemaker by trade?” said Mr. Lorry, looking steadfastly at him.

His haggard eyes turned to Defarge as if he would have transferred the question to him: but as no help came from that quarter, they turned back on the questioner when they had sought the ground.

“I am not a shoemaker by trade? No, I was not a shoemaker by trade. I-I learnt it here. I taught myself. I asked leave to—”

He lapsed away, even for minutes, ringing those measured changes on his hands the whole time. His eyes came slowly back, at last, to the face from which they had wandered; when they rested on it, he started, and resumed, in the manner of a sleeper that moment awake, reverting to a subject of last night.

“I asked leave to teach myself, and I got it with much difficulty after a long while, and I have made shoes ever since.”

As he held out his hand for the shoe that had been taken from him, Mr. Lorry said, still looking steadfastly in his face:

“Monsieur Manette, do you remember nothing of me?”

The shoe dropped to the ground, and he sat looking fixedly at the questioner.

“Monsieur Manette”; Mr. Lorry laid his hand upon Defarge’s arm; “do you remember nothing of this man? Look at him. Look at me. Is there no old banker, no old business, no old servant, no old time, rising in your mind, Monsieur Manette?”

As the captive of many years sat looking fixedly, by turns, at Mr. Lorry and at Defarge, some long obliterated marks of an actively intent intelligence in the middle of the forehead, gradually forced themselves through the black mist that had fallen on him. They were overclouded again, they were fainter, they were gone; but they had been there. And so exactly was the expression repeated on the fair young face of her who had crept along the wall to a point where she could see him, and where she now stood looking at him, with hands which at first had been only raised in frightened compassion, if not even to keep him off and shut out the sight of him, but which were now extending towards him, trembling with eagerness to lay the spectral face upon her warm young breast, and love it back to life and hope—so exactly was the expression repeated (though in stronger characters) on her fair young face, that it looked as though it had passed like a moving light, from him to her.

Darkness had fallen on him in its place. He looked at the two, less and less attentively, and his eyes in gloomy abstraction sought the ground and looked about him in the old way. Finally, with a deep long sigh, he took the shoe up, and resumed his work.

“Have you recognised him, monsieur?” asked Defarge in a whisper.

“Yes; for a moment. At first I thought it quite hopeless, but I have unquestionably seen, for a single moment, the face that I once knew so well. Hush! Let us draw further back. Hush!”

She had moved from the wall of the garret, very near to the bench on which he sat. There was something awful in his unconsciousness of the figure that could have put out its hand and touched him as he stooped over his labour.

Not a word was spoken, not a sound was made. She stood, like a spirit, beside him, and he bent over his work.

It happened, at length, that he had occasion to change the instrument in his hand, for his shoemaker’s knife. It lay on that side of him which was not the side on which she stood. He had taken it up, and was stooping to work again, when his eyes caught the skirt of her dress. He raised them, and saw her face. The two spectators started forward, but she stayed them with a motion of her hand. She had no fear of his striking at her with the knife, though they had.

He stared at her with a fearful look, and after a while his lips began to form some words, though no sound proceeded from them. By degrees, in the pauses of his quick and laboured breathing, he was heard to say:

“What is this?”

With the tears streaming down her face, she put her two hands to her lips, and kissed them to him; then clasped them on her breast, as if she laid his ruined head there.

“You are not the gaoler’s daughter?”

She sighed “No.”

“Who are you?”

Not yet trusting the tones of her voice, she sat down on the bench beside him. He recoiled, but she laid her hand upon his arm. A strange thrill struck him when she did so, and visibly passed over his frame; he laid the knife down softly, as he sat staring at her.

Her golden hair, which she wore in long curls, had been hurriedly pushed aside, and fell down over her neck. Advancing his hand by little and little, he took it up and looked at it. In the midst of the action he went astray, and, with another deep sigh, fell to work at his shoemaking.

But not for long. Releasing his arm, she laid her hand upon his shoulder. After looking doubtfully at it, two or three times, as if to be sure that it was really there, he laid down his work, put his hand to his neck, and took off a blackened string with a scrap of folded rag attached to it. He opened this, carefully, on his knee, and it contained a very little quantity of hair: not more than one or two long golden hairs, which he had, in some old day, wound off upon his finger.

He took her hair into his hand again, and looked closely at it. “It is the same. How can it be! When was it! How was it!”

As the concentrated expression returned to his forehead, he seemed to become conscious that it was in hers too. He turned her full to the light, and looked at her.

“She had laid her head upon my shoulder, that night when I was summoned out—she had a fear of my going, though I had none—and when I was brought to the North Tower they found these upon my sleeve. ‘You will leave me them? They can never help me to escape in the body, though they may in the spirit.’ Those were the words I said. I remember them very well.”

He formed this speech with his lips many times before he could utter it. But when he did find spoken words for it, they came to him coherently, though slowly.

“How was this?—Was it you?”

Once more, the two spectators started, as he turned upon her with a frightful suddenness. But she sat perfectly still in his grasp, and only said, in a low voice, “I entreat you, good gentlemen, do not come near us, do not speak, do not move!”

“Hark!” he exclaimed. “Whose voice was that?”

His hands released her as he uttered this cry, and went up to his white hair, which they tore in a frenzy. It died out, as everything but his shoemaking did die out of him, and he refolded his little packet and tried to secure it in his breast; but he still looked at her, and gloomily shook his head.

“No, no, no; you are too young, too blooming. It can’t be. See what the prisoner is. These are not the hands she knew, this is not the face she knew, this is not a voice she ever heard. No, no. She was—and He was—before the slow years of the North Tower—ages ago. What is your name, my gentle angel?”

Hailing his softened tone and manner, his daughter fell upon her knees before him, with her appealing hands upon his breast.

“O, sir, at another time you shall know my name, and who my mother was, and who my father, and how I never knew their hard, hard history. But I cannot tell you at this time, and I cannot tell you here. All that I may tell you, here and now, is, that I pray to you to touch me and to bless me. Kiss me, kiss me! O my dear, my dear!”

His cold white head mingled with her radiant hair, which warmed and lighted it as though it were the light of Freedom shining on him.

“If you hear in my voice—I don’t know that it is so, but I hope it is—if you hear in my voice any resemblance to a voice that once was sweet music in your ears, weep for it, weep for it! If you touch, in touching my hair, anything that recalls a beloved head that lay on your breast when you were young and free, weep for it, weep for it! If, when I hint to you of a Home that is before us, where I will be true to you with all my duty and with all my faithful service, I bring back the remembrance of a Home long desolate, while your poor heart pined away, weep for it, weep for it!”

She held him closer round the neck, and rocked him on her breast like a child.

“If, when I tell you, dearest dear, that your agony is over, and that I have come here to take you from it, and that we go to England to be at peace and at rest, I cause you to think of your useful life laid waste, and of our native France so wicked to you, weep for it, weep for it! And if, when I shall tell you of my name, and of my father who is living, and of my mother who is dead, you learn that I have to kneel to my honoured father, and implore his pardon for having never for his sake striven all day and lain awake and wept all night, because the love of my poor mother hid his torture from me, weep for it, weep for it! Weep for her, then, and for me! Good gentlemen, thank God! I feel his sacred tears upon my face, and his sobs strike against my heart. O, see! Thank God for us, thank God!”

He had sunk in her arms, and his face dropped on her breast: a sight so touching, yet so terrible in the tremendous wrong and suffering which had gone before it, that the two beholders covered their faces.',
1) || 'unique needle',
generate_series(1, 100));

INSERT INTO files (content)
SELECT CONCAT(REPEAT('CHAPTER 1. I AM BORN
Whether I shall turn out to be the hero of my own life, or whether that station will be held by anybody else, these pages must show. To begin my life with the beginning of my life, I record that I was born (as I have been informed and believe) on a Friday, at twelve o’clock at night. It was remarked that the clock began to strike, and I began to cry, simultaneously.

In consideration of the day and hour of my birth, it was declared by the nurse, and by some sage women in the neighbourhood who had taken a lively interest in me several months before there was any possibility of our becoming personally acquainted, first, that I was destined to be unlucky in life; and secondly, that I was privileged to see ghosts and spirits; both these gifts inevitably attaching, as they believed, to all unlucky infants of either gender, born towards the small hours on a Friday night.

I need say nothing here, on the first head, because nothing can show better than my history whether that prediction was verified or falsified by the result. On the second branch of the question, I will only remark, that unless I ran through that part of my inheritance while I was still a baby, I have not come into it yet. But I do not at all complain of having been kept out of this property; and if anybody else should be in the present enjoyment of it, he is heartily welcome to keep it.

I was born with a caul, which was advertised for sale, in the newspapers, at the low price of fifteen guineas. Whether sea-going people were short of money about that time, or were short of faith and preferred cork jackets, I don’t know; all I know is, that there was but one solitary bidding, and that was from an attorney connected with the bill-broking business, who offered two pounds in cash, and the balance in sherry, but declined to be guaranteed from drowning on any higher bargain. Consequently the advertisement was withdrawn at a dead loss—for as to sherry, my poor dear mother’s own sherry was in the market then—and ten years afterwards, the caul was put up in a raffle down in our part of the country, to fifty members at half-a-crown a head, the winner to spend five shillings. I was present myself, and I remember to have felt quite uncomfortable and confused, at a part of myself being disposed of in that way. The caul was won, I recollect, by an old lady with a hand-basket, who, very reluctantly, produced from it the stipulated five shillings, all in halfpence, and twopence halfpenny short—as it took an immense time and a great waste of arithmetic, to endeavour without any effect to prove to her. It is a fact which will be long remembered as remarkable down there, that she was never drowned, but died triumphantly in bed, at ninety-two. I have understood that it was, to the last, her proudest boast, that she never had been on the water in her life, except upon a bridge; and that over her tea (to which she was extremely partial) she, to the last, expressed her indignation at the impiety of mariners and others, who had the presumption to go ‘meandering’ about the world. It was in vain to represent to her that some conveniences, tea perhaps included, resulted from this objectionable practice. She always returned, with greater emphasis and with an instinctive knowledge of the strength of her objection, ‘Let us have no meandering.’

Not to meander myself, at present, I will go back to my birth.

I was born at Blunderstone, in Suffolk, or ‘there by’, as they say in Scotland. I was a posthumous child. My father’s eyes had closed upon the light of this world six months, when mine opened on it. There is something strange to me, even now, in the reflection that he never saw me; and something stranger yet in the shadowy remembrance that I have of my first childish associations with his white grave-stone in the churchyard, and of the indefinable compassion I used to feel for it lying out alone there in the dark night, when our little parlour was warm and bright with fire and candle, and the doors of our house were—almost cruelly, it seemed to me sometimes—bolted and locked against it.

An aunt of my father’s, and consequently a great-aunt of mine, of whom I shall have more to relate by and by, was the principal magnate of our family. Miss Trotwood, or Miss Betsey, as my poor mother always called her, when she sufficiently overcame her dread of this formidable personage to mention her at all (which was seldom), had been married to a husband younger than herself, who was very handsome, except in the sense of the homely adage, ‘handsome is, that handsome does’—for he was strongly suspected of having beaten Miss Betsey, and even of having once, on a disputed question of supplies, made some hasty but determined arrangements to throw her out of a two pair of stairs’ window. These evidences of an incompatibility of temper induced Miss Betsey to pay him off, and effect a separation by mutual consent. He went to India with his capital, and there, according to a wild legend in our family, he was once seen riding on an elephant, in company with a Baboon; but I think it must have been a Baboo—or a Begum. Anyhow, from India tidings of his death reached home, within ten years. How they affected my aunt, nobody knew; for immediately upon the separation, she took her maiden name again, bought a cottage in a hamlet on the sea-coast a long way off, established herself there as a single woman with one servant, and was understood to live secluded, ever afterwards, in an inflexible retirement.

My father had once been a favourite of hers, I believe; but she was mortally affronted by his marriage, on the ground that my mother was ‘a wax doll’. She had never seen my mother, but she knew her to be not yet twenty. My father and Miss Betsey never met again. He was double my mother’s age when he married, and of but a delicate constitution. He died a year afterwards, and, as I have said, six months before I came into the world.

This was the state of matters, on the afternoon of, what I may be excused for calling, that eventful and important Friday. I can make no claim therefore to have known, at that time, how matters stood; or to have any remembrance, founded on the evidence of my own senses, of what follows.

My mother was sitting by the fire, but poorly in health, and very low in spirits, looking at it through her tears, and desponding heavily about herself and the fatherless little stranger, who was already welcomed by some grosses of prophetic pins, in a drawer upstairs, to a world not at all excited on the subject of his arrival; my mother, I say, was sitting by the fire, that bright, windy March afternoon, very timid and sad, and very doubtful of ever coming alive out of the trial that was before her, when, lifting her eyes as she dried them, to the window opposite, she saw a strange lady coming up the garden.

My mother had a sure foreboding at the second glance, that it was Miss Betsey. The setting sun was glowing on the strange lady, over the garden-fence, and she came walking up to the door with a fell rigidity of figure and composure of countenance that could have belonged to nobody else.

When she reached the house, she gave another proof of her identity. My father had often hinted that she seldom conducted herself like any ordinary Christian; and now, instead of ringing the bell, she came and looked in at that identical window, pressing the end of her nose against the glass to that extent, that my poor dear mother used to say it became perfectly flat and white in a moment.

She gave my mother such a turn, that I have always been convinced I am indebted to Miss Betsey for having been born on a Friday.

My mother had left her chair in her agitation, and gone behind it in the corner. Miss Betsey, looking round the room, slowly and inquiringly, began on the other side, and carried her eyes on, like a Saracen’s Head in a Dutch clock, until they reached my mother. Then she made a frown and a gesture to my mother, like one who was accustomed to be obeyed, to come and open the door. My mother went.

‘Mrs. David Copperfield, I think,’ said Miss Betsey; the emphasis referring, perhaps, to my mother’s mourning weeds, and her condition.

‘Yes,’ said my mother, faintly.

‘Miss Trotwood,’ said the visitor. ‘You have heard of her, I dare say?’

My mother answered she had had that pleasure. And she had a disagreeable consciousness of not appearing to imply that it had been an overpowering pleasure.

‘Now you see her,’ said Miss Betsey. My mother bent her head, and begged her to walk in.

They went into the parlour my mother had come from, the fire in the best room on the other side of the passage not being lighted—not having been lighted, indeed, since my father’s funeral; and when they were both seated, and Miss Betsey said nothing, my mother, after vainly trying to restrain herself, began to cry. ‘Oh tut, tut, tut!’ said Miss Betsey, in a hurry. ‘Don’t do that! Come, come!’

My mother couldn’t help it notwithstanding, so she cried until she had had her cry out.

‘Take off your cap, child,’ said Miss Betsey, ‘and let me see you.’

My mother was too much afraid of her to refuse compliance with this odd request, if she had any disposition to do so. Therefore she did as she was told, and did it with such nervous hands that her hair (which was luxuriant and beautiful) fell all about her face.

‘Why, bless my heart!’ exclaimed Miss Betsey. ‘You are a very Baby!’

My mother was, no doubt, unusually youthful in appearance even for her years; she hung her head, as if it were her fault, poor thing, and said, sobbing, that indeed she was afraid she was but a childish widow, and would be but a childish mother if she lived. In a short pause which ensued, she had a fancy that she felt Miss Betsey touch her hair, and that with no ungentle hand; but, looking at her, in her timid hope, she found that lady sitting with the skirt of her dress tucked up, her hands folded on one knee, and her feet upon the fender, frowning at the fire.

‘In the name of Heaven,’ said Miss Betsey, suddenly, ‘why Rookery?’

‘Do you mean the house, ma’am?’ asked my mother.

‘Why Rookery?’ said Miss Betsey. ‘Cookery would have been more to the purpose, if you had had any practical ideas of life, either of you.’

‘The name was Mr. Copperfield’s choice,’ returned my mother. ‘When he bought the house, he liked to think that there were rooks about it.’

The evening wind made such a disturbance just now, among some tall old elm-trees at the bottom of the garden, that neither my mother nor Miss Betsey could forbear glancing that way. As the elms bent to one another, like giants who were whispering secrets, and after a few seconds of such repose, fell into a violent flurry, tossing their wild arms about, as if their late confidences were really too wicked for their peace of mind, some weatherbeaten ragged old rooks’-nests, burdening their higher branches, swung like wrecks upon a stormy sea.

‘Where are the birds?’ asked Miss Betsey.

‘The—?’ My mother had been thinking of something else.

‘The rooks—what has become of them?’ asked Miss Betsey.

‘There have not been any since we have lived here,’ said my mother. ‘We thought—Mr. Copperfield thought—it was quite a large rookery; but the nests were very old ones, and the birds have deserted them a long while.’

‘David Copperfield all over!’ cried Miss Betsey. ‘David Copperfield from head to foot! Calls a house a rookery when there’s not a rook near it, and takes the birds on trust, because he sees the nests!’

‘Mr. Copperfield,’ returned my mother, ‘is dead, and if you dare to speak unkindly of him to me—’

My poor dear mother, I suppose, had some momentary intention of committing an assault and battery upon my aunt, who could easily have settled her with one hand, even if my mother had been in far better training for such an encounter than she was that evening. But it passed with the action of rising from her chair; and she sat down again very meekly, and fainted.

When she came to herself, or when Miss Betsey had restored her, whichever it was, she found the latter standing at the window. The twilight was by this time shading down into darkness; and dimly as they saw each other, they could not have done that without the aid of the fire.

‘Well?’ said Miss Betsey, coming back to her chair, as if she had only been taking a casual look at the prospect; ‘and when do you expect—’

‘I am all in a tremble,’ faltered my mother. ‘I don’t know what’s the matter. I shall die, I am sure!’

‘No, no, no,’ said Miss Betsey. ‘Have some tea.’

‘Oh dear me, dear me, do you think it will do me any good?’ cried my mother in a helpless manner.

‘Of course it will,’ said Miss Betsey. ‘It’s nothing but fancy. What do you call your girl?’

‘I don’t know that it will be a girl, yet, ma’am,’ said my mother innocently.

‘Bless the Baby!’ exclaimed Miss Betsey, unconsciously quoting the second sentiment of the pincushion in the drawer upstairs, but applying it to my mother instead of me, ‘I don’t mean that. I mean your servant-girl.’

‘Peggotty,’ said my mother.

‘Peggotty!’ repeated Miss Betsey, with some indignation. ‘Do you mean to say, child, that any human being has gone into a Christian church, and got herself named Peggotty?’ ‘It’s her surname,’ said my mother, faintly. ‘Mr. Copperfield called her by it, because her Christian name was the same as mine.’

‘Here! Peggotty!’ cried Miss Betsey, opening the parlour door. ‘Tea. Your mistress is a little unwell. Don’t dawdle.’

Having issued this mandate with as much potentiality as if she had been a recognized authority in the house ever since it had been a house, and having looked out to confront the amazed Peggotty coming along the passage with a candle at the sound of a strange voice, Miss Betsey shut the door again, and sat down as before: with her feet on the fender, the skirt of her dress tucked up, and her hands folded on one knee.

‘You were speaking about its being a girl,’ said Miss Betsey. ‘I have no doubt it will be a girl. I have a presentiment that it must be a girl. Now child, from the moment of the birth of this girl—’

‘Perhaps boy,’ my mother took the liberty of putting in.

‘I tell you I have a presentiment that it must be a girl,’ returned Miss Betsey. ‘Don’t contradict. From the moment of this girl’s birth, child, I intend to be her friend. I intend to be her godmother, and I beg you’ll call her Betsey Trotwood Copperfield. There must be no mistakes in life with THIS Betsey Trotwood. There must be no trifling with HER affections, poor dear. She must be well brought up, and well guarded from reposing any foolish confidences where they are not deserved. I must make that MY care.’

There was a twitch of Miss Betsey’s head, after each of these sentences, as if her own old wrongs were working within her, and she repressed any plainer reference to them by strong constraint. So my mother suspected, at least, as she observed her by the low glimmer of the fire: too much scared by Miss Betsey, too uneasy in herself, and too subdued and bewildered altogether, to observe anything very clearly, or to know what to say.

‘And was David good to you, child?’ asked Miss Betsey, when she had been silent for a little while, and these motions of her head had gradually ceased. ‘Were you comfortable together?’

‘We were very happy,’ said my mother. ‘Mr. Copperfield was only too good to me.’

‘What, he spoilt you, I suppose?’ returned Miss Betsey.

‘For being quite alone and dependent on myself in this rough world again, yes, I fear he did indeed,’ sobbed my mother.

‘Well! Don’t cry!’ said Miss Betsey. ‘You were not equally matched, child—if any two people can be equally matched—and so I asked the question. You were an orphan, weren’t you?’ ‘Yes.’

‘And a governess?’

‘I was nursery-governess in a family where Mr. Copperfield came to visit. Mr. Copperfield was very kind to me, and took a great deal of notice of me, and paid me a good deal of attention, and at last proposed to me. And I accepted him. And so we were married,’ said my mother simply.

‘Ha! Poor Baby!’ mused Miss Betsey, with her frown still bent upon the fire. ‘Do you know anything?’

‘I beg your pardon, ma’am,’ faltered my mother.

‘About keeping house, for instance,’ said Miss Betsey.

‘Not much, I fear,’ returned my mother. ‘Not so much as I could wish. But Mr. Copperfield was teaching me—’

(‘Much he knew about it himself!’) said Miss Betsey in a parenthesis. —‘And I hope I should have improved, being very anxious to learn, and he very patient to teach me, if the great misfortune of his death’—my mother broke down again here, and could get no farther.

‘Well, well!’ said Miss Betsey. —‘I kept my housekeeping-book regularly, and balanced it with Mr. Copperfield every night,’ cried my mother in another burst of distress, and breaking down again.

‘Well, well!’ said Miss Betsey. ‘Don’t cry any more.’ —‘And I am sure we never had a word of difference respecting it, except when Mr. Copperfield objected to my threes and fives being too much like each other, or to my putting curly tails to my sevens and nines,’ resumed my mother in another burst, and breaking down again.

‘You’ll make yourself ill,’ said Miss Betsey, ‘and you know that will not be good either for you or for my god-daughter. Come! You mustn’t do it!’

This argument had some share in quieting my mother, though her increasing indisposition had a larger one. There was an interval of silence, only broken by Miss Betsey’s occasionally ejaculating ‘Ha!’ as she sat with her feet upon the fender.

‘David had bought an annuity for himself with his money, I know,’ said she, by and by. ‘What did he do for you?’

‘Mr. Copperfield,’ said my mother, answering with some difficulty, ‘was so considerate and good as to secure the reversion of a part of it to me.’

‘How much?’ asked Miss Betsey.

‘A hundred and five pounds a year,’ said my mother.

‘He might have done worse,’ said my aunt.

The word was appropriate to the moment. My mother was so much worse that Peggotty, coming in with the teaboard and candles, and seeing at a glance how ill she was,—as Miss Betsey might have done sooner if there had been light enough,—conveyed her upstairs to her own room with all speed; and immediately dispatched Ham Peggotty, her nephew, who had been for some days past secreted in the house, unknown to my mother, as a special messenger in case of emergency, to fetch the nurse and doctor.

Those allied powers were considerably astonished, when they arrived within a few minutes of each other, to find an unknown lady of portentous appearance, sitting before the fire, with her bonnet tied over her left arm, stopping her ears with jewellers’ cotton. Peggotty knowing nothing about her, and my mother saying nothing about her, she was quite a mystery in the parlour; and the fact of her having a magazine of jewellers’ cotton in her pocket, and sticking the article in her ears in that way, did not detract from the solemnity of her presence.

The doctor having been upstairs and come down again, and having satisfied himself, I suppose, that there was a probability of this unknown lady and himself having to sit there, face to face, for some hours, laid himself out to be polite and social. He was the meekest of his sex, the mildest of little men. He sidled in and out of a room, to take up the less space. He walked as softly as the Ghost in Hamlet, and more slowly. He carried his head on one side, partly in modest depreciation of himself, partly in modest propitiation of everybody else. It is nothing to say that he hadn’t a word to throw at a dog. He couldn’t have thrown a word at a mad dog. He might have offered him one gently, or half a one, or a fragment of one; for he spoke as slowly as he walked; but he wouldn’t have been rude to him, and he couldn’t have been quick with him, for any earthly consideration.

Mr. Chillip, looking mildly at my aunt with his head on one side, and making her a little bow, said, in allusion to the jewellers’ cotton, as he softly touched his left ear:

‘Some local irritation, ma’am?’

‘What!’ replied my aunt, pulling the cotton out of one ear like a cork.

Mr. Chillip was so alarmed by her abruptness—as he told my mother afterwards—that it was a mercy he didn’t lose his presence of mind. But he repeated sweetly:

‘Some local irritation, ma’am?’

‘Nonsense!’ replied my aunt, and corked herself again, at one blow.

Mr. Chillip could do nothing after this, but sit and look at her feebly, as she sat and looked at the fire, until he was called upstairs again. After some quarter of an hour’s absence, he returned.

‘Well?’ said my aunt, taking the cotton out of the ear nearest to him.

‘Well, ma’am,’ returned Mr. Chillip, ‘we are—we are progressing slowly, ma’am.’

‘Ba—a—ah!’ said my aunt, with a perfect shake on the contemptuous interjection. And corked herself as before.

Really—really—as Mr. Chillip told my mother, he was almost shocked; speaking in a professional point of view alone, he was almost shocked. But he sat and looked at her, notwithstanding, for nearly two hours, as she sat looking at the fire, until he was again called out. After another absence, he again returned.

‘Well?’ said my aunt, taking out the cotton on that side again.

‘Well, ma’am,’ returned Mr. Chillip, ‘we are—we are progressing slowly, ma’am.’

‘Ya—a—ah!’ said my aunt. With such a snarl at him, that Mr. Chillip absolutely could not bear it. It was really calculated to break his spirit, he said afterwards. He preferred to go and sit upon the stairs, in the dark and a strong draught, until he was again sent for.

Ham Peggotty, who went to the national school, and was a very dragon at his catechism, and who may therefore be regarded as a credible witness, reported next day, that happening to peep in at the parlour-door an hour after this, he was instantly descried by Miss Betsey, then walking to and fro in a state of agitation, and pounced upon before he could make his escape. That there were now occasional sounds of feet and voices overhead which he inferred the cotton did not exclude, from the circumstance of his evidently being clutched by the lady as a victim on whom to expend her superabundant agitation when the sounds were loudest. That, marching him constantly up and down by the collar (as if he had been taking too much laudanum), she, at those times, shook him, rumpled his hair, made light of his linen, stopped his ears as if she confounded them with her own, and otherwise tousled and maltreated him. This was in part confirmed by his aunt, who saw him at half past twelve o’clock, soon after his release, and affirmed that he was then as red as I was.

The mild Mr. Chillip could not possibly bear malice at such a time, if at any time. He sidled into the parlour as soon as he was at liberty, and said to my aunt in his meekest manner:

‘Well, ma’am, I am happy to congratulate you.’

‘What upon?’ said my aunt, sharply.

Mr. Chillip was fluttered again, by the extreme severity of my aunt’s manner; so he made her a little bow and gave her a little smile, to mollify her.

‘Mercy on the man, what’s he doing!’ cried my aunt, impatiently. ‘Can’t he speak?’

‘Be calm, my dear ma’am,’ said Mr. Chillip, in his softest accents.

‘There is no longer any occasion for uneasiness, ma’am. Be calm.’

It has since been considered almost a miracle that my aunt didn’t shake him, and shake what he had to say, out of him. She only shook her own head at him, but in a way that made him quail.

‘Well, ma’am,’ resumed Mr. Chillip, as soon as he had courage, ‘I am happy to congratulate you. All is now over, ma’am, and well over.’

During the five minutes or so that Mr. Chillip devoted to the delivery of this oration, my aunt eyed him narrowly.

‘How is she?’ said my aunt, folding her arms with her bonnet still tied on one of them.

‘Well, ma’am, she will soon be quite comfortable, I hope,’ returned Mr. Chillip. ‘Quite as comfortable as we can expect a young mother to be, under these melancholy domestic circumstances. There cannot be any objection to your seeing her presently, ma’am. It may do her good.’

‘And SHE. How is SHE?’ said my aunt, sharply.

Mr. Chillip laid his head a little more on one side, and looked at my aunt like an amiable bird.

‘The baby,’ said my aunt. ‘How is she?’

‘Ma’am,’ returned Mr. Chillip, ‘I apprehended you had known. It’s a boy.’

My aunt said never a word, but took her bonnet by the strings, in the manner of a sling, aimed a blow at Mr. Chillip’s head with it, put it on bent, walked out, and never came back. She vanished like a discontented fairy; or like one of those supernatural beings, whom it was popularly supposed I was entitled to see; and never came back any more.

No. I lay in my basket, and my mother lay in her bed; but Betsey Trotwood Copperfield was for ever in the land of dreams and shadows, the tremendous region whence I had so lately travelled; and the light upon the window of our room shone out upon the earthly bourne of all such travellers, and the mound above the ashes and the dust that once was he, without whom I had never been.

CHAPTER 2. I OBSERVE
The first objects that assume a distinct presence before me, as I look far back, into the blank of my infancy, are my mother with her pretty hair and youthful shape, and Peggotty with no shape at all, and eyes so dark that they seemed to darken their whole neighbourhood in her face, and cheeks and arms so hard and red that I wondered the birds didn’t peck her in preference to apples.

I believe I can remember these two at a little distance apart, dwarfed to my sight by stooping down or kneeling on the floor, and I going unsteadily from the one to the other. I have an impression on my mind which I cannot distinguish from actual remembrance, of the touch of Peggotty’s forefinger as she used to hold it out to me, and of its being roughened by needlework, like a pocket nutmeg-grater.

This may be fancy, though I think the memory of most of us can go farther back into such times than many of us suppose; just as I believe the power of observation in numbers of very young children to be quite wonderful for its closeness and accuracy. Indeed, I think that most grown men who are remarkable in this respect, may with greater propriety be said not to have lost the faculty, than to have acquired it; the rather, as I generally observe such men to retain a certain freshness, and gentleness, and capacity of being pleased, which are also an inheritance they have preserved from their childhood.

I might have a misgiving that I am ‘meandering’ in stopping to say this, but that it brings me to remark that I build these conclusions, in part upon my own experience of myself; and if it should appear from anything I may set down in this narrative that I was a child of close observation, or that as a man I have a strong memory of my childhood, I undoubtedly lay claim to both of these characteristics.

Looking back, as I was saying, into the blank of my infancy, the first objects I can remember as standing out by themselves from a confusion of things, are my mother and Peggotty. What else do I remember? Let me see.

There comes out of the cloud, our house—not new to me, but quite familiar, in its earliest remembrance. On the ground-floor is Peggotty’s kitchen, opening into a back yard; with a pigeon-house on a pole, in the centre, without any pigeons in it; a great dog-kennel in a corner, without any dog; and a quantity of fowls that look terribly tall to me, walking about, in a menacing and ferocious manner. There is one cock who gets upon a post to crow, and seems to take particular notice of me as I look at him through the kitchen window, who makes me shiver, he is so fierce. Of the geese outside the side-gate who come waddling after me with their long necks stretched out when I go that way, I dream at night: as a man environed by wild beasts might dream of lions.

Here is a long passage—what an enormous perspective I make of it!—leading from Peggotty’s kitchen to the front door. A dark store-room opens out of it, and that is a place to be run past at night; for I don’t know what may be among those tubs and jars and old tea-chests, when there is nobody in there with a dimly-burning light, letting a mouldy air come out of the door, in which there is the smell of soap, pickles, pepper, candles, and coffee, all at one whiff. Then there are the two parlours: the parlour in which we sit of an evening, my mother and I and Peggotty—for Peggotty is quite our companion, when her work is done and we are alone—and the best parlour where we sit on a Sunday; grandly, but not so comfortably. There is something of a doleful air about that room to me, for Peggotty has told me—I don’t know when, but apparently ages ago—about my father’s funeral, and the company having their black cloaks put on. One Sunday night my mother reads to Peggotty and me in there, how Lazarus was raised up from the dead. And I am so frightened that they are afterwards obliged to take me out of bed, and show me the quiet churchyard out of the bedroom window, with the dead all lying in their graves at rest, below the solemn moon.

There is nothing half so green that I know anywhere, as the grass of that churchyard; nothing half so shady as its trees; nothing half so quiet as its tombstones. The sheep are feeding there, when I kneel up, early in the morning, in my little bed in a closet within my mother’s room, to look out at it; and I see the red light shining on the sun-dial, and think within myself, ‘Is the sun-dial glad, I wonder, that it can tell the time again?’

0041 

Here is our pew in the church. What a high-backed pew! With a window near it, out of which our house can be seen, and IS seen many times during the morning’s service, by Peggotty, who likes to make herself as sure as she can that it’s not being robbed, or is not in flames. But though Peggotty’s eye wanders, she is much offended if mine does, and frowns to me, as I stand upon the seat, that I am to look at the clergyman. But I can’t always look at him—I know him without that white thing on, and I am afraid of his wondering why I stare so, and perhaps stopping the service to inquire—and what am I to do? It’s a dreadful thing to gape, but I must do something. I look at my mother, but she pretends not to see me. I look at a boy in the aisle, and he makes faces at me. I look at the sunlight coming in at the open door through the porch, and there I see a stray sheep—I don’t mean a sinner, but mutton—half making up his mind to come into the church. I feel that if I looked at him any longer, I might be tempted to say something out loud; and what would become of me then! I look up at the monumental tablets on the wall, and try to think of Mr. Bodgers late of this parish, and what the feelings of Mrs. Bodgers must have been, when affliction sore, long time Mr. Bodgers bore, and physicians were in vain. I wonder whether they called in Mr. Chillip, and he was in vain; and if so, how he likes to be reminded of it once a week. I look from Mr. Chillip, in his Sunday neckcloth, to the pulpit; and think what a good place it would be to play in, and what a castle it would make, with another boy coming up the stairs to attack it, and having the velvet cushion with the tassels thrown down on his head. In time my eyes gradually shut up; and, from seeming to hear the clergyman singing a drowsy song in the heat, I hear nothing, until I fall off the seat with a crash, and am taken out, more dead than alive, by Peggotty.

And now I see the outside of our house, with the latticed bedroom-windows standing open to let in the sweet-smelling air, and the ragged old rooks’-nests still dangling in the elm-trees at the bottom of the front garden. Now I am in the garden at the back, beyond the yard where the empty pigeon-house and dog-kennel are—a very preserve of butterflies, as I remember it, with a high fence, and a gate and padlock; where the fruit clusters on the trees, riper and richer than fruit has ever been since, in any other garden, and where my mother gathers some in a basket, while I stand by, bolting furtive gooseberries, and trying to look unmoved. A great wind rises, and the summer is gone in a moment. We are playing in the winter twilight, dancing about the parlour. When my mother is out of breath and rests herself in an elbow-chair, I watch her winding her bright curls round her fingers, and straitening her waist, and nobody knows better than I do that she likes to look so well, and is proud of being so pretty.

That is among my very earliest impressions. That, and a sense that we were both a little afraid of Peggotty, and submitted ourselves in most things to her direction, were among the first opinions—if they may be so called—that I ever derived from what I saw.

Peggotty and I were sitting one night by the parlour fire, alone. I had been reading to Peggotty about crocodiles. I must have read very perspicuously, or the poor soul must have been deeply interested, for I remember she had a cloudy impression, after I had done, that they were a sort of vegetable. I was tired of reading, and dead sleepy; but having leave, as a high treat, to sit up until my mother came home from spending the evening at a neighbour’s, I would rather have died upon my post (of course) than have gone to bed. I had reached that stage of sleepiness when Peggotty seemed to swell and grow immensely large. I propped my eyelids open with my two forefingers, and looked perseveringly at her as she sat at work; at the little bit of wax-candle she kept for her thread—how old it looked, being so wrinkled in all directions!—at the little house with a thatched roof, where the yard-measure lived; at her work-box with a sliding lid, with a view of St. Paul’s Cathedral (with a pink dome) painted on the top; at the brass thimble on her finger; at herself, whom I thought lovely. I felt so sleepy, that I knew if I lost sight of anything for a moment, I was gone.

‘Peggotty,’ says I, suddenly, ‘were you ever married?’

‘Lord, Master Davy,’ replied Peggotty. ‘What’s put marriage in your head?’

She answered with such a start, that it quite awoke me. And then she stopped in her work, and looked at me, with her needle drawn out to its thread’s length.

‘But WERE you ever married, Peggotty?’ says I. ‘You are a very handsome woman, an’t you?’

I thought her in a different style from my mother, certainly; but of another school of beauty, I considered her a perfect example. There was a red velvet footstool in the best parlour, on which my mother had painted a nosegay. The ground-work of that stool, and Peggotty’s complexion appeared to me to be one and the same thing. The stool was smooth, and Peggotty was rough, but that made no difference.

‘Me handsome, Davy!’ said Peggotty. ‘Lawk, no, my dear! But what put marriage in your head?’

‘I don’t know!—You mustn’t marry more than one person at a time, may you, Peggotty?’

‘Certainly not,’ says Peggotty, with the promptest decision.

‘But if you marry a person, and the person dies, why then you may marry another person, mayn’t you, Peggotty?’

‘YOU MAY,’ says Peggotty, ‘if you choose, my dear. That’s a matter of opinion.’

‘But what is your opinion, Peggotty?’ said I.

I asked her, and looked curiously at her, because she looked so curiously at me.

‘My opinion is,’ said Peggotty, taking her eyes from me, after a little indecision and going on with her work, ‘that I never was married myself, Master Davy, and that I don’t expect to be. That’s all I know about the subject.’

‘You an’t cross, I suppose, Peggotty, are you?’ said I, after sitting quiet for a minute.

I really thought she was, she had been so short with me; but I was quite mistaken: for she laid aside her work (which was a stocking of her own), and opening her arms wide, took my curly head within them, and gave it a good squeeze. I know it was a good squeeze, because, being very plump, whenever she made any little exertion after she was dressed, some of the buttons on the back of her gown flew off. And I recollect two bursting to the opposite side of the parlour, while she was hugging me.

‘Now let me hear some more about the Crorkindills,’ said Peggotty, who was not quite right in the name yet, ‘for I an’t heard half enough.’

I couldn’t quite understand why Peggotty looked so queer, or why she was so ready to go back to the crocodiles. However, we returned to those monsters, with fresh wakefulness on my part, and we left their eggs in the sand for the sun to hatch; and we ran away from them, and baffled them by constantly turning, which they were unable to do quickly, on account of their unwieldy make; and we went into the water after them, as natives, and put sharp pieces of timber down their throats; and in short we ran the whole crocodile gauntlet. I did, at least; but I had my doubts of Peggotty, who was thoughtfully sticking her needle into various parts of her face and arms, all the time.

We had exhausted the crocodiles, and begun with the alligators, when the garden-bell rang. We went out to the door; and there was my mother, looking unusually pretty, I thought, and with her a gentleman with beautiful black hair and whiskers, who had walked home with us from church last Sunday.

As my mother stooped down on the threshold to take me in her arms and kiss me, the gentleman said I was a more highly privileged little fellow than a monarch—or something like that; for my later understanding comes, I am sensible, to my aid here.

‘What does that mean?’ I asked him, over her shoulder.

He patted me on the head; but somehow, I didn’t like him or his deep voice, and I was jealous that his hand should touch my mother’s in touching me—which it did. I put it away, as well as I could.

‘Oh, Davy!’ remonstrated my mother.

‘Dear boy!’ said the gentleman. ‘I cannot wonder at his devotion!’

I never saw such a beautiful colour on my mother’s face before. She gently chid me for being rude; and, keeping me close to her shawl, turned to thank the gentleman for taking so much trouble as to bring her home. She put out her hand to him as she spoke, and, as he met it with his own, she glanced, I thought, at me.

‘Let us say “good night”, my fine boy,’ said the gentleman, when he had bent his head—I saw him!—over my mother’s little glove.

‘Good night!’ said I.

‘Come! Let us be the best friends in the world!’ said the gentleman, laughing. ‘Shake hands!’

My right hand was in my mother’s left, so I gave him the other.

‘Why, that’s the Wrong hand, Davy!’ laughed the gentleman.

My mother drew my right hand forward, but I was resolved, for my former reason, not to give it him, and I did not. I gave him the other, and he shook it heartily, and said I was a brave fellow, and went away.

At this minute I see him turn round in the garden, and give us a last look with his ill-omened black eyes, before the door was shut.

Peggotty, who had not said a word or moved a finger, secured the fastenings instantly, and we all went into the parlour. My mother, contrary to her usual habit, instead of coming to the elbow-chair by the fire, remained at the other end of the room, and sat singing to herself. —‘Hope you have had a pleasant evening, ma’am,’ said Peggotty, standing as stiff as a barrel in the centre of the room, with a candlestick in her hand.

‘Much obliged to you, Peggotty,’ returned my mother, in a cheerful voice, ‘I have had a VERY pleasant evening.’

‘A stranger or so makes an agreeable change,’ suggested Peggotty.

‘A very agreeable change, indeed,’ returned my mother.

Peggotty continuing to stand motionless in the middle of the room, and my mother resuming her singing, I fell asleep, though I was not so sound asleep but that I could hear voices, without hearing what they said. When I half awoke from this uncomfortable doze, I found Peggotty and my mother both in tears, and both talking.

‘Not such a one as this, Mr. Copperfield wouldn’t have liked,’ said Peggotty. ‘That I say, and that I swear!’

‘Good Heavens!’ cried my mother, ‘you’ll drive me mad! Was ever any poor girl so ill-used by her servants as I am! Why do I do myself the injustice of calling myself a girl? Have I never been married, Peggotty?’

‘God knows you have, ma’am,’ returned Peggotty. ‘Then, how can you dare,’ said my mother—‘you know I don’t mean how can you dare, Peggotty, but how can you have the heart—to make me so uncomfortable and say such bitter things to me, when you are well aware that I haven’t, out of this place, a single friend to turn to?’

‘The more’s the reason,’ returned Peggotty, ‘for saying that it won’t do. No! That it won’t do. No! No price could make it do. No!’—I thought Peggotty would have thrown the candlestick away, she was so emphatic with it.

‘How can you be so aggravating,’ said my mother, shedding more tears than before, ‘as to talk in such an unjust manner! How can you go on as if it was all settled and arranged, Peggotty, when I tell you over and over again, you cruel thing, that beyond the commonest civilities nothing has passed! You talk of admiration. What am I to do? If people are so silly as to indulge the sentiment, is it my fault? What am I to do, I ask you? Would you wish me to shave my head and black my face, or disfigure myself with a burn, or a scald, or something of that sort? I dare say you would, Peggotty. I dare say you’d quite enjoy it.’

Peggotty seemed to take this aspersion very much to heart, I thought.

‘And my dear boy,’ cried my mother, coming to the elbow-chair in which I was, and caressing me, ‘my own little Davy! Is it to be hinted to me that I am wanting in affection for my precious treasure, the dearest little fellow that ever was!’

‘Nobody never went and hinted no such a thing,’ said Peggotty.

‘You did, Peggotty!’ returned my mother. ‘You know you did. What else was it possible to infer from what you said, you unkind creature, when you know as well as I do, that on his account only last quarter I wouldn’t buy myself a new parasol, though that old green one is frayed the whole way up, and the fringe is perfectly mangy? You know it is, Peggotty. You can’t deny it.’ Then, turning affectionately to me, with her cheek against mine, ‘Am I a naughty mama to you, Davy? Am I a nasty, cruel, selfish, bad mama? Say I am, my child; say “yes”, dear boy, and Peggotty will love you; and Peggotty’s love is a great deal better than mine, Davy. I don’t love you at all, do I?’

At this, we all fell a-crying together. I think I was the loudest of the party, but I am sure we were all sincere about it. I was quite heart-broken myself, and am afraid that in the first transports of wounded tenderness I called Peggotty a ‘Beast’. That honest creature was in deep affliction, I remember, and must have become quite buttonless on the occasion; for a little volley of those explosives went off, when, after having made it up with my mother, she kneeled down by the elbow-chair, and made it up with me.

We went to bed greatly dejected. My sobs kept waking me, for a long time; and when one very strong sob quite hoisted me up in bed, I found my mother sitting on the coverlet, and leaning over me. I fell asleep in her arms, after that, and slept soundly.

Whether it was the following Sunday when I saw the gentleman again, or whether there was any greater lapse of time before he reappeared, I cannot recall. I don’t profess to be clear about dates. But there he was, in church, and he walked home with us afterwards. He came in, too, to look at a famous geranium we had, in the parlour-window. It did not appear to me that he took much notice of it, but before he went he asked my mother to give him a bit of the blossom. She begged him to choose it for himself, but he refused to do that—I could not understand why—so she plucked it for him, and gave it into his hand. He said he would never, never part with it any more; and I thought he must be quite a fool not to know that it would fall to pieces in a day or two.

Peggotty began to be less with us, of an evening, than she had always been. My mother deferred to her very much—more than usual, it occurred to me—and we were all three excellent friends; still we were different from what we used to be, and were not so comfortable among ourselves. Sometimes I fancied that Peggotty perhaps objected to my mother’s wearing all the pretty dresses she had in her drawers, or to her going so often to visit at that neighbour’s; but I couldn’t, to my satisfaction, make out how it was.

Gradually, I became used to seeing the gentleman with the black whiskers. I liked him no better than at first, and had the same uneasy jealousy of him; but if I had any reason for it beyond a child’s instinctive dislike, and a general idea that Peggotty and I could make much of my mother without any help, it certainly was not THE reason that I might have found if I had been older. No such thing came into my mind, or near it. I could observe, in little pieces, as it were; but as to making a net of a number of these pieces, and catching anybody in it, that was, as yet, beyond me.

One autumn morning I was with my mother in the front garden, when Mr. Murdstone—I knew him by that name now—came by, on horseback. He reined up his horse to salute my mother, and said he was going to Lowestoft to see some friends who were there with a yacht, and merrily proposed to take me on the saddle before him if I would like the ride.

The air was so clear and pleasant, and the horse seemed to like the idea of the ride so much himself, as he stood snorting and pawing at the garden-gate, that I had a great desire to go. So I was sent upstairs to Peggotty to be made spruce; and in the meantime Mr. Murdstone dismounted, and, with his horse’s bridle drawn over his arm, walked slowly up and down on the outer side of the sweetbriar fence, while my mother walked slowly up and down on the inner to keep him company. I recollect Peggotty and I peeping out at them from my little window; I recollect how closely they seemed to be examining the sweetbriar between them, as they strolled along; and how, from being in a perfectly angelic temper, Peggotty turned cross in a moment, and brushed my hair the wrong way, excessively hard.

Mr. Murdstone and I were soon off, and trotting along on the green turf by the side of the road. He held me quite easily with one arm, and I don’t think I was restless usually; but I could not make up my mind to sit in front of him without turning my head sometimes, and looking up in his face. He had that kind of shallow black eye—I want a better word to express an eye that has no depth in it to be looked into—which, when it is abstracted, seems from some peculiarity of light to be disfigured, for a moment at a time, by a cast. Several times when I glanced at him, I observed that appearance with a sort of awe, and wondered what he was thinking about so closely. His hair and whiskers were blacker and thicker, looked at so near, than even I had given them credit for being. A squareness about the lower part of his face, and the dotted indication of the strong black beard he shaved close every day, reminded me of the wax-work that had travelled into our neighbourhood some half-a-year before. This, his regular eyebrows, and the rich white, and black, and brown, of his complexion—confound his complexion, and his memory!—made me think him, in spite of my misgivings, a very handsome man. I have no doubt that my poor dear mother thought him so too.

We went to an hotel by the sea, where two gentlemen were smoking cigars in a room by themselves. Each of them was lying on at least four chairs, and had a large rough jacket on. In a corner was a heap of coats and boat-cloaks, and a flag, all bundled up together.

They both rolled on to their feet in an untidy sort of manner, when we came in, and said, ‘Halloa, Murdstone! We thought you were dead!’

‘Not yet,’ said Mr. Murdstone.

‘And who’s this shaver?’ said one of the gentlemen, taking hold of me.

‘That’s Davy,’ returned Mr. Murdstone.

‘Davy who?’ said the gentleman. ‘Jones?’

‘Copperfield,’ said Mr. Murdstone.

‘What! Bewitching Mrs. Copperfield’s encumbrance?’ cried the gentleman. ‘The pretty little widow?’

‘Quinion,’ said Mr. Murdstone, ‘take care, if you please. Somebody’s sharp.’

‘Who is?’ asked the gentleman, laughing. I looked up, quickly; being curious to know.

‘Only Brooks of Sheffield,’ said Mr. Murdstone.

I was quite relieved to find that it was only Brooks of Sheffield; for, at first, I really thought it was I.

There seemed to be something very comical in the reputation of Mr. Brooks of Sheffield, for both the gentlemen laughed heartily when he was mentioned, and Mr. Murdstone was a good deal amused also. After some laughing, the gentleman whom he had called Quinion, said:

‘And what is the opinion of Brooks of Sheffield, in reference to the projected business?’

‘Why, I don’t know that Brooks understands much about it at present,’ replied Mr. Murdstone; ‘but he is not generally favourable, I believe.’

There was more laughter at this, and Mr. Quinion said he would ring the bell for some sherry in which to drink to Brooks. This he did; and when the wine came, he made me have a little, with a biscuit, and, before I drank it, stand up and say, ‘Confusion to Brooks of Sheffield!’ The toast was received with great applause, and such hearty laughter that it made me laugh too; at which they laughed the more. In short, we quite enjoyed ourselves.

We walked about on the cliff after that, and sat on the grass, and looked at things through a telescope—I could make out nothing myself when it was put to my eye, but I pretended I could—and then we came back to the hotel to an early dinner. All the time we were out, the two gentlemen smoked incessantly—which, I thought, if I might judge from the smell of their rough coats, they must have been doing, ever since the coats had first come home from the tailor’s. I must not forget that we went on board the yacht, where they all three descended into the cabin, and were busy with some papers. I saw them quite hard at work, when I looked down through the open skylight. They left me, during this time, with a very nice man with a very large head of red hair and a very small shiny hat upon it, who had got a cross-barred shirt or waistcoat on, with ‘Skylark’ in capital letters across the chest. I thought it was his name; and that as he lived on board ship and hadn’t a street door to put his name on, he put it there instead; but when I called him Mr. Skylark, he said it meant the vessel.

I observed all day that Mr. Murdstone was graver and steadier than the two gentlemen. They were very gay and careless. They joked freely with one another, but seldom with him. It appeared to me that he was more clever and cold than they were, and that they regarded him with something of my own feeling. I remarked that, once or twice when Mr. Quinion was talking, he looked at Mr. Murdstone sideways, as if to make sure of his not being displeased; and that once when Mr. Passnidge (the other gentleman) was in high spirits, he trod upon his foot, and gave him a secret caution with his eyes, to observe Mr. Murdstone, who was sitting stern and silent. Nor do I recollect that Mr. Murdstone laughed at all that day, except at the Sheffield joke—and that, by the by, was his own.

We went home early in the evening. It was a very fine evening, and my mother and he had another stroll by the sweetbriar, while I was sent in to get my tea. When he was gone, my mother asked me all about the day I had had, and what they had said and done. I mentioned what they had said about her, and she laughed, and told me they were impudent fellows who talked nonsense—but I knew it pleased her. I knew it quite as well as I know it now. I took the opportunity of asking if she was at all acquainted with Mr. Brooks of Sheffield, but she answered No, only she supposed he must be a manufacturer in the knife and fork way.

Can I say of her face—altered as I have reason to remember it, perished as I know it is—that it is gone, when here it comes before me at this instant, as distinct as any face that I may choose to look on in a crowded street? Can I say of her innocent and girlish beauty, that it faded, and was no more, when its breath falls on my cheek now, as it fell that night? Can I say she ever changed, when my remembrance brings her back to life, thus only; and, truer to its loving youth than I have been, or man ever is, still holds fast what it cherished then?

I write of her just as she was when I had gone to bed after this talk, and she came to bid me good night. She kneeled down playfully by the side of the bed, and laying her chin upon her hands, and laughing, said:

‘What was it they said, Davy? Tell me again. I can’t believe it.’

‘“Bewitching—“’ I began.

My mother put her hands upon my lips to stop me.

‘It was never bewitching,’ she said, laughing. ‘It never could have been bewitching, Davy. Now I know it wasn’t!’

‘Yes, it was. “Bewitching Mrs. Copperfield”,’ I repeated stoutly. ‘And, “pretty.”’

‘No, no, it was never pretty. Not pretty,’ interposed my mother, laying her fingers on my lips again.

‘Yes it was. “Pretty little widow.”’

‘What foolish, impudent creatures!’ cried my mother, laughing and covering her face. ‘What ridiculous men! An’t they? Davy dear—’

‘Well, Ma.’

‘Don’t tell Peggotty; she might be angry with them. I am dreadfully angry with them myself; but I would rather Peggotty didn’t know.’

I promised, of course; and we kissed one another over and over again, and I soon fell fast asleep.

It seems to me, at this distance of time, as if it were the next day when Peggotty broached the striking and adventurous proposition I am about to mention; but it was probably about two months afterwards.

We were sitting as before, one evening (when my mother was out as before), in company with the stocking and the yard-measure, and the bit of wax, and the box with St. Paul’s on the lid, and the crocodile book, when Peggotty, after looking at me several times, and opening her mouth as if she were going to speak, without doing it—which I thought was merely gaping, or I should have been rather alarmed—said coaxingly:

‘Master Davy, how should you like to go along with me and spend a fortnight at my brother’s at Yarmouth? Wouldn’t that be a treat?’

‘Is your brother an agreeable man, Peggotty?’ I inquired, provisionally.

‘Oh, what an agreeable man he is!’ cried Peggotty, holding up her hands. ‘Then there’s the sea; and the boats and ships; and the fishermen; and the beach; and Am to play with—’

Peggotty meant her nephew Ham, mentioned in my first chapter; but she spoke of him as a morsel of English Grammar.

I was flushed by her summary of delights, and replied that it would indeed be a treat, but what would my mother say?

‘Why then I’ll as good as bet a guinea,’ said Peggotty, intent upon my face, ‘that she’ll let us go. I’ll ask her, if you like, as soon as ever she comes home. There now!’

‘But what’s she to do while we’re away?’ said I, putting my small elbows on the table to argue the point. ‘She can’t live by herself.’

If Peggotty were looking for a hole, all of a sudden, in the heel of that stocking, it must have been a very little one indeed, and not worth darning.

‘I say! Peggotty! She can’t live by herself, you know.’

‘Oh, bless you!’ said Peggotty, looking at me again at last. ‘Don’t you know? She’s going to stay for a fortnight with Mrs. Grayper. Mrs. Grayper’s going to have a lot of company.’

Oh! If that was it, I was quite ready to go. I waited, in the utmost impatience, until my mother came home from Mrs. Grayper’s (for it was that identical neighbour), to ascertain if we could get leave to carry out this great idea. Without being nearly so much surprised as I had expected, my mother entered into it readily; and it was all arranged that night, and my board and lodging during the visit were to be paid for.

The day soon came for our going. It was such an early day that it came soon, even to me, who was in a fever of expectation, and half afraid that an earthquake or a fiery mountain, or some other great convulsion of nature, might interpose to stop the expedition. We were to go in a carrier’s cart, which departed in the morning after breakfast. I would have given any money to have been allowed to wrap myself up over-night, and sleep in my hat and boots.

It touches me nearly now, although I tell it lightly, to recollect how eager I was to leave my happy home; to think how little I suspected what I did leave for ever.

I am glad to recollect that when the carrier’s cart was at the gate, and my mother stood there kissing me, a grateful fondness for her and for the old place I had never turned my back upon before, made me cry. I am glad to know that my mother cried too, and that I felt her heart beat against mine.

I am glad to recollect that when the carrier began to move, my mother ran out at the gate, and called to him to stop, that she might kiss me once more. I am glad to dwell upon the earnestness and love with which she lifted up her face to mine, and did so.

As we left her standing in the road, Mr. Murdstone came up to where she was, and seemed to expostulate with her for being so moved. I was looking back round the awning of the cart, and wondered what business it was of his. Peggotty, who was also looking back on the other side, seemed anything but satisfied; as the face she brought back in the cart denoted.

I sat looking at Peggotty for some time, in a reverie on this supposititious case: whether, if she were employed to lose me like the boy in the fairy tale, I should be able to track my way home again by the buttons she would shed.

CHAPTER 3. I HAVE A CHANGE
The carrier’s horse was the laziest horse in the world, I should hope, and shuffled along, with his head down, as if he liked to keep people waiting to whom the packages were directed. I fancied, indeed, that he sometimes chuckled audibly over this reflection, but the carrier said he was only troubled with a cough. The carrier had a way of keeping his head down, like his horse, and of drooping sleepily forward as he drove, with one of his arms on each of his knees. I say ‘drove’, but it struck me that the cart would have gone to Yarmouth quite as well without him, for the horse did all that; and as to conversation, he had no idea of it but whistling.

Peggotty had a basket of refreshments on her knee, which would have lasted us out handsomely, if we had been going to London by the same conveyance. We ate a good deal, and slept a good deal. Peggotty always went to sleep with her chin upon the handle of the basket, her hold of which never relaxed; and I could not have believed unless I had heard her do it, that one defenceless woman could have snored so much.

We made so many deviations up and down lanes, and were such a long time delivering a bedstead at a public-house, and calling at other places, that I was quite tired, and very glad, when we saw Yarmouth. It looked rather spongy and soppy, I thought, as I carried my eye over the great dull waste that lay across the river; and I could not help wondering, if the world were really as round as my geography book said, how any part of it came to be so flat. But I reflected that Yarmouth might be situated at one of the poles; which would account for it.

As we drew a little nearer, and saw the whole adjacent prospect lying a straight low line under the sky, I hinted to Peggotty that a mound or so might have improved it; and also that if the land had been a little more separated from the sea, and the town and the tide had not been quite so much mixed up, like toast and water, it would have been nicer. But Peggotty said, with greater emphasis than usual, that we must take things as we found them, and that, for her part, she was proud to call herself a Yarmouth Bloater.

When we got into the street (which was strange enough to me) and smelt the fish, and pitch, and oakum, and tar, and saw the sailors walking about, and the carts jingling up and down over the stones, I felt that I had done so busy a place an injustice; and said as much to Peggotty, who heard my expressions of delight with great complacency, and told me it was well known (I suppose to those who had the good fortune to be born Bloaters) that Yarmouth was, upon the whole, the finest place in the universe.

‘Here’s my Am!’ screamed Peggotty, ‘growed out of knowledge!’

He was waiting for us, in fact, at the public-house; and asked me how I found myself, like an old acquaintance. I did not feel, at first, that I knew him as well as he knew me, because he had never come to our house since the night I was born, and naturally he had the advantage of me. But our intimacy was much advanced by his taking me on his back to carry me home. He was, now, a huge, strong fellow of six feet high, broad in proportion, and round-shouldered; but with a simpering boy’s face and curly light hair that gave him quite a sheepish look. He was dressed in a canvas jacket, and a pair of such very stiff trousers that they would have stood quite as well alone, without any legs in them. And you couldn’t so properly have said he wore a hat, as that he was covered in a-top, like an old building, with something pitchy.

Ham carrying me on his back and a small box of ours under his arm, and Peggotty carrying another small box of ours, we turned down lanes bestrewn with bits of chips and little hillocks of sand, and went past gas-works, rope-walks, boat-builders’ yards, shipwrights’ yards, ship-breakers’ yards, caulkers’ yards, riggers’ lofts, smiths’ forges, and a great litter of such places, until we came out upon the dull waste I had already seen at a distance; when Ham said,

‘Yon’s our house, Mas’r Davy!’

I looked in all directions, as far as I could stare over the wilderness, and away at the sea, and away at the river, but no house could I make out. There was a black barge, or some other kind of superannuated boat, not far off, high and dry on the ground, with an iron funnel sticking out of it for a chimney and smoking very cosily; but nothing else in the way of a habitation that was visible to me.

‘That’s not it?’ said I. ‘That ship-looking thing?’

‘That’s it, Mas’r Davy,’ returned Ham.

If it had been Aladdin’s palace, roc’s egg and all, I suppose I could not have been more charmed with the romantic idea of living in it. There was a delightful door cut in the side, and it was roofed in, and there were little windows in it; but the wonderful charm of it was, that it was a real boat which had no doubt been upon the water hundreds of times, and which had never been intended to be lived in, on dry land. That was the captivation of it to me. If it had ever been meant to be lived in, I might have thought it small, or inconvenient, or lonely; but never having been designed for any such use, it became a perfect abode.

It was beautifully clean inside, and as tidy as possible. There was a table, and a Dutch clock, and a chest of drawers, and on the chest of drawers there was a tea-tray with a painting on it of a lady with a parasol, taking a walk with a military-looking child who was trundling a hoop. The tray was kept from tumbling down, by a bible; and the tray, if it had tumbled down, would have smashed a quantity of cups and saucers and a teapot that were grouped around the book. On the walls there were some common coloured pictures, framed and glazed, of scripture subjects; such as I have never seen since in the hands of pedlars, without seeing the whole interior of Peggotty’s brother’s house again, at one view. Abraham in red going to sacrifice Isaac in blue, and Daniel in yellow cast into a den of green lions, were the most prominent of these. Over the little mantelshelf, was a picture of the ‘Sarah Jane’ lugger, built at Sunderland, with a real little wooden stern stuck on to it; a work of art, combining composition with carpentry, which I considered to be one of the most enviable possessions that the world could afford. There were some hooks in the beams of the ceiling, the use of which I did not divine then; and some lockers and boxes and conveniences of that sort, which served for seats and eked out the chairs.

All this I saw in the first glance after I crossed the threshold—child-like, according to my theory—and then Peggotty opened a little door and showed me my bedroom. It was the completest and most desirable bedroom ever seen—in the stern of the vessel; with a little window, where the rudder used to go through; a little looking-glass, just the right height for me, nailed against the wall, and framed with oyster-shells; a little bed, which there was just room enough to get into; and a nosegay of seaweed in a blue mug on the table. The walls were whitewashed as white as milk, and the patchwork counterpane made my eyes quite ache with its brightness. One thing I particularly noticed in this delightful house, was the smell of fish; which was so searching, that when I took out my pocket-handkerchief to wipe my nose, I found it smelt exactly as if it had wrapped up a lobster. On my imparting this discovery in confidence to Peggotty, she informed me that her brother dealt in lobsters, crabs, and crawfish; and I afterwards found that a heap of these creatures, in a state of wonderful conglomeration with one another, and never leaving off pinching whatever they laid hold of, were usually to be found in a little wooden outhouse where the pots and kettles were kept.

We were welcomed by a very civil woman in a white apron, whom I had seen curtseying at the door when I was on Ham’s back, about a quarter of a mile off. Likewise by a most beautiful little girl (or I thought her so) with a necklace of blue beads on, who wouldn’t let me kiss her when I offered to, but ran away and hid herself. By and by, when we had dined in a sumptuous manner off boiled dabs, melted butter, and potatoes, with a chop for me, a hairy man with a very good-natured face came home. As he called Peggotty ‘Lass’, and gave her a hearty smack on the cheek, I had no doubt, from the general propriety of her conduct, that he was her brother; and so he turned out—being presently introduced to me as Mr. Peggotty, the master of the house.

‘Glad to see you, sir,’ said Mr. Peggotty. ‘You’ll find us rough, sir, but you’ll find us ready.’

0061 

I thanked him, and replied that I was sure I should be happy in such a delightful place.

‘How’s your Ma, sir?’ said Mr. Peggotty. ‘Did you leave her pretty jolly?’

I gave Mr. Peggotty to understand that she was as jolly as I could wish, and that she desired her compliments—which was a polite fiction on my part.

‘I’m much obleeged to her, I’m sure,’ said Mr. Peggotty. ‘Well, sir, if you can make out here, fur a fortnut, ‘long wi’ her,’ nodding at his sister, ‘and Ham, and little Em’ly, we shall be proud of your company.’

Having done the honours of his house in this hospitable manner, Mr. Peggotty went out to wash himself in a kettleful of hot water, remarking that ‘cold would never get his muck off’. He soon returned, greatly improved in appearance; but so rubicund, that I couldn’t help thinking his face had this in common with the lobsters, crabs, and crawfish,—that it went into the hot water very black, and came out very red.

After tea, when the door was shut and all was made snug (the nights being cold and misty now), it seemed to me the most delicious retreat that the imagination of man could conceive. To hear the wind getting up out at sea, to know that the fog was creeping over the desolate flat outside, and to look at the fire, and think that there was no house near but this one, and this one a boat, was like enchantment. Little Em’ly had overcome her shyness, and was sitting by my side upon the lowest and least of the lockers, which was just large enough for us two, and just fitted into the chimney corner. Mrs. Peggotty with the white apron, was knitting on the opposite side of the fire. Peggotty at her needlework was as much at home with St. Paul’s and the bit of wax-candle, as if they had never known any other roof. Ham, who had been giving me my first lesson in all-fours, was trying to recollect a scheme of telling fortunes with the dirty cards, and was printing off fishy impressions of his thumb on all the cards he turned. Mr. Peggotty was smoking his pipe. I felt it was a time for conversation and confidence.

‘Mr. Peggotty!’ says I.

‘Sir,’ says he.

‘Did you give your son the name of Ham, because you lived in a sort of ark?’

Mr. Peggotty seemed to think it a deep idea, but answered:

‘No, sir. I never giv him no name.’

‘Who gave him that name, then?’ said I, putting question number two of the catechism to Mr. Peggotty.

‘Why, sir, his father giv it him,’ said Mr. Peggotty.

‘I thought you were his father!’

‘My brother Joe was his father,’ said Mr. Peggotty.

‘Dead, Mr. Peggotty?’ I hinted, after a respectful pause.

‘Drowndead,’ said Mr. Peggotty.

I was very much surprised that Mr. Peggotty was not Ham’s father, and began to wonder whether I was mistaken about his relationship to anybody else there. I was so curious to know, that I made up my mind to have it out with Mr. Peggotty.

‘Little Em’ly,’ I said, glancing at her. ‘She is your daughter, isn’t she, Mr. Peggotty?’

‘No, sir. My brother-in-law, Tom, was her father.’

I couldn’t help it. ‘—Dead, Mr. Peggotty?’ I hinted, after another respectful silence.

‘Drowndead,’ said Mr. Peggotty.

I felt the difficulty of resuming the subject, but had not got to the bottom of it yet, and must get to the bottom somehow. So I said:

‘Haven’t you ANY children, Mr. Peggotty?’

‘No, master,’ he answered with a short laugh. ‘I’m a bacheldore.’

‘A bachelor!’ I said, astonished. ‘Why, who’s that, Mr. Peggotty?’ pointing to the person in the apron who was knitting.

‘That’s Missis Gummidge,’ said Mr. Peggotty.

‘Gummidge, Mr. Peggotty?’

But at this point Peggotty—I mean my own peculiar Peggotty—made such impressive motions to me not to ask any more questions, that I could only sit and look at all the silent company, until it was time to go to bed. Then, in the privacy of my own little cabin, she informed me that Ham and Em’ly were an orphan nephew and niece, whom my host had at different times adopted in their childhood, when they were left destitute: and that Mrs. Gummidge was the widow of his partner in a boat, who had died very poor. He was but a poor man himself, said Peggotty, but as good as gold and as true as steel—those were her similes. The only subject, she informed me, on which he ever showed a violent temper or swore an oath, was this generosity of his; and if it were ever referred to, by any one of them, he struck the table a heavy blow with his right hand (had split it on one such occasion), and swore a dreadful oath that he would be ‘Gormed’ if he didn’t cut and run for good, if it was ever mentioned again. It appeared, in answer to my inquiries, that nobody had the least idea of the etymology of this terrible verb passive to be gormed; but that they all regarded it as constituting a most solemn imprecation.

I was very sensible of my entertainer’s goodness, and listened to the women’s going to bed in another little crib like mine at the opposite end of the boat, and to him and Ham hanging up two hammocks for themselves on the hooks I had noticed in the roof, in a very luxurious state of mind, enhanced by my being sleepy. As slumber gradually stole upon me, I heard the wind howling out at sea and coming on across the flat so fiercely, that I had a lazy apprehension of the great deep rising in the night. But I bethought myself that I was in a boat, after all; and that a man like Mr. Peggotty was not a bad person to have on board if anything did happen.

Nothing happened, however, worse than morning. Almost as soon as it shone upon the oyster-shell frame of my mirror I was out of bed, and out with little Em’ly, picking up stones upon the beach.

‘You’re quite a sailor, I suppose?’ I said to Em’ly. I don’t know that I supposed anything of the kind, but I felt it an act of gallantry to say something; and a shining sail close to us made such a pretty little image of itself, at the moment, in her bright eye, that it came into my head to say this.

‘No,’ replied Em’ly, shaking her head, ‘I’m afraid of the sea.’

‘Afraid!’ I said, with a becoming air of boldness, and looking very big at the mighty ocean. ‘I an’t!’

‘Ah! but it’s cruel,’ said Em’ly. ‘I have seen it very cruel to some of our men. I have seen it tear a boat as big as our house, all to pieces.’

‘I hope it wasn’t the boat that—’

‘That father was drownded in?’ said Em’ly. ‘No. Not that one, I never see that boat.’

‘Nor him?’ I asked her.

Little Em’ly shook her head. ‘Not to remember!’

Here was a coincidence! I immediately went into an explanation how I had never seen my own father; and how my mother and I had always lived by ourselves in the happiest state imaginable, and lived so then, and always meant to live so; and how my father’s grave was in the churchyard near our house, and shaded by a tree, beneath the boughs of which I had walked and heard the birds sing many a pleasant morning. But there were some differences between Em’ly’s orphanhood and mine, it appeared. She had lost her mother before her father; and where her father’s grave was no one knew, except that it was somewhere in the depths of the sea.

‘Besides,’ said Em’ly, as she looked about for shells and pebbles, ‘your father was a gentleman and your mother is a lady; and my father was a fisherman and my mother was a fisherman’s daughter, and my uncle Dan is a fisherman.’

‘Dan is Mr. Peggotty, is he?’ said I.

‘Uncle Dan—yonder,’ answered Em’ly, nodding at the boat-house.

‘Yes. I mean him. He must be very good, I should think?’

‘Good?’ said Em’ly. ‘If I was ever to be a lady, I’d give him a sky-blue coat with diamond buttons, nankeen trousers, a red velvet waistcoat, a cocked hat, a large gold watch, a silver pipe, and a box of money.’

I said I had no doubt that Mr. Peggotty well deserved these treasures. I must acknowledge that I felt it difficult to picture him quite at his ease in the raiment proposed for him by his grateful little niece, and that I was particularly doubtful of the policy of the cocked hat; but I kept these sentiments to myself.

Little Em’ly had stopped and looked up at the sky in her enumeration of these articles, as if they were a glorious vision. We went on again, picking up shells and pebbles.

‘You would like to be a lady?’ I said.

Emily looked at me, and laughed and nodded ‘yes’.

‘I should like it very much. We would all be gentlefolks together, then. Me, and uncle, and Ham, and Mrs. Gummidge. We wouldn’t mind then, when there comes stormy weather.—-Not for our own sakes, I mean. We would for the poor fishermen’s, to be sure, and we’d help ‘em with money when they come to any hurt.’ This seemed to me to be a very satisfactory and therefore not at all improbable picture. I expressed my pleasure in the contemplation of it, and little Em’ly was emboldened to say, shyly,

‘Don’t you think you are afraid of the sea, now?’

It was quiet enough to reassure me, but I have no doubt if I had seen a moderately large wave come tumbling in, I should have taken to my heels, with an awful recollection of her drowned relations. However, I said ‘No,’ and I added, ‘You don’t seem to be either, though you say you are,’—for she was walking much too near the brink of a sort of old jetty or wooden causeway we had strolled upon, and I was afraid of her falling over.

‘I’m not afraid in this way,’ said little Em’ly. ‘But I wake when it blows, and tremble to think of Uncle Dan and Ham and believe I hear ‘em crying out for help. That’s why I should like so much to be a lady. But I’m not afraid in this way. Not a bit. Look here!’

She started from my side, and ran along a jagged timber which protruded from the place we stood upon, and overhung the deep water at some height, without the least defence. The incident is so impressed on my remembrance, that if I were a draughtsman I could draw its form here, I dare say, accurately as it was that day, and little Em’ly springing forward to her destruction (as it appeared to me), with a look that I have never forgotten, directed far out to sea.

The light, bold, fluttering little figure turned and came back safe to me, and I soon laughed at my fears, and at the cry I had uttered; fruitlessly in any case, for there was no one near. But there have been times since, in my manhood, many times there have been, when I have thought, Is it possible, among the possibilities of hidden things, that in the sudden rashness of the child and her wild look so far off, there was any merciful attraction of her into danger, any tempting her towards him permitted on the part of her dead father, that her life might have a chance of ending that day? There has been a time since when I have wondered whether, if the life before her could have been revealed to me at a glance, and so revealed as that a child could fully comprehend it, and if her preservation could have depended on a motion of my hand, I ought to have held it up to save her. There has been a time since—I do not say it lasted long, but it has been—when I have asked myself the question, would it have been better for little Em’ly to have had the waters close above her head that morning in my sight; and when I have answered Yes, it would have been.

This may be premature. I have set it down too soon, perhaps. But let it stand.

We strolled a long way, and loaded ourselves with things that we thought curious, and put some stranded starfish carefully back into the water—I hardly know enough of the race at this moment to be quite certain whether they had reason to feel obliged to us for doing so, or the reverse—and then made our way home to Mr. Peggotty’s dwelling. We stopped under the lee of the lobster-outhouse to exchange an innocent kiss, and went in to breakfast glowing with health and pleasure.

‘Like two young mavishes,’ Mr. Peggotty said. I knew this meant, in our local dialect, like two young thrushes, and received it as a compliment.

Of course I was in love with little Em’ly. I am sure I loved that baby quite as truly, quite as tenderly, with greater purity and more disinterestedness, than can enter into the best love of a later time of life, high and ennobling as it is. I am sure my fancy raised up something round that blue-eyed mite of a child, which etherealized, and made a very angel of her. If, any sunny forenoon, she had spread a little pair of wings and flown away before my eyes, I don’t think I should have regarded it as much more than I had had reason to expect.

We used to walk about that dim old flat at Yarmouth in a loving manner, hours and hours. The days sported by us, as if Time had not grown up himself yet, but were a child too, and always at play. I told Em’ly I adored her, and that unless she confessed she adored me I should be reduced to the necessity of killing myself with a sword. She said she did, and I have no doubt she did.

As to any sense of inequality, or youthfulness, or other difficulty in our way, little Em’ly and I had no such trouble, because we had no future. We made no more provision for growing older, than we did for growing younger. We were the admiration of Mrs. Gummidge and Peggotty, who used to whisper of an evening when we sat, lovingly, on our little locker side by side, ‘Lor! wasn’t it beautiful!’ Mr. Peggotty smiled at us from behind his pipe, and Ham grinned all the evening and did nothing else. They had something of the sort of pleasure in us, I suppose, that they might have had in a pretty toy, or a pocket model of the Colosseum.

I soon found out that Mrs. Gummidge did not always make herself so agreeable as she might have been expected to do, under the circumstances of her residence with Mr. Peggotty. Mrs. Gummidge’s was rather a fretful disposition, and she whimpered more sometimes than was comfortable for other parties in so small an establishment. I was very sorry for her; but there were moments when it would have been more agreeable, I thought, if Mrs. Gummidge had had a convenient apartment of her own to retire to, and had stopped there until her spirits revived.

Mr. Peggotty went occasionally to a public-house called The Willing Mind. I discovered this, by his being out on the second or third evening of our visit, and by Mrs. Gummidge’s looking up at the Dutch clock, between eight and nine, and saying he was there, and that, what was more, she had known in the morning he would go there.

Mrs. Gummidge had been in a low state all day, and had burst into tears in the forenoon, when the fire smoked. ‘I am a lone lorn creetur’,’ were Mrs. Gummidge’s words, when that unpleasant occurrence took place, ‘and everythink goes contrary with me.’

‘Oh, it’ll soon leave off,’ said Peggotty—I again mean our Peggotty—‘and besides, you know, it’s not more disagreeable to you than to us.’

‘I feel it more,’ said Mrs. Gummidge.

It was a very cold day, with cutting blasts of wind. Mrs. Gummidge’s peculiar corner of the fireside seemed to me to be the warmest and snuggest in the place, as her chair was certainly the easiest, but it didn’t suit her that day at all. She was constantly complaining of the cold, and of its occasioning a visitation in her back which she called ‘the creeps’. At last she shed tears on that subject, and said again that she was ‘a lone lorn creetur’ and everythink went contrary with her’.

‘It is certainly very cold,’ said Peggotty. ‘Everybody must feel it so.’

‘I feel it more than other people,’ said Mrs. Gummidge.

So at dinner; when Mrs. Gummidge was always helped immediately after me, to whom the preference was given as a visitor of distinction. The fish were small and bony, and the potatoes were a little burnt. We all acknowledged that we felt this something of a disappointment; but Mrs. Gummidge said she felt it more than we did, and shed tears again, and made that former declaration with great bitterness.

Accordingly, when Mr. Peggotty came home about nine o’clock, this unfortunate Mrs. Gummidge was knitting in her corner, in a very wretched and miserable condition. Peggotty had been working cheerfully. Ham had been patching up a great pair of waterboots; and I, with little Em’ly by my side, had been reading to them. Mrs. Gummidge had never made any other remark than a forlorn sigh, and had never raised her eyes since tea.

‘Well, Mates,’ said Mr. Peggotty, taking his seat, ‘and how are you?’

We all said something, or looked something, to welcome him, except Mrs. Gummidge, who only shook her head over her knitting.

‘What’s amiss?’ said Mr. Peggotty, with a clap of his hands. ‘Cheer up, old Mawther!’ (Mr. Peggotty meant old girl.)

Mrs. Gummidge did not appear to be able to cheer up. She took out an old black silk handkerchief and wiped her eyes; but instead of putting it in her pocket, kept it out, and wiped them again, and still kept it out, ready for use.

‘What’s amiss, dame?’ said Mr. Peggotty.

‘Nothing,’ returned Mrs. Gummidge. ‘You’ve come from The Willing Mind, Dan’l?’

‘Why yes, I’ve took a short spell at The Willing Mind tonight,’ said Mr. Peggotty.

‘I’m sorry I should drive you there,’ said Mrs. Gummidge.

‘Drive! I don’t want no driving,’ returned Mr. Peggotty with an honest laugh. ‘I only go too ready.’

‘Very ready,’ said Mrs. Gummidge, shaking her head, and wiping her eyes. ‘Yes, yes, very ready. I am sorry it should be along of me that you’re so ready.’

‘Along o’ you! It an’t along o’ you!’ said Mr. Peggotty. ‘Don’t ye believe a bit on it.’

‘Yes, yes, it is,’ cried Mrs. Gummidge. ‘I know what I am. I know that I am a lone lorn creetur’, and not only that everythink goes contrary with me, but that I go contrary with everybody. Yes, yes. I feel more than other people do, and I show it more. It’s my misfortun’.’

I really couldn’t help thinking, as I sat taking in all this, that the misfortune extended to some other members of that family besides Mrs. Gummidge. But Mr. Peggotty made no such retort, only answering with another entreaty to Mrs. Gummidge to cheer up.

‘I an’t what I could wish myself to be,’ said Mrs. Gummidge. ‘I am far from it. I know what I am. My troubles has made me contrary. I feel my troubles, and they make me contrary. I wish I didn’t feel ‘em, but I do. I wish I could be hardened to ‘em, but I an’t. I make the house uncomfortable. I don’t wonder at it. I’ve made your sister so all day, and Master Davy.’

Here I was suddenly melted, and roared out, ‘No, you haven’t, Mrs. Gummidge,’ in great mental distress.

‘It’s far from right that I should do it,’ said Mrs. Gummidge. ‘It an’t a fit return. I had better go into the house and die. I am a lone lorn creetur’, and had much better not make myself contrary here. If thinks must go contrary with me, and I must go contrary myself, let me go contrary in my parish. Dan’l, I’d better go into the house, and die and be a riddance!’

Mrs. Gummidge retired with these words, and betook herself to bed. When she was gone, Mr. Peggotty, who had not exhibited a trace of any feeling but the profoundest sympathy, looked round upon us, and nodding his head with a lively expression of that sentiment still animating his face, said in a whisper:

‘She’s been thinking of the old ‘un!’

I did not quite understand what old one Mrs. Gummidge was supposed to have fixed her mind upon, until Peggotty, on seeing me to bed, explained that it was the late Mr. Gummidge; and that her brother always took that for a received truth on such occasions, and that it always had a moving effect upon him. Some time after he was in his hammock that night, I heard him myself repeat to Ham, ‘Poor thing! She’s been thinking of the old ‘un!’ And whenever Mrs. Gummidge was overcome in a similar manner during the remainder of our stay (which happened some few times), he always said the same thing in extenuation of the circumstance, and always with the tenderest
',
1) || 'unique needle',
generate_series(1, 100));