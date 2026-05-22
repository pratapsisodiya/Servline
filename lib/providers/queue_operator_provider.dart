// Queue operator state is managed directly in QueueOperatorScreen
// as ConsumerStatefulWidget local state — no provider needed.
// This avoids Riverpod family complexity for a screen-scoped concern.
export 'package:servline/repositories/queue_operator_repository.dart'
    show QueueOperatorRepository, queueOperatorRepositoryProvider;
