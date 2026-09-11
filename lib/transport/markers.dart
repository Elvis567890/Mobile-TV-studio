/// Marker interfaces so the TransportSelector can identify which
/// radio it is currently running without importing every transport
/// implementation. Each transport mixes in exactly one of these.

abstract class WifiMarker {}

abstract class InternetMarker {}

abstract class BluetoothMarker {}
