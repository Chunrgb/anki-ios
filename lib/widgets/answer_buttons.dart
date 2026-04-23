import 'package:flutter/cupertino.dart';

typedef AnswerCallback = void Function(int ease);

class AnswerButtons extends StatelessWidget {
  final AnswerCallback onAnswer;
  final List<String> nextReviewTimes;

  const AnswerButtons({super.key, required this.onAnswer, required this.nextReviewTimes});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        border: const Border(top: BorderSide(color: CupertinoColors.separator)),
      ),
      child: Row(
        children: [
          Expanded(child: _AnswerButton(label: 'De Novo', time: _time(0), color: CupertinoColors.destructiveRed, onTap: () => onAnswer(1))),
          const SizedBox(width: 6),
          Expanded(child: _AnswerButton(label: 'Difícil', time: _time(1), color: CupertinoColors.systemOrange, onTap: () => onAnswer(2))),
          const SizedBox(width: 6),
          Expanded(child: _AnswerButton(label: 'Bom', time: _time(2), color: CupertinoColors.activeGreen, onTap: () => onAnswer(3))),
          const SizedBox(width: 6),
          Expanded(child: _AnswerButton(label: 'Fácil', time: _time(3), color: CupertinoColors.activeBlue, onTap: () => onAnswer(4))),
        ],
      ),
    );
  }

  String _time(int index) {
    if (index < nextReviewTimes.length) return nextReviewTimes[index];
    return '';
  }
}

class _AnswerButton extends StatelessWidget {
  final String label;
  final String time;
  final Color color;
  final VoidCallback onTap;

  const _AnswerButton({required this.label, required this.time, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (time.isNotEmpty)
              Text(time, style: TextStyle(fontSize: 11, color: color.withOpacity(0.8), fontWeight: FontWeight.w500)),
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }
}
