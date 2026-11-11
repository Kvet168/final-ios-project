// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Khmer Central Khmer (`km`).
class AppLocalizationsKm extends AppLocalizations {
  AppLocalizationsKm([String locale = 'km']) : super(locale);

  @override
  String get appName => 'WAYFARER';

  @override
  String get tagline => 'រៀបចំដំណើរកម្សាន្ត យ៉ាងងាយស្រួល';

  @override
  String get splashLoading => 'កំពុងបើក WAYFARER';

  @override
  String get splashReady => 'កំពុងរៀបចំ...';

  @override
  String get splashSlow => 'កំពុងភ្ជាប់ទៅម៉ាស៊ីនមេ សូមរង់ចាំបន្តិច';

  @override
  String get tabDiscover => 'ស្វែងរក';

  @override
  String get tabStays => 'ស្នាក់នៅ';

  @override
  String get tabTrips => 'ដំណើរ';

  @override
  String get tabMe => 'គណនី';

  @override
  String get askAiGuide => 'សួរមគ្គុទ្ទេសក៍ AI';

  @override
  String get administration => 'ការគ្រប់គ្រង';

  @override
  String get partnerPortal => 'ផ្ទាំងដៃគូ';

  @override
  String get pageNotFound => 'រកមិនឃើញទំព័រនេះទេ';

  @override
  String get backToDiscover => 'ត្រឡប់ទៅទំព័រស្វែងរក';

  @override
  String get welcome1Eyebrow => 'ស្វែងរក';

  @override
  String get welcome1Title => 'កម្ពុជា';

  @override
  String get welcome1Italic => 'ឱ្យកាន់តែជិត';

  @override
  String get welcome1Body =>
      'គោលដៅដប់ពីរ ទីកន្លែង និងកន្លែងស្នាក់នៅរាប់រយ ចាប់ពីអង្គរពេលថ្ងៃរះ រហូតដល់កោះរ៉ុង។';

  @override
  String get welcome2Eyebrow => 'រៀបចំផែនការ';

  @override
  String get welcome2Title => 'ដំណើរដែលរៀបចំ';

  @override
  String get welcome2Italic => 'ដោយស្វ័យប្រវត្តិ';

  @override
  String get welcome2Body =>
      'ប្រាប់កម្មវិធីរៀបចំ AI ពីទីកន្លែង រយៈពេល និងចំណូលចិត្តរបស់អ្នក។ វានឹងរៀបចំកម្មវិធីប្រចាំថ្ងៃ ដោយផ្អែកលើទីកន្លែងពិតៗ។';

  @override
  String get welcome3Eyebrow => 'ចេញដំណើរ';

  @override
  String get welcome3Title => 'កក់ភ្លាម';

  @override
  String get welcome3Italic => 'យកតាមខ្លួន';

  @override
  String get welcome3Body =>
      'កក់បន្ទប់ជាមួយលក្ខខណ្ឌច្បាស់លាស់ រក្សាសំបុត្រនៅក្នុងទូរស័ព្ទ ហើយសួរមគ្គុទ្ទេសក៍បានគ្រប់ពេលក្នុងដំណើរ។';

  @override
  String get skip => 'រំលង';

  @override
  String get next => 'បន្ទាប់';

  @override
  String get startExploring => 'ចាប់ផ្តើមស្វែងរក';

  @override
  String fromPerDay(String price) {
    return 'ចាប់ពី $price / ថ្ងៃ';
  }

  @override
  String priceForNights(String price, int nights) {
    return '$price សម្រាប់ $nights យប់';
  }

  @override
  String get perNight => '/ យប់';

  @override
  String kmAway(String distance) {
    return 'ចម្ងាយ $distance គ.ម';
  }

  @override
  String photoFor(String name) {
    return 'រូបភាព $name';
  }

  @override
  String get perkFreeCancellation => 'លុបចោលឥតគិតថ្លៃ';

  @override
  String get perkBreakfast => 'អាហារពេលព្រឹក';

  @override
  String get perkFamily => 'គ្រួសារ';

  @override
  String get typeHotel => 'សណ្ឋាគារ';

  @override
  String get typeGuesthouse => 'ផ្ទះសំណាក់';

  @override
  String get typeResort => 'រីសត';

  @override
  String get typeHostel => 'ហូស្ទែល';

  @override
  String get typeBoutique => 'សណ្ឋាគារប៊ូទិក';

  @override
  String get typeVilla => 'វីឡា';

  @override
  String get typeApartment => 'អាផាតមិន';

  @override
  String get typeBungalow => 'បឹងហ្គាឡូ';

  @override
  String get catTemple => 'ប្រាសាទ និងវត្ត';

  @override
  String get catMuseum => 'សារមន្ទីរ';

  @override
  String get catMarket => 'ផ្សារ';

  @override
  String get catNature => 'ធម្មជាតិ';

  @override
  String get catBeach => 'ឆ្នេរ';

  @override
  String get catFood => 'ម្ហូបអាហារ';

  @override
  String get catCafe => 'ហាងកាហ្វេ';

  @override
  String get catCulture => 'វប្បធម៌';

  @override
  String get catTour => 'ដំណើរទេសចរណ៍';

  @override
  String get catOutdoor => 'សកម្មភាពក្រៅផ្ទះ';

  @override
  String get catFamily => 'គ្រួសារ';

  @override
  String get catLandmark => 'កន្លែងល្បី';

  @override
  String get catHistory => 'ប្រវត្តិសាស្ត្រ';

  @override
  String get catRestaurant => 'ភោជនីយដ្ឋាន';

  @override
  String get catActivity => 'សកម្មភាព';

  @override
  String get catAttraction => 'កន្លែងទេសចរណ៍';

  @override
  String get tagTemples => 'ប្រាសាទ';

  @override
  String get tagRelaxed => 'សម្រាកលំហែ';

  @override
  String get tagCity => 'ទីក្រុង';

  @override
  String get tagIslands => 'កោះ';

  @override
  String get free => 'ឥតគិតថ្លៃ';

  @override
  String minutesShort(int minutes) {
    return '$minutes នាទី';
  }

  @override
  String get saveToWishlist => 'រក្សាទុកក្នុងបញ្ជីចូលចិត្ត';

  @override
  String get removeFromWishlist => 'ដកចេញពីបញ្ជីចូលចិត្ត';

  @override
  String get loading => 'កំពុងផ្ទុក';

  @override
  String get genericError => 'មានបញ្ហាបន្តិចបន្តួច។ សូមព្យាយាមម្តងទៀត។';

  @override
  String get noConnection => 'គ្មានអ៊ីនធឺណិត';

  @override
  String get didntLoad => 'មិនអាចផ្ទុកបានទេ';

  @override
  String get tryAgain => 'ព្យាយាមម្តងទៀត';

  @override
  String get demoListing => 'ទិន្នន័យគំរូ';

  @override
  String get demoTooltip =>
      'ទិន្នន័យគំរូសម្រាប់ការសិក្សា មិនមែនជាការផ្តល់ជូនពិតប្រាកដទេ';

  @override
  String get ratingNew => 'ថ្មី';

  @override
  String starProperty(int stars) {
    return 'កន្លែងស្នាក់នៅ $stars ផ្កាយ';
  }

  @override
  String stayCardSemantics(String name, int stars, String type) {
    return '$name, $type $stars ផ្កាយ';
  }

  @override
  String get statusConfirmed => 'បានបញ្ជាក់';

  @override
  String get statusAwaitingPayment => 'រង់ចាំការទូទាត់';

  @override
  String get statusCheckedIn => 'បានចូលស្នាក់នៅ';

  @override
  String get statusCompleted => 'បានបញ្ចប់';

  @override
  String get statusCancelled => 'បានលុបចោល';

  @override
  String get statusExpired => 'ផុតកំណត់';

  @override
  String get statusRefundPending => 'កំពុងរង់ចាំការសងប្រាក់';

  @override
  String get statusRefunded => 'បានសងប្រាក់វិញ';

  @override
  String get statusDraft => 'សេចក្តីព្រាង';

