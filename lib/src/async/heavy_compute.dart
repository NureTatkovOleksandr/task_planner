import 'dart:isolate';

/// Глобальна змінна для демонстрації ізоляції пам'яті.
int sharedCounter = 0;

/// Важке синхронне обчислення: підрахунок простих чисел до [limit].
int countPrimesUpTo(int limit) {
  sharedCounter += 1;
  var count = 0;
  for (var n = 2; n <= limit; n++) {
    if (_isPrime(n)) {
      count++;
    }
  }
  return count;
}

bool _isPrime(int n) {
  if (n < 2) {
    return false;
  }
  for (var i = 2; i * i <= n; i++) {
    if (n % i == 0) {
      return false;
    }
  }
  return true;
}

/// Запускає [countPrimesUpTo] в окремому ізоляті.
Future<int> countPrimesInIsolate(int limit) {
  return Isolate.run(() => countPrimesUpTo(limit));
}
