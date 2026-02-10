import 'package:flutter/material.dart';

class AsyncList<t> with ChangeNotifier implements Iterable<t> {
  num steps;
  num total;
  late List<t> items;

  AsyncList({
    this.steps = 0,
    this.total = 0,
  }) {
    this.items = <t>[];
  }

  void addAll(Iterable<t> iterable) {
    items.addAll(iterable);
    notifyListeners();
  }

  void add(t item) {
    items.add(item);
    notifyListeners();
  }

  void clear() {
    items.clear();
    notifyListeners();
  }

  void setTotal(num total) {
    this.total = total;
    notifyListeners();
  }

  void setSteps(num steps) {
    this.steps = steps;
    notifyListeners();
  }

  void addStep({amount = 1}) {
    steps += amount;
    notifyListeners();
  }

  double get progress => steps / total;

  bool get isFinished => steps >= total;

  // Iterable<t> implementation

  @override
  bool any(bool Function(t element) test) {
    return items.any(test);
  }

  @override
  Iterable<R> cast<R>() {
    return items.cast<R>();
  }

  @override
  bool contains(Object? element) {
    return items.contains(element);
  }

  @override
  t elementAt(int index) {
    return items.elementAt(index);
  }

  @override
  bool every(bool Function(t element) test) {
    return items.every(test);
  }

  @override
  Iterable<T> expand<T>(Iterable<T> Function(t element) toElements) {
    return items.expand(toElements);
  }

  @override
  t get first => items.first;

  @override
  t firstWhere(bool Function(t element) test, {t Function()? orElse}) {
    return items.firstWhere(test, orElse: orElse);
  }

  @override
  T fold<T>(T initialValue, T Function(T previousValue, t element) combine) {
    return items.fold(initialValue, combine);
  }

  @override
  Iterable<t> followedBy(Iterable<t> other) {
    return items.followedBy(other);
  }

  @override
  void forEach(void Function(t element) action) {
    items.forEach(action);
  }

  @override
  bool get isEmpty => items.isEmpty;

  @override
  bool get isNotEmpty => items.isNotEmpty;

  @override
  Iterator<t> get iterator => items.iterator;

  @override
  String join([String separator = ""]) {
    return items.join(separator);
  }

  @override
  t get last => items.last;

  @override
  t lastWhere(bool Function(t element) test, {t Function()? orElse}) {
    return items.lastWhere(test, orElse: orElse);
  }

  @override
  int get length => items.length;

  @override
  Iterable<T> map<T>(T Function(t e) toElement) {
    return items.map(toElement);
  }

  @override
  t reduce(t Function(t value, t element) combine) {
    return items.reduce(combine);
  }

  @override
  t get single => items.single;

  @override
  t singleWhere(bool Function(t element) test, {t Function()? orElse}) {
    return items.singleWhere(test, orElse: orElse);
  }

  @override
  Iterable<t> skip(int count) {
    return items.skip(count);
  }

  @override
  Iterable<t> skipWhile(bool Function(t value) test) {
    return items.skipWhile(test);
  }

  @override
  Iterable<t> take(int count) {
    return items.take(count);
  }

  @override
  Iterable<t> takeWhile(bool Function(t value) test) {
    return items.takeWhile(test);
  }

  @override
  List<t> toList({bool growable = true}) {
    return items.toList(growable: growable);
  }

  @override
  Set<t> toSet() {
    return items.toSet();
  }

  @override
  Iterable<t> where(bool Function(t element) test) {
    return items.where(test);
  }

  @override
  Iterable<T> whereType<T>() {
    return items.whereType<T>();
  }
}
