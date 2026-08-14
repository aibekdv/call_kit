/// Marker for "this argument was not passed".
///
/// `copyWith` cannot tell `null` from "leave it alone" when a field is itself
/// nullable, and several fields here genuinely need to be cleared — an error
/// message, an active speaker, a start time. Passing this sentinel by default
/// makes the difference expressible.
const Object unset = Object();

/// Resolves a `copyWith` argument that may be [unset].
T? resolve<T>(Object? value, T? current) =>
    identical(value, unset) ? current : value as T?;
