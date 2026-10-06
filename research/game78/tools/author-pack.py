"""Original TRHGD-authored research pack. Curated CC0 vocabulary is separate.
All profiles carry stable IDs; changing this authoring source creates a new pack digest."""
import json,re
from pathlib import Path
P={"version":"trhgd-game78-1","author":"TRHGD project; original research content","license":"Project-owned original content; third-party vocabulary has separate notices"}
def ident(s):return re.sub(r'[^a-z0-9]+','-',s.lower()).strip('-')
def rows(text,fields):
 out=[]
 for line in text.strip().splitlines():
  parts=line.split('|');row=dict(zip(fields,parts));row['id']=ident(parts[0]);row.setdefault('requires',[]);out.append(row)
 return out
P['purposes']=rows('''watchtower|military|watchtower|observation post
signal station|communication|signal station|message relay
border storehouse|military|border storehouse|supply depot
training yard|military|training yard|instruction ground
road shelter|travel|road shelter|traveller refuge
toll house|administrative|toll house|route accounting
record hall|administrative|record hall|register archive
weigh house|trade|weigh house|measure inspection
market shelter|trade|market shelter|covered exchange
pack animal yard|trade|pack-animal yard|caravan staging
smithy|industrial|smithy|metalworking
pottery kiln|industrial|pottery kiln|ceramic firing
lime kiln|industrial|lime kiln|mortar preparation
stone cutting yard|resource|stone-cutting yard|masonry preparation
charcoal shelter|resource|charcoal shelter|fuel storage
ore sorting floor|resource|ore-sorting floor|mineral sorting
seed store|agricultural|seed store|seed keeping
granary|agricultural|granary|grain storage
press house|agricultural|press house|crop processing
drying barn|agricultural|drying barn|harvest drying
sick house|refuge|sick house|convalescence
winter refuge|refuge|winter refuge|seasonal shelter
common kitchen|domestic|common kitchen|shared cooking
wash house|domestic|wash house|laundry work
manor outbuilding|domestic|manor outbuilding|household storage
burial chapel|burial|burial chapel|funeral observance
memorial court|burial|memorial court|commemoration
scriptorium|research|scriptorium|manuscript copying
survey lodge|research|survey lodge|boundary records
small observatory|research|small observatory|sky observation
pilgrim lodge|religious|pilgrim lodge|pilgrim shelter
votive hall|religious|votive hall|public offerings
ceremonial court|ritual|ceremonial court|communal observance
defensive gatehouse|defensive|gatehouse|controlled access
cistern court|domestic|cistern court|water storage
boat repair shed|industrial|boat-repair shed|hull repairs''',['key','category','label','function'])
P['purposes'][-1]['requires']=['port']
P['conditions']=rows('''roof missing|roof|open to the weather
roof patched|roof|patched roof timbers
roof intact|roof|an intact roof
roof sagging|roof|sagging roof beams
roof tiled|roof|uneven surviving tiles
walls braced|walls|braced masonry
walls weathered|walls|weathered stonework
walls scorched|walls|smoke-stained walls
walls cracked|walls|cracked mortar joints
walls stripped|walls|bare inner walls
walls repaired|walls|newer masonry among older courses
walls chalked|walls|faded tally marks
entrance blocked|access|an entrance blocked by fallen masonry
entrance open|access|an open entrance
entrance boarded|access|a boarded doorway
entrance widened|access|a widened doorway
entrance narrowed|access|a later narrow threshold
entrance barred|access|a rusted door bar
floor uneven|floor|an uneven floor
floor swept|floor|a swept central floor
floor subsided|floor|a sunken floor corner
floor paved|floor|worn stone paving
floor gravelled|floor|gravel over the old floor
floor stained|floor|dark stains across the floor
surrounds cleared|surrounds|a cleared strip around the walls
surrounds rubble|surrounds|sorted rubble outside
surrounds nettles|surrounds|nettles along the footings
surrounds trees|surrounds|tree roots around the footings
surrounds sand|surrounds|windblown sand along the footings
surrounds reeds|surrounds|reeds around damp footings
surrounds stacked|surrounds|stacked salvaged bricks
surrounds trodden|surrounds|a trampled patch by the threshold''',['key','facet','label'])
for r in P['conditions']:
 if r['id']=='surrounds-trees':r['requires']=['forest']
 if r['id']=='surrounds-sand':r['requires']=['arid']
 if r['id']=='surrounds-reeds':r['requires']=['wetland']
