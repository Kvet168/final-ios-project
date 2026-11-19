import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

export 'app_localizations.dart';

/// `context.l10n.someKey`: the app's strings in the current language (English or Khmer).
/// Add strings to lib/l10n/app_en.arb and app_km.arb together; `flutter gen-l10n` (run by every build) regenerates the class.
extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
  bool get isKhmer => Localizations.localeOf(this).languageCode == 'km';
}

String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// Accommodation type codes from the API (hotel, resort, ...) as display names.
String stayTypeLabel(AppLocalizations l, String? t) => switch (t) {
  'hotel' => l.typeHotel,
  'guesthouse' => l.typeGuesthouse,
  'resort' => l.typeResort,
  'hostel' => l.typeHostel,
  'boutique' => l.typeBoutique,
  'villa' => l.typeVilla,
  'apartment' => l.typeApartment,
  'bungalow' => l.typeBungalow,
  _ => _cap(t ?? ''),
};

/// Place categories and destination tags from the API as display names. Unknown codes fall back to the code itself.
String categoryLabel(AppLocalizations l, String? c) => switch (c) {
  'temple' => l.catTemple,
  'temples' => l.tagTemples,
  'museum' => l.catMuseum,
  'market' => l.catMarket,
  'nature' => l.catNature,
  'beach' => l.catBeach,
  'food' => l.catFood,
  'cafe' => l.catCafe,
  'culture' => l.catCulture,
  'tour' => l.catTour,
  'outdoor' => l.catOutdoor,
  'family' => l.catFamily,
  'landmark' => l.catLandmark,
  'history' => l.catHistory,
  'restaurant' => l.catRestaurant,
  'activity' => l.catActivity,
  'attraction' => l.catAttraction,
  'relaxed' => l.tagRelaxed,
  'city' => l.tagCity,
  'islands' => l.tagIslands,
  _ => _cap((c ?? '').replaceAll('_', ' ')),
};

/// Amenity codes from the API as display names; unknown codes keep the server's English label.
String amenityLabel(AppLocalizations l, String? code, String fallback) =>
    switch (code) {
      'wifi' => l.amenWifi,
      'pool' => l.amenPool,
      'ac' => l.amenAc,
      'breakfast' => l.amenBreakfast,
      'parking' => l.amenParking,
      'airport-shuttle' => l.amenShuttle,
      'gym' => l.amenGym,
      'spa' => l.amenSpa,
      'restaurant' => l.amenRestaurant,
      'family-room' => l.amenFamilyRoom,
      'kids-pool' => l.amenKidsPool,
      'accessible' => l.amenAccessible,
      'bar' => l.amenBar,
      'laundry' => l.amenLaundry,
      'kitchen' => l.amenKitchen,
      _ => fallback,
    };

/// Booking and payment status codes from the API as display names.
String statusLabel(AppLocalizations l, String status) => switch (status) {
  'CONFIRMED' => l.statusConfirmed,
  'PENDING_CONFIRMATION' => l.statusAwaitingPayment,
  'CHECKED_IN' => l.statusCheckedIn,
  'COMPLETED' => l.statusCompleted,
  'CANCELLED' => l.statusCancelled,
  'EXPIRED' => l.statusExpired,
  'REFUND_PENDING' => l.statusRefundPending,
  'REFUNDED' => l.statusRefunded,
  'DRAFT' => l.statusDraft,
  'SUCCESS' => l.statusPaid,
  'FAILED' => l.statusPaymentFailed,
  'PENDING' => l.statusPaymentPending,
  _ => _cap(status.replaceAll('_', ' ').toLowerCase()),
};
