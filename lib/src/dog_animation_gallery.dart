import 'package:flutter/material.dart';

import 'glossy_sprite.dart';

@immutable
class DogAnimationEntry {
  const DogAnimationEntry(this.id, this.label, this.description, this.sprite);
  final String id;
  final String label;
  final String description;
  final GlossySpriteSpec sprite;
}

/// These exact asset paths and timings come from committed Dog metadata.
/// This gallery is a *manual preview*, not a phone usage diagnosis or
/// automatic task-completion event detector.
const dogAnimationEntries = <DogAnimationEntry>[
  DogAnimationEntry(
    'idle',
    'Bình thường',
    'Chú chó ngồi chờ bình yên',
    GlossySpriteSpec.dogIdle,
  ),
  DogAnimationEntry(
    'remind',
    'Nhắc nhở',
    'Chú chó nhắc một việc đã chọn',
    GlossySpriteSpec.dogRemind,
  ),
  DogAnimationEntry(
    'alarm',
    'Báo thức',
    'Chú chó báo thức một cách dễ thương',
    GlossySpriteSpec.dogAlarm,
  ),
  DogAnimationEntry(
    'resting',
    'Nghỉ ngơi',
    'Chú chó nghỉ ngơi thư giãn',
    GlossySpriteSpec.dogResting,
  ),
  DogAnimationEntry(
    'overloaded',
    'Quá tải',
    'Chú chó có biểu cảm quá tải vui nhộn',
    GlossySpriteSpec.dogOverloaded,
  ),
  DogAnimationEntry(
    'happy',
    'Vui vẻ',
    'Chú chó vui vẻ',
    GlossySpriteSpec.dogHappy,
  ),
  DogAnimationEntry(
    'sleepy',
    'Buồn ngủ',
    'Chú chó ngáp và buồn ngủ',
    GlossySpriteSpec.dogSleepy,
  ),
  DogAnimationEntry(
    'recovering',
    'Hồi phục',
    'Chú chó vươn vai sau khi nghỉ',
    GlossySpriteSpec.dogRecovering,
  ),
  DogAnimationEntry(
    'focus',
    'Tập trung',
    'Chú chó chú ý vào một việc',
    GlossySpriteSpec.dogFocus,
  ),
  DogAnimationEntry(
    'study',
    'Học tập',
    'Chú chó đọc sách',
    GlossySpriteSpec.dogStudy,
  ),
  DogAnimationEntry(
    'done',
    'Hoàn thành',
    'Chú chó ăn mừng hoàn thành nhiệm vụ',
    GlossySpriteSpec.dogDone,
  ),
  DogAnimationEntry(
    'thinking',
    'Suy nghĩ',
    'Chú chó đang suy nghĩ',
    GlossySpriteSpec.dogThinking,
  ),
  DogAnimationEntry(
    'sad',
    'Buồn',
    'Chú chó có biểu cảm buồn dịu dàng',
    GlossySpriteSpec.dogSad,
  ),
  DogAnimationEntry(
    'balanced',
    'Cân bằng',
    'Chú chó hít thở và bình tĩnh',
    GlossySpriteSpec.dogBalanced,
  ),
  DogAnimationEntry(
    'strained',
    'Căng nhẹ',
    'Chú chó hơi căng thẳng và thở ra',
    GlossySpriteSpec.dogStrained,
  ),
];

class DogAnimationGalleryPage extends StatefulWidget {
  const DogAnimationGalleryPage({super.key});

  @override
  State<DogAnimationGalleryPage> createState() =>
      _DogAnimationGalleryPageState();
}

class _DogAnimationGalleryPageState extends State<DogAnimationGalleryPage> {
  String _selected = 'recovering';
  int _replay = 0;

  @override
  Widget build(BuildContext context) {
    final entry = dogAnimationEntries.firstWhere(
      (item) => item.id == _selected,
    );
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Hoạt ảnh Chó · 15 trạng thái')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Glossy Kawaii · Nền trong suốt',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                'Chọn một trạng thái để xem nhân vật thật. '
                'Các hoạt ảnh là ứng viên cần đánh giá mỹ thuật và thiết bị trước khi phát hành.',
              ),
              const SizedBox(height: 16),
              Card(
                color: scheme.surfaceContainerLow,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      GlossySprite(
                        key: ValueKey('gallery-${entry.id}-$_replay'),
                        spec: entry.sprite,
                        size: 160,
                        semanticLabel: entry.description,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        entry.label,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(entry.description, textAlign: TextAlign.center),
                      const SizedBox(height: 8),
                      Text(
                        '${entry.sprite.frames} frame · '
                        '${entry.sprite.frameDurationMs} ms/frame · '
                        '${entry.sprite.loop ? 'lặp' : 'phát một lần'}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      TextButton.icon(
                        onPressed: () => setState(() => _replay++),
                        icon: const Icon(Icons.replay),
                        label: const Text('Xem lại hoạt ảnh'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Danh sách 15 trạng thái',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final item in dogAnimationEntries)
                    ChoiceChip(
                      key: ValueKey('state-${item.id}'),
                      label: Text(item.label),
                      selected: _selected == item.id,
                      onSelected: (selected) {
                        if (selected && _selected != item.id) {
                          setState(() {
                            _selected = item.id;
                            _replay++;
                          });
                        }
                      },
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Lưu ý: “Căng nhẹ” đang dùng tư thế minh họa được dựng lại; '
                'chưa đạt yêu cầu vẽ chuyển động độc lập và chưa được duyệt phát hành.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