P['events']=rows('''foundation laid|founded|laid the first foundations|standing
wing added|expanded|added a small wing|standing
store built|expanded|built an adjoining store|standing
porch added|expanded|added a sheltered porch|standing
court enclosed|expanded|enclosed the outer court|standing
upper floor added|expanded|added an upper floor|standing
roof renewed|repair|renewed the roof|standing
floor relaid|repair|relaid the central floor|standing
wall braced|repair|braced a failing wall|standing
lintel replaced|repair|replaced a cracked lintel|standing
stair repaired|repair|repaired the main stair|standing
door replaced|repair|fitted a replacement door|standing
fire damaged roof|damage|lost part of the roof to fire|damaged
storm broke roof|damage|lost roof timbers in a storm|damaged
beam failed|damage|suffered a beam failure|damaged
stair collapsed|damage|lost the inner stair|damaged
wall cracked|damage|developed a crack in the outer wall|damaged
subsidence occurred|damage|suffered subsidence at one corner|damaged
stone removed|salvage|had dressed stone removed for reuse|damaged
tiles salvaged|salvage|had roof tiles taken for repairs elsewhere|damaged
iron stripped|salvage|had its iron fittings stripped|damaged
timber salvaged|salvage|had sound timbers taken away|damaged
paving lifted|salvage|had part of its paving lifted|damaged
door sold|salvage|had its outer door sold|damaged
storage reuse|reuse|became a temporary store|standing
meeting reuse|reuse|became a meeting place|standing
workshop reuse|reuse|housed a small repair workshop|standing
shelter reuse|reuse|sheltered displaced households|standing
archive reuse|reuse|held salvaged records|standing
kitchen reuse|reuse|housed a shared kitchen|standing
keeper appointed|care|gained a resident keeper|standing
threshold cleared|care|had its threshold cleared|standing
stones catalogued|care|had its worked stones catalogued|standing
roof tarred|care|had the surviving roof weatherproofed|standing
boundary marked|care|had its boundary marked with stones|standing
rubble sorted|care|had the outer rubble sorted|standing
account disputed|social|became the subject of an ownership dispute|standing
keeper departed|social|lost its last resident keeper|abandoned
lease ended|social|fell out of use when its lease ended|abandoned
work moved|social|lost its work to another building|abandoned
records moved|social|had its records moved elsewhere|abandoned
funding ceased|social|lost the funds for ordinary repairs|abandoned
storage emptied|abandonment|had its last stores removed|abandoned
doors sealed|abandonment|had its doors sealed|abandoned
staff dispersed|abandonment|lost its remaining workers|abandoned
keys surrendered|abandonment|had its keys surrendered|abandoned
service ended|abandonment|ceased its original service|abandoned
inventory closed|abandonment|had its last inventory closed|abandoned
memorial added|memory|gained a small memorial stone|standing
name recorded|memory|had its old name entered in local records|standing
repair marked|memory|had a repair date cut into a lintel|standing
plan copied|memory|had its floor plan copied|standing
stone numbered|memory|had its dressed stones numbered|standing
story collected|memory|had a keeper's account recorded|standing
river flood|damage|lost stored goods to flooding|damaged
forest encroached|abandonment|had trees take root against the walls|abandoned
harbour lease|social|received a lease for harbour storage|standing
watch quartered|reuse|housed a temporary gate watch|standing''',['key','category','clause','state'])
for r in P['events']:
 if r['id']=='river-flood':r['requires']=['river']
 if r['id']=='forest-encroached':r['requires']=['forest']
 if r['id']=='harbour-lease':r['requires']=['port']
 if r['id']=='watch-quartered':r['requires']=['walls']