  @override
  String get statusPaidSimulated => 'បានបង់ (សាកល្បង)';

  @override
  String get statusPaymentFailed => 'ការទូទាត់មិនបានសម្រេច';

  @override
  String get statusPaymentPending => 'កំពុងរង់ចាំការទូទាត់';

  @override
  String get confirm => 'បញ្ជាក់';

  @override
  String get keep => 'ទុកដដែល';

  @override
  String get cancel => 'បោះបង់';

  @override
  String get save => 'រក្សាទុក';

  @override
  String get close => 'បិទ';

  @override
  String get done => 'រួចរាល់';

  @override
  String get seeAll => 'មើលទាំងអស់';

  @override
  String get all => 'ទាំងអស់';

  @override
  String get greetingNight => 'អ្នកដើរលេងពេលយប់';

  @override
  String get greetingMorning => 'អរុណសួស្តី';

  @override
  String get greetingAfternoon => 'ទិវាសួស្តី';

  @override
  String get greetingEvening => 'សាយណ្ហសួស្តី';

  @override
  String greetingWithName(String greeting, String name) {
    return '$greeting $name';
  }

  @override
  String get signIn => 'ចូលគណនី';

  @override
  String get heroLine1 => 'តើអ្នកនឹង';

  @override
  String get heroLine2 => 'ទៅណាបន្ទាប់?';

  @override
  String get searchStays => 'ស្វែងរកកន្លែងស្នាក់នៅ';

  @override
  String get findYourStay => 'ស្វែងរកកន្លែងស្នាក់នៅ';

  @override
  String get anywhereAnyDates =>
      'គ្រប់ទីកន្លែង · គ្រប់កាលបរិច្ឆេទ · ចំនួនភ្ញៀវណាក៏បាន';

  @override
  String get quickAiPlanner => 'រៀបចំដំណើរ AI';

  @override
  String get quickDayByDay => 'តាមថ្ងៃនីមួយៗ';

  @override
  String get quickAskGuide => 'សួរមគ្គុទ្ទេសក៍';

  @override
  String get quickInstantAnswers => 'ចម្លើយភ្លាមៗ';

  @override
  String get quickMap => 'ផែនទី';

  @override
  String get quickNearYou => 'ក្បែរអ្នក';

  @override
  String get recentlyViewed => 'បានមើលថ្មីៗ';

  @override
  String get pickUpWhereLeft => 'បន្តពីកន្លែងដែលអ្នកបានមើល';

  @override
  String get featured => 'ពិសេស';

  @override
  String get destinationsWeLove => 'គោលដៅដែលយើងចូលចិត្ត';

  @override
  String get explore => 'ស្វែងយល់';

  @override
  String get browseByMood => 'ជ្រើសតាមចំណូលចិត្ត';

  @override
  String get topRated => 'ពិន្ទុខ្ពស់បំផុត';

  @override
  String get staysWorthTrip => 'កន្លែងស្នាក់នៅដែលគួរឱ្យទៅ';

  @override
  String get browse => 'មើល';

  @override
  String get itineraries => 'កម្មវិធីដំណើរ';

  @override
  String get readyMadeJourneys => 'ដំណើររៀបចំរួចជាស្រេច';

  @override
  String get planYours => 'រៀបចំផ្ទាល់ខ្លួន';

  @override
  String get thisWeek => 'សប្តាហ៍នេះ';

  @override
  String get trendingNow => 'ពេញនិយមឥឡូវនេះ';

  @override
  String get statDestinations => 'គោលដៅ';

  @override
  String get statPlaces => 'ទីកន្លែង';

  @override
  String get statStays => 'កន្លែងស្នាក់នៅ';

  @override
  String daysCount(int days) {
    return '$days ថ្ងៃ';
  }

  @override
  String estimatedTotal(String amount) {
    return 'ប្រហែល $amount';
  }

  @override
  String get destinationsTitle => 'គោលដៅ';

  @override
  String get sort => 'តម្រៀប';

  @override
  String get sortPopular => 'ពេញនិយមបំផុត';

  @override
  String get sortNameAZ => 'ឈ្មោះ A–Z';

  @override
  String get sortBudgetLow => 'ថវិកា៖ ពីទាបទៅខ្ពស់';

  @override
  String get sortBudgetHigh => 'ថវិកា៖ ពីខ្ពស់ទៅទាប';

  @override
  String get searchDestinations => 'ស្វែងរកគោលដៅ';

  @override
  String get noDestinationsMatch => 'រកមិនឃើញគោលដៅដែលត្រូវគ្នា';

  @override
  String get noDestinationsHint => 'សូមសាកល្បងដកតម្រងចេញ ឬស្វែងរកឈ្មោះផ្សេង។';

  @override
  String get clearFilters => 'សម្អាតតម្រង';

  @override
  String destinationsCount(int count) {
    return 'គោលដៅចំនួន $count';
  }

  @override
  String photoOf(String name) {
    return 'រូបភាព $name';
  }

  @override
  String photoIndex(int index, int total) {
    return '$index / $total';
  }

  @override
  String budgetPerDay(String amount) {
    return '~$amount / ថ្ងៃ';
  }

  @override
  String get showLess => 'បង្ហាញតិច';

  @override
  String get readMore => 'អានបន្ថែម';

  @override
  String get thingsToDo => 'កន្លែងលេង និងកន្លែងញ៉ាំ';

  @override
  String get kindAttractions => 'កន្លែងទេសចរណ៍';

  @override
  String get kindActivities => 'សកម្មភាព';

  @override
  String get kindRestaurants => 'ភោជនីយដ្ឋាន';

  @override
  String get nothingListed => 'មិនទាន់មានទិន្នន័យនៅឡើយ';

  @override
  String get nothingListedHint =>
      'មិនទាន់មានទីកន្លែងប្រភេទនេះ សម្រាប់គោលដៅនេះទេ។';

  @override
  String showAllCount(int count) {
    return 'បង្ហាញទាំង $count';
  }

  @override
  String get staysEyebrow => 'កន្លែងស្នាក់នៅ';

  @override
  String get whereToStay => 'ស្នាក់នៅទីណា';

  @override
  String get keepGoing => 'បន្តដំណើរ';

  @override
  String get nearbyAndRelated => 'កន្លែងក្បែរៗ និងពាក់ព័ន្ធ';

  @override
  String kmShort(String distance) {
    return '$distance គ.ម';
  }

  @override
  String get readAndAsk => 'អាន និងសួរ';

  @override
  String get travelGuides => 'ការណែនាំការធ្វើដំណើរ';

  @override
  String get findStays => 'រកកន្លែងស្នាក់នៅ';

  @override
  String get planTrip => 'រៀបចំដំណើរ';

  @override
  String get indicative => '(ប៉ាន់ស្មាន)';

  @override
  String get familyFriendly => 'សមរម្យសម្រាប់គ្រួសារ';

  @override
  String get directions => 'ផ្លូវទៅ';

  @override
  String get destination => 'គោលដៅ';

  @override
  String get placesTitle => 'ទីកន្លែង';

  @override
  String get searchPlacesHint => 'ស្វែងរកទីកន្លែង ឧ. អង្គរ ផ្សារ សារមន្ទីរ';

  @override
  String placesCount(int count) {
    return 'ទីកន្លែងចំនួន $count';
  }

  @override
  String get noPlacesMatch => 'រកមិនឃើញទីកន្លែងដែលត្រូវគ្នា';

  @override
  String get noPlacesHint => 'សូមសាកល្បងប្រភេទ ឬពាក្យស្វែងរកផ្សេង។';

  @override
  String get locationOff => 'សេវាទីតាំងត្រូវបានបិទនៅលើឧបករណ៍នេះ។';

  @override
  String get locationDeclined =>
      'អ្នកមិនបានអនុញ្ញាតឱ្យប្រើទីតាំងទេ។ អ្នកនៅតែអាចមើលផែនទី និងស្វែងរកតាមគោលដៅបាន។';

  @override
  String get locationBlocked =>
      'ការប្រើទីតាំងត្រូវបានរារាំង។ សូមបើកវានៅក្នុងការកំណត់ឧបករណ៍ ដើម្បីប្រើមុខងារនេះ។';

