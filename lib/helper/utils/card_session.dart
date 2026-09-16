import 'dart:async';

/// A local cancellation request. Only the executor closes its Rust operation;
/// cancellation never races it to free a handle or abort an in-flight exchange.
class CardCancellation {
  bool _cancelled = false;
  void cancel() => _cancelled = true;
  void check() {
    if (_cancelled) throw StateError('Card operation cancelled');
  }
}

/// Serializes whole use cases, including connection setup and cleanup.
/// The zone is only an ownership marker, never a global selected-app/profile cache.
class CardSessions {
  final Object _zoneKey = Object();
  Future<void> _tail = Future<void>.value();
  int _generation = 0;
  int _queued = 0;

  bool get isBusy => _queued != 0;

  CardSession? get current => Zone.current[_zoneKey] as CardSession?;

  void invalidate() => _generation++;

  Future<T> run<T>(Future<T> Function(CardSession session) action) async {
    if (current != null) {
      throw StateError(
        'Nested card use cases must share their existing session',
      );
    }
    _queued++;
    final previous = _tail;
    final done = Completer<void>();
    _tail = done.future;
    await previous;
    final session = CardSession._(this);
    try {
      return await runZoned(
        () => action(session),
        zoneValues: {_zoneKey: session},
      );
    } finally {
      // Even an accidentally unawaited exchange must settle before reuse.
      try {
        await session._close();
      } finally {
        _queued--;
        done.complete();
      }
    }
  }
}

class CardSession {
  CardSession._(this._owner);
  final CardSessions _owner;
  CardLease? _lease;
  bool _closed = false;

  CardLease get lease {
    if (_closed) throw StateError('Card session is closed');
    final lease = _lease;
    if (lease == null) throw StateError('Card connection has not been bound');
    lease.check();
    return lease;
  }

  /// Rebinding is explicit after a new poll/connection. It clears all prior
  /// selected-app evidence, and cannot replace an outstanding exchange.
  void bind(Future<String> Function(String) exchange) {
    if (_closed ||
        (_lease?._pending != null) ||
        (_lease?._operationToken != null)) {
      throw StateError('Cannot replace an active or closed card connection');
    }
    _owner.invalidate();
    _lease?._closed = true;
    _lease?._releaseResources();
    _lease = CardLease._(_owner, _owner._generation, exchange);
  }

  Future<void> _close() async {
    _closed = true;
    final lease = _lease;
    if (lease != null) {
      lease._closed = true;
      await lease._pending;
      lease._releaseResources();
    }
  }
}

/// A generation-bound raw channel. Keep this same object through start, every
/// advance and result publication. It owns neither APDU continuation nor retries.
class CardLease {
  CardLease._(this._owner, this._generation, this._exchange);
  final CardSessions _owner;
  final int _generation;
  final Future<String> Function(String) _exchange;
  bool _closed = false;
  bool _failed = false;
  Future<void>? _pending;
  Object? _operationToken;

  int _selectionGeneration = 0;
  int _profileGeneration = 0;
  int get selectionGeneration => _selectionGeneration;
  int get profileGeneration => _profileGeneration;

  /// Call before a known selecting operation, never by inspecting APDU bytes.
  void willSelectApplet() {
    check();
    if (isExchanging) {
      throw StateError('Cannot select during an active operation');
    }
    _selectionGeneration++;
  }

  /// Local invalidation is valid even after a lost response poisoned the lease.
  /// Every applet's profile evidence must be refreshed after an exposed write.
  void invalidateProfileEvidence() => _profileGeneration++;

  int? _adminAuthSelection;
  int? _adminAuthProfile;

  /// Record an authenticated Admin session. Only an explicit, successful
  /// facade VERIFY on this lease may call this; a UI credential cache never
  /// creates this evidence. The stamp is bound to the current selection and
  /// profile generations, so any later applet selection or profile
  /// invalidation expires it without further bookkeeping.
  void recordAdminAuthentication() {
    check();
    _adminAuthSelection = _selectionGeneration;
    _adminAuthProfile = _profileGeneration;
  }

  /// Whether the recorded Admin authentication still matches both generations.
  bool get hasAdminAuthentication =>
      _adminAuthSelection != null &&
      _adminAuthSelection == _selectionGeneration &&
      _adminAuthProfile == _profileGeneration;

  /// Explicit invalidation after an exposed or uncertain Admin mutation and
  /// after a failed request that relied on the recorded session.
  void invalidateAdminAuthentication() {
    _adminAuthSelection = null;
    _adminAuthProfile = null;
  }

  /// Reserve the whole protocol operation, including gaps between exchanges.
  /// Competing work fails before I/O rather than sharing selection/auth state.
  CardOperationLease beginOperation() {
    check();
    if (_pending != null || _operationToken != null) {
      throw StateError('A card operation is already active');
    }
    final token = _operationToken = Object();
    return CardOperationLease._(this, token);
  }

  bool get isExchanging => _pending != null || _operationToken != null;
  final List<void Function()> _resources = [];

  /// Transfer local resource cleanup to this physical lease, never a UI cache.
  void onClose(void Function() release) {
    check();
    _resources.add(release);
  }

  void _releaseResources() {
    Object? failure;
    StackTrace? stack;
    while (_resources.isNotEmpty) {
      try {
        _resources.removeLast()();
      } catch (error, trace) {
        failure ??= error;
        stack ??= trace;
      }
    }
    if (failure != null) Error.throwWithStackTrace(failure, stack!);
  }

  void check() {
    if (_closed || _failed || _owner._generation != _generation) {
      throw StateError('Card session is no longer current');
    }
  }

  Future<String> exchange(String command) => _exchangeOwned(command, null);

  Future<String> _exchangeOwned(String command, Object? token) async {
    check();
    if (!identical(token, _operationToken)) {
      throw StateError('Raw exchange cannot interrupt a protocol operation');
    }
    if (_pending != null) {
      throw StateError('Concurrent exchange in a card session');
    }
    final settled = Completer<void>();
    _pending = settled.future;
    try {
      final response = await _exchange(command);
      check();
      return response;
    } catch (_) {
      _failed = true;
      rethrow;
    } finally {
      _pending = null;
      settled.complete();
    }
  }
}

/// Executor-owned reservation. Releasing it is local and sends no APDU.
class CardOperationLease {
  CardOperationLease._(this._lease, this._token);
  final CardLease _lease;
  final Object _token;
  bool _closed = false;

  void check() {
    _lease.check();
    if (_closed || !identical(_lease._operationToken, _token)) {
      throw StateError('Card operation reservation is closed');
    }
  }

  Future<String> exchange(String command) {
    check();
    return _lease._exchangeOwned(command, _token);
  }

  void close() {
    if (_closed) return;
    _closed = true;
    if (identical(_lease._operationToken, _token)) {
      _lease._operationToken = null;
    }
  }
}