# Public memories are distinct historical actions, not synonyms. Actors and
# observable consequences are structured separately; clauses belong to the renderer.
P['memories']=rows('''shared roof repair|households|pooled spare tiles after several roofs failed|a store of spare tiles
workshop loan|craft workers|lent their benches while a neighbouring workshop was repaired|a shared workbench
old register|clerks|copied a damaged household register by hand|a duplicate register
winter kitchen|neighbours|kept a common kitchen through a hard winter|a large cooking pot
lost tally|traders|settled a dispute by comparing their own tally sticks|matched tally sticks
water vessel|households|collected vessels for carrying water during repairs|a row of old carrying jars
funeral cloth|weavers|made a shared funeral cloth for families unable to provide one|a carefully patched cloth
boundary ledger|record keepers|recorded household boundaries after an old ledger was lost|a replacement ledger
school bench|parents|built a bench for the first shared lessons|a worn school bench
borrowed tools|apprentices|kept a list of tools lent between workshops|a tool-loan register
failed bell|metalworkers|mended the small bell used to call communal meetings|a soldered bell
harvest drying|growers|shared covered space after a wet harvest|a drying rack
common scales|traders|agreed to keep one set of comparison weights|a boxed set of weights
brick collection|masons|saved usable bricks from a dismantled building|a stack of marked bricks
cold cellar|households|shared a cool storage room when several stores spoiled|a set of cellar shelves
street lamps|neighbours|took turns tending simple lamps on dark evenings|a soot-marked lamp
written debts|shopkeepers|copied old debts before a damaged book fell apart|a bound debt book
mended banner|needleworkers|repaired a plain banner used at communal gatherings|a patched banner
orphan apprenticeship|craft workers|arranged apprenticeships for children without a household trade|a training ledger
retired keeper|neighbours|maintained a retired keeper's home in return for teaching repairs|a keeper's tool chest
market awning|stall holders|sewed a common awning after rain spoiled stored wares|a patched awning
letter chest|clerks|provided a locked chest for letters awaiting collection|a wooden letter chest
old song|elders|wrote down a work song before its last regular singers died|a sheet of song words
stone benches|masons|set aside offcuts to make benches for public meetings|a stone bench
wash day|households|agreed on turns at a shared washing place|a washing rota
shared oven|bakers|let neighbours use their oven while home hearths were repaired|an oven-use tally
repair lessons|craft workers|held free lessons in mending ordinary tools|a practice tool rack
blanket stock|needleworkers|put aside blankets for households whose bedding was lost|a blanket chest
hearth tax|clerks|corrected a levy after several households were counted twice|a corrected account
lost keys|keepers|commissioned a spare set after keys were mislaid|a spare-key board
measurement mark|builders|cut a common measuring mark into an old workbench|a notched workbench
burial register|record keepers|copied faded names from an older burial register|a copied name list
common cart|carters|shared a cart during repairs to several broken axles|a repaired axle
pot repair|potters|gathered broken household vessels for inexpensive repairs|a pot-mending bench
cloth measures|weavers|agreed on comparison lengths for traded cloth|a marked cloth rod
hearth stones|masons|reused dressed stones from an empty storehouse for hearth repairs|a reused hearth block
old shutters|woodworkers|reworked discarded shutters into storage boxes|a shutter-board chest
disputed seal|clerks|settled a document dispute by recording who had witnessed it|a witness list
lost apprentice|craft workers|kept a place for an apprentice who never returned|an unused stool
common savings|households|kept small contributions for repairs to shared equipment|a contribution box
rain repairs|builders|repaired leaking store roofs before the autumn rains|a patched roof tile
old measures|traders|preserved obsolete measures beside their replacements|an old measuring cup
timber salvage|woodworkers|salvaged sound timber rather than buy newly cut boards|a salvaged beam
spare handles|craft workers|kept spare handles for neighbours' broken tools|a handle rack
shared stories|elders|recorded ordinary household stories alongside official accounts|a household chronicle
mourning names|neighbours|read the names of absent households at a yearly gathering|a folded name sheet
gate hinges|gate workers|replaced worn hinges without closing the gate for a full day|a discarded hinge
watch cloak|needleworkers|mended a common cloak used by the gate's night watch|a patched watch cloak
harbour rope|harbour workers|kept a shared stock of rope for damaged moorings|a rope chest
net lessons|net makers|taught young workers to repair nets before taking harbour work|a sample net
woodland tools|woodworkers|marked borrowed woodland tools so they could be returned|a stamped tool handle
river baskets|households|replaced baskets lost during a river flood|a repaired carrying basket''',['key','actors','action','legacy'])
P['traditions']=rows('''tool return|return borrowed tools before the year's last gathering|tool lending
spare tile|bring a spare tile to communal roof repairs|roof repair
first stitch|show apprentices the first stitch in an old household cloth|apprentice teaching
empty stool|leave one stool for absent neighbours at a gathering|communal memory
shared cup|pass a plain cup before discussing shared expenses|meeting etiquette
winter cloth|air stored blankets before winter|household care
measure check|compare shop measures at a regular gathering|trade practice
work song|teach a work song during an apprentice's first week|craft teaching
lamp cleaning|clean shared lamp glass on a fixed evening|lamp care
name reading|read old household names before communal accounts|commemoration
hearth sweeping|sweep a neighbour's hearth when they cannot do it|mutual aid
loan marks|mark lent tools with a removable strip of cloth|tool lending
bench repair|mend a shared bench before holding a meeting|public care
spare thread|keep a skein of thread for other households' repairs|mutual aid
letter handover|read a letter's recipient aloud when handing it over|letter practice
old ledger|show apprentices a corrected page in an old ledger|clerical teaching
pot lending|leave a small marked pot available for borrowing|household lending
first loaf|share part of the first loaf from a repaired oven|oven care
stone brushing|brush dust from old memorial lettering before a gathering|commemoration
cloth airing|air the communal cloth without displaying household names|cloth care
key counting|count spare keys in front of two witnesses|keeper practice
weight wrapping|wrap comparison weights in plain cloth after use|trade care
quiet pause|pause before reading names of neighbours who have died|commemoration
handle testing|test repaired tool handles with the apprentice present|craft practice
repair tally|keep old repair tallies beside the tools they concern|record keeping
chest airing|open the shared storage chest for airing before filling it|store care
borrower thanks|thank the last borrower when a tool returns sound|lending etiquette
apprentice meal|invite a new apprentice to a modest shared meal|apprentice welcome
shelf cleaning|clean shared shelves before stored goods are counted|store care
old token|pass an old counting token when a meeting changes speaker|meeting etiquette
new binding|bind damaged records before adding another year's entries|clerical care
patch showing|show a household repair without concealing its patch|repair custom
spare peg|leave a spare wooden peg beside the shared tool rack|craft care
cart inspection|inspect a borrowed cart with its owner before returning it|lending practice
recipe copying|copy an old household recipe when a child learns to cook|household teaching
common ink|provide a little ink for neighbours recording family matters|mutual aid
absent names|include absent households when recording communal contributions|accounting practice
window cleaning|clean a neighbour's high window in exchange for another small task|mutual aid
first shaving|keep the first shaving from an apprentice's finished handle|craft memory
cloth tally|record cloth lengths before cutting them for shared repairs|trade practice
blanket turning|turn stored blankets during the cold season|household care
pot inspection|inspect a repaired pot before entrusting it with hot food|craft practice
spare buckle|keep usable buckles from discarded belts for repairs|salvage practice
quiet work|finish a small necessary repair before a commemorative meal|commemoration
story correction|invite another witness to correct a household story|local memory
seal witness|have a second person witness the sealing of a shared chest|keeper practice
gate oil|oil the gate hinges before changing the night watch|gate care
watch mending|mend shared watch clothing before winter|watch care
rope testing|test shared ropes before returning them to harbour storage|harbour care
net patch|keep a sample patch when teaching net repair|harbour teaching
wood mark|show new apprentices the marks on borrowed woodland tools|woodcraft teaching
river store|move shared vessels above the usual river storage level before winter|river care''',['key','practice','occasion'])
for key in ['memories','traditions']:
 for r in P[key]:
  if r['id'] in ['gate-hinges','watch-cloak','gate-oil','watch-mending']:r['requires']=['walls']
  if r['id'] in ['harbour-rope','net-lessons','rope-testing','net-patch']:r['requires']=['port']
  if r['id'] in ['woodland-tools','wood-mark']:r['requires']=['forest']
  if r['id'] in ['river-baskets','river-store']:r['requires']=['river']