  @override
  String locationFailed(String reason) {
    return 'មិនអាចរកទីតាំងរបស់អ្នកបានទេ ($reason)។';
  }

  @override
  String get locationTimeout => 'អស់ពេល ឬមិនគាំទ្រ';

  @override
  String perNightKmAway(String price, String distance) {
    return '$price / យប់ · ចម្ងាយ $distance គ.ម';
  }

  @override
  String get youAreHere => 'អ្នកនៅទីនេះ';

  @override
  String get nearMe => 'ក្បែរខ្ញុំ';

  @override
  String get staysNearYou => 'កន្លែងស្នាក់នៅក្បែរអ្នក';

  @override
  String get noStaysNearby =>
      'គ្មានកន្លែងស្នាក់នៅក្នុងចម្ងាយ 60 គ.ម ទេ។ ទិន្នន័យរបស់យើងគ្របដណ្តប់តែគោលដៅមួយចំនួន សូមជ្រើសរើសគោលដៅណាមួយជំនួសវិញ។';

  @override
  String get noLocations => 'គ្មានទីតាំងសម្រាប់បង្ហាញ';

  @override
  String get directionsInMaps => 'បើកផ្លូវក្នុងកម្មវិធីផែនទី';

  @override
  String get showResults => 'បង្ហាញលទ្ធផល';

  @override
  String get anywhere => 'គ្រប់ទីកន្លែង';

  @override
  String get anyDates => 'គ្រប់កាលបរិច្ឆេទ';

  @override
  String guestsCount(int count) {
    return 'ភ្ញៀវ $count នាក់';
  }

  @override
  String roomsCount(int count) {
    return '$count បន្ទប់';
  }

  @override
  String nightsCount(int count) {
    return '$count យប់';
  }

  @override
  String adultsCount(int count) {
    return 'មនុស្សពេញវ័យ $count នាក់';
  }

  @override
  String childrenCount(int count) {
    return 'កុមារ $count នាក់';
  }

  @override
  String get staysEyebrowCaps => 'កន្លែងស្នាក់នៅ';

  @override
  String get findPlaceToRest => 'ស្វែងរកកន្លែង\nសម្រាក';

  @override
  String get filters => 'តម្រង';

  @override
  String filtersActive(int count) {
    return 'តម្រង · $count';
  }

  @override
  String get sortRecommended => 'ណែនាំ';

  @override
  String get sortPriceLow => 'តម្លៃ៖ ពីទាបទៅខ្ពស់';

  @override
  String get sortPriceHigh => 'តម្លៃ៖ ពីខ្ពស់ទៅទាប';

  @override
  String get sortGuestRating => 'ពិន្ទុពីភ្ញៀវ';

  @override
  String get sortDistance => 'ចម្ងាយ';

  @override
  String get sortPriceUp => 'តម្លៃ ↑';

  @override
  String get sortPriceDown => 'តម្លៃ ↓';

  @override
  String get sortNearest => 'ជិតបំផុត';

  @override
  String get listView => 'បង្ហាញជាបញ្ជី';

  @override
  String get mapView => 'បង្ហាញលើផែនទី';

  @override
  String get searching => 'កំពុងស្វែងរក…';

  @override
  String staysCount(int count) {
    return 'កន្លែងស្នាក់នៅ $count';
  }

  @override
  String totalsShownForNights(int count) {
    return '$count យប់ បង្ហាញតម្លៃសរុប';
  }

  @override
  String get addDatesForAvailability =>
      'បញ្ចូលកាលបរិច្ឆេទ ដើម្បីមើលបន្ទប់ទំនេរ';

  @override
  String get noStaysMatch => 'រកមិនឃើញកន្លែងស្នាក់នៅដែលត្រូវគ្នា';

  @override
  String get noStaysDatesHint =>
      'ប្រហែលជាគ្មានបន្ទប់ទំនេរសម្រាប់កាលបរិច្ឆេទ និងចំនួនភ្ញៀវនេះទេ។ សូមសាកល្បងកាលបរិច្ឆេទផ្សេង ដកតម្រងខ្លះ ឬជ្រើសគោលដៅផ្សេង។';

  @override
  String get noStaysHint => 'សូមពង្រីកចន្លោះតម្លៃ ឬដកតម្រងណាមួយចេញ។';

  @override
  String get clearAll => 'សម្អាតទាំងអស់';

  @override
  String pricePerNightRange(String min, String max) {
    return 'តម្លៃក្នុងមួយយប់ · $min – $max';
  }

  @override
  String get starRating => 'ចំនួនផ្កាយ';

  @override
  String get guestRating => 'ពិន្ទុពីភ្ញៀវ';

  @override
  String get propertyType => 'ប្រភេទកន្លែងស្នាក់នៅ';

  @override
  String get popular => 'ពេញនិយម';

  @override
  String get breakfastAvailable => 'មានអាហារពេលព្រឹក';

  @override
  String get amenities => 'សេវាកម្ម និងបរិក្ខារ';

  @override
  String get realAvailability =>
      'បន្ទប់ទំនេរពិតប្រាកដ និងតម្លៃសរុបសម្រាប់កាលបរិច្ឆេទរបស់អ្នក។';

  @override
  String get selectCheckInOut => 'ជ្រើសថ្ងៃចូល និងថ្ងៃចេញ';

  @override
  String fewer(String label) {
    return 'បន្ថយ $label';
  }

  @override
  String more(String label) {
    return 'បន្ថែម $label';
  }

  @override
  String get adults => 'មនុស្សពេញវ័យ';

  @override
  String get adultsAge => 'អាយុ 13 ឆ្នាំឡើងទៅ';

  @override
  String get children => 'កុមារ';

  @override
  String get childrenAge => 'អាយុ 0 ដល់ 12 ឆ្នាំ';

  @override
  String get rooms => 'បន្ទប់';

  @override
  String get apply => 'អនុវត្ត';

  @override
  String get checkoutAfterCheckin => 'ថ្ងៃចេញត្រូវតែក្រោយថ្ងៃចូល';

  @override
  String get addDates => 'បញ្ចូលកាលបរិច្ឆេទ';

  @override
  String get whereTo => 'ទៅណា?';

  @override
  String get whereToHint => 'ទីក្រុង គោលដៅ ឬសណ្ឋាគារ';

  @override
  String get dates => 'កាលបរិច្ឆេទ';

  @override
  String get guests => 'ភ្ញៀវ';

  @override
  String fieldValue(String label, String value) {
    return '$label៖ $value';
  }

  @override
  String photoNofM(int index, int total, String name) {
    return 'រូបភាពទី $index ក្នុងចំណោម $total នៃ $name';
  }

  @override
  String get whatThisPlaceOffers => 'អ្វីដែលកន្លែងនេះផ្តល់ជូន';

  @override
  String get goodToKnow => 'ព័ត៌មានគួរដឹង';

  @override
  String get cancellation => 'ការលុបចោល';

  @override
  String get checkIn => 'ចូលស្នាក់នៅ';

  @override
  String get checkOut => 'ចាកចេញ';

  @override
  String fromTime(String time) {
    return 'ចាប់ពីម៉ោង $time';
  }

  @override
  String byTime(String time) {
    return 'មុនម៉ោង $time';
  }

  @override
  String get taxesAndFees => 'ពន្ធ និងថ្លៃសេវា';

  @override
  String taxesAndFeesBody(String tax, String fee) {
    return 'ពន្ធ $tax% និងថ្លៃសេវា $fee% ត្រូវបានបូកបន្ថែមលើតម្លៃបន្ទប់ ហើយបង្ហាញជូនមុនពេលអ្នកបង់ប្រាក់។';
  }

  @override
  String get location => 'ទីតាំង';

  @override
  String get chooseYourRoom => 'ជ្រើសរើសបន្ទប់';

  @override
  String get similarStays => 'កន្លែងស្នាក់នៅស្រដៀងគ្នានៅក្បែរ';

  @override
  String get fromCaps => 'ចាប់ពី';

