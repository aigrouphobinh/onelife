import 'package:flutter/material.dart';
import 'glossy_sprite.dart';

@immutable
class RobotAnimationEntry {
  const RobotAnimationEntry(this.id, this.label, this.description, this.sprite);
  final String id;
  final String label;
  final String description;
  final GlossySpriteSpec sprite;
}

/// Exactly 12 source-backed Robot animations present on main.
/// Missing Sad / Balanced / Strained are intentionally not previewed as fake art.
const robotAnimationEntries = <RobotAnimationEntry>[
  RobotAnimationEntry('idle', 'Bình thường', 'Robot đứng chờ, đèn sáng dịu', GlossySpriteSpec.robotIdle),
  RobotAnimationEntry('remind', 'Nhắc nhở', 'Robot nhắc một việc đã chọn', GlossySpriteSpec.robotRemind),
  RobotAnimationEntry('happy', 'Vui vẻ', 'Robot mỉm cười và nhún nhảy', GlossySpriteSpec.robotHappy),
  RobotAnimationEntry('overloaded', 'Quá tải', 'Robot giảm nhịp khi cần nghỉ', GlossySpriteSpec.robotOverloaded),
  RobotAnimationEntry('resting', 'Nghỉ ngơi', 'Robot thư giãn và hạ tay', GlossySpriteSpec.robotResting),
  RobotAnimationEntry('alarm', 'Báo thức', 'Robot đánh thức nhẹ nhàng', GlossySpriteSpec.robotAlarm),
  RobotAnimationEntry('sleepy', 'Buồn ngủ', 'Robot buồn ngủ và chớp mắt', GlossySpriteSpec.robotSleepy),
  RobotAnimationEntry('recovering', 'Hồi phục', 'Robot khôi phục sau giờ nghỉ', GlossySpriteSpec.robotRecovering),
  RobotAnimationEntry('focus', 'Tập trung', 'Robot hướng sự chú ý vào một việc', GlossySpriteSpec.robotFocus),
  RobotAnimationEntry('study', 'Học tập', 'Robot đọc và khám phá kiến thức', GlossySpriteSpec.robotStudy),
  RobotAnimationEntry('done', 'Hoàn thành', 'Robot ăn mừng hoàn thành việc nhỏ', GlossySpriteSpec.robotDone),
  RobotAnimationEntry('thinking', 'Suy nghĩ', 'Robot nghiêng đầu, suy nghĩ và có ý tưởng', GlossySpriteSpec.robotThinking),
];

class RobotAnimationGalleryPage extends StatefulWidget {
  const RobotAnimationGalleryPage({super.key});

  @override
  State<RobotAnimationGalleryPage> createState() =>
      _RobotAnimationGalleryPageState();
}

class _RobotAnimationGalleryPageState extends State<RobotAnimationGalleryPage> {
  String _selected = 'thinking';
  int _replayCount = 0;

  @override
  Widget build(BuildContext context) {
    final current = robotAnimationEntries.firstWhere((e) => e.id == _selected);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Hoạt ảnh Robot · 12 trạng thái')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Glossy Kawaii · PNG nền trong suốt',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              const Text(
                'Hiện có 12/15 animation nguồn Robot. '
                'Sad, Balanced và Strained chưa có sprite thật; '
                'không sử dụng ảnh mô phỏng cho ba trạng thái này.',
              ),
              const SizedBox(height: 12),
              Card(
                color: scheme.surfaceContainerLow,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      GlossySprite(
                        key: ValueKey('robot-${current.id}-$_replayCount'),
                        spec: current.sprite,
                        size: 160,
                        semanticLabel: current.description,
                      ),
                      const SizedBox(height: 8),
                      Text(current.label,
                          style: Theme.of(context).textTheme.titleLarge),
                      Text(current.description, textAlign: TextAlign.center),
                      Text(
                        '${current.sprite.frames} frame · '
                        '${current.sprite.frameDurationMs} ms/frame · '
                        '${current.sprite.loop ? 'lặp' : 'phát một lần'}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () => setState(() => _replayCount++),
                        icon: const Icon(Icons.replay),
                        label: const Text('Xem lại hoạt ảnh'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text('12 trạng thái có asset thật',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final item in robotAnimationEntries)
                    ChoiceChip(
                      key: ValueKey('robot-state-${item.id}'),
                      label: Text(item.label),
                      selected: item.id == _selected,
                      onSelected: (selected) {
                        if (selected && _selected != item.id) {
                          setState(() {
                            _selected = item.id;
                            _replayCount++;
                          });
                        }
                      },
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Nguồn đã vượt kiểm tra kỹ thuật; mỹ thuật, độ đồng nhất '
                'với master và Android/iOS thực tế chưa được nghiệm thu.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