# The declarative solver checks both tags and relational dependencies.
P['occupations']=rows('''toolmaker|craft|all-purpose tools
potter|craft|clay vessels
weaver|craft|plain cloth
mason|craft|ordinary stonework
baker|household|bread ovens
cobbler|craft|worn footwear
scribe|records|household accounts
carter|transport|loads and axles
needleworker|craft|household clothing
basket maker|craft|carrying baskets
brewer|household|small brewing vessels
herbal preparer|household|dried herb stores
rope maker|craft|cordage
lamp keeper|care|lamp cleaning
porter|transport|storage loads
repairer|craft|household repairs
book binder|records|worn bindings
metalworker|craft|iron fittings
stall keeper|trade|ordinary wares
tavern keeper|household|shared tables
local clerk|records|local registers
traveller|transport|borrowed equipment
religious attendant|religious|communal observances
possible recruit|craft|practical repairs
woodworker|craft|timber tools
charcoal burner|craft|fuel baskets
harbour worker|transport|mooring ropes
net maker|craft|working nets
gate keeper|care|hinges and bars
river carrier|transport|carrying vessels''',['key','category','work'])
for r in P['occupations']:
 if r['id'] in ['woodworker','charcoal-burner']:r['requires']=['forest']
 if r['id'] in ['harbour-worker','net-maker']:r['requires']=['port']
 if r['id']=='gate-keeper':r['requires']=['walls']
 if r['id']=='river-carrier':r['requires']=['river']
 if r['id']=='religious-attendant':r['requires']=['religion']
 r['provides']=['occupation:'+r['id'],r['category']]