  @override
  String get chooseARoom => 'ជ្រើសរើសបន្ទប់';

  @override
  String get chooseYourDates => 'ជ្រើសរើសកាលបរិច្ឆេទ';

  @override
  String nightsTapToChange(int count) {
    return '$count យប់ · ចុចដើម្បីប្តូរ';
  }

  @override
  String get tapToSelect => 'ចុចដើម្បីជ្រើសរើស';

  @override
  String get removeRoom => 'ដកបន្ទប់មួយ';

  @override
  String get addRoom => 'បន្ថែមបន្ទប់មួយ';

  @override
  String get selectDates => 'ជ្រើសកាលបរិច្ឆេទ';

  @override
  String get tooSmallForParty => 'តូចពេកសម្រាប់ក្រុមរបស់អ្នក';

  @override
  String get notAvailable => 'មិនទំនេរ';

  @override
  String get reserve => 'កក់';

  @override
  String get basePerNight => 'តម្លៃគោល / យប់';

  @override
  String upToAdults(int count) {
    return 'រហូតដល់មនុស្សពេញវ័យ $count នាក់';
  }

  @override
  String plusChildren(int count) {
    return ' + កុមារ $count នាក់';
  }

  @override
  String get breakfastIncluded => 'រួមបញ្ចូលអាហារពេលព្រឹក';

  @override
  String avgTimesNights(String price, int count) {
    return 'ជាមធ្យម $price × $count យប់';
  }

  @override
  String timesRooms(int count) {
    return ' × $count បន្ទប់';
  }

  @override
  String taxesPercent(String percent) {
    return 'ពន្ធ ($percent%)';
  }

  @override
  String serviceFeePercent(String percent) {
    return 'ថ្លៃសេវា ($percent%)';
  }

  @override
  String get total => 'សរុប';

  @override
  String get guestReviews => 'ការវាយតម្លៃពីភ្ញៀវ';

  @override
  String get sampleDataDemo => 'ទិន្នន័យគំរូក្នុងកម្មវិធីសាកល្បងនេះ';

  @override
  String get writeOne => 'សរសេរ';

  @override
  String get noReviewsYet => 'មិនទាន់មានការវាយតម្លៃ';

  @override
  String get beFirstReview => 'ក្លាយជាអ្នកដំបូងដែលចែករំលែកបទពិសោធន៍ស្នាក់នៅ។';

  @override
  String get demoReview => 'ការវាយតម្លៃគំរូ';

  @override
  String get verifiedStay => 'បានស្នាក់នៅពិតប្រាកដ';

  @override
  String get writeAReview => 'សរសេរការវាយតម្លៃ';

  @override
  String starsCount(int count) {
    return '$count ផ្កាយ';
  }

  @override
  String get title => 'ចំណងជើង';

  @override
  String get addShortTitle => 'សូមបញ្ចូលចំណងជើងខ្លី';

  @override
  String get yourExperience => 'បទពិសោធន៍របស់អ្នក';

  @override
  String get atLeast10Chars => 'សូមសរសេរយ៉ាងហោចណាស់ 10 តួអក្សរ';

  @override
  String get onlyGuestsCanReview =>
      'មានតែភ្ញៀវដែលមានការកក់បានបញ្ជាក់ទេ ទើបអាចវាយតម្លៃបាន។';

  @override
  String get submit => 'ដាក់ស្នើ';

  @override
  String get amenWifi => 'Wi‑Fi';

  @override
  String get amenPool => 'អាងហែលទឹក';

  @override
  String get amenAc => 'ម៉ាស៊ីនត្រជាក់';

  @override
  String get amenBreakfast => 'អាហារពេលព្រឹក';

  @override
  String get amenParking => 'ចំណតរថយន្ត';

  @override
  String get amenShuttle => 'សេវាដឹកទៅព្រលានយន្តហោះ';

  @override
  String get amenGym => 'កន្លែងហាត់ប្រាណ';

  @override
  String get amenSpa => 'ស្ប៉ា';

  @override
  String get amenRestaurant => 'ភោជនីយដ្ឋាន';

  @override
  String get amenFamilyRoom => 'បន្ទប់គ្រួសារ';

  @override
  String get amenKidsPool => 'អាងហែលទឹកកុមារ';

  @override
  String get amenAccessible => 'ងាយស្រួលសម្រាប់ជនពិការ';

  @override
  String get amenBar => 'បារ';

  @override
  String get amenLaundry => 'សេវាបោកអ៊ុត';

  @override
  String get amenKitchen => 'ផ្ទះបាយ';

  @override
  String get bookingNotPayable => 'ការកក់នេះមិនអាចបង់ប្រាក់បានទៀតទេ។';

  @override
  String paymentNotConfirmed(String status) {
    return '$status (សាកល្បង)។ ការកក់របស់អ្នកមិនទាន់បានបញ្ជាក់ទេ — អ្នកអាចព្យាយាមម្តងទៀត មុនពេលផុតកំណត់រក្សាបន្ទប់។';
  }

  @override
  String get unknownError => 'កំហុសមិនស្គាល់';

  @override
  String get yourStayCaps => 'ការស្នាក់នៅរបស់អ្នក';

  @override
  String nightWord(int count) {
    return 'យប់';
  }

  @override
  String get roomSubtotal => 'តម្លៃបន្ទប់';

  @override
  String get taxes => 'ពន្ធ';

  @override
  String get serviceFee => 'ថ្លៃសេវា';

  @override
  String get noLongerAvailable => 'លែងទំនេរហើយ';

  @override
  String get guestDetails => 'ព័ត៌មានភ្ញៀវ';

  @override
  String get fullNameAsId => 'ឈ្មោះពេញ (ដូចក្នុងអត្តសញ្ញាណប័ណ្ណ)';

  @override
  String get enterGuestName => 'សូមបញ្ចូលឈ្មោះភ្ញៀវ';

  @override
  String get email => 'អ៊ីមែល';

  @override
  String get enterValidEmail => 'សូមបញ្ចូលអ៊ីមែលឱ្យបានត្រឹមត្រូវ';

  @override
  String get phoneOptional => 'លេខទូរស័ព្ទ (មិនចាំបាច់)';

  @override
  String get specialRequestsOptional => 'សំណើពិសេស (មិនចាំបាច់)';

  @override
  String get continueToPayment => 'បន្តទៅការទូទាត់';

  @override
  String get roomHeldNotice =>
      'បន្ទប់របស់អ្នកត្រូវបានរក្សាទុកមួយរយៈខ្លី ខណៈពេលអ្នកបង់ប្រាក់។ ការកក់នឹងត្រូវបានបញ្ជាក់ លុះត្រាតែម៉ាស៊ីនមេផ្ទៀងផ្ទាត់ការទូទាត់រួច។';

  @override
  String get payment => 'ការទូទាត់';

  @override
  String get holdExpired => 'ផុតពេលរក្សាបន្ទប់';

  @override
  String roomHeldFor(String time) {
    return 'រក្សាបន្ទប់ក្នុងរយៈពេល $time';
  }

  @override
  String get simulatedPaymentNotice =>
      'ការទូទាត់សាកល្បង។ កម្មវិធីនេះប្រើប្រព័ន្ធទូទាត់គំរូ៖ គ្មានការកាត់ប្រាក់ពីកាត ហើយគ្មានការផ្ទេរប្រាក់ពិតប្រាកដទេ។ សូមជ្រើសលទ្ធផល ដើម្បីសាកល្បងមើលប្រតិកម្មនៃការកក់។';

  @override
  String referenceValue(String ref) {
    return 'លេខយោង $ref';
  }

  @override
  String get amountDue => 'ចំនួនទឹកប្រាក់ត្រូវបង់';

  @override
  String get payNowSimulate => 'បង់ឥឡូវ (សាកល្បងជោគជ័យ)';

  @override
  String get simulateDeclined => 'សាកល្បងកាតត្រូវបានបដិសេធ';

  @override
  String get payLater => 'បង់ពេលក្រោយពី ការកក់របស់ខ្ញុំ';

  @override
  String get checkoutTitle => 'បង់ប្រាក់';

