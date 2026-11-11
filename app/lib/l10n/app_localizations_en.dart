// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'WAYFARER';

  @override
  String get tagline => 'Travel, planned beautifully';

  @override
  String get splashLoading => 'Loading WAYFARER';

  @override
  String get splashReady => 'Getting things ready';

  @override
  String get splashSlow => 'Waking the server, this can take a moment';

  @override
  String get tabDiscover => 'Discover';

  @override
  String get tabStays => 'Stays';

  @override
  String get tabTrips => 'Trips';

  @override
  String get tabMe => 'Me';

  @override
  String get askAiGuide => 'Ask the AI travel guide';

  @override
  String get administration => 'Administration';

  @override
  String get partnerPortal => 'Partner portal';

  @override
  String get pageNotFound => 'We could not find that page';

  @override
  String get backToDiscover => 'Back to Discover';

  @override
  String get welcome1Eyebrow => 'Discover';

  @override
  String get welcome1Title => 'Cambodia,';

  @override
  String get welcome1Italic => 'close up';

  @override
  String get welcome1Body =>
      'Twelve destinations, hundreds of places and stays, from Angkor at sunrise to the islands of Koh Rong.';

  @override
  String get welcome2Eyebrow => 'Plan';

  @override
  String get welcome2Title => 'Trips that build';

  @override
  String get welcome2Italic => 'themselves';

  @override
  String get welcome2Body =>
      'Tell the AI planner where, how long and what you love. It lays out every day on real, stored places.';

  @override
  String get welcome3Eyebrow => 'Go';

  @override
  String get welcome3Title => 'Book it,';

  @override
  String get welcome3Italic => 'carry it';

  @override
  String get welcome3Body =>
      'Reserve rooms with clear policies, keep tickets in your pocket and ask the guide anything on the way.';

  @override
  String get skip => 'Skip';

  @override
  String get next => 'Next';

  @override
  String get startExploring => 'Start exploring';

  @override
  String fromPerDay(String price) {
    return 'from $price / day';
  }

  @override
  String priceForNights(String price, int nights) {
    String _temp0 = intl.Intl.pluralLogic(
      nights,
      locale: localeName,
      other: '$nights nights',
      one: '1 night',
    );
    return '$price for $_temp0';
  }

  @override
  String get perNight => '/ night';

  @override
  String kmAway(String distance) {
    return '$distance km away';
  }

  @override
  String photoFor(String name) {
    return 'Photo for $name';
  }

  @override
  String get perkFreeCancellation => 'Free cancellation';

  @override
  String get perkBreakfast => 'Breakfast';

  @override
  String get perkFamily => 'Family';

  @override
  String get typeHotel => 'Hotel';

  @override
  String get typeGuesthouse => 'Guesthouse';

  @override
  String get typeResort => 'Resort';

  @override
  String get typeHostel => 'Hostel';

  @override
  String get typeBoutique => 'Boutique hotel';

  @override
  String get typeVilla => 'Villa';

  @override
  String get typeApartment => 'Apartment';

  @override
  String get typeBungalow => 'Bungalow';

  @override
  String get catTemple => 'Temple';

  @override
  String get catMuseum => 'Museum';

  @override
  String get catMarket => 'Market';

  @override
  String get catNature => 'Nature';

  @override
  String get catBeach => 'Beach';

  @override
  String get catFood => 'Food';

  @override
  String get catCafe => 'Cafe';

  @override
  String get catCulture => 'Culture';

  @override
  String get catTour => 'Tour';

  @override
  String get catOutdoor => 'Outdoor';

  @override
  String get catFamily => 'Family';

  @override
  String get catLandmark => 'Landmark';

  @override
  String get catHistory => 'History';

  @override
  String get catRestaurant => 'Restaurant';

  @override
  String get catActivity => 'Activity';

  @override
  String get catAttraction => 'Attraction';

  @override
  String get tagTemples => 'Temples';

  @override
  String get tagRelaxed => 'Relaxed';

  @override
  String get tagCity => 'City';

  @override
  String get tagIslands => 'Islands';

  @override
  String get free => 'Free';

  @override
  String minutesShort(int minutes) {
    return '$minutes min';
  }

  @override
  String get saveToWishlist => 'Save to wishlist';

  @override
  String get removeFromWishlist => 'Remove from wishlist';

  @override
  String get loading => 'Loading';

  @override
  String get genericError => 'Something went wrong. Please try again.';

  @override
  String get noConnection => 'No connection';

  @override
  String get didntLoad => 'That didn\'t load';

  @override
  String get tryAgain => 'Try again';

  @override
  String get demoListing => 'Demo listing';

  @override
  String get demoTooltip =>
      'Educational sample data: not a real commercial offer';

  @override
  String get ratingNew => 'New';

  @override
  String starProperty(int stars) {
    return '$stars star property';
  }

  @override
  String stayCardSemantics(String name, int stars, String type) {
    return '$name, $stars star $type';
  }

  @override
  String get statusConfirmed => 'Confirmed';

  @override
  String get statusAwaitingPayment => 'Awaiting payment';

  @override
  String get statusCheckedIn => 'Checked in';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get statusExpired => 'Expired';

  @override
  String get statusRefundPending => 'Refund pending';

  @override
  String get statusRefunded => 'Refunded';

  @override
  String get statusDraft => 'Draft';

  @override
  String get statusPaidSimulated => 'Paid (simulated)';

  @override
  String get statusPaymentFailed => 'Payment failed';

  @override
  String get statusPaymentPending => 'Payment pending';

  @override
  String get confirm => 'Confirm';

  @override
  String get keep => 'Keep';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get close => 'Close';

  @override
  String get done => 'Done';

  @override
  String get seeAll => 'See all';

  @override
  String get all => 'All';

  @override
  String get greetingNight => 'Late night wanderer';

  @override
  String get greetingMorning => 'Good morning';

  @override
  String get greetingAfternoon => 'Good afternoon';

  @override
  String get greetingEvening => 'Good evening';

  @override
  String greetingWithName(String greeting, String name) {
    return '$greeting, $name';
  }

  @override
  String get signIn => 'Sign in';

  @override
  String get heroLine1 => 'Where will you';

  @override
  String get heroLine2 => 'wander next?';

  @override
  String get searchStays => 'Search stays';

  @override
  String get findYourStay => 'Find your stay';

  @override
  String get anywhereAnyDates => 'Anywhere · Any dates · Any guests';

  @override
  String get quickAiPlanner => 'AI planner';

  @override
  String get quickDayByDay => 'Day-by-day';

  @override
  String get quickAskGuide => 'Ask guide';

  @override
  String get quickInstantAnswers => 'Instant answers';

  @override
  String get quickMap => 'Map';

  @override
  String get quickNearYou => 'Near you';

  @override
  String get recentlyViewed => 'Recently viewed';

  @override
  String get pickUpWhereLeft => 'Pick up where you left off';

  @override
  String get featured => 'Featured';

  @override
  String get destinationsWeLove => 'Destinations we love';

  @override
  String get explore => 'Explore';

  @override
  String get browseByMood => 'Browse by mood';

  @override
  String get topRated => 'Top rated';

  @override
  String get staysWorthTrip => 'Stays worth the trip';

  @override
  String get browse => 'Browse';

  @override
  String get itineraries => 'Itineraries';

  @override
  String get readyMadeJourneys => 'Ready-made journeys';

  @override
  String get planYours => 'Plan yours';

  @override
  String get thisWeek => 'This week';

  @override
  String get trendingNow => 'Trending now';

  @override
  String get statDestinations => 'Destinations';

  @override
  String get statPlaces => 'Places';

  @override
  String get statStays => 'Stays';

  @override
  String daysCount(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String estimatedTotal(String amount) {
    return 'Est. $amount';
  }

  @override
  String get destinationsTitle => 'Destinations';

  @override
  String get sort => 'Sort';

  @override
  String get sortPopular => 'Most popular';

  @override
  String get sortNameAZ => 'Name A–Z';

  @override
  String get sortBudgetLow => 'Budget: low to high';

  @override
  String get sortBudgetHigh => 'Budget: high to low';

  @override
  String get searchDestinations => 'Search destinations';

  @override
  String get noDestinationsMatch => 'No destinations match';

  @override
  String get noDestinationsHint =>
      'Try removing a filter or searching for a different name.';

  @override
  String get clearFilters => 'Clear filters';

  @override
  String destinationsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count destinations',
      one: '1 destination',
    );
    return '$_temp0';
  }

  @override
  String photoOf(String name) {
    return 'Photo of $name';
  }

  @override
  String photoIndex(int index, int total) {
    return '$index / $total';
  }

  @override
  String budgetPerDay(String amount) {
    return '~$amount / day';
  }

  @override
  String get showLess => 'Show less';

  @override
  String get readMore => 'Read more';

  @override
  String get thingsToDo => 'Things to do and eat';

  @override
  String get kindAttractions => 'Attractions';

  @override
  String get kindActivities => 'Activities';

  @override
  String get kindRestaurants => 'Restaurants';

  @override
  String get nothingListed => 'Nothing listed yet';

  @override
  String get nothingListedHint =>
      'We have no places of this type for this destination.';

  @override
  String showAllCount(int count) {
    return 'Show all $count';
  }

  @override
  String get staysEyebrow => 'Stays';

  @override
  String get whereToStay => 'Where to stay';

  @override
  String get keepGoing => 'Keep going';

  @override
  String get nearbyAndRelated => 'Nearby and related';

  @override
  String kmShort(String distance) {
    return '$distance km';
  }

  @override
  String get readAndAsk => 'Read & ask';

  @override
  String get travelGuides => 'Travel guides';

  @override
  String get findStays => 'Find stays';

  @override
  String get planTrip => 'Plan trip';

  @override
  String get indicative => '(indicative)';

  @override
  String get familyFriendly => 'Family friendly';

  @override
  String get directions => 'Directions';

  @override
  String get destination => 'Destination';

  @override
  String get placesTitle => 'Places';

  @override
  String get searchPlacesHint => 'Search places, e.g. Angkor, market, museum';

  @override
  String placesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count places',
      one: '1 place',
    );
    return '$_temp0';
  }

  @override
  String get noPlacesMatch => 'No places match';

  @override
  String get noPlacesHint => 'Try a different category or search term.';

  @override
  String get locationOff => 'Location services are turned off on this device.';

  @override
  String get locationDeclined =>
      'Location permission was declined. You can still explore the map and search by destination.';

  @override
  String get locationBlocked =>
      'Location permission is blocked. Enable it in your device settings to use this feature.';

  @override
  String locationFailed(String reason) {
    return 'We could not get your location ($reason).';
  }

  @override
  String get locationTimeout => 'timeout or unsupported';

  @override
  String perNightKmAway(String price, String distance) {
    return '$price / night · $distance km away';
  }

  @override
  String get youAreHere => 'You are here';

  @override
  String get nearMe => 'Near me';

  @override
  String get staysNearYou => 'Stays near you';

  @override
  String get noStaysNearby =>
      'No stays within 60 km. Our listings cover specific destinations; explore one instead.';

  @override
  String get noLocations => 'No locations to show';

  @override
  String get directionsInMaps => 'Directions in maps app';

  @override
  String get showResults => 'Show results';

  @override
  String get anywhere => 'Anywhere';

  @override
  String get anyDates => 'Any dates';

  @override
  String guestsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count guests',
      one: '1 guest',
    );
    return '$_temp0';
  }

  @override
  String roomsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rooms',
      one: '1 room',
    );
    return '$_temp0';
  }

  @override
  String nightsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nights',
      one: '1 night',
    );
    return '$_temp0';
  }

  @override
  String adultsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count adults',
      one: '1 adult',
    );
    return '$_temp0';
  }

  @override
  String childrenCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count children',
      one: '1 child',
    );
    return '$_temp0';
  }

  @override
  String get staysEyebrowCaps => 'STAYS';

  @override
  String get findPlaceToRest => 'Find a place\nto rest';

  @override
  String get filters => 'Filters';

  @override
  String filtersActive(int count) {
    return 'Filters · $count';
  }

  @override
  String get sortRecommended => 'Recommended';

  @override
  String get sortPriceLow => 'Price: low to high';

  @override
  String get sortPriceHigh => 'Price: high to low';

  @override
  String get sortGuestRating => 'Guest rating';

  @override
  String get sortDistance => 'Distance';

  @override
  String get sortPriceUp => 'Price ↑';

  @override
  String get sortPriceDown => 'Price ↓';

  @override
  String get sortNearest => 'Nearest';

  @override
  String get listView => 'List view';

  @override
  String get mapView => 'Map view';

  @override
  String get searching => 'Searching…';

  @override
  String staysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stays',
      one: '1 stay',
    );
    return '$_temp0';
  }

  @override
  String totalsShownForNights(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nights',
      one: '1 night',
    );
    return '$_temp0, totals shown';
  }

  @override
  String get addDatesForAvailability => 'add dates for real availability';

  @override
  String get noStaysMatch => 'No stays match';

  @override
  String get noStaysDatesHint =>
      'There may be no availability for these dates and guests. Try different dates, fewer filters or another destination.';

  @override
  String get noStaysHint =>
      'Try widening your price range or removing a filter.';

  @override
  String get clearAll => 'Clear all';

  @override
  String pricePerNightRange(String min, String max) {
    return 'Price per night · $min – $max';
  }

  @override
  String get starRating => 'Star rating';

  @override
  String get guestRating => 'Guest rating';

  @override
  String get propertyType => 'Property type';

  @override
  String get popular => 'Popular';

  @override
  String get breakfastAvailable => 'Breakfast available';

  @override
  String get amenities => 'Amenities';

  @override
  String get realAvailability =>
      'Real availability and total prices for your dates.';

  @override
  String get selectCheckInOut => 'Select check-in and check-out';

  @override
  String fewer(String label) {
    return 'Fewer $label';
  }

  @override
  String more(String label) {
    return 'More $label';
  }

  @override
  String get adults => 'Adults';

  @override
  String get adultsAge => 'Age 13 or above';

  @override
  String get children => 'Children';

  @override
  String get childrenAge => 'Age 0 to 12';

  @override
  String get rooms => 'Rooms';

  @override
  String get apply => 'Apply';

  @override
  String get checkoutAfterCheckin => 'Check-out must be after check-in';

  @override
  String get addDates => 'Add dates';

  @override
  String get whereTo => 'Where to?';

  @override
  String get whereToHint => 'City, destination or hotel';

  @override
  String get dates => 'Dates';

  @override
  String get guests => 'Guests';

  @override
  String fieldValue(String label, String value) {
    return '$label: $value';
  }

  @override
  String photoNofM(int index, int total, String name) {
    return 'Photo $index of $total for $name';
  }

  @override
  String get whatThisPlaceOffers => 'What this place offers';

  @override
  String get goodToKnow => 'Good to know';

  @override
  String get cancellation => 'Cancellation';

  @override
  String get checkIn => 'Check-in';

  @override
  String get checkOut => 'Check-out';

  @override
  String fromTime(String time) {
    return 'From $time';
  }

  @override
  String byTime(String time) {
    return 'By $time';
  }

  @override
  String get taxesAndFees => 'Taxes and fees';

  @override
  String taxesAndFeesBody(String tax, String fee) {
    return '$tax% tax and $fee% service fee are added to the room rate and shown before you pay.';
  }

  @override
  String get location => 'Location';

  @override
  String get chooseYourRoom => 'Choose your room';

  @override
  String get similarStays => 'Similar stays nearby';

  @override
  String get fromCaps => 'FROM';

  @override
  String get chooseARoom => 'Choose a room';

  @override
  String get chooseYourDates => 'Choose your dates';

  @override
  String nightsTapToChange(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nights',
      one: '1 night',
    );
    return '$_temp0 · tap to change';
  }

  @override
  String get tapToSelect => 'Tap to select';

  @override
  String get removeRoom => 'Remove a room';

  @override
  String get addRoom => 'Add a room';

  @override
  String get selectDates => 'Select dates';

  @override
  String get tooSmallForParty => 'Too small for your party';

  @override
  String get notAvailable => 'Not available';

  @override
  String get reserve => 'Reserve';

  @override
  String get basePerNight => 'base / night';

  @override
  String upToAdults(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count adults',
      one: '1 adult',
    );
    return 'Up to $_temp0';
  }

  @override
  String plusChildren(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count children',
      one: '1 child',
    );
    return ' + $_temp0';
  }

  @override
  String get breakfastIncluded => 'Breakfast included';

  @override
  String avgTimesNights(String price, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nights',
      one: '1 night',
    );
    return '$price avg × $_temp0';
  }

  @override
  String timesRooms(int count) {
    return ' × $count rooms';
  }

  @override
  String taxesPercent(String percent) {
    return 'Taxes ($percent%)';
  }

  @override
  String serviceFeePercent(String percent) {
    return 'Service fee ($percent%)';
  }

  @override
  String get total => 'Total';

  @override
  String get guestReviews => 'Guest reviews';

  @override
  String get sampleDataDemo => 'Sample data in this demo';

  @override
  String get writeOne => 'Write one';

  @override
  String get noReviewsYet => 'No reviews yet';

  @override
  String get beFirstReview => 'Be the first to share your stay.';

  @override
  String get demoReview => 'Demo review';

  @override
  String get verifiedStay => 'Verified stay';

  @override
  String get writeAReview => 'Write a review';

  @override
  String starsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stars',
      one: '1 star',
    );
    return '$_temp0';
  }

  @override
  String get title => 'Title';

  @override
  String get addShortTitle => 'Add a short title';

  @override
  String get yourExperience => 'Your experience';

  @override
  String get atLeast10Chars => 'Please write at least 10 characters';

  @override
  String get onlyGuestsCanReview =>
      'Only guests with a confirmed booking can review a property.';

  @override
  String get submit => 'Submit';

  @override
  String get amenWifi => 'Wi‑Fi';

  @override
  String get amenPool => 'Swimming pool';

  @override
  String get amenAc => 'Air conditioning';

  @override
  String get amenBreakfast => 'Breakfast';

  @override
  String get amenParking => 'Parking';

  @override
  String get amenShuttle => 'Airport shuttle';

  @override
  String get amenGym => 'Gym';

  @override
  String get amenSpa => 'Spa';

  @override
  String get amenRestaurant => 'Restaurant';

  @override
  String get amenFamilyRoom => 'Family rooms';

  @override
  String get amenKidsPool => 'Kids\' pool';

  @override
  String get amenAccessible => 'Accessible';

  @override
  String get amenBar => 'Bar';

  @override
  String get amenLaundry => 'Laundry';

  @override
  String get amenKitchen => 'Kitchen';

  @override
  String get bookingNotPayable => 'This booking can no longer be paid.';

  @override
  String paymentNotConfirmed(String status) {
    return '$status (simulated). Your booking is not confirmed — you can try again before the hold expires.';
  }

  @override
  String get unknownError => 'Unknown error';

  @override
  String get yourStayCaps => 'YOUR STAY';

  @override
  String nightWord(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'nights',
      one: 'night',
    );
    return '$_temp0';
  }

  @override
  String get roomSubtotal => 'Room subtotal';

  @override
  String get taxes => 'Taxes';

  @override
  String get serviceFee => 'Service fee';

  @override
  String get noLongerAvailable => 'No longer available';

  @override
  String get guestDetails => 'Guest details';

  @override
  String get fullNameAsId => 'Full name (as on ID)';

  @override
  String get enterGuestName => 'Enter the guest name';

  @override
  String get email => 'Email';

  @override
  String get enterValidEmail => 'Enter a valid email';

  @override
  String get phoneOptional => 'Phone (optional)';

  @override
  String get specialRequestsOptional => 'Special requests (optional)';

  @override
  String get continueToPayment => 'Continue to payment';

  @override
  String get roomHeldNotice =>
      'Your room is held for a short time while you pay. A booking is only confirmed after payment is verified by the server.';

  @override
  String get payment => 'Payment';

  @override
  String get holdExpired => 'Hold expired';

  @override
  String roomHeldFor(String time) {
    return 'Room held for $time';
  }

  @override
  String get simulatedPaymentNotice =>
      'Simulated payment. This demo uses a mock payment provider: no card is charged and no real money moves. Choose an outcome to test how the booking reacts.';

  @override
  String referenceValue(String ref) {
    return 'Reference $ref';
  }

  @override
  String get amountDue => 'Amount due';

  @override
  String get payNowSimulate => 'Pay now (simulate success)';

  @override
  String get simulateDeclined => 'Simulate a declined card';

  @override
  String get payLater => 'Pay later from My bookings';

  @override
  String get checkoutTitle => 'Checkout';

  @override
  String get stepRoom => 'Room';

  @override
  String get stepDetails => 'Details';

  @override
  String get myBookings => 'My bookings';

  @override
  String get upcoming => 'Upcoming';

  @override
  String get pastAndCancelled => 'Past & cancelled';

  @override
  String get nothingHereYet => 'Nothing here yet';

  @override
  String get noUpcomingTrips => 'No upcoming trips';

  @override
  String get pastBookingsHint =>
      'Completed and cancelled bookings appear here.';

  @override
  String get nextAdventureHint => 'Your next adventure is one search away.';

  @override
  String get nights => 'Nights';

  @override
  String get reference => 'Reference';

  @override
  String get cancelBookingQ => 'Cancel this booking?';

  @override
  String get cancelFreeBody =>
      'You are within the free-cancellation window. The room will be released.';

  @override
  String get cancelFreePaidBody =>
      'You are within the free-cancellation window. A simulated refund will be recorded. The room will be released.';

  @override
  String get cancelNonRefundBody =>
      'The free-cancellation window has passed, so this booking is non-refundable. The room will be released.';

  @override
  String get cancelBooking => 'Cancel booking';

  @override
  String get bookingCancelled => 'Booking cancelled.';

  @override
  String get receiptCaps => 'RECEIPT';

  @override
  String paymentRefStatus(String ref, String status) {
    return 'Payment ref $ref · $status';
  }

  @override
  String get yourBooking => 'Your booking';

  @override
  String get room => 'Room';

  @override
  String get guest => 'Guest';

  @override
  String get payForBooking => 'Pay for this booking';

  @override
  String get receipt => 'Receipt';

  @override
  String get priceBreakdown => 'Price breakdown';

  @override
  String get cancellationPolicy => 'Cancellation policy';

  @override
  String freeCancellationUntil(String date) {
    return 'Free cancellation until $date';
  }

  @override
  String get statusHistory => 'Status history';

  @override
  String get payments => 'Payments';

  @override
  String get simulatedSuffix => ' (simulated)';

  @override
  String get youreBooked => 'You\'re booked!';

  @override
  String get paymentVerified =>
      'Payment verified by the server. Simulated payment: no real money moved.';

  @override
  String get tripsEyebrowCaps => 'TRIPS';

  @override
  String get tripsHero => 'Tell us where.\nWe build the days.';

  @override
  String get planWithAi => 'Plan with AI';

  @override
  String get planWithAiExample => '\"3 days in Kampot, relaxed, two kids\"';

  @override
  String get signInToSaveItineraries =>
      'Sign in to save itineraries and edit them any time.';

  @override
  String get startFromOne => 'Start from one';

  @override
  String get curatedJourneys => 'Curated journeys';

  @override
  String get plannerRules => 'Rules planner';

  @override
  String get plannerAi => 'AI-assisted';

  @override
  String get plannerManual => 'Manual';

  @override
  String get exKampot => 'Slow Kampot weekend';

  @override
  String get exAngkor => 'Angkor for photographers';

  @override
  String get exPhnomPenh => 'Phnom Penh on \$150';

  @override
  String get aiTripPlannerCaps => 'AI TRIP PLANNER';

  @override
  String get describeTrip => 'Describe the trip\nyou want.';

  @override
  String get plannerModeLlm =>
      'Language-model assisted, grounded in stored places';

  @override
  String get plannerModeRules =>
      'Built on stored places by a rules engine. Fast and never invents.';

  @override
  String get plannerHint =>
      'e.g. 5 days in Kampot and Siem Reap, 2 adults, \$300 total, love food and culture';

  @override
  String get planningYourDays => 'Planning your days…';

  @override
  String get createItinerary => 'Create itinerary';

  @override
  String get moreDetailPlease => 'A little more detail, please';

  @override
  String get destinationsICanPlan => 'DESTINATIONS I CAN PLAN';

  @override
  String get iUnderstood => 'I understood';

  @override
  String childrenSuffix(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count children',
      one: '1 child',
    );
    return ', $_temp0';
  }

  @override
  String budgetPerDayLabel(String amount) {
    return '$amount per day';
  }

  @override
  String budgetTotalLabel(String amount) {
    return '$amount total';
  }

  @override
  String get saveToMyTrips => 'Save to my trips';

  @override
  String get signInToSaveTrip => 'Sign in to save this trip';

  @override
  String dayN(int n) {
    return 'Day $n';
  }

  @override
  String stopsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stops',
      one: '1 stop',
    );
    return '$_temp0';
  }

  @override
  String get timeline => 'Timeline';

  @override
  String get routeMap => 'Route map';

  @override
  String regenerateDay(int n) {
    return 'Regenerate day $n';
  }

  @override
  String get noStopsYet => 'No stops yet';

  @override
  String get noStopsHint => 'This day has no suggestions.';

  @override
  String get dashedLineNote =>
      'The dashed line joins stops in order: straight lines, not driving directions.';

  @override
  String get budgetStay => 'Stay';

  @override
  String get budgetActivities => 'Activities';

  @override
  String get budgetFood => 'Food';

  @override
  String get budgetTransport => 'Transport';

  @override
  String get estimatedTotalCaps => 'ESTIMATED TOTAL';

  @override
  String withinBudget(String amount) {
    return 'Within your $amount budget';
  }

  @override
  String overBudget(String amount) {
    return 'Over your $amount budget';
  }

  @override
  String lodgingNights(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nights',
      one: '1 night',
    );
    return '$name · $_temp0';
  }

  @override
  String get assumptions => 'Assumptions';

  @override
  String minutesCompact(int minutes) {
    return '${minutes}m';
  }

  @override
  String travelMinutes(int minutes) {
    return '~$minutes min travel';
  }

  @override
  String get moveUp => 'Move up';

  @override
  String get moveDown => 'Move down';

  @override
  String get removeStop => 'Remove stop';

  @override
  String get copyToMyTrips => 'Copy to my trips';

  @override
  String estimateRecalculated(String amount) {
    return 'Estimate recalculated: $amount';
  }

  @override
  String get recalculate => 'Recalculate';

  @override
  String get deleteTripQ => 'Delete this trip?';

  @override
  String get deleteTripBody => 'This removes the itinerary from your account.';

  @override
  String get delete => 'Delete';

  @override
  String get addAStop => 'Add a stop';

  @override
  String get inTrip => 'In trip';

  @override
  String addToDay(int n) {
    return 'Add to day $n';
  }

  @override
  String get starterBestTime => 'Best time to go';

  @override
  String get starterGettingAround => 'Getting around';

  @override
  String get starterDailyBudget => 'Daily budget';

  @override
  String get starterWhatToEat => 'What to eat';

  @override
  String get starterTempleEtiquette => 'Temple etiquette';

  @override
  String get starterCancellation => 'Cancellation';

  @override
  String get somethingWentWrong => 'Something went wrong.';

  @override
  String get guideName => 'Wayfarer Guide';

  @override
  String get guideModeLlm => 'AI travel assistant · uses our guides';

  @override
  String get guideModeRules => 'Instant · answers from our guides';

  @override
  String get newChat => 'New chat';

  @override
  String get askMeAnything => 'Ask me anything\nabout your trip.';

  @override
  String get askIntro =>
      'Ask in your own words. I use WAYFARER\'s guides when they help and general travel knowledge when they don\'t, and I show my sources.';

  @override
  String get generalKnowledge => 'General travel knowledge';

  @override
  String get notInGuides => 'Not in approved guides';

  @override
  String planWithPlanner(String name) {
    return 'Plan $name with the AI planner';
  }

  @override
  String sourcesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sources',
      one: '1 source',
    );
    return '$_temp0';
  }

  @override
  String get demoContentSuffix => ' (demo content)';

  @override
  String get cardStay => 'STAY';

  @override
  String get cardPlace => 'PLACE';

  @override
  String get cardDestination => 'DESTINATION';

  @override
  String get askHint => 'Ask about a destination…';

  @override
  String get send => 'Send';

  @override
  String get checkYourEmail => 'Check your email';

  @override
  String verificationSent(String email) {
    return 'We sent a verification link to $email. Open it, then sign in.';
  }

  @override
  String get ok => 'OK';

  @override
  String get googleNotSetUp =>
      'Google sign-in is not set up yet. Use your email and password for now.';

  @override
  String get createAnAccountTitle => 'Create an\naccount';

  @override
  String get welcomeBack => 'Welcome\nback';

  @override
  String get signUpWithGoogle => 'Sign up with Google';

  @override
  String get signInWithGoogle => 'Sign in with Google';

  @override
  String get or => 'or';

  @override
  String get firstName => 'First name';

  @override
  String get lastName => 'Last name';

  @override
  String get required => 'Required';

  @override
  String get enterValidEmailAddress => 'Enter a valid email address';

  @override
  String get password => 'Password';

  @override
  String get passwordHelper => '10+ characters, with letters and a number';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get enterPassword => 'Enter your password';

  @override
  String get passwordRule => 'Use 10+ characters with letters and a number';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get createAccount => 'Create account';

  @override
  String get termsNotice =>
      'By creating an account you agree to the WAYFARER Terms of Service and Privacy Policy.';

  @override
  String get haveAccount => 'Have an account? ';

  @override
  String get newHere => 'New here? ';

  @override
  String get logInHere => 'Log in here';

  @override
  String get createAnAccount => 'Create an account';

  @override
  String get resetPassword => 'Reset password';

  @override
  String resetLinkSent(String email) {
    return 'If an account exists for $email, a reset link is on its way.';
  }

  @override
  String get sendResetLink => 'Send reset link';

  @override
  String get verifyEmailFirst =>
      'Please verify your email first. We just sent you a new link: open it, then sign in again.';

  @override
  String get authEmailInUse =>
      'An account with this email already exists. Try signing in instead.';

  @override
  String get authInvalidEmail => 'That email address does not look right.';

  @override
  String get authWeakPassword =>
      'Choose a stronger password: at least 10 characters with letters and a number.';

  @override
  String get authWrongCredentials => 'Email or password is incorrect.';

  @override
  String get authDisabled => 'This account has been disabled. Contact support.';

  @override
  String get authTooMany =>
      'Too many attempts. Please wait a few minutes and try again.';

  @override
  String get authNetwork => 'No connection. Check your internet and try again.';

  @override
  String get authNotAllowed =>
      'This sign-in method is not turned on in Firebase yet.';

  @override
  String get authOtherMethod =>
      'This email is already used with another sign-in method.';

  @override
  String authFailed(String code) {
    return 'Sign-in failed ($code). Please try again.';
  }

  @override
  String get displayCurrency => 'Display currency';

  @override
  String get currencyNote =>
      'Prices are stored in USD and converted with documented sample rates, not live market rates.';

  @override
  String get accountHero => 'Your travel\nlife, in one place.';

  @override
  String get accountSignInHint =>
      'Sign in to see bookings, saved trips and your wishlist.';

  @override
  String get myBookingsSub => 'Tickets, cancellation and receipts';

  @override
  String get wishlist => 'Wishlist';

  @override
  String get wishlistSub => 'Saved destinations and stays';

  @override
  String get notifications => 'Notifications';

  @override
  String get notificationsSub => 'Booking and payment updates';

  @override
  String get exploreMap => 'Explore map';

  @override
  String get exploreMapSub => 'Destinations and stays near you';

  @override
  String get administrationSub =>
      'Overview, bookings, payments, reviews, audit log';

  @override
  String get partnerPortalSub => 'Your properties, bookings and availability';

  @override
  String get signOut => 'Sign out';

  @override
  String get deleteMyAccount => 'Delete my account';

  @override
  String get deleteAccountQ => 'Delete your account?';

  @override
  String get deleteAccountBody =>
      'Your profile is anonymised and you will be signed out. Active bookings must be cancelled first. This cannot be undone.';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get keepAccount => 'Keep account';

  @override
  String get nothingSavedYet => 'Nothing saved yet';

  @override
  String get nothingSavedHint =>
      'Tap the heart on a destination or stay to keep it here.';

  @override
  String get savedItem => 'Saved item';

  @override
  String get stay => 'Stay';

  @override
  String get markAllRead => 'Mark all read';

  @override
  String get allCaughtUp => 'You\'re all caught up';

  @override
  String get inAppOnlyNote =>
      'In-app notifications only. Push delivery needs Firebase credentials and is not configured.';

  @override
  String get language => 'Language';

  @override
  String get languageSub => 'English or Khmer';

  @override
  String get languageSystem => 'Phone setting';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageKhmer => 'ភាសាខ្មែរ';

  @override
  String get languageNote =>
      'Places, descriptions and AI answers come from our database and are in English.';

  @override
  String get settings => 'Settings';

  @override
  String get currency => 'Currency';

  @override
  String get join => 'Join';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get roleStaff => 'Staff';

  @override
  String get rolePartner => 'Partner';

  @override
  String get roleCustomer => 'Traveller';

  @override
  String get adminOverview => 'Overview';

  @override
  String get adminBookings => 'Bookings';

  @override
  String get adminPayments => 'Payments';

  @override
  String get adminUsers => 'Users';

  @override
  String get adminReviews => 'Reviews';

  @override
  String get adminAuditLog => 'Audit log';

  @override
  String get adminContent => 'Content';

  @override
  String get adminAccessRequired => 'Admin access required';

  @override
  String get adminAccessHint =>
      'This area is only available to staff and administrators. Access is enforced by the server.';

  @override
  String totalCount(int count) {
    return '$count total';
  }

  @override
  String get previousPage => 'Previous page';

  @override
  String get nextPage => 'Next page';

  @override
  String get simulatedNetRevenue => 'simulated net revenue';

  @override
  String get bookingsByStatus => 'Bookings by status';

  @override
  String get aiUsage => 'AI usage';

  @override
  String get noAiCalls => 'No AI calls recorded yet.';

  @override
  String aiCallsAvg(String calls, String ms) {
    return '$calls calls · avg $ms ms';
  }

  @override
  String get searchBookingsHint => 'Reference, guest, email';

  @override
  String get demoSuffix => ' · demo';

  @override
  String get actions => 'Actions';

  @override
  String cancelBookingRef(String ref) {
    return 'Cancel booking $ref?';
  }

  @override
  String get adminCancelBody =>
      'The room is released and the guest is notified. Refund rules follow the booking policy.';

  @override
  String get markCheckedIn => 'Mark checked in';

  @override
  String get markCompleted => 'Mark completed';

  @override
  String get bookingDetail => 'Booking detail';

  @override
  String get paymentsAndTransactions => 'Payments and transactions';

  @override
  String get nameOrEmail => 'Name or email';

  @override
  String get demoAccountSuffix => ' · demo account';

  @override
  String get changeRoleQ => 'Change role?';

  @override
  String changeRoleBody(String email, String role) {
    return 'Set $email to \"$role\". This changes what the account can do.';
  }

  @override
  String get changeRole => 'Change role';

  @override
  String get reviewModeration => 'Review moderation';

  @override
  String get hide => 'Hide';

  @override
  String get publish => 'Publish';

  @override
  String get system => 'system';

  @override
  String numberBetween(String lo, String hi) {
    return 'Enter a number between $lo and $hi';
  }

  @override
  String get createDestination => 'Create destination';

  @override
  String get name => 'Name';

  @override
  String get atLeast2Chars => 'At least 2 characters';

  @override
  String get country => 'Country';

  @override
  String get shortDescription => 'Short description (10+ chars)';

  @override
  String get atLeast10CharsShort => 'At least 10 characters';

  @override
  String get longDescription => 'Long description (20+ chars)';

  @override
  String get atLeast20Chars => 'At least 20 characters';

  @override
  String get latitude => 'Latitude';

  @override
  String get longitude => 'Longitude';

  @override
  String get dailyBudgetUsd => 'Daily budget (USD)';

  @override
  String get destinationCreated => 'Destination created and audited.';

  @override
  String get adminHotelsNote =>
      'Hotels, rooms, prices and stock are managed by each partner in the web Partner dashboard (/partner). Administrators can browse them in the web Admin console (/admin).';

  @override
  String get partnerAccessRequired => 'Partner access required';

  @override
  String get partnerAccessHint =>
      'Only partner accounts can manage properties. Access is enforced by the server.';

  @override
  String get occupancyNext30 => 'occupancy, next 30 days';

  @override
  String get notApplicable => 'n/a';

  @override
  String get yourProperties => 'Your properties';

  @override
  String get noPropertiesAssigned =>
      'No properties assigned to this partner account';

  @override
  String baseRooms(String price, String count) {
    return '$price base · $count rooms';
  }

  @override
  String get availability => 'Availability';

  @override
  String get incomingBookings => 'Incoming bookings';

  @override
  String get checkInAction => 'Check in';

  @override
  String get complete => 'Complete';

  @override
  String availabilityFor(String name) {
    return 'Availability: $name';
  }

  @override
  String roomsAvailablePerNight(String max) {
    return 'Rooms available per night (0–$max)';
  }

  @override
  String get nightlyPriceOptional => 'Nightly price USD (optional)';

  @override
  String get availabilityUpdated => 'Availability updated';

  @override
  String get offlineMessage =>
      'You appear to be offline, or the server is unreachable.';

  @override
  String get timeoutMessage =>
      'The server took too long to respond. Check your connection and try again.';

  @override
  String get quickPlaces => 'Places';

  @override
  String get quickThingsToDo => 'Things to do';

  @override
  String get saveAsPdf => 'Save as PDF';

  @override
  String get preparingPdf => 'Preparing your PDF…';

  @override
  String get pdfFailed => 'Could not create the PDF. Please try again.';

  @override
  String get pdfBrandLine => 'WAYFARER · TRIP ITINERARY';

  @override
  String pdfCreatedOn(String date) {
    return 'Created on $date';
  }

  @override
  String pdfDayTitle(int n) {
    return 'Day $n';
  }

  @override
  String get back => 'Back';

  @override
  String get exKohRong => 'Koh Rong island escape';

  @override
  String get exMondulkiri => 'Mondulkiri nature';

  @override
  String get exBattambang => 'Battambang food & culture';

  @override
  String get fontCredit => 'Khmer typeface: MiSans Khmer by Xiaomi';

  @override
  String dayInCity(int n, String city) {
    return 'Day $n · $city';
  }

  @override
  String transferFromCity(String city) {
    return 'Transfer from $city';
  }

  @override
  String transferInfo(String km, String time, String price) {
    return 'About $km km by road · $time · $price (estimate)';
  }

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String durationHours(int hours) {
    return '$hours h';
  }

  @override
  String get exTwoCities => 'Kampot + Siem Reap';
}