def options(name,text):P[name]=[{'id':ident(s),'label':s,'requires':[]} for s in text.split('|')]
options('family','extended household|single-parent household|guardian household|two-parent household|adoptive household|grandparent household|sibling household|household of family friends|widowed guardian household|two connected households|family of itinerant workers|household of retired craft workers')
options('childhood','sharing a crowded workroom|caring for younger children|copying household accounts|mending ordinary possessions|delivering small parcels|helping prepare communal meals|watching experienced workers|sorting salvaged materials|learning borrowed tools|tending stored supplies|taking turns at household chores|listening to older neighbours')
options('training','a patient older apprentice|a demanding workshop keeper|a retired craft worker|a neighbour who taught evening lessons|a relative with failing eyesight|a record keeper who exchanged lessons for errands|a travelling repairer who stayed one season|an older sibling|a guardian who valued careful work|a worker known for correcting mistakes|a household friend|a former employer')
options('failure','miscounted a borrowed tool set|spoiled a first independent repair|lost a carefully copied account|returned a parcel to the wrong household|promised more work than could be finished|left stored materials unprotected from rain|failed to ask for help soon enough|mistook a worn measuring mark|forgot an agreed meeting|damaged a loaned vessel|kept quiet about a small mistake|trusted an incomplete inventory')
options('success','completed a difficult repair|returned a missing family possession|settled a small account dispute|finished a task others had abandoned|taught a younger worker patiently|saved usable material from disposal|kept a household supplied during repairs|corrected an old transcription|made a replacement part that lasted|shared tools without losing any|helped complete a communal task|found an economical way to reuse worn goods')
options('motivation','learn unfamiliar crafts|pay a modest family debt|return a borrowed possession|find a former mentor|carry a household letter|prove that a past failure need not define them|seek work beyond familiar workshops|collect practical repair methods|visit a relative who moved away|make a living without leaning on family|understand an old family account|earn enough to repair a family home|keep a promise to a departed friend|find the origin of an inherited tool|bring a younger sibling new opportunities|see how other places manage shared work')
options('concern','losing borrowed tools|becoming dependent on strangers|leaving household duties unfinished|forgetting names and obligations|repeating a costly mistake|being dismissed as unskilled|failing someone who lent help|returning without useful work|mistaking pride for competence|trusting an unreliable account|being unable to repay kindness|letting a friendship lapse')
options('contact','a former apprentice|a household neighbour|a retired employer|an older cousin|a sibling who stayed home|a keeper of local records|a repair customer|a travelling worker met during training|a friend from shared lessons|a person who once lent tools|a household guardian|a clerk who remembers an old mistake')
options('secret','kept an unfinished practice piece|hid a small unpaid debt|copied a private letter without permission|gave away a tool they did not own|misreported a damaged parcel|kept a token meant to be returned|concealed who paid for their training|left a task unfinished and blamed poor materials|failed to deliver a household message|secretly plans to change their trade|still keeps a rival’s discarded work|has not admitted a family disagreement')
options('habit','checks knots twice|counts tools before leaving|folds letters along existing creases|keeps small usable offcuts|cleans a cup before offering it|notes who lent an object|repairs worn bindings|pauses before making promises|records small expenses|turns a ring when thinking|sets tools in a fixed order|listens before giving an opinion')
options('value','repaying kindness|careful workmanship|keeping modest promises|honest records|sharing useful knowledge|respect for borrowed goods|patience with learners|remembering absent neighbours|repair before replacement|witnessed agreements|practical fairness|independence without ingratitude')
options('keepsake','a repaired wooden cup|a plain copper ring|a folded household letter|a short measuring cord|a worn tool handle|a stitched scrap of cloth|an old tally stick|a spare buckle|a blank account leaf|a smoothed stone from a workbench|a tiny box of spare pegs|a bent practice nail')
P['traits']=rows('''cautious|care|reckless,fearless
patient|care|impatient
reserved|speech|boastful
plain spoken|speech|evasive
curious|learning|incurious
methodical|work|careless
loyal|relationships|faithless
sceptical|judgement|credulous
stubborn|judgement|pliant
generous|relationships|miserly
private|speech|indiscreet
self critical|judgement|vain
reckless|care|cautious
impatient|care|patient
boastful|speech|reserved
fearless|care|cautious,cowardly
cowardly|care|fearless
practical|work|impractical''',['key','category','conflicts'])
for r in P['traits']:r['conflicts']=r['conflicts'].split(',')
P['items']=rows('''hand axe|tool|iron,steel|wood|cutting and splitting
pruning knife|tool|iron,steel|wood|trimming woody growth
awl|craft tool|iron,steel|wood|piercing leather
chisel|craft tool|iron,steel|wood|shaping workpieces
plane|craft tool|wood|iron|smoothing boards
small hammer|craft tool|iron,steel|wood|driving fittings
pliers|craft tool|iron,steel||gripping small fittings
shears|craft tool|iron,steel||cutting cloth
needle case|container|wood,bone|linen|keeping needles
spindle|craft tool|wood|linen|twisting thread
measuring rod|survey|wood|iron|comparing lengths
plumb weight|survey|bronze,iron|linen|checking vertical work
compass dividers|survey|bronze,iron||copying distances
balance scale|trade|bronze,iron|wood|comparing small weights
weight box|trade|wood|bronze|keeping comparison weights
seal stamp|seal|bronze,iron|wood|marking documents
key|key|iron,bronze||opening an ordinary lock
belt buckle|clothing|bronze,iron||fastening a belt
cloak|clothing|wool,linen||wearing in poor weather
hood|clothing|wool,linen||covering the head
work apron|clothing|linen,leather||protecting clothing
work gloves|clothing|leather,linen||protecting the hands
cloth cap|clothing|wool,linen||ordinary wear
shoulder bag|travel|linen,leather|wood|carrying small possessions
water flask|travel|leather,ceramic|linen|carrying water
travelling cup|vessel|wood,ceramic|linen|drinking away from home
cooking pot|household|iron,ceramic||cooking modest meals
ladle|household|wood,iron||serving food
small bowl|household|wood,ceramic||holding food
storage jar|container|ceramic|linen|storing household goods
wooden chest|container|wood|iron|keeping possessions
lidded box|container|wood|bronze|keeping small objects
carrying basket|container|wicker|linen|carrying modest loads
lamp|household|ceramic,bronze|linen|holding lamp oil
candlestick|household|iron,bronze||holding a candle
mirror|household|bronze|wood|ordinary grooming
comb|household|wood,bone||ordinary grooming
razor|tool|steel,iron|wood|shaving
plain ring|jewellery|bronze,silver||personal wear
brooch|jewellery|bronze,silver||fastening clothing
pendant|jewellery|wood,bronze|linen|personal commemoration
bead strand|jewellery|wood,bone|linen|personal wear
account book|document|paper|linen|recording ordinary accounts
letter folio|document|paper|leather|protecting letters
wax tablet|document|wood|wax|temporary notes
copying stylus|document|bronze,bone||writing on wax
bookmark|document|linen,leather||keeping a reading place
prayer board|religious|wood|linen|private observance
offering cup|religious|ceramic,bronze||communal offerings
votive plaque|religious|wood,bronze||commemoration
bell|ceremonial|bronze,iron||calling a gathering
plain banner|ceremonial|linen,wool|wood|marking a gathering
ceremonial staff|ceremonial|wood|bronze|leading an observance
small drum|ceremonial|wood|leather|keeping a gathering's rhythm
walking staff|travel|wood|iron|support while walking
rope coil|travel|linen||tying ordinary loads
tent cloth|travel|linen|leather|temporary shelter
bedroll|travel|wool|linen|sleeping away from home
whetstone|tool|stone||maintaining cutting edges
repair pouch|medical|linen,leather||keeping bandage cloth
bandage roll|medical|linen||wrapping an injury
herb jar|medical|ceramic|linen|keeping dried preparations
small mortar|medical|stone,ceramic|wood|grinding preparations
spear head|weapon|iron,steel|wood|a simple hunting implement
short blade|weapon|iron,steel|wood|an ordinary sidearm
buckler|armour|wood,iron|leather|a small protective shield
helmet|armour|iron,steel|leather|ordinary head protection
metal cup|vessel|bronze,iron||serving drink
bread tin|household|iron||baking bread
folding stool|travel|wood|leather|resting during work
survey chain|survey|iron,bronze||comparing repeated lengths
ceremonial key|ceremonial|bronze,iron||commemorating a former office''',['key','category','materials','secondary','use'])
for r in P['items']:
 r['materials']=r['materials'].split(',');r['secondary']=r['secondary'].split(',') if r['secondary'] else []
 if r['category']=='religious':r['requires']=['religion']