  @override
  String get stepRoom => 'បន្ទប់';

  @override
  String get stepDetails => 'ព័ត៌មាន';

  @override
  String get myBookings => 'ការកក់របស់ខ្ញុំ';

  @override
  String get upcoming => 'នាពេលខាងមុខ';

  @override
  String get pastAndCancelled => 'កន្លងមក និងបានលុបចោល';

  @override
  String get nothingHereYet => 'មិនទាន់មានអ្វីនៅទីនេះទេ';

  @override
  String get noUpcomingTrips => 'មិនទាន់មានដំណើរនាពេលខាងមុខ';

  @override
  String get pastBookingsHint =>
      'ការកក់ដែលបានបញ្ចប់ និងបានលុបចោល នឹងបង្ហាញនៅទីនេះ។';

  @override
  String get nextAdventureHint =>
      'ដំណើរកម្សាន្តបន្ទាប់របស់អ្នក គ្រាន់តែស្វែងរកមួយដងប៉ុណ្ណោះ។';

  @override
  String get nights => 'យប់';

  @override
  String get reference => 'លេខយោង';

  @override
  String get cancelBookingQ => 'លុបចោលការកក់នេះ?';

  @override
  String get cancelFreeBody =>
      'អ្នកនៅក្នុងរយៈពេលលុបចោលឥតគិតថ្លៃ។ បន្ទប់នឹងត្រូវបានដោះលែង។';

  @override
  String get cancelFreePaidBody =>
      'អ្នកនៅក្នុងរយៈពេលលុបចោលឥតគិតថ្លៃ។ ការសងប្រាក់វិញ (សាកល្បង) នឹងត្រូវបានកត់ត្រា។ បន្ទប់នឹងត្រូវបានដោះលែង។';

  @override
  String get cancelNonRefundBody =>
      'រយៈពេលលុបចោលឥតគិតថ្លៃបានកន្លងផុតហើយ ដូច្នេះការកក់នេះមិនអាចសងប្រាក់វិញបានទេ។ បន្ទប់នឹងត្រូវបានដោះលែង។';

  @override
  String get cancelBooking => 'លុបចោលការកក់';

  @override
  String get bookingCancelled => 'បានលុបចោលការកក់។';

  @override
  String get receiptCaps => 'បង្កាន់ដៃ';

  @override
  String paymentRefStatus(String ref, String status) {
    return 'លេខយោងការទូទាត់ $ref · $status';
  }

  @override
  String get yourBooking => 'ការកក់របស់អ្នក';

  @override
  String get room => 'បន្ទប់';

  @override
  String get guest => 'ភ្ញៀវ';

  @override
  String get payForBooking => 'បង់ប្រាក់សម្រាប់ការកក់នេះ';

  @override
  String get receipt => 'បង្កាន់ដៃ';

  @override
  String get priceBreakdown => 'ព័ត៌មានលម្អិតតម្លៃ';

  @override
  String get cancellationPolicy => 'គោលការណ៍លុបចោល';

  @override
  String freeCancellationUntil(String date) {
    return 'លុបចោលឥតគិតថ្លៃរហូតដល់ $date';
  }

  @override
  String get statusHistory => 'ប្រវត្តិស្ថានភាព';

  @override
  String get payments => 'ការទូទាត់';

  @override
  String get simulatedSuffix => ' (សាកល្បង)';

  @override
  String get youreBooked => 'កក់បានសម្រេច!';

  @override
  String get paymentVerified =>
      'ម៉ាស៊ីនមេបានផ្ទៀងផ្ទាត់ការទូទាត់។ ការទូទាត់សាកល្បង៖ គ្មានការផ្ទេរប្រាក់ពិតប្រាកដទេ។';

  @override
  String get tripsEyebrowCaps => 'ដំណើរ';

  @override
  String get tripsHero => 'ប្រាប់យើងពីគោលដៅ\nយើងរៀបចំកម្មវិធីជូន';

  @override
  String get planWithAi => 'រៀបចំជាមួយ AI';

  @override
  String get planWithAiExample =>
      '\"៣ ថ្ងៃនៅកំពត បែបសម្រាកលំហែ ជាមួយកូនពីរនាក់\"';

  @override
  String get signInToSaveItineraries =>
      'ចូលគណនី ដើម្បីរក្សាទុក និងកែសម្រួលកម្មវិធីដំណើរបានគ្រប់ពេល។';

  @override
  String get startFromOne => 'ចាប់ផ្តើមពីគំរូ';

  @override
  String get curatedJourneys => 'ដំណើរដែលបានជ្រើសរើស';

  @override
  String get plannerRules => 'កម្មវិធីរៀបចំតាមច្បាប់';

  @override
  String get plannerAi => 'ជំនួយដោយ AI';

  @override
  String get plannerManual => 'ដោយដៃ';

  @override
  String get exKampot => 'ចុងសប្តាហ៍សម្រាកនៅកំពត';

  @override
  String get exAngkor => 'អង្គរ សម្រាប់អ្នកថតរូប';

  @override
  String get exPhnomPenh => 'ភ្នំពេញ ក្នុងថវិកា \$150';

  @override
  String get aiTripPlannerCaps => 'កម្មវិធីរៀបចំដំណើរ AI';

  @override
  String get describeTrip => 'រៀបរាប់ពីដំណើរ\nដែលអ្នកចង់បាន';

  @override
  String get plannerModeLlm => 'ជំនួយដោយ AI ផ្អែកលើទីកន្លែងដែលមានក្នុងប្រព័ន្ធ';

  @override
  String get plannerModeRules =>
      'រៀបចំដោយប្រព័ន្ធច្បាប់ ផ្អែកលើទីកន្លែងក្នុងប្រព័ន្ធ។ លឿន និងមិនបង្កើតព័ត៌មានក្លែងក្លាយ។';

  @override
  String get plannerHint =>
      'សរសេរជាភាសាអង់គ្លេស ឧ. 5 days in Kampot and Siem Reap, 2 adults, \$300 total, love food and culture';

  @override
  String get planningYourDays => 'កំពុងរៀបចំកម្មវិធី…';

  @override
  String get createItinerary => 'បង្កើតកម្មវិធីដំណើរ';

  @override
  String get moreDetailPlease => 'សូមផ្តល់ព័ត៌មានបន្ថែមបន្តិច';

  @override
  String get destinationsICanPlan => 'គោលដៅដែលអាចរៀបចំបាន';

  @override
  String get iUnderstood => 'ខ្ញុំយល់ថា';

  @override
  String childrenSuffix(int count) {
    return ', កុមារ $count នាក់';
  }

  @override
  String budgetPerDayLabel(String amount) {
    return '$amount ក្នុងមួយថ្ងៃ';
  }

  @override
  String budgetTotalLabel(String amount) {
    return '$amount សរុប';
  }

  @override
  String get saveToMyTrips => 'រក្សាទុកក្នុងដំណើររបស់ខ្ញុំ';

  @override
  String get signInToSaveTrip => 'ចូលគណនី ដើម្បីរក្សាទុកដំណើរនេះ';

  @override
  String dayN(int n) {
    return 'ថ្ងៃទី $n';
  }

  @override
  String stopsCount(int count) {
    return '$count កន្លែង';
  }

  @override
  String get timeline => 'កាលវិភាគ';

  @override
  String get routeMap => 'ផែនទីផ្លូវ';

  @override
  String regenerateDay(int n) {
    return 'បង្កើតថ្ងៃទី $n ឡើងវិញ';
  }

  @override
  String get noStopsYet => 'មិនទាន់មានកន្លែងទៅ';

  @override
  String get noStopsHint => 'ថ្ងៃនេះមិនទាន់មានការណែនាំទេ។';

  @override
  String get dashedLineNote =>
      'បន្ទាត់ដាច់ៗភ្ជាប់កន្លែងតាមលំដាប់៖ ជាបន្ទាត់ត្រង់ មិនមែនផ្លូវបើកបរពិតប្រាកដទេ។';

  @override
  String get budgetStay => 'ស្នាក់នៅ';

  @override
  String get budgetActivities => 'សកម្មភាព';

