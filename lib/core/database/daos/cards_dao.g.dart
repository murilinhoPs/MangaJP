// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cards_dao.dart';

// ignore_for_file: type=lint
mixin _$CardsDaoMixin on DatabaseAccessor<AppDatabase> {
  $UserWordsTable get userWords => attachedDatabase.userWords;
  $UserCardsTable get userCards => attachedDatabase.userCards;
  $UserCardSrsTable get userCardSrs => attachedDatabase.userCardSrs;
  $UserReviewLogsTable get userReviewLogs => attachedDatabase.userReviewLogs;
  CardsDaoManager get managers => CardsDaoManager(this);
}

class CardsDaoManager {
  final _$CardsDaoMixin _db;
  CardsDaoManager(this._db);
  $$UserWordsTableTableManager get userWords =>
      $$UserWordsTableTableManager(_db.attachedDatabase, _db.userWords);
  $$UserCardsTableTableManager get userCards =>
      $$UserCardsTableTableManager(_db.attachedDatabase, _db.userCards);
  $$UserCardSrsTableTableManager get userCardSrs =>
      $$UserCardSrsTableTableManager(_db.attachedDatabase, _db.userCardSrs);
  $$UserReviewLogsTableTableManager get userReviewLogs =>
      $$UserReviewLogsTableTableManager(
        _db.attachedDatabase,
        _db.userReviewLogs,
      );
}