options('qualities','plain but sound|carefully finished|roughly finished|well balanced|made for easy repair|compactly made|deliberately unadorned|made with visible tool marks')
options('wear','polished by handling|scuffed along one edge|patched at a stress point|marked by an old repair|darkened with age|kept clean despite wear|scratched with an ownership mark|worn where it was often held|wrapped for careful storage|stained by ordinary work')
options('makers','a household craft worker|a small local workshop|an itinerant repairer|an experienced apprentice|a workshop kept by two relatives|a retired maker working at home|a maker known for plain practical work|a former employer’s workshop|a shared workroom|a craft worker who accepted salvaged material|a workshop that repaired its own older goods|a maker paid partly in materials')
options('marks','a row of shallow dots|a small crossed-line mark|an uneven maker’s initial|a repeated notch pattern|a faded inventory number|a narrow border of incised lines|a worn household sign|a carefully filed edge|a small stamped circle|a patched maker’s label|an old tally mark|a newer mark beside an older one')
options('item_events','passed to a younger household member|sold when its owner changed work|exchanged for a needed repair|given in payment for several days of work|kept when a workshop closed|returned after being lent for a season|bought from a retired worker|shared between two households|carried away by an apprentice|recovered from a mislabelled store|held in place of a small debt|given to someone who had repaired it')
options('repairs','a worn fastening was replaced|a loose joint was tightened|a damaged edge was dressed|a surface crack was secured|an older repair was cleaned and checked|a protective wrapping was renewed|a maker’s mark was recut beside the worn original|a storage cover was replaced')
options('rare_roles','a keeper of shared records|a retiring craft master|a household elder|a travelling surveyor|a custodian of comparison measures|a witness to communal agreements|a keeper of ceremonial goods|a former apprentice who became a maker|a collector of ordinary craft history|a person appointed to maintain shared equipment|a guardian of inherited household goods|a writer of local accounts')
options('reputations','remembered for careful workmanship|kept as evidence of an old agreement|valued because its repairs were documented|shown when teaching an old craft method|preserved after its workshop closed|associated with a modest public ceremony|used as a comparison piece by later makers|kept beside its original account|passed on with instructions for its care|remembered for an unusually patient repair|preserved because its owner refused a replacement|retained to explain a disputed maker’s mark')
options('item_secrets','one ownership mark was added by a later keeper|the oldest fastening is a later replacement|a claimed single maker actually shared the work|an early repair account omits a failed first attempt|the object was exchanged rather than freely given|a previous keeper concealed a small debt|the older maker’s mark was copied from an account|the public chain of ownership leaves out one borrower|a supposed original surface was refinished|an inherited object was briefly sold and bought back|a ceremonial use began much later than its creation|a family story mistakes a custodian for the maker')
options('contracts','copy an exposed inscription|return a borrowed comparison piece|check a damaged inventory|identify a displaced maker’s mark|record surviving worked stones|deliver a sealed repair account|retrieve an openly stored tool chest|verify the condition of an old doorway|compare a surviving plan with the visible building|recover a missing household document|inspect a reported repair|ask a former keeper about an ownership entry|find a second witness to an account|record marks before a stone is reused|carry a replacement binding|locate the owner of a marked vessel')
options('complications','two accounts give different ownership dates|one witness remembers the event differently|the surviving copy is incomplete|a repair has obscured an older mark|the requested object has been moved to another store|the issuer lacks a complete inventory|a second household also claims the object|the easiest route through the building is blocked')
options('group_types','repair fellowship|record circle|mutual-aid group|workshop association|burial society|teaching circle|measure keepers|household cooperative|travellers’ correspondence circle|salvage association|ceremonial custodians|letter carriers’ circle')
options('group_purposes','share tools without losing them|preserve household records|teach practical skills to new workers|maintain shared equipment|keep contributions fairly recorded|repair objects that would otherwise be discarded|preserve accounts of ordinary work|settle disagreements over borrowed goods|care for communal cloth and vessels|record who has taken responsibility for repairs|help absent households maintain their possessions|compare trade measures openly')
options('symbols','a crossed pair of plain lines|a ring around a small square|three shallow notches|an open hand beside a peg|a stitched circle|a single dark stripe|a small hanging bell|a plain measuring rod')
# Compatibility refinements found by reading sequential QA, not by cherry picking.
for r in P['conditions']:
 if r['id']=='roof-missing':r['label']='a missing section of roof'