  @override
  String get budgetFood => 'ម្ហូបអាហារ';

  @override
  String get budgetTransport => 'ការធ្វើដំណើរ';

  @override
  String get estimatedTotalCaps => 'សរុបប្រហែល';

  @override
  String withinBudget(String amount) {
    return 'ស្ថិតក្នុងថវិកា $amount របស់អ្នក';
  }

  @override
  String overBudget(String amount) {
    return 'លើសថវិកា $amount របស់អ្នក';
  }

  @override
  String lodgingNights(String name, int count) {
    return '$name · $count យប់';
  }

  @override
  String get assumptions => 'ការសន្មត';

  @override
  String minutesCompact(int minutes) {
    return '$minutes នាទី';
  }

  @override
  String travelMinutes(int minutes) {
    return 'ធ្វើដំណើរប្រហែល $minutes នាទី';
  }

  @override
  String get moveUp => 'ផ្លាស់ឡើងលើ';

  @override
  String get moveDown => 'ផ្លាស់ចុះក្រោម';

  @override
  String get removeStop => 'ដកកន្លែងនេះចេញ';

  @override
  String get copyToMyTrips => 'ចម្លងទៅដំណើររបស់ខ្ញុំ';

  @override
  String estimateRecalculated(String amount) {
    return 'បានគណនាតម្លៃឡើងវិញ៖ $amount';
  }

  @override
  String get recalculate => 'គណនាឡើងវិញ';

  @override
  String get deleteTripQ => 'លុបដំណើរនេះ?';

  @override
  String get deleteTripBody => 'កម្មវិធីដំណើរនេះនឹងត្រូវលុបចេញពីគណនីរបស់អ្នក។';

  @override
  String get delete => 'លុប';

  @override
  String get addAStop => 'បន្ថែមកន្លែងទៅ';

  @override
  String get inTrip => 'មានក្នុងដំណើរ';

  @override
  String addToDay(int n) {
    return 'បន្ថែមទៅថ្ងៃទី $n';
  }

  @override
  String get starterBestTime => 'ពេលល្អបំផុតដើម្បីទៅ';

  @override
  String get starterGettingAround => 'ការធ្វើដំណើរក្នុងតំបន់';

  @override
  String get starterDailyBudget => 'ថវិកាប្រចាំថ្ងៃ';

  @override
  String get starterWhatToEat => 'ញ៉ាំអ្វីល្អ';

  @override
  String get starterTempleEtiquette => 'សុជីវធម៌ពេលចូលវត្ត';

  @override
  String get starterCancellation => 'ការលុបចោល';

  @override
  String get somethingWentWrong => 'មានបញ្ហាបន្តិចបន្តួច។';

  @override
  String get guideName => 'មគ្គុទ្ទេសក៍ Wayfarer';

  @override
  String get guideModeLlm => 'ជំនួយការធ្វើដំណើរ AI · ប្រើការណែនាំរបស់យើង';

  @override
  String get guideModeRules => 'ភ្លាមៗ · ចម្លើយពីការណែនាំរបស់យើង';

  @override
  String get newChat => 'ការសន្ទនាថ្មី';

  @override
  String get askMeAnything => 'សួរខ្ញុំអំពី\nដំណើររបស់អ្នក។';

  @override
  String get askIntro =>
      'សួរតាមរបៀបរបស់អ្នក។ ខ្ញុំប្រើការណែនាំរបស់ WAYFARER នៅពេលដែលវាមានប្រយោជន៍ និងចំណេះដឹងទូទៅអំពីការធ្វើដំណើរនៅពេលផ្សេង ហើយខ្ញុំបង្ហាញប្រភពជានិច្ច។ ចម្លើយអាចជាភាសាអង់គ្លេស។';

  @override
  String get generalKnowledge => 'ចំណេះដឹងទូទៅអំពីការធ្វើដំណើរ';

  @override
  String get notInGuides => 'មិនមាននៅក្នុងការណែនាំផ្លូវការ';

  @override
  String planWithPlanner(String name) {
    return 'រៀបចំដំណើរទៅ $name ជាមួយ AI';
  }

  @override
  String sourcesCount(int count) {
    return 'ប្រភព $count';
  }

  @override
  String get demoContentSuffix => ' (ខ្លឹមសារគំរូ)';

  @override
  String get cardStay => 'ស្នាក់នៅ';

  @override
  String get cardPlace => 'ទីកន្លែង';

  @override
  String get cardDestination => 'គោលដៅ';

  @override
  String get askHint => 'សួរអំពីគោលដៅ…';

  @override
  String get send => 'ផ្ញើ';

  @override
  String get checkYourEmail => 'សូមពិនិត្យអ៊ីមែលរបស់អ្នក';

  @override
  String verificationSent(String email) {
    return 'យើងបានផ្ញើតំណផ្ទៀងផ្ទាត់ទៅ $email។ សូមបើកវា រួចចូលគណនី។';
  }

  @override
  String get ok => 'យល់ព្រម';

  @override
  String get googleNotSetUp =>
      'ការចូលតាម Google មិនទាន់បានរៀបចំនៅឡើយទេ។ សូមប្រើអ៊ីមែល និងពាក្យសម្ងាត់សិន។';

  @override
  String get createAnAccountTitle => 'បង្កើត\nគណនី';

  @override
  String get welcomeBack => 'សូមស្វាគមន៍\nការត្រឡប់មកវិញ';

  @override
  String get signUpWithGoogle => 'ចុះឈ្មោះជាមួយ Google';

  @override
  String get signInWithGoogle => 'ចូលជាមួយ Google';

  @override
  String get or => 'ឬ';

  @override
  String get firstName => 'នាមខ្លួន';

  @override
  String get lastName => 'នាមត្រកូល';

  @override
  String get required => 'ត្រូវបំពេញ';

  @override
  String get enterValidEmailAddress =>
      'សូមបញ្ចូលអាសយដ្ឋានអ៊ីមែលឱ្យបានត្រឹមត្រូវ';

  @override
  String get password => 'ពាក្យសម្ងាត់';

  @override
  String get passwordHelper => 'យ៉ាងតិច 10 តួ មានអក្សរ និងលេខ';

  @override
  String get showPassword => 'បង្ហាញពាក្យសម្ងាត់';

  @override
  String get hidePassword => 'លាក់ពាក្យសម្ងាត់';

  @override
  String get enterPassword => 'សូមបញ្ចូលពាក្យសម្ងាត់';

  @override
  String get passwordRule => 'សូមប្រើយ៉ាងតិច 10 តួ ដែលមានអក្សរ និងលេខ';

  @override
  String get forgotPassword => 'ភ្លេចពាក្យសម្ងាត់?';

  @override
  String get createAccount => 'បង្កើតគណនី';

  @override
  String get termsNotice =>
      'ការបង្កើតគណនី មានន័យថាអ្នកយល់ព្រមលើលក្ខខណ្ឌប្រើប្រាស់ និងគោលការណ៍ឯកជនភាពរបស់ WAYFARER។';

  @override
  String get haveAccount => 'មានគណនីរួចហើយ? ';

  @override
  String get newHere => 'ទើបមកដំបូង? ';

  @override
  String get logInHere => 'ចូលគណនីនៅទីនេះ';

  @override
  String get createAnAccount => 'បង្កើតគណនី';

  @override
  String get resetPassword => 'កំណត់ពាក្យសម្ងាត់ឡើងវិញ';

  @override
  String resetLinkSent(String email) {
    return 'ប្រសិនបើមានគណនីសម្រាប់ $email តំណកំណត់ពាក្យសម្ងាត់ឡើងវិញ នឹងត្រូវផ្ញើទៅ។';
  }

  @override
  String get sendResetLink => 'ផ្ញើតំណកំណត់ឡើងវិញ';

  @override
  String get verifyEmailFirst =>
      'សូមផ្ទៀងផ្ទាត់អ៊ីមែលរបស់អ្នកជាមុនសិន។ យើងទើបផ្ញើតំណថ្មីទៅអ្នក៖ សូមបើកវា រួចចូលគណនីម្តងទៀត។';

