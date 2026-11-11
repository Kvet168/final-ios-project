import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_km.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('km'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'WAYFARER'**
  String get appName;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Travel, planned beautifully'**
  String get tagline;

  /// No description provided for @splashLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading WAYFARER'**
  String get splashLoading;

  /// No description provided for @splashReady.
  ///
  /// In en, this message translates to:
  /// **'Getting things ready'**
  String get splashReady;

  /// No description provided for @splashSlow.
  ///
  /// In en, this message translates to:
  /// **'Waking the server, this can take a moment'**
  String get splashSlow;

  /// No description provided for @tabDiscover.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get tabDiscover;

  /// No description provided for @tabStays.
  ///
  /// In en, this message translates to:
  /// **'Stays'**
  String get tabStays;

  /// No description provided for @tabTrips.
  ///
  /// In en, this message translates to:
  /// **'Trips'**
  String get tabTrips;

  /// No description provided for @tabMe.
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get tabMe;

  /// No description provided for @askAiGuide.
  ///
  /// In en, this message translates to:
  /// **'Ask the AI travel guide'**
  String get askAiGuide;

  /// No description provided for @administration.
  ///
  /// In en, this message translates to:
  /// **'Administration'**
  String get administration;

  /// No description provided for @partnerPortal.
  ///
  /// In en, this message translates to:
  /// **'Partner portal'**
  String get partnerPortal;

  /// No description provided for @pageNotFound.
  ///
  /// In en, this message translates to:
  /// **'We could not find that page'**
  String get pageNotFound;

  /// No description provided for @backToDiscover.
  ///
  /// In en, this message translates to:
  /// **'Back to Discover'**
  String get backToDiscover;

  /// No description provided for @welcome1Eyebrow.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get welcome1Eyebrow;

  /// No description provided for @welcome1Title.
  ///
  /// In en, this message translates to:
  /// **'Cambodia,'**
  String get welcome1Title;

  /// No description provided for @welcome1Italic.
  ///
  /// In en, this message translates to:
  /// **'close up'**
  String get welcome1Italic;

  /// No description provided for @welcome1Body.
  ///
  /// In en, this message translates to:
  /// **'Twelve destinations, hundreds of places and stays, from Angkor at sunrise to the islands of Koh Rong.'**
  String get welcome1Body;

  /// No description provided for @welcome2Eyebrow.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get welcome2Eyebrow;

  /// No description provided for @welcome2Title.
  ///
  /// In en, this message translates to:
  /// **'Trips that build'**
  String get welcome2Title;

  /// No description provided for @welcome2Italic.
  ///
  /// In en, this message translates to:
  /// **'themselves'**
  String get welcome2Italic;

  /// No description provided for @welcome2Body.
  ///
  /// In en, this message translates to:
  /// **'Tell the AI planner where, how long and what you love. It lays out every day on real, stored places.'**
  String get welcome2Body;

  /// No description provided for @welcome3Eyebrow.
  ///
  /// In en, this message translates to:
  /// **'Go'**
  String get welcome3Eyebrow;

  /// No description provided for @welcome3Title.
  ///
  /// In en, this message translates to:
  /// **'Book it,'**
  String get welcome3Title;

  /// No description provided for @welcome3Italic.
  ///
  /// In en, this message translates to:
  /// **'carry it'**
  String get welcome3Italic;

  /// No description provided for @welcome3Body.
  ///
  /// In en, this message translates to:
  /// **'Reserve rooms with clear policies, keep tickets in your pocket and ask the guide anything on the way.'**
  String get welcome3Body;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @startExploring.
  ///
  /// In en, this message translates to:
  /// **'Start exploring'**
  String get startExploring;

  /// No description provided for @fromPerDay.
  ///
  /// In en, this message translates to:
  /// **'from {price} / day'**
  String fromPerDay(String price);

  /// No description provided for @priceForNights.
  ///
  /// In en, this message translates to:
  /// **'{price} for {nights, plural, =1{1 night} other{{nights} nights}}'**
  String priceForNights(String price, int nights);

  /// No description provided for @perNight.
  ///
  /// In en, this message translates to:
  /// **'/ night'**
  String get perNight;

  /// No description provided for @kmAway.
  ///
  /// In en, this message translates to:
  /// **'{distance} km away'**
  String kmAway(String distance);

  /// No description provided for @photoFor.
  ///
  /// In en, this message translates to:
  /// **'Photo for {name}'**
  String photoFor(String name);

  /// No description provided for @perkFreeCancellation.
  ///
  /// In en, this message translates to:
  /// **'Free cancellation'**
  String get perkFreeCancellation;

  /// No description provided for @perkBreakfast.
  ///
  /// In en, this message translates to:
  /// **'Breakfast'**
  String get perkBreakfast;

  /// No description provided for @perkFamily.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get perkFamily;

  /// No description provided for @typeHotel.
  ///
  /// In en, this message translates to:
  /// **'Hotel'**
  String get typeHotel;

  /// No description provided for @typeGuesthouse.
  ///
  /// In en, this message translates to:
  /// **'Guesthouse'**
  String get typeGuesthouse;

  /// No description provided for @typeResort.
  ///
  /// In en, this message translates to:
  /// **'Resort'**
  String get typeResort;

  /// No description provided for @typeHostel.
  ///
  /// In en, this message translates to:
  /// **'Hostel'**
  String get typeHostel;

  /// No description provided for @typeBoutique.
  ///
  /// In en, this message translates to:
  /// **'Boutique hotel'**
  String get typeBoutique;

  /// No description provided for @typeVilla.
  ///
  /// In en, this message translates to:
  /// **'Villa'**
  String get typeVilla;

  /// No description provided for @typeApartment.
  ///
  /// In en, this message translates to:
  /// **'Apartment'**
  String get typeApartment;

  /// No description provided for @typeBungalow.
  ///
  /// In en, this message translates to:
  /// **'Bungalow'**
  String get typeBungalow;

  /// No description provided for @catTemple.
  ///
  /// In en, this message translates to:
  /// **'Temple'**
  String get catTemple;

  /// No description provided for @catMuseum.
  ///
  /// In en, this message translates to:
  /// **'Museum'**
  String get catMuseum;

  /// No description provided for @catMarket.
  ///
  /// In en, this message translates to:
  /// **'Market'**
  String get catMarket;

  /// No description provided for @catNature.
  ///
  /// In en, this message translates to:
  /// **'Nature'**
  String get catNature;

  /// No description provided for @catBeach.
  ///
  /// In en, this message translates to:
  /// **'Beach'**
  String get catBeach;

  /// No description provided for @catFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get catFood;

  /// No description provided for @catCafe.
  ///
  /// In en, this message translates to:
  /// **'Cafe'**
  String get catCafe;

  /// No description provided for @catCulture.
  ///
  /// In en, this message translates to:
  /// **'Culture'**
  String get catCulture;

  /// No description provided for @catTour.
  ///
  /// In en, this message translates to:
  /// **'Tour'**
  String get catTour;

  /// No description provided for @catOutdoor.
  ///
  /// In en, this message translates to:
  /// **'Outdoor'**
  String get catOutdoor;

  /// No description provided for @catFamily.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get catFamily;

  /// No description provided for @catLandmark.
  ///
  /// In en, this message translates to:
  /// **'Landmark'**
  String get catLandmark;

  /// No description provided for @catHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get catHistory;

  /// No description provided for @catRestaurant.
  ///
  /// In en, this message translates to:
  /// **'Restaurant'**
  String get catRestaurant;

  /// No description provided for @catActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get catActivity;

  /// No description provided for @catAttraction.
  ///
  /// In en, this message translates to:
  /// **'Attraction'**
  String get catAttraction;

  /// No description provided for @tagTemples.
  ///
  /// In en, this message translates to:
  /// **'Temples'**
  String get tagTemples;

  /// No description provided for @tagRelaxed.
  ///
  /// In en, this message translates to:
  /// **'Relaxed'**
  String get tagRelaxed;

  /// No description provided for @tagCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get tagCity;

  /// No description provided for @tagIslands.
  ///
  /// In en, this message translates to:
  /// **'Islands'**
  String get tagIslands;

  /// No description provided for @free.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get free;

  /// No description provided for @minutesShort.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String minutesShort(int minutes);

  /// No description provided for @saveToWishlist.
  ///
  /// In en, this message translates to:
  /// **'Save to wishlist'**
  String get saveToWishlist;

  /// No description provided for @removeFromWishlist.
  ///
  /// In en, this message translates to:
  /// **'Remove from wishlist'**
  String get removeFromWishlist;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;

  /// No description provided for @genericError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get genericError;

  /// No description provided for @noConnection.
  ///
  /// In en, this message translates to:
  /// **'No connection'**
  String get noConnection;

  /// No description provided for @didntLoad.
  ///
  /// In en, this message translates to:
  /// **'That didn\'t load'**
  String get didntLoad;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @demoListing.
  ///
  /// In en, this message translates to:
  /// **'Demo listing'**
  String get demoListing;

  /// No description provided for @demoTooltip.
  ///
  /// In en, this message translates to:
  /// **'Educational sample data: not a real commercial offer'**
  String get demoTooltip;

  /// No description provided for @ratingNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get ratingNew;

  /// No description provided for @starProperty.
  ///
  /// In en, this message translates to:
  /// **'{stars} star property'**
  String starProperty(int stars);

  /// No description provided for @stayCardSemantics.
  ///
  /// In en, this message translates to:
  /// **'{name}, {stars} star {type}'**
  String stayCardSemantics(String name, int stars, String type);

  /// No description provided for @statusConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get statusConfirmed;

  /// No description provided for @statusAwaitingPayment.
  ///
  /// In en, this message translates to:
  /// **'Awaiting payment'**
  String get statusAwaitingPayment;

  /// No description provided for @statusCheckedIn.
  ///
  /// In en, this message translates to:
  /// **'Checked in'**
  String get statusCheckedIn;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @statusExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get statusExpired;

  /// No description provided for @statusRefundPending.
  ///
  /// In en, this message translates to:
  /// **'Refund pending'**
  String get statusRefundPending;

  /// No description provided for @statusRefunded.
  ///
  /// In en, this message translates to:
  /// **'Refunded'**
  String get statusRefunded;

  /// No description provided for @statusDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get statusDraft;

  /// No description provided for @statusPaidSimulated.
  ///
  /// In en, this message translates to:
  /// **'Paid (simulated)'**
  String get statusPaidSimulated;

  /// No description provided for @statusPaymentFailed.
  ///
  /// In en, this message translates to:
  /// **'Payment failed'**
  String get statusPaymentFailed;

  /// No description provided for @statusPaymentPending.
  ///
  /// In en, this message translates to:
  /// **'Payment pending'**
  String get statusPaymentPending;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @keep.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get keep;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @greetingNight.
  ///
  /// In en, this message translates to:
  /// **'Late night wanderer'**
  String get greetingNight;

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get greetingEvening;

  /// No description provided for @greetingWithName.
  ///
  /// In en, this message translates to:
  /// **'{greeting}, {name}'**
  String greetingWithName(String greeting, String name);

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @heroLine1.
  ///
  /// In en, this message translates to:
  /// **'Where will you'**
  String get heroLine1;

  /// No description provided for @heroLine2.
  ///
  /// In en, this message translates to:
  /// **'wander next?'**
  String get heroLine2;

  /// No description provided for @searchStays.
  ///
  /// In en, this message translates to:
  /// **'Search stays'**
  String get searchStays;

  /// No description provided for @findYourStay.
  ///
  /// In en, this message translates to:
  /// **'Find your stay'**
  String get findYourStay;

  /// No description provided for @anywhereAnyDates.
  ///
  /// In en, this message translates to:
  /// **'Anywhere · Any dates · Any guests'**
  String get anywhereAnyDates;

  /// No description provided for @quickAiPlanner.
  ///
  /// In en, this message translates to:
  /// **'AI planner'**
  String get quickAiPlanner;

  /// No description provided for @quickDayByDay.
  ///
  /// In en, this message translates to:
  /// **'Day-by-day'**
  String get quickDayByDay;

  /// No description provided for @quickAskGuide.
  ///
  /// In en, this message translates to:
  /// **'Ask guide'**
  String get quickAskGuide;

  /// No description provided for @quickInstantAnswers.
  ///
  /// In en, this message translates to:
  /// **'Instant answers'**
  String get quickInstantAnswers;

  /// No description provided for @quickMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get quickMap;

  /// No description provided for @quickNearYou.
  ///
  /// In en, this message translates to:
  /// **'Near you'**
  String get quickNearYou;

  /// No description provided for @recentlyViewed.
  ///
  /// In en, this message translates to:
  /// **'Recently viewed'**
  String get recentlyViewed;

  /// No description provided for @pickUpWhereLeft.
  ///
  /// In en, this message translates to:
  /// **'Pick up where you left off'**
  String get pickUpWhereLeft;

  /// No description provided for @featured.
  ///
  /// In en, this message translates to:
  /// **'Featured'**
  String get featured;

  /// No description provided for @destinationsWeLove.
  ///
  /// In en, this message translates to:
  /// **'Destinations we love'**
  String get destinationsWeLove;

  /// No description provided for @explore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get explore;

  /// No description provided for @browseByMood.
  ///
  /// In en, this message translates to:
  /// **'Browse by mood'**
  String get browseByMood;

  /// No description provided for @topRated.
  ///
  /// In en, this message translates to:
  /// **'Top rated'**
  String get topRated;

  /// No description provided for @staysWorthTrip.
  ///
  /// In en, this message translates to:
  /// **'Stays worth the trip'**
  String get staysWorthTrip;

  /// No description provided for @browse.
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get browse;

  /// No description provided for @itineraries.
  ///
  /// In en, this message translates to:
  /// **'Itineraries'**
  String get itineraries;

  /// No description provided for @readyMadeJourneys.
  ///
  /// In en, this message translates to:
  /// **'Ready-made journeys'**
  String get readyMadeJourneys;

  /// No description provided for @planYours.
  ///
  /// In en, this message translates to:
  /// **'Plan yours'**
  String get planYours;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get thisWeek;

  /// No description provided for @trendingNow.
  ///
  /// In en, this message translates to:
  /// **'Trending now'**
  String get trendingNow;

  /// No description provided for @statDestinations.
  ///
  /// In en, this message translates to:
  /// **'Destinations'**
  String get statDestinations;

  /// No description provided for @statPlaces.
  ///
  /// In en, this message translates to:
  /// **'Places'**
  String get statPlaces;

  /// No description provided for @statStays.
  ///
  /// In en, this message translates to:
  /// **'Stays'**
  String get statStays;

  /// No description provided for @daysCount.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{1 day} other{{days} days}}'**
  String daysCount(int days);

  /// No description provided for @estimatedTotal.
  ///
  /// In en, this message translates to:
  /// **'Est. {amount}'**
  String estimatedTotal(String amount);

  /// No description provided for @destinationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Destinations'**
  String get destinationsTitle;

  /// No description provided for @sort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sort;

  /// No description provided for @sortPopular.
  ///
  /// In en, this message translates to:
  /// **'Most popular'**
  String get sortPopular;

  /// No description provided for @sortNameAZ.
  ///
  /// In en, this message translates to:
  /// **'Name A–Z'**
  String get sortNameAZ;

  /// No description provided for @sortBudgetLow.
  ///
  /// In en, this message translates to:
  /// **'Budget: low to high'**
  String get sortBudgetLow;

  /// No description provided for @sortBudgetHigh.
  ///
  /// In en, this message translates to:
  /// **'Budget: high to low'**
  String get sortBudgetHigh;

  /// No description provided for @searchDestinations.
  ///
  /// In en, this message translates to:
  /// **'Search destinations'**
  String get searchDestinations;

  /// No description provided for @noDestinationsMatch.
  ///
  /// In en, this message translates to:
  /// **'No destinations match'**
  String get noDestinationsMatch;

  /// No description provided for @noDestinationsHint.
  ///
  /// In en, this message translates to:
  /// **'Try removing a filter or searching for a different name.'**
  String get noDestinationsHint;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get clearFilters;

  /// No description provided for @destinationsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 destination} other{{count} destinations}}'**
  String destinationsCount(int count);

  /// No description provided for @photoOf.
  ///
  /// In en, this message translates to:
  /// **'Photo of {name}'**
  String photoOf(String name);

  /// No description provided for @photoIndex.
  ///
  /// In en, this message translates to:
  /// **'{index} / {total}'**
  String photoIndex(int index, int total);

  /// No description provided for @budgetPerDay.
  ///
  /// In en, this message translates to:
  /// **'~{amount} / day'**
  String budgetPerDay(String amount);

  /// No description provided for @showLess.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get showLess;

  /// No description provided for @readMore.
  ///
  /// In en, this message translates to:
  /// **'Read more'**
  String get readMore;

  /// No description provided for @thingsToDo.
  ///
  /// In en, this message translates to:
  /// **'Things to do and eat'**
  String get thingsToDo;

  /// No description provided for @kindAttractions.
  ///
  /// In en, this message translates to:
  /// **'Attractions'**
  String get kindAttractions;

  /// No description provided for @kindActivities.
  ///
  /// In en, this message translates to:
  /// **'Activities'**
  String get kindActivities;

  /// No description provided for @kindRestaurants.
  ///
  /// In en, this message translates to:
  /// **'Restaurants'**
  String get kindRestaurants;

  /// No description provided for @nothingListed.
  ///
  /// In en, this message translates to:
  /// **'Nothing listed yet'**
  String get nothingListed;

  /// No description provided for @nothingListedHint.
  ///
  /// In en, this message translates to:
  /// **'We have no places of this type for this destination.'**
  String get nothingListedHint;

  /// No description provided for @showAllCount.
  ///
  /// In en, this message translates to:
  /// **'Show all {count}'**
  String showAllCount(int count);

  /// No description provided for @staysEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Stays'**
  String get staysEyebrow;

  /// No description provided for @whereToStay.
  ///
  /// In en, this message translates to:
  /// **'Where to stay'**
  String get whereToStay;

  /// No description provided for @keepGoing.
  ///
  /// In en, this message translates to:
  /// **'Keep going'**
  String get keepGoing;

  /// No description provided for @nearbyAndRelated.
  ///
  /// In en, this message translates to:
  /// **'Nearby and related'**
  String get nearbyAndRelated;

  /// No description provided for @kmShort.
  ///
  /// In en, this message translates to:
  /// **'{distance} km'**
  String kmShort(String distance);

  /// No description provided for @readAndAsk.
  ///
  /// In en, this message translates to:
  /// **'Read & ask'**
  String get readAndAsk;

  /// No description provided for @travelGuides.
  ///
  /// In en, this message translates to:
  /// **'Travel guides'**
  String get travelGuides;

  /// No description provided for @findStays.
  ///
  /// In en, this message translates to:
  /// **'Find stays'**
  String get findStays;

  /// No description provided for @planTrip.
  ///
  /// In en, this message translates to:
  /// **'Plan trip'**
  String get planTrip;

  /// No description provided for @indicative.
  ///
  /// In en, this message translates to:
  /// **'(indicative)'**
  String get indicative;

  /// No description provided for @familyFriendly.
  ///
  /// In en, this message translates to:
  /// **'Family friendly'**
  String get familyFriendly;

  /// No description provided for @directions.
  ///
  /// In en, this message translates to:
  /// **'Directions'**
  String get directions;

  /// No description provided for @destination.
  ///
  /// In en, this message translates to:
  /// **'Destination'**
  String get destination;

  /// No description provided for @placesTitle.
  ///
  /// In en, this message translates to:
  /// **'Places'**
  String get placesTitle;

  /// No description provided for @searchPlacesHint.
  ///
  /// In en, this message translates to:
  /// **'Search places, e.g. Angkor, market, museum'**
  String get searchPlacesHint;

  /// No description provided for @placesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 place} other{{count} places}}'**
  String placesCount(int count);

  /// No description provided for @noPlacesMatch.
  ///
  /// In en, this message translates to:
  /// **'No places match'**
  String get noPlacesMatch;

  /// No description provided for @noPlacesHint.
  ///
  /// In en, this message translates to:
  /// **'Try a different category or search term.'**
  String get noPlacesHint;

  /// No description provided for @locationOff.
  ///
  /// In en, this message translates to:
  /// **'Location services are turned off on this device.'**
  String get locationOff;

  /// No description provided for @locationDeclined.
  ///
  /// In en, this message translates to:
  /// **'Location permission was declined. You can still explore the map and search by destination.'**
  String get locationDeclined;

  /// No description provided for @locationBlocked.
  ///
  /// In en, this message translates to:
  /// **'Location permission is blocked. Enable it in your device settings to use this feature.'**
  String get locationBlocked;

  /// No description provided for @locationFailed.
  ///
  /// In en, this message translates to:
  /// **'We could not get your location ({reason}).'**
  String locationFailed(String reason);

  /// No description provided for @locationTimeout.
  ///
  /// In en, this message translates to:
  /// **'timeout or unsupported'**
  String get locationTimeout;

  /// No description provided for @perNightKmAway.
  ///
  /// In en, this message translates to:
  /// **'{price} / night · {distance} km away'**
  String perNightKmAway(String price, String distance);

  /// No description provided for @youAreHere.
  ///
  /// In en, this message translates to:
  /// **'You are here'**
  String get youAreHere;

  /// No description provided for @nearMe.
  ///
  /// In en, this message translates to:
  /// **'Near me'**
  String get nearMe;

  /// No description provided for @staysNearYou.
  ///
  /// In en, this message translates to:
  /// **'Stays near you'**
  String get staysNearYou;

  /// No description provided for @noStaysNearby.
  ///
  /// In en, this message translates to:
  /// **'No stays within 60 km. Our listings cover specific destinations; explore one instead.'**
  String get noStaysNearby;

  /// No description provided for @noLocations.
  ///
  /// In en, this message translates to:
  /// **'No locations to show'**
  String get noLocations;

  /// No description provided for @directionsInMaps.
  ///
  /// In en, this message translates to:
  /// **'Directions in maps app'**
  String get directionsInMaps;

  /// No description provided for @showResults.
  ///
  /// In en, this message translates to:
  /// **'Show results'**
  String get showResults;

  /// No description provided for @anywhere.
  ///
  /// In en, this message translates to:
  /// **'Anywhere'**
  String get anywhere;

  /// No description provided for @anyDates.
  ///
  /// In en, this message translates to:
  /// **'Any dates'**
  String get anyDates;

  /// No description provided for @guestsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 guest} other{{count} guests}}'**
  String guestsCount(int count);

  /// No description provided for @roomsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 room} other{{count} rooms}}'**
  String roomsCount(int count);

  /// No description provided for @nightsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 night} other{{count} nights}}'**
  String nightsCount(int count);

  /// No description provided for @adultsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 adult} other{{count} adults}}'**
  String adultsCount(int count);

  /// No description provided for @childrenCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 child} other{{count} children}}'**
  String childrenCount(int count);

  /// No description provided for @staysEyebrowCaps.
  ///
  /// In en, this message translates to:
  /// **'STAYS'**
  String get staysEyebrowCaps;

  /// No description provided for @findPlaceToRest.
  ///
  /// In en, this message translates to:
  /// **'Find a place\nto rest'**
  String get findPlaceToRest;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @filtersActive.
  ///
  /// In en, this message translates to:
  /// **'Filters · {count}'**
  String filtersActive(int count);

  /// No description provided for @sortRecommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get sortRecommended;

  /// No description provided for @sortPriceLow.
  ///
  /// In en, this message translates to:
  /// **'Price: low to high'**
  String get sortPriceLow;

  /// No description provided for @sortPriceHigh.
  ///
  /// In en, this message translates to:
  /// **'Price: high to low'**
  String get sortPriceHigh;

  /// No description provided for @sortGuestRating.
  ///
  /// In en, this message translates to:
  /// **'Guest rating'**
  String get sortGuestRating;

  /// No description provided for @sortDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get sortDistance;

  /// No description provided for @sortPriceUp.
  ///
  /// In en, this message translates to:
  /// **'Price ↑'**
  String get sortPriceUp;

  /// No description provided for @sortPriceDown.
  ///
  /// In en, this message translates to:
  /// **'Price ↓'**
  String get sortPriceDown;

  /// No description provided for @sortNearest.
  ///
  /// In en, this message translates to:
  /// **'Nearest'**
  String get sortNearest;

  /// No description provided for @listView.
  ///
  /// In en, this message translates to:
  /// **'List view'**
  String get listView;

  /// No description provided for @mapView.
  ///
  /// In en, this message translates to:
  /// **'Map view'**
  String get mapView;

  /// No description provided for @searching.
  ///
  /// In en, this message translates to:
  /// **'Searching…'**
  String get searching;

  /// No description provided for @staysCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 stay} other{{count} stays}}'**
  String staysCount(int count);

  /// No description provided for @totalsShownForNights.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 night} other{{count} nights}}, totals shown'**
  String totalsShownForNights(int count);

  /// No description provided for @addDatesForAvailability.
  ///
  /// In en, this message translates to:
  /// **'add dates for real availability'**
  String get addDatesForAvailability;

  /// No description provided for @noStaysMatch.
  ///
  /// In en, this message translates to:
  /// **'No stays match'**
  String get noStaysMatch;

  /// No description provided for @noStaysDatesHint.
  ///
  /// In en, this message translates to:
  /// **'There may be no availability for these dates and guests. Try different dates, fewer filters or another destination.'**
  String get noStaysDatesHint;

  /// No description provided for @noStaysHint.
  ///
  /// In en, this message translates to:
  /// **'Try widening your price range or removing a filter.'**
  String get noStaysHint;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get clearAll;

  /// No description provided for @pricePerNightRange.
  ///
  /// In en, this message translates to:
  /// **'Price per night · {min} – {max}'**
  String pricePerNightRange(String min, String max);

  /// No description provided for @starRating.
  ///
  /// In en, this message translates to:
  /// **'Star rating'**
  String get starRating;

  /// No description provided for @guestRating.
  ///
  /// In en, this message translates to:
  /// **'Guest rating'**
  String get guestRating;

  /// No description provided for @propertyType.
  ///
  /// In en, this message translates to:
  /// **'Property type'**
  String get propertyType;

  /// No description provided for @popular.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get popular;

  /// No description provided for @breakfastAvailable.
  ///
  /// In en, this message translates to:
  /// **'Breakfast available'**
  String get breakfastAvailable;

  /// No description provided for @amenities.
  ///
  /// In en, this message translates to:
  /// **'Amenities'**
  String get amenities;

  /// No description provided for @realAvailability.
  ///
  /// In en, this message translates to:
  /// **'Real availability and total prices for your dates.'**
  String get realAvailability;

  /// No description provided for @selectCheckInOut.
  ///
  /// In en, this message translates to:
  /// **'Select check-in and check-out'**
  String get selectCheckInOut;

  /// No description provided for @fewer.
  ///
  /// In en, this message translates to:
  /// **'Fewer {label}'**
  String fewer(String label);

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More {label}'**
  String more(String label);

  /// No description provided for @adults.
  ///
  /// In en, this message translates to:
  /// **'Adults'**
  String get adults;

  /// No description provided for @adultsAge.
  ///
  /// In en, this message translates to:
  /// **'Age 13 or above'**
  String get adultsAge;

  /// No description provided for @children.
  ///
  /// In en, this message translates to:
  /// **'Children'**
  String get children;

  /// No description provided for @childrenAge.
  ///
  /// In en, this message translates to:
  /// **'Age 0 to 12'**
  String get childrenAge;

  /// No description provided for @rooms.
  ///
  /// In en, this message translates to:
  /// **'Rooms'**
  String get rooms;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @checkoutAfterCheckin.
  ///
  /// In en, this message translates to:
  /// **'Check-out must be after check-in'**
  String get checkoutAfterCheckin;

  /// No description provided for @addDates.
  ///
  /// In en, this message translates to:
  /// **'Add dates'**
  String get addDates;

  /// No description provided for @whereTo.
  ///
  /// In en, this message translates to:
  /// **'Where to?'**
  String get whereTo;

  /// No description provided for @whereToHint.
  ///
  /// In en, this message translates to:
  /// **'City, destination or hotel'**
  String get whereToHint;

  /// No description provided for @dates.
  ///
  /// In en, this message translates to:
  /// **'Dates'**
  String get dates;

  /// No description provided for @guests.
  ///
  /// In en, this message translates to:
  /// **'Guests'**
  String get guests;

  /// No description provided for @fieldValue.
  ///
  /// In en, this message translates to:
  /// **'{label}: {value}'**
  String fieldValue(String label, String value);

  /// No description provided for @photoNofM.
  ///
  /// In en, this message translates to:
  /// **'Photo {index} of {total} for {name}'**
  String photoNofM(int index, int total, String name);

  /// No description provided for @whatThisPlaceOffers.
  ///
  /// In en, this message translates to:
  /// **'What this place offers'**
  String get whatThisPlaceOffers;

  /// No description provided for @goodToKnow.
  ///
  /// In en, this message translates to:
  /// **'Good to know'**
  String get goodToKnow;

  /// No description provided for @cancellation.
  ///
  /// In en, this message translates to:
  /// **'Cancellation'**
  String get cancellation;

  /// No description provided for @checkIn.
  ///
  /// In en, this message translates to:
  /// **'Check-in'**
  String get checkIn;

  /// No description provided for @checkOut.
  ///
  /// In en, this message translates to:
  /// **'Check-out'**
  String get checkOut;

  /// No description provided for @fromTime.
  ///
  /// In en, this message translates to:
  /// **'From {time}'**
  String fromTime(String time);

  /// No description provided for @byTime.
  ///
  /// In en, this message translates to:
  /// **'By {time}'**
  String byTime(String time);

  /// No description provided for @taxesAndFees.
  ///
  /// In en, this message translates to:
  /// **'Taxes and fees'**
  String get taxesAndFees;

  /// No description provided for @taxesAndFeesBody.
  ///
  /// In en, this message translates to:
  /// **'{tax}% tax and {fee}% service fee are added to the room rate and shown before you pay.'**
  String taxesAndFeesBody(String tax, String fee);

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @chooseYourRoom.
  ///
  /// In en, this message translates to:
  /// **'Choose your room'**
  String get chooseYourRoom;

  /// No description provided for @similarStays.
  ///
  /// In en, this message translates to:
  /// **'Similar stays nearby'**
  String get similarStays;

  /// No description provided for @fromCaps.
  ///
  /// In en, this message translates to:
  /// **'FROM'**
  String get fromCaps;

  /// No description provided for @chooseARoom.
  ///
  /// In en, this message translates to:
  /// **'Choose a room'**
  String get chooseARoom;

  /// No description provided for @chooseYourDates.
  ///
  /// In en, this message translates to:
  /// **'Choose your dates'**
  String get chooseYourDates;

  /// No description provided for @nightsTapToChange.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 night} other{{count} nights}} · tap to change'**
  String nightsTapToChange(int count);

  /// No description provided for @tapToSelect.
  ///
  /// In en, this message translates to:
  /// **'Tap to select'**
  String get tapToSelect;

  /// No description provided for @removeRoom.
  ///
  /// In en, this message translates to:
  /// **'Remove a room'**
  String get removeRoom;

  /// No description provided for @addRoom.
  ///
  /// In en, this message translates to:
  /// **'Add a room'**
  String get addRoom;

  /// No description provided for @selectDates.
  ///
  /// In en, this message translates to:
  /// **'Select dates'**
  String get selectDates;

  /// No description provided for @tooSmallForParty.
  ///
  /// In en, this message translates to:
  /// **'Too small for your party'**
  String get tooSmallForParty;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get notAvailable;

  /// No description provided for @reserve.
  ///
  /// In en, this message translates to:
  /// **'Reserve'**
  String get reserve;

  /// No description provided for @basePerNight.
  ///
  /// In en, this message translates to:
  /// **'base / night'**
  String get basePerNight;

  /// No description provided for @upToAdults.
  ///
  /// In en, this message translates to:
  /// **'Up to {count, plural, =1{1 adult} other{{count} adults}}'**
  String upToAdults(int count);

  /// No description provided for @plusChildren.
  ///
  /// In en, this message translates to:
  /// **' + {count, plural, =1{1 child} other{{count} children}}'**
  String plusChildren(int count);

  /// No description provided for @breakfastIncluded.
  ///
  /// In en, this message translates to:
  /// **'Breakfast included'**
  String get breakfastIncluded;

  /// No description provided for @avgTimesNights.
  ///
  /// In en, this message translates to:
  /// **'{price} avg × {count, plural, =1{1 night} other{{count} nights}}'**
  String avgTimesNights(String price, int count);

  /// No description provided for @timesRooms.
  ///
  /// In en, this message translates to:
  /// **' × {count} rooms'**
  String timesRooms(int count);

  /// No description provided for @taxesPercent.
  ///
  /// In en, this message translates to:
  /// **'Taxes ({percent}%)'**
  String taxesPercent(String percent);

  /// No description provided for @serviceFeePercent.
  ///
  /// In en, this message translates to:
  /// **'Service fee ({percent}%)'**
  String serviceFeePercent(String percent);

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @guestReviews.
  ///
  /// In en, this message translates to:
  /// **'Guest reviews'**
  String get guestReviews;

  /// No description provided for @sampleDataDemo.
  ///
  /// In en, this message translates to:
  /// **'Sample data in this demo'**
  String get sampleDataDemo;

  /// No description provided for @writeOne.
  ///
  /// In en, this message translates to:
  /// **'Write one'**
  String get writeOne;

  /// No description provided for @noReviewsYet.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet'**
  String get noReviewsYet;

  /// No description provided for @beFirstReview.
  ///
  /// In en, this message translates to:
  /// **'Be the first to share your stay.'**
  String get beFirstReview;

  /// No description provided for @demoReview.
  ///
  /// In en, this message translates to:
  /// **'Demo review'**
  String get demoReview;

  /// No description provided for @verifiedStay.
  ///
  /// In en, this message translates to:
  /// **'Verified stay'**
  String get verifiedStay;

  /// No description provided for @writeAReview.
  ///
  /// In en, this message translates to:
  /// **'Write a review'**
  String get writeAReview;

  /// No description provided for @starsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 star} other{{count} stars}}'**
  String starsCount(int count);

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @addShortTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a short title'**
  String get addShortTitle;

  /// No description provided for @yourExperience.
  ///
  /// In en, this message translates to:
  /// **'Your experience'**
  String get yourExperience;

  /// No description provided for @atLeast10Chars.
  ///
  /// In en, this message translates to:
  /// **'Please write at least 10 characters'**
  String get atLeast10Chars;

  /// No description provided for @onlyGuestsCanReview.
  ///
  /// In en, this message translates to:
  /// **'Only guests with a confirmed booking can review a property.'**
  String get onlyGuestsCanReview;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @amenWifi.
  ///
  /// In en, this message translates to:
  /// **'Wi‑Fi'**
  String get amenWifi;

  /// No description provided for @amenPool.
  ///
  /// In en, this message translates to:
  /// **'Swimming pool'**
  String get amenPool;

  /// No description provided for @amenAc.
  ///
  /// In en, this message translates to:
  /// **'Air conditioning'**
  String get amenAc;

  /// No description provided for @amenBreakfast.
  ///
  /// In en, this message translates to:
  /// **'Breakfast'**
  String get amenBreakfast;

  /// No description provided for @amenParking.
  ///
  /// In en, this message translates to:
  /// **'Parking'**
  String get amenParking;

  /// No description provided for @amenShuttle.
  ///
  /// In en, this message translates to:
  /// **'Airport shuttle'**
  String get amenShuttle;

  /// No description provided for @amenGym.
  ///
  /// In en, this message translates to:
  /// **'Gym'**
  String get amenGym;

  /// No description provided for @amenSpa.
  ///
  /// In en, this message translates to:
  /// **'Spa'**
  String get amenSpa;

  /// No description provided for @amenRestaurant.
  ///
  /// In en, this message translates to:
  /// **'Restaurant'**
  String get amenRestaurant;

  /// No description provided for @amenFamilyRoom.
  ///
  /// In en, this message translates to:
  /// **'Family rooms'**
  String get amenFamilyRoom;

  /// No description provided for @amenKidsPool.
  ///
  /// In en, this message translates to:
  /// **'Kids\' pool'**
  String get amenKidsPool;

  /// No description provided for @amenAccessible.
  ///
  /// In en, this message translates to:
  /// **'Accessible'**
  String get amenAccessible;

  /// No description provided for @amenBar.
  ///
  /// In en, this message translates to:
  /// **'Bar'**
  String get amenBar;

  /// No description provided for @amenLaundry.
  ///
  /// In en, this message translates to:
  /// **'Laundry'**
  String get amenLaundry;

  /// No description provided for @amenKitchen.
  ///
  /// In en, this message translates to:
  /// **'Kitchen'**
  String get amenKitchen;

  /// No description provided for @bookingNotPayable.
  ///
  /// In en, this message translates to:
  /// **'This booking can no longer be paid.'**
  String get bookingNotPayable;

  /// No description provided for @paymentNotConfirmed.
  ///
  /// In en, this message translates to:
  /// **'{status} (simulated). Your booking is not confirmed — you can try again before the hold expires.'**
  String paymentNotConfirmed(String status);

  /// No description provided for @unknownError.
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get unknownError;

  /// No description provided for @yourStayCaps.
  ///
  /// In en, this message translates to:
  /// **'YOUR STAY'**
  String get yourStayCaps;

  /// No description provided for @nightWord.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{night} other{nights}}'**
  String nightWord(int count);

  /// No description provided for @roomSubtotal.
  ///
  /// In en, this message translates to:
  /// **'Room subtotal'**
  String get roomSubtotal;

  /// No description provided for @taxes.
  ///
  /// In en, this message translates to:
  /// **'Taxes'**
  String get taxes;

  /// No description provided for @serviceFee.
  ///
  /// In en, this message translates to:
  /// **'Service fee'**
  String get serviceFee;

  /// No description provided for @noLongerAvailable.
  ///
  /// In en, this message translates to:
  /// **'No longer available'**
  String get noLongerAvailable;

  /// No description provided for @guestDetails.
  ///
  /// In en, this message translates to:
  /// **'Guest details'**
  String get guestDetails;

  /// No description provided for @fullNameAsId.
  ///
  /// In en, this message translates to:
  /// **'Full name (as on ID)'**
  String get fullNameAsId;

  /// No description provided for @enterGuestName.
  ///
  /// In en, this message translates to:
  /// **'Enter the guest name'**
  String get enterGuestName;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @enterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get enterValidEmail;

  /// No description provided for @phoneOptional.
  ///
  /// In en, this message translates to:
  /// **'Phone (optional)'**
  String get phoneOptional;

  /// No description provided for @specialRequestsOptional.
  ///
  /// In en, this message translates to:
  /// **'Special requests (optional)'**
  String get specialRequestsOptional;

  /// No description provided for @continueToPayment.
  ///
  /// In en, this message translates to:
  /// **'Continue to payment'**
  String get continueToPayment;

  /// No description provided for @roomHeldNotice.
  ///
  /// In en, this message translates to:
  /// **'Your room is held for a short time while you pay. A booking is only confirmed after payment is verified by the server.'**
  String get roomHeldNotice;

  /// No description provided for @payment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get payment;

  /// No description provided for @holdExpired.
  ///
  /// In en, this message translates to:
  /// **'Hold expired'**
  String get holdExpired;

  /// No description provided for @roomHeldFor.
  ///
  /// In en, this message translates to:
  /// **'Room held for {time}'**
  String roomHeldFor(String time);

  /// No description provided for @simulatedPaymentNotice.
  ///
  /// In en, this message translates to:
  /// **'Simulated payment. This demo uses a mock payment provider: no card is charged and no real money moves. Choose an outcome to test how the booking reacts.'**
  String get simulatedPaymentNotice;

  /// No description provided for @referenceValue.
  ///
  /// In en, this message translates to:
  /// **'Reference {ref}'**
  String referenceValue(String ref);

  /// No description provided for @amountDue.
  ///
  /// In en, this message translates to:
  /// **'Amount due'**
  String get amountDue;

  /// No description provided for @payNowSimulate.
  ///
  /// In en, this message translates to:
  /// **'Pay now (simulate success)'**
  String get payNowSimulate;

  /// No description provided for @simulateDeclined.
  ///
  /// In en, this message translates to:
  /// **'Simulate a declined card'**
  String get simulateDeclined;

  /// No description provided for @payLater.
  ///
  /// In en, this message translates to:
  /// **'Pay later from My bookings'**
  String get payLater;

  /// No description provided for @checkoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get checkoutTitle;

  /// No description provided for @stepRoom.
  ///
  /// In en, this message translates to:
  /// **'Room'**
  String get stepRoom;

  /// No description provided for @stepDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get stepDetails;

  /// No description provided for @myBookings.
  ///
  /// In en, this message translates to:
  /// **'My bookings'**
  String get myBookings;

  /// No description provided for @upcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get upcoming;

  /// No description provided for @pastAndCancelled.
  ///
  /// In en, this message translates to:
  /// **'Past & cancelled'**
  String get pastAndCancelled;

  /// No description provided for @nothingHereYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get nothingHereYet;

  /// No description provided for @noUpcomingTrips.
  ///
  /// In en, this message translates to:
  /// **'No upcoming trips'**
  String get noUpcomingTrips;

  /// No description provided for @pastBookingsHint.
  ///
  /// In en, this message translates to:
  /// **'Completed and cancelled bookings appear here.'**
  String get pastBookingsHint;

  /// No description provided for @nextAdventureHint.
  ///
  /// In en, this message translates to:
  /// **'Your next adventure is one search away.'**
  String get nextAdventureHint;

  /// No description provided for @nights.
  ///
  /// In en, this message translates to:
  /// **'Nights'**
  String get nights;

  /// No description provided for @reference.
  ///
  /// In en, this message translates to:
  /// **'Reference'**
  String get reference;

  /// No description provided for @cancelBookingQ.
  ///
  /// In en, this message translates to:
  /// **'Cancel this booking?'**
  String get cancelBookingQ;

  /// No description provided for @cancelFreeBody.
  ///
  /// In en, this message translates to:
  /// **'You are within the free-cancellation window. The room will be released.'**
  String get cancelFreeBody;

  /// No description provided for @cancelFreePaidBody.
  ///
  /// In en, this message translates to:
  /// **'You are within the free-cancellation window. A simulated refund will be recorded. The room will be released.'**
  String get cancelFreePaidBody;

  /// No description provided for @cancelNonRefundBody.
  ///
  /// In en, this message translates to:
  /// **'The free-cancellation window has passed, so this booking is non-refundable. The room will be released.'**
  String get cancelNonRefundBody;

  /// No description provided for @cancelBooking.
  ///
  /// In en, this message translates to:
  /// **'Cancel booking'**
  String get cancelBooking;

  /// No description provided for @bookingCancelled.
  ///
  /// In en, this message translates to:
  /// **'Booking cancelled.'**
  String get bookingCancelled;

  /// No description provided for @receiptCaps.
  ///
  /// In en, this message translates to:
  /// **'RECEIPT'**
  String get receiptCaps;

  /// No description provided for @paymentRefStatus.
  ///
  /// In en, this message translates to:
  /// **'Payment ref {ref} · {status}'**
  String paymentRefStatus(String ref, String status);

  /// No description provided for @yourBooking.
  ///
  /// In en, this message translates to:
  /// **'Your booking'**
  String get yourBooking;

  /// No description provided for @room.
  ///
  /// In en, this message translates to:
  /// **'Room'**
  String get room;

  /// No description provided for @guest.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get guest;

  /// No description provided for @payForBooking.
  ///
  /// In en, this message translates to:
  /// **'Pay for this booking'**
  String get payForBooking;

  /// No description provided for @receipt.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get receipt;

  /// No description provided for @priceBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Price breakdown'**
  String get priceBreakdown;

  /// No description provided for @cancellationPolicy.
  ///
  /// In en, this message translates to:
  /// **'Cancellation policy'**
  String get cancellationPolicy;

  /// No description provided for @freeCancellationUntil.
  ///
  /// In en, this message translates to:
  /// **'Free cancellation until {date}'**
  String freeCancellationUntil(String date);

  /// No description provided for @statusHistory.
  ///
  /// In en, this message translates to:
  /// **'Status history'**
  String get statusHistory;

  /// No description provided for @payments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get payments;

  /// No description provided for @simulatedSuffix.
  ///
  /// In en, this message translates to:
  /// **' (simulated)'**
  String get simulatedSuffix;

  /// No description provided for @youreBooked.
  ///
  /// In en, this message translates to:
  /// **'You\'re booked!'**
  String get youreBooked;

  /// No description provided for @paymentVerified.
  ///
  /// In en, this message translates to:
  /// **'Payment verified by the server. Simulated payment: no real money moved.'**
  String get paymentVerified;

  /// No description provided for @tripsEyebrowCaps.
  ///
  /// In en, this message translates to:
  /// **'TRIPS'**
  String get tripsEyebrowCaps;

  /// No description provided for @tripsHero.
  ///
  /// In en, this message translates to:
  /// **'Tell us where.\nWe build the days.'**
  String get tripsHero;

  /// No description provided for @planWithAi.
  ///
  /// In en, this message translates to:
  /// **'Plan with AI'**
  String get planWithAi;

  /// No description provided for @planWithAiExample.
  ///
  /// In en, this message translates to:
  /// **'\"3 days in Kampot, relaxed, two kids\"'**
  String get planWithAiExample;

  /// No description provided for @signInToSaveItineraries.
  ///
  /// In en, this message translates to:
  /// **'Sign in to save itineraries and edit them any time.'**
  String get signInToSaveItineraries;

  /// No description provided for @startFromOne.
  ///
  /// In en, this message translates to:
  /// **'Start from one'**
  String get startFromOne;

  /// No description provided for @curatedJourneys.
  ///
  /// In en, this message translates to:
  /// **'Curated journeys'**
  String get curatedJourneys;

  /// No description provided for @plannerRules.
  ///
  /// In en, this message translates to:
  /// **'Rules planner'**
  String get plannerRules;

  /// No description provided for @plannerAi.
  ///
  /// In en, this message translates to:
  /// **'AI-assisted'**
  String get plannerAi;

  /// No description provided for @plannerManual.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get plannerManual;

  /// No description provided for @exKampot.
  ///
  /// In en, this message translates to:
  /// **'Slow Kampot weekend'**
  String get exKampot;

  /// No description provided for @exAngkor.
  ///
  /// In en, this message translates to:
  /// **'Angkor for photographers'**
  String get exAngkor;

  /// No description provided for @exPhnomPenh.
  ///
  /// In en, this message translates to:
  /// **'Phnom Penh on \$150'**
  String get exPhnomPenh;

  /// No description provided for @aiTripPlannerCaps.
  ///
  /// In en, this message translates to:
  /// **'AI TRIP PLANNER'**
  String get aiTripPlannerCaps;

  /// No description provided for @describeTrip.
  ///
  /// In en, this message translates to:
  /// **'Describe the trip\nyou want.'**
  String get describeTrip;

  /// No description provided for @plannerModeLlm.
  ///
  /// In en, this message translates to:
  /// **'Language-model assisted, grounded in stored places'**
  String get plannerModeLlm;

  /// No description provided for @plannerModeRules.
  ///
  /// In en, this message translates to:
  /// **'Built on stored places by a rules engine. Fast and never invents.'**
  String get plannerModeRules;

  /// No description provided for @plannerHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 5 days in Kampot and Siem Reap, 2 adults, \$300 total, love food and culture'**
  String get plannerHint;

  /// No description provided for @planningYourDays.
  ///
  /// In en, this message translates to:
  /// **'Planning your days…'**
  String get planningYourDays;

  /// No description provided for @createItinerary.
  ///
  /// In en, this message translates to:
  /// **'Create itinerary'**
  String get createItinerary;

  /// No description provided for @moreDetailPlease.
  ///
  /// In en, this message translates to:
  /// **'A little more detail, please'**
  String get moreDetailPlease;

  /// No description provided for @destinationsICanPlan.
  ///
  /// In en, this message translates to:
  /// **'DESTINATIONS I CAN PLAN'**
  String get destinationsICanPlan;

  /// No description provided for @iUnderstood.
  ///
  /// In en, this message translates to:
  /// **'I understood'**
  String get iUnderstood;

  /// No description provided for @childrenSuffix.
  ///
  /// In en, this message translates to:
  /// **', {count, plural, =1{1 child} other{{count} children}}'**
  String childrenSuffix(int count);

  /// No description provided for @budgetPerDayLabel.
  ///
  /// In en, this message translates to:
  /// **'{amount} per day'**
  String budgetPerDayLabel(String amount);

  /// No description provided for @budgetTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'{amount} total'**
  String budgetTotalLabel(String amount);

  /// No description provided for @saveToMyTrips.
  ///
  /// In en, this message translates to:
  /// **'Save to my trips'**
  String get saveToMyTrips;

  /// No description provided for @signInToSaveTrip.
  ///
  /// In en, this message translates to:
  /// **'Sign in to save this trip'**
  String get signInToSaveTrip;

  /// No description provided for @dayN.
  ///
  /// In en, this message translates to:
  /// **'Day {n}'**
  String dayN(int n);

  /// No description provided for @stopsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 stop} other{{count} stops}}'**
  String stopsCount(int count);

  /// No description provided for @timeline.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get timeline;

  /// No description provided for @routeMap.
  ///
  /// In en, this message translates to:
  /// **'Route map'**
  String get routeMap;

  /// No description provided for @regenerateDay.
  ///
  /// In en, this message translates to:
  /// **'Regenerate day {n}'**
  String regenerateDay(int n);

  /// No description provided for @noStopsYet.
  ///
  /// In en, this message translates to:
  /// **'No stops yet'**
  String get noStopsYet;

  /// No description provided for @noStopsHint.
  ///
  /// In en, this message translates to:
  /// **'This day has no suggestions.'**
  String get noStopsHint;

  /// No description provided for @dashedLineNote.
  ///
  /// In en, this message translates to:
  /// **'The dashed line joins stops in order: straight lines, not driving directions.'**
  String get dashedLineNote;

  /// No description provided for @budgetStay.
  ///
  /// In en, this message translates to:
  /// **'Stay'**
  String get budgetStay;

  /// No description provided for @budgetActivities.
  ///
  /// In en, this message translates to:
  /// **'Activities'**
  String get budgetActivities;

  /// No description provided for @budgetFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get budgetFood;

  /// No description provided for @budgetTransport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get budgetTransport;

  /// No description provided for @estimatedTotalCaps.
  ///
  /// In en, this message translates to:
  /// **'ESTIMATED TOTAL'**
  String get estimatedTotalCaps;

  /// No description provided for @withinBudget.
  ///
  /// In en, this message translates to:
  /// **'Within your {amount} budget'**
  String withinBudget(String amount);

  /// No description provided for @overBudget.
  ///
  /// In en, this message translates to:
  /// **'Over your {amount} budget'**
  String overBudget(String amount);

  /// No description provided for @lodgingNights.
  ///
  /// In en, this message translates to:
  /// **'{name} · {count, plural, =1{1 night} other{{count} nights}}'**
  String lodgingNights(String name, int count);

  /// No description provided for @assumptions.
  ///
  /// In en, this message translates to:
  /// **'Assumptions'**
  String get assumptions;

  /// No description provided for @minutesCompact.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m'**
  String minutesCompact(int minutes);

  /// No description provided for @travelMinutes.
  ///
  /// In en, this message translates to:
  /// **'~{minutes} min travel'**
  String travelMinutes(int minutes);

  /// No description provided for @moveUp.
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get moveUp;

  /// No description provided for @moveDown.
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get moveDown;

  /// No description provided for @removeStop.
  ///
  /// In en, this message translates to:
  /// **'Remove stop'**
  String get removeStop;

  /// No description provided for @copyToMyTrips.
  ///
  /// In en, this message translates to:
  /// **'Copy to my trips'**
  String get copyToMyTrips;

  /// No description provided for @estimateRecalculated.
  ///
  /// In en, this message translates to:
  /// **'Estimate recalculated: {amount}'**
  String estimateRecalculated(String amount);

  /// No description provided for @recalculate.
  ///
  /// In en, this message translates to:
  /// **'Recalculate'**
  String get recalculate;

  /// No description provided for @deleteTripQ.
  ///
  /// In en, this message translates to:
  /// **'Delete this trip?'**
  String get deleteTripQ;

  /// No description provided for @deleteTripBody.
  ///
  /// In en, this message translates to:
  /// **'This removes the itinerary from your account.'**
  String get deleteTripBody;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @addAStop.
  ///
  /// In en, this message translates to:
  /// **'Add a stop'**
  String get addAStop;

  /// No description provided for @inTrip.
  ///
  /// In en, this message translates to:
  /// **'In trip'**
  String get inTrip;

  /// No description provided for @addToDay.
  ///
  /// In en, this message translates to:
  /// **'Add to day {n}'**
  String addToDay(int n);

  /// No description provided for @starterBestTime.
  ///
  /// In en, this message translates to:
  /// **'Best time to go'**
  String get starterBestTime;

  /// No description provided for @starterGettingAround.
  ///
  /// In en, this message translates to:
  /// **'Getting around'**
  String get starterGettingAround;

  /// No description provided for @starterDailyBudget.
  ///
  /// In en, this message translates to:
  /// **'Daily budget'**
  String get starterDailyBudget;

  /// No description provided for @starterWhatToEat.
  ///
  /// In en, this message translates to:
  /// **'What to eat'**
  String get starterWhatToEat;

  /// No description provided for @starterTempleEtiquette.
  ///
  /// In en, this message translates to:
  /// **'Temple etiquette'**
  String get starterTempleEtiquette;

  /// No description provided for @starterCancellation.
  ///
  /// In en, this message translates to:
  /// **'Cancellation'**
  String get starterCancellation;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong.'**
  String get somethingWentWrong;

  /// No description provided for @guideName.
  ///
  /// In en, this message translates to:
  /// **'Wayfarer Guide'**
  String get guideName;

  /// No description provided for @guideModeLlm.
  ///
  /// In en, this message translates to:
  /// **'AI travel assistant · uses our guides'**
  String get guideModeLlm;

  /// No description provided for @guideModeRules.
  ///
  /// In en, this message translates to:
  /// **'Instant · answers from our guides'**
  String get guideModeRules;

  /// No description provided for @newChat.
  ///
  /// In en, this message translates to:
  /// **'New chat'**
  String get newChat;

  /// No description provided for @askMeAnything.
  ///
  /// In en, this message translates to:
  /// **'Ask me anything\nabout your trip.'**
  String get askMeAnything;

  /// No description provided for @askIntro.
  ///
  /// In en, this message translates to:
  /// **'Ask in your own words. I use WAYFARER\'s guides when they help and general travel knowledge when they don\'t, and I show my sources.'**
  String get askIntro;

  /// No description provided for @generalKnowledge.
  ///
  /// In en, this message translates to:
  /// **'General travel knowledge'**
  String get generalKnowledge;

  /// No description provided for @notInGuides.
  ///
  /// In en, this message translates to:
  /// **'Not in approved guides'**
  String get notInGuides;

  /// No description provided for @planWithPlanner.
  ///
  /// In en, this message translates to:
  /// **'Plan {name} with the AI planner'**
  String planWithPlanner(String name);

  /// No description provided for @sourcesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 source} other{{count} sources}}'**
  String sourcesCount(int count);

  /// No description provided for @demoContentSuffix.
  ///
  /// In en, this message translates to:
  /// **' (demo content)'**
  String get demoContentSuffix;

  /// No description provided for @cardStay.
  ///
  /// In en, this message translates to:
  /// **'STAY'**
  String get cardStay;

  /// No description provided for @cardPlace.
  ///
  /// In en, this message translates to:
  /// **'PLACE'**
  String get cardPlace;

  /// No description provided for @cardDestination.
  ///
  /// In en, this message translates to:
  /// **'DESTINATION'**
  String get cardDestination;

  /// No description provided for @askHint.
  ///
  /// In en, this message translates to:
  /// **'Ask about a destination…'**
  String get askHint;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @checkYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Check your email'**
  String get checkYourEmail;

  /// No description provided for @verificationSent.
  ///
  /// In en, this message translates to:
  /// **'We sent a verification link to {email}. Open it, then sign in.'**
  String verificationSent(String email);

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @googleNotSetUp.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in is not set up yet. Use your email and password for now.'**
  String get googleNotSetUp;

  /// No description provided for @createAnAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Create an\naccount'**
  String get createAnAccountTitle;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome\nback'**
  String get welcomeBack;

  /// No description provided for @signUpWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign up with Google'**
  String get signUpWithGoogle;

  /// No description provided for @signInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get signInWithGoogle;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get or;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get lastName;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @enterValidEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get enterValidEmailAddress;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @passwordHelper.
  ///
  /// In en, this message translates to:
  /// **'10+ characters, with letters and a number'**
  String get passwordHelper;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterPassword;

  /// No description provided for @passwordRule.
  ///
  /// In en, this message translates to:
  /// **'Use 10+ characters with letters and a number'**
  String get passwordRule;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @termsNotice.
  ///
  /// In en, this message translates to:
  /// **'By creating an account you agree to the WAYFARER Terms of Service and Privacy Policy.'**
  String get termsNotice;

  /// No description provided for @haveAccount.
  ///
  /// In en, this message translates to:
  /// **'Have an account? '**
  String get haveAccount;

  /// No description provided for @newHere.
  ///
  /// In en, this message translates to:
  /// **'New here? '**
  String get newHere;

  /// No description provided for @logInHere.
  ///
  /// In en, this message translates to:
  /// **'Log in here'**
  String get logInHere;

  /// No description provided for @createAnAccount.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get createAnAccount;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get resetPassword;

  /// No description provided for @resetLinkSent.
  ///
  /// In en, this message translates to:
  /// **'If an account exists for {email}, a reset link is on its way.'**
  String resetLinkSent(String email);

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send reset link'**
  String get sendResetLink;

  /// No description provided for @verifyEmailFirst.
  ///
  /// In en, this message translates to:
  /// **'Please verify your email first. We just sent you a new link: open it, then sign in again.'**
  String get verifyEmailFirst;

  /// No description provided for @authEmailInUse.
  ///
  /// In en, this message translates to:
  /// **'An account with this email already exists. Try signing in instead.'**
  String get authEmailInUse;

  /// No description provided for @authInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'That email address does not look right.'**
  String get authInvalidEmail;

  /// No description provided for @authWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Choose a stronger password: at least 10 characters with letters and a number.'**
  String get authWeakPassword;

  /// No description provided for @authWrongCredentials.
  ///
  /// In en, this message translates to:
  /// **'Email or password is incorrect.'**
  String get authWrongCredentials;

  /// No description provided for @authDisabled.
  ///
  /// In en, this message translates to:
  /// **'This account has been disabled. Contact support.'**
  String get authDisabled;

  /// No description provided for @authTooMany.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait a few minutes and try again.'**
  String get authTooMany;

  /// No description provided for @authNetwork.
  ///
  /// In en, this message translates to:
  /// **'No connection. Check your internet and try again.'**
  String get authNetwork;

  /// No description provided for @authNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'This sign-in method is not turned on in Firebase yet.'**
  String get authNotAllowed;

  /// No description provided for @authOtherMethod.
  ///
  /// In en, this message translates to:
  /// **'This email is already used with another sign-in method.'**
  String get authOtherMethod;

  /// No description provided for @authFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign-in failed ({code}). Please try again.'**
  String authFailed(String code);

  /// No description provided for @displayCurrency.
  ///
  /// In en, this message translates to:
  /// **'Display currency'**
  String get displayCurrency;

  /// No description provided for @currencyNote.
  ///
  /// In en, this message translates to:
  /// **'Prices are stored in USD and converted with documented sample rates, not live market rates.'**
  String get currencyNote;

  /// No description provided for @accountHero.
  ///
  /// In en, this message translates to:
  /// **'Your travel\nlife, in one place.'**
  String get accountHero;

  /// No description provided for @accountSignInHint.
  ///
  /// In en, this message translates to:
  /// **'Sign in to see bookings, saved trips and your wishlist.'**
  String get accountSignInHint;

  /// No description provided for @myBookingsSub.
  ///
  /// In en, this message translates to:
  /// **'Tickets, cancellation and receipts'**
  String get myBookingsSub;

  /// No description provided for @wishlist.
  ///
  /// In en, this message translates to:
  /// **'Wishlist'**
  String get wishlist;

  /// No description provided for @wishlistSub.
  ///
  /// In en, this message translates to:
  /// **'Saved destinations and stays'**
  String get wishlistSub;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @notificationsSub.
  ///
  /// In en, this message translates to:
  /// **'Booking and payment updates'**
  String get notificationsSub;

  /// No description provided for @exploreMap.
  ///
  /// In en, this message translates to:
  /// **'Explore map'**
  String get exploreMap;

  /// No description provided for @exploreMapSub.
  ///
  /// In en, this message translates to:
  /// **'Destinations and stays near you'**
  String get exploreMapSub;

  /// No description provided for @administrationSub.
  ///
  /// In en, this message translates to:
  /// **'Overview, bookings, payments, reviews, audit log'**
  String get administrationSub;

  /// No description provided for @partnerPortalSub.
  ///
  /// In en, this message translates to:
  /// **'Your properties, bookings and availability'**
  String get partnerPortalSub;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @deleteMyAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete my account'**
  String get deleteMyAccount;

  /// No description provided for @deleteAccountQ.
  ///
  /// In en, this message translates to:
  /// **'Delete your account?'**
  String get deleteAccountQ;

  /// No description provided for @deleteAccountBody.
  ///
  /// In en, this message translates to:
  /// **'Your profile is anonymised and you will be signed out. Active bookings must be cancelled first. This cannot be undone.'**
  String get deleteAccountBody;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// No description provided for @keepAccount.
  ///
  /// In en, this message translates to:
  /// **'Keep account'**
  String get keepAccount;

  /// No description provided for @nothingSavedYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing saved yet'**
  String get nothingSavedYet;

  /// No description provided for @nothingSavedHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the heart on a destination or stay to keep it here.'**
  String get nothingSavedHint;

  /// No description provided for @savedItem.
  ///
  /// In en, this message translates to:
  /// **'Saved item'**
  String get savedItem;

  /// No description provided for @stay.
  ///
  /// In en, this message translates to:
  /// **'Stay'**
  String get stay;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get markAllRead;

  /// No description provided for @allCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up'**
  String get allCaughtUp;

  /// No description provided for @inAppOnlyNote.
  ///
  /// In en, this message translates to:
  /// **'In-app notifications only. Push delivery needs Firebase credentials and is not configured.'**
  String get inAppOnlyNote;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSub.
  ///
  /// In en, this message translates to:
  /// **'English or Khmer'**
  String get languageSub;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'Phone setting'**
  String get languageSystem;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageKhmer.
  ///
  /// In en, this message translates to:
  /// **'ភាសាខ្មែរ'**
  String get languageKhmer;

  /// No description provided for @languageNote.
  ///
  /// In en, this message translates to:
  /// **'Places, descriptions and AI answers come from our database and are in English.'**
  String get languageNote;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @join.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get join;

  /// No description provided for @roleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get roleAdmin;

  /// No description provided for @roleStaff.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get roleStaff;

  /// No description provided for @rolePartner.
  ///
  /// In en, this message translates to:
  /// **'Partner'**
  String get rolePartner;

  /// No description provided for @roleCustomer.
  ///
  /// In en, this message translates to:
  /// **'Traveller'**
  String get roleCustomer;

  /// No description provided for @adminOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get adminOverview;

  /// No description provided for @adminBookings.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get adminBookings;

  /// No description provided for @adminPayments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get adminPayments;

  /// No description provided for @adminUsers.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get adminUsers;

  /// No description provided for @adminReviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get adminReviews;

  /// No description provided for @adminAuditLog.
  ///
  /// In en, this message translates to:
  /// **'Audit log'**
  String get adminAuditLog;

  /// No description provided for @adminContent.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get adminContent;

  /// No description provided for @adminAccessRequired.
  ///
  /// In en, this message translates to:
  /// **'Admin access required'**
  String get adminAccessRequired;

  /// No description provided for @adminAccessHint.
  ///
  /// In en, this message translates to:
  /// **'This area is only available to staff and administrators. Access is enforced by the server.'**
  String get adminAccessHint;

  /// No description provided for @totalCount.
  ///
  /// In en, this message translates to:
  /// **'{count} total'**
  String totalCount(int count);

  /// No description provided for @previousPage.
  ///
  /// In en, this message translates to:
  /// **'Previous page'**
  String get previousPage;

  /// No description provided for @nextPage.
  ///
  /// In en, this message translates to:
  /// **'Next page'**
  String get nextPage;

  /// No description provided for @simulatedNetRevenue.
  ///
  /// In en, this message translates to:
  /// **'simulated net revenue'**
  String get simulatedNetRevenue;

  /// No description provided for @bookingsByStatus.
  ///
  /// In en, this message translates to:
  /// **'Bookings by status'**
  String get bookingsByStatus;

  /// No description provided for @aiUsage.
  ///
  /// In en, this message translates to:
  /// **'AI usage'**
  String get aiUsage;

  /// No description provided for @noAiCalls.
  ///
  /// In en, this message translates to:
  /// **'No AI calls recorded yet.'**
  String get noAiCalls;

  /// No description provided for @aiCallsAvg.
  ///
  /// In en, this message translates to:
  /// **'{calls} calls · avg {ms} ms'**
  String aiCallsAvg(String calls, String ms);

  /// No description provided for @searchBookingsHint.
  ///
  /// In en, this message translates to:
  /// **'Reference, guest, email'**
  String get searchBookingsHint;

  /// No description provided for @demoSuffix.
  ///
  /// In en, this message translates to:
  /// **' · demo'**
  String get demoSuffix;

  /// No description provided for @actions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actions;

  /// No description provided for @cancelBookingRef.
  ///
  /// In en, this message translates to:
  /// **'Cancel booking {ref}?'**
  String cancelBookingRef(String ref);

  /// No description provided for @adminCancelBody.
  ///
  /// In en, this message translates to:
  /// **'The room is released and the guest is notified. Refund rules follow the booking policy.'**
  String get adminCancelBody;

  /// No description provided for @markCheckedIn.
  ///
  /// In en, this message translates to:
  /// **'Mark checked in'**
  String get markCheckedIn;

  /// No description provided for @markCompleted.
  ///
  /// In en, this message translates to:
  /// **'Mark completed'**
  String get markCompleted;

  /// No description provided for @bookingDetail.
  ///
  /// In en, this message translates to:
  /// **'Booking detail'**
  String get bookingDetail;

  /// No description provided for @paymentsAndTransactions.
  ///
  /// In en, this message translates to:
  /// **'Payments and transactions'**
  String get paymentsAndTransactions;

  /// No description provided for @nameOrEmail.
  ///
  /// In en, this message translates to:
  /// **'Name or email'**
  String get nameOrEmail;

  /// No description provided for @demoAccountSuffix.
  ///
  /// In en, this message translates to:
  /// **' · demo account'**
  String get demoAccountSuffix;

  /// No description provided for @changeRoleQ.
  ///
  /// In en, this message translates to:
  /// **'Change role?'**
  String get changeRoleQ;

  /// No description provided for @changeRoleBody.
  ///
  /// In en, this message translates to:
  /// **'Set {email} to \"{role}\". This changes what the account can do.'**
  String changeRoleBody(String email, String role);

  /// No description provided for @changeRole.
  ///
  /// In en, this message translates to:
  /// **'Change role'**
  String get changeRole;

  /// No description provided for @reviewModeration.
  ///
  /// In en, this message translates to:
  /// **'Review moderation'**
  String get reviewModeration;

  /// No description provided for @hide.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get hide;

  /// No description provided for @publish.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get publish;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'system'**
  String get system;

  /// No description provided for @numberBetween.
  ///
  /// In en, this message translates to:
  /// **'Enter a number between {lo} and {hi}'**
  String numberBetween(String lo, String hi);

  /// No description provided for @createDestination.
  ///
  /// In en, this message translates to:
  /// **'Create destination'**
  String get createDestination;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @atLeast2Chars.
  ///
  /// In en, this message translates to:
  /// **'At least 2 characters'**
  String get atLeast2Chars;

  /// No description provided for @country.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get country;

  /// No description provided for @shortDescription.
  ///
  /// In en, this message translates to:
  /// **'Short description (10+ chars)'**
  String get shortDescription;

  /// No description provided for @atLeast10CharsShort.
  ///
  /// In en, this message translates to:
  /// **'At least 10 characters'**
  String get atLeast10CharsShort;

  /// No description provided for @longDescription.
  ///
  /// In en, this message translates to:
  /// **'Long description (20+ chars)'**
  String get longDescription;

  /// No description provided for @atLeast20Chars.
  ///
  /// In en, this message translates to:
  /// **'At least 20 characters'**
  String get atLeast20Chars;

  /// No description provided for @latitude.
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get latitude;

  /// No description provided for @longitude.
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get longitude;

  /// No description provided for @dailyBudgetUsd.
  ///
  /// In en, this message translates to:
  /// **'Daily budget (USD)'**
  String get dailyBudgetUsd;

  /// No description provided for @destinationCreated.
  ///
  /// In en, this message translates to:
  /// **'Destination created and audited.'**
  String get destinationCreated;

  /// No description provided for @adminHotelsNote.
  ///
  /// In en, this message translates to:
  /// **'Hotels, rooms, prices and stock are managed by each partner in the web Partner dashboard (/partner). Administrators can browse them in the web Admin console (/admin).'**
  String get adminHotelsNote;

  /// No description provided for @partnerAccessRequired.
  ///
  /// In en, this message translates to:
  /// **'Partner access required'**
  String get partnerAccessRequired;

  /// No description provided for @partnerAccessHint.
  ///
  /// In en, this message translates to:
  /// **'Only partner accounts can manage properties. Access is enforced by the server.'**
  String get partnerAccessHint;

  /// No description provided for @occupancyNext30.
  ///
  /// In en, this message translates to:
  /// **'occupancy, next 30 days'**
  String get occupancyNext30;

  /// No description provided for @notApplicable.
  ///
  /// In en, this message translates to:
  /// **'n/a'**
  String get notApplicable;

  /// No description provided for @yourProperties.
  ///
  /// In en, this message translates to:
  /// **'Your properties'**
  String get yourProperties;

  /// No description provided for @noPropertiesAssigned.
  ///
  /// In en, this message translates to:
  /// **'No properties assigned to this partner account'**
  String get noPropertiesAssigned;

  /// No description provided for @baseRooms.
  ///
  /// In en, this message translates to:
  /// **'{price} base · {count} rooms'**
  String baseRooms(String price, String count);

  /// No description provided for @availability.
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get availability;

  /// No description provided for @incomingBookings.
  ///
  /// In en, this message translates to:
  /// **'Incoming bookings'**
  String get incomingBookings;

  /// No description provided for @checkInAction.
  ///
  /// In en, this message translates to:
  /// **'Check in'**
  String get checkInAction;

  /// No description provided for @complete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get complete;

  /// No description provided for @availabilityFor.
  ///
  /// In en, this message translates to:
  /// **'Availability: {name}'**
  String availabilityFor(String name);

  /// No description provided for @roomsAvailablePerNight.
  ///
  /// In en, this message translates to:
  /// **'Rooms available per night (0–{max})'**
  String roomsAvailablePerNight(String max);

  /// No description provided for @nightlyPriceOptional.
  ///
  /// In en, this message translates to:
  /// **'Nightly price USD (optional)'**
  String get nightlyPriceOptional;

  /// No description provided for @availabilityUpdated.
  ///
  /// In en, this message translates to:
  /// **'Availability updated'**
  String get availabilityUpdated;

  /// No description provided for @offlineMessage.
  ///
  /// In en, this message translates to:
  /// **'You appear to be offline, or the server is unreachable.'**
  String get offlineMessage;

  /// No description provided for @timeoutMessage.
  ///
  /// In en, this message translates to:
  /// **'The server took too long to respond. Check your connection and try again.'**
  String get timeoutMessage;

  /// No description provided for @quickPlaces.
  ///
  /// In en, this message translates to:
  /// **'Places'**
  String get quickPlaces;

  /// No description provided for @quickThingsToDo.
  ///
  /// In en, this message translates to:
  /// **'Things to do'**
  String get quickThingsToDo;

  /// No description provided for @saveAsPdf.
  ///
  /// In en, this message translates to:
  /// **'Save as PDF'**
  String get saveAsPdf;

  /// No description provided for @preparingPdf.
  ///
  /// In en, this message translates to:
  /// **'Preparing your PDF…'**
  String get preparingPdf;

  /// No description provided for @pdfFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not create the PDF. Please try again.'**
  String get pdfFailed;

  /// No description provided for @pdfBrandLine.
  ///
  /// In en, this message translates to:
  /// **'WAYFARER · TRIP ITINERARY'**
  String get pdfBrandLine;

  /// No description provided for @pdfCreatedOn.
  ///
  /// In en, this message translates to:
  /// **'Created on {date}'**
  String pdfCreatedOn(String date);

  /// No description provided for @pdfDayTitle.
  ///
  /// In en, this message translates to:
  /// **'Day {n}'**
  String pdfDayTitle(int n);

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @exKohRong.
  ///
  /// In en, this message translates to:
  /// **'Koh Rong island escape'**
  String get exKohRong;

  /// No description provided for @exMondulkiri.
  ///
  /// In en, this message translates to:
  /// **'Mondulkiri nature'**
  String get exMondulkiri;

  /// No description provided for @exBattambang.
  ///
  /// In en, this message translates to:
  /// **'Battambang food & culture'**
  String get exBattambang;

  /// No description provided for @fontCredit.
  ///
  /// In en, this message translates to:
  /// **'Khmer typeface: MiSans Khmer by Xiaomi'**
  String get fontCredit;

  /// No description provided for @dayInCity.
  ///
  /// In en, this message translates to:
  /// **'Day {n} · {city}'**
  String dayInCity(int n, String city);

  /// No description provided for @transferFromCity.
  ///
  /// In en, this message translates to:
  /// **'Transfer from {city}'**
  String transferFromCity(String city);

  /// No description provided for @transferInfo.
  ///
  /// In en, this message translates to:
  /// **'About {km} km by road · {time} · {price} (estimate)'**
  String transferInfo(String km, String time, String price);

  /// No description provided for @durationHoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'{hours} h {minutes} min'**
  String durationHoursMinutes(int hours, int minutes);

  /// No description provided for @durationHours.
  ///
  /// In en, this message translates to:
  /// **'{hours} h'**
  String durationHours(int hours);

  /// No description provided for @exTwoCities.
  ///
  /// In en, this message translates to:
  /// **'Kampot + Siem Reap'**
  String get exTwoCities;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'km'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'km':
      return AppLocalizationsKm();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