for r in P['items']:
 if r['id']=='work-gloves':r['key']='pair of work gloves'
 if r['id']=='shears':r['key']='pair of shears'
 if r['id']=='pliers':r['key']='pair of pliers'
 if r['id']=='compass-dividers':r['key']='pair of compass dividers'
for r in P['training']:
 if r['id'] in ['a-record-keeper-who-exchanged-lessons-for-errands']:r['requires']=['records']
 if r['id'] in ['a-retired-craft-worker','a-travelling-repairer-who-stayed-one-season']:r['requires']=['craft']
for r in P['traits']:
 if r['id']=='reckless':r['conflicts'].append('cowardly')
 if r['id']=='cowardly':r['conflicts'].append('reckless')
 if r['id']=='private':r['conflicts'].append('boastful')
 if r['id']=='boastful':r['conflicts'].append('private')
for r in P['qualities']:
 if r['id']=='well-balanced':r['requires']=[{'any':['item:tool','item:craft-tool','item:weapon','item:survey','item:ceremonial']}]
for r in P['marks']:
 if r['id'] not in ['a-patched-maker-s-label','a-faded-inventory-number','a-worn-household-sign','an-uneven-maker-s-initial','a-small-stamped-circle']:
  r['requires']=[{'not':'flexible'}]
for r in P['group_types']:
 if r['id']=='measure-keepers':r['label']='circle of measure keepers'
 if r['id']=='ceremonial-custodians':r['label']='association of ceremonial custodians'
for r in P['events']:
 r['damage_component']=None;r['repair_component']=None
 if r['id'] in ['fire-damaged-roof','storm-broke-roof','timber-salvaged','tiles-salvaged']:r['damage_component']='roof'
 if r['id'] in ['wall-cracked','stone-removed']:r['damage_component']='walls'
 if r['id'] in ['subsidence-occurred','paving-lifted']:r['damage_component']='floor'
 if r['id'] in ['stair-collapsed','door-sold','iron-stripped']:r['damage_component']='access'
 if r['id'] in ['beam-failed']:r['damage_component']='roof'
 if r['id'] in ['roof-renewed','roof-tarred']:r['repair_component']='roof'
 if r['id'] in ['wall-braced','lintel-replaced']:r['repair_component']='walls'
 if r['id'] in ['floor-relaid']:r['repair_component']='floor'
 if r['id'] in ['stair-repaired','door-replaced','threshold-cleared']:r['repair_component']='access'
for r in P['occupations']:
 if r['id']=='possible-recruit':r['key']='repair apprentice'
# Matching purposes retain the distinction between group type and civic function.
group_purposes={
'repair-fellowship':['share-tools-without-losing-them','repair-objects-that-would-otherwise-be-discarded','maintain-shared-equipment'],
'record-circle':['preserve-household-records','preserve-accounts-of-ordinary-work','keep-contributions-fairly-recorded'],
'mutual-aid-group':['share-tools-without-losing-them','help-absent-households-maintain-their-possessions','keep-contributions-fairly-recorded'],
'workshop-association':['teach-practical-skills-to-new-workers','compare-trade-measures-openly','share-tools-without-losing-them'],
'burial-society':['preserve-household-records','care-for-communal-cloth-and-vessels','keep-contributions-fairly-recorded'],
 'teaching-circle':['teach-practical-skills-to-new-workers','preserve-accounts-of-ordinary-work'],
 'measure-keepers':['compare-trade-measures-openly','settle-disagreements-over-borrowed-goods'],
 'household-cooperative':['help-absent-households-maintain-their-possessions','share-tools-without-losing-them'],
 'travellers-correspondence-circle':['preserve-household-records','help-absent-households-maintain-their-possessions'],
 'salvage-association':['repair-objects-that-would-otherwise-be-discarded','share-tools-without-losing-them'],
 'ceremonial-custodians':['care-for-communal-cloth-and-vessels','keep-contributions-fairly-recorded'],
 'letter-carriers-circle':['preserve-household-records','help-absent-households-maintain-their-possessions']}