  @override
  String get authEmailInUse =>
      'មានគណនីប្រើអ៊ីមែលនេះរួចហើយ។ សូមសាកល្បងចូលគណនីជំនួសវិញ។';

  @override
  String get authInvalidEmail => 'អាសយដ្ឋានអ៊ីមែលនេះហាក់ដូចជាមិនត្រឹមត្រូវ។';

  @override
  String get authWeakPassword =>
      'សូមជ្រើសពាក្យសម្ងាត់ដែលរឹងមាំជាងនេះ៖ យ៉ាងតិច 10 តួ មានអក្សរ និងលេខ។';

  @override
  String get authWrongCredentials => 'អ៊ីមែល ឬពាក្យសម្ងាត់មិនត្រឹមត្រូវ។';

  @override
  String get authDisabled => 'គណនីនេះត្រូវបានបិទ។ សូមទាក់ទងផ្នែកជំនួយ។';

  @override
  String get authTooMany =>
      'ព្យាយាមច្រើនដងពេក។ សូមរង់ចាំប៉ុន្មាននាទី រួចព្យាយាមម្តងទៀត។';

  @override
  String get authNetwork =>
      'គ្មានការតភ្ជាប់។ សូមពិនិត្យអ៊ីនធឺណិត រួចព្យាយាមម្តងទៀត។';

  @override
  String get authNotAllowed =>
      'វិធីចូលគណនីនេះ មិនទាន់បានបើកនៅក្នុង Firebase នៅឡើយទេ។';

  @override
  String get authOtherMethod =>
      'អ៊ីមែលនេះត្រូវបានប្រើជាមួយវិធីចូលគណនីផ្សេងរួចហើយ។';

  @override
  String authFailed(String code) {
    return 'ការចូលគណនីមិនបានសម្រេច ($code)។ សូមព្យាយាមម្តងទៀត។';
  }

  @override
  String get displayCurrency => 'រូបិយប័ណ្ណបង្ហាញ';

  @override
  String get currencyNote =>
      'តម្លៃត្រូវបានរក្សាទុកជាដុល្លារអាមេរិក ហើយប្តូរតាមអត្រាគំរូ មិនមែនអត្រាទីផ្សារបច្ចុប្បន្នទេ។';

  @override
  String get accountHero => 'ការធ្វើដំណើររបស់អ្នក\nនៅកន្លែងតែមួយ។';

  @override
  String get accountSignInHint =>
      'ចូលគណនី ដើម្បីមើលការកក់ ដំណើរដែលបានរក្សាទុក និងបញ្ជីចូលចិត្ត។';

  @override
  String get myBookingsSub => 'សំបុត្រ ការលុបចោល និងបង្កាន់ដៃ';

  @override
  String get wishlist => 'បញ្ជីចូលចិត្ត';

  @override
  String get wishlistSub => 'គោលដៅ និងកន្លែងស្នាក់នៅដែលបានរក្សាទុក';

  @override
  String get notifications => 'ការជូនដំណឹង';

  @override
  String get notificationsSub => 'ព័ត៌មានថ្មីៗអំពីការកក់ និងការទូទាត់';

  @override
  String get exploreMap => 'មើលផែនទី';

  @override
  String get exploreMapSub => 'គោលដៅ និងកន្លែងស្នាក់នៅក្បែរអ្នក';

  @override
  String get administrationSub =>
      'ទិដ្ឋភាពទូទៅ ការកក់ ការទូទាត់ ការវាយតម្លៃ កំណត់ហេតុសវនកម្ម';

  @override
  String get partnerPortalSub => 'កន្លែងស្នាក់នៅ ការកក់ និងបន្ទប់ទំនេររបស់អ្នក';

  @override
  String get signOut => 'ចាកចេញពីគណនី';

  @override
  String get deleteMyAccount => 'លុបគណនីរបស់ខ្ញុំ';

  @override
  String get deleteAccountQ => 'លុបគណនីរបស់អ្នក?';

  @override
  String get deleteAccountBody =>
      'ព័ត៌មានផ្ទាល់ខ្លួនរបស់អ្នកនឹងត្រូវលុបអត្តសញ្ញាណ ហើយអ្នកនឹងត្រូវចាកចេញពីគណនី។ ការកក់ដែលកំពុងដំណើរការ ត្រូវលុបចោលជាមុនសិន។ សកម្មភាពនេះមិនអាចត្រឡប់វិញបានទេ។';

  @override
  String get confirmPassword => 'បញ្ជាក់ពាក្យសម្ងាត់';

  @override
  String get keepAccount => 'រក្សាគណនី';

  @override
  String get nothingSavedYet => 'មិនទាន់មានអ្វីរក្សាទុក';

  @override
  String get nothingSavedHint =>
      'ចុចរូបបេះដូងលើគោលដៅ ឬកន្លែងស្នាក់នៅ ដើម្បីរក្សាទុកវានៅទីនេះ។';

  @override
  String get savedItem => 'ធាតុដែលបានរក្សាទុក';

  @override
  String get stay => 'កន្លែងស្នាក់នៅ';

  @override
  String get markAllRead => 'សម្គាល់ថាបានអានទាំងអស់';

  @override
  String get allCaughtUp => 'អ្នកបានមើលទាំងអស់ហើយ';

  @override
  String get inAppOnlyNote =>
      'ការជូនដំណឹងក្នុងកម្មវិធីតែប៉ុណ្ណោះ។ ការជូនដំណឹងតាម Push ត្រូវការការកំណត់ Firebase ដែលមិនទាន់បានរៀបចំ។';

  @override
  String get language => 'ភាសា';

  @override
  String get languageSub => 'ភាសាអង់គ្លេស ឬភាសាខ្មែរ';

  @override
  String get languageSystem => 'តាមការកំណត់ទូរស័ព្ទ';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageKhmer => 'ភាសាខ្មែរ';

  @override
  String get languageNote =>
      'ឈ្មោះទីកន្លែង ការពិពណ៌នា និងចម្លើយ AI មកពីមូលដ្ឋានទិន្នន័យរបស់យើង ហើយជាភាសាអង់គ្លេស។';

  @override
  String get settings => 'ការកំណត់';

  @override
  String get currency => 'រូបិយប័ណ្ណ';

  @override
  String get join => 'ចុះឈ្មោះ';

  @override
  String get roleAdmin => 'អ្នកគ្រប់គ្រង';

  @override
  String get roleStaff => 'បុគ្គលិក';

  @override
  String get rolePartner => 'ដៃគូ';

  @override
  String get roleCustomer => 'អ្នកធ្វើដំណើរ';

  @override
  String get adminOverview => 'ទិដ្ឋភាពទូទៅ';

  @override
  String get adminBookings => 'ការកក់';

  @override
  String get adminPayments => 'ការទូទាត់';

  @override
  String get adminUsers => 'អ្នកប្រើប្រាស់';

  @override
  String get adminReviews => 'ការវាយតម្លៃ';

  @override
  String get adminAuditLog => 'កំណត់ហេតុសវនកម្ម';

  @override
  String get adminContent => 'ខ្លឹមសារ';

  @override
  String get adminAccessRequired => 'ត្រូវការសិទ្ធិអ្នកគ្រប់គ្រង';

  @override
  String get adminAccessHint =>
      'ផ្នែកនេះសម្រាប់តែបុគ្គលិក និងអ្នកគ្រប់គ្រងប៉ុណ្ណោះ។ សិទ្ធិចូលប្រើត្រូវបានគ្រប់គ្រងដោយម៉ាស៊ីនមេ។';

  @override
  String totalCount(int count) {
    return 'សរុប $count';
  }

  @override
  String get previousPage => 'ទំព័រមុន';

  @override
  String get nextPage => 'ទំព័របន្ទាប់';

  @override
  String get simulatedNetRevenue => 'ចំណូលសុទ្ធ (សាកល្បង)';

  @override
  String get bookingsByStatus => 'ការកក់តាមស្ថានភាព';

  @override
  String get aiUsage => 'ការប្រើប្រាស់ AI';

