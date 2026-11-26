// The menu overlay must work under a modern `material_ui` host: it has to read
// the host theme, open a real overlay, run menu actions and dismiss. Pumping
// the SDK `flutter/material.dart` app instead would hide a broken import.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:quick_action_menu/quick_action_menu.dart';

const _anchorKey = Key('anchor');
const _menuItemKey = Key('menu-copy');

ThemeData _hostTheme(Brightness brightness) => ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF0A7EA4),
        brightness: brightness,
      ),
    );

Widget _menu(VoidCallback onCopy) => Material(
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: _menuItemKey,
        onTap: onCopy,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text('Copy'),
        ),
      ),
    );

class _Host extends StatelessWidget {
  const _Host({required this.onCopy});

  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return QuickActionMenu(
      child: Builder(
        builder: (menuContext) => Center(
          child: QuickActionAnchor(
            tag: 'bubble',
            child: GestureDetector(
              key: _anchorKey,
              onTap: () => QuickActionMenu.of(menuContext).showMenu(
                tag: 'bubble',
                topMenuWidget: _menu(onCopy),
              ),
              child: Container(
                width: 160,
                height: 48,
                color: Colors.blueGrey,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void main() {
  for (final brightness in Brightness.values) {
    final mode = brightness.name;
    testWidgets('opens, runs and dismisses the menu in $mode mode', (
      tester,
    ) async {
      var copyTaps = 0;
      final theme = _hostTheme(brightness);

      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(body: _Host(onCopy: () => copyTaps++)),
        ),
      );

      expect(
        Theme.of(tester.element(find.byKey(_anchorKey))).colorScheme.primary,
        theme.colorScheme.primary,
        reason: 'the host material_ui theme must reach the package widgets',
      );
      expect(find.text('Copy'), findsNothing);

      await tester.tap(find.byKey(_anchorKey));
      await tester.pumpAndSettle();

      expect(find.text('Copy'), findsOneWidget);

      final scrim = tester.widget<Container>(
        find.descendant(
          of: find.byType(BackdropFilter),
          matching: find.byType(Container),
        ),
      );
      expect(
        scrim.color,
        Colors.black.withValues(alpha: 0.2),
        reason: 'the default scrim stays black at 20% opacity',
      );

      await tester.tap(find.byKey(_menuItemKey));
      await tester.pumpAndSettle();
      expect(copyTaps, 1);

      await tester.tapAt(const Offset(4, 4));
      await tester.pumpAndSettle();

      expect(find.text('Copy'), findsNothing);
      expect(find.byKey(_anchorKey), findsOneWidget);
    });
  }
}