for r in P['group_types']:r['allowed_purposes']=group_purposes[r['id']]
for r in P['contracts']:
 r['target_kind']='public-document' if any(word in r['id'] for word in ['account','document','binding','inventory','plan']) else 'public-object'
 if any(word in r['id'] for word in ['inscription','stones','doorway','building']):r['target_kind']='visible-building-feature'
 if 'witness' in r['id'] or 'keeper' in r['id']:r['target_kind']='known-person'
P['memories']+=rows("""adjacent letter exchange|letter carriers|kept copies of letters exchanged with households in neighbouring settlements|a letter-copy bundle
neighbour repair agreement|craft workers|recorded which borrowed tools should be returned to neighbouring settlements|a tool-return list
capital account copying|clerks|copied communal accounts before older volumes were retired|a preserved account volume
large store inventory|keepers|reorganised a crowded communal store without discarding older inventories|a shelf inventory
village shared bench|neighbours|made a small bench for household meetings instead of a separate meeting hall|a plain wooden bench
woodcraft teaching chest|woodworkers|kept sample joints to teach repair rather than decoration|a box of practice joints""",['key','actors','action','legacy'])
P['traditions']+=rows("""neighbour parcel check|check a parcel's recipient before passing it to carriers visiting neighbouring settlements|letter exchange
neighbour tool marks|write the lending household's settlement beside borrowed tool marks|tool return
capital old account|display a corrected old account before recording communal contributions|clerical memory
large store tally|compare shelf tallies with a second keeper before moving shared stores|store care
village borrowed bench|lend a meeting bench to a household gathering before storing it away|shared space
woodcraft sample|keep a sound sample joint beside a newly repaired wooden tool|craft teaching""",['key','practice','occasion'])
for name in ['memories','traditions']:
 for r in P[name]:
  if r['id'].startswith('neighbour') or r['id']=='adjacent-letter-exchange':r['requires']=['adjacent-town']
  if r['id'].startswith('capital'):r['requires']=['capital']
  if r['id'].startswith('large-store'):r['requires']=['larger-relative']
  if r['id'].startswith('village'):r['requires']=['settlement:village']
  if r['id'].startswith('woodcraft'):r['requires']=['forest']
for r in P['family']:
 if r['id']=='two-connected-households':r['label']='pair of connected households'
# Lifecycle and physical damage are separate. Recording a memorial never
# magically restores an abandoned or damaged building.
for r in P['events']:
 r['transition']='preserve'
 if r['id']=='foundation-laid':r['transition']='standing'
 if r['category']=='abandonment' or (r['category']=='social' and r['state']=='abandoned'):r['transition']='abandoned'
 if r['category']=='reuse':r['transition']='reused'
P['site_secrets']=rows("""uncredited repair|an uncredited apprentice completed a repair assigned to the keeper
altered inventory|a later keeper altered one inventory entry to conceal a missing tool
borrowed key|a supposedly lost key was lent to another household
failed first repair|the surviving repair account leaves out a failed first attempt
misdated lintel|the date on a replacement lintel was copied from the older stone
shared maker|work credited to one maker was completed by two workshops
returned possession|a keeper returned a disputed possession without recording the exchange
concealed lease|an informal lease continued after the formal account ended
copied plan|the surviving plan was copied from a later survey rather than the original building
unrecorded cupboard|a shallow wall cupboard was omitted from an inventory
hidden work sample|an apprentice hid an unfinished practice piece rather than discard it
changed purpose|a keeper changed the use of a side room without changing its label
missing witness|one witness asked to have their name left out of the record
unpaid materials|some building materials were supplied against a debt never acknowledged
reused inscription|an inscribed block was reused with its older face turned inward
household contribution|an ordinary household paid for a repair publicly credited elsewhere
borrowed measure|a measuring piece recorded as owned was borrowed for the work
incorrect owner|an account mistakes a temporary custodian for the owner
surrendered tools|a departing worker surrendered tools that another keeper later claimed
omitted accident|a repair entry conceals a small avoidable accident""",['key','detail'])
Path('research/game78/packs/trhgd-expanded-v1.json').write_text(json.dumps(P,ensure_ascii=False,indent=2)+'\n')
print({k:len(v) for k,v in P.items() if isinstance(v,list)})