  @override
  String get noAiCalls => 'មិនទាន់មានការប្រើ AI នៅឡើយទេ។';

  @override
  String aiCallsAvg(String calls, String ms) {
    return '$calls ដង · មធ្យម $ms ms';
  }

  @override
  String get searchBookingsHint => 'លេខយោង ភ្ញៀវ អ៊ីមែល';

  @override
  String get demoSuffix => ' · គំរូ';

  @override
  String get actions => 'សកម្មភាព';

  @override
  String cancelBookingRef(String ref) {
    return 'លុបចោលការកក់ $ref?';
  }

  @override
  String get adminCancelBody =>
      'បន្ទប់នឹងត្រូវបានដោះលែង ហើយភ្ញៀវនឹងទទួលបានការជូនដំណឹង។ ការសងប្រាក់វិញអនុវត្តតាមគោលការណ៍នៃការកក់។';

  @override
  String get markCheckedIn => 'សម្គាល់ថាបានចូលស្នាក់នៅ';

  @override
  String get markCompleted => 'សម្គាល់ថាបានបញ្ចប់';

  @override
  String get bookingDetail => 'ព័ត៌មានលម្អិតនៃការកក់';

  @override
  String get paymentsAndTransactions => 'ការទូទាត់ និងប្រតិបត្តិការ';

  @override
  String get nameOrEmail => 'ឈ្មោះ ឬអ៊ីមែល';

  @override
  String get demoAccountSuffix => ' · គណនីគំរូ';

  @override
  String get changeRoleQ => 'ប្តូរតួនាទី?';

  @override
  String changeRoleBody(String email, String role) {
    return 'កំណត់ $email ជា \"$role\"។ វានឹងផ្លាស់ប្តូរសិទ្ធិរបស់គណនីនេះ។';
  }

  @override
  String get changeRole => 'ប្តូរតួនាទី';

  @override
  String get reviewModeration => 'ត្រួតពិនិត្យការវាយតម្លៃ';

  @override
  String get hide => 'លាក់';

  @override
  String get publish => 'ផ្សព្វផ្សាយ';

  @override
  String get system => 'ប្រព័ន្ធ';

  @override
  String numberBetween(String lo, String hi) {
    return 'សូមបញ្ចូលលេខចន្លោះពី $lo ដល់ $hi';
  }

  @override
  String get createDestination => 'បង្កើតគោលដៅ';

  @override
  String get name => 'ឈ្មោះ';

  @override
  String get atLeast2Chars => 'យ៉ាងតិច 2 តួអក្សរ';

  @override
  String get country => 'ប្រទេស';

  @override
  String get shortDescription => 'ការពិពណ៌នាខ្លី (10 តួឡើងទៅ)';

  @override
  String get atLeast10CharsShort => 'យ៉ាងតិច 10 តួអក្សរ';

  @override
  String get longDescription => 'ការពិពណ៌នាលម្អិត (20 តួឡើងទៅ)';

  @override
  String get atLeast20Chars => 'យ៉ាងតិច 20 តួអក្សរ';

  @override
  String get latitude => 'រយៈទទឹង';

  @override
  String get longitude => 'រយៈបណ្តោយ';

  @override
  String get dailyBudgetUsd => 'ថវិកាប្រចាំថ្ងៃ (USD)';

  @override
  String get destinationCreated => 'បានបង្កើតគោលដៅ និងកត់ត្រាសវនកម្ម។';

  @override
  String get adminHotelsNote =>
      'សណ្ឋាគារ បន្ទប់ តម្លៃ និងចំនួនបន្ទប់ ត្រូវបានគ្រប់គ្រងដោយដៃគូនីមួយៗ នៅក្នុងផ្ទាំងដៃគូលើគេហទំព័រ (/partner)។ អ្នកគ្រប់គ្រងអាចមើលវានៅក្នុងផ្ទាំងគ្រប់គ្រងលើគេហទំព័រ (/admin)។';

  @override
  String get partnerAccessRequired => 'ត្រូវការសិទ្ធិដៃគូ';

  @override
  String get partnerAccessHint =>
      'មានតែគណនីដៃគូទេ ដែលអាចគ្រប់គ្រងកន្លែងស្នាក់នៅបាន។ សិទ្ធិចូលប្រើត្រូវបានគ្រប់គ្រងដោយម៉ាស៊ីនមេ។';

  @override
  String get occupancyNext30 => 'អត្រាស្នាក់នៅ 30 ថ្ងៃខាងមុខ';

  @override
  String get notApplicable => 'គ្មាន';

  @override
  String get yourProperties => 'កន្លែងស្នាក់នៅរបស់អ្នក';

  @override
  String get noPropertiesAssigned =>
      'មិនទាន់មានកន្លែងស្នាក់នៅសម្រាប់គណនីដៃគូនេះទេ';

  @override
  String baseRooms(String price, String count) {
    return 'តម្លៃគោល $price · $count បន្ទប់';
  }

  @override
  String get availability => 'បន្ទប់ទំនេរ';

  @override
  String get incomingBookings => 'ការកក់ថ្មីៗ';

  @override
  String get checkInAction => 'ចុះឈ្មោះចូល';

  @override
  String get complete => 'បញ្ចប់';

  @override
  String availabilityFor(String name) {
    return 'បន្ទប់ទំនេរ៖ $name';
  }

  @override
  String roomsAvailablePerNight(String max) {
    return 'ចំនួនបន្ទប់ទំនេរក្នុងមួយយប់ (0–$max)';
  }

  @override
  String get nightlyPriceOptional => 'តម្លៃក្នុងមួយយប់ USD (មិនចាំបាច់)';

  @override
  String get availabilityUpdated => 'បានធ្វើបច្ចុប្បន្នភាពបន្ទប់ទំនេរ';

  @override
  String get offlineMessage =>
      'អ្នកហាក់ដូចជាគ្មានអ៊ីនធឺណិត ឬមិនអាចភ្ជាប់ទៅម៉ាស៊ីនមេបាន។';

  @override
  String get timeoutMessage =>
      'ម៉ាស៊ីនមេឆ្លើយតបយឺតពេក។ សូមពិនិត្យការតភ្ជាប់ រួចព្យាយាមម្តងទៀត។';

  @override
  String get quickPlaces => 'ទីកន្លែង';

  @override
  String get quickThingsToDo => 'កន្លែងលេង';

  @override
  String get saveAsPdf => 'រក្សាទុកជា PDF';

  @override
  String get preparingPdf => 'កំពុងរៀបចំ PDF…';

  @override
  String get pdfFailed => 'មិនអាចបង្កើត PDF បានទេ។ សូមព្យាយាមម្តងទៀត។';

  @override
  String get pdfBrandLine => 'WAYFARER · កម្មវិធីដំណើរ';

  @override
  String pdfCreatedOn(String date) {
    return 'បង្កើតនៅថ្ងៃ $date';
  }

  @override
  String pdfDayTitle(int n) {
    return 'ថ្ងៃទី $n';
  }

  @override
  String get back => 'ត្រឡប់ក្រោយ';

  @override
  String get exKohRong => 'គេចទៅកោះរ៉ុង';

  @override
  String get exMondulkiri => 'ធម្មជាតិមណ្ឌលគិរី';

  @override
  String get exBattambang => 'ម្ហូប និងវប្បធម៌បាត់ដំបង';

  @override
  String get fontCredit => 'ពុម្ពអក្សរខ្មែរ៖ MiSans Khmer ដោយ Xiaomi';

  @override
  String dayInCity(int n, String city) {
    return 'ថ្ងៃទី $n · $city';
  }

  @override
  String transferFromCity(String city) {
    return 'ធ្វើដំណើរពី $city';
  }

  @override
  String transferInfo(String km, String time, String price) {
    return 'ប្រហែល $km គ.ម តាមផ្លូវគោក · $time · $price (ប៉ាន់ស្មាន)';
  }

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '$hours ម៉ោង $minutes នាទី';
  }

  @override
  String durationHours(int hours) {
    return '$hours ម៉ោង';
  }

  @override
  String get exTwoCities => 'កំពត + សៀមរាប';
}
